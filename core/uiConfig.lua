-- MARK: UI Configuration Module
-- Centralized UI dimensions and styling configuration for NextKey
-- Extracted from ui/main.lua to improve maintainability

local _, NextKey222 = ...

local UIConfig = {
    -- MARK: Main Window Configuration
    WINDOW = {
        WIDTH = 600,                    -- Overall window width
        BASE_HEIGHT = 645,              -- Base window height (changes dynamically)
        DUNGEON_VIEW_HEIGHT = 775,      -- Height when showing dungeon cards
        PLAYER_VIEW_HEIGHT = 645,       -- Height when showing player keystones
        PLAYER_VIEW_HEIGHT_DEBUG = 675  -- Height for keystone view when debug controls are visible
    },
    
    -- MARK: Card Layout Configuration
    CARD = {
        HEIGHT = 88,                    -- Standard keystone card height (matches UI factory)
        HEIGHT_COMPACT = 28,            -- Compact keystone card height
        HEIGHT_DUNGEON = 75,            -- Dungeon card height (shorter than keystones)
        VERTICAL_SPACING = 8,           -- Vertical space between cards
        MARGIN = 8,                     -- Margin around each card
        HEADER_PADDING = 8,            -- Extra space for headers and padding
        CONTENT_INSET_TOP = 9,         -- Top inset for card content area
        CONTENT_INSET_BOTTOM = 12       -- Bottom inset for card content area
    },
    
    -- MARK: Icon Configuration
    ICON = {
        SIZE = 48,                      -- Icon image size (64x64px)
        WIDTH = 60,                     -- Icon container width
        ROLE_SIZE = 16,                 -- Role icon size (16x16px)
        ROLE_WIDTH = 20                 -- Role icon container width
    },
    
    -- MARK: Text Element Widths
    TEXT = {
        NAME_LABEL_WIDTH = 260,         -- Dungeon name display width
        SCORE_LABEL_WIDTH = 90          -- IO score display width
    },
    
    -- MARK: Button Dimensions
    BUTTON = {
        HEIGHT = 28,                    -- Standard height for all buttons
        TELEPORT_WIDTH = 100,           -- Teleport button width
        LOOT_WIDTH = 75,                -- Loot button width
        PREFERENCE_WIDTH = 50           -- Like/Dislike button width
    },
    
    -- MARK: Layout Configuration
    LAYOUT = {
        CONTAINER_PADDING = 0,          -- Padding inside the main results container
        USE_TIGHT_LAYOUT = true,        -- Use SimpleGroup for minimal padding
        USE_ULTRA_TIGHT = false,        -- Use raw frames for absolute minimal padding
        RESULTS_TOP_PADDING = 0         -- Vertical space between control buttons and results list
    },
    
    
    -- MARK: Teleport Card Configuration (from ui/teleport.lua)
    TELEPORT_CARD = {
        CARD_ICON_SIZE = 48,            -- Icon size for teleport cards
        CARD_HEIGHT = 68,               -- Height of teleport cards (reduced from 72)
        CARD_PADDING = 0,               -- Padding around teleport cards (reduced from 12)
        WINDOW_WIDTH = 320,             -- Width of teleport window
        CARD_SPACING = 0,               -- Spacing between teleport cards (reduced from 8)
        COMPACT_ICON_SIZE = 48,         -- Icon size in compact mode
        COMPACT_SPACING = 4,            -- Spacing between compact icons
        FOOTER_INSTRUCTION_FULL = "Compact mode in /nk opt",
        FOOTER_INSTRUCTION_COMPACT = "Click to TP"
    },
    
    -- MARK: Hearthstone Selector Configuration (from ui/hearthstoneSelector.lua)
    HEARTHSTONE_SELECTOR = {
        WINDOW_WIDTH = 340,             -- Width of hearthstone selector window
        WINDOW_HEIGHT = 300,            -- Height of hearthstone selector window
        MIN_COLUMNS = 8,                -- Minimum columns to ensure text fits
        MAX_COLUMNS = 10,               -- Maximum columns to prevent window getting too wide
        SAVE_BUTTON_HEIGHT = 30         -- Height of save button
    },
    
    -- MARK: Loot Window Configuration (from ui/lootWindow.lua)
    LOOT_WINDOW = {
        WINDOW_WIDTH = 400,             -- Width of loot window (wider for long titles)
        WINDOW_HEIGHT = 305,            -- Height of loot window
        LIST_ITEM_HEIGHT = 65           -- Height of list items in loot window
    },
    
    -- MARK: Dungeon Cards Configuration (from ui/dungeonCards.lua)
    DUNGEON_CARDS = {
        CARD_WIDTH = 350,               -- Width of dungeon cards
        CARD_HEIGHT = 90,               -- Height of dungeon cards
        CARD_PADDING = 10,              -- Padding around dungeon cards
        CARDS_PER_ROW = 2,              -- Number of cards per row
        CARD_WIDTH_COMPACT = 250,       -- Width of compact dungeon cards
        CARD_HEIGHT_COMPACT = 60,       -- Height of compact dungeon cards
        CARDS_PER_ROW_COMPACT = 3       -- Number of compact cards per row
    },
    
    -- MARK: Spell Configuration (from ui/teleport.lua)
    SPELL = {
        BANK_PLAYER = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0,
        BANK_PET = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1
    },
    
    -- MARK: Item Configuration (from ui/teleport.lua)
    ITEM = {
        HEARTHSTONE_ID = 6948            -- Standard Hearthstone item ID
    }
}

-- Register module
NextKey222.UIConfig = UIConfig
NextKey222.RegisterModule("UIConfig", UIConfig)

-- Module interface
function UIConfig:Initialize()
    return true
end

-- Helper function to get window height for view mode
function UIConfig:GetWindowHeight(viewMode, debugMode)
    local isDebug = false
    if type(debugMode) == "table" then
        isDebug = debugMode.debugMode or debugMode.isDebugMode
    else
        isDebug = debugMode == true
    end

    if viewMode == "dungeons" then
        return self.WINDOW.DUNGEON_VIEW_HEIGHT
    else
        if isDebug and self.WINDOW.PLAYER_VIEW_HEIGHT_DEBUG then
            return self.WINDOW.PLAYER_VIEW_HEIGHT_DEBUG
        end
        return self.WINDOW.PLAYER_VIEW_HEIGHT
    end
end

return UIConfig
