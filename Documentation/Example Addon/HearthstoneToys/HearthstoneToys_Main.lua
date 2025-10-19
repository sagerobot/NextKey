-- HearthstoneToys_Main.lua
-- print("HearthstoneToys_Main.lua")

-- Declare the addon namespace
HearthstoneToys = {}
local addonName, addon = ...

-- Define a debug flag
addon.DEBUG = false  -- Set to true to enable debug prints

---------------
-- Constants --
---------------
addon.CONST = {
    ADDON_NAME = "HearthstoneToys",
    ADDON_DISPLAY_NAME = "Hearthstone Toys",
    DB_NAME = "HearthstoneToysDB",
    ADDON_ICON_TEXTURE = "Interface\\Icons\\INV_Misc_Rune_01",
    TOY_FRAME_SHOW_SOUND_ID = 2022070,
    TOY_FRAME_HIDE_SOUND_ID = 2906065,
    ADDON_TEXT_COLOR = "|cFF00a7ff",
    DEBUG_TEXT_COLOR = "|cFFff0000",
    RESET_COLOR = "|r",
    mainFrame,
    toyButtons = {},
    availableToys = {},
    includeToys = {},
    presetNameInput,
    presetsDropdown,
    xPositionInput, yPositionInput,
    UpdateCooldown,
    optionsCategoryId,
    ADDON_VERSION = "1.11.6", -- Update this with each release
    ADDON_UPDATES = "Added Redeployment Module. Updated code to show the cooldown. Reminder: click for toy buttons, right-click for options, shift click to use random toy. Please leave bug reports or feature requests on the Curseforge page.",
    WELCOME_MESSAGE = "Type '/hst' to access the options panel where you can adjust settings, including disabling this welcome message. Please leave bug reports or feature requests on the Curseforge page.",
}

addon.isProfessionRequired = false
addon.requiredProfession = nil
addon.flavorTextOutputChannel = "private"
addon.requiresTargetForFlavor = false

-- Always track the GCD by spell ID
addon.COOLDOWN_SPELL_ID = 61304

-- Hearthstone shared item CD (keep this for Hearthstone Toys)
addon.COOLDOWN_ITEM_ID = 6948

--------------------------
-- List of toy item IDs --
--------------------------
addon.toyList = {
    {id = 54452, type = "toy"}, -- Ethereal Portal
    {id = 64488, type = "toy"}, -- The Innkeeper's Daughter
    {id = 93672, type = "toy"}, -- Dark Portal
    {id = 110560, type = "toy"}, -- Garrison Hearthstone
    {id = 140192, type = "toy"}, -- Dalaran Hearthstone
    {id = 142542, type = "toy"}, -- Tome of Town Portal
    {id = 162973, type = "toy"}, -- Greatfather Winter's Hearthstone
    {id = 163045, type = "toy"}, -- Headless Horseman's Hearthstone
    {id = 163206, type = "toy"}, -- Weary Spirit Binding
    {id = 165669, type = "toy"}, -- Lunar Elder's Hearthstone
    {id = 165670, type = "toy"}, -- Peddlefeet's Lovely Hearthstone
    {id = 165802, type = "toy"}, -- Noble Gardener's Hearthstone
    {id = 166746, type = "toy"}, -- Fire Eater's Hearthstone
    {id = 166747, type = "toy"}, -- Brewfest Reveler's Hearthstone
    {id = 168907, type = "toy"}, -- Holographic Digitalization Hearthstone
    {id = 172179, type = "toy"}, -- Eternal Traveler's Hearthstone
    {id = 180290, type = "toy"}, -- Night Fae Hearthstone
    {id = 182773, type = "toy"}, -- Necrolord Hearthstone
    {id = 183716, type = "toy"}, -- Venthyr Sinstone
    {id = 184353, type = "toy"}, -- Kyrian Hearthstone
    {id = 188952, type = "toy"}, -- Dominated Hearthstone
    {id = 190196, type = "toy"}, -- Enlightened Hearthstone
    {id = 190237, type = "toy"}, -- Broker Translocation Matrix
    {id = 193588, type = "toy"}, -- Timewalker's Hearthstone
    {id = 200630, type = "toy"}, -- Ohnir Windsage's Hearthstone
    {id = 206195, type = "toy"}, -- Path of the Naaru
    {id = 208704, type = "toy"}, -- Deepdweller's Earthen Hearthstone
    {id = 209035, type = "toy"}, -- Hearthstone of the Flame
    {id = 210455, type = "toy"}, -- Draenic Hologem
    {id = 212337, type = "toy"}, -- Stone of the Hearth
    {id = 228940, type = "toy"}, -- Notorious Thread's Hearthstone
    {id = 236687, type = "toy"}, -- Explosive Hearthstone
    {id = 246565, type = "toy"}, -- Cosmic Hearthstone
    {id = 245970, type = "toy"}, -- P.O.S.T. Master's Express Hearthstone
    {id = 235016, type = "toy"}, -- Redeployment Module
    {id = 6948, type = "item"}, -- Default Hearthstone
    {id = 37118, type = "item"}, -- Scroll of Recall
    {id = 44314, type = "item"}, -- Scroll of Recall II
    {id = 44315, type = "item"}, -- Scroll of Recall III
    {id = 556, type = "spell"}, -- Astral Recall
}

--------------------
-- Flavor Message --
--------------------
addon.FLAVOR_MESSAGES = {
    "A wise mage once said, 'The fireball spell is the best way to say hello!'",
    "Beware the Dark Iron Dwarves. Their brew is stronger than their armor!",
    "The real secret of the Shaman's power is the sound of the totem's beat!",
    "Rogues don’t need a reason to stab people, but it's usually money.",
    "Hunters always know where their prey is, especially when they're hungry.",
    "Priests heal, but they never forget the time you got them killed!",
    "Warriors love their battles, but they secretly crave a good meal.",
    "Paladins are always prepared. They carry extra blessings just in case!",
    "Mages like to keep their spells hot, and their puns even hotter!",
    "Druids are all about nature, but they don’t mind the occasional moonfire!",
    "Druids are one with nature, but they can’t resist a good bear hug!",
    "Mages freeze their enemies, but their jokes are the real cold snap!",
    "Paladins have a hammer for every occasion... and a Light to match!",
    "Warriors live by the sword... and die by the bigger sword.",
    "Priests smite their foes with holy wrath, but they're really just practicing for bingo night.",
    "Rogues vanish, but your wallet vanishes faster!",
    "Shamans summon storms, but they’re the real force of nature!",
    "Hunters’ pets are loyal, but don't ask them to fetch!",
    "Warlocks always have friends in low places... like the Twisting Nether.",
    "Warlocks don’t just summon demons; they have them on speed dial.",
    "When a Warlock says 'let's make a pact,' it's best to read the fine print.",
    "Monks may be zen, but they’ll still knock you out with a keg!",
    "Demon Hunters have vision like no other-just don't ask how they lost their depth perception.",
    "Demon Hunters don't just stare; they glare right through you!",
    "Demon Hunters leap before they look... and it usually works out!",
    "Death Knights don't need a heart to break yours!",
    "Gnomes may be small, but their egos are perfectly sized!",
    "Dwarves believe that anything can be fixed with a hammer... even bad jokes.",
    "Orcs don't need coffee—they wake up ready to smash something.",
    "Tauren always know where the grass is greener. It's their job to find it!",
    "Blood Elves have perfected the art of looking fabulous while judging your fashion sense.",
    "Trolls might seem laid-back, but they take their head-hunting very seriously.",
    "Humans are great diplomats, mostly because they’ve had so much practice apologizing.",
    "Undead don’t need beauty sleep, but it’s still polite not to mention it.",
    "Goblins believe that 'more explosions' is the solution to any problem.",
    "For Goblins, safety regulations are just suggestions—expensive ones!",
    "Even after thousands of years, Night Elves are still trying to figure out why their hair glows at night.",
}

-- Saved variable to store settings
_G[addon.CONST.DB_NAME] = _G[addon.CONST.DB_NAME] or {}
_G[addon.CONST.DB_NAME].generalSettings = _G[addon.CONST.DB_NAME].generalSettings or {}
_G[addon.CONST.DB_NAME].mainFramePosition = _G[addon.CONST.DB_NAME].mainFramePosition or {}
_G[addon.CONST.DB_NAME].specificSettings = _G[addon.CONST.DB_NAME].specificSettings or {}
_G[addon.CONST.DB_NAME].toySettings = _G[addon.CONST.DB_NAME].toySettings or {}
_G[addon.CONST.DB_NAME].presets = _G[addon.CONST.DB_NAME].presets or {}

-- Default settings
addon.defaults = {
    generalSettings = {
        showWelcomeMessage = true,
        playSoundWhenFrameShown = true,
        lockPosition = false,
        version = addon.CONST.ADDON_VERSION,
    },
    mainFramePosition = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        xOfs = 0,
        yOfs = 0,
    },
    specificSettings = {
        showChatMessage = true,
        showButtonOnMouseOver = false,
        toyFramePosition = "LEFT",
        buttonSize = 44,
    },
}

-- Initialize saved variables
function addon.InitializeAddon()
    if addon.DEBUG then
        addon.DebugPrint("addon.InitializeAddon called")
    end
    -- Initialize database using defaults
    for key, value in pairs(addon.defaults) do
        if type(value) == "table" then
            if not _G[addon.CONST.DB_NAME][key] then
                _G[addon.CONST.DB_NAME][key] = {}
            end
            for nestedKey, nestedValue in pairs(value) do
                if _G[addon.CONST.DB_NAME][key][nestedKey] == nil then
                    _G[addon.CONST.DB_NAME][key][nestedKey] = nestedValue
                end
            end
        else
            if _G[addon.CONST.DB_NAME][key] == nil then
                _G[addon.CONST.DB_NAME][key] = value
            end
        end
    end

    -- Set buttonSize to a local variable for easy access
    addon.buttonSize = _G[addon.CONST.DB_NAME].specificSettings.buttonSize

    -- Initialize toySettings with PlayerHasToy validation
    for _, toyListEntry in ipairs(addon.toyList) do
        local itemID = toyListEntry.id
        if type(itemID) == "number" and _G[addon.CONST.DB_NAME].toySettings[itemID] == nil then
            -- Default to true only if the player owns the toy
            _G[addon.CONST.DB_NAME].toySettings[itemID] = PlayerHasToy(itemID)
        end
    end

    -- Initialize components
    addon.UIFrames.Initialize()
    addon.OptionsPanel.Initialize()

    C_Timer.After(0.2, function()
        -- Register Slash Command
        SLASH_HST1 = "/hst"
        SlashCmdList["HST"] = function(msg)
            if addon.OptionsPanel.optionsCategoryId then
                -- Open the options panel using the registered category ID
                Settings.OpenToCategory(addon.OptionsPanel.optionsCategoryId)
            else
                print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Options panel not registered yet.")
            end
        end
    end)
end

if addon.DEBUG then
    -- TEST COMMAND TO TEMPORARILY REMOVE A TOY FROM THE availableToys table
    SLASH_REMOVETOY1 = "/removetoy"
    SlashCmdList["REMOVETOY"] = function(msg)
        local testToyID = tonumber(msg)
        if not testToyID then
            print("Usage: /removetoy <toyID>")
            return
        end

        local isValidToy = false
        for _, toy in ipairs(addon.toyList) do
            if toy.id == testToyID then
                isValidToy = true
                break
            end
        end

        if not isValidToy then
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Invalid toy ID.")
            return
        end

        -- Remove from toySettings
        _G[addon.CONST.DB_NAME].toySettings[testToyID] = nil
        addon.DebugPrint("Toy removed from toySettings: " .. testToyID)

        -- Fake that the player does NOT own it for this snapshot
        local originalPlayerHasToy = PlayerHasToy
        PlayerHasToy = function(id)
            if id == testToyID then
                return false
            else
                return originalPlayerHasToy(id)
            end
        end

        -- Rebuild snapshot with the toy marked as not owned
        addon.HandleNewToyAcquisition()

        -- Restore
        PlayerHasToy = originalPlayerHasToy

        addon.InitializeIncludedToys()
        addon.RefreshUI()
    end

    -- TEST COMMAND TO SIMULATE ACQUIRING A TOY
    SLASH_ACQUIRETOY1 = "/acquiretoy"
    SlashCmdList["ACQUIRETOY"] = function(msg)
        local testToyID = tonumber(msg) -- Parse the toy ID from the command
        if not testToyID then
            print("Usage: /acquiretoy <toyID>")
            return
        end

        -- Validate that the toy exists in toyList
        local isValidToy = false
        for _, toy in ipairs(addon.toyList) do
            if toy.id == testToyID then
                isValidToy = true
                break
            end
        end

        if not isValidToy then
            print(addon.CONST.ADDON_TEXT_COLOR .. "[" .. addon.CONST.ADDON_DISPLAY_NAME .. "]: " .. addon.CONST.RESET_COLOR .. "Invalid toy ID.")
            return
        end

        -- Simulate PlayerHasToy behavior for the test
        local originalPlayerHasToy = PlayerHasToy -- Backup original function
        
        PlayerHasToy = function(id)
            if id == testToyID then
                return true -- Simulate that the toy is now owned
            else
                return originalPlayerHasToy(id)
            end
        end

        addon.DebugPrint("Simulating acquisition of toy ID:", testToyID)

        -- Trigger the normal acquisition handling process
        addon.HandleNewToyAcquisition()

        -- Restore original PlayerHasToy function
        PlayerHasToy = originalPlayerHasToy
    end
end