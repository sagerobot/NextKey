-- MARK: UI Configuration Module
-- Centralized UI dimensions and styling configuration for NextKey
-- Extracted from ui/main.lua to improve maintainability

local _, NextKey222 = ...

local UIConfig = {
    -- MARK: Window Dimensions
    WINDOW = {
        WIDTH = 570,                    -- Overall window width
        BASE_HEIGHT = 645,              -- Base window height (changes dynamically)
        DUNGEON_VIEW_HEIGHT = 775,      -- Height when showing dungeon cards
        PLAYER_VIEW_HEIGHT = 645,       -- Height when showing player keystones
        PLAYER_VIEW_HEIGHT_DEBUG = 675  -- Height for keystone view when debug controls are visible
    },
    
    -- MARK: Card Layout
    CARD = {
        HEIGHT = 35,                    -- Height of each individual card
        VERTICAL_SPACING = 0,           -- Vertical space between cards (0 = no gap)
        MARGIN = 0,                     -- Margin around each card
        HEADER_PADDING = 10             -- Extra space for headers and padding
    },
    
    -- MARK: Icon Configuration
    ICON = {
        SIZE = 32,                      -- Icon image size (32x32px)
        WIDTH = 40,                     -- Icon container width
        ROLE_SIZE = 16,                 -- Role icon size (16x16px)
        ROLE_WIDTH = 20                  -- Role icon container width
    },
    
    -- MARK: Text Element Widths
    TEXT = {
        NAME_LABEL_WIDTH = 180,         -- Dungeon name display width
        SCORE_LABEL_WIDTH = 90          -- IO score display width
    },
    
    -- MARK: Button Dimensions
    BUTTON = {
        HEIGHT = 28,                    -- Standard height for all buttons
        TELEPORT_WIDTH = 100,           -- Teleport button width
        LOOT_WIDTH = 75,                -- Loot button width  
        PREFERENCE_WIDTH = 50,          -- Like/Dislike button width
        CLOSE_WIDTH = 80,               -- Close button width
        CLOSE_HEIGHT = 25,              -- Close button height
        TOGGLE_WIDTH = 120,             -- Toggle button width (wider for longer text)
        TOGGLE_HEIGHT = 25              -- Toggle button height
    },
    
    -- MARK: Layout Configuration
    LAYOUT = {
        CONTAINER_PADDING = 0,          -- Padding inside the main results container
        USE_TIGHT_LAYOUT = true,        -- Use SimpleGroup for minimal padding
        USE_ULTRA_TIGHT = false,        -- Use raw frames for absolute minimal padding
        RESULTS_TOP_PADDING = 60        -- Vertical space between control buttons and results list
    },
    
    -- MARK: Teleport Window Configuration
    TELEPORT_WINDOW = {
        -- Standard keystone sizing
        STANDARD = {
            MIN_WIDTH = 100,            -- Minimum window width for regular keystones
            LEFT_PADDING = 14,          -- Left side padding
            RIGHT_PADDING = 14,         -- Right side padding
            BETWEEN_PADDING = 12,       -- Space between icon and text columns
            ELEMENT_SPACING = 6,        -- Spacing between text elements vertically
            BOTTOM_PADDING = 12         -- Bottom padding
        },
        -- Compact dungeon portal sizing
        COMPACT = {
            MIN_WIDTH = 130,            -- Minimum window width for dungeon portals
            LEFT_PADDING = 12,          -- Reduced left padding
            RIGHT_PADDING = 12,         -- Reduced right padding
            BETWEEN_PADDING = 10,       -- Reduced space between columns
            ELEMENT_SPACING = 4,        -- Tighter vertical spacing
            BOTTOM_PADDING = 6          -- Minimal bottom padding
        }
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
