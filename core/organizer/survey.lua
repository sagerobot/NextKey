-- MARK: Module Definition
local _, NextKey222 = ...

local ParticipantSurvey = {}
NextKey222.ParticipantSurvey = ParticipantSurvey
NextKey222.RegisterModule("ParticipantSurvey", ParticipantSurvey)

local Debug = NextKey222.Debug

-- MARK: Module State
ParticipantSurvey.activeDialog = nil

-- MARK: Initialization
function ParticipantSurvey:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "Initializing Participant Survey module")
        
        -- Register communication handlers
        self:RegisterHandlers()
        
        Debug:Dev("organizer", "Participant Survey initialized successfully")
        return true
    end, "ParticipantSurvey:Initialize")
end

-- MARK: Communication Handlers
function ParticipantSurvey:RegisterHandlers()
    -- Handler registration removed - Communications module routes messages directly
    -- via ProcessOrganizerPollRequest and ProcessOrganizerPollResponse
    Debug:Dev("organizer", "Survey communication handlers ready (routed via Communications module)")
end

-- MARK: Poll Request (Organizer → Participants)
function ParticipantSurvey:SendPollRequest(pollID)
    return NextKey222.SafeRun(function()
        local message = {
            pollID = pollID,
            timeout = 60,
            organizerName = UnitName("player") .. "-" .. GetRealmName()
        }
        
        NextKey222.Communications:SendOrganizerMessage(
            "ORG_POLL_REQUEST",
            message,
            "RAID"
        )
        
        Debug:Dev("organizer", "Sent poll request to RAID - ID:", pollID)
        
    end, "ParticipantSurvey:SendPollRequest")
end

function ParticipantSurvey:OnPollRequestReceived(message, sender)
    return NextKey222.SafeRun(function()
        -- REMOVED: No longer excluding organizer from survey
        -- The organizer should also receive and respond to the poll
        
        Debug:Dev("organizer", "Received poll request from", sender, "- ID:", message.pollID)
        
        -- Show survey dialog
        self:ShowSurveyDialog(message)
        
    end, "ParticipantSurvey:OnPollRequestReceived")
end

-- MARK: Poll Response (Participant → Organizer)
function ParticipantSurvey:SendPollResponse(response, organizerName)
    return NextKey222.SafeRun(function()
        -- Use OrganizerComms module instead of Communications
        if NextKey222.OrganizerComms then
            NextKey222.OrganizerComms:SendOrganizerMessage(
                "ORG_POLL_RESPONSE",
                response,
                "WHISPER",
                organizerName
            )
            Debug:Dev("organizer", "Sent poll response to", organizerName)
        else
            Debug:Error("OrganizerComms module not available")
        end
        
    end, "ParticipantSurvey:SendPollResponse")
end

function ParticipantSurvey:OnPollResponseReceived(message, sender)
    return NextKey222.SafeRun(function()
        local response = message
        
        -- Validate we have an active poll
        if not NextKey222.RosterBoard or not NextKey222.RosterBoard.activePoll then
            Debug:Dev("organizer", "Received response but no active poll - ignoring")
            return
        end
        
        -- Validate poll ID matches
        if NextKey222.RosterBoard.activePoll.id ~= response.pollID then
            Debug:Dev("organizer", "Received response for wrong poll ID - ignoring")
            return
        end
        
        Debug:Dev("organizer", "POLL RESPONSE RECEIVED from", sender)
        Debug:Dev("organizer", "  - Has specPreferences:", response.specPreferences ~= nil)
        Debug:Dev("organizer", "  - Has specDetails:", response.specDetails ~= nil)
        if response.specPreferences then
            local prefCount = 0
            for role, pref in pairs(response.specPreferences) do
                prefCount = prefCount + 1
                Debug:Dev("organizer", "    - Role", role, "=", pref)
            end
            Debug:Dev("organizer", "  - Total preferences:", prefCount)
        end
        
        -- Store response
        table.insert(NextKey222.RosterBoard.activePoll.responses, {
            sender = sender,
            response = response,
            timestamp = GetTime()
        })
        
        -- Process response immediately (updates OrganizerState)
        self:ProcessResponse(sender, response)
        
        -- SESSION 4: Auto-save state after poll response
        if NextKey222.OrganizerState and NextKey222.OrganizerState.SaveToPersistence then
            NextKey222.OrganizerState:SaveToPersistence()
        end
        
        -- SESSION 3: Sync UI to match state changes (opt-out moves, alt additions, etc.)
        if NextKey222.RosterBoard and NextKey222.RosterBoard.SyncUIToState then
            NextKey222.RosterBoard:SyncUIToState()
        end
        
        -- Update UI progress
        if NextKey222.RosterBoard.UpdatePollProgress then
            NextKey222.RosterBoard:UpdatePollProgress()
        end
        
    end, "ParticipantSurvey:OnPollResponseReceived")
end

-- MARK: Response Processing
function ParticipantSurvey:ProcessResponse(playerID, response)
    return NextKey222.SafeRun(function()
        -- Normalize response format
        local optedIn = response.optedIn
        if optedIn == nil and response.participation then
            optedIn = (response.participation == "in")
        end
        
        -- CRITICAL: Store poll response in OrganizerState (prevents data loss!)
        NextKey222.OrganizerState:UpdatePlayerFromPollResponse(playerID, response)
        
        if optedIn then
            -- Player opted in
            if response.selectedCharacter == playerID then
                -- Current character selected
                Debug:Dev("organizer", "Poll response: Player", playerID, "opted in on current character")
                
                -- Update state
                local location = NextKey222.OrganizerState:GetPlayerLocation(playerID)
                
                if location == "opt_out" then
                    NextKey222.OrganizerState:MoveToBench(playerID)
                    Debug:Dev("organizer", "Moved", playerID, "from opt-out to bench in state")
                elseif not location then
                    NextKey222.OrganizerState:MoveToBench(playerID)
                    Debug:Dev("organizer", "Added new player", playerID, "to bench in state")
                end
                
            else
                -- Alt character selected
                local altID = response.selectedCharacter
                Debug:Dev("organizer", "Poll response: Player", playerID, "selected alt:", altID)
                
                -- Update state
                local altPlayerData = self:BuildAltPlayerData(response)
                NextKey222.OrganizerState:SetPlayer(altID, altPlayerData)
                NextKey222.OrganizerState:MoveToBench(altID)
                NextKey222.OrganizerState:UpdatePlayer(playerID, {benchedForAlt = true})
                NextKey222.OrganizerState:MoveToOptOut(playerID)
                
                Debug:Dev("organizer", "Added alt", altID, "to bench and moved", playerID, "to opt-out")
            end
        else
            -- Player opted out
            Debug:Dev("organizer", "Poll response: Player", playerID, "opted out")
            NextKey222.OrganizerState:MoveToOptOut(playerID)
        end
        
    end, "ParticipantSurvey:ProcessResponse")
end

-- MARK: Player Data Building
function ParticipantSurvey:BuildPlayerDataFromResponse(playerID, response)
    -- Get base profile data from ProfilesService
    local profile = {}
    if NextKey222.ProfilesService and NextKey222.ProfilesService.GetOrganizerProfile then
        profile = NextKey222.ProfilesService:GetOrganizerProfile(playerID) or {}
    end
    
    -- CRITICAL: Add spec preferences from poll response for multi-role display
    if response.specPreferences then
        profile.specPreferences = response.specPreferences
        profile.specDetails = response.specDetails  -- NEW: Store spec-level breakdown for tooltips
        
        -- DEBUG: Verify specDetails structure
        if response.specDetails then
            Debug:Dev("organizer", "BuildPlayerDataFromResponse - specDetails for", playerID, ":")
            for role, specs in pairs(response.specDetails) do
                Debug:Dev("organizer", "  - Role:", role, "- Specs:", #specs)
            end
        else
            Debug:Error("BuildPlayerDataFromResponse - response.specDetails is NIL for", playerID)
        end
        
        Debug:Dev("organizer", "Added spec preferences to player data:", playerID, "- prefs:", response.specPreferences)
    else
        Debug:Error("BuildPlayerDataFromResponse - response.specPreferences is NIL for", playerID)
    end
    
    -- Enhance with survey response data
    profile.surveyResponse = {
        optedIn = response.optedIn,
        selectedCharacter = response.selectedCharacter,
        rolePreferences = response.rolePreferences or {},
        timestamp = GetTime()
    }
    
    profile.dataSource = "addon"
    profile.hasAddon = true
    
    -- Ensure we have at least basic data
    profile.id = profile.id or playerID
    profile.name = profile.name or playerID:match("^([^%-]+)") or playerID
    profile.class = profile.class or "WARRIOR"
    profile.roles = profile.roles or {"DAMAGER"}
    profile.overallScore = profile.io or profile.overallScore or 0
    
    Debug:Dev("organizer", "Built player data from response for", playerID)
    
    return profile
end

function ParticipantSurvey:BuildAltPlayerData(response)
    -- Use character data from response
    local altData = response.characterData or {}
    
    local playerData = {
        id = response.selectedCharacter .. "_TEMP",
        name = altData.name or response.selectedCharacter:match("^([^%-]+)") or response.selectedCharacter,
        realm = altData.realm or GetRealmName(),
        class = altData.class or "WARRIOR",
        roles = self:ExtractRoles(altData.availableRoles or {}),
        utilities = altData.utilities or {},
        keystone = altData.keystone,
        scores = altData.scores,
        overallScore = altData.overallScore or 0,
        specName = altData.specName,
        preferences = {},
        
        -- CRITICAL: Add spec preferences from poll response for multi-role display
        specPreferences = response.specPreferences,
        specDetails = response.specDetails,  -- NEW: Store spec-level breakdown for tooltips
        
        -- Temporary flags
        isTemporary = true,
        sourceCharacter = response.selectedCharacter,
        dataSource = "temporary",
        hasAddon = true,
        
        -- Survey response
        surveyResponse = {
            rolePreferences = response.rolePreferences or {}
        }
    }
    
    Debug:Dev("organizer", "Built alt player data for", playerData.name, "with spec prefs:", response.specPreferences)
    
    return playerData
end

function ParticipantSurvey:ExtractRoles(availableRoles)
    local roles = {}
    
    if type(availableRoles) == "table" then
        for role, enabled in pairs(availableRoles) do
            if enabled then
                table.insert(roles, role)
            end
        end
    end
    
    -- Fallback to DAMAGER if no roles found
    if #roles == 0 then
        table.insert(roles, "DAMAGER")
    end
    
    return roles
end

-- MARK: Survey Dialog Interface
function ParticipantSurvey:ShowSurveyDialog(pollData)
    -- Delegate to SurveyDialog module
    if NextKey222.SurveyDialog and NextKey222.SurveyDialog.Show then
        NextKey222.SurveyDialog:Show(pollData)
    else
        Debug:Error("SurveyDialog module not available")
    end
end