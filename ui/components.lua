-- UI Components - Shared rendering components for NextKey
-- Provides reusable card, button, and backdrop factory functions
-- Following Ace3 best practices and DRY principles
-- Enhanced with dynamic configuration support (Phase 7)

local _, NextKey222 = ...
local AceGUI = LibStub("AceGUI-3.0")

local Components = {}
NextKey222.UIComponents = Components

-- Register with module system
NextKey222.RegisterModule("UIComponents", Components)

-- MARK: Dynamic Configuration Integration
-- Integration with ConfigurationContext for context-aware component creation

--- Gets the current configuration context
-- @return table The configuration context or nil if not available
function Components:GetConfigurationContext()
    return NextKey222.ConfigurationContext
end

--- Synchronizes configuration context before component creation
-- @param contextType string The type of context to synchronize (optional)
function Components:SynchronizeContext(contextType)
    local configContext = self:GetConfigurationContext()
    if configContext and NextKey222.UI then
        configContext:SynchronizeWithUI(NextKey222.UI)
    end
end

--- Applies dynamic configuration to a component
-- @param widget table The AceGUI widget to configure
-- @param componentType string The type of component
-- @param baseConfig table The base configuration for the component
-- @param dynamicConfig table Optional dynamic configuration overrides
-- @return table The final merged configuration
function Components:ApplyDynamicConfiguration(widget, componentType, baseConfig, dynamicConfig)
    -- Synchronize context first
    self:SynchronizeContext()
    
    -- Get configuration context
    local configContext = self:GetConfigurationContext()
    if not configContext then
        -- Fallback to base configuration if context not available
        return baseConfig
    end
    
    -- Start with base configuration
    local finalConfig = {}
    for k, v in pairs(baseConfig or {}) do
        finalConfig[k] = v
    end
    
    -- Apply dynamic configuration based on context
    if dynamicConfig then
        for k, v in pairs(dynamicConfig) do
            finalConfig[k] = v
        end
    end
    
    -- Apply context-specific overrides
    local contextConfig = configContext:GetResolvedConfig(componentType)
    if contextConfig then
        for k, v in pairs(contextConfig) do
            finalConfig[k] = v
        end
    end
    
    return finalConfig
end

-- MARK: Spec to Role Mapping
-- Definitive mapping of all specialization IDs to their roles
-- This is more reliable than WoW API calls and ensures correct role display
local SPEC_TO_ROLE = {
    -- Death Knight
    [250] = "TANK",     -- Blood
    [251] = "DAMAGER",  -- Frost
    [252] = "DAMAGER",  -- Unholy
    
    -- Demon Hunter
    [577] = "DAMAGER",  -- Havoc
    [581] = "TANK",     -- Vengeance
    
    -- Druid
    [102] = "DAMAGER",  -- Balance
    [103] = "DAMAGER",  -- Feral
    [104] = "TANK",     -- Guardian
    [105] = "HEALER",   -- Restoration
    
    -- Evoker
    [1467] = "DAMAGER", -- Devastation
    [1468] = "HEALER",  -- Preservation
    [1473] = "DAMAGER", -- Augmentation
    
    -- Hunter
    [253] = "DAMAGER",  -- Beast Mastery
    [254] = "DAMAGER",  -- Marksmanship
    [255] = "DAMAGER",  -- Survival
    
    -- Mage
    [62] = "DAMAGER",   -- Arcane
    [63] = "DAMAGER",   -- Fire
    [64] = "DAMAGER",   -- Frost
    
    -- Monk
    [268] = "TANK",     -- Brewmaster
    [270] = "HEALER",   -- Mistweaver
    [269] = "DAMAGER",  -- Windwalker
    
    -- Paladin
    [65] = "HEALER",    -- Holy
    [66] = "TANK",      -- Protection
    [70] = "DAMAGER",   -- Retribution
    
    -- Priest
    [256] = "HEALER",   -- Discipline
    [257] = "HEALER",   -- Holy
    [258] = "DAMAGER",  -- Shadow
    
    -- Rogue
    [259] = "DAMAGER",  -- Assassination
    [260] = "DAMAGER",  -- Outlaw
    [261] = "DAMAGER",  -- Subtlety
    
    -- Shaman
    [262] = "DAMAGER",  -- Elemental
    [263] = "DAMAGER",  -- Enhancement
    [264] = "HEALER",   -- Restoration
    
    -- Warlock
    [265] = "DAMAGER",  -- Affliction
    [266] = "DAMAGER",  -- Demonology
    [267] = "DAMAGER",  -- Destruction
    
    -- Warrior
    [71] = "DAMAGER",   -- Arms
    [72] = "DAMAGER",   -- Fury
    [73] = "TANK",      -- Protection
}

-- MARK: Backdrop Type Constants
-- Public access to backdrop type constants for external use
Components.BACKDROP_TOOLTIP = "tooltip"
Components.BACKDROP_DIALOG = "dialog"
Components.BACKDROP_DARK_DIALOG = "dark_dialog"
Components.BACKDROP_COMPACT = "compact"

-- MARK: Role Detection Helper
-- Shared function for reliable role detection from specID

--- Gets the role for a given specID using the definitive mapping table
-- @param specID number The specialization ID
-- @param fallbackRole string Optional fallback role if specID not found (default: "DAMAGER")
-- @return string The role: "TANK", "HEALER", or "DAMAGER"
function Components:GetRoleFromSpecID(specID, fallbackRole)
    if specID and SPEC_TO_ROLE[specID] then
        return SPEC_TO_ROLE[specID]
    end
    return fallbackRole or "DAMAGER"
end

-- MARK: Backdrop Configuration
-- Standardized backdrop configurations for different AceGUI widgets

local BACKDROP_COLORS = {
    dark = { bg = {0, 0, 0, 0.9}, border = {0.35, 0.35, 0.35, 1} },
    standard = { bg = {0, 0, 0, 0.8}, border = {0.5, 0.5, 0.5, 1} },
    light = { bg = {0, 0, 0, 0.55}, border = {0.6, 0.6, 0.6, 1} },
    transparent = { bg = {0, 0, 0, 0.45}, border = {0.35, 0.35, 0.35, 1} }
}

local BACKDROP_CONFIGS = {
    [Components.BACKDROP_TOOLTIP] = {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    },
    [Components.BACKDROP_DIALOG] = {
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    },
    [Components.BACKDROP_DARK_DIALOG] = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    },
    [Components.BACKDROP_COMPACT] = {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    }
}

-- Legacy mappings for backward compatibility
BACKDROP_CONFIGS.keystone = BACKDROP_CONFIGS[Components.BACKDROP_TOOLTIP]
BACKDROP_CONFIGS.keystone_compact = BACKDROP_CONFIGS[Components.BACKDROP_COMPACT]
BACKDROP_CONFIGS.dungeon = BACKDROP_CONFIGS[Components.BACKDROP_DARK_DIALOG]

--- Configures a backdrop for an existing frame (Phase 7: Enhanced with theme support)
-- @param widget Frame The frame to apply the backdrop to (e.g., widget.frame)
-- @param backdropType string The backdrop type: "tooltip", "dialog", "dark_dialog", "compact"
-- @param config table Optional configuration overrides (colorScheme, customBgColor, customBorderColor)
function Components:ConfigureBackdrop(widget, backdropType, config)
    config = config or {}
    local frame = widget.frame or widget
    if not frame or not frame.SetBackdrop then return end

    local backdropConfig = BACKDROP_CONFIGS[backdropType]
    if not backdropConfig then
        NextKey222.Debug:Dev("components", "Unknown backdrop type:", backdropType)
        backdropConfig = BACKDROP_CONFIGS[Components.BACKDROP_TOOLTIP]
    end

    frame:SetBackdrop(backdropConfig)
    
    -- Phase 7: Apply theme colors if available
    if NextKey222.Theme then
        local themeConfig = NextKey222.Theme:GetThemeConfig("card")
        if themeConfig then
            if themeConfig.backgroundColor then
                frame:SetBackdropColor(unpack(themeConfig.backgroundColor))
            end
            if themeConfig.borderColor then
                frame:SetBackdropBorderColor(unpack(themeConfig.borderColor))
            end
        end
    else
        -- Fallback to original color scheme system
        local colorScheme = config.colorScheme or "standard"
        local colors = config.customBgColor and config.customBorderColor and nil or BACKDROP_COLORS[colorScheme]
        
        if colors then
            frame:SetBackdropColor(unpack(colors.bg))
            frame:SetBackdropBorderColor(unpack(colors.border))
        elseif config.customBgColor and config.customBorderColor then
            frame:SetBackdropColor(unpack(config.customBgColor))
            frame:SetBackdropBorderColor(unpack(config.customBorderColor))
        else
            -- Fallback to standard colors
            frame:SetBackdropColor(unpack(BACKDROP_COLORS.standard.bg))
            frame:SetBackdropBorderColor(unpack(BACKDROP_COLORS.standard.border))
        end
    end
end

-- MARK: Score Retrieval System

--- Gets player's total IO score from multiple sources
-- @param playerInfo table Player info containing ownerName, rating, rioScore, etc.
-- @return number The player's IO score (0 if not found)
function Components:GetPlayerScore(playerInfo)
    if not playerInfo then return 0 end
    
    local score = 0
    
    -- Try multiple score sources (LibOpenRaid uses 'rating' field)
    score = playerInfo.rating or playerInfo.rioScore or playerInfo.io or playerInfo.score or 0
    
    -- For the actual player, try getting current live score
    local ownerName = playerInfo.ownerName or "Unknown"
    if NextKey222.Addon.IsPlayerOwner and NextKey222.Addon:IsPlayerOwner(ownerName) then
        if NextKey222.Addon and NextKey222.Addon.GetRaiderIOTotalScore then
            local playerScore = NextKey222.Addon:GetRaiderIOTotalScore()
            if playerScore and playerScore > score then
                score = playerScore
            end
        end
    end
    
    -- Check RaiderIO API for additional data
    if RaiderIO and RaiderIO.GetProfile then
        local profile = RaiderIO.GetProfile(ownerName)
        if profile and profile.mythicKeystoneProfile then
            local rioScore = profile.mythicKeystoneProfile.currentScore
            if rioScore and rioScore > score then
                score = rioScore
            end
        end
    end
    
    return score
end

--- Normalizes player name with realm information
-- @param rawName string The raw player name
-- @return string Normalized name with realm
function Components:NormalizePlayerName(rawName)
    if not rawName or rawName == "Unknown" then 
        return rawName or "Unknown"
    end
    
    -- Add current realm if no realm specified
    if not string.find(rawName, "-") then
        local currentRealm = GetRealmName()
        if currentRealm and currentRealm ~= "" then
            return rawName .. "-" .. currentRealm
        end
    end
    
    return rawName
end

-- MARK: Button Type Constants
Components.BUTTON_PRIMARY_ACTION = "primary_action"
Components.BUTTON_SECONDARY_ACTION = "secondary_action"
Components.BUTTON_COMPACT_LIST = "compact_list"
Components.BUTTON_SELECT = "select"
Components.BUTTON_SELECT_COMPACT = "select_compact"
Components.BUTTON_ICON = "icon"
Components.BUTTON_SECURE = "secure"
Components.BUTTON_TOGGLE = "toggle"
Components.BUTTON_SMALL = "small"
Components.BUTTON_LARGE = "large"

local BUTTON_CONFIGS = {
    [Components.BUTTON_PRIMARY_ACTION] = {
        size = { 120, 25 },
        text = "Action",
        colorScheme = "standard"
    },
    [Components.BUTTON_SECONDARY_ACTION] = {
        size = { 100, 25 },
        text = "Secondary",
        colorScheme = "light"
    },
    [Components.BUTTON_COMPACT_LIST] = {
        size = { 80, 22 },
        text = "Compact",
        colorScheme = "transparent"
    },
    [Components.BUTTON_SELECT] = {
        size = { 100, 25 },
        text = "Select",
        colorScheme = "standard"
    },
    [Components.BUTTON_SELECT_COMPACT] = {
        size = { 80, 22 },
        text = "Select",
        colorScheme = "light"
    },
    [Components.BUTTON_ICON] = {
        size = { 32, 32 },
        text = "",
        colorScheme = "transparent"
    },
    [Components.BUTTON_SECURE] = {
        size = { 100, 25 },
        text = "Secure",
        colorScheme = "standard"
    },
    [Components.BUTTON_TOGGLE] = {
        size = { 100, 25 },
        text = "Toggle",
        colorScheme = "standard"
    },
    [Components.BUTTON_SMALL] = {
        size = { 70, 20 },
        text = "Small",
        colorScheme = "light"
    },
    [Components.BUTTON_LARGE] = {
        size = { 150, 30 },
        text = "Large",
        colorScheme = "standard"
    }
}

--- Configures an AceGUI button with standardized styling
-- @param widget AceGUI-Button The AceGUI button widget to configure
-- @param buttonType string Button type from constants
-- @param config table Configuration overrides
function Components:ConfigureButton(widget, buttonType, config)
    config = config or {}

    local buttonConfig = BUTTON_CONFIGS[buttonType]
    if not buttonConfig then
        NextKey222.Debug:Dev("components", "Unknown button type:", buttonType)
        buttonConfig = BUTTON_CONFIGS[Components.BUTTON_PRIMARY_ACTION]
    end

    widget:SetText(config.text or buttonConfig.text)

    local size = config.size or buttonConfig.size
    widget:SetWidth(size[1])
    widget:SetHeight(size[2])

    if config.onClick then
        widget:SetCallback("OnClick", config.onClick)
    end
    if config.onEnter then
        widget:SetCallback("OnEnter", config.onEnter)
    end
    if config.onLeave then
        widget:SetCallback("OnLeave", config.onLeave)
    end
    if config.enabled ~= nil then
        widget:SetDisabled(not config.enabled)
    end
    
    -- Phase 7: Apply theme styling if available
    if NextKey222.Theme then
        NextKey222.Theme:ApplyButtonStyle(widget.frame, "normal")
    else
        -- Fallback to original backdrop styling
        if buttonConfig.colorScheme then
            self:ConfigureBackdrop(widget, "compact", { colorScheme = buttonConfig.colorScheme })
        end
    end
end

-- MARK: Icon Type Constants
Components.ICON_CLASS = "class"
Components.ICON_ROLE = "role"
Components.ICON_DUNGEON = "dungeon"
Components.ICON_ITEM = "item"
Components.ICON_SMALL = "small"
Components.ICON_LARGE = "large"

local ICON_CONFIGS = {
    [Components.ICON_CLASS] = {
        size = { 32, 32 },
        defaultTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    },
    [Components.ICON_ROLE] = {
        size = { 16, 16 },
        defaultTexture = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
    },
    [Components.ICON_DUNGEON] = {
        size = { 32, 32 },
        defaultTexture = "Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider"
    },
    [Components.ICON_ITEM] = {
        size = { 32, 32 },
        defaultTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    },
    [Components.ICON_SMALL] = {
        size = { 16, 16 },
        defaultTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    },
    [Components.ICON_LARGE] = {
        size = { 64, 64 },
        defaultTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    }
}

--- Configures an AceGUI icon with standardized styling
-- @param widget AceGUI-Icon The AceGUI icon widget to configure
-- @param iconType string Icon type from constants
-- @param config table Configuration overrides
function Components:ConfigureIcon(widget, iconType, config)
    config = config or {}

    local iconConfig = ICON_CONFIGS[iconType]
    if not iconConfig then
        NextKey222.Debug:Dev("components", "Unknown icon type:", iconType)
        iconConfig = ICON_CONFIGS[Components.ICON_SMALL]
    end

    local size = config.size or iconConfig.size
    widget:SetImageSize(size[1], size[2])
    widget:SetWidth(size[1])
    widget:SetHeight(size[2])

    if config.imagePath then
        widget:SetImage(config.imagePath)
    elseif iconConfig.defaultTexture then
        widget:SetImage(iconConfig.defaultTexture)
    end

    if config.onClick then
        widget:SetCallback("OnClick", config.onClick)
    end
    if config.onEnter then
        widget:SetCallback("OnEnter", config.onEnter)
    end
    if config.onLeave then
        widget:SetCallback("OnLeave", config.onLeave)
    end
end

-- MARK: Frame Type Constants
Components.FRAME_WINDOW = "window"
Components.FRAME_PANEL = "panel"
Components.FRAME_CONTAINER = "container"
Components.FRAME_SCROLL = "scroll"
Components.FRAME_TOOLTIP = "tooltip"
Components.FRAME_DIALOG = "dialog"

local FRAME_CONFIGS = {
    [Components.FRAME_WINDOW] = {
        backdropType = "dialog",
        colorScheme = "dark"
    },
    [Components.FRAME_PANEL] = {
        backdropType = "tooltip",
        colorScheme = "standard"
    },
    [Components.FRAME_CONTAINER] = {
        backdropType = "compact",
        colorScheme = "transparent"
    },
    [Components.FRAME_SCROLL] = {
        backdropType = "tooltip",
        colorScheme = "light"
    },
    [Components.FRAME_TOOLTIP] = {
        backdropType = "tooltip",
        colorScheme = "standard"
    },
    [Components.FRAME_DIALOG] = {
        backdropType = "dialog",
        colorScheme = "dark"
    }
}

--- Configures an AceGUI frame/container with standardized styling
-- @param widget AceGUI-Container The AceGUI container widget to configure
-- @param frameType string Frame type from constants
-- @param config table Configuration overrides
function Components:ConfigureFrame(widget, frameType, config)
    config = config or {}

    local frameConfig = FRAME_CONFIGS[frameType]
    if not frameConfig then
        NextKey222.Debug:Dev("components", "Unknown frame type:", frameType)
        frameConfig = FRAME_CONFIGS[Components.FRAME_CONTAINER]
    end

    -- Apply backdrop styling
    self:ConfigureBackdrop(widget, frameConfig.backdropType, {
        colorScheme = config.colorScheme or frameConfig.colorScheme
    })

    if config.width then
        widget:SetWidth(config.width)
    end
    if config.height then
        widget:SetHeight(config.height)
    end
    if config.fullWidth then
        widget:SetFullWidth(true)
    end
    if config.fullHeight then
        widget:SetFullHeight(true)
    end
    if config.relativeWidth then
        widget:SetRelativeWidth(config.relativeWidth)
    end
    if config.layout then
        widget:SetLayout(config.layout)
    end
end

-- MARK: Text Type Constants
Components.TEXT_HEADER = "header"
Components.TEXT_BODY = "body"
Components.TEXT_LABEL = "label"
Components.TEXT_TOOLTIP = "tooltip"
Components.TEXT_SCORE = "score"
Components.TEXT_SMALL = "small"
Components.TEXT_LARGE = "large"

local TEXT_CONFIGS = {
    [Components.TEXT_HEADER] = {
        fontObject = GameFontNormalLarge,
        color = {1, 1, 1},
        justifyH = "CENTER"
    },
    [Components.TEXT_BODY] = {
        fontObject = GameFontNormal,
        color = {1, 1, 1},
        justifyH = "LEFT"
    },
    [Components.TEXT_LABEL] = {
        fontObject = GameFontNormalSmall,
        color = {0.8, 0.8, 0.8},
        justifyH = "LEFT"
    },
    [Components.TEXT_TOOLTIP] = {
        fontObject = GameTooltipText,
        color = {1, 1, 1},
        justifyH = "LEFT"
    },
    [Components.TEXT_SCORE] = {
        fontObject = GameFontNormal,
        color = {0, 1, 0},
        justifyH = "RIGHT"
    },
    [Components.TEXT_SMALL] = {
        fontObject = GameFontNormalSmall,
        color = {0.7, 0.7, 0.7},
        justifyH = "LEFT"
    },
    [Components.TEXT_LARGE] = {
        fontObject = GameFontNormalLarge,
        color = {1, 1, 1},
        justifyH = "CENTER"
    }
}

--- Configures an AceGUI label with standardized styling (Phase 7: Enhanced with theme support)
-- @param widget AceGUI-Label The AceGUI label widget to configure
-- @param textType string Text type from constants
-- @param config table Configuration overrides
function Components:ConfigureText(widget, textType, config)
    config = config or {}

    local textConfig = TEXT_CONFIGS[textType]
    if not textConfig then
        NextKey222.Debug:Dev("components", "Unknown text type:", textType)
        textConfig = TEXT_CONFIGS[Components.TEXT_BODY]
    end

    local textValue = config.text or textConfig.text

    -- Phase 7: Apply theme styling if available
    if NextKey222.Theme then
        local themeFont = NextKey222.Theme:GetFont("text", textType, textConfig.fontObject)
        local themeColor = NextKey222.Theme:GetColor("text", textType, textConfig.color)
        
        widget:SetFontObject(themeFont)
        widget:SetColor(themeColor[1], themeColor[2], themeColor[3])
    else
        -- Fallback to original styling
        widget:SetFontObject(config.fontObject or textConfig.fontObject)
        
        local color = config.color or textConfig.color
        widget:SetColor(color[1], color[2], color[3])
    end
    
    widget:SetJustifyH(config.justifyH or textConfig.justifyH)
    
    if textValue then
        widget:SetText(textValue)
    end

    if config.width then
        widget:SetWidth(config.width)
    end
    if config.height then
        widget:SetHeight(config.height)
    end
    if config.fullWidth then
        widget:SetFullWidth(true)
    end
    if config.relativeWidth then
        widget:SetRelativeWidth(config.relativeWidth)
    end
end

-- MARK: Component Factory Functions

--- Creates a configured button widget
-- @param buttonType string Button type from constants
-- @param parent Frame Parent frame (optional)
-- @param config table Configuration overrides
-- @return AceGUI-Button The configured button widget
function Components:CreateButton(buttonType, parent, config)
    local widget = AceGUI:Create("Button")
    self:ConfigureButton(widget, buttonType, config)
    return widget
end

--- Creates a configured icon widget with dynamic configuration support
-- @param iconType string Icon type from constants
-- @param parent Frame Parent frame (optional)
-- @param config table Configuration overrides
-- @return AceGUI-Icon The configured icon widget
function Components:CreateIcon(iconType, parent, config)
    local widget = AceGUI:Create("Icon")
    
    -- Apply dynamic configuration
    local baseConfig = ICON_CONFIGS[iconType] or ICON_CONFIGS[self.ICON_SMALL]
    local finalConfig = self:ApplyDynamicConfiguration(widget, "icon", baseConfig, config)
    
    self:ConfigureIcon(widget, iconType, finalConfig)
    return widget
end

--- Creates a configured container widget with dynamic configuration support
-- @param frameType string Frame type from constants
-- @param parent Frame Parent frame (optional)
-- @param config table Configuration overrides
-- @return AceGUI-Container The configured container widget
function Components:CreateFrame(frameType, parent, config)
    local widgetType = "SimpleGroup"
    if frameType == Components.FRAME_WINDOW then
        widgetType = "Frame"
    elseif frameType == Components.FRAME_SCROLL then
        widgetType = "ScrollFrame"
    elseif frameType == Components.FRAME_TOOLTIP then
        widgetType = "SimpleGroup"
    end
    
    local widget = AceGUI:Create(widgetType)
    
    -- Apply dynamic configuration
    local baseConfig = FRAME_CONFIGS[frameType] or FRAME_CONFIGS[self.FRAME_CONTAINER]
    local finalConfig = self:ApplyDynamicConfiguration(widget, "frame", baseConfig, config)
    
    self:ConfigureFrame(widget, frameType, finalConfig)
    return widget
end

--- Creates a configured text widget with dynamic configuration support
-- @param textType string Text type from constants
-- @param parent Frame Parent frame (optional)
-- @param config table Configuration overrides
-- @return AceGUI-Label The configured label widget
function Components:CreateText(textType, parent, config)
    local widget = AceGUI:Create("Label")
    
    -- Apply dynamic configuration
    local baseConfig = TEXT_CONFIGS[textType] or TEXT_CONFIGS[self.TEXT_BODY]
    local finalConfig = self:ApplyDynamicConfiguration(widget, "text", baseConfig, config)
    
    self:ConfigureText(widget, textType, finalConfig)

    if parent then
        widget.frame:SetParent(parent)
        if parent.GetFrameLevel then
            widget.frame:SetFrameLevel(parent:GetFrameLevel() + 1)
        end
        if parent.GetFrameStrata then
            widget.frame:SetFrameStrata(parent:GetFrameStrata())
        end
        widget.frame:Show()
    else
        widget.frame:Hide()
    end

    if not widget.GetStringWidth then
        function widget:GetStringWidth()
            return self.label and self.label:GetStringWidth() or 0
        end
    end
    if not widget.GetStringHeight then
        function widget:GetStringHeight()
            return self.label and self.label:GetStringHeight() or 0
        end
    end

    return widget
end

--- Creates a configured backdrop on an existing frame with dynamic configuration support
-- @param frame Frame The frame to apply backdrop to
-- @param backdropType string Backdrop type from constants
-- @param config table Configuration overrides
-- @return Frame The frame with backdrop applied
function Components:CreateBackdrop(frame, backdropType, config)
    -- Apply dynamic configuration
    local baseConfig = BACKDROP_CONFIGS[backdropType] or BACKDROP_CONFIGS[self.BACKDROP_TOOLTIP]
    local finalConfig = self:ApplyDynamicConfiguration(frame, "backdrop", baseConfig, config)
    
    self:ConfigureBackdrop(frame, backdropType, finalConfig)
    return frame
end

-- MARK: Complex Widget Type Constants
Components.DROPDOWN_PRIMARY = "primary"
Components.DROPDOWN_COMPACT = "compact"
Components.SCROLLFRAME_PRIMARY = "primary"
Components.SCROLLFRAME_COMPACT = "compact"

local DROPDOWN_CONFIGS = {
    [Components.DROPDOWN_PRIMARY] = {
        width = 200,
        height = 25,
        colorScheme = "standard"
    },
    [Components.DROPDOWN_COMPACT] = {
        width = 150,
        height = 22,
        colorScheme = "light"
    }
}

local SCROLLFRAME_CONFIGS = {
    [Components.SCROLLFRAME_PRIMARY] = {
        backdropType = "tooltip",
        colorScheme = "standard"
    },
    [Components.SCROLLFRAME_COMPACT] = {
        backdropType = "compact",
        colorScheme = "light"
    }
}

--- Configures an AceGUI dropdown with standardized styling
-- @param widget AceGUI-Dropdown The AceGUI dropdown widget to configure
-- @param dropdownType string Dropdown type from constants
-- @param config table Configuration overrides
function Components:ConfigureDropdown(widget, dropdownType, config)
    config = config or {}

    local dropdownConfig = DROPDOWN_CONFIGS[dropdownType]
    if not dropdownConfig then
        NextKey222.Debug:Dev("components", "Unknown dropdown type:", dropdownType)
        dropdownConfig = DROPDOWN_CONFIGS[Components.DROPDOWN_PRIMARY]
    end

    if config.width then
        widget:SetWidth(config.width)
    else
        widget:SetWidth(dropdownConfig.width)
    end
    
    if config.height then
        widget:SetHeight(config.height)
    end
    
    if config.label then
        widget:SetLabel(config.label)
    end
    
    if config.list then
        widget:SetList(config.list)
    end
    
    if config.value then
        widget:SetValue(config.value)
    end
    
    if config.onValueChanged then
        widget:SetCallback("OnValueChanged", config.onValueChanged)
    end

    -- Apply backdrop styling
    self:ConfigureBackdrop(widget, "compact", {
        colorScheme = config.colorScheme or dropdownConfig.colorScheme
    })
end

--- Configures an AceGUI scroll frame with standardized styling
-- @param widget AceGUI-ScrollFrame The AceGUI scroll frame widget to configure
-- @param scrollFrameType string Scroll frame type from constants
-- @param config table Configuration overrides
function Components:ConfigureScrollFrame(widget, scrollFrameType, config)
    config = config or {}

    local scrollFrameConfig = SCROLLFRAME_CONFIGS[scrollFrameType]
    if not scrollFrameConfig then
        NextKey222.Debug:Dev("components", "Unknown scroll frame type:", scrollFrameType)
        scrollFrameConfig = SCROLLFRAME_CONFIGS[Components.SCROLLFRAME_PRIMARY]
    end

    if config.width then
        widget:SetWidth(config.width)
    end
    
    if config.height then
        widget:SetHeight(config.height)
    end
    
    if config.layout then
        widget:SetLayout(config.layout)
    end
    
    if config.fullWidth then
        widget:SetFullWidth(true)
    end
    
    if config.fullHeight then
        widget:SetFullHeight(true)
    end

    -- Apply backdrop styling
    self:ConfigureBackdrop(widget, scrollFrameConfig.backdropType, {
        colorScheme = config.colorScheme or scrollFrameConfig.colorScheme
    })
end

--- Creates a configured dropdown widget
-- @param dropdownType string Dropdown type from constants
-- @param parent Frame Parent frame (optional)
-- @param config table Configuration overrides
-- @return AceGUI-Dropdown The configured dropdown widget
function Components:CreateDropdown(dropdownType, parent, config)
    local widget = AceGUI:Create("Dropdown")
    self:ConfigureDropdown(widget, dropdownType, config)
    return widget
end

--- Creates a configured scroll frame widget
-- @param scrollFrameType string Scroll frame type from constants
-- @param parent Frame Parent frame (optional)
-- @param config table Configuration overrides
-- @return AceGUI-ScrollFrame The configured scroll frame widget
function Components:CreateScrollFrame(scrollFrameType, parent, config)
    NextKey222.Debug:Dev("components", "CreateScrollFrame called - creating AceGUI ScrollFrame")
    local widget = AceGUI:Create("ScrollFrame")
    
    -- CRITICAL: Check if the underlying frame is being created visible
    if widget and widget.frame then
        NextKey222.Debug:Dev("components", "ScrollFrame created - underlying frame visibility:", widget.frame:IsShown() and "VISIBLE" or "HIDDEN")
        NextKey222.Debug:Dev("components", "ScrollFrame parent:", widget.frame:GetParent() and widget.frame:GetParent():GetName() or "nil")
        
        -- Force hide the scroll frame immediately to prevent scroll bar showing
        widget.frame:Hide()
        NextKey222.Debug:Dev("components", "ScrollFrame force HIDDEN to prevent scroll bar on load")
    end
    
    self:ConfigureScrollFrame(widget, scrollFrameType, config)
    return widget
end

-- MARK: Legacy Factory Functions (for backward compatibility)

--- Creates a card container for keystone/dungeon display
-- @param height number Height of the container
-- @param compact boolean Whether to use compact layout
-- @return AceGUI-Container The configured container
function Components:CreateCardContainer(height, compact)
    local container = AceGUI:Create("SimpleGroup")

    container:SetFullWidth(true)
    container:SetLayout("Manual")
    container:SetHeight(height)

    local frame = container.frame
    frame:SetHeight(height)
    frame.height = height
    frame:SetClipsChildren(false)

    local content = container.content
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    content:SetHeight(height)
    content.height = height
    content:SetClipsChildren(false)

    return container
end

--- Creates a class icon with tooltip support
-- @param parent Frame Parent frame
-- @param classToken string Class token (e.g., "WARRIOR")
-- @param size number Icon size
-- @param playerData table Player data for tooltip
-- @return Frame The class icon frame
function Components:CreateClassIcon(parent, classToken, size, playerData)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size, size)
    
    -- Set class icon texture
    local classIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
    if classToken and _G.CLASS_ICON_TCOORDS[classToken] then
        classIcon = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
        local coords = _G.CLASS_ICON_TCOORDS[classToken]
        local texture = icon:CreateTexture()
        texture:SetAllPoints()
        texture:SetTexture(classIcon)
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        local texture = icon:CreateTexture()
        texture:SetAllPoints()
        texture:SetTexture(classIcon)
    end
    
    -- Add tooltip support
    if playerData then
        icon:SetScript("OnEnter", function()
            -- Tooltip implementation would go here
        end)
        icon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return icon
end

--- Creates a role icon
-- @param parent Frame Parent frame
-- @param role string Role ("TANK", "HEALER", "DAMAGER")
-- @param size number Icon size
-- @return Frame The role icon frame
function Components:CreateRoleIcon(parent, role, size)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size, size)
    
    -- Set role icon texture
    local roleIcon = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
    local texture = icon:CreateTexture()
    texture:SetAllPoints()
    texture:SetTexture(roleIcon)
    
    -- Set texture coordinates based on role
    if role == "TANK" then
        texture:SetTexCoord(0, 0.25, 0, 0.25)
    elseif role == "HEALER" then
        texture:SetTexCoord(0.25, 0.5, 0, 0.25)
    elseif role == "DAMAGER" then
        texture:SetTexCoord(0.5, 0.75, 0, 0.25)
    else
        texture:SetTexCoord(0.75, 1, 0, 0.25)
    end
    
    return icon
end

--- Creates a select button (LEGACY - for backward compatibility)
-- @param parent Frame Parent frame
-- @param buttonType string Button type ("select" or "select_compact")
-- @param text string Button text (optional)
-- @param onClick function Button click handler
-- @return Frame The button frame
function Components:CreateButtonLegacy(parent, buttonType, text, onClick)
    local button = CreateFrame("Button", nil, parent)
    
    local config = BUTTON_CONFIGS[buttonType] or BUTTON_CONFIGS[Components.BUTTON_SELECT]
    button:SetSize(config.size[1], config.size[2])
    
    -- Apply backdrop
    self:ConfigureBackdrop(button, "compact", { colorScheme = config.colorScheme or "standard" })
    
    -- Set text
    if text and type(text) == "string" then
        button:SetText(text)
    elseif config.text then
        button:SetText(config.text)
    end
    
    -- Set click handler
    if onClick and type(onClick) == "function" then
        button:SetScript("OnClick", onClick)
    end
    
    return button
end

-- MARK: Text Formatting Utilities

--- Formats player name with IO score coloring
-- @param playerName string Player name
-- @param classToken string Class token
-- @param score number IO score
-- @return string Formatted player name with score
function Components:FormatPlayerNameWithScore(playerName, classToken, score)
    if not playerName then return "Unknown" end
    
    local displayName = playerName:match("^([^%-]+)") or playerName
    
    -- Add class color if available
    if classToken and _G.RAID_CLASS_COLORS[classToken] then
        local color = _G.RAID_CLASS_COLORS[classToken]
        displayName = string.format("|cff%02x%02x%02x%s|r",
            color.r * 255, color.g * 255, color.b * 255, displayName)
    end
    
    -- Add score if available
    if score and score > 0 then
        return string.format("%s (%.0f)", displayName, score)
    else
        return displayName
    end
end

--- Formats keystone display text
-- @param dungeonName string Dungeon name
-- @param level number Keystone level
-- @return string Formatted keystone display
function Components:FormatKeystoneDisplay(dungeonName, level)
    if not dungeonName then return "No Keystone" end
    
    if level and level > 0 then
        return string.format("%s |cff4aa3ff+%d|r", dungeonName, level)
    else
        return dungeonName
    end
end

-- MARK: Tooltip System (Phase 7: Enhanced with centralized tooltip management)

--- Attaches player tooltip to a frame (Phase 7: Now using centralized tooltip system)
-- @param frame Frame The frame to attach tooltip to
-- @param playerData table Player information
function Components:AttachPlayerTooltip(frame, playerData)
    if not frame or not playerData then return end
    
    -- Phase 7: Use centralized tooltip system if available
    if NextKey222.Tooltip then
        local tooltipData = {
            frame = frame,
            name = playerData.ownerName or "Unknown",
            classToken = playerData.classToken,
            specName = playerData.specName,
            role = playerData.role,
            io = playerData.io,
            hasHeroism = playerData.hasHeroism,
            hasBattleRes = playerData.hasBattleRes
        }
        
        NextKey222.Tooltip:Attach(frame, NextKey222.Tooltip.TYPE_PLAYER, tooltipData)
        return
    end
    
    -- Fallback to original implementation
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(playerData.ownerName or "Unknown", 1, 1, 1)
        
        if playerData.specName then
            GameTooltip:AddLine("Specialization: " .. playerData.specName, 0.8, 0.8, 0.8)
        end
        
        if playerData.role then
            GameTooltip:AddLine("Role: " .. playerData.role, 0.8, 0.8, 0.8)
        end
        
        if playerData.io and playerData.io > 0 then
            GameTooltip:AddLine(string.format("Total IO: %.0f", playerData.io), 0, 1, 0)
        end
        
        GameTooltip:Show()
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Attaches keystone tooltip to a frame (Phase 7: New centralized tooltip support)
-- @param frame Frame The frame to attach tooltip to
-- @param keyData table Keystone information
function Components:AttachKeystoneTooltip(frame, keyData)
    if not frame or not keyData then return end
    
    -- Phase 7: Use centralized tooltip system if available
    if NextKey222.Tooltip then
        local tooltipData = {
            frame = frame,
            dungeonName = keyData.dungeonName,
            level = keyData.level,
            ownerName = keyData.ownerName,
            ioGain = keyData.ioGain
        }
        
        NextKey222.Tooltip:Attach(frame, NextKey222.Tooltip.TYPE_KEYSTONE, tooltipData)
        return
    end
    
    -- Fallback implementation
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        if keyData.dungeonName and keyData.level then
            GameTooltip:SetText(string.format("%s (+%d)", keyData.dungeonName, keyData.level), 1, 1, 1)
        else
            GameTooltip:SetText("Keystone", 1, 1, 1)
        end
        
        if keyData.ownerName then
            GameTooltip:AddLine("Owner: " .. keyData.ownerName, 0.8, 0.8, 0.8)
        end
        
        if keyData.ioGain and keyData.ioGain > 0 then
            GameTooltip:AddLine(string.format("IO Gain: +%.0f", keyData.ioGain), 0, 1, 0)
        end
        
        GameTooltip:Show()
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Attaches dungeon tooltip to a frame (Phase 7: New centralized tooltip support)
-- @param frame Frame The frame to attach tooltip to
-- @param dungeonData table Dungeon information
function Components:AttachDungeonTooltip(frame, dungeonData)
    if not frame or not dungeonData then return end
    
    -- Phase 7: Use centralized tooltip system if available
    if NextKey222.Tooltip then
        local tooltipData = {
            frame = frame,
            name = dungeonData.name,
            score = dungeonData.score,
            bestLevel = dungeonData.bestLevel,
            chests = dungeonData.chests
        }
        
        NextKey222.Tooltip:Attach(frame, NextKey222.Tooltip.TYPE_DUNGEON, tooltipData)
        return
    end
    
    -- Fallback implementation
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(dungeonData.name or "Dungeon", 1, 1, 1)
        
        if dungeonData.score and dungeonData.score > 0 then
            GameTooltip:AddLine(string.format("Score: %.0f", dungeonData.score), 0, 1, 0)
        end
        
        if dungeonData.bestLevel and dungeonData.bestLevel > 0 then
            GameTooltip:AddLine(string.format("Best Level: +%d", dungeonData.bestLevel), 0.4, 1, 0.9)
        end
        
        GameTooltip:Show()
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Attaches IO gain tooltip to a frame (Phase 7: New centralized tooltip support)
-- @param frame Frame The frame to attach tooltip to
-- @param ioData table IO gain information
function Components:AttachIOGainTooltip(frame, ioData)
    if not frame or not ioData then return end
    
    -- Phase 7: Use centralized tooltip system if available
    if NextKey222.Tooltip then
        local tooltipData = {
            frame = frame,
            title = ioData.title,
            subtitle = ioData.subtitle,
            breakdown = ioData.breakdown,
            totals = ioData.totals
        }
        
        NextKey222.Tooltip:Attach(frame, NextKey222.Tooltip.TYPE_IO_GAIN, tooltipData)
        return
    end
    
    -- Fallback implementation
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(ioData.title or "IO Gain", 1, 1, 1)
        
        if ioData.subtitle then
            GameTooltip:AddLine(ioData.subtitle, 0.9, 0.9, 1)
        end
        
        GameTooltip:Show()
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Attaches item tooltip to a frame (Phase 7: New centralized tooltip support)
-- @param frame Frame The frame to attach tooltip to
-- @param itemID number The item ID
function Components:AttachItemTooltip(frame, itemID)
    if not frame or not itemID then return end
    
    -- Phase 7: Use centralized tooltip system if available
    if NextKey222.Tooltip then
        local itemName, itemLink, itemQuality = GetItemInfo(itemID)
        local tooltipData = {
            frame = frame,
            name = itemName or "Unknown Item",
            quality = itemQuality,
            type = "Item",
            description = "Click for more details"
        }
        
        NextKey222.Tooltip:Attach(frame, NextKey222.Tooltip.TYPE_ITEM, tooltipData)
        return
    end
    
    -- Fallback to standard item tooltip
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(itemID)
        GameTooltip:Show()
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- MARK: Initialization
function Components:Initialize()
    NextKey222.Debug:Dev("components", "UI Components system initialized")
    return true
end

return Components
