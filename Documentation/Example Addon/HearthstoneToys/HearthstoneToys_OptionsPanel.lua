-- HearthstoneToys_OptionsPanel.lua
-- print("HearthstoneToys_OptionsPanel.lua")

-- Access the addon namespace
local addonName, addon = ...

-- Ensure the Options Panel module is part of the addon namespace
addon.OptionsPanel = {}

-- Local reference
local addonName = addon.CONST.ADDON_DISPLAY_NAME
addon.OptionsPanel.optionsCategoryId = nil -- Initialize as nil
addon.xPositionInput = nil
addon.yPositionInput = nil
    
-----------------------------------
-- Function to create Options Panel
-----------------------------------
function addon.OptionsPanel.Initialize()
    if addon.DEBUG then
        addon.DebugPrint("addon.OptionsPanel.Initialize called")
    end

    local optionsPanel = CreateFrame("Frame", addon.CONST.ADDON_NAME .. "OptionsPanel", InterfaceOptionsFramePanelContainer)
    optionsPanel.name = addonName

    -- Create a scrollable content area
    local scrollFrame = CreateFrame("ScrollFrame", addon.CONST.ADDON_NAME .. "ScrollFrame", optionsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 0, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -30, 10)

    -- Create a frame to hold the actual content
    local content = CreateFrame("Frame", addon.CONST.ADDON_NAME .. "ScrollFrameContent", scrollFrame)
    content:SetSize(640, 800) -- Adjust size as needed
    scrollFrame:SetScrollChild(content)

    -- Create a title for the options panel
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(addon.CONST.ADDON_DISPLAY_NAME .. " Options")

    -- Call the function to create the Defaults button
    addon.OptionsPanel.CreateResetDatabaseButton(content)

    local line = content:CreateTexture(nil, "ARTWORK")
    line:SetHeight(2) -- Thickness of the line
    line:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, -8) -- Stretch to match panel width

    -- Section 1: General Settings
    local generalSettingsHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    generalSettingsHeader:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -30)
    generalSettingsHeader:SetText("General Settings")

    -- Add checkbox for the welcome message
    local showWelcomeMessageCheckbox = CreateFrame("CheckButton", addon.CONST.ADDON_NAME .. "ShowWelcomeMessageCheckbox", content, "ChatConfigCheckButtonTemplate")
    showWelcomeMessageCheckbox:SetPoint("TOPLEFT", generalSettingsHeader, "BOTTOMLEFT", 20, -8)
    showWelcomeMessageCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.showWelcomeMessage)
    showWelcomeMessageCheckbox:SetScript("OnClick", function(self)
        _G[addon.CONST.DB_NAME].generalSettings.showWelcomeMessage = self:GetChecked()
    end)
    addon.generalSettingsCheckbox = showWelcomeMessageCheckbox -- Store reference
    local showWelcomeMessageLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showWelcomeMessageLabel:SetPoint("LEFT", showWelcomeMessageCheckbox, "RIGHT", 5, 0)
    showWelcomeMessageLabel:SetText("Show Welcome Message")

    -- Checkbox to show/hide chat messages
    local showChatMessageCheckbox = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    showChatMessageCheckbox:SetPoint("TOPLEFT", showWelcomeMessageCheckbox, "BOTTOMLEFT", 0, -8)
    showChatMessageCheckbox:SetChecked(_G[addon.CONST.DB_NAME].specificSettings.showChatMessage)
    showChatMessageCheckbox:SetScript("OnClick", function(self)
        _G[addon.CONST.DB_NAME].specificSettings.showChatMessage = self:GetChecked()
    end)
    addon.showChatMessageCheckbox = showChatMessageCheckbox -- Store reference
    local showChatMessageLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showChatMessageLabel:SetPoint("LEFT", showChatMessageCheckbox, "RIGHT", 5, 0)
    showChatMessageLabel:SetText("Show flavor message when using " .. addon.CONST.ADDON_DISPLAY_NAME)

    -- Checkbox to toggle sound
    local playSoundWhenFrameShownCheckbox = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    playSoundWhenFrameShownCheckbox:SetPoint("TOPLEFT", showChatMessageCheckbox, "BOTTOMLEFT", 0, -8)
    playSoundWhenFrameShownCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.playSoundWhenFrameShown)
    playSoundWhenFrameShownCheckbox:SetScript("OnClick", function(self)
        _G[addon.CONST.DB_NAME].generalSettings.playSoundWhenFrameShown = self:GetChecked()
    end)
    addon.playSoundWhenFrameShownCheckbox = playSoundWhenFrameShownCheckbox -- Store reference
    local playSoundWhenFrameShownLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playSoundWhenFrameShownLabel:SetPoint("LEFT", playSoundWhenFrameShownCheckbox, "RIGHT", 5, 0)
    playSoundWhenFrameShownLabel:SetText("Play sound when show/hide " .. addon.CONST.ADDON_DISPLAY_NAME)

    -- Checkbox to toggle showhide on mouseover
    local showButtonOnMouseOverCheckbox = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    showButtonOnMouseOverCheckbox:SetPoint("TOPLEFT", playSoundWhenFrameShownCheckbox, "BOTTOMLEFT", 0, -8)
    showButtonOnMouseOverCheckbox:SetChecked(_G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver)
    showButtonOnMouseOverCheckbox:SetScript("OnClick", function(self)
        _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver = self:GetChecked()
        addon.UpdateVisibility() -- Call the global function to update visibility
    end)
    addon.showButtonOnMouseOverCheckbox = showButtonOnMouseOverCheckbox -- Store reference
    local showButtonOnMouseOverLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showButtonOnMouseOverLabel:SetPoint("LEFT", showButtonOnMouseOverCheckbox, "RIGHT", 5, 0)
    showButtonOnMouseOverLabel:SetText("Hide button until mouseover")

    ------------------------------------------
    -- Create the "Position Settings" label --
    ------------------------------------------
    local mainFramePositionLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainFramePositionLabel:SetPoint("TOPLEFT", generalSettingsHeader, "BOTTOMLEFT", 0, -150)
    mainFramePositionLabel:SetText("Position Settings")

    -- Checkbox to lock/unlock frame position
    local lockPositionCheckbox = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
    lockPositionCheckbox:SetPoint("TOPLEFT", mainFramePositionLabel, "BOTTOMLEFT", 20, -8)
    lockPositionCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.lockPosition)
    lockPositionCheckbox:SetScript("OnClick", function(self)
        local isLocked = self:GetChecked()
        _G[addon.CONST.DB_NAME].generalSettings.lockPosition = isLocked
        if isLocked then
            addon.mainFrame:RegisterForDrag()  -- Unregister drag
        else
            addon.mainFrame:RegisterForDrag("LeftButton")  -- Register drag
        end
    end)
    addon.lockPositionCheckbox = lockPositionCheckbox -- Store reference
    local lockPositionLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockPositionLabel:SetPoint("LEFT", lockPositionCheckbox, "RIGHT", 5, 0)
    lockPositionLabel:SetText("Lock Dragging")

    -- Button to move the mainFrame to the center of the screen
    local centerButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    centerButton:SetSize(200, 25)
    centerButton:SetText("Move to center of the screen")
    centerButton:SetPoint("TOPLEFT", mainFramePositionLabel, "BOTTOMLEFT", 240, -8)
    centerButton:SetScript("OnClick", function()
        -- Move the mainFrame to the center of the screen
        addon.mainFrame:ClearAllPoints()
        addon.mainFrame:SetPoint("CENTER", UIParent, "CENTER")
        
        -- Update the saved position in the database
        _G[addon.CONST.DB_NAME].mainFramePosition.point = "CENTER"
        _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo = nil
        _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = 0
        _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = 0
    end)

    -- Create the "Fine tune button position" label
    local fineTuneLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fineTuneLabel:SetPoint("TOPLEFT", lockPositionLabel, "BOTTOMLEFT", 0, -20)
    fineTuneLabel:SetText("Fine tune button position")

    -- Create a text field for the X position
    addon.xPositionInput = CreateFrame("EditBox", addon.CONST.ADDON_NAME .. "xPositionInput", content, "InputBoxTemplate")
    addon.xPositionInput:SetPoint("TOPLEFT", fineTuneLabel, "BOTTOMLEFT", 75, -10)
    addon.xPositionInput:SetSize(75, 15)
    addon.xPositionInput:SetJustifyH("CENTER")
    addon.xPositionInput:SetAutoFocus(false)
    addon.xPositionInput:ClearFocus()
    addon.xPositionInput:SetMaxLetters(6)
    addon.xPositionInput:SetText(tostring(_G[addon.CONST.DB_NAME].mainFramePosition.xOfs or 0))
    addon.xPositionInput:SetCursorPosition(0)  -- Set cursor to the start of the text

    -- Create a label for the X position input
    local xPositionLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xPositionLabel:SetPoint("RIGHT", addon.xPositionInput, "LEFT", -10, 0)
    xPositionLabel:SetText("X Position:")

    -- Create a text field for the Y position
    addon.yPositionInput = CreateFrame("EditBox", addon.CONST.ADDON_NAME .. "yPositionInput", content, "InputBoxTemplate")
    addon.yPositionInput:SetPoint("TOPLEFT", addon.xPositionInput, "BOTTOMLEFT", 0, -10)
    addon.yPositionInput:SetSize(75, 15)
    addon.yPositionInput:SetJustifyH("CENTER")
    addon.yPositionInput:SetAutoFocus(false)
    addon.yPositionInput:ClearFocus()
    addon.yPositionInput:SetMaxLetters(6)
    addon.yPositionInput:SetText(tostring(_G[addon.CONST.DB_NAME].mainFramePosition.yOfs or 0))
    addon.yPositionInput:SetCursorPosition(0)  -- Set cursor to the start of the text
    
    -- Create a label for the Y position input
    local yPositionLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yPositionLabel:SetPoint("RIGHT", addon.yPositionInput, "LEFT", -10, 0)
    yPositionLabel:SetText("Y Position:")

    -- Set scripts to update the button position when the text fields are changed
    addon.xPositionInput:SetScript("OnEnterPressed", function()
        local x = tonumber(addon.xPositionInput:GetText())
        local y = tonumber(addon.yPositionInput:GetText())
        if x and y then
            _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = x
            _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = y
            addon.LoadMainFramePosition()  -- Call the function to update the frame's position
        end
    end)
    
    addon.yPositionInput:SetScript("OnEnterPressed", function()
        local x = tonumber(addon.xPositionInput:GetText())
        local y = tonumber(addon.yPositionInput:GetText())
        if x and y then
            _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = x
            _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = y
            addon.LoadMainFramePosition()  -- Call the function to update the frame's position
        end
    end)

    ------------------------------
    -- Position Presets Section --
    ------------------------------
    local function SavePreset()
        local presetName = presetNameInput:GetText()
        if presetName and presetName ~= "" then
            if not _G[addon.CONST.DB_NAME].presets then
                _G[addon.CONST.DB_NAME].presets = {}
            end
    
            _G[addon.CONST.DB_NAME].presets[presetName] = {
                point = _G[addon.CONST.DB_NAME].mainFramePosition.point,
                relativeTo = _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo,
                relativePoint = _G[addon.CONST.DB_NAME].mainFramePosition.relativePoint,
                xOfs = _G[addon.CONST.DB_NAME].mainFramePosition.xOfs,
                yOfs = _G[addon.CONST.DB_NAME].mainFramePosition.yOfs,
            }
            presetNameInput:SetText("")
            UIDropDownMenu_SetText(presetsDropdown, "Select Preset")
            UIDropDownMenu_Initialize(presetsDropdown, InitializePresetsDropdown)
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: "  .. addon.CONST.RESET_COLOR .. "Preset: '" .. presetName .. "' saved.")
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Please enter a valid preset name.")
        end
    end
    
    local function LoadPreset()
        local presetName = presetNameInput:GetText()
        if _G[addon.CONST.DB_NAME].presets and _G[addon.CONST.DB_NAME].presets[presetName] then
            local preset = _G[addon.CONST.DB_NAME].presets[presetName]
            _G[addon.CONST.DB_NAME].mainFramePosition.point = preset.point
            _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo = preset.relativeTo
            _G[addon.CONST.DB_NAME].mainFramePosition.relativePoint = preset.relativePoint
            _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = preset.xOfs
            _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = preset.yOfs
            addon.LoadMainFramePosition()
            presetNameInput:SetText("")
            UIDropDownMenu_SetText(presetsDropdown, "Select Preset")
            UIDropDownMenu_Initialize(presetsDropdown, InitializePresetsDropdown)
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Preset: '" .. presetName .. "' loaded.")
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Preset: '" .. presetName .. "' not found.")
        end
    end
    
    local function DeletePreset()
        local presetName = presetNameInput:GetText()
        if _G[addon.CONST.DB_NAME].presets and _G[addon.CONST.DB_NAME].presets[presetName] then
            _G[addon.CONST.DB_NAME].presets[presetName] = nil
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Preset: '" .. presetName .. "' deleted.")
            -- Clear the EditBox and update the dropdown menu
            presetNameInput:SetText("")
            UIDropDownMenu_SetText(presetsDropdown, "Select Preset")
            UIDropDownMenu_Initialize(presetsDropdown, InitializePresetsDropdown)
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Preset: '" .. presetName .. "' not found.")
        end
    end

    -- Adjust preset save and load UI elements
    local presetLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    presetLabel:SetPoint("TOPLEFT", fineTuneLabel, "BOTTOMLEFT", 250, 12)
    presetLabel:SetText("Position Presets")

    presetNameInput = CreateFrame("EditBox", addon.CONST.ADDON_NAME .. "PresetNameInput", content, "InputBoxTemplate")
    presetNameInput:SetPoint("TOPLEFT", presetLabel, "BOTTOMLEFT", 0, -10)
    presetNameInput:SetSize(170, 20)
    presetNameInput:SetAutoFocus(false)
    presetNameInput:SetMaxLetters(20)
    presetNameInput:SetText("Preset Name")
    presetNameInput:SetJustifyH("CENTER")
    presetNameInput:SetCursorPosition(0)
    presetNameInput:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Preset Name" then
            self:SetText("")
        end
    end)
    presetNameInput:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Preset Name")
        end
    end)
    presetNameInput:SetScript("OnTextChanged", function(self, userInput)
        presetNameInput = self
    end)
    
    local savePresetButton = CreateFrame("Button", addon.CONST.ADDON_NAME .. "SavePresetButton", content, "UIPanelButtonTemplate")
    savePresetButton:SetPoint("LEFT", presetNameInput, "RIGHT", 10, 0)
    savePresetButton:SetSize(100, 20)
    savePresetButton:SetText("Save Preset")
    savePresetButton:SetScript("OnClick", function()
        local presetName = presetNameInput:GetText()
        if addon.DEBUG then
            addon.DebugPrint("Debug: Saved presetName = ", presetName)
        end
        if presetName and presetName ~= "" and presetName ~= "Preset Name" then
            SavePreset(presetName)
            presetNameInput:SetText("") -- Clear EditBox
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Invalid preset name!")
        end
    end)

    local loadPresetButton = CreateFrame("Button", addon.CONST.ADDON_NAME .. "LoadPresetButton", content, "UIPanelButtonTemplate")
    loadPresetButton:SetPoint("TOPLEFT", savePresetButton, "BOTTOMLEFT", 0, -10)
    loadPresetButton:SetSize(100, 20)
    loadPresetButton:SetText("Load Preset")
    loadPresetButton:SetScript("OnClick", function()
        local presetName = presetNameInput:GetText()
        if presetName ~= "" then
            LoadPreset(presetName)
        end
    end)

    -- Create a delete preset button
    local deletePresetButton = CreateFrame("Button", addon.CONST.ADDON_NAME .. "DeletePresetButton", content, "UIPanelButtonTemplate")
    deletePresetButton:SetPoint("TOPLEFT", loadPresetButton, "BOTTOMLEFT", 0, -10)
    deletePresetButton:SetSize(100, 20)
    deletePresetButton:SetText("Delete Preset")
    deletePresetButton:SetScript("OnClick", function()
        local presetName = presetNameInput:GetText()
        if presetName ~= "" then
            DeletePreset(presetName)
            presetNameInput:SetText("") -- Clear EditBox
        end
    end)
    
    -- Create dropdown menu for presets
    presetsDropdown = CreateFrame("Frame", addon.CONST.ADDON_NAME .. "PresetDropdown", content, "UIDropDownMenuTemplate")
    presetsDropdown:SetPoint("TOPLEFT", presetNameInput, "BOTTOMLEFT", -16, -10)
    UIDropDownMenu_SetWidth(presetsDropdown, 150)
    UIDropDownMenu_SetText(presetsDropdown, "Select Preset")
    
    local function InitializePresetsDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for presetName in pairs(_G[addon.CONST.DB_NAME].presets or {}) do
            info.text = presetName
            info.func = function()
                UIDropDownMenu_SetText(presetsDropdown, presetName)
                presetNameInput:SetText(presetName)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    addon.InitializePresetsDropdown = InitializePresetsDropdown -- Store function reference
    UIDropDownMenu_Initialize(presetsDropdown, InitializePresetsDropdown)
    addon.presetsDropdown = presetsDropdown -- Store reference

    -- Center the text in the dropdown menu
    local text = _G[presetsDropdown:GetName().."Text"]
    text:ClearAllPoints()
    text:SetPoint("CENTER", presetsDropdown, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")

    ----------------------------------------------
    -- Create a label for the position dropdown --
    ----------------------------------------------
    local toyButtonPositionLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toyButtonPositionLabel:SetPoint("TOPLEFT", mainFramePositionLabel, "BOTTOMLEFT", 0, -155)
    toyButtonPositionLabel:SetText("Toy Button Position relative to Main Button")
    
    -- Dropdown for positioning
    addon.positions = {"LEFT", "RIGHT", "ABOVE", "BELOW"}

    addon.positionDropdown = CreateFrame("Frame", addon.CONST.ADDON_NAME .. "PositionDropdown", content, "UIDropDownMenuTemplate")
    addon.positionDropdown:SetPoint("TOPLEFT", toyButtonPositionLabel, "BOTTOMLEFT", 20, -10)

    local function PositionDropdown_OnClick(self)
        UIDropDownMenu_SetSelectedID(addon.positionDropdown, self:GetID())
        _G[addon.CONST.DB_NAME].specificSettings.toyFramePosition = addon.positions[self:GetID()]
        addon.UpdateToyButtonPositions() -- Call UpdateToyButtonPositions when position is changed
    end
    
    local function InitializePositionDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for index, toyFramePosition in ipairs(addon.positions) do
            info = UIDropDownMenu_CreateInfo()
            info.text = toyFramePosition:sub(1, 1) .. toyFramePosition:sub(2):lower()
            info.value = toyFramePosition
            info.func = PositionDropdown_OnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(addon.positionDropdown, InitializePositionDropdown)
    UIDropDownMenu_SetWidth(addon.positionDropdown, 100)
    UIDropDownMenu_SetButtonWidth(addon.positionDropdown, 124)

    -- Find the index of the current position in positions table
    local selectedPositionIndex
    for i, pos in ipairs(addon.positions) do
        if pos == _G[addon.CONST.DB_NAME].specificSettings.toyFramePosition then
            selectedPositionIndex = i
            break
        end
    end
    UIDropDownMenu_SetSelectedID(addon.positionDropdown, selectedPositionIndex or 1)
    UIDropDownMenu_JustifyText(addon.positionDropdown, "LEFT")

    -- Ensure the settings are loaded first
    local buttonSize = addon.buttonSize or 44  -- Using addon.buttonSize, which was set in InitializeAddon

    ----------------------------------------
    -- Create a label for the size slider --
    ----------------------------------------
    local sizeSliderLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sizeSliderLabel:SetPoint("TOPLEFT", toyButtonPositionLabel, "BOTTOMLEFT", 0, -70)
    sizeSliderLabel:SetText("Size Settings")

    -- Create a slider for adjusting button sizes
    addon.sizeSlider = CreateFrame("Slider", addon.CONST.ADDON_NAME .. "SizeSlider", content, "OptionsSliderTemplate")
    addon.sizeSlider:SetPoint("TOPLEFT", sizeSliderLabel, "BOTTOMLEFT", 35, -10)
    addon.sizeSlider:SetMinMaxValues(20, 100)
    addon.sizeSlider:SetValueStep(1)
    addon.sizeSlider:SetValue(_G[addon.CONST.DB_NAME].specificSettings.buttonSize or 44)  -- Set the slider to the saved size
    addon.sizeSlider:SetWidth(150)
    addon.sizeSlider:SetObeyStepOnDrag(true)

    _G[addon.sizeSlider:GetName() .. "Low"]:SetText("20")
    _G[addon.sizeSlider:GetName() .. "High"]:SetText("100")

    -- Create an input box to display and input the size value
    addon.sizeInput = CreateFrame("EditBox", addon.CONST.ADDON_NAME .. "SizeInput", content, "InputBoxTemplate")
    addon.sizeInput:SetPoint("LEFT", addon.sizeSlider, "RIGHT", 20, 0)
    addon.sizeInput:SetSize(50, 30)
    addon.sizeInput:SetJustifyH("CENTER")  -- Center the text in the input box
    addon.sizeInput:SetAutoFocus(false)
    addon.sizeInput:ClearFocus()
    addon.sizeInput:SetText(math.floor(_G[addon.CONST.DB_NAME].specificSettings.buttonSize or 44))
    addon.sizeInput:SetCursorPosition(0)

    -- Function to update button sizes
    local function UpdateButtonSizes(value)
        addon.buttonSize = value  -- Ensure addon.buttonSize is updated
        _G[addon.CONST.DB_NAME].specificSettings.buttonSize = addon.buttonSize

        -- Apply the new size to your buttons
        addon.mainFrame:SetSize(addon.buttonSize, addon.buttonSize)
        for _, button in ipairs(addon.CONST.toyButtons) do
            button:SetSize(addon.buttonSize, addon.buttonSize)
        end

        -- Update toy button positions if necessary
        addon.UpdateToyButtonPositions()
    end

    -- Update button sizes when the slider value changes
    addon.sizeSlider:SetScript("OnValueChanged", function(self, value)
        local newSize = math.floor(value)
        addon.sizeInput:SetText(newSize)  -- Update the input field
        UpdateButtonSizes(newSize)  -- Apply the size change in real-time
    end)

    -- Update slider and button sizes when the input field value changes
    addon.sizeInput:SetScript("OnEnterPressed", function(self)
        local inputValue = tonumber(self:GetText())
        if inputValue and inputValue >= 20 and inputValue <= 100 then
            addon.sizeSlider:SetValue(inputValue)  -- This will also trigger the slider's OnValueChanged
        else
            self:SetText(math.floor(addon.sizeSlider:GetValue()))  -- Revert to the current size if the input is invalid
        end
        addon.sizeInput:ClearFocus()  -- Clear focus after entering a value
    end)

    -------------------------------------------
    -- Create a label for the toy checkboxes --
    -------------------------------------------
    local toyListLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    toyListLabel:SetPoint("TOPLEFT", sizeSliderLabel, "BOTTOMLEFT", 0, -75)
    toyListLabel:SetText("Included Toys")
    
    -- Table to store created checkboxes
    local checkBoxes = {}
    
    -- Function to create checkboxes
    local function CreateCheckbox(parent, itemID, itemType, index)
        local checkButton = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        checkButton:SetPoint("TOPLEFT", toyListLabel, "BOTTOMLEFT", 10, -(index * 30 + 15)) -- Adjust starting point and spacing here
        checkButton.Text:SetText("Loading...")

        local function UpdateItemName(attempts)
            local itemName
            if itemType == "toy" and PlayerHasToy(itemID) then
                itemName = select(2, C_ToyBox.GetToyInfo(itemID))
            elseif itemType == "item" and GetItemInfo(itemID) then
                itemName = GetItemInfo(itemID)
            elseif itemType == "spell" and C_Spell.GetSpellName(itemID) then
                itemName = C_Spell.GetSpellName(itemID)
            end

            if itemName and itemName ~= "" then
                checkButton.Text:SetText(itemName)
            else
                if attempts > 0 then
                    C_Timer.After(0.5, function()
                        UpdateItemName(attempts - 1)
                    end)
                else
                    checkButton.Text:SetText("Unknown Item")
                end
            end
            checkButton.Text:ClearAllPoints()
            checkButton.Text:SetPoint("LEFT", checkButton, "RIGHT", 5, 0)
        end

        UpdateItemName(5) -- Attempt 5 times with a 0.5-second delay between each

        if _G[addon.CONST.DB_NAME].toySettings[itemID] == nil then
            _G[addon.CONST.DB_NAME].toySettings[itemID] = true
        end

        checkButton:SetChecked(_G[addon.CONST.DB_NAME].toySettings[itemID])

        checkButton:SetScript("OnClick", function(self)
            addon.ToggleToyInclusion(itemID, self:GetChecked())
        end)

        return checkButton
    end
    
    -- Function to create toy checkboxes
    function addon.CreateToyCheckboxes()
        if addon.DEBUG then
            -- addon.DebugPrint("addon.CreateToyCheckboxes called")
        end

        -- Clear existing checkboxes
        for _, checkBox in ipairs(checkBoxes) do
            checkBox:Hide()
        end
        wipe(checkBoxes) -- Use wipe to clear the table properly

        local index = 0

        for _, entry in ipairs(addon.CONST.availableToys) do
            local checkButton = CreateCheckbox(content, entry.id, entry.type, index)
            table.insert(checkBoxes, checkButton)
            index = index + 1
        end

        content:SetHeight(index * 30 + 400) -- Adjust height as needed to fit all elements
    end
    addon.CreateToyCheckboxes()

    optionsPanel:SetScript("OnShow", function()
        addon.CreateToyCheckboxes()
   end)

    local category, layout = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
    addon.OptionsPanel.optionsCategoryId = category:GetID()  -- Ensure this assignment is correct
    Settings.RegisterAddOnCategory(category)
end

-- Function to create the Defaults Button
function addon.OptionsPanel.CreateResetDatabaseButton(content)
    -- Create a "Reset Database" button
    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 25)
    resetButton:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, -15) -- Adjust placement as needed
    resetButton:SetText("Defaults")
    resetButton:SetScript("OnClick", function()
        StaticPopupDialogs["HEARTHSTONETOYS_RESET_CONFIRMATION"] = {
            text = "Are you sure you want to reset all addon settings? This action cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                addon.ResetDatabase()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("HEARTHSTONETOYS_RESET_CONFIRMATION")
    end)
end