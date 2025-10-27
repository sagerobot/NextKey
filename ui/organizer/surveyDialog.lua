-- MARK: Module Definition
local _, NextKey222 = ...

local SurveyDialog = {}
NextKey222.SurveyDialog = SurveyDialog
NextKey222.RegisterModule("SurveyDialog", SurveyDialog)

local AceGUI = LibStub("AceGUI-3.0")
local Debug = NextKey222.Debug

-- MARK: Module State
SurveyDialog.activeDialog = nil

-- MARK: Initialization
function SurveyDialog:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "Initializing Survey Dialog module")
        Debug:Dev("organizer", "Survey Dialog initialized successfully")
        return true
    end, "SurveyDialog:Initialize")
end

-- MARK: Main Dialog Creation
function SurveyDialog:Show(pollData)
    return NextKey222.SafeRun(function()
        -- Close existing dialog if open
        if self.activeDialog then
            AceGUI:Release(self.activeDialog)
            self.activeDialog = nil
        end
        
        -- Create dialog frame
        local dialog = AceGUI:Create("Frame")
        dialog:SetTitle("M+ Group Organizer - Poll")
        dialog:SetWidth(500)
        dialog:SetHeight(600)
        dialog:SetLayout("Flow")
        
        -- Store poll metadata
        dialog.pollID = pollData.pollID
        dialog.organizerName = pollData.organizerName
        
        -- Set callback for close button
        dialog:SetCallback("OnClose", function(widget)
            AceGUI:Release(widget)
            self.activeDialog = nil
        end)
        
        -- Build all sections
        self:AddInstructionSection(dialog)
        self:AddParticipationSection(dialog)
        self:AddCharacterSelectionSection(dialog)
        self:AddRoleSelectionSection(dialog)
        self:AddButtonSection(dialog)
        
        -- Force layout refresh to render all widgets
        dialog:DoLayout()
        
        -- Store reference
        self.activeDialog = dialog
        
        -- CRITICAL: Show the dialog (AceGUI Frames are hidden by default)
        dialog:Show()
        
        Debug:Dev("organizer", "Showed survey dialog for poll:", pollData.pollID)
        
    end, "SurveyDialog:Show")
end

-- MARK: Instruction Section
function SurveyDialog:AddInstructionSection(dialog)
    local instructions = AceGUI:Create("Label")
    instructions:SetText("The raid leader is organizing M+ groups. Please indicate your participation preferences.")
    instructions:SetFullWidth(true)
    -- Remove SetFont call - AceGUI Labels don't use this method the same way
    dialog:AddChild(instructions)
    
    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    dialog:AddChild(spacer)
end

-- MARK: Participation Section
function SurveyDialog:AddParticipationSection(dialog)
    local header = AceGUI:Create("Heading")
    header:SetText("1. Participation")
    header:SetFullWidth(true)
    dialog:AddChild(header)
    
    -- Opt-in checkbox
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
    
    -- Opt-out checkbox
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
    
    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    dialog:AddChild(spacer)
end

-- MARK: Character Selection Section
function SurveyDialog:AddCharacterSelectionSection(dialog)
    local header = AceGUI:Create("Heading")
    header:SetText("2. Character Selection")
    header:SetFullWidth(true)
    dialog:AddChild(header)
    dialog.charHeader = header
    
    -- Get all characters from storage
    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    local charList = self:BuildCharacterList()
    
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
    
    -- Alt warning label
    local altWarning = AceGUI:Create("Label")
    altWarning:SetText("")
    altWarning:SetFullWidth(true)
    -- Remove SetFont call - AceGUI Labels don't use this method
    dialog:AddChild(altWarning)
    dialog.altWarning = altWarning
    
    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    dialog:AddChild(spacer)
end

-- MARK: Role Selection Section
function SurveyDialog:AddRoleSelectionSection(dialog)
    local header = AceGUI:Create("Heading")
    header:SetText("3. Role Preferences")
    header:SetFullWidth(true)
    dialog:AddChild(header)
    dialog.roleHeader = header
    
    -- Get available roles for current character
    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    local availableRoles = self:GetAvailableRolesForCharacter(currentChar)
    
    -- Create role preference widgets
    dialog.rolePreferences = {}
    dialog.roleWidgets = {}
    
    for _, role in ipairs({"Tank", "Healer", "DPS"}) do
        if availableRoles[role] then
            local roleGroup = self:CreateRolePreferenceWidget(dialog, role)
            dialog:AddChild(roleGroup)
            table.insert(dialog.roleWidgets, roleGroup)
        end
    end
    
    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    dialog:AddChild(spacer)
end

-- MARK: Role Preference Widget
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

-- MARK: Button Section
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
    
    -- Force layout on button group
    buttonGroup:DoLayout()
    
    dialog:AddChild(buttonGroup)
end

-- MARK: Event Handlers
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

function SurveyDialog:UpdateRoleSelectionForCharacter(dialog, charID)
    -- Get available roles for selected character
    local availableRoles = self:GetAvailableRolesForCharacter(charID)
    
    -- Clear existing role widgets
    if dialog.roleWidgets then
        for _, widget in ipairs(dialog.roleWidgets) do
            widget:Release()
        end
    end
    dialog.roleWidgets = {}
    dialog.rolePreferences = {}
    
    -- Recreate role widgets based on character's roles
    for _, role in ipairs({"Tank", "Healer", "DPS"}) do
        if availableRoles[role] then
            local roleGroup = self:CreateRolePreferenceWidget(dialog, role)
            dialog:AddChild(roleGroup)
            table.insert(dialog.roleWidgets, roleGroup)
        end
    end
    
    Debug:Dev("organizer", "Updated role selection for:", charID)
end

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
                local altData = self:GetCharacterData(response.selectedCharacter)
                response.characterData = {
                    name = altData.name,
                    realm = altData.realm,
                    class = altData.class,
                    keystone = altData.currentKeystone,
                    scores = altData.dungeonScores,
                    overallScore = altData.overallScore,
                    availableRoles = altData.availableRoles,
                    utilities = altData.utilities,
                    specName = altData.specName
                }
            end
        end
        
        -- Check if we're the organizer - if so, process response directly
        local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
        if currentPlayer == dialog.organizerName then
            -- We're the organizer - process our own response directly
            Debug:Dev("organizer", "Organizer submitting own response - processing directly")
            if NextKey222.ParticipantSurvey then
                NextKey222.ParticipantSurvey:ProcessResponse(currentPlayer, response)
            end
            -- Also update poll progress
            if NextKey222.RosterBoard and NextKey222.RosterBoard.UpdatePollProgress then
                -- Add to responses list
                if NextKey222.RosterBoard.activePoll then
                    table.insert(NextKey222.RosterBoard.activePoll.responses, {
                        sender = currentPlayer,
                        response = response,
                        timestamp = GetTime()
                    })
                end
                NextKey222.RosterBoard:UpdatePollProgress()
            end
        else
            -- We're a participant - send response to organizer
            if NextKey222.ParticipantSurvey then
                NextKey222.ParticipantSurvey:SendPollResponse(response, dialog.organizerName)
            end
        end
        
        -- Close dialog - only hide, don't release (parent will release)
        if dialog then
            dialog:Hide()
        end
        self.activeDialog = nil
        
        Debug:Dev("organizer", "Submitted poll response - opted in:", response.optedIn)
        
    end, "SurveyDialog:OnSubmitClicked")
end

function SurveyDialog:OnCancelClicked(dialog)
    Debug:Dev("organizer", "Survey dialog cancelled")
    dialog:Hide()
    AceGUI:Release(dialog)
    self.activeDialog = nil
end

function SurveyDialog:ShowCharacterAndRoleSelections(dialog)
    -- Show character selection widgets using frame.frame:Show()
    if dialog.charHeader and dialog.charHeader.frame then dialog.charHeader.frame:Show() end
    if dialog.charDropdown and dialog.charDropdown.frame then dialog.charDropdown.frame:Show() end
    if dialog.altWarning and dialog.altWarning.frame then dialog.altWarning.frame:Show() end
    
    -- Show role selection widgets
    if dialog.roleHeader and dialog.roleHeader.frame then dialog.roleHeader.frame:Show() end
    if dialog.roleWidgets then
        for _, widget in ipairs(dialog.roleWidgets) do
            if widget and widget.frame then
                widget.frame:Show()
            end
        end
    end
end

function SurveyDialog:HideCharacterAndRoleSelections(dialog)
    -- Hide character selection widgets using frame.frame:Hide()
    if dialog.charHeader and dialog.charHeader.frame then dialog.charHeader.frame:Hide() end
    if dialog.charDropdown and dialog.charDropdown.frame then dialog.charDropdown.frame:Hide() end
    if dialog.altWarning and dialog.altWarning.frame then dialog.altWarning.frame:Hide() end
    
    -- Hide role selection widgets
    if dialog.roleHeader and dialog.roleHeader.frame then dialog.roleHeader.frame:Hide() end
    if dialog.roleWidgets then
        for _, widget in ipairs(dialog.roleWidgets) do
            if widget and widget.frame then
                widget.frame:Hide()
            end
        end
    end
end

-- MARK: Helper Functions
function SurveyDialog:BuildCharacterList()
    local charList = {}
    
    -- Get all characters from CharacterStorage
    if NextKey222.CharacterStorage then
        local characters = NextKey222.CharacterStorage:GetAllCharacters()
        for charID, charData in pairs(characters) do
            local keystoneText = "No Key"
            if charData.currentKeystone then
                local dungeon = "???"
                if NextKey222.DungeonNameService then
                    dungeon = NextKey222.DungeonNameService:GetAlias(charData.currentKeystone.dungeonID)
                end
                keystoneText = dungeon .. ": +" .. charData.currentKeystone.level
            end
            
            local displayText = charData.name .. " - " .. charData.class .. " (" .. keystoneText .. ")"
            charList[charID] = displayText
        end
    end
    
    -- Always include current character
    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    if not charList[currentChar] then
        local class = select(2, UnitClass("player"))
        charList[currentChar] = currentChar:match("^([^%-]+)") .. " - " .. class .. " (Current)"
    end
    
    return charList
end

function SurveyDialog:GetAvailableRolesForCharacter(charID)
    -- Get roles from CharacterStorage or current player
    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    
    if charID == currentChar then
        -- Get current player's roles from ProfilesService
        local profile = NextKey222.ProfilesService and NextKey222.ProfilesService:GetOrganizerProfile(charID)
        if profile and profile.roles then
            local roles = {}
            for _, role in ipairs(profile.roles) do
                local normalizedRole = role:upper()
                if normalizedRole == "TANK" then
                    roles.Tank = true
                elseif normalizedRole == "HEALER" then
                    roles.Healer = true
                else
                    roles.DPS = true
                end
            end
            return roles
        end
    else
        -- Get alt's roles from CharacterStorage
        if NextKey222.CharacterStorage then
            local charData = NextKey222.CharacterStorage:GetCharacter(charID)
            if charData and charData.availableRoles then
                return charData.availableRoles
            end
        end
    end
    
    -- Fallback: return DPS only
    return {DPS = true}
end

function SurveyDialog:GetCharacterData(charID)
    -- Get character data from CharacterStorage
    if NextKey222.CharacterStorage then
        local charData = NextKey222.CharacterStorage:GetCharacter(charID)
        if charData then
            return charData
        end
    end
    
    -- Fallback: return minimal data
    return {
        name = charID:match("^([^%-]+)") or charID,
        realm = GetRealmName(),
        class = "WARRIOR",
        availableRoles = {DPS = true}
    }
end