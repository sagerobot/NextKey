# M+ Group Organizer - Phase 2: Participant Survey

**Version:** 1.0  
**Status:** Implementation Ready  
**Dependencies:** Phase 0 (Foundation), Phase 0.5 (Integration), Phase 1 (UI Framework)  
**Estimated Complexity:** Medium  
**Implementation Priority:** HIGH - Required for data collection

---

## Overview

This phase implements the participant polling system - the mechanism by which the Organizer gathers participation intent, character selection, and role preferences from all raid members with the addon.

**Key Deliverables:**
1. Poll request trigger mechanism
2. Survey popup UI for participants
3. Response collection and processing
4. Automatic roster board population
5. Integration with auto-detection system

---

## 1. Survey Trigger System

### 1.1 Poll Group Button Handler

**File:** `ui/organizer/rosterBoard.lua` (extend from Phase 1)

```lua
function RosterBoard:OnPollGroupClicked()
    return NextKey222.SafeRun(function(
        -- Validate we're in a group
        local groupSize = GetNumGroupMembers()
        if groupSize < 2 then
            Debug:User("You must be in a group to poll members")
            return
        end
        
        -- Generate unique poll ID
        local pollID = self:GeneratePollID()
        
        -- Store poll state
        self.activePoll = {
            id = pollID,
            startTime = GetTime(),
            responses = {},
            timeout = 60 -- seconds
        }
        
        -- Send poll request to all members
        NextKey222.ParticipantSurvey:SendPollRequest(pollID)
        
        -- Simultaneously trigger auto-detection
        self:RunAutoDetection()
        
        -- Start timeout timer
        self:StartPollTimeout()
        
        -- Update UI
        self:ShowPollInProgress()
        
        Debug:Dev("organizer", "Started poll with ID:", pollID)
        
    end, "RosterBoard:OnPollGroupClicked")
end

function RosterBoard:GeneratePollID()
    -- Create unique ID: Timestamp + Random
    return tostring(time()) .. "-" .. tostring(math.random(1000, 9999))
end

function RosterBoard:RunAutoDetection()
    -- Use auto-detection from Phase 0
    local nonAddonPlayers = NextKey222.OrganizerAutoDetection:ScanForNonAddonPlayers()
    
    -- Add to bench immediately with indicator
    for _, playerData in ipairs(nonAddonPlayers) do
        self:AddPlayerToBench(playerData)
    end
    
    Debug:Dev("organizer", "Auto-detected", #nonAddonPlayers, "non-addon players")
end

function RosterBoard:StartPollTimeout()
    self.pollTimeoutTimer = C_Timer.NewTimer(60, function()
        self:OnPollTimeout()
    end)
end

function RosterBoard:OnPollTimeout()
    Debug:User("Poll timeout reached. Processing responses...")
    self:CompletePoll()
end

function RosterBoard:ShowPollInProgress()
    -- Disable poll button
    if self.pollButton then
        self.pollButton:SetDisabled(true)
        self.pollButton:SetText("Polling... (0/" .. GetNumGroupMembers() .. ")")
    end
end
```

---

## 2. Communication Layer

### 2.1 Poll Request Message

**File:** `core/organizer/survey.lua` (NEW)

```lua
-- MARK: Module Definition
local ParticipantSurvey = {}
NextKey222.ParticipantSurvey = ParticipantSurvey
NextKey222.RegisterModule("ParticipantSurvey", ParticipantSurvey)

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
        
        Debug:Dev("organizer", "Sent poll request to RAID")
        
    end, "ParticipantSurvey:SendPollRequest")
end

function ParticipantSurvey:OnPollRequestReceived(message, sender)
    return NextKey222.SafeRun(function()
        -- Only show survey if we're not the organizer
        if sender == UnitName("player") .. "-" .. GetRealmName() then
            return
        end
        
        -- Show survey dialog
        self:ShowSurveyDialog(message.data)
        
        Debug:Dev("organizer", "Received poll request from", sender)
        
    end, "ParticipantSurvey:OnPollRequestReceived")
end
```

---

## 3. Survey Dialog UI

### 3.1 Main Dialog Structure

**File:** `ui/organizer/surveyDialog.lua` (NEW)

```lua
-- MARK: Module Definition
local SurveyDialog = {}
NextKey222.SurveyDialog = SurveyDialog
NextKey222.RegisterModule("SurveyDialog", SurveyDialog)

local AceGUI = LibStub("AceGUI-3.0")

function SurveyDialog:Show(pollData)
    return NextKey222.SafeRun(function()
        -- Create dialog frame
        local dialog = AceGUI:Create("Frame")
        dialog:SetTitle("M+ Group Organizer - Poll")
        dialog:SetWidth(500)
        dialog:SetHeight(600)
        dialog:SetLayout("Flow")
        
        -- Store poll ID
        dialog.pollID = pollData.pollID
        dialog.organizerName = pollData.organizerName
        
        -- Build sections
        self:AddInstructionSection(dialog)
        self:AddParticipationSection(dialog)
        self:AddCharacterSelectionSection(dialog)
        self:AddRoleSelectionSection(dialog)
        self:AddButtonSection(dialog)
        
        -- Store reference
        self.activeDialog = dialog
        
        Debug:Dev("organizer_ui", "Showed survey dialog")
        
    end, "SurveyDialog:Show")
end

function SurveyDialog:AddInstructionSection(dialog)
    local instructions = AceGUI:Create("Label")
    instructions:SetText("The raid leader is organizing M+ groups. Please indicate your participation preferences.")
    instructions:SetFullWidth(true)
    instructions:SetFont(GameFontNormal)
    dialog:AddChild(instructions)
    
    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    dialog:AddChild(spacer)
end

function SurveyDialog:AddParticipationSection(dialog)
    local header = AceGUI:Create("Heading")
    header:SetText("1. Participation")
    header:SetFullWidth(true)
    dialog:AddChild(header)
    
    -- Radio button group (simulated with checkboxes)
    local optInCheckbox = AceGUI:Create("CheckBox")
    optInCheckbox:SetLabel("I want to participate")
    optInCheckbox:SetValue(true)
    optInCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        if value then
            dialog.optOutCheckbox:SetValue(false)
            self:ShowCharacterAndRoleSelections(dialog)
        end
    end)
    dialog:AddChild(optInCheckbox)
    dialog.optInCheckbox = optInCheckbox
    
    local optOutCheckbox = AceGUI:Create("CheckBox")
    optOutCheckbox:SetLabel("I do NOT want to participate")
    optOutCheckbox:SetValue(false)
    optOutCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
        if value then
            dialog.optInCheckbox:SetValue(false)
            self:HideCharacterAndRoleSelections(dialog)
        end
    end)
    dialog:AddChild(optOutCheckbox)
    dialog.optOutCheckbox = optOutCheckbox
end

function SurveyDialog:AddCharacterSelectionSection(dialog)
    local header = AceGUI:Create("Heading")
    header:SetText("2. Character Selection")
    header:SetFullWidth(true)
    dialog:AddChild(header)
    
    -- Get all characters from storage
    local characters = NextKey222.CharacterStorage:GetAllCharacters()
    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    
    -- Build character list with keystones
    local charList = {}
    for charID, charData in pairs(characters) do
        local keystoneText = "No Key"
        if charData.currentKeystone then
            local dungeon = NextKey222.Utils:GetDungeonAbbreviation(charData.currentKeystone.dungeonID)
            keystoneText = dungeon .. ": +" .. charData.currentKeystone.level
        end
        
        local displayText = charData.name .. " - " .. charData.class .. " (" .. keystoneText .. ")"
        charList[charID] = displayText
    end
    
    -- Dropdown for character selection
    local charDropdown = AceGUI:Create("Dropdown")
    charDropdown:SetLabel("Select Character:")
    charDropdown:SetList(charList)
    charDropdown:SetValue(currentChar)
    charDropdown:SetFullWidth(true)
    charDropdown:SetCallback("OnValueChanged", function(widget, event, value)
        dialog.selectedCharacter = value
        self:OnCharacterChanged(dialog, value)
    end)
    dialog:AddChild(charDropdown)
    dialog.charDropdown = charDropdown
    dialog.selectedCharacter = currentChar
    
    -- Info label for alt selection
    local altWarning = AceGUI:Create("Label")
    altWarning:SetText("|cFFFFAA00Note: Selecting an alt will bench your current character.|r")
    altWarning:SetFullWidth(true)
    altWarning:SetFont(GameFontNormalSmall)
    dialog:AddChild(altWarning)
    dialog.altWarning = altWarning
    dialog.altWarning:SetText("") -- Hidden by default
end

function SurveyDialog:OnCharacterChanged(dialog, selectedCharID)
    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    
    if selectedCharID ~= currentChar then
        -- Show alt warning
        dialog.altWarning:SetText("|cFFFFAA00Note: Your current character will be moved to 'Opted Out'.|r")
        
        -- Update role selection to show alt's roles
        self:UpdateRoleSelectionForCharacter(dialog, selectedCharID)
    else
        dialog.altWarning:SetText("")
        self:UpdateRoleSelectionForCharacter(dialog, currentChar)
    end
end

function SurveyDialog:AddRoleSelectionSection(dialog)
    local header = AceGUI:Create("Heading")
    header:SetText("3. Role Preferences")
    header:SetFullWidth(true)
    dialog:AddChild(header)
    
    -- Get available roles for current character
    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    local charData = NextKey222.CharacterStorage:GetCharacter(currentChar)
    local availableRoles = charData and charData.availableRoles or {}
    
    -- Role preference selectors
    dialog.rolePreferences = {}
    
    for _, role in ipairs({"Tank", "Healer", "DPS"}) do
        if availableRoles[role] then
            local roleGroup = self:CreateRolePreferenceWidget(dialog, role)
            dialog:AddChild(roleGroup)
        end
    end
end

function SurveyDialog:CreateRolePreferenceWidget(dialog, role)
    local group = AceGUI:Create("InlineGroup")
    group:SetTitle(role)
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    
    -- Preference dropdown
    local prefDropdown = AceGUI:Create("Dropdown")
    prefDropdown:SetLabel("Preference:")
    prefDropdown:SetList({
        will_play = "Will Play",
        fill = "Fill (if needed)"
    })
    prefDropdown:SetValue("will_play")
    prefDropdown:SetWidth(200)
    group:AddChild(prefDropdown)
    
    -- Store reference
    dialog.rolePreferences[role] = prefDropdown
    
    return group
end

function SurveyDialog:UpdateRoleSelectionForCharacter(dialog, charID)
    -- Clear existing role widgets
    -- Rebuild with new character's roles
    -- (Implementation details...)
end

function SurveyDialog:AddButtonSection(dialog)
    local buttonGroup = AceGUI:Create("SimpleGroup")
    buttonGroup:SetFullWidth(true)
    buttonGroup:SetLayout("Flow")
    
    -- Submit button
    local submitButton = AceGUI:Create("Button")
    submitButton:SetText("Submit Response")
    submitButton:SetWidth(150)
    submitButton:SetCallback("OnClick", function()
        self:OnSubmitClicked(dialog)
    end)
    buttonGroup:AddChild(submitButton)
    
    -- Cancel button
    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(100)
    cancelButton:SetCallback("OnClick", function()
        self:OnCancelClicked(dialog)
    end)
    buttonGroup:AddChild(cancelButton)
    
    dialog:AddChild(buttonGroup)
end
```

---

## 4. Response Processing

### 4.1 Submit Handler

```lua
function SurveyDialog:OnSubmitClicked(dialog)
    return NextKey222.SafeRun(function()
        -- Validate response
        if not dialog.optInCheckbox:GetValue() and not dialog.optOutCheckbox:GetValue() then
            Debug:User("Please select whether you want to participate")
            return
        end
        
        -- Build response data
        local response = {
            pollID = dialog.pollID,
            optedIn = dialog.optInCheckbox:GetValue(),
            selectedCharacter = dialog.selectedCharacter,
            rolePreferences = {}
        }
        
        if response.optedIn then
            -- Collect role preferences
            for role, dropdown in pairs(dialog.rolePreferences) do
                response.rolePreferences[role] = dropdown:GetValue()
            end
            
            -- Include character data if alt selected
            local currentChar = UnitName("player") .. "-" .. GetRealmName()
            if response.selectedCharacter ~= currentChar then
                local altData = NextKey222.CharacterStorage:GetCharacter(response.selectedCharacter)
                response.characterData = {
                    name = altData.name,
                    realm = altData.realm,
                    class = altData.class,
                    keystone = altData.currentKeystone,
                    scores = altData.dungeonScores,
                    overallScore = altData.overallScore,
                    availableRoles = altData.availableRoles,
                    utilities = altData.utilities
                }
            end
        end
        
        -- Send response
        NextKey222.ParticipantSurvey:SendPollResponse(response, dialog.organizerName)
        
        -- Close dialog
        dialog:Hide()
        self.activeDialog = nil
        
        Debug:Dev("organizer", "Submitted poll response")
        
    end, "SurveyDialog:OnSubmitClicked")
end
```

### 4.2 Response Reception and Processing

**File:** `core/organizer/survey.lua`

```lua
function ParticipantSurvey:SendPollResponse(response, organizerName)
    NextKey222.Communications:SendOrganizerMessage(
        "ORG_POLL_RESPONSE",
        response,
        "WHISPER",
        organizerName
    )
end

function ParticipantSurvey:OnPollResponseReceived(message, sender)
    return NextKey222.SafeRun(function()
        local response = message.data
        
        -- Validate poll ID
        if not NextKey222.RosterBoard.activePoll or 
           NextKey222.RosterBoard.activePoll.id ~= response.pollID then
            Debug:Dev("organizer", "Received response for inactive poll, ignoring")
            return
        end
        
        -- Store response
        table.insert(NextKey222.RosterBoard.activePoll.responses, {
            sender = sender,
            response = response,
            timestamp = GetTime()
        })
        
        -- Process response immediately
        self:ProcessResponse(sender, response)
        
        -- Update UI
        NextKey222.RosterBoard:UpdatePollProgress()
        
        Debug:Dev("organizer", "Received poll response from", sender)
        
    end, "ParticipantSurvey:OnPollResponseReceived")
end

function ParticipantSurvey:ProcessResponse(playerID, response)
    if response.optedIn then
        if response.selectedCharacter == playerID then
            -- Current character, add to bench
            local playerData = self:BuildPlayerDataFromResponse(playerID, response)
            NextKey222.RosterBoard:AddPlayerToBench(playerData)
        else
            -- Alt selected
            -- 1. Create temporary player card for alt
            local altPlayerData = self:BuildAltPlayerData(response)
            NextKey222.RosterBoard:AddPlayerToBench(altPlayerData)
            
            -- 2. Create card for main character in opt-out
            local mainPlayerData = self:BuildPlayerDataFromResponse(playerID, response)
            mainPlayerData.benchedForAlt = true
            NextKey222.RosterBoard:AddPlayerToOptOut(mainPlayerData)
        end
    else
        -- Opted out, add to opt-out row
        local playerData = self:BuildPlayerDataFromResponse(playerID, response)
        NextKey222.RosterBoard:AddPlayerToOptOut(playerData)
    end
end

function ParticipantSurvey:BuildPlayerDataFromResponse(playerID, response)
    -- Use ProfilesService to get base data
    local profile = NextKey222.ProfilesService:GetOrganizerProfile(playerID)
    
    -- Enhance with survey response
    profile.surveyResponse = {
        optedIn = response.optedIn,
        selectedCharacter = response.selectedCharacter,
        rolePreferences = response.rolePreferences,
        timestamp = GetTime()
    }
    
    profile.dataSource = "addon"
    profile.hasAddon = true
    
    return profile
end

function ParticipantSurvey:BuildAltPlayerData(response)
    -- Use character data from response
    local altData = response.characterData
    
    return {
        id = response.selectedCharacter .. "_TEMP",
        name = altData.name,
        realm = altData.realm,
        class = altData.class,
        roles = self:ExtractRoles(altData.availableRoles),
        utilities = altData.utilities,
        keystone = altData.keystone,
        scores = altData.scores,
        overallScore = altData.overallScore,
        preferences = {}, -- Use source character's preferences
        
        -- Temporary flags
        isTemporary = true,
        sourceCharacter = response.selectedCharacter,
        dataSource = "temporary",
        hasAddon = true,
        
        -- Survey response
        surveyResponse = {
            rolePreferences = response.rolePreferences
        }
    }
end

function ParticipantSurvey:ExtractRoles(availableRoles)
    local roles = {}
    for role, enabled in pairs(availableRoles) do
        if enabled then
            table.insert(roles, role)
        end
    end
    return roles
end
```

---

## 5. Poll Progress Tracking

```lua
function RosterBoard:UpdatePollProgress()
    local totalMembers = GetNumGroupMembers()
    local responses = #self.activePoll.responses
    
    -- Update button text
    if self.pollButton then
        self.pollButton:SetText("Polling... (" .. responses .. "/" .. totalMembers .. ")")
    end
    
    -- Check if complete
    if responses >= totalMembers - 1 then -- -1 for organizer
        self:CompletePoll()
    end
end

function RosterBoard:CompletePoll()
    if not self.activePoll then return end
    
    -- Cancel timeout timer
    if self.pollTimeoutTimer then
        self.pollTimeoutTimer:Cancel()
        self.pollTimeoutTimer = nil
    end
    
    -- Re-enable poll button
    if self.pollButton then
        self.pollButton:SetDisabled(false)
        self.pollButton:SetText("Poll Group")
    end
    
    -- Show completion message
    local totalResponses = #self.activePoll.responses
    local totalMembers = GetNumGroupMembers() - 1
    
    Debug:User("Poll complete: " .. totalResponses .. "/" .. totalMembers .. " members responded")
    
    -- Clear active poll
    self.activePoll = nil
end
```

---

## 6. Integration with Roster Board

### 6.1 Adding Players to Bench

```lua
function RosterBoard:AddPlayerToBench(playerData)
    return NextKey222.SafeRun(function()
        -- Create player card
        local playerCard = NextKey222.PlayerCard:AcquireCard(playerData, "bench")
        
        -- Add to bench scroll container
        self.benchColumn.scrollContainer:AddChild(playerCard)
        table.insert(self.benchColumn.playerCards, playerCard)
        
        -- Add visual indicator if auto-detected
        if playerData.dataSource == "auto-detected" then
            self:AddAutoDetectedIndicator(playerCard)
        end
        
        Debug:Dev("organizer_ui", "Added player to bench:", playerData.name)
        
    end, "RosterBoard:AddPlayerToBench")
end

function RosterBoard:AddPlayerToOptOut(playerData)
    return NextKey222.SafeRun(function()
        -- Create player card
        local playerCard = NextKey222.PlayerCard:AcquireCard(playerData, "opt_out")
        
        -- Add to opt-out scroll container
        self.optOutSection.scrollFrame:AddChild(playerCard)
        table.insert(self.optOutSection.playerCards, playerCard)
        
        Debug:Dev("organizer_ui", "Added player to opt-out:", playerData.name)
        
    end, "RosterBoard:AddPlayerToOptOut")
end

function RosterBoard:AddAutoDetectedIndicator(playerCard)
    -- Add small icon to card indicating no addon
    local icon = AceGUI:Create("Icon")
    icon:SetImage("Interface\\FriendsFrame\\Battlenet-WoWicon")
    icon:SetImageSize(12, 12)
    icon:SetCallback("OnEnter", function()
        GameTooltip:SetOwner(icon.frame, "ANCHOR_RIGHT")
        GameTooltip:AddLine("This player does not have NextKey installed")
        GameTooltip:AddLine("Their data was gathered from game APIs", 1, 1, 1)
        GameTooltip:Show()
    end)
    icon:SetCallback("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    playerCard:AddChild(icon)
end
```

---

## 7. Testing Strategy

### 7.1 Test Suite

**File:** `debug/organizer_survey_tests.lua` (NEW)

```lua
function TestSurveyDialog()
    -- Test dialog creation
    -- Verify all sections present
    -- Test opt-in/opt-out radio behavior
end

function TestCharacterSelection()
    -- Test with multiple alts
    -- Verify keystone display
    -- Test alt warning message
end

function TestRoleSelection()
    -- Test with single-role character
    -- Test with multi-role character
    -- Verify preference dropdowns
end

function TestResponseSubmission()
    -- Test opt-in response
    -- Test opt-out response
    -- Test alt selection response
    -- Verify message sending
end

function TestResponseProcessing()
    -- Test bench population
    -- Test opt-out population
    -- Test temporary player card creation
    -- Verify auto-detection integration
end

function TestPollProgress()
    -- Test progress tracking
    -- Test timeout handling
    -- Test completion detection
end
```

---

## 8. Implementation Checklist

- [ ] Create `core/organizer/survey.lua` module
- [ ] Create `ui/organizer/surveyDialog.lua` module
- [ ] Implement poll request trigger in RosterBoard
- [ ] Build survey dialog UI with all sections
- [ ] Implement character selection dropdown
- [ ] Build role preference widgets
- [ ] Create response validation logic
- [ ] Implement response submission handler
- [ ] Build response processing system
- [ ] Implement temporary player card creation
- [ ] Add poll progress tracking
- [ ] Implement poll timeout system
- [ ] Add auto-detection integration
- [ ] Create visual indicators for auto-detected players
- [ ] Write test suite
- [ ] Test with various response scenarios
- [ ] Test alt selection workflow
- [ ] Test timeout handling
- [ ] Update `NextKey.toc` with new files

---

## 9. Known Issues & Edge Cases

1. **Stale Character Data**: Alt data may be outdated if not logged in recently
2. **Survey Timeout**: Some players may miss the 60-second window
3. **Multiple Polls**: Need to handle accidental double-polling
4. **Response Conflicts**: Player responds twice (keep latest)
5. **Dialog Dismissal**: Player closes without submitting (counts as no response)

---

**Document Status:** Complete  
**Ready for Implementation:** Yes  
**Blockers:** Phase 0, 0.5, and 1 must complete first  
**Next Document:** Phase 3 - Manual Mode