-- MARK: Responsive System
-- Centralized responsive layout management with adaptive sizing and positioning
-- Phase 7: Responsive Layout Configuration System

local _, NextKey222 = ...

local Responsive = {}
NextKey222.Responsive = Responsive

-- Register with module system
NextKey222.RegisterModule("Responsive", Responsive)

-- MARK: Layout Constants
-- Standardized layout breakpoints and configurations

Responsive.breakpoints = {
    mobile = 800,      -- Mobile breakpoint width
    tablet = 1200,     -- Tablet breakpoint width
    desktop = 1600,    -- Desktop breakpoint width
    large = 99999      -- Large screens (catch-all)
}

Responsive.layoutModes = {
    COMPACT = "compact",      -- Compact layout for small screens
    STANDARD = "standard",    -- Standard layout for medium screens
    EXPANDED = "expanded",    -- Expanded layout for large screens
    AUTO = "auto"             -- Automatically select based on screen size
}

-- MARK: State Management
-- Current layout state and configuration

Responsive.currentMode = Responsive.layoutModes.AUTO
Responsive.currentBreakpoint = nil
Responsive.screenWidth = GetScreenWidth()
Responsive.screenHeight = GetScreenHeight()

-- MARK: Breakpoint Detection
-- Functions to detect current screen size and determine layout mode

--- Gets the current screen width
-- @return number The current screen width
function Responsive:GetScreenWidth()
    return GetScreenWidth()
end

--- Gets the current screen height
-- @return number The current screen height
function Responsive:GetScreenHeight()
    return GetScreenHeight()
end

--- Updates the current screen dimensions
function Responsive:UpdateScreenDimensions()
    self.screenWidth = self:GetScreenWidth()
    self.screenHeight = self:GetScreenHeight()
end

--- Determines the current breakpoint based on screen width
-- @return string The current breakpoint (mobile, tablet, desktop, large)
function Responsive:GetCurrentBreakpoint()
    self:UpdateScreenDimensions()
    
    for breakpoint, width in pairs(self.breakpoints) do
        if self.screenWidth <= width then
            return breakpoint
        end
    end
    
    return self.breakpoints.large and "large" or "desktop"
end

--- Gets the appropriate layout mode for the current screen size
-- @param forceMode string Optional force mode override
-- @return string The layout mode (compact, standard, expanded)
function Responsive:GetLayoutMode(forceMode)
    if forceMode and self.layoutModes[forceMode:upper()] then
        return forceMode:upper()
    end
    
    if self.currentMode ~= self.layoutModes.AUTO then
        return self.currentMode
    end
    
    local breakpoint = self:GetCurrentBreakpoint()
    
    if breakpoint == "mobile" then
        return self.layoutModes.COMPACT
    elseif breakpoint == "tablet" then
        return self.layoutModes.STANDARD
    else
        return self.layoutModes.EXPANDED
    end
end

--- Sets the layout mode
-- @param mode string The layout mode to set
-- @return boolean True if mode was set successfully
function Responsive:SetLayoutMode(mode)
    if not mode or not self.layoutModes[mode:upper()] then
        Debug:Error("Responsive:SetLayoutMode - Invalid layout mode:", mode)
        return false
    end
    
    self.currentMode = mode:upper()
    self:NotifyLayoutChange()
    self:SaveLayoutMode()
    
    Debug:Dev("responsive", "Layout mode set to:", self.currentMode)
    return true
end

--- Gets the current layout mode
-- @return string The current layout mode
function Responsive:GetCurrentLayoutMode()
    return self.currentMode
end

-- MARK: Config Templates
-- Standardized configurations for different layout modes

Responsive.layouts = {
    [Responsive.layoutModes.COMPACT] = {
        name = "Compact",
        description = "Compact layout for small screens and limited space",
        
        -- Window configuration
        window = {
            width = 450,
            height = 500,
            minWidth = 400,
            minHeight = 450,
            maxWidth = 500,
            maxHeight = 600
        },
        
        -- Card configuration
        card = {
            height = 30,
            spacing = 0,
            padding = 2,
            iconSize = 24,
            iconWidth = 28,
            textWidth = 120,
            scoreWidth = 70,
            buttonWidth = 60
        },
        
        -- Button configuration
        button = {
            height = 22,
            padding = 4,
            fontSize = 10,
            showLabels = false,
            iconOnly = true
        },
        
        -- Text configuration
        text = {
            headerFontSize = 12,
            bodyFontSize = 10,
            labelFontSize = 9,
            scoreFontSize = 10
        },
        
        -- Layout configuration
        layout = {
            columns = 1,
            maxItems = 8,
            scrollThreshold = 6,
            compactMode = true
        }
    },
    
    [Responsive.layoutModes.STANDARD] = {
        name = "Standard",
        description = "Standard layout for medium screens and normal usage",
        
        window = {
            width = 570,
            height = 645,
            minWidth = 500,
            minHeight = 600,
            maxWidth = 650,
            maxHeight = 700
        },
        
        card = {
            height = 35,
            spacing = 0,
            padding = 4,
            iconSize = 32,
            iconWidth = 40,
            textWidth = 180,
            scoreWidth = 90,
            buttonWidth = 75
        },
        
        button = {
            height = 25,
            padding = 6,
            fontSize = 11,
            showLabels = true,
            iconOnly = false
        },
        
        text = {
            headerFontSize = 14,
            bodyFontSize = 12,
            labelFontSize = 11,
            scoreFontSize = 12
        },
        
        layout = {
            columns = 1,
            maxItems = 12,
            scrollThreshold = 8,
            compactMode = false
        }
    },
    
    [Responsive.layoutModes.EXPANDED] = {
        name = "Expanded",
        description = "Expanded layout for large screens with maximum information",
        
        window = {
            width = 700,
            height = 750,
            minWidth = 600,
            minHeight = 700,
            maxWidth = 800,
            maxHeight = 850
        },
        
        card = {
            height = 40,
            spacing = 2,
            padding = 6,
            iconSize = 36,
            iconWidth = 44,
            textWidth = 220,
            scoreWidth = 100,
            buttonWidth = 85
        },
        
        button = {
            height = 28,
            padding = 8,
            fontSize = 12,
            showLabels = true,
            iconOnly = false
        },
        
        text = {
            headerFontSize = 16,
            bodyFontSize = 13,
            labelFontSize = 12,
            scoreFontSize = 13
        },
        
        layout = {
            columns = 1,
            maxItems = 15,
            scrollThreshold = 10,
            compactMode = false
        }
    }
}

-- MARK: Config Resolution
-- Functions to resolve layout configuration based on current mode

--- Gets layout configuration for the current mode
-- @param elementType string The element type (window, card, button, text, layout)
-- @param forceMode string Optional force mode override
-- @return table The layout configuration for the element
function Responsive:GetLayoutConfig(elementType, forceMode)
    local mode = self:GetLayoutMode(forceMode)
    local layout = self.layouts[mode]
    
    if not layout then
        Debug:Error("Responsive:GetLayoutConfig - Layout not found for mode:", mode)
        return {}
    end
    
    local config = layout[elementType]
    if not config then
        Debug:Dev("responsive", "Layout element not found:", elementType, "in mode:", mode)
        return {}
    end
    
    return config
end

--- Gets a dimension value from the current layout
-- @param elementType string The element type
-- @param dimensionType string The dimension type (width, height, etc.)
-- @param defaultValue any Default value if not found
-- @return any The dimension value
function Responsive:GetDimension(elementType, dimensionType, defaultValue)
    local config = self:GetLayoutConfig(elementType)
    return config[dimensionType] or defaultValue
end

--- Applies responsive configuration to a frame
-- @param frame Frame The frame to configure
-- @param elementType string The element type
-- @param forceMode string Optional force mode override
function Responsive:ApplyLayout(frame, elementType, forceMode)
    if not frame then return end
    
    local config = self:GetLayoutConfig(elementType, forceMode)
    if not config then return end
    
    -- Apply dimensions
    if config.width and frame.SetWidth then
        frame:SetWidth(config.width)
    end
    
    if config.height and frame.SetHeight then
        frame:SetHeight(config.height)
    end
    
    if config.minWidth and frame.SetMinResize then
        frame:SetMinResize(config.minWidth, config.minHeight or config.minWidth)
    end
    
    if config.maxWidth and frame.SetMaxResize then
        frame:SetMaxResize(config.maxWidth, config.maxHeight or config.maxWidth)
    end
    
    -- Apply padding
    if config.padding and frame.SetPadding then
        frame:SetPadding(config.padding, config.padding, config.padding, config.padding)
    end
    
    Debug:Dev("responsive", "Applied layout for", elementType, "with config:", config)
end

--- Applies responsive configuration to a card
-- @param card Frame The card frame to configure
-- @param forceMode string Optional force mode override
function Responsive:ApplyCardLayout(card, forceMode)
    if not card then return end
    
    local config = self:GetLayoutConfig("card", forceMode)
    if not config then return end
    
    -- Apply card dimensions
    if card.SetHeight then
        card:SetHeight(config.height)
    end
    
    -- Apply icon sizing
    if card.icon and config.iconSize then
        card.icon:SetSize(config.iconSize, config.iconSize)
    end
    
    if card.iconFrame and config.iconWidth then
        card.iconFrame:SetWidth(config.iconWidth)
    end
    
    -- Apply text sizing
    if card.name and config.textWidth then
        card.name:SetWidth(config.textWidth)
    end
    
    if card.score and config.scoreWidth then
        card.score:SetWidth(config.scoreWidth)
    end
    
    -- Apply button sizing
    if card.buttons then
        for _, button in pairs(card.buttons) do
            if button.SetWidth then
                button:SetWidth(config.buttonWidth)
            end
            if button.SetHeight then
                button:SetHeight(config.buttonHeight or config.height - 10)
            end
        end
    end
    
    Debug:Dev("responsive", "Applied card layout with config:", config)
end

--- Applies responsive configuration to a button
-- @param button Frame The button frame to configure
-- @param forceMode string Optional force mode override
function Responsive:ApplyButtonLayout(button, forceMode)
    if not button then return end
    
    local config = self:GetLayoutConfig("button", forceMode)
    if not config then return end
    
    -- Apply button dimensions
    if button.SetHeight then
        button:SetHeight(config.height)
    end
    
    -- Apply font size
    if config.fontSize and button.SetNormalFontObject then
        local fontObject = GameFontNormalSmall
        if config.fontSize >= 12 then
            fontObject = GameFontNormal
        elseif config.fontSize <= 10 then
            fontObject = GameFontNormalSmall
        end
        button:SetNormalFontObject(fontObject)
    end
    
    -- Apply label visibility
    if button.SetText and config.showLabels == false then
        -- Hide text, show only icon
        button:SetText("")
    end
    
    Debug:Dev("responsive", "Applied button layout with config:", config)
end

-- MARK: Layout Adaptation
-- Functions to adapt UI elements based on layout changes

--- Adapts the main UI window to the current layout
function Responsive:AdaptMainWindow()
    if not NextKey222.UI or not NextKey222.UI.mainFrame then return end
    
    local windowConfig = self:GetLayoutConfig("window")
    if not windowConfig then return end
    
    local mainFrame = NextKey222.UI.mainFrame
    
    -- Apply window dimensions
    mainFrame:SetWidth(windowConfig.width)
    mainFrame:SetHeight(windowConfig.height)
    
    -- Apply resize limits
    mainFrame:SetMinResize(windowConfig.minWidth, windowConfig.minHeight)
    mainFrame:SetMaxResize(windowConfig.maxWidth, windowConfig.maxHeight)
    
    -- Apply UI scale if available
    if NextKey222.UIScale then
        local scale = NextKey222.UIScale:GetCurrentScale()
        mainFrame:SetScale(scale)
    end
    
    Debug:Dev("responsive", "Adapted main window to layout:", self:GetLayoutMode())
end

--- Adapts card layouts to the current layout
function Responsive:AdaptCardLayouts()
    if not NextKey222.UI or not NextKey222.UI.resultsFrame then return end
    
    local cardConfig = self:GetLayoutConfig("card")
    if not cardConfig then return end
    
    -- Re-render results with new layout
    if NextKey222.UI.RefreshResults then
        NextKey222.UI:RefreshResults()
    end
    
    Debug:Dev("responsive", "Adapted card layouts to:", self:GetLayoutMode())
end

--- Adapts button layouts to the current layout
function Responsive:AdaptButtonLayouts()
    if not NextKey222.UI or not NextKey222.UI.controlsContainer then return end
    
    local buttonConfig = self:GetLayoutConfig("button")
    if not buttonConfig then return end
    
    -- Update control buttons
    local buttons = {
        NextKey222.UI.viewToggleBtn,
        NextKey222.UI.guildToggleBtn
    }
    
    for _, button in pairs(buttons) do
        if button and button.frame then
            self:ApplyButtonLayout(button.frame)
        end
    end
    
    Debug:Dev("responsive", "Adapted button layouts to:", self:GetLayoutMode())
end

-- MARK: Change Notify
-- Functions to notify systems of layout changes

--- Notifies all systems of layout changes
function Responsive:NotifyLayoutChange()
    local mode = self:GetLayoutMode()
    
    -- Adapt UI elements
    self:AdaptMainWindow()
    self:AdaptCardLayouts()
    self:AdaptButtonLayouts()
    
    -- Notify other systems
    if NextKey222.UI and NextKey222.UI.OnLayoutChanged then
        NextKey222.UI:OnLayoutChanged(mode)
    end
    
    if NextKey222.Tooltip and NextKey222.Tooltip.OnLayoutChanged then
        NextKey222.Tooltip:OnLayoutChanged(mode)
    end
    
    if NextKey222.Theme and NextKey222.Theme.OnLayoutChanged then
        NextKey222.Theme:OnLayoutChanged(mode)
    end
    
    Debug:Dev("responsive", "Layout change notification sent for mode:", mode)
end

-- MARK: Persistence
-- Functions to save and load layout preferences

--- Saves the current layout mode to saved variables
function Responsive:SaveLayoutMode()
    if NextKey and NextKey.db and NextKey.db.char then
        NextKey.db.char.layoutMode = self.currentMode
        Debug:Dev("responsive", "Layout mode saved:", self.currentMode)
    end
end

--- Loads the layout mode from saved variables
function Responsive:LoadLayoutMode()
    if NextKey and NextKey.db and NextKey.db.char and NextKey.db.char.layoutMode then
        self:SetLayoutMode(NextKey.db.char.layoutMode)
        Debug:Dev("responsive", "Layout mode loaded:", NextKey.db.char.layoutMode)
    else
        Debug:Dev("responsive", "No saved layout mode found, using auto")
    end
end

-- MARK: Event Handling
-- Functions to handle layout-related events

--- Called when screen resolution changes
function Responsive:OnScreenResolutionChanged()
    local oldBreakpoint = self.currentBreakpoint
    self.currentBreakpoint = self:GetCurrentBreakpoint()
    
    if oldBreakpoint ~= self.currentBreakpoint then
        Debug:Dev("responsive", "Screen resolution changed, new breakpoint:", self.currentBreakpoint)
        
        if self.currentMode == self.layoutModes.AUTO then
            self:NotifyLayoutChange()
        end
    end
end

--- Called when UI scale changes
function Responsive:OnUIScaleChanged()
    self:NotifyLayoutChange()
    Debug:Dev("responsive", "UI scale changed, layout adapted")
end

-- MARK: Utilities
-- Utility functions for layout calculations

--- Calculates optimal window position for current layout
-- @param windowWidth number Window width
-- @param windowHeight number Window height
-- @return number, number X and Y coordinates
function Responsive:CalculateOptimalPosition(windowWidth, windowHeight)
    local screenWidth = self:GetScreenWidth()
    local screenHeight = self:GetScreenHeight()
    
    -- Center the window
    local x = (screenWidth - windowWidth) / 2
    local y = (screenHeight - windowHeight) / 2
    
    -- Ensure window stays within screen bounds
    x = math.max(0, math.min(x, screenWidth - windowWidth))
    y = math.max(0, math.min(y, screenHeight - windowHeight))
    
    return x, y
end

--- Checks if compact mode should be used based on content count
-- @param itemCount number Number of items to display
-- @return boolean True if compact mode should be used
function Responsive:ShouldUseCompactMode(itemCount)
    local layoutConfig = self:GetLayoutConfig("layout")
    return layoutConfig.compactMode or (itemCount > (layoutConfig.scrollThreshold or 8))
end

--- Gets the maximum number of items that can be displayed without scrolling
-- @return number Maximum number of items
function Responsive:GetMaxItemsWithoutScroll()
    local layoutConfig = self:GetLayoutConfig("layout")
    return layoutConfig.maxItems or 12
end

-- MARK: Initialization
function Responsive:Initialize()
    Debug:Dev("responsive", "Responsive Layout module initialized")
    
    -- Load saved layout mode
    self:LoadLayoutMode()
    
    -- Register for resolution change events
    local resolutionFrame = CreateFrame("Frame")
    resolutionFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    resolutionFrame:SetScript("OnEvent", function()
        if event == "DISPLAY_SIZE_CHANGED" then
            self:OnScreenResolutionChanged()
        end
    end)
    
    -- Apply initial layout
    self:NotifyLayoutChange()
    
    return true
end

return Responsive