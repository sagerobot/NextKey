-- ==============================================================================
-- NextKey Debug UI Module - Professional Debug Interface
-- ==============================================================================
-- Provides a comprehensive UI for managing debug settings with grouped categories,
-- visual feedback, and advanced controls.
-- ==============================================================================

local _, NextKey222 = ...
local DebugService = NextKey222.Debug
local AceGUI = LibStub("AceGUI-3.0")

local DebugUI = {}

-- Use the same DEBUG_CATEGORY_GROUPS from DebugService
local DEBUG_CATEGORY_GROUPS = DebugService:GetCategoryGroups()

-- Track expanded/collapsed state for each group
DebugUI.expandedGroups = {}

-- Live update timer for statistics
DebugUI.updateTimer = nil
DebugUI.updateInterval = 1.0  -- Update every 1 second

-- Debug presets (make accessible for testing)
DebugUI.DEBUG_PRESETS = {
    ["minimal"] = {
        description = "Minimal debugging - errors only",
        level = 1, -- ERROR only
        groups = {},
        categories = {}
    },
    ["standard"] = {
        description = "Standard debugging - errors and user messages",
        level = 2, -- ERROR + USER
        groups = {},
        categories = {}
    },
    ["verbose"] = {
        description = "Verbose debugging - errors, user, and dev messages",
        level = 3, -- ERROR + USER + DEV
        groups = {},
        categories = {}
    },
    ["full"] = {
        description = "Full debugging - all message types",
        level = 4, -- ERROR + USER + DEV + TRACE
        groups = {},
        categories = {}
    }
}

-- Local reference for easier access
local DEBUG_PRESETS = DebugUI.DEBUG_PRESETS

-- Helper function to format uptime
function DebugUI:FormatUptime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Helper function to refresh options UI
function DebugUI:RefreshOptions()
    local reg = LibStub("AceConfigRegistry-3.0", true)
    if reg then
        reg:NotifyChange("NextKey")
    end
end

-- Start live statistics updates
function DebugUI:StartLiveUpdates()
    if self.updateTimer then
        return  -- Already running
    end
    
    self.updateTimer = C_Timer.NewTicker(self.updateInterval, function()
        -- Only refresh if the debug panel is actually open
        local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
        if AceConfigDialog and AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["NextKey"] then
            self:RefreshOptions()
        else
            -- Panel is closed, stop the timer
            self:StopLiveUpdates()
        end
    end)
end

-- Stop live statistics updates
function DebugUI:StopLiveUpdates()
    if self.updateTimer then
        self.updateTimer:Cancel()
        self.updateTimer = nil
    end
end

-- Helper function to create pattern args dynamically
function DebugUI:CreatePatternArgs()
    local patternArgs = {}
    local stats = DebugService:GetFilteringStats()
    local order = 1

    if #stats.patterns == 0 then
        patternArgs.noPatterns = {
            type = "description",
            name = "|cFF888888No filter patterns defined|r\nAdd a pattern above to start filtering messages.",
            fontSize = "small",
            order = order
        }
    else
        for _, pattern in ipairs(stats.patterns) do
            local key = "pattern_" .. string.gsub(pattern.name, "[^a-zA-Z0-9_]", "_")
            
            patternArgs[key .. "_header"] = {
                type = "header",
                name = pattern.name,
                order = order
            }
            order = order + 1

            patternArgs[key .. "_info"] = {
                type = "description",
                name = string.format(
                    "Type: |cFF00FFFF%s|r\n" ..
                    "Pattern: |cFFFFFF00%s|r\n" ..
                    "Matches: %d | Last Match: %s",
                    pattern.type,
                    pattern.pattern,
                    pattern.matchCount,
                    pattern.lastMatch and date("%H:%M:%S", pattern.lastMatch) or "Never"
                ),
                fontSize = "small",
                order = order
            }
            order = order + 1

            patternArgs[key .. "_toggle"] = {
                type = "toggle",
                name = "Enabled",
                get = function() return pattern.enabled end,
                set = function(_, value)
                    DebugService:ToggleFilterPattern(pattern.name, value)
                    self:RefreshOptions()
                end,
                order = order
            }
            order = order + 1

            patternArgs[key .. "_remove"] = {
                type = "execute",
                name = "|TInterface\\ICONS\\INV_Misc_Dust_02:16|t Remove",
                confirm = true,
                confirmText = "Remove filter pattern: " .. pattern.name,
                func = function()
                    DebugService:RemoveFilterPattern(pattern.name)
                    self:RefreshOptions()
                end,
                order = order
            }
            order = order + 1
        end
    end

    return patternArgs
end

-- Create the main debug options structure with tabs
function DebugUI:CreateDebugOptions()
    local tabs = {}
    
    -- Main tab
    tabs.main = {
        type = "group",
        name = "Main",
        order = 1,
        args = self:CreateMainTabArgs()
    }
    
    -- Category group tabs (always create them, but hide when disabled)
    local debugGroups = DebugService:GetCategoryGroups()
    local sortedGroups = {}
    for groupName, groupData in pairs(debugGroups) do
        table.insert(sortedGroups, {name = groupName, data = groupData})
    end
    table.sort(sortedGroups, function(a, b) return a.data.order < b.data.order end)
    
    for _, group in ipairs(sortedGroups) do
        local groupName = group.name
        local groupData = group.data
        
        tabs[groupName] = {
            type = "group",
            name = groupName,
            desc = groupData.description,
            order = groupData.order + 1,
            hidden = function() return not DebugService.enabled end,
            args = self:CreateCategoryGroupTabArgs(groupName, groupData)
        }
    end
    
    return {
        type = "group",
        name = "Debug System",
        order = 99,
        childGroups = "tab",
        args = tabs
    }
end

-- Create main tab arguments
function DebugUI:CreateMainTabArgs()
    local args = {}
    
    -- Master controls (on same line)
    args.enabled = {
        type = "toggle",
        name = "Enable Debug Mode",
        desc = "Master toggle for the entire debug system",
        get = function() return DebugService.enabled end,
        set = function(_, value)
            DebugService:SetEnabled(value)
            self:RefreshOptions()
        end,
        width = "normal",
        order = 1
    }

    -- All other controls (hide when debug mode is disabled)
    args.level = {
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
        width = "double",
        hidden = function() return not DebugService.enabled end,
        order = 2
    }
    
    -- Message when disabled
    args.disabledMessage = {
        type = "description",
        name = "|cFF888888Enable debug mode to access debug settings and tools.|r",
        fontSize = "medium",
        hidden = function() return DebugService.enabled end,
        order = 2
    }
    
    -- Quick actions
    args.quickActionsHeader = {
        type = "header",
        name = "Quick Actions",
        hidden = function() return not DebugService.enabled end,
        order = 10
    }
    
    args.quickActionsDesc = {
        type = "description",
        name = "Use these quick toggles to enable or disable entire category groups at once. For fine-grained control over individual categories within each group, use the category-specific tabs above.",
        fontSize = "small",
        hidden = function() return not DebugService.enabled end,
        order = 11
    }
    
    -- Enable/Disable All master toggle
    args.toggleAllCategories = {
        type = "toggle",
        name = "Enable All Categories",
        desc = "Master toggle - enable or disable all debug categories at once",
        width = "full",
        hidden = function() return not DebugService.enabled end,
        get = function()
            -- Check if all categories are enabled
            local allEnabled = true
            for _, enabled in pairs(DebugService.categories) do
                if not enabled then
                    allEnabled = false
                    break
                end
            end
            return allEnabled
        end,
        set = function(_, value)
            for category, _ in pairs(DebugService.categories) do
                DebugService.categories[category] = value
                if NextKey222.Addon and NextKey222.Addon.db then
                    NextKey222.Addon.db.global.debug.categories[category] = value
                end
            end
            self:RefreshOptions()
        end,
        order = 12
    }
    
    -- Individual group toggles
    local debugGroups = DebugService:GetCategoryGroups()
    local sortedGroups = {}
    for groupName, groupData in pairs(debugGroups) do
        table.insert(sortedGroups, {name = groupName, data = groupData})
    end
    table.sort(sortedGroups, function(a, b) return a.data.order < b.data.order end)
    
    local groupOrder = 13
    for _, group in ipairs(sortedGroups) do
        local groupName = group.name
        local groupData = group.data
        
        args["toggle_" .. groupName] = {
            type = "toggle",
            name = groupName,
            desc = groupData.description,
            width = "full",
            hidden = function() return not DebugService.enabled end,
            get = function()
                local enabled, _, _ = DebugService:GetGroupStatus(groupName)
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
            order = groupOrder
        }
        groupOrder = groupOrder + 1
    end
    
    -- Simple status (after Quick Actions, so order starts at 30)
    -- Always show status, even when debug mode is off
    args.statusHeader = {
        type = "header",
        name = "Current Status",
        order = 30
    }
    
    args.statusDisplay = {
        type = "description",
        name = function()
            local stats = DebugService:GetStatistics()
            local levelIcon = DebugService.enabled and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t" or "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:16|t"
            
            -- Show categories count only when debug mode is ON
            if DebugService.enabled then
                return string.format(
                    "%s Debug %s | %d/%d categories enabled | %d messages logged",
                    levelIcon,
                    "|cFF00FF00ON|r",
                    stats.enabledCategories,
                    stats.totalCategories,
                    stats.totalMessages
                )
            else
                return string.format(
                    "%s Debug %s | %d messages logged",
                    levelIcon,
                    "|cFFFF4444OFF|r",
                    stats.totalMessages
                )
            end
        end,
        fontSize = "medium",
        order = 31
    }
    
    -- Statistics section - always show
    args.statisticsHeader = {
        type = "header",
        name = "Debug Statistics",
        order = 40
    }
    
    local statsArgs = self:CreateSimplifiedStatisticsArgs()
    for k, v in pairs(statsArgs) do
        v.order = v.order + 40
        -- Don't hide statistics when debug mode is off
        args[k] = v
    end
    
    return args
end

-- Create individual category group tab
function DebugUI:CreateCategoryGroupTabArgs(groupName, groupData)
    local args = {}
    
    -- Toggle All checkbox for this group
    args.toggleAll = {
        type = "toggle",
        name = "Enable All " .. groupName,
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
        order = 1
    }
    
    args.separator = {
        type = "header",
        name = "Individual Categories",
        order = 2
    }
    
    -- Individual category toggles
    local catOrder = 3
    for categoryName, categoryData in pairs(groupData.categories) do
        args[categoryName] = {
            type = "toggle",
            name = categoryData.name .. " |cFF888888[" .. categoryName .. "]|r",
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
            order = catOrder
        }
        catOrder = catOrder + 1
    end
    
    return args
end

-- Create category tabs (one tab per group)
function DebugUI:CreateCategoryTabsArgs()
    local tabArgs = {}
    local debugGroups = DebugService:GetCategoryGroups()
    local sortedGroups = {}
    for groupName, groupData in pairs(debugGroups) do
        table.insert(sortedGroups, {name = groupName, data = groupData})
    end
    table.sort(sortedGroups, function(a, b) return a.data.order < b.data.order end)
    
    for _, group in ipairs(sortedGroups) do
        local groupName = group.name
        local groupData = group.data
        
        local categoryArgs = {}
        local catOrder = 1
        
        -- Add individual category toggles for this group
        for categoryName, categoryData in pairs(groupData.categories) do
            categoryArgs[categoryName] = {
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
                order = catOrder
            }
            catOrder = catOrder + 1
        end
        
        tabArgs[groupName] = {
            type = "group",
            name = groupName,
            desc = groupData.description,
            order = groupData.order,
            args = categoryArgs
        }
    end
    
    return tabArgs
end


-- Create category groups arguments
function DebugUI:CreateCategoryGroupsArgs()
    local args = {}
    local order = 1

    -- Get groups from DebugService
    local debugGroups = DEBUG_CATEGORY_GROUPS or DebugService:GetCategoryGroups()
    
    -- Sort groups by order
    local sortedGroups = {}
    for groupName, groupData in pairs(debugGroups) do
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

        -- Group status with visual indicators
        args[groupName .. "_status"] = {
            type = "description",
            name = function()
                local enabled, enabledCount, totalCount = DebugService:GetGroupStatus(groupName)
                local statusIcon = enabled and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:12|t" or "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:12|t"
                local statusColor = enabled and "|cFF00FF00" or "|cFFFF4444"
                local statusText = enabled and "Enabled" or "Disabled"
                return string.format("%s %s%s|r (%d/%d categories)", statusIcon, statusColor, statusText, enabledCount, totalCount)
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
                name = categoryData.name .. " |cFF888888[" .. categoryName .. "]|r",
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
                order = order
            }
            order = order + 1
        end
    end

    return args
end

-- Create output options arguments
function DebugUI:CreateOutputOptionsArgs()
    return {
        formatting = {
            type = "group",
            name = "Message Formatting",
            order = 1,
            args = {
                timestamps = {
                    type = "toggle",
                    name = "|TInterface\\ICONS\\INV_Misc_PocketWatch_01:16|t Show Timestamps",
                    desc = "Include timestamps in debug messages for better timing analysis",
                    get = function()
                        return DebugService.db and DebugService.db.global and DebugService.db.global.debug and
                               DebugService.db.global.debug.formatting and
                               DebugService.db.global.debug.formatting.timestamps or false
                    end,
                    set = function(_, value)
                        if not DebugService.db then return end
                        DebugService.db.global.debug = DebugService.db.global.debug or {}
                        DebugService.db.global.debug.formatting = DebugService.db.global.debug.formatting or {}
                        DebugService.db.global.debug.formatting.timestamps = value
                        DebugService:User("Timestamp display", value and "enabled" or "disabled")
                    end,
                    width = "full",
                    order = 1
                },

                sourceLocation = {
                    type = "toggle",
                    name = "|TInterface\\ICONS\\INV_Misc_Book_09:16|t Show Source Location",
                    desc = "Include file and line number in debug messages for precise code location",
                    get = function()
                        return DebugService.db and DebugService.db.global and DebugService.db.global.debug and
                               DebugService.db.global.debug.formatting and
                               DebugService.db.global.debug.formatting.sourceLocation or false
                    end,
                    set = function(_, value)
                        if not DebugService.db then return end
                        DebugService.db.global.debug = DebugService.db.global.debug or {}
                        DebugService.db.global.debug.formatting = DebugService.db.global.debug.formatting or {}
                        DebugService.db.global.debug.formatting.sourceLocation = value
                        DebugService:User("Source location display", value and "enabled" or "disabled")
                    end,
                    width = "full",
                    order = 2
                },

                stackTraces = {
                    type = "toggle",
                    name = "|TInterface\\ICONS\\INV_Misc_Scroll_02:16|t Show Stack Traces",
                    desc = "Include detailed stack traces for error messages (can be verbose)",
                    get = function()
                        return DebugService.db and DebugService.db.global and DebugService.db.global.debug and
                               DebugService.db.global.debug.formatting and
                               DebugService.db.global.debug.formatting.stackTraces or false
                    end,
                    set = function(_, value)
                        if not DebugService.db then return end
                        DebugService.db.global.debug = DebugService.db.global.debug or {}
                        DebugService.db.global.debug.formatting = DebugService.db.global.debug.formatting or {}
                        DebugService.db.global.debug.formatting.stackTraces = value
                        DebugService:User("Stack trace display", value and "enabled" or "disabled")
                    end,
                    width = "full",
                    order = 3
                },

                colorCoding = {
                    type = "toggle",
                    name = "|TInterface\\ICONS\\INV_Inscription_InkPurple01:16|t Enhanced Color Coding",
                    desc = "Use enhanced colors and formatting for different debug levels",
                    get = function()
                        return DebugService.db and DebugService.db.global and DebugService.db.global.debug and
                               DebugService.db.global.debug.formatting and
                               DebugService.db.global.debug.formatting.colorCoding or true
                    end,
                    set = function(_, value)
                        if not DebugService.db then return end
                        DebugService.db.global.debug = DebugService.db.global.debug or {}
                        DebugService.db.global.debug.formatting = DebugService.db.global.debug.formatting or {}
                        DebugService.db.global.debug.formatting.colorCoding = value
                        DebugService:User("Enhanced color coding", value and "enabled" or "disabled")
                    end,
                    width = "full",
                    order = 4
                }
            }
        },

    }
end

-- Create presets arguments
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
            ["full"] = "Full (ERROR + USER + DEV + TRACE)"
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
        name = "|TInterface\\ICONS\\INV_Misc_Wrench_01:16|t Apply Selected Preset",
        desc = "Apply the selected debug preset configuration",
        func = function()
            -- Get the selected preset from the dropdown
            local selectedPreset = args.presetSelector.get()
            if selectedPreset and selectedPreset ~= "" then
                self:ApplyPreset(selectedPreset)
            else
                DebugService:User("Please select a preset first")
            end
        end,
        order = order
    }
    order = order + 1

    -- Save current as preset
    args.savePreset = {
        type = "group",
        name = "|TInterface\\ICONS\\INV_Inscription_ScrollOfWisdom_01:16|t Save Current Configuration",
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
                name = "|TInterface\\ICONS\\INV_Misc_StoneTablet_02:16|t Save Preset",
                desc = "Save the current debug configuration as a reusable preset",
                func = function()
                    -- Implementation for saving preset
                    DebugService:User("|TInterface\\ICONS\\INV_Misc_QuestionMark:12|t Save preset feature coming soon!")
                end,
                order = 2
            },

            presetDescription = {
                type = "input",
                name = "Description (Optional)",
                desc = "Optional description for your preset",
                multiline = true,
                width = "full",
                get = function() return "" end,
                set = function(_, value)
                    -- Store description for saving
                    self.pendingPresetDescription = value
                end,
                order = 3
            }
        }
    }

    return args
end

-- Create simplified statistics arguments (no nested groups)
function DebugUI:CreateSimplifiedStatisticsArgs()
    return {
        statsDisplay = {
            type = "description",
            name = function()
                local stats = DebugService:GetStatistics()
                local memoryIcon = "|TInterface\\ICONS\\INV_Misc_Coin_01:12|t"
                local uptimeIcon = "|TInterface\\ICONS\\INV_Misc_PocketWatch_01:12|t"
                local messageIcon = "|TInterface\\ICONS\\INV_Inscription_Scroll:12|t"
                local categoryIcon = "|TInterface\\ICONS\\INV_Misc_Book_09:12|t"
                
                -- Convert KB to MB for easier reading
                local memoryKB = stats.memoryUsage
                local memoryMB = memoryKB / 1024
                
                -- Determine memory status color based on expected ranges
                -- Expected: Baseline <10MB (~10,240 KB), Peak <50MB (~51,200 KB)
                local memoryColor
                if memoryKB < 10240 then
                    memoryColor = "|cFF00FF00"  -- Green: Good (baseline)
                elseif memoryKB < 51200 then
                    memoryColor = "|cFFFFFF00"  -- Yellow: Normal (peak usage)
                else
                    memoryColor = "|cFFFF4444"  -- Red: High (investigate)
                end

                return string.format(
                    "%s |cFF00FF00Total Messages: %d|r\n" ..
                    "  |cFFFF4444Errors: %d|r |cFFFFFF00User: %d|r |cFF888888Dev: %d|r |cFF444444Trace: %d|r\n" ..
                    "%s |cFF00FFFFEnabled Categories: %d/%d|r\n" ..
                    "%s %sMemory Usage: %.1f MB|r |cFF888888(%.0f KB)|r\n" ..
                    "%s |cFFFFA500Uptime: %s|r",
                    messageIcon, stats.totalMessages,
                    stats.errorCount, stats.userCount, stats.devCount, stats.traceCount,
                    categoryIcon, stats.enabledCategories, stats.totalCategories,
                    memoryIcon, memoryColor, memoryMB, memoryKB,
                    uptimeIcon, self:FormatUptime(stats.uptime)
                )
            end,
            fontSize = "medium",
            order = 1
        },
        
        memoryInfo = {
            type = "description",
            name = "|cFF888888Expected Memory Usage: Baseline <10 MB, Peak <50 MB during heavy usage|r",
            fontSize = "small",
            order = 1.5
        },

        performanceMetrics = {
            type = "description",
            name = function()
                local stats = DebugService:GetStatistics()
                local avgMsgPerMin = stats.uptime > 0 and (stats.totalMessages / (stats.uptime / 60)) or 0
                local memoryPerMsg = stats.totalMessages > 0 and (stats.memoryUsage / stats.totalMessages) or 0

                return string.format(
                    "|TInterface\\ICONS\\SPELL_HOLY_BORROWEDTIME:12|t |cFFFFFF00Performance Metrics|r\n" ..
                    "Messages/Minute: %.1f\n" ..
                    "Memory/Message: %.2f KB\n" ..
                    "Active Groups: %d/6",
                    avgMsgPerMin,
                    memoryPerMsg,
                    self:GetActiveGroupCount()
                )
            end,
            fontSize = "small",
            order = 2
        },

        resetStats = {
            type = "execute",
            name = "|TInterface\\ICONS\\INV_Misc_Dust_02:16|t Reset Statistics",
            desc = "Reset all debug statistics counters to zero",
            func = function()
                -- Reset basic statistics
                DebugService.stats.errorCount = 0
                DebugService.stats.userCount = 0
                DebugService.stats.devCount = 0
                DebugService.stats.traceCount = 0
                DebugService.stats.totalMessages = 0
                DebugService.stats.uptime = GetTime()
                self:RefreshOptions()
                DebugService:User("Debug statistics have been reset")
            end,
            order = 3
        }
    }
end

-- Helper function to count active groups
function DebugUI:GetActiveGroupCount()
    local count = 0
    local debugGroups = DEBUG_CATEGORY_GROUPS or DebugService:GetCategoryGroups()
    for groupName, _ in pairs(debugGroups) do
        local enabled = DebugService:GetGroupStatus(groupName)
        if enabled then
            count = count + 1
        end
    end
    return count
end

-- Apply a preset configuration
function DebugUI:ApplyPreset(presetName)
    local preset = DEBUG_PRESETS[presetName]
    if not preset then
        DebugService:Error("Unknown preset:", presetName)
        return
    end

    -- Apply level
    if preset.level then
        DebugService:SetLevel(preset.level)
    end

    -- Apply groups
    if preset.groups then
        for groupName, enabled in pairs(preset.groups) do
            if enabled then
                DebugService:EnableGroup(groupName)
            else
                DebugService:DisableGroup(groupName)
            end
        end
    end

    -- Apply individual categories
    if preset.categories then
        for categoryName, enabled in pairs(preset.categories) do
            if enabled then
                DebugService:EnableCategory(categoryName)
            else
                DebugService:DisableCategory(categoryName)
            end
        end
    end

    DebugService:User("|TInterface\\ICONS\\INV_Misc_Wrench_01:16|t Applied preset: |cFFFFFF00" .. presetName .. "|r - " .. preset.description)
    self:RefreshOptions()
end

-- Save current configuration as a preset
function DebugUI:SaveCurrentAsPreset(presetName)
    -- Implementation for saving custom presets
    local description = self.pendingPresetDescription or ("Custom preset: " .. presetName)

    -- Create a new preset based on current settings
    local currentPreset = {
        description = description,
        level = DebugService.level,
        groups = {},
        categories = {}
    }

    -- Get groups from DebugService
    local debugGroups = DEBUG_CATEGORY_GROUPS or DebugService:GetCategoryGroups()
    
    -- Capture current group states
    for groupName, _ in pairs(debugGroups) do
        local enabled = DebugService:GetGroupStatus(groupName)
        if enabled then
            currentPreset.groups[groupName] = true
        end
    end

    -- Capture individual category states that differ from group defaults
    for categoryName, enabled in pairs(DebugService.categories) do
        local groupName = DebugService:GetCategoryGroup(categoryName)
        local groupEnabled = groupName and DebugService:GetGroupStatus(groupName) or false

        -- Only save if it differs from the group setting
        if enabled ~= groupEnabled then
            currentPreset.categories[categoryName] = enabled
        end
    end

    -- Add to presets table
    DEBUG_PRESETS[presetName] = currentPreset

    DebugService:User("|TInterface\\ICONS\\INV_Misc_StoneTablet_02:16|t Saved preset: |cFFFFFF00" .. presetName .. "|r")
    self.pendingPresetDescription = nil

    -- Refresh options to show the new preset in dropdown
    self:RefreshOptions()
end

-- Force rebuild of Debug System options (used when toggling debug mode)
function DebugUI:RebuildDebugOptions()
    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
    if not AceConfigRegistry then return end
    
    -- Get the current NextKey options table
    local options = AceConfigRegistry:GetOptionsTable("NextKey")
    if not options or not options.args then return end
    
    -- Recreate the debug system options
    options.args.debugSystem = self:CreateDebugOptions()
    
    -- Also handle developer tools injection
    local debugOptions = options.args.debugSystem
    if debugOptions.args and debugOptions.args.main and debugOptions.args.main.args then
        if DebugService and DebugService.enabled then
            -- Import create_developer_tools_group from options/main.lua scope
            if NextKey222.Addon and NextKey222.Addon.CreateDeveloperToolsGroup then
                local devTools = NextKey222.Addon:CreateDeveloperToolsGroup()
                if devTools and devTools.args then
                    -- Add developer tools section to Main tab
                    debugOptions.args.main.args.devToolsHeader = {
                        type = "header",
                        name = "Developer Tools",
                        order = 100
                    }
                    
                    -- Merge all developer tool items (except the duplicate Enable Debug Mode toggle)
                    for k, v in pairs(devTools.args) do
                        -- Skip the header and enable_debug_mode toggle (duplicate of main tab's toggle)
                        if k ~= "header" and k ~= "enable_debug_mode" then
                            v.order = (v.order or 0) + 100
                            debugOptions.args.main.args[k] = v
                        end
                    end
                end
            end
        end
    end
    
    -- Notify AceConfig that the options table changed
    AceConfigRegistry:NotifyChange("NextKey")
    
    -- Start live updates when the debug panel is opened
    self:StartLiveUpdates()
end

-- Register module
NextKey222.DebugUI = DebugUI

-- Register with module system if available, otherwise just assign
if NextKey222.RegisterModule then
    NextKey222.RegisterModule("DebugUI", DebugUI)
end

-- Initialize DEBUG_CATEGORY_GROUPS after DebugService is available
function DebugUI:InitializeAfterLoad()
    if not DEBUG_CATEGORY_GROUPS then
        DEBUG_CATEGORY_GROUPS = DebugService:GetCategoryGroups()
    end
end

return DebugUI