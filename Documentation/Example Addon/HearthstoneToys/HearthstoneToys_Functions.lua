-- HearthstoneToys_Functions.lua
-- print("HearthstoneToys_Functions.lua")

-- Access the addon namespace
local addonName, addon = ...

-- Ensure the Functions module is part of the addon namespace
addon.Functions = {}

-- Store last known toy ownership state
local lastKnownOwnedToyIDs = {}
local hasToySnapshotInitialized = false

-- Function for Debug Print
function addon.DebugPrint(...)
    if not addon.DEBUG then return end

    local messageParts = {...}
    for i = 1, #messageParts do
        messageParts[i] = tostring(messageParts[i])
    end

    print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " ..
          addon.CONST.RESET_COLOR .. addon.CONST.DEBUG_TEXT_COLOR .. "[DEBUG] " ..
          addon.CONST.RESET_COLOR .. table.concat(messageParts, " "))
end

-- Function to find Available Toys by filtering toyList
function addon.InitializeAvailableToys()
    wipe(addon.CONST.availableToys) -- Clear the availableToys table
    
    for _, entry in ipairs(addon.toyList) do
        local itemID = entry.id
        local itemType = entry.type
        
        if itemType == "toy" then
            if PlayerHasToy(itemID) then
                table.insert(addon.CONST.availableToys, {id = itemID, type = itemType})
            end
        elseif itemType == "item" then
            if GetItemCount(itemID) > 0 then
                table.insert(addon.CONST.availableToys, {id = itemID, type = itemType})
            end
        elseif itemType == "spell" then
            if IsSpellKnown(itemID) then
                table.insert(addon.CONST.availableToys, {id = itemID, type = itemType})
            end
        end
    end
end

-- Function to find Included Toys by filtering availableToys based on checkboxes in options panel
function addon.InitializeIncludedToys()
    wipe(addon.CONST.includeToys) -- Clear the includeToys table
    
    -- Add toys, items, and spells from the saved settings to the includeToys table
    for itemID, isIncluded in pairs(_G[addon.CONST.DB_NAME].toySettings) do
        if isIncluded then
            local isToy = false
            local isSpell = false
            local isItem = false

            -- Check each type and their respective functions
            for _, entry in ipairs(addon.toyList) do
                if entry.id == itemID then
                    if entry.type == "toy" then
                        isToy = PlayerHasToy(itemID)
                    elseif entry.type == "spell" then
                        isSpell = IsSpellKnown(itemID)
                    elseif entry.type == "item" then
                        isItem = GetItemInfo(itemID) ~= nil
                    end
                    break
                end
            end

            if isToy or isSpell or isItem then  -- Include if it's a toy, a spell, or a valid item
                table.insert(addon.CONST.includeToys, itemID)
            end
        end
    end
end

-- Function to save position
function addon.SaveMainFramePosition()
    _G[addon.CONST.DB_NAME].mainFramePosition = _G[addon.CONST.DB_NAME].mainFramePosition or {}
    local point, relativeTo, relativePoint, xOfs, yOfs = addon.mainFrame:GetPoint()

    -- Format the offsets to fit within 6 characters (e.g., max 2 decimal places)
    local formattedXOfs = string.format("%.2f", xOfs)
    local formattedYOfs = string.format("%.2f", yOfs)

    _G[addon.CONST.DB_NAME].mainFramePosition.point = point
    _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo = relativeTo and relativeTo:GetName() or "UIParent"
    _G[addon.CONST.DB_NAME].mainFramePosition.relativePoint = relativePoint
    _G[addon.CONST.DB_NAME].mainFramePosition.xOfs = tonumber(formattedXOfs)  -- Ensure it's saved as a number
    _G[addon.CONST.DB_NAME].mainFramePosition.yOfs = tonumber(formattedYOfs)  -- Ensure it's saved as a number

    addon.DebugPrint("Main frame position saved: Point: " .. tostring(point) ..
        ", Relative To: " .. tostring(_G[addon.CONST.DB_NAME].mainFramePosition.relativeTo) ..
        ", Relative Point: " .. tostring(relativePoint) ..
        ", X Offset: " .. tostring(formattedXOfs) ..
        ", Y Offset: " .. tostring(formattedYOfs))

    -- Update the EditBoxes with the truncated values
    if addon.xPositionInput and addon.yPositionInput then
        addon.xPositionInput:SetText(formattedXOfs)
        addon.yPositionInput:SetText(formattedYOfs)
    end
end

-- Function to load position
function addon.LoadMainFramePosition()
    if _G[addon.CONST.DB_NAME].mainFramePosition then
        addon.mainFrame:ClearAllPoints()
        addon.mainFrame:SetPoint(
            _G[addon.CONST.DB_NAME].mainFramePosition.point or "CENTER", 
            _G[addon.CONST.DB_NAME].mainFramePosition.relativeTo or UIParent, 
            _G[addon.CONST.DB_NAME].mainFramePosition.relativePoint or "CENTER", 
            _G[addon.CONST.DB_NAME].mainFramePosition.xOfs or 0, 
            _G[addon.CONST.DB_NAME].mainFramePosition.yOfs or 0
        )
    else
        addon.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    if addon.xPositionInput and addon.yPositionInput then
        addon.xPositionInput:SetText(tostring(_G[addon.CONST.DB_NAME].mainFramePosition.xOfs or 0))
        addon.yPositionInput:SetText(tostring(_G[addon.CONST.DB_NAME].mainFramePosition.yOfs or 0))
    end
end

-- Function to clear all the toy buttons
function addon.ClearToyButtons()
    for _, toyActionButton in ipairs(addon.CONST.toyButtons) do
        toyActionButton:Hide()
        toyActionButton:SetParent(nil)
    end
    wipe(addon.CONST.toyButtons) -- Clear the toy buttons table
end

-- Create toy buttons for included toys and items
function addon.CreateToyButtons()
    -- if addon.DEBUG then
    --     local trace = debugstack(2, 3, 0)
    --     addon.DebugPrint("CreateToyButtons: Trace\n" .. trace)
    -- end

    addon.ClearToyButtons()

    if addon.DEBUG then
        -- addon.DebugPrint("CreateToyButtons: Scanning", #addon.CONST.includeToys, "toys")
        
        for index, itemID in ipairs(addon.CONST.includeToys) do
            local isToy = PlayerHasToy(itemID)
            local isSpell = IsSpellKnown(itemID)
            local itemCount = GetItemCount(itemID)

            -- addon.DebugPrint(string.format("ItemID %s: isToy=%s, isSpell=%s, itemCount=%s",
            --     itemID, tostring(isToy), tostring(isSpell), tostring(itemCount)))
        end
    end

    local index = 1

    for _, itemID in ipairs(addon.CONST.includeToys) do
        local isToy = PlayerHasToy(itemID)
        local isSpell = IsSpellKnown(itemID)
        
        if isToy or isSpell then
            local toyActionButton = addon.CreateButton(itemID, addon.toyFrame, index)
            table.insert(addon.CONST.toyButtons, toyActionButton)
            index = index + 1
        else
            -- Handle non-toy items (e.g., items in the player's bags)
            local itemCount = GetItemCount(itemID)
            if itemCount > 0 then
                local toyActionButton = addon.CreateButton(itemID, addon.toyFrame, index)
                table.insert(addon.CONST.toyButtons, toyActionButton)
                index = index + 1
            end
        end
    end
    addon.UpdateToyButtonPositions() -- Update button positions after creating them

    -- >>> initialize per-button cooldown states
    if addon.UpdateAllToyButtonCooldowns then
        addon.UpdateAllToyButtonCooldowns()
    end
end

-- Function to toggle toy inclusion in the options panel
function addon.ToggleToyInclusion(itemID, isIncluded)
    if addon.DEBUG then
        addon.DebugPrint("ToggleToyInclusion called for", itemID)
    end
    if type(itemID) == "number" then
        _G[addon.CONST.DB_NAME].toySettings[itemID] = isIncluded
        addon.InitializeIncludedToys()
        addon.ClearToyButtons()
        addon.CreateToyButtons()
    else
        -- Handle or log invalid itemID
    end
end

-- Function to print message if addon has been updated
function addon.AddonUpdatedMessage()
    if _G[addon.CONST.DB_NAME].generalSettings.version ~= addon.CONST.ADDON_VERSION then
        print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Addon has been updated to version " .. addon.CONST.ADDON_VERSION .. ". Updates include: " .. addon.CONST.ADDON_UPDATES)
        _G[addon.CONST.DB_NAME].generalSettings.version = addon.CONST.ADDON_VERSION  -- Update stored version to current version
    end
end

-- Function to display a flavor message
function addon.FlavorMessage()
    local messageCount = #addon.FLAVOR_MESSAGES
    if messageCount == 0 then
        local fallback = "No flavor messages available."
        if addon.flavorTextOutputChannel == "say" then
            SendChatMessage(fallback, "SAY")
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. fallback .. addon.CONST.RESET_COLOR)
        end
        return
    end

    local selectedMessage = addon.FLAVOR_MESSAGES[math.random(1, messageCount)]

    -- If the addon requires a target for flavor messages
    if addon.requiresTargetForFlavor then
        local targetName = UnitName("target")
        if not targetName then
            -- print(addon.CONST.ADDON_TEXT_COLOR .. "No target selected. Cannot send message." .. addon.CONST.RESET_COLOR)
            return
        end
        SendChatMessage(selectedMessage, "SAY", nil, targetName)
    else
        if addon.flavorTextOutputChannel == "say" then
            SendChatMessage(selectedMessage, "SAY")
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. selectedMessage .. addon.CONST.RESET_COLOR)
        end
    end
end

function addon.PrintWelcomeMessage()
    -- Print Welcome Message
    if _G[addon.CONST.DB_NAME].generalSettings.showWelcomeMessage then
        print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. addon.CONST.WELCOME_MESSAGE)
    end
end

-- Function to update the cooldown frame
function addon.UpdateCooldown()
    if not addon.cooldownFrame then
        print(addon.CONST.DEBUG_TEXT_COLOR .. "Cooldown frame not initialized yet!" .. addon.CONST.RESET_COLOR)
        return
    end

    local function normalize(start, dur)
        -- Coerce to numbers
        start = type(start) == "number" and start or 0
        dur   = type(dur)   == "number" and dur   or 0
        -- Convert ms → s if it looks like milliseconds
        if dur > 1000 then
            start = start / 1000
            dur   = dur   / 1000
        end
        return start, dur
    end

    local function GetSpellCooldownSafe(id)
        if C_Spell and C_Spell.GetSpellCooldown then
            local a, b, c, d = C_Spell.GetSpellCooldown(id)
            if type(a) == "table" then
                local info = a
                local start = info.startTime
                local dur   = info.duration
                local en    = info.isEnabled and 1 or 0
                local rate  = info.modRate
                return start, dur, en, rate
            else
                -- Old-style: start, dur, enabled, modRate
                return a, b, c, d
            end
        elseif _G.GetSpellCooldown then
            return _G.GetSpellCooldown(id)
        end
        return nil, nil, nil, nil
    end

    local shown = false

    -- 1) Global Cooldown first
    local spellID = addon.COOLDOWN_SPELL_ID
    if spellID then
        local sStart, sDur, sEnable = GetSpellCooldownSafe(spellID)
        sStart, sDur = normalize(sStart, sDur)

        if addon.DEBUG then
            print(string.format("[GCD] enable=%s dur=%.3f start=%.3f", tostring(sEnable), sDur or 0, sStart or 0))
        end

        if (sEnable == 1 or sEnable == true) and sDur > 0 then
            addon.cooldownFrame:SetCooldown(sStart, sDur)
            shown = true
        end
    end

    -- 2) Fallback to item cooldown if configured and GCD not shown
    if not shown then
        local itemID = addon.COOLDOWN_ITEM_ID
        if itemID and _G.GetItemCooldown then
            local iStart, iDur, iEnable = _G.GetItemCooldown(itemID)
            iStart, iDur = normalize(iStart, iDur)

            if addon.DEBUG then
                print(string.format("[ItemCD %s] enable=%s dur=%.3f start=%.3f", tostring(itemID), tostring(iEnable), iDur or 0, iStart or 0))
            end

            if (iEnable == 1 or iEnable == true) and iDur > 0 then
                addon.cooldownFrame:SetCooldown(iStart, iDur)
                shown = true
            end
        end
    end

    if not shown then
        addon.cooldownFrame:Clear()
    end
end

-- Function to highlight the icon temporarily
function addon.HighlightIcon()
    -- Add glow effect
    ActionButton_ShowOverlayGlow(addon.mainFrame)

    -- Remove glow effect after delay
    C_Timer.After(5, function()
        ActionButton_HideOverlayGlow(addon.mainFrame)
    end)
end

-- Function to Reset the Database to defaults
function addon.ResetDatabase()
    -- Print a confirmation message
    print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Resetting database to default settings...")

    -- Reset all saved variables to their defaults
    for key, value in pairs(addon.defaults) do
        if type(value) == "table" then
            -- For nested tables, reset each entry individually
            _G[addon.CONST.DB_NAME][key] = {}
            for nestedKey, nestedValue in pairs(value) do
                _G[addon.CONST.DB_NAME][key][nestedKey] = nestedValue
            end
        else
            -- For non-table values, reset directly
            _G[addon.CONST.DB_NAME][key] = value
        end
    end

    -- Reset toySettings
    _G[addon.CONST.DB_NAME].toySettings = {}
    for _, toyListEntry in ipairs(addon.toyList) do
        local itemID = toyListEntry.id
        if type(itemID) == "number" then
            _G[addon.CONST.DB_NAME].toySettings[itemID] = true
        end
    end

    -- Reset presets
    _G[addon.CONST.DB_NAME].presets = {}

    -- Refresh options panel UI
    addon.RefreshUI()

    -- Notify the user of the reset
    print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Database reset complete.")
end

-- Function to Refresh the UI when the Database is Reset to defaults
function addon.RefreshUI()
    if addon.DEBUG then
        addon.DebugPrint("addon.RefreshUI called")
    end

    -- Update the General Settings Section
    if addon.generalSettingsCheckbox then
        addon.generalSettingsCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.showWelcomeMessage)
    end
    if addon.showChatMessageCheckbox then
        addon.showChatMessageCheckbox:SetChecked(_G[addon.CONST.DB_NAME].specificSettings.showChatMessage)
    end
    if addon.playSoundWhenFrameShownCheckbox then
        addon.playSoundWhenFrameShownCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.playSoundWhenFrameShown)
    end
    if addon.showButtonOnMouseOverCheckbox then
        addon.showButtonOnMouseOverCheckbox:SetChecked(_G[addon.CONST.DB_NAME].specificSettings.showButtonOnMouseOver)
    end
    addon.UpdateVisibility()

    -- Refresh the Position Settings Section
    if addon.lockPositionCheckbox then
        addon.lockPositionCheckbox:SetChecked(_G[addon.CONST.DB_NAME].generalSettings.lockPosition)
    end
    addon.mainFrame:RegisterForDrag("LeftButton")  -- Register drag
    if addon.presetsDropdown then
        UIDropDownMenu_SetText(addon.presetsDropdown, "Select Preset")
        UIDropDownMenu_Initialize(addon.presetsDropdown, addon.InitializePresetsDropdown)
    end
    addon.LoadMainFramePosition()

    -- Refresh the Toy Button Position Section
    if addon.positionDropdown then
        local selectedPositionIndex
        for i, pos in ipairs(addon.positions) do
            if pos == _G[addon.CONST.DB_NAME].specificSettings.toyFramePosition then
                selectedPositionIndex = i
                break
            end
        end
        UIDropDownMenu_SetSelectedID(addon.positionDropdown, selectedPositionIndex or 1)
        UIDropDownMenu_SetText(addon.positionDropdown, addon.positions[selectedPositionIndex or 1])
    end
    
    -- Refresh Size Settings Section
    if addon.sizeSlider and addon.sizeInput then
        local buttonSize = _G[addon.CONST.DB_NAME].specificSettings.buttonSize or 44
        addon.sizeSlider:SetValue(buttonSize)
        addon.sizeInput:SetText(math.floor(buttonSize))
    end

    addon.UpdateToyButtonPositions()

    -- Refresh Included Toys Section
    if addon.CreateToyCheckboxes then
        addon.CreateToyCheckboxes() -- Recreate toy checkboxes based on current database state
    end
    if addon.ToggleToyInclusion then
        for _, entry in ipairs(addon.CONST.availableToys) do
            local isIncluded = _G[addon.CONST.DB_NAME].toySettings[entry.id]
            addon.ToggleToyInclusion(entry.id, isIncluded)
        end
    end

    -- Force options panel refresh
    if addon.optionsPanel and addon.optionsPanel:IsShown() then
        addon.optionsPanel:Hide()
        C_Timer.After(0.1, function()
            addon.optionsPanel:Show()
        end)
    end
end

-- Function handle when new toys are acquired
function addon.HandleNewToyAcquisition()
    if addon.DEBUG then
        addon.DebugPrint("addon.HandleNewToyAcquisition called")
    end

    local newlyAcquired = {}
    local currentOwnedToyIDs = {}

    -- Scan the toy list
    for _, entry in ipairs(addon.toyList) do
        local itemID = entry.id
        local hasToy = PlayerHasToy(itemID)

        if entry.type == "toy" and hasToy then
            currentOwnedToyIDs[itemID] = true

            -- Update persistent toySettings
            if _G[addon.CONST.DB_NAME].toySettings[itemID] == nil then
                _G[addon.CONST.DB_NAME].toySettings[itemID] = true
            end

            -- Only mark as newly acquired if it's truly new (based on snapshot)
            if hasToySnapshotInitialized and not lastKnownOwnedToyIDs[itemID] then
                table.insert(newlyAcquired, {id = itemID, type = "toy"})
            end
        end
    end

    -- Detect if there's a difference
    local toysChanged = false
    if hasToySnapshotInitialized then
        for toyID in pairs(currentOwnedToyIDs) do
            if not lastKnownOwnedToyIDs[toyID] then
                toysChanged = true
                break
            end
        end
        if not toysChanged then
            for toyID in pairs(lastKnownOwnedToyIDs) do
                if not currentOwnedToyIDs[toyID] then
                    toysChanged = true
                    break
                end
            end
        end
    else
        -- Do not treat first snapshot as change
        if addon.DEBUG then
            addon.DebugPrint("First toy snapshot initialized, skipping refresh.")
        end
    end

    -- Update snapshot for next comparison
    lastKnownOwnedToyIDs = currentOwnedToyIDs
    hasToySnapshotInitialized = true

    -- Always update available toys
    addon.InitializeAvailableToys()

    -- Update availableToys if any new ones were found
    local availableToyIDs = {}
    for _, toy in ipairs(addon.CONST.availableToys) do
        availableToyIDs[toy.id] = true
    end

    for _, toy in ipairs(newlyAcquired) do
        if not availableToyIDs[toy.id] then
            table.insert(addon.CONST.availableToys, toy)
        end
    end

    -- Only refresh UI and print if toys actually changed
    if toysChanged then
        if addon.DEBUG then
            addon.DebugPrint("Toys changed. Refreshing UI.")
        end

        addon.RefreshUI()

        for _, toy in ipairs(newlyAcquired) do
            local _, toyName = C_ToyBox.GetToyInfo(toy.id)
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " ..
                  addon.CONST.RESET_COLOR .. "New toy acquired: " .. (toyName or "Unknown"))
            addon.HighlightIcon()
        end
    elseif addon.DEBUG then
        addon.DebugPrint("No toy changes detected. Skipping refresh.")
    end
end

function addon.PlayerHasProfession(professionName)
    local professions = { GetProfessions() }
    for _, profIndex in ipairs(professions) do
        if profIndex then
            local name = select(1, GetProfessionInfo(profIndex))
            if name == professionName then
                return true
            end
        end
    end
    return false
end

-- Safe spell cooldown getter (supports table or multi-return API)
local function GetSpellCooldownSafe(id)
    if C_Spell and C_Spell.GetSpellCooldown then
        local a, b, c, d = C_Spell.GetSpellCooldown(id)
        if type(a) == "table" then
            local info = a
            return info.startTime or 0, info.duration or 0, (info.isEnabled and 1 or 0), info.modRate
        else
            return a or 0, b or 0, c or 0, d
        end
    elseif _G.GetSpellCooldown then
        local s, d, e = _G.GetSpellCooldown(id)
        return s or 0, d or 0, e or 0, 1
    end
    return 0, 0, 0, 1
end

function addon.UpdateToyButtonCooldown(btn)
    if not btn or not btn.cooldown or not btn._cdType or not btn._cdID then return end

    -- SPELL buttons: just use the spell cooldown
    if btn._cdType == "spell" then
        local sStart, sDur = GetSpellCooldownSafe(btn._cdID)
        if sDur and sDur > 0 then
            btn.cooldown:SetCooldown(sStart or 0, sDur)
        else
            if btn.cooldown.Clear then btn.cooldown:Clear() else btn.cooldown:SetCooldown(0, 0) end
        end
        return
    end

    -- ITEM/TOY buttons: try the item’s cooldown first
    local iStart, iDur = 0, 0
    if _G.GetItemCooldown then
        iStart, iDur = _G.GetItemCooldown(btn._cdID)
    end
    if iDur and iDur > 0 then
        btn.cooldown:SetCooldown(iStart or 0, iDur)
        return
    end

    -- Fallback: some toys/items (e.g., Ultrasafe Transporters/portals) expose cooldown only on their spell
    local spellID = btn._spellFromItem
    if spellID == nil then
        local _, sid = GetItemSpell(btn._cdID)
        spellID = sid
        btn._spellFromItem = sid or false
        if not sid and C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(btn._cdID)
            if btn.RegisterEvent then btn:RegisterEvent("GET_ITEM_INFO_RECEIVED") end
        end
    end

    if spellID then
        local sStart, sDur = GetSpellCooldownSafe(spellID)
        if sDur and sDur > 0 then
            btn.cooldown:SetCooldown(sStart or 0, sDur)
            return
        end
    end

    -- Nothing active
    if btn.cooldown.Clear then btn.cooldown:Clear() else btn.cooldown:SetCooldown(0, 0) end
end

function addon.UpdateAllToyButtonCooldowns()
    for _, btn in ipairs(addon.CONST.toyButtons) do
        addon.UpdateToyButtonCooldown(btn)
    end
end
