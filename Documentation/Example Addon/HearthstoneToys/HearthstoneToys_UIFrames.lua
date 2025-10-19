-- HearthstoneToys_UIFrames.lua
-- print("HearthstoneToys_UIFrames.lua")

-- Access the addon namespace
local addonName, addon = ...

-- Ensure the UIFrames module is part of the addon namespace
addon.UIFrames = {}

-- Local references
local addonName = addon.CONST.ADDON_DISPLAY_NAME
addon.mainFrame = nil
addon.toyFrame = nil
addon.cooldownFrame = nil

function addon.CreateToyFrame()
    if addon.DEBUG then
        -- addon.DebugPrint("CreateToyFrame called")
        addon.DebugPrint("CreateToyFrame: Called from", debugstack(2, 1, 0):match("([^/\\]+%.lua:%d+)"))
    end
    
    -- Destroy the old frame if it exists
    if addon.toyFrame then
        addon.toyFrame:Hide()
        addon.toyFrame:SetParent(nil)
        addon.toyFrame = nil
    end

    -- Recreate the frame
    addon.toyFrame = CreateFrame("Frame", addon.CONST.ADDON_NAME .. "ToyFrame", UIParent, "BackdropTemplate")
    addon.toyFrame:SetSize(#addon.toyList * (addon.buttonSize + 4), addon.buttonSize + 4)
    addon.toyFrame:SetFrameStrata("HIGH")
    addon.toyFrame:SetFrameLevel(100)
    addon.toyFrame:Hide() -- Hide until explicitly shown later

    if addon.DEBUG then
        addon.toyFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        addon.toyFrame:SetBackdropColor(0, 0, 0, 0.8)
        addon.toyFrame:SetBackdropBorderColor(1, 1, 1, 1)
    end
    
    -- Reparent toy buttons to the new frame
    for _, button in ipairs(addon.CONST.toyButtons) do
        button:SetParent(addon.toyFrame)
        button:Show() -- Ensure they're visible
    end

    -- Update layout
    if addon.UpdateToyButtonPositions then
        addon.UpdateToyButtonPositions()
    end
end

-- Function to create the main UI frame
function addon.UIFrames.Initialize()
    if addon.DEBUG then
        addon.DebugPrint("addon.UIFrames.Initialize called")
    end
    -- Function to Create the Main Button
    addon.mainFrame = CreateFrame("Button", addon.CONST.ADDON_NAME .. "mainFrame", UIParent, "SecureActionButtonTemplate")
    addon.mainFrame:SetSize(addon.buttonSize, addon.buttonSize)
    addon.mainFrame:SetNormalTexture(addon.CONST.ADDON_ICON_TEXTURE)
    addon.mainFrame:RegisterForClicks("AnyUp")
    addon.mainFrame:SetMovable(true)
    addon.mainFrame:EnableMouse(true)
    addon.mainFrame:RegisterForDrag("LeftButton")
    addon.mainFrame:SetFrameStrata("MEDIUM")
    addon.mainFrame:SetFrameLevel(100)
    addon.mainFrame:SetPoint("CENTER", _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo or UIParent, _G[addon.CONST.DB_NAME].mainFramePosition.point, _G[addon.CONST.DB_NAME].mainFramePosition.xOfs, _G[addon.CONST.DB_NAME].mainFramePosition.yOfs)
    addon.mainFrame:Hide()
    
    -- Mouse Over section for mainFrame tooltips and hiding on mouse leave
    addon.mainFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:ClearLines()
        GameTooltip:SetText(addon.CONST.ADDON_TEXT_COLOR .. addon.CONST.ADDON_DISPLAY_NAME .. addon.CONST.RESET_COLOR, 1, 1, 1, 1, true)
        GameTooltip:AddLine("Left-click: Toy buttons", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Options panel", 1, 1, 1)
        GameTooltip:AddLine("Shift-click: Use random toy", 1, 1, 1)
        GameTooltip:Show()

        if _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver then
            addon.mainFrame:SetAlpha(1)
        end
    end)

    addon.mainFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()

        if _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver and not addon.toyFrame:IsShown() then
            addon.mainFrame:SetAlpha(0)
        end
    end)

    addon.mainFrame:RegisterForClicks("AnyDown", "AnyUp")

    local randomActionTriggered = false -- Flag to track if shift-click occurred
    local isDragging = false  -- Flag to check if we are dragging
    local lastMouseX, lastMouseY  -- Variables to track mouse position

    local function selectRandomAction()
        local actionList = addon.CONST.includeToys -- Your toy/item/spell list

        -- Randomly select an action
        if #actionList == 0 then
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Action list is empty.")
            return nil, nil
        end

        local randomIndex = math.random(1, #actionList)
        local itemID = actionList[randomIndex]

        -- Determine the type and validate
        local isToy = PlayerHasToy(itemID)
        local isSpell = IsSpellKnown(itemID)
        local itemCount = GetItemCount(itemID)

        if isToy then
            return "toy", itemID
        elseif isSpell then
            return "spell", itemID
        elseif itemCount > 0 then
            return "item", "item:" .. itemID
        else
            return nil, nil
        end
    end

    addon.mainFrame:SetScript("OnMouseDown", function(self, button)
        addon.UpdateCooldown()
        if button == "LeftButton"  and not IsShiftKeyDown() then
            isDragging = false  -- Reset dragging flag
            lastMouseX, lastMouseY = GetCursorPosition()  -- Track initial mouse position
            
            if not _G[addon.CONST.DB_NAME].generalSettings.lockPosition then
                self:StartMoving()  -- Start dragging the main frame
            end
        elseif button == "RightButton" and not IsShiftKeyDown() then
            Settings.OpenToCategory(addon.OptionsPanel.optionsCategoryId)
        elseif button == "LeftButton" and IsShiftKeyDown() then
            -- Handle shift-click for random action
            local actionType, actionID = selectRandomAction()
            if actionType and actionID then
                self:SetAttribute("type", actionType)
                self:SetAttribute(actionType, actionID)
                randomActionTriggered = true -- Set the flag
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "No valid action found.")
                self:SetAttribute("type", nil)
                randomActionTriggered = false -- Reset the flag
            end
            if _G[addon.CONST.DB_NAME].specificSettings.showChatMessage then
                addon.FlavorMessage()
            end
        end
    end)    

    addon.mainFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()  -- Stop moving the frame
            
            -- Check if the frame was dragged
            local newMouseX, newMouseY = GetCursorPosition()
            if (lastMouseX ~= newMouseX) or (lastMouseY ~= newMouseY) then
                isDragging = true
            end
            
            if not isDragging then
                -- Toggle toyFrame visibility on click
                if addon.toyFrame:IsShown() then
                    addon.toyFrame:Hide()
                    if _G[addon.CONST.DB_NAME].generalSettings.playSoundWhenFrameShown then
                        PlaySoundFile(addon.CONST.TOY_FRAME_HIDE_SOUND_ID, "Effects")
                    end
                else
                    if _G[addon.CONST.DB_NAME].generalSettings.playSoundWhenFrameShown then
                        PlaySoundFile(addon.CONST.TOY_FRAME_SHOW_SOUND_ID, "Effects")
                    end

                    -- addon.CreateToyFrame()
                    addon.toyFrame:Show()

                end
            end
            addon.SaveMainFramePosition()  -- Save the frame position
        end
    end)

    addon.mainFrame:SetScript("PostClick", function(self)
        if not randomActionTriggered then
            return -- Exit if not triggered by a shift-click
        end
    
        local actionType = self:GetAttribute("type")
        local actionID = actionType and self:GetAttribute(actionType)
    
        if actionType and actionID then
            -- print("PostClick - Activated action:", actionType, actionID)
            -- Clear attributes after secure execution
            C_Timer.After(0.1, function()
                self:SetAttribute("type", nil)
                self:SetAttribute("toy", nil)
                self:SetAttribute("spell", nil)
                self:SetAttribute("item", nil)
                randomActionTriggered = false -- Reset the flag
            end)
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "PostClick - No valid action found for type:", actionType)
            randomActionTriggered = false -- Reset the flag
        end
    end)

    -- Manage main button dragging and saving the position
    addon.mainFrame:SetScript("OnDragStart", function(self)
        if not _G[addon.CONST.DB_NAME].generalSettings.lockPosition then
            isDragging = true
            self:StartMoving()
        end
    end)

    addon.mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        addon.SaveMainFramePosition()
    end)

    -- Add Cooldown Frame to mainFrame
    addon.cooldownFrame = CreateFrame("Cooldown", addon.CONST.ADDON_NAME .. "CooldownFrame", addon.mainFrame, "CooldownFrameTemplate")
    addon.cooldownFrame:SetAllPoints(addon.mainFrame)

    -- Ensure it renders above the button’s icon
    addon.cooldownFrame:SetFrameStrata(addon.mainFrame:GetFrameStrata())
    addon.cooldownFrame:SetFrameLevel(addon.mainFrame:GetFrameLevel() + 5)

    -- Optional visual clarity (safe defaults)
    addon.cooldownFrame:SetDrawSwipe(true)
    addon.cooldownFrame:SetDrawEdge(false)
    addon.cooldownFrame:SetSwipeColor(0, 0, 0, 0.7)   -- dark overlay
    -- If you use OmniCC or similar and want numbers, leave this as-is; to hide numbers:
    -- addon.cooldownFrame:SetHideCountdownNumbers(true)

    -- addon.UpdateVisibility()
end

function addon.UpdateVisibility()
    if addon.DEBUG then
        local trace = debugstack(2, 3, 0)
        addon.DebugPrint("UpdateVisibility: Trace\n" .. trace)
    end

    local showOnMouseover = _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver

    -- Always apply state driver for protected UI conditions
    RegisterStateDriver(addon.mainFrame, "visibility", "[petbattle][overridebar][vehicleui][possessbar][@vehicle,exists] hide; show")

    if showOnMouseover then
        addon.mainFrame:SetAlpha(0)
    else
        addon.mainFrame:SetAlpha(1)
    end
end

-- Function to update toy button positions
function addon.UpdateToyButtonPositions()
    if addon.DEBUG then
        -- addon.DebugPrint("UpdateToyButtonPositions: Called from", debugstack(2, 1, 0):match("([^/\\]+%.lua:%d+)"))
    end

    local toyFramePosition = _G[addon.CONST.DB_NAME].specificSettings.toyFramePosition or "LEFT"
    local buttonSize = _G[addon.CONST.DB_NAME].specificSettings.buttonSize
    local spacing = 3
    local offsetX, offsetY = 0, 0
    
    -- Calculate offsets based on position
    if toyFramePosition == "LEFT" then
        addon.toyFrame:SetPoint("RIGHT", addon.mainFrame, "LEFT", -(buttonSize / 2 + spacing), 0)
        offsetX = buttonSize
    elseif toyFramePosition == "RIGHT" then
        addon.toyFrame:SetPoint("LEFT", addon.mainFrame, "RIGHT", buttonSize / 2 + spacing, 0)
        offsetX = buttonSize
    elseif toyFramePosition == "ABOVE" then
        addon.toyFrame:SetPoint("BOTTOM", addon.mainFrame, "TOP", 0, buttonSize / 2 + spacing)
        offsetY = buttonSize
    elseif toyFramePosition == "BELOW" then
        addon.toyFrame:SetPoint("TOP", addon.mainFrame, "BOTTOM", 0, -(buttonSize / 2 + spacing))
        offsetY = buttonSize
    end

    -- Adjust toyButtons positions based on their index and selected position
    for index, button in ipairs(addon.CONST.toyButtons) do
        local buttonOffsetX, buttonOffsetY = 0, 0

        if toyFramePosition == "LEFT" or toyFramePosition == "RIGHT" then
            buttonOffsetX = (index - 1) * (buttonSize + spacing) + offsetX + 3
            if toyFramePosition == "LEFT" then
                buttonOffsetX = -buttonOffsetX  -- Reverse direction for LEFT position
            end
        elseif toyFramePosition == "ABOVE" or toyFramePosition == "BELOW" then
            buttonOffsetY = (index - 1) * (buttonSize + spacing) + offsetY + 3
            if toyFramePosition == "BELOW" then
                buttonOffsetY = -buttonOffsetY  -- Reverse direction for BELOW position
            end
        end

        button:ClearAllPoints()
        button:SetPoint("CENTER", addon.mainFrame, "CENTER", buttonOffsetX, buttonOffsetY)
    end
end

-- Function to Set the Button Texture
local function SetButtonTexture(toyActionButton, itemID, texture, retries)
    if retries == 0 then
        -- If no retries left, set the default question mark texture
        toyActionButton:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        return
    end

    if texture and texture ~= "" then
        -- If texture is available, set it directly
        toyActionButton:SetNormalTexture(texture)
    else
        -- Retry loading the texture after a short delay
        C_Timer.After(0.7, function()
            local _, _, retryTexture
            if C_ToyBox.GetToyInfo then
                -- Try fetching toy info
                _, _, retryTexture = C_ToyBox.GetToyInfo(itemID)
            elseif C_Spell.GetSpellTexture then
                -- Try fetching spell texture
                retryTexture = C_Spell.GetSpellTexture(itemID)
            elseif GetItemInfo then
                -- Try fetching item info
                _, _, retryTexture = GetItemInfo(itemID)
            else
                -- No available methods to fetch texture
                retryTexture = nil
            end

            -- Retry setting the button texture with decremented retries
            SetButtonTexture(toyActionButton, itemID, retryTexture, retries - 1)
        end)
    end
end

---------------------------------
-- Function to Create Toy Buttons
---------------------------------
function addon.CreateButton(itemID, parent, index)
    local toyActionButton = CreateFrame("Button", addon.CONST.ADDON_NAME .. "Button" .. index, parent, "SecureActionButtonTemplate")
    toyActionButton:SetSize(addon.buttonSize, addon.buttonSize)

    local isToy = PlayerHasToy(itemID)
    local isSpell = IsSpellKnown(itemID)
    local texture
    local tooltipFunc

    -- Preload texture and setup tooltip function
    if isToy then
        local _, toyName, toyTexture = C_ToyBox.GetToyInfo(itemID)
        texture = toyTexture
        tooltipFunc = function(self)
            if GetItemInfo(itemID) then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetToyByItemID(itemID)
                GameTooltip:Show()
            else
                self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
            end
        end
        toyActionButton:SetAttribute("type", "toy")
        toyActionButton:SetAttribute("toy", itemID)

        -- >>> store what to use for cooldown
        toyActionButton._cdType = "item"     -- toys use item cooldowns
        toyActionButton._cdID   = itemID

    elseif isSpell then
        local spellName = C_Spell.GetSpellName(itemID)
        texture = C_Spell.GetSpellTexture(itemID)
        tooltipFunc = function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(itemID)
            GameTooltip:Show()
        end
        toyActionButton:SetAttribute("type", "spell")
        toyActionButton:SetAttribute("spell", itemID)

        -- >>> store what to use for cooldown
        toyActionButton._cdType = "spell"
        toyActionButton._cdID   = itemID

    else
        local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
        texture = itemTexture
        tooltipFunc = function(self)
            if GetItemInfo(itemID) then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemID)
                GameTooltip:Show()
            else
                self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
            end
        end
        toyActionButton:SetAttribute("type", "item")
        toyActionButton:SetAttribute("item", "item:" .. itemID)

        -- >>> store what to use for cooldown
        toyActionButton._cdType = "item"
        toyActionButton._cdID   = itemID
    end

    -- Use the SetButtonTexture function with retry logic
    SetButtonTexture(toyActionButton, itemID, texture, 7)

    -- Tooltip handling with caching check
    toyActionButton:SetScript("OnEnter", function(self)
        tooltipFunc(self)
    end)

    toyActionButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Handle delayed tooltip update when item info is received
    toyActionButton:SetScript("OnEvent", function(self, event, receivedItemID)
        if event == "GET_ITEM_INFO_RECEIVED" and receivedItemID == itemID then
            self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
            if self:IsMouseOver() then
                tooltipFunc(self)
            end
        end
    end)

    toyActionButton:SetScript("PostClick", function(self)
        if addon.toyFrame then
            addon.toyFrame:Hide() -- Hide the toy frame
        end
        -- Adjust mainFrame visibility depending on mouseover setting
        if _G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver then
            addon.mainFrame:SetAlpha(0)
        else
            addon.mainFrame:SetAlpha(1)
        end
        -- Optional Flavor Message
        if _G[addon.CONST.DB_NAME].specificSettings.showChatMessage then
            addon.FlavorMessage()
        end
    end)

    toyActionButton:RegisterForClicks("AnyDown", "AnyUp")
    toyActionButton:SetFrameStrata("HIGH")
    toyActionButton:SetFrameLevel(101)

    ----------------------------------------------------------------
    -- >>> Add a cooldown overlay on each toyActionButton
    ----------------------------------------------------------------
    local cd = CreateFrame("Cooldown", toyActionButton:GetName() .. "Cooldown", toyActionButton, "CooldownFrameTemplate")
    cd:SetAllPoints(toyActionButton)
    cd:SetFrameStrata(toyActionButton:GetFrameStrata())
    cd:SetFrameLevel(toyActionButton:GetFrameLevel() + 1)
    cd:SetDrawSwipe(true)
    cd:SetDrawEdge(false)
    cd:SetSwipeColor(0, 0, 0, 0.7)
    cd:SetReverse(false)
    cd:SetHideCountdownNumbers(false)
    toyActionButton.cooldown = cd

    -- >>> immediate initial update so the state is right when shown
    if addon.UpdateToyButtonCooldown then
        addon.UpdateToyButtonCooldown(toyActionButton)
    end

    return toyActionButton
end