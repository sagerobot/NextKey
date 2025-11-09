-- MARK: UI Configuration Module
-- Centralized UI dimensions and styling configuration for NextKey
-- Extracted from ui/main.lua to improve maintainability

local _, NextKey222 = ...

local UIConfig = {
    -- MARK: Main Window Configuration
    WINDOW = {
        WIDTH = 600,                    -- Overall window width
        BASE_HEIGHT = 645,              -- Base window height (changes dynamically)
        DUNGEON_VIEW_HEIGHT = 776,      -- Height when showing dungeon cards (8 cards × 75px + ~150px UI chrome + small buffer)
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
    
    -- MARK: Poll Window Configuration (from ui/organizer/surveyDialog.lua)
    POLL_WINDOW = {
        -- Phase 1: Participation
        PHASE1_WIDTH = 380,
        PHASE1_HEIGHT = 280,
        PARTICIPATION_CARD_HEIGHT_YES = 50,     -- 25% smaller (was 90)
        PARTICIPATION_CARD_HEIGHT_NO = 35,      -- 50% smaller (was 90)
        PARTICIPATION_CARD_SPACING = 8,
        
        -- Phase 2: Alt Selection
        PHASE2_WIDTH = 420,
        PHASE2_BASE_HEIGHT = 180,
        PHASE2_CARD_HEIGHT = 95,
        PHASE2_MAX_HEIGHT = 700,
        
        -- Phase 3: Spec Selection
        PHASE3_WIDTH = 340,
        PHASE3_BASE_HEIGHT = 160,
        PHASE3_SPEC_HEIGHT = 80,
        
        -- Card styling
        ICON_SIZE = 48,
        CARD_PADDING = 8,
        
        -- Colors
        COLOR_GREEN_BORDER = {0.2, 0.8, 0.2, 1},
        COLOR_RED_BORDER = {0.8, 0.2, 0.2, 1},
        COLOR_YELLOW_BORDER = {0.9, 0.8, 0.2, 1},
        COLOR_GREY_BORDER = {0.35, 0.35, 0.35, 0.8}
    },
    
    -- MARK: Spell Configuration (from ui/teleport.lua)
    SPELL = {
        BANK_PLAYER = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0,
        BANK_PET = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1
    },
    
    -- MARK: Item Configuration (from ui/teleport.lua)
    ITEM = {
        HEARTHSTONE_ID = 6948            -- Standard Hearthstone item ID
    },
    
    -- MARK: M+ Organizer Configuration
    ORGANIZER = {
        -- Window dimensions
        COLUMN_WIDTH = 195,              -- Width of each group column (increased from 180 to accommodate wider expanded cards)
        BENCH_WIDTH = 260,               -- Width of bench column
        PADDING = 20,                    -- Padding at window edges (left/right)
        BENCH_LEFT_GAP = 10,             -- Gap between M+ groups and bench (left side of bench)
        BENCH_RIGHT_GAP = 54,            -- Gap between bench and right window edge
        
        -- Section heights
        HEADER_HEIGHT = 90,              -- Header section height (2-row layout: poll + organize)
        GROUP_HEIGHT = 550,              -- Height of group/bench area
        OPT_OUT_HEIGHT = 90,             -- Opt-out section height
        STATUS_BAR_HEIGHT = 30,          -- Status bar height
        
        -- Spacing between sections
        HEADER_TO_GROUPS_GAP = 20,       -- Gap between header controls and M+ groups/bench area
        GROUP_TO_OPTOUT_GAP = 5,        -- Gap between groups/bench and opt-out section (increased for better spacing)
        OPTOUT_TO_BOTTOM_GAP = 40,       -- Gap between opt-out section and bottom of window (increased to prevent close button overlap)
        
        -- Button sizes (consistent constants)
        BUTTON_SIZES = {
            PRIMARY = 100,               -- Standard action buttons
            DROPDOWN = 120,              -- Dropdowns (need arrow space)
            SECONDARY = 120,             -- Emphasized actions
            CHECKBOX = 58,               -- Checkbox labels
            DEBUG = 100                  -- Debug utilities
        },
        
        -- Bench configuration
        BENCH_TITLE_HEIGHT = 10,         -- Height of bench title bar
        BENCH_SCROLL_GAP = 8,            -- Gap between title and scroll frame
        BENCH_CARD_HEIGHT = 25,          -- Height of bench player cards
        BENCH_CARD_SPACING = 3,          -- Spacing between bench cards
        BENCH_CARD_LEFT_PADDING = 3,     -- Left padding before first role icon in bench cards
        BENCH_HORIZONTAL_PADDING = 10,   -- Left/right padding inside bench frame
        BENCH_SCROLLBAR_PADDING = 18,    -- Extra padding for scrollbar
        
        -- Opt-out card configuration
        OPT_OUT_CARD_WIDTH = 90,         -- Width of opt-out cards
        OPT_OUT_CARD_HEIGHT = 40,        -- Height of opt-out cards
        OPT_OUT_PADDING = 5,             -- Padding from edges
        
        -- Group slot configuration
        SLOT_HEIGHT = 100,               -- Height of each group slot
        SLOT_SPACING = 10,               -- Spacing between slots
        
        -- Header layout
        HEADER_LABEL_HEIGHT = 16,        -- Section label height
        HEADER_BUTTON_HEIGHT = 24,       -- Button row height
        HEADER_ROW_GAP = 8,              -- Gap between rows
        HEADER_SECTION_GAP = 4,          -- Gap between label and buttons
        
        -- Group title bar button config (add/remove groups)
        GROUP_BUTTON_SIZE = 20,          -- Small icon buttons
        GROUP_BUTTON_SPACING = 3,        -- Gap between [-] and [+]
        GROUP_BUTTON_RIGHT_MARGIN = 2    -- Distance from right edge
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
