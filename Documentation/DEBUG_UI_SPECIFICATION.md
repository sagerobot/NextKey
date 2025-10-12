# Debug UI Implementation Specification

## Overview

This document provides the detailed implementation specification for the enhanced debug options interface that will be integrated into the NextKey addon's main configuration panel.

## File Structure

```
core/
├── debugService.lua (existing - will be enhanced)
├── debugUI.lua (new - debug UI module)
└── debugPresets.lua (new - preset management)

options/
├── main.lua (existing - will be enhanced)
└── debugOptions.lua (new - debug-specific options)

Documentation/
├── DEBUG_SYSTEM_DESIGN.md (created)
├── DEBUG_CATEGORY_MAPPING.md (created)
├── DEBUG_SYSTEM_ARCHITECTURE.md (created)
└── DEBUG_UI_SPECIFICATION.md (this file)
```

## Enhanced DebugService.lua

### New Group Management Functions

```lua
-- Add to DebugService in core/debugService.lua

-- Group management functions
function DebugService:GetCategoryGroups()
    return DEBUG_CATEGORY_GROUPS
end

function DebugService:EnableGroup(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        self:Error("Unknown debug group:", groupName)
        return false
    end
    
    local enabledCount = 0
    for categoryName, _ in pairs(group.categories) do
        if self:EnableCategory(categoryName) then
            enabledCount = enabledCount + 1
        end
    end
    
    self:User("Enabled debug group:", groupName, "(" .. enabledCount .. " categories)")
    return true
end

function DebugService:DisableGroup(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        self:Error("Unknown debug group:", groupName)
        return false
    end
    
    local disabledCount = 0
    for categoryName, _ in pairs(group.categories) do
        if self:DisableCategory(categoryName) then
            disabledCount = disabledCount + 1
        end
    end
    
    self:User("Disabled debug group:", groupName, "(" .. disabledCount .. " categories)")
    return true
end

function DebugService:ToggleGroup(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        self:Error("Unknown debug group:", groupName)
        return false
    end
    
    local currentState = self:GetGroupStatus(groupName)
    if currentState then
        return self:DisableGroup(groupName)
    else
        return self:EnableGroup(groupName)
    end
end

function DebugService:GetGroupStatus(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        return nil
    end
    
    local enabledCount = 0
    local totalCount = 0
    
    for categoryName, _ in pairs(group.categories) do
        totalCount = totalCount + 1
        if self.categories[categoryName] then
            enabledCount = enabledCount + 1
        end
    end
    
    return enabledCount > 0, enabledCount, totalCount
end

function DebugService:GetGroupCategories(groupName)
    local group = DEBUG_CATEGORY_GROUPS[groupName]
    if not group then
        return {}
    end
    
    local categories = {}
    for categoryName, _ in pairs(group.categories) do
        table.insert(categories, categoryName)
    end
    
    return categories
end

function DebugService:GetCategoryGroup(categoryName)
    for groupName, group in pairs(DEBUG_CATEGORY_GROUPS) do
        if group.categories[categoryName] then
            return groupName
        end
    end
    return nil
end
```

### Enhanced Statistics Functions

```lua
-- Add to DebugService in core/debugService.lua

function DebugService:GetStatistics()
    return {
        totalMessages = self.stats.errorCount + self.stats.userCount + 
                       self.stats.devCount + self.stats.traceCount,
        errorCount = self.stats.errorCount,
        userCount = self.stats.userCount,
        devCount = self.stats.devCount,
        traceCount = self.stats.traceCount,
        enabledCategories = self:GetEnabledCategoriesCount(),
        totalCategories = self:GetTotalCategoriesCount(),
        currentLevel = self.level,
        enabled = self.enabled,
        uptime = self:GetUptime(),
        memoryUsage = self:GetMemoryUsage()
    }
end

function DebugService:GetEnabledCategoriesCount()
    local count = 0
    for _, enabled in pairs(self.categories) do
        if enabled then
            count = count + 1
        end
    end
    return count
end

function DebugService:GetTotalCategoriesCount()
    local count = 0
    for _ in pairs(self.categories) do
        count = count + 1
    end
    return count
end

function DebugService:GetUptime()
    -- Calculate addon uptime in seconds
    if self.startTime then
        return time() - self.startTime
    end
    return 0
end

function DebugService:GetMemoryUsage()
    -- Get memory usage for debug system (in KB)
    if UpdateAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
        return GetAddOnMemoryUsage("NextKey")
    end
    return 0
end

function DebugService:ResetStatistics()
    self.stats.errorCount = 0
    self.stats.userCount = 0
    self.stats.devCount = 0
    self.stats.traceCount = 0
    self.startTime = time()
    self:User("Debug statistics reset")
end
```

## New DebugUI.lua Module

```lua
-- Create new file: core/debugUI.lua

local _, NextKey222 = ...
local DebugService = NextKey222.Debug
local AceGUI = LibStub("AceGUI-3.0")

local DebugUI = {}

-- Category groups configuration (imported from DEBUG_CATEGORY_MAPPING.md)
local DEBUG_CATEGORY_GROUPS = {
    -- (Same as defined in DEBUG_CATEGORY_MAPPING.md)
}

-- Preset configurations
local DEBUG_PRESETS = {
    -- (Same as defined in DEBUG_CATEGORY_MAPPING.md)
}

function DebugUI:CreateDebugOptions()
    return {
        type = "group",
        name = "Debug System",
        order = 50,
        args = {
            controlPanel = {
                type = "group",
                name = "Debug Control Panel",
                order = 1,
                args = self:CreateControlPanelArgs()
            },
            categoryGroups = {
                type = "group",
                name = "Category Groups",
                order = 2,
                args = self:CreateCategoryGroupsArgs()
            },
            outputOptions = {
                type = "group",
                name = "Output Options",
                order = 3,
                args = self:CreateOutputOptionsArgs()
            },
            presets = {
                type = "group",
                name = "Debug Presets",
                order = 4,
                args = self:CreatePresetsArgs()
            },
            statistics = {
                type = "group",
                name = "Statistics & Monitoring",
                order = 5,
                args = self:CreateStatisticsArgs()
            }
        }
    }
end

function DebugUI:CreateControlPanelArgs()
    return {
        enabled = {
            type = "toggle",
            name = "Enable Debug Mode",
            desc = "Master toggle for the entire debug system",
            get = function() return DebugService.enabled end,
            set = function(_, value) 
                DebugService:SetEnabled(value)
                self:RefreshOptions()
            end,
            width = "full",
            order = 1
        },
        
        level = {
            type = "select",
            name = "Debug Level",
            desc = "Set the verbosity level for debug output",
            values = {
                [0] = "NONE (0) - Silent",
                [1] = "ERROR (1) - Critical errors only",
                [2] = "USER (2) - User messages",
                [3] = "DEV (3) - Development messages",
                [4] = "TRACE (4) - Ultra-verbose tracing"
            },
            get = function() return DebugService.level end,
            set = function(_, value)
                DebugService:SetLevel(value)
                self:RefreshOptions()
            end,
            width = "full",
            order = 2
        },
        
        statusHeader = {
            type = "header",
            name = "Current Status",
            order = 3
        },
        
        statusDisplay = {
            type = "description",
            name = function()
                local stats = DebugService:GetStatistics()
                local levelNames = {"NONE", "ERROR", "USER", "DEV", "TRACE"}
                return string.format(
                    "Level: %s\n" ..
                    "Enabled Categories: %d/%d\n" ..
                    "Total Messages: %d\n" ..
                    "Uptime: %s",
                    levelNames[stats.currentLevel + 1] or "UNKNOWN",
                    stats.enabledCategories,
                    stats.totalCategories,
                    stats.totalMessages,
                    self:FormatUptime(stats.uptime)
                )
            end,
            fontSize = "medium",
            order = 4
        }
    }
end

function DebugUI:CreateCategoryGroupsArgs()
    local args = {}
    local order = 1
    
    -- Sort groups by order
    local sortedGroups = {}
    for groupName, groupData in pairs(DEBUG_CATEGORY_GROUPS) do
        table.insert(sortedGroups, {name = groupName, data = groupData})
    end
    table.sort(sortedGroups, function(a, b) return a.data.order < b.data.order end)
    
    for _, group in ipairs(sortedGroups) do
        local groupName = group.name
        local groupData = group.data
        
        -- Group header
        args[groupName .. "_header"] = {
            type = "header",
            name = groupData.description,
            order = order
        }
        order = order + 1
        
        -- Group toggle
        args[groupName .. "_toggle"] = {
            type = "toggle",
            name = "Enable " .. groupName,
            desc = "Enable/disable all categories in " .. groupName,
            get = function()
                local enabled, enabledCount, totalCount = DebugService:GetGroupStatus(groupName)
                return enabled
            end,
            set = function(_, value)
                if value then
                    DebugService:EnableGroup(groupName)
                else
                    DebugService:DisableGroup(groupName)
                end
                self:RefreshOptions()
            end,
            width = "full",
            order = order
        }
        order = order + 1
        
        -- Group status
        args[groupName .. "_status"] = {
            type = "description",
            name = function()
                local enabled, enabledCount, totalCount = DebugService:GetGroupStatus(groupName)
                local status = enabled and "|cFF00FF00Enabled|r" or "|cFF888888Disabled|r"
                return string.format("Status: %s (%d/%d categories)", status, enabledCount, totalCount)
            end,
            fontSize = "small",
            order = order
        }
        order = order + 1
        
        -- Individual category toggles
        for categoryName, categoryData in pairs(groupData.categories) do
            local key = groupName .. "_" .. categoryName
            
            args[key] = {
                type = "toggle",
                name = categoryData.name,
                desc = categoryData.description,
                get = function() return DebugService.categories[categoryName] end,
                set = function(_, value)
                    if value then
                        DebugService:EnableCategory(categoryName)
                    else
                        DebugService:DisableCategory(categoryName)
                    end
                    self:RefreshOptions()
                end,
                width = "full",
                order = order,
                indent = 1
            }
            order = order + 1
        end
    end
    
    return args
end

function DebugUI:CreateOutputOptionsArgs()
    return {
        formatting = {
            type = "group",
            name = "Message Formatting",
            order = 1,
            args = {
                timestamps = {
                    type = "toggle",
                    name = "Show Timestamps",
                    desc = "Include timestamps in debug messages",
                    get = function() 
                        return DebugService.db.global.debug.formatting and 
                               DebugService.db.global.debug.formatting.timestamps or false
                    end,
                    set = function(_, value)
                        DebugService.db.global.debug.formatting = DebugService.db.global.debug.formatting or {}
                        DebugService.db.global.debug.formatting.timestamps = value
                    end,
                    width = "full",
                    order = 1
                },
                
                sourceLocation = {
                    type = "toggle",
                    name = "Show Source Location",
                    desc = "Include file and line number in debug messages",
                    get = function() 
                        return DebugService.db.global.debug.formatting and 
                               DebugService.db.global.debug.formatting.sourceLocation or false
                    end,
                    set = function(_, value)
                        DebugService.db.global.debug.formatting = DebugService.db.global.debug.formatting or {}
                        DebugService.db.global.debug.formatting.sourceLocation = value
                    end,
                    width = "full",
                    order = 2
                },
                
                stackTraces = {
                    type = "toggle",
                    name = "Show Stack Traces",
                    desc = "Include detailed stack traces for error messages",
                    get = function() 
                        return DebugService.db.global.debug.formatting and 
                               DebugService.db.global.debug.formatting.stackTraces or false
                    end,
                    set = function(_, value)
                        DebugService.db.global.debug.formatting = DebugService.db.global.debug.formatting or {}
                        DebugService.db.global.debug.formatting.stackTraces = value
                    end,
                    width = "full",
                    order = 3
                }
            }
        },
        
        filtering = {
            type = "group",
            name = "Output Filtering",
            order = 2,
            args = {
                destination = {
                    type = "select",
                    name = "Output Destination",
                    desc = "Where debug messages should be displayed",
                    values = {
                        chat = "Chat Frame",
                        dedicated = "Dedicated Debug Frame",
                        both = "Both Chat and Debug Frame"
                    },
                    get = function() 
                        return DebugService.db.global.debug.filtering and 
                               DebugService.db.global.debug.filtering.destination or "chat"
                    end,
                    set = function(_, value)
                        DebugService.db.global.debug.filtering = DebugService.db.global.debug.filtering or {}
                        DebugService.db.global.debug.filtering.destination = value
                    end,
                    width = "full",
                    order = 1
                },
                
                throttling = {
                    type = "range",
                    name = "Message Throttling",
                    desc = "Maximum messages per second (0 = no limit)",
                    min = 0,
                    max = 100,
                    step = 1,
                    get = function() 
                        return DebugService.db.global.debug.filtering and 
                               DebugService.db.global.debug.filtering.throttling or 0
                    end,
                    set = function(_, value)
                        DebugService.db.global.debug.filtering = DebugService.db.global.debug.filtering or {}
                        DebugService.db.global.debug.filtering.throttling = value
                    end,
                    width = "full",
                    order = 2
                }
            }
        }
    }
end

function DebugUI:CreatePresetsArgs()
    local args = {}
    local order = 1
    
    -- Preset selector
    args.presetSelector = {
        type = "select",
        name = "Debug Presets",
        desc = "Quickly apply common debug configurations",
        values = {
            [""] = "Select a preset...",
            ["minimal"] = "Minimal (ERROR only)",
            ["standard"] = "Standard (ERROR + USER)",
            ["verbose"] = "Verbose (ERROR + USER + DEV)",
            ["full"] = "Full (ERROR + USER + DEV + TRACE)",
            ["ui_testing"] = "UI Testing",
            ["communications_testing"] = "Communications Testing",
            ["performance_testing"] = "Performance Testing"
        },
        get = function() return "" end,
        set = function(_, value)
            if value and value ~= "" then
                self:ApplyPreset(value)
            end
        end,
        width = "full",
        order = order
    }
    order = order + 1
    
    -- Apply preset button
    args.applyPreset = {
        type = "execute",
        name = "Apply Selected Preset",
        desc = "Apply the selected debug preset configuration",
        func = function()
            -- This would get the selected preset and apply it
            DebugService:User("Preset application not implemented yet")
        end,
        order = order
    }
    order = order + 1
    
    -- Save current as preset
    args.savePreset = {
        type = "group",
        name = "Save Current Configuration",
        order = order,
        args = {
            presetName = {
                type = "input",
                name = "Preset Name",
                desc = "Enter a name for your custom preset",
                get = function() return "" end,
                set = function(_, value)
                    if value and value ~= "" then
                        self:SaveCurrentAsPreset(value)
                    end
                end,
                order = 1
            },
            
            saveButton = {
                type = "execute",
                name = "Save Preset",
                func = function()
                    -- Implementation for saving preset
                    DebugService:User("Save preset not implemented yet")
                end,
                order = 2
            }
        }
    }
    
    return args
end

function DebugUI:CreateStatisticsArgs()
    return {
        currentStats = {
            type = "group",
            name = "Current Statistics",
            order = 1,
            args = {
                statsDisplay = {
                    type = "description",
                    name = function()
                        local stats = DebugService:GetStatistics()
                        return string.format(
                            "Total Messages: %d\n" ..
                            "  Errors: %d\n" ..
                            "  User Messages: %d\n" ..
                            "  Dev Messages: %d\n" ..
                            "  Trace Messages: %d\n" ..
                            "Enabled Categories: %d/%d\n" ..
                            "Memory Usage: %s KB\n" ..
                            "Uptime: %s",
                            stats.totalMessages,
                            stats.errorCount,
                            stats.userCount,
                            stats.devCount,
                            stats.traceCount,
                            stats.enabledCategories,
                            stats.totalCategories,
                            tostring(stats.memoryUsage),
                            self:FormatUptime(stats.uptime)
                        )
                    end,
                    fontSize = "medium",
                    order = 1
                },
                
                resetStats = {
                    type = "execute",
                    name = "Reset Statistics",
                    desc = "Reset all debug statistics counters",
                    func = function()
                        DebugService:ResetStatistics()
                        self:RefreshOptions()
                    end,
                    order = 2
                }
            }
        }
    }
end

-- Helper functions
function DebugUI:FormatUptime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function DebugUI:RefreshOptions()
    local reg = LibStub("AceConfigRegistry-3.0", true)
    if reg then
        reg:NotifyChange("NextKey")
    end
end

function DebugUI:ApplyPreset(presetName)
    -- Implementation for applying presets
    DebugService:User("Applying preset:", presetName)
    -- This would load the preset configuration and apply it
end

function DebugUI:SaveCurrentAsPreset(presetName)
    -- Implementation for saving current configuration as preset
    DebugService:User("Saving current configuration as preset:", presetName)
    -- This would save the current debug configuration
end

-- Register module
NextKey222.DebugUI = DebugUI
NextKey222.RegisterModule("DebugUI", DebugUI)

return DebugUI
```

## Enhanced Options Integration

### Modified options/main.lua

```lua
-- Add to options/main.lua in the SetupOptions function

function addon:SetupOptions()
    local options = {
        name = "NextKey",
        type = "group",
        args = {
            -- ... existing args ...
            
            -- Add debug section
            debug = {
                type = "group",
                name = "Debug System",
                order = 99,
                args = NextKey222.DebugUI:CreateDebugOptions()
            }
        }
    }
    
    -- ... rest of existing SetupOptions function ...
end
```

## Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Enhance `core/debugService.lua` with group management functions
- [ ] Create `core/debugUI.lua` module with basic UI structure
- [ ] Integrate debug UI into main options panel
- [ ] Implement basic group enable/disable functionality

### Phase 2: UI Enhancement
- [ ] Add visual status indicators for groups and categories
- [ ] Implement output formatting options
- [ ] Add basic statistics display
- [ ] Create preset management system

### Phase 3: Advanced Features
- [ ] Add real-time statistics monitoring
- [ ] Implement custom preset saving/loading
- [ ] Add performance monitoring features
- [ ] Create export/import functionality

### Phase 4: Polish and Optimization
- [ ] Optimize UI refresh performance
- [ ] Add keyboard navigation support
- [ ] Implement accessibility features
- [ ] Add comprehensive error handling

## Testing Strategy

### Unit Testing
- Test all new DebugService functions
- Verify group operations work correctly
- Test preset application and saving
- Validate statistics accuracy

### Integration Testing
- Test UI integration with existing options system
- Verify backward compatibility with slash commands
- Test settings persistence and migration
- Validate performance impact

### User Acceptance Testing
- Test with various debug configurations
- Validate UI usability and intuitiveness
- Test preset functionality with real scenarios
- Gather feedback from power users

## Performance Considerations

### Lazy Loading
- Load debug UI only when accessed
- Load statistics data on demand
- Cache frequently accessed data

### Efficient Updates
- Batch UI updates when multiple settings change
- Throttle statistics refresh to avoid excessive updates
- Use efficient data structures for category management

### Memory Management
- Clean up unused UI elements
- Limit statistics history size
- Properly dispose of resources when UI is closed

This specification provides a comprehensive roadmap for implementing the enhanced debug system while maintaining compatibility with existing functionality and ensuring optimal performance.