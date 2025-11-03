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
                -- Current character - check if already exists ANYWHERE before adding
                Debug:Dev("organizer", "Building player data for current character:", playerID)
                local playerData = self:BuildPlayerDataFromResponse(playerID, response)
                Debug:Dev("organizer", "Built playerData - has specPreferences:", playerData.specPreferences ~= nil)
                Debug:Dev("organizer", "Built playerData - has specDetails:", playerData.specDetails ~= nil)
                
                if NextKey222.RosterBoard then
                    -- CRITICAL FIX: Find card in ANY location (bench, slot, or opt-out)
                    local existingCard = NextKey222.RosterBoard:FindCardByPlayerID(playerID)
                    
                    if existingCard then
                        Debug:Dev("organizer", "Found existing card for", playerID, "at location:", existingCard.location)
                        Debug:Dev("organizer", "Updating", playerID, "in", existingCard.location, "with new spec preferences")
                        Debug:Dev("organizer", "New spec preferences:", playerData.specPreferences)
                        
                        -- CRITICAL FIX: Update existing card's playerData with new spec preferences
                        existingCard.playerData.specPreferences = playerData.specPreferences
                        existingCard.playerData.specDetails = playerData.specDetails  -- NEW: For tooltip display
                        existingCard.playerData.surveyResponse = playerData.surveyResponse
                        
                        -- DEBUG: Verify the data was copied correctly
                        Debug:Dev("organizer", "POST-UPDATE verification for", playerID, ":")
                        Debug:Dev("organizer", "  - existingCard.playerData.specPreferences:", existingCard.playerData.specPreferences ~= nil)
                        Debug:Dev("organizer", "  - existingCard.playerData.specDetails:", existingCard.playerData.specDetails ~= nil)
                        
                        if existingCard.playerData.specDetails then
                            Debug:Dev("organizer", "  - specDetails keys:")
                            for role, specs in pairs(existingCard.playerData.specDetails) do
                                Debug:Dev("organizer", "      -", role, ":", #specs, "specs")
                            end
                        else
                            Debug:Error("POST-UPDATE: existingCard.playerData.specDetails is NIL after assignment!")
                        end
                        
                        -- DEBUG: Log the spec preferences we're setting
                        Debug:Dev("organizer", "Setting spec preferences for", playerID, ":")
                        if playerData.specPreferences then
                            for role, preference in pairs(playerData.specPreferences) do
                                Debug:Dev("organizer", "  -", role, ":", preference)
                            end
                        else
                            Debug:Dev("organizer", "  - NO SPEC PREFERENCES IN RESPONSE")
                        end
                        
                        -- FIX #1: If card is in a slot, update IN PLACE (don't move to bench)
                        if type(existingCard.location) == "table" and existingCard.location.type == "role_slot" then
                            Debug:Dev("organizer", "Updating", playerID, "in slot with new spec preferences (staying in slot)")
                            Debug:Dev("organizer", "Card playerData.specPreferences after update:")
                            if existingCard.playerData.specPreferences then
                                for role, preference in pairs(existingCard.playerData.specPreferences) do
                                    Debug:Dev("organizer", "  -", role, ":", preference)
                                end
                            else
                                Debug:Dev("organizer", "  - CARD HAS NO SPEC PREFERENCES")
                            end
                            -- Update the card content to show multi-role icons
                            Debug:Dev("organizer", "CALLING UpdateCardContent for slot card:", playerID)
                            if NextKey222.PlayerCard and NextKey222.PlayerCard.UpdateCardContent then
                                NextKey222.PlayerCard:UpdateCardContent(existingCard, "expanded")
                                Debug:Dev("organizer", "UpdateCardContent COMPLETED for slot card:", playerID)
                            else
                                Debug:Error("PlayerCard.UpdateCardContent NOT AVAILABLE!")
                            end
                        elseif existingCard.location == "opt_out" then
                            Debug:Dev("organizer", "Moving", playerID, "from opt-out to bench (re-opted in)")
                            -- Use HandleCardDrop to properly move the card
                            local benchTarget = {type = "bench"}
                            NextKey222.RosterBoard:HandleCardDrop(existingCard, benchTarget)
                        else
                            -- Already in bench - just refresh display
                            Debug:Dev("organizer", "Updating", playerID, "in bench with new spec preferences")
                            Debug:Dev("organizer", "CALLING UpdateCardContent for bench card:", playerID)
                            if NextKey222.PlayerCard and NextKey222.PlayerCard.UpdateCardContent then
                                NextKey222.PlayerCard:UpdateCardContent(existingCard, "compact")
                                Debug:Dev("organizer", "UpdateCardContent COMPLETED for bench card:", playerID)
                            else
                                Debug:Error("PlayerCard.UpdateCardContent NOT AVAILABLE!")
                            end
                        end
                    else
                        -- Player doesn't exist anywhere - add to bench
                        if NextKey222.RosterBoard.AddPlayerToBench then
                            NextKey222.RosterBoard:AddPlayerToBench(playerData)
                            Debug:Dev("organizer", "Added", playerID, "to bench (current character)")
                        end
                    end
                end
                
            else
                -- FIX #2: Alt selected - prevent duplicate cards
                Debug:Dev("organizer", playerID, "selected alt:", response.selectedCharacter)
                
                if NextKey222.RosterBoard then
                    -- STEP 1: Check if alt card already exists
                    local altPlayerData = self:BuildAltPlayerData(response)
                    local existingAltCard = NextKey222.RosterBoard:FindCardByPlayerID(altPlayerData.id)
                    
                    if not existingAltCard then
                        -- Alt doesn't exist - create it
                        if NextKey222.RosterBoard.AddPlayerToBench then
                            NextKey222.RosterBoard:AddPlayerToBench(altPlayerData)
                            Debug:Dev("organizer", "Created new alt card in bench:", response.selectedCharacter)
                        end
                    else
                        Debug:Dev("organizer", "Alt card already exists - updating:", altPlayerData.id)
                        existingAltCard.playerData.specPreferences = altPlayerData.specPreferences
                        existingAltCard.playerData.specDetails = altPlayerData.specDetails  -- NEW: For tooltip display
                        
                        -- DEBUG: Verify alt data copy
                        Debug:Dev("organizer", "Alt POST-UPDATE - specDetails:", existingAltCard.playerData.specDetails ~= nil)
                        Debug:Dev("organizer", "CALLING UpdateCardContent for alt card:", altPlayerData.id)
                        if NextKey222.PlayerCard and NextKey222.PlayerCard.UpdateCardContent then
                            local displayMode = existingAltCard.location == "bench" and "compact" or "expanded"
                            NextKey222.PlayerCard:UpdateCardContent(existingAltCard, displayMode)
                            Debug:Dev("organizer", "UpdateCardContent COMPLETED for alt card:", altPlayerData.id)
                        else
                            Debug:Error("PlayerCard.UpdateCardContent NOT AVAILABLE!")
                        end
                    end
                    
                    -- STEP 2: Handle main character - MOVE to opt-out instead of creating new card
                    local existingMainCard = NextKey222.RosterBoard:FindCardByPlayerID(playerID)
                    
                    if existingMainCard then
                        Debug:Dev("organizer", "Found existing main card at:", existingMainCard.location, "- moving to opt-out")
                        
                        -- Update card data
                        local mainPlayerData = self:BuildPlayerDataFromResponse(playerID, response)
                        mainPlayerData.benchedForAlt = true
                        existingMainCard.playerData.benchedForAlt = true
                        existingMainCard.playerData.surveyResponse = mainPlayerData.surveyResponse
                        
                        -- Move to opt-out if not already there
                        if existingMainCard.location ~= "opt_out" then
                            local optOutTarget = {type = "opt_out"}
                            NextKey222.RosterBoard:HandleCardDrop(existingMainCard, optOutTarget)
                        else
                            Debug:Dev("organizer", "Main card already in opt-out - updating data")
                            if NextKey222.PlayerCard and NextKey222.PlayerCard.UpdateCardContent then
                                NextKey222.PlayerCard:UpdateCardContent(existingMainCard, "opt_out")
                            end
                        end
                    else
                        -- Main card doesn't exist - create new opt-out card
                        Debug:Dev("organizer", "Main card not found - creating new opt-out card")
                        local mainPlayerData = self:BuildPlayerDataFromResponse(playerID, response)
                        mainPlayerData.benchedForAlt = true
                        if NextKey222.RosterBoard.AddPlayerToOptOut then
                            NextKey222.RosterBoard:AddPlayerToOptOut(mainPlayerData)
                        end
                    end
                end
            end
        else
            -- Opted out - CRITICAL FIX: Check ALL locations before creating new card
            local playerData = self:BuildPlayerDataFromResponse(playerID, response)
            
            if NextKey222.RosterBoard then
                -- Find existing card in ANY location (bench, slot, or already in opt-out)
                local existingCard = NextKey222.RosterBoard:FindCardByPlayerID(playerID)
                
                if existingCard then
                    Debug:Dev("organizer", playerID, "already exists at location:", existingCard.location, "- moving to opt-out")
                    
                    -- Update card data with survey response
                    existingCard.playerData.surveyResponse = playerData.surveyResponse
                    
                    -- If already in opt-out, just update the card
                    if existingCard.location == "opt_out" then
                        Debug:Dev("organizer", playerID, "already in opt-out - updating data")
                        if NextKey222.PlayerCard and NextKey222.PlayerCard.UpdateCardContent then
                            NextKey222.PlayerCard:UpdateCardContent(existingCard, "opt_out")
                        end
                    else
                        -- Move from current location (bench or slot) to opt-out
                        Debug:Dev("organizer", "Moving", playerID, "from", existingCard.location, "to opt-out")
                        local optOutTarget = {type = "opt_out"}
                        NextKey222.RosterBoard:HandleCardDrop(existingCard, optOutTarget)
                    end
                else
                    -- Player doesn't exist anywhere - create new card in opt-out
                    if NextKey222.RosterBoard.AddPlayerToOptOut then
                        NextKey222.RosterBoard:AddPlayerToOptOut(playerData)
                        Debug:Dev("organizer", "Created new opt-out card for", playerID)
                    end
                end
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