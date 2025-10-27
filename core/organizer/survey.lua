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
    if not NextKey222.Communications then
        Debug:Error("Communications module not available for survey registration")
        return
    end
    
    -- Register poll request handler (participants receive this)
    NextKey222.Communications:RegisterOrganizerHandler("ORG_POLL_REQUEST", function(message, sender)
        self:OnPollRequestReceived(message, sender)
    end)
    
    -- Register poll response handler (organizer receives this)
    NextKey222.Communications:RegisterOrganizerHandler("ORG_POLL_RESPONSE", function(message, sender)
        self:OnPollResponseReceived(message, sender)
    end)
    
    Debug:Dev("organizer", "Survey communication handlers registered")
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
        
        Debug:Dev("organizer", "Received valid poll response from", sender)
        
        -- Store response
        table.insert(NextKey222.RosterBoard.activePoll.responses, {
            sender = sender,
            response = response,
            timestamp = GetTime()
        })
        
        -- Process response immediately
        self:ProcessResponse(sender, response)
        
        -- Update UI progress
        if NextKey222.RosterBoard.UpdatePollProgress then
            NextKey222.RosterBoard:UpdatePollProgress()
        end
        
    end, "ParticipantSurvey:OnPollResponseReceived")
end

-- MARK: Response Processing
function ParticipantSurvey:ProcessResponse(playerID, response)
    return NextKey222.SafeRun(function()
        -- Normalize response format (handle both 'optedIn' and 'participation' fields)
        local optedIn = response.optedIn
        if optedIn == nil and response.participation then
            optedIn = (response.participation == "in")
        end
        
        if optedIn then
            -- Check if they selected an alt or their current character
            if response.selectedCharacter == playerID then
                -- Current character - check if already in bench before adding
                local playerData = self:BuildPlayerDataFromResponse(playerID, response)
                
                if NextKey222.RosterBoard then
                    -- Check if player is already in bench
                    local existingCard = NextKey222.RosterBoard:FindCardByPlayerID(playerID)
                    if existingCard and existingCard.location == "bench" then
                        Debug:Dev("organizer", playerID, "already in bench - skipping duplicate add")
                    elseif NextKey222.RosterBoard.AddPlayerToBench then
                        NextKey222.RosterBoard:AddPlayerToBench(playerData)
                        Debug:Dev("organizer", "Added", playerID, "to bench (current character)")
                    end
                end
                
            else
                -- Alt selected
                Debug:Dev("organizer", playerID, "selected alt:", response.selectedCharacter)
                
                -- 1. Create temporary player card for alt
                local altPlayerData = self:BuildAltPlayerData(response)
                if NextKey222.RosterBoard and NextKey222.RosterBoard.AddPlayerToBench then
                    NextKey222.RosterBoard:AddPlayerToBench(altPlayerData)
                    Debug:Dev("organizer", "Added alt to bench:", response.selectedCharacter)
                end
                
                -- 2. Add main character to opt-out
                local mainPlayerData = self:BuildPlayerDataFromResponse(playerID, response)
                mainPlayerData.benchedForAlt = true
                if NextKey222.RosterBoard and NextKey222.RosterBoard.AddPlayerToOptOut then
                    NextKey222.RosterBoard:AddPlayerToOptOut(mainPlayerData)
                    Debug:Dev("organizer", "Added main to opt-out:", playerID)
                end
            end
        else
            -- Opted out - need to remove from bench first if present
            local playerData = self:BuildPlayerDataFromResponse(playerID, response)
            
            -- Remove from bench if present
            if NextKey222.RosterBoard and NextKey222.RosterBoard.RemovePlayerFromBench then
                NextKey222.RosterBoard:RemovePlayerFromBench(playerID)
                Debug:Dev("organizer", "Removed", playerID, "from bench before opt-out")
            end
            
            -- Add to opt-out section
            if NextKey222.RosterBoard and NextKey222.RosterBoard.AddPlayerToOptOut then
                NextKey222.RosterBoard:AddPlayerToOptOut(playerData)
                Debug:Dev("organizer", "Added", playerID, "to opt-out")
            end
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
    
    Debug:Dev("organizer", "Built alt player data for", playerData.name)
    
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