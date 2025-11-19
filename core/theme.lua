-- MARK: Theme Config
-- Centralized theme management with consistent styling and color schemes
-- Phase 7: Basic theme configuration system

local _, NextKey222 = ...

local Theme = {}
NextKey222.Theme = Theme

-- Register with module system
NextKey222.RegisterModule("Theme", Theme)

-- MARK: Theme Types
-- Standardized theme types for consistent configuration

Theme.TYPE_DEFAULT = "default"
Theme.TYPE_DARK = "dark"
Theme.TYPE_LIGHT = "light"
Theme.TYPE_COLORBLIND = "colorblind"
Theme.TYPE_HIGH_CONTRAST = "high_contrast"

-- MARK: Theme Templates
-- Standardized configurations for different theme types

Theme.themes = {
    [Theme.TYPE_DEFAULT] = {
        name = "Default",
        description = "Standard NextKey theme with balanced colors",
        
        -- Window styling
        window = {
            backgroundColor = {0, 0, 0, 0.9},
            borderColor = {0.5, 0.5, 0.5, 1},
            titleColor = {1, 1, 1},
            titleFont = GameFontNormalLarge
        },
        
        -- Card styling
        card = {
            backgroundColor = {0, 0, 0, 0.8},
            borderColor = {0.5, 0.5, 0.5, 1},
            selectedBackgroundColor = {0.1, 0.2, 0.3, 0.9},
            selectedBorderColor = {0.2, 0.4, 0.8, 1},
            hoverBackgroundColor = {0.05, 0.1, 0.15, 0.9},
            hoverBorderColor = {0.3, 0.3, 0.3, 1}
        },
        
        -- Button styling
        button = {
            normal = {
                backgroundColor = {0.2, 0.2, 0.2, 0.8},
                borderColor = {0.5, 0.5, 0.5, 1},
                textColor = {1, 1, 1},
                textFont = GameFontNormal
            },
            hover = {
                backgroundColor = {0.3, 0.3, 0.3, 0.9},
                borderColor = {0.7, 0.7, 0.7, 1},
                textColor = {1, 1, 1},
                textFont = GameFontNormal
            },
            pressed = {
                backgroundColor = {0.1, 0.1, 0.1, 0.9},
                borderColor = {0.4, 0.4, 0.4, 1},
                textColor = {0.9, 0.9, 0.9},
                textFont = GameFontNormal
            },
            disabled = {
                backgroundColor = {0.1, 0.1, 0.1, 0.5},
                borderColor = {0.3, 0.3, 0.3, 0.5},
                textColor = {0.5, 0.5, 0.5},
                textFont = GameFontNormal
            }
        },
        
        -- Text styling
        text = {
            header = {
                color = {1, 1, 1},
                font = GameFontNormalLarge
            },
            body = {
                color = {1, 1, 1},
                font = GameFontNormal
            },
            label = {
                color = {0.8, 0.8, 0.8},
                font = GameFontNormalSmall
            },
            score = {
                color = {0, 1, 0},
                font = GameFontNormal
            },
            highlight = {
                color = {1, 0.82, 0},
                font = GameFontNormal
            }
        },
        
        -- Role colors
        roles = {
            TANK = {0.2, 0.6, 1},
            HEALER = {0.2, 1, 0.2},
            DAMAGER = {1, 0.2, 0.2}
        },
        
        -- Class colors (uses RAID_CLASS_COLORS as fallback)
        classes = nil, -- Will use RAID_CLASS_COLORS
        
        -- Quality colors (uses ITEM_QUALITY_COLORS as fallback)
        qualities = nil -- Will use ITEM_QUALITY_COLORS
    },
    
    [Theme.TYPE_DARK] = {
        name = "Dark",
        description = "Enhanced dark theme with deeper blacks and higher contrast",
        
        window = {
            backgroundColor = {0, 0, 0, 0.95},
            borderColor = {0.3, 0.3, 0.3, 1},
            titleColor = {1, 1, 1},
            titleFont = GameFontNormalLarge
        },
        
        card = {
            backgroundColor = {0, 0, 0, 0.9},
            borderColor = {0.3, 0.3, 0.3, 1},
            selectedBackgroundColor = {0.05, 0.1, 0.2, 0.95},
            selectedBorderColor = {0.1, 0.2, 0.6, 1},
            hoverBackgroundColor = {0.02, 0.05, 0.1, 0.95},
            hoverBorderColor = {0.2, 0.2, 0.2, 1}
        },
        
        button = {
            normal = {
                backgroundColor = {0.15, 0.15, 0.15, 0.9},
                borderColor = {0.3, 0.3, 0.3, 1},
                textColor = {1, 1, 1},
                textFont = GameFontNormal
            },
            hover = {
                backgroundColor = {0.25, 0.25, 0.25, 0.95},
                borderColor = {0.5, 0.5, 0.5, 1},
                textColor = {1, 1, 1},
                textFont = GameFontNormal
            },
            pressed = {
                backgroundColor = {0.05, 0.05, 0.05, 0.95},
                borderColor = {0.2, 0.2, 0.2, 1},
                textColor = {0.9, 0.9, 0.9},
                textFont = GameFontNormal
            },
            disabled = {
                backgroundColor = {0.05, 0.05, 0.05, 0.5},
                borderColor = {0.15, 0.15, 0.15, 0.5},
                textColor = {0.4, 0.4, 0.4},
                textFont = GameFontNormal
            }
        },
        
        text = {
            header = {
                color = {1, 1, 1},
                font = GameFontNormalLarge
            },
            body = {
                color = {0.95, 0.95, 0.95},
                font = GameFontNormal
            },
            label = {
                color = {0.7, 0.7, 0.7},
                font = GameFontNormalSmall
            },
            score = {
                color = {0.2, 1, 0.2},
                font = GameFontNormal
            },
            highlight = {
                color = {1, 0.9, 0.3},
                font = GameFontNormal
            }
        },
        
        roles = {
            TANK = {0.1, 0.5, 0.9},
            HEALER = {0.1, 0.9, 0.1},
            DAMAGER = {0.9, 0.1, 0.1}
        }
    },
    
    [Theme.TYPE_LIGHT] = {
        name = "Light",
        description = "Light theme with bright backgrounds and dark text",
        
        window = {
            backgroundColor = {0.95, 0.95, 0.95, 0.95},
            borderColor = {0.3, 0.3, 0.3, 1},
            titleColor = {0.1, 0.1, 0.1},
            titleFont = GameFontNormalLarge
        },
        
        card = {
            backgroundColor = {0.9, 0.9, 0.9, 0.9},
            borderColor = {0.4, 0.4, 0.4, 1},
            selectedBackgroundColor = {0.8, 0.85, 0.9, 0.95},
            selectedBorderColor = {0.3, 0.4, 0.7, 1},
            hoverBackgroundColor = {0.85, 0.85, 0.85, 0.95},
            hoverBorderColor = {0.5, 0.5, 0.5, 1}
        },
        
        button = {
            normal = {
                backgroundColor = {0.8, 0.8, 0.8, 0.9},
                borderColor = {0.4, 0.4, 0.4, 1},
                textColor = {0.1, 0.1, 0.1},
                textFont = GameFontNormal
            },
            hover = {
                backgroundColor = {0.7, 0.7, 0.7, 0.95},
                borderColor = {0.3, 0.3, 0.3, 1},
                textColor = {0.1, 0.1, 0.1},
                textFont = GameFontNormal
            },
            pressed = {
                backgroundColor = {0.6, 0.6, 0.6, 0.95},
                borderColor = {0.2, 0.2, 0.2, 1},
                textColor = {0.2, 0.2, 0.2},
                textFont = GameFontNormal
            },
            disabled = {
                backgroundColor = {0.85, 0.85, 0.85, 0.5},
                borderColor = {0.6, 0.6, 0.6, 0.5},
                textColor = {0.5, 0.5, 0.5},
                textFont = GameFontNormal
            }
        },
        
        text = {
            header = {
                color = {0.1, 0.1, 0.1},
                font = GameFontNormalLarge
            },
            body = {
                color = {0.2, 0.2, 0.2},
                font = GameFontNormal
            },
            label = {
                color = {0.4, 0.4, 0.4},
                font = GameFontNormalSmall
            },
            score = {
                color = {0, 0.6, 0},
                font = GameFontNormal
            },
            highlight = {
                color = {0.8, 0.6, 0},
                font = GameFontNormal
            }
        },
        
        roles = {
            TANK = {0.1, 0.4, 0.8},
            HEALER = {0, 0.7, 0},
            DAMAGER = {0.8, 0.1, 0.1}
        }
    },
    
    [Theme.TYPE_COLORBLIND] = {
        name = "Colorblind",
        description = "Colorblind-friendly theme with enhanced contrast and distinct colors",
        
        window = {
            backgroundColor = {0, 0, 0, 0.9},
            borderColor = {0.6, 0.6, 0.6, 1},
            titleColor = {1, 1, 1},
            titleFont = GameFontNormalLarge
        },
        
        card = {
            backgroundColor = {0, 0, 0, 0.8},
            borderColor = {0.6, 0.6, 0.6, 1},
            selectedBackgroundColor = {0.2, 0.1, 0.1, 0.9},
            selectedBorderColor = {0.8, 0.4, 0.4, 1},
            hoverBackgroundColor = {0.1, 0.05, 0.05, 0.9},
            hoverBorderColor = {0.4, 0.4, 0.4, 1}
        },
        
        button = {
            normal = {
                backgroundColor = {0.2, 0.2, 0.2, 0.8},
                borderColor = {0.6, 0.6, 0.6, 1},
                textColor = {1, 1, 1},
                textFont = GameFontNormal
            },
            hover = {
                backgroundColor = {0.3, 0.3, 0.3, 0.9},
                borderColor = {0.8, 0.8, 0.8, 1},
                textColor = {1, 1, 1},
                textFont = GameFontNormal
            },
            pressed = {
                backgroundColor = {0.1, 0.1, 0.1, 0.9},
                borderColor = {0.5, 0.5, 0.5, 1},
                textColor = {0.9, 0.9, 0.9},
                textFont = GameFontNormal
            },
            disabled = {
                backgroundColor = {0.1, 0.1, 0.1, 0.5},
                borderColor = {0.3, 0.3, 0.3, 0.5},
                textColor = {0.5, 0.5, 0.5},
                textFont = GameFontNormal
            }
        },
        
        text = {
            header = {
                color = {1, 1, 1},
                font = GameFontNormalLarge
            },
            body = {
                color = {1, 1, 1},
                font = GameFontNormal
            },
            label = {
                color = {0.9, 0.9, 0.9},
                font = GameFontNormalSmall
            },
            score = {
                color = {0.8, 0.8, 0.2},
                font = GameFontNormal
            },
            highlight = {
                color = {0.8, 0.6, 0.2},
                font = GameFontNormal
            }
        },
        
        roles = {
            TANK = {0.6, 0.4, 0.8},    -- Purple instead of blue
            HEALER = {0.8, 0.8, 0.2},  -- Yellow instead of green
            DAMAGER = {0.8, 0.2, 0.2}   -- Red (kept as it's distinct)
        }
    },
    
    [Theme.TYPE_HIGH_CONTRAST] = {
        name = "High Contrast",
        description = "High contrast theme for maximum visibility",
        
        window = {
            backgroundColor = {0, 0, 0, 1},
            borderColor = {1, 1, 1, 1},
            titleColor = {1, 1, 1},
            titleFont = GameFontNormalLarge
        },
        
        card = {
            backgroundColor = {0, 0, 0, 0.95},
            borderColor = {1, 1, 1, 1},
            selectedBackgroundColor = {0.2, 0.2, 0.2, 1},
            selectedBorderColor = {1, 1, 0, 1},
            hoverBackgroundColor = {0.1, 0.1, 0.1, 1},
            hoverBorderColor = {0.8, 0.8, 0.8, 1}
        },
        
        button = {
            normal = {
                backgroundColor = {0.2, 0.2, 0.2, 1},
                borderColor = {1, 1, 1, 1},
                textColor = {1, 1, 1},
                textFont = GameFontNormal
            },
            hover = {
                backgroundColor = {0.4, 0.4, 0.4, 1},
                borderColor = {1, 1, 1, 1},
                textColor = {1, 1, 1},
                textFont = GameFontNormal
            },
            pressed = {
                backgroundColor = {0.1, 0.1, 0.1, 1},
                borderColor = {0.8, 0.8, 0.8, 1},
                textColor = {0.9, 0.9, 0.9},
                textFont = GameFontNormal
            },
            disabled = {
                backgroundColor = {0.1, 0.1, 0.1, 0.5},
                borderColor = {0.5, 0.5, 0.5, 0.5},
                textColor = {0.5, 0.5, 0.5},
                textFont = GameFontNormal
            }
        },
        
        text = {
            header = {
                color = {1, 1, 1},
                font = GameFontNormalLarge
            },
            body = {
                color = {1, 1, 1},
                font = GameFontNormal
            },
            label = {
                color = {0.9, 0.9, 0.9},
                font = GameFontNormalSmall
            },
            score = {
                color = {1, 1, 0},
                font = GameFontNormal
            },
            highlight = {
                color = {1, 0.8, 0},
                font = GameFontNormal
            }
        },
        
        roles = {
            TANK = {0, 0.8, 1},
            HEALER = {0, 1, 0},
            DAMAGER = {1, 0, 0}
        }
    }
}

-- MARK: State Management
-- Current theme and caching system

Theme.currentTheme = Theme.TYPE_DEFAULT
Theme.cache = {}

-- MARK: Resolution Functions
-- Functions to resolve theme colors and styling

--- Gets the current theme
-- @return string The current theme type
function Theme:GetCurrentTheme()
    return self.currentTheme
end

--- Sets the current theme
-- @param themeType string The theme type to set
-- @return boolean True if theme was set successfully
function Theme:SetCurrentTheme(themeType)
    if not themeType or not self.themes[themeType] then
        Debug:Error("Theme:SetCurrentTheme - Unknown theme type:", themeType)
        return false
    end
    
    self.currentTheme = themeType
    self:InvalidateCache()
    Debug:Dev("theme", "Theme changed to:", themeType)
    return true
end

--- Gets theme configuration for a specific element
-- @param elementType string The element type (window, card, button, text, roles)
-- @param elementSubType string The element subtype (normal, hover, pressed, etc.)
-- @return table The theme configuration for the element
function Theme:GetThemeConfig(elementType, elementSubType)
    -- Check cache first
    local cacheKey = elementType .. "." .. (elementSubType or "")
    if self.cache[cacheKey] then
        return self.cache[cacheKey]
    end
    
    -- Get current theme
    local theme = self.themes[self.currentTheme]
    if not theme then
        Debug:Error("Theme:GetThemeConfig - Current theme not found:", self.currentTheme)
        return {}
    end
    
    -- Get element configuration
    local config = theme[elementType]
    if not config then
        Debug:Dev("theme", "Theme element not found:", elementType)
        return {}
    end
    
    -- Get subtype configuration if specified
    if elementSubType and type(config) == "table" then
        config = config[elementSubType] or config
    end
    
    -- Cache the result
    self.cache[cacheKey] = config
    return config
end

--- Gets a color from the current theme
-- @param elementType string The element type
-- @param elementSubType string The element subtype
-- @param fallbackColor table Fallback color if not found in theme
-- @return table The color as {r, g, b, a}
function Theme:GetColor(elementType, elementSubType, fallbackColor)
    local config = self:GetThemeConfig(elementType, elementSubType)
    
    if config and config.color then
        return config.color
    elseif config and type(config) == "table" and config[1] then
        -- Handle direct color tables
        return {config[1], config[2], config[3], config[4] or 1}
    end
    
    return fallbackColor or {1, 1, 1, 1}
end

--- Gets a font from the current theme
-- @param elementType string The element type
-- @param elementSubType string The element subtype
-- @param fallbackFont table Fallback font if not found in theme
-- @return table The font object
function Theme:GetFont(elementType, elementSubType, fallbackFont)
    local config = self:GetThemeConfig(elementType, elementSubType)
    
    if config and config.font then
        return config.font
    end
    
    return fallbackFont or GameFontNormal
end

--- Gets role color from the current theme
-- @param role string The role (TANK, HEALER, DAMAGER)
-- @param fallbackColor table Fallback color if not found in theme
-- @return table The color as {r, g, b}
function Theme:GetRoleColor(role, fallbackColor)
    return self:GetColor("roles", role, fallbackColor or {1, 1, 1})
end

--- Gets class color from the current theme or RAID_CLASS_COLORS
-- @param classToken string The class token (WARRIOR, PALADIN, etc.)
-- @param fallbackColor table Fallback color if not found
-- @return table The color as {r, g, b}
function Theme:GetClassColor(classToken, fallbackColor)
    -- Try theme first
    local theme = self.themes[self.currentTheme]
    if theme and theme.classes and theme.classes[classToken] then
        return theme.classes[classToken]
    end
    
    -- Fallback to RAID_CLASS_COLORS
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
        local color = RAID_CLASS_COLORS[classToken]
        return {color.r, color.g, color.b}
    end
    
    return fallbackColor or {1, 1, 1}
end

--- Gets quality color from the current theme or ITEM_QUALITY_COLORS
-- @param quality number The item quality
-- @param fallbackColor table Fallback color if not found
-- @return table The color as {r, g, b}
function Theme:GetQualityColor(quality, fallbackColor)
    -- Try theme first
    local theme = self.themes[self.currentTheme]
    if theme and theme.qualities and theme.qualities[quality] then
        return theme.qualities[quality]
    end
    
    -- Fallback to ITEM_QUALITY_COLORS
    if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local color = ITEM_QUALITY_COLORS[quality]
        return {color.r, color.g, color.b}
    end
    
    return fallbackColor or {1, 1, 1}
end

-- MARK: Apply Functions
-- Functions to apply theme styling to UI elements

--- Applies theme styling to a frame
-- @param frame Frame The frame to style
-- @param elementType string The element type
-- @param elementSubType string The element subtype
function Theme:ApplyFrameStyle(frame, elementType, elementSubType)
    if not frame then return end
    
    local config = self:GetThemeConfig(elementType, elementSubType)
    if not config then return end
    
    -- Apply backdrop styling
    if frame.SetBackdrop then
        local backdropConfig = {}
        
        if config.backgroundColor then
            backdropConfig.bgFile = "Interface/Tooltips/UI-Tooltip-Background"
            backdropConfig.tile = true
            backdropConfig.tileSize = 16
        end
        
        if config.borderColor then
            backdropConfig.edgeFile = "Interface/Tooltips/UI-Tooltip-Border"
            backdropConfig.edgeSize = 16
            backdropConfig.insets = { left = 4, right = 4, top = 4, bottom = 4 }
        end
        
        if backdropConfig.bgFile or backdropConfig.edgeFile then
            frame:SetBackdrop(backdropConfig)
            
            if config.backgroundColor then
                frame:SetBackdropColor(unpack(config.backgroundColor))
            end
            
            if config.borderColor then
                frame:SetBackdropBorderColor(unpack(config.borderColor))
            end
        end
    end
    
    -- Apply text styling if applicable
    if config.textColor and frame.SetTextColor then
        frame:SetTextColor(unpack(config.textColor))
    end
    
    -- Apply font if applicable
    if config.font and frame.SetFont then
        frame:SetFont(config.font:GetFont())
    end
end

--- Applies theme styling to a button
-- @param button Frame The button to style
-- @param state string The button state (normal, hover, pressed, disabled)
function Theme:ApplyButtonStyle(button, state)
    state = state or "normal"
    self:ApplyFrameStyle(button, "button", state)
end

--- Applies theme styling to text
-- @param textElement Frame The text element to style
-- @param textType string The text type (header, body, label, etc.)
function Theme:ApplyTextStyle(textElement, textType)
    if not textElement then return end
    
    local config = self:GetThemeConfig("text", textType)
    if not config then return end
    
    -- Apply color
    if config.color and textElement.SetTextColor then
        textElement:SetTextColor(unpack(config.color))
    end
    
    -- Apply font
    if config.font and textElement.SetFont then
        textElement:SetFont(config.font:GetFont())
    end
end

-- MARK: Cache Management

--- Invalidates the theme cache
function Theme:InvalidateCache()
    self.cache = {}
    Debug:Dev("theme", "Theme cache invalidated")
end

--- Clears the theme cache and resets theme
function Theme:ClearCache()
    self.cache = {}
    self.currentTheme = self.TYPE_DEFAULT
    Debug:Dev("theme", "Theme cache cleared and reset to default")
end

-- MARK: Persistence
-- Functions to save and load theme preferences

--- Saves the current theme to saved variables
function Theme:SaveTheme()
    if NextKey and NextKey.db and NextKey.db.char then
        NextKey.db.char.currentTheme = self.currentTheme
        Debug:Dev("theme", "Theme saved:", self.currentTheme)
    end
end

--- Loads the theme from saved variables
function Theme:LoadTheme()
    if NextKey and NextKey.db and NextKey.db.char and NextKey.db.char.currentTheme then
        self:SetCurrentTheme(NextKey.db.char.currentTheme)
        Debug:Dev("theme", "Theme loaded:", NextKey.db.char.currentTheme)
    else
        Debug:Dev("theme", "No saved theme found, using default")
    end
end

-- MARK: Initialization
function Theme:Initialize()
    Debug:Dev("theme", "Theme module initialized")
    
    -- Load saved theme
    self:LoadTheme()
    
    return true
end

return Theme