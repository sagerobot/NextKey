-- HearthstoneToys_EventHandlers.lua
-- print("HearthstoneToys_EventHandlers.lua")

-- Access the addon namespace
local addonName, addon = ...

-- Ensure the EventHandlers module is part of the addon namespace
addon.EventHandlers = {}

----------------------------
-- Function for Player Login
----------------------------
local function PlayerLogin()
    C_Timer.After(1, function()
        addon.LoadMainFramePosition()
        addon.AddonUpdatedMessage()
    end)
    C_Timer.After(2, function()  -- delay
        addon.InitializeAvailableToys()
        addon.InitializeIncludedToys()
        addon.CreateToyFrame()
        addon.CreateToyButtons()
        addon.UpdateToyButtonPositions()
        addon.UpdateCooldown()
        if addon.UpdateAllToyButtonCooldowns then addon.UpdateAllToyButtonCooldowns() end
        addon.mainFrame:SetSize(addon.buttonSize, addon.buttonSize)
        addon.PrintWelcomeMessage()
        C_Timer.After(0.1, addon.UpdateVisibility)
    end)
end

-- Define an initialization in progress flag
addon.isInitializing = true

-- Define a debounce
local toyUpdateDebounceActive = false

------------------
-- Register events
------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("TOYS_UPDATED")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addon.CONST.ADDON_NAME then
        -- Your addon is loaded, initialize saved variables here
        addon.InitializeAddon()
        eventFrame:UnregisterEvent("ADDON_LOADED") -- Unregister to prevent redundant calls
    elseif event == "PLAYER_LOGIN" then
        local hasProfession = not addon.isProfessionRequired or addon.PlayerHasProfession(addon.requiredProfession)
        
        if hasProfession then
            C_Timer.After(1, function()
                PlayerLogin()
            end)
            C_Timer.After(2, function()
                addon.isInitializing = false
                if addon.DEBUG then
                    addon.DebugPrint("Initialization complete. TOYS_UPDATED events will now be processed.")
                end
            end)
        else
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "You do not have the required profession (" .. addon.requiredProfession .. ") to use this addon.")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(4, function()
            addon.UpdateCooldown()
            if addon.UpdateAllToyButtonCooldowns then addon.UpdateAllToyButtonCooldowns() end
            if #addon.CONST.toyButtons == 0 then
                if addon.DEBUG then
                    addon.DebugPrint("PLAYER_ENTERING_WORLD: Rebuilding toy buttons...")
                end
            addon.CreateToyFrame()
            addon.CreateToyButtons()
        end
        end)
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if addon.DEBUG then print("SPELL_UPDATE_COOLDOWN") end
        addon.UpdateCooldown()
        if addon.UpdateAllToyButtonCooldowns then addon.UpdateAllToyButtonCooldowns() end
    elseif event == "BAG_UPDATE_COOLDOWN" then
        if addon.DEBUG then print("BAG_UPDATE_COOLDOWN") end
        addon.UpdateCooldown()
        if addon.UpdateAllToyButtonCooldowns then addon.UpdateAllToyButtonCooldowns() end
    elseif event == "TOYS_UPDATED" then
        if addon.isInitializing then
            if addon.DEBUG then
                addon.DebugPrint("TOYS_UPDATED ignored during initialization.")
            end
            return
        end

        if not toyUpdateDebounceActive then
            toyUpdateDebounceActive = true

            if addon.DEBUG then
                addon.DebugPrint("TOYS_UPDATED: Debounced call scheduled.")
            end

            -- Wait briefly to allow a burst of events to settle
            C_Timer.After(0.5, function()
                toyUpdateDebounceActive = false

                if addon.DEBUG then
                    addon.DebugPrint("TOYS_UPDATED: Executing HandleNewToyAcquisition.")
                end

                addon.HandleNewToyAcquisition()

                -- Retry toyFrame creation if needed
                if #addon.CONST.toyButtons == 0 then
                    if addon.DEBUG then
                        addon.DebugPrint("TOYS_UPDATED: No toy buttons found, retrying CreateToyFrame...")
                    end
                    addon.CreateToyFrame()
                end
            end)
        else
            if addon.DEBUG then
                addon.DebugPrint("TOYS_UPDATED: Skipped due to active debounce.")
            end
        end
    end
end)