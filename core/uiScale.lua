-- MARK: UI Scale Config
-- Centralized UI scale management with responsive scaling and user preferences
-- Phase 7: UI Scale Configuration System

local _, NextKey222 = ...

local UIScale = {}
NextKey222.UIScale = UIScale

-- Register with module system
NextKey222.RegisterModule("UIScale", UIScale)

-- MARK: Scale Constants
-- Standardized scale factors and limits

UIScale.MIN_SCALE = 0.5
UIScale.MAX_SCALE = 2.0
UIScale.DEFAULT_SCALE = 1.0
UIScale.AUTO_SCALE = "auto"

-- MARK: Scale Configuration
-- Current scale state and configuration

UIScale.currentScale = UIScale.DEFAULT_SCALE
UIScale.autoScaleEnabled = false
UIScale.baseUIScale = UIParent:GetScale()

-- MARK: Resolution Functions
-- Functions to calculate and apply UI scaling

--- Gets the current UI scale
-- @return number The current scale factor
function UIScale:GetCurrentScale()
    return self.currentScale
end

--- Sets the UI scale
-- @param scale number The scale factor to set (0.5-2.0)
-- @return boolean True if scale was set successfully
function UIScale:SetScale(scale)
    if not scale or scale < self.MIN_SCALE or scale > self.MAX_SCALE then
        Debug:Error("UIScale:SetScale - Invalid scale value:", scale)
        return false
    end
    
    self.currentScale = scale
    self.autoScaleEnabled = false
    self:ApplyScale()
    self:SaveScale()
    
    Debug:Dev("uiScale", "UI scale set to:", scale)
    return true
end

--- Enables automatic scaling based on screen resolution
-- @return boolean True if auto scaling was enabled successfully
function UIScale:EnableAutoScale()
    self.autoScaleEnabled = true
    self:CalculateAutoScale()
    self:ApplyScale()
    self:SaveScale()
    
    Debug:Dev("uiScale", "Auto scale enabled")
    return true
end

--- Disables automatic scaling
-- @return boolean True if auto scaling was disabled successfully
function UIScale:DisableAutoScale()
    self.autoScaleEnabled = false
    self:SaveScale()
    
    Debug:Dev("uiScale", "Auto scale disabled")
    return true
end

--- Checks if auto scaling is enabled
-- @return boolean True if auto scaling is enabled
function UIScale:IsAutoScaleEnabled()
    return self.autoScaleEnabled
end

--- Calculates optimal scale based on screen resolution
-- @return number The calculated scale factor
function UIScale:CalculateAutoScale()
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    
    -- Validate screen dimensions
    if not screenWidth or not screenHeight or screenWidth <= 0 or screenHeight <= 0 then
        Debug:Error("UIScale:CalculateAutoScale - Invalid screen dimensions:", screenWidth, screenHeight)
        return self.DEFAULT_SCALE
    end
    
    -- Calculate optimal scale based on screen resolution
    -- Target: maintain roughly the same physical size across different resolutions
    local baseResolution = 1920 * 1080 -- Reference 1080p
    local currentResolution = screenWidth * screenHeight
    
    -- Prevent division by zero
    if currentResolution <= 0 then
        Debug:Error("UIScale:CalculateAutoScale - Invalid current resolution:", currentResolution)
        return self.DEFAULT_SCALE
    end
    
    -- Calculate scale factor (square root for area scaling)
    local resolutionFactor = math.sqrt(currentResolution / baseResolution)
    
    -- Apply gentle scaling (not too aggressive)
    local calculatedScale = 1.0 / resolutionFactor
    
    -- Clamp to min/max values
    calculatedScale = math.max(self.MIN_SCALE, math.min(self.MAX_SCALE, calculatedScale))
    
    -- Round to 2 decimal places for consistency
    calculatedScale = math.floor(calculatedScale * 100 + 0.5) / 100
    
    Debug:Dev("uiScale", "Auto scale calculated:", calculatedScale,
              "based on resolution:", screenWidth, "x", screenHeight)
    
    return calculatedScale
end

--- Applies the current scale to UI elements
function UIScale:ApplyScale()
    local scale = self.currentScale
    
    if self.autoScaleEnabled then
        scale = self:CalculateAutoScale()
    end
    
    -- Apply scale to main UI elements
    if NextKey222.UI and NextKey222.UI.mainFrame then
        NextKey222.UI.mainFrame:SetScale(scale)
    end
    
    -- Apply scale to teleport window
    if NextKey222.Addon and NextKey222.Addon.teleportWindow then
        NextKey222.Addon.teleportWindow.frame:SetScale(scale)
    end
    
    -- Apply scale to loot window
    if NextKey222.LootWindow and NextKey222.LootWindow.frame then
        NextKey222.LootWindow.frame:SetScale(scale)
    end
    
    -- Notify other systems of scale change
    self:NotifyScaleChange(scale)
    
    Debug:Dev("uiScale", "UI scale applied:", scale)
end

--- Notifies other systems of scale changes
-- @param scale number The new scale factor
function UIScale:NotifyScaleChange(scale)
    -- Notify UI system
    if NextKey222.UI and NextKey222.UI.OnScaleChanged then
        NextKey222.UI:OnScaleChanged(scale)
    end
    
    -- Notify tooltip system
    if NextKey222.Tooltip and NextKey222.Tooltip.OnScaleChanged then
        NextKey222.Tooltip:OnScaleChanged(scale)
    end
    
    -- Notify theme system
    if NextKey222.Theme and NextKey222.Theme.OnScaleChanged then
        NextKey222.Theme:OnScaleChanged(scale)
    end
end

-- MARK: Scale Presets
-- Predefined scale factors for common use cases

UIScale.presets = {
    tiny = 0.6,
    small = 0.8,
    normal = 1.0,
    large = 1.2,
    huge = 1.5,
    massive = 1.8
}

--- Applies a scale preset
-- @param presetName string The preset name (tiny, small, normal, large, huge, massive)
-- @return boolean True if preset was applied successfully
function UIScale:ApplyPreset(presetName)
    local scale = self.presets[presetName]
    if not scale then
        Debug:Error("UIScale:ApplyPreset - Unknown preset:", presetName)
        return false
    end
    
    return self:SetScale(scale)
end

--- Gets available scale presets
-- @return table List of available presets with their scale factors
function UIScale:GetPresets()
    local presets = {}
    for name, scale in pairs(self.presets) do
        table.insert(presets, {
            name = name,
            scale = scale,
            displayName = name:sub(1, 1):upper() .. name:sub(2)
        })
    end
    
    -- Sort by scale factor
    table.sort(presets, function(a, b) return a.scale < b.scale end)
    
    return presets
end

-- MARK: Animation
-- Smooth scale transitions

UIScale.animationDuration = 0.3
UIScale.animationEasing = "in-out"

--- Animates scale change to a new value
-- @param targetScale number The target scale factor
-- @param duration number Animation duration in seconds (optional)
-- @param easing string Animation easing type (optional)
function UIScale:AnimateScale(targetScale, duration, easing)
    duration = duration or self.animationDuration
    easing = easing or self.animationEasing
    
    local startScale = self.currentScale
    local startTime = GetTime()
    local endTime = startTime + duration
    
    -- Create animation frame
    local animationFrame = CreateFrame("Frame")
    animationFrame:SetScript("OnUpdate", function()
        local elapsed = GetTime() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        -- Apply easing
        local easedProgress
        if easing == "in-out" then
            easedProgress = progress < 0.5 and 2 * progress * progress or 1 - math.pow(-2 * progress + 2, 2) / 2
        elseif easing == "in" then
            easedProgress = progress * progress
        elseif easing == "out" then
            easedProgress = 1 - math.pow(1 - progress, 2)
        else
            easedProgress = progress
        end
        
        -- Calculate current scale
        local currentScale = startScale + (targetScale - startScale) * easedProgress
        
        -- Apply scale
        self.currentScale = currentScale
        self:ApplyScale()
        
        -- Clean up when animation is complete
        if progress >= 1 then
            animationFrame:SetScript("OnUpdate", nil)
            self:SaveScale()
        end
    end)
    
    Debug:Dev("uiScale", "Scale animation started:", startScale, "->", targetScale)
end

-- MARK: Persistence
-- Functions to save and load scale preferences

--- Saves the current scale to saved variables
function UIScale:SaveScale()
    if NextKey and NextKey.db and NextKey.db.char then
        NextKey.db.char.uiScale = {
            scale = self.currentScale,
            autoScaleEnabled = self.autoScaleEnabled
        }
        Debug:Dev("uiScale", "UI scale saved:", self.currentScale, "auto:", self.autoScaleEnabled)
    end
end

--- Loads the scale from saved variables
function UIScale:LoadScale()
    if NextKey and NextKey.db and NextKey.db.char and NextKey.db.char.uiScale then
        local savedScale = NextKey.db.char.uiScale
        
        self.currentScale = savedScale.scale or self.DEFAULT_SCALE
        self.autoScaleEnabled = savedScale.autoScaleEnabled or false
        
        Debug:Dev("uiScale", "UI scale loaded:", self.currentScale, "auto:", self.autoScaleEnabled)
    else
        Debug:Dev("uiScale", "No saved scale found, using defaults")
    end
end

-- MARK: Utilities
-- Utility functions for scale calculations

--- Scales a dimension value by the current scale factor
-- @param value number The value to scale
-- @param round boolean Whether to round the result (optional)
-- @return number The scaled value
function UIScale:ScaleValue(value, round)
    local scaled = value * self.currentScale
    return round and math.floor(scaled + 0.5) or scaled
end

--- Unscales a dimension value by the current scale factor
-- @param value number The value to unscale
-- @param round boolean Whether to round the result (optional)
-- @return number The unscaled value
function UIScale:UnscaleValue(value, round)
    -- Prevent division by zero
    if not self.currentScale or self.currentScale == 0 then
        Debug:Error("UIScale:UnscaleValue - Invalid current scale:", self.currentScale)
        return value
    end
    
    local unscaled = value / self.currentScale
    return round and math.floor(unscaled + 0.5) or unscaled
end

--- Gets the effective scale (current scale * base UI scale)
-- @return number The effective scale factor
function UIScale:GetEffectiveScale()
    return self.currentScale * self.baseUIScale
end

--- Resets scale to default values
function UIScale:Reset()
    self.currentScale = self.DEFAULT_SCALE
    self.autoScaleEnabled = false
    self:ApplyScale()
    self:SaveScale()
    
    Debug:Dev("uiScale", "UI scale reset to defaults")
end

-- MARK: Event Handling
-- Functions to handle scale-related events

--- Called when screen resolution changes
function UIScale:OnScreenResolutionChanged()
    if self.autoScaleEnabled then
        local newScale = self:CalculateAutoScale()
        if math.abs(newScale - self.currentScale) > 0.01 then
            self:AnimateScale(newScale)
            Debug:Dev("uiScale", "Auto scale adjusted due to resolution change")
        end
    end
end

--- Called when UI scale settings change
function UIScale:OnUIScaleSettingsChanged()
    self.baseUIScale = UIParent:GetScale()
    self:ApplyScale()
    Debug:Dev("uiScale", "Base UI scale changed, reapplying scale")
end

-- MARK: Initialization
function UIScale:Initialize()
    Debug:Dev("uiScale", "UI Scale module initialized")
    
    -- Load saved scale
    self:LoadScale()
    
    -- Register for resolution change events
    local resolutionFrame = CreateFrame("Frame")
    resolutionFrame:RegisterEvent("UI_SCALE_CHANGED")
    resolutionFrame:SetScript("OnEvent", function()
        if event == "UI_SCALE_CHANGED" then
            self:OnUIScaleSettingsChanged()
        end
    end)
    
    -- Apply initial scale
    self:ApplyScale()
    
    return true
end

return UIScale