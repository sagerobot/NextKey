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

-- Debug presets (make accessible for testing)
DebugUI.DEBUG_PRESETS = {
local DEBUG_PRESETS = DebugUI.DEBUG_PRESETS
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
    },
    ["ui_testing"] = {
        description = "UI testing - focus on interface debugging",
        level = 3,
        groups = { ["Features & UI"] = true },
        categories = {}
    },
    ["communications_testing"] = {
        description = "Communications testing - focus on network debugging",
        level = 3,
        groups = { ["Communications"] = true },
        categories = {}
    },
    ["performance_testing"] = {
        description = "Performance testing - focus on performance monitoring",
        level = 3,
        groups = { ["Core Systems"] = true },
        categories = { performance = true }
    }
}

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

-- Create the main debug options structure
function DebugUI:CreateDebugOptions()
    return {
        type = "group",
        name = "Debug System",
        order = 99,
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

-- Create control panel arguments
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
                local levelIcon = DebugService.enabled and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16|t" or "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:16|t"
                local levelColor = DebugService.enabled and "|cFF00FF00" or "|cFFFF4444"

                return string.format(
                    "%s %sLevel: %s|r\n" ..
                    "|TInterface\\ICONS\\INV_Misc_Book_09:12|t Enabled Categories: %d/%d\n" ..
                    "|TInterface\\ICONS\\INV_Inscription_Scroll:12|t Total Messages: %d\n" ..
                    "|TInterface\\ICONS\\INV_Misc_PocketWatch_01:12|t Uptime: %s",
                    levelIcon,
                    levelColor,
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

        basicFiltering = {
            type = "group",
            name = "Basic Output Filtering",
            order = 2,
            args = {
                destination = {
                    type = "select",
                    name = "|TInterface\\ICONS\\INV_Letter_17:16|t Output Destination",
                    desc = "Where debug messages should be displayed",
                    values = {
                        chat = "|TInterface\\ICONS\\INV_Letter_17:12|t Chat Frame",
                        dedicated = "|TInterface\\ICONS\\INV_Misc_Book_08:12|t Dedicated Debug Frame",
                        both = "|TInterface\\ICONS\\INV_Misc_Book_09:12|t Both Chat and Debug Frame"
                    },
                    get = function()
                        return DebugService.db and DebugService.db.global and DebugService.db.global.debug and
                               DebugService.db.global.debug.filtering and
                               DebugService.db.global.debug.filtering.destination or "chat"
                    end,
                    set = function(_, value)
                        if not DebugService.db then return end
                        DebugService.db.global.debug = DebugService.db.global.debug or {}
                        DebugService.db.global.debug.filtering = DebugService.db.global.debug.filtering or {}
                        DebugService.db.global.debug.filtering.destination = value
                        DebugService:User("Output destination set to:", value)
                    end,
                    width = "full",
                    order = 1
                },

                throttling = {
                    type = "range",
                    name = "|TInterface\\ICONS\\SPELL_HOLY_BORROWEDTIME:16|t Message Throttling",
                    desc = "Maximum messages per second (0 = no limit, higher values reduce spam)",
                    min = 0,
                    max = 100,
                    step = 1,
                    get = function()
                        return DebugService.db and DebugService.db.global and DebugService.db.global.debug and
                               DebugService.db.global.debug.filtering and
                               DebugService.db.global.debug.filtering.throttling or 0
                    end,
                    set = function(_, value)
                        if not DebugService.db then return end
                        DebugService.db.global.debug = DebugService.db.global.debug or {}
                        DebugService.db.global.debug.filtering = DebugService.db.global.debug.filtering or {}
                        DebugService.db.global.debug.filtering.throttling = value
                        if value > 0 then
                            DebugService:User("Message throttling set to", value, "messages/second")
                        else
                            DebugService:User("Message throttling disabled")
                        end
                    end,
                    width = "full",
                    order = 2
                },

                autoScroll = {
                    type = "toggle",
                    name = "|TInterface\\ICONS\\INV_Misc_Scroll_04:16|t Auto-Scroll Debug Frame",
                    desc = "Automatically scroll to bottom of debug frame when new messages arrive",
                    get = function()
                        return DebugService.db and DebugService.db.global and DebugService.db.global.debug and
                               DebugService.db.global.debug.filtering and
                               DebugService.db.global.debug.filtering.autoScroll or true
                    end,
                    set = function(_, value)
                        if not DebugService.db then return end
                        DebugService.db.global.debug = DebugService.db.global.debug or {}
                        DebugService.db.global.debug.filtering = DebugService.db.global.debug.filtering or {}
                        DebugService.db.global.debug.filtering.autoScroll = value
                        DebugService:User("Auto-scroll", value and "enabled" or "disabled")
                    end,
                    width = "full",
                    order = 3
                }
            }
        },

        advancedFiltering = {
            type = "group",
            name = "Advanced Message Filtering",
            order = 3,
            args = {
                filterToggle = {
                    type = "toggle",
                    name = "|TInterface\\ICONS\\INV_Misc_Filter_01:16|t Enable Advanced Filtering",
                    desc = "Enable sophisticated message filtering with patterns, time ranges, and more",
                    get = function() return DebugService.filtering and DebugService.filtering.enabled or false end,
                    set = function(_, value)
                        DebugService:EnableFiltering(value)
                        self:RefreshOptions()
                    end,
                    width = "full",
                    order = 1
                },

                filterStatus = {
                    type = "description",
                    name = function()
                        local stats = DebugService:GetFilteringStats()
                        local statusIcon = stats.enabled and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:12|t" or "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:12|t"
                        local statusColor = stats.enabled and "|cFF00FF00" or "|cFFFF4444"
                        local statusText = stats.enabled and "Active" or "Inactive"

                        return string.format(
                            "%s %s%s|r\n" ..
                            "|TInterface\\ICONS\\INV_Misc_Filter_01:12|t Filter Patterns: %d/%d enabled\n" ..
                            "|TInterface\\ICONS\\INV_Misc_Note_01:12|t Total Matches: %d\n" ..
                            "|TInterface\\ICONS\\INV_Misc_Book_09:12|t Message Buffer: %d/%d",
                            statusIcon, statusColor, statusText,
                            stats.enabledPatterns, stats.totalPatterns,
                            stats.totalMatches,
                            stats.bufferSize, DebugService.filtering and DebugService.filtering.bufferSize or 1000
                        )
                    end,
                    fontSize = "medium",
                    order = 2
                },

                patternFilters = {
                    type = "group",
                    name = "Pattern Filters",
                    order = 3,
                    args = {
                        addPattern = {
                            type = "group",
                            name = "|TInterface\\ICONS\\INV_Misc_Note_01:16|t Add Filter Pattern",
                            order = 1,
                            args = {
                                patternName = {
                                    type = "input",
                                    name = "Pattern Name",
                                    desc = "Unique name for this filter pattern",
                                    get = function() return "" end,
                                    set = function(_, value)
                                        self.pendingPatternName = value
                                    end,
                                    order = 1
                                },

                                patternText = {
                                    type = "input",
                                    name = "Pattern",
                                    desc = "The text, regex, or wildcard pattern to match",
                                    get = function() return "" end,
                                    set = function(_, value)
                                        self.pendingPatternText = value
                                    end,
                                    order = 2
                                },

                                patternType = {
                                    type = "select",
                                    name = "Pattern Type",
                                    desc = "Type of pattern matching to use",
                                    values = {
                                        ["text"] = "Text Match (case-insensitive)",
                                        ["regex"] = "Regular Expression",
                                        ["wildcard"] = "Wildcard (* for any characters)"
                                    },
                                    get = function() return "text" end,
                                    set = function(_, value)
                                        self.pendingPatternType = value
                                    end,
                                    order = 3
                                },

                                addPatternButton = {
                                    type = "execute",
                                    name = "|TInterface\\ICONS\\INV_Misc_StoneTablet_02:16|t Add Pattern",
                                    desc = "Add the new filter pattern",
                                    func = function()
                                        if self.pendingPatternName and self.pendingPatternText then
                                            local success = DebugService:AddFilterPattern(
                                                self.pendingPatternName,
                                                self.pendingPatternText,
                                                self.pendingPatternType or "text",
                                                true
                                            )
                                            if success then
                                                self.pendingPatternName = nil
                                                self.pendingPatternText = nil
                                                self.pendingPatternType = nil
                                                self:RefreshOptions()
                                            end
                                        else
                                            DebugService:User("Please enter both pattern name and pattern text")
                                        end
                                    end,
                                    order = 4
                                }
                            }
                        },

                        existingPatterns = {
                            type = "group",
                            name = "Existing Patterns",
                            order = 2,
                            args = self:CreatePatternArgs()
                        }
                    }
                },

                timeRangeFilter = {
                    type = "group",
                    name = "Time Range Filtering",
                    order = 4,
                    args = {
                        timeRangeEnabled = {
                            type = "toggle",
                            name = "|TInterface\\ICONS\\INV_Misc_PocketWatch_01:16|t Enable Time Range",
                            desc = "Only show debug messages within a specific time range",
                            get = function()
                                return DebugService.filtering and DebugService.filtering.timeRange and DebugService.filtering.timeRange.enabled or false
                            end,
                            set = function(_, value)
                                if value then
                                    -- Enable with current time as range
                                    local now = time()
                                    DebugService:SetTimeRangeFilter(now - 3600, now)  -- Last hour
                                else
                                    DebugService:SetTimeRangeFilter(nil, nil)
                                end
                                self:RefreshOptions()
                            end,
                            width = "full",
                            order = 1
                        },

                        timeRangeStatus = {
                            type = "description",
                            name = function()
                                local timeRange = DebugService.filtering and DebugService.filtering.timeRange or {}
                                if not timeRange.enabled then
                                    return "|cFF888888Time range filtering is disabled|r"
                                end

                                local startStr = date("%Y-%m-%d %H:%M:%S", timeRange.startTime)
                                local endStr = date("%Y-%m-%d %H:%M:%S", timeRange.endTime)
                                local duration = timeRange.endTime - timeRange.startTime

                                return string.format(
                                    "|cFF00FF00Time range active|r\n" ..
                                    "Start: %s\n" ..
                                    "End: %s\n" ..
                                    "Duration: %d minutes",
                                    startStr, endStr, math.floor(duration / 60)
                                )
                            end,
                            fontSize = "small",
                            order = 2
                        }
                    }
                },

                levelCategoryFilters = {
                    type = "group",
                    name = "Level & Category Filters",
                    order = 5,
                    args = {
                        levelFilters = {
                            type = "multiselect",
                            name = "|TInterface\\ICONS\\INV_Misc_Book_09:16|t Filter by Debug Level",
                            desc = "Select debug levels to filter out (disabled levels will not be shown)",
                            values = {
                                [1] = "ERROR (1) - Critical errors",
                                [2] = "USER (2) - User messages",
                                [3] = "DEV (3) - Development messages",
                                [4] = "TRACE (4) - Verbose tracing"
                            },
                            get = function(_, key)
                                return DebugService.filtering and DebugService.filtering.levelFilters and DebugService.filtering.levelFilters[key] == false
                            end,
                            set = function(_, key, value)
                                DebugService:SetLevelFilter(key, not value)  -- Invert because we're setting "filtered" state
                                self:RefreshOptions()
                            end,
                            order = 1
                        },

                        categoryFilters = {
                            type = "multiselect",
                            name = "|TInterface\\ICONS\\INV_Misc_Book_09:16|t Filter by Category",
                            desc = "Select categories to filter out (disabled categories will not be shown)",
                            values = function()
                                local values = {}
                                for category, _ in pairs(DebugService.categories) do
                                    local groupName = DebugService:GetCategoryGroup(category)
                                    local groupPrefix = groupName and "[" .. groupName .. "] " or ""
                                    values[category] = groupPrefix .. category
                                end
                                return values
                            end,
                            get = function(_, key)
                                return DebugService.filtering and DebugService.filtering.categoryFilters and DebugService.filtering.categoryFilters[key] == false
                            end,
                            set = function(_, key, value)
                                DebugService:SetCategoryFilter(key, not value)  -- Invert because we're setting "filtered" state
                                self:RefreshOptions()
                            end,
                            order = 2
                        }
                    }
                },

                exportFiltering = {
                    type = "execute",
                    name = "|TInterface\\ICONS\\INV_Inscription_ScrollOfWisdom_01:16|t Export Filtering Data",
                    desc = "Export filtering statistics and configuration for analysis",
                    func = function()
                        local filterData = DebugService:ExportFilteringData()
                        local exportText = string.format(
                            "NextKey Filtering Data Export\n" ..
                            "Timestamp: %s\n" ..
                            "Filtering Enabled: %s\n" ..
                            "Total Patterns: %d/%d enabled\n" ..
                            "Total Matches: %d\n" ..
                            "Buffer Size: %d\n" ..
                            "Time Range: %s",
                            filterData.timestamp,
                            filterData.stats.enabled and "Yes" or "No",
                            filterData.stats.enabledPatterns, filterData.stats.totalPatterns,
                            filterData.stats.totalMatches,
                            filterData.stats.bufferSize,
                            filterData.stats.timeRangeEnabled and "Enabled" or "Disabled"
                        )

                        -- Add pattern details
                        if #filterData.stats.patterns > 0 then
                            exportText = exportText .. "\n\nPatterns:"
                            for _, pattern in ipairs(filterData.stats.patterns) do
                                exportText = exportText .. string.format(
                                    "\n- %s (%s): %s - %d matches",
                                    pattern.name, pattern.type, pattern.pattern, pattern.matchCount
                                )
                            end
                        end

                        -- Copy to clipboard (if possible)
                        if _G.ChatEdit_InsertLink then
                            _G.ChatEdit_InsertLink(exportText)
                            DebugService:User("Filtering data copied to clipboard")
                        else
                            DebugService:User("Filtering data export: " .. exportText)
                        end
                    end,
                    order = 6
                }
            }
        }
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

-- Create statistics arguments
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
                        local memoryIcon = "|TInterface\\ICONS\\INV_Misc_Coin_01:12|t"
                        local uptimeIcon = "|TInterface\\ICONS\\INV_Misc_PocketWatch_01:12|t"
                        local messageIcon = "|TInterface\\ICONS\\INV_Inscription_Scroll:12|t"
                        local categoryIcon = "|TInterface\\ICONS\\INV_Misc_Book_09:12|t"

                        return string.format(
                            "%s |cFF00FF00Total Messages: %d|r\n" ..
                            "  |cFFFF4444Errors: %d|r |cFFFFFF00User: %d|r |cFF888888Dev: %d|r |cFF444444Trace: %d|r\n" ..
                            "%s |cFF00FFFFEnabled Categories: %d/%d|r\n" ..
                            "%s |cFFFFFF00Memory Usage: %s KB|r\n" ..
                            "%s |cFFFFA500Uptime: %s|r",
                            messageIcon, stats.totalMessages,
                            stats.errorCount, stats.userCount, stats.devCount, stats.traceCount,
                            categoryIcon, stats.enabledCategories, stats.totalCategories,
                            memoryIcon, tostring(stats.memoryUsage),
                            uptimeIcon, self:FormatUptime(stats.uptime)
                        )
                    end,
                    fontSize = "medium",
                    order = 1
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
                            "Active Groups: %d/5\n" ..
                            "Filter Efficiency: %.1f%%\n" ..
                            "Cache Efficiency: %.1f%%",
                            avgMsgPerMin,
                            memoryPerMsg,
                            self:GetActiveGroupCount(),
                            stats.performanceMetrics.filterEfficiency,
                            stats.performanceMetrics.cacheEfficiency
                        )
                    end,
                    fontSize = "small",
                    order = 2
                },

                optimizationTools = {
                    type = "group",
                    name = "Optimization Tools",
                    order = 3,
                    args = {
                        memoryBreakdown = {
                            type = "description",
                            name = function()
                                local breakdown = DebugService:GetMemoryBreakdown()
                                return string.format(
                                    "|TInterface\\ICONS\\INV_Misc_Coin_01:12|t |cFF00FFFFMemory Usage Breakdown|r\n" ..
                                    "Message Cache: %d entries\n" ..
                                    "Performance History: %d entries\n" ..
                                    "Filtering Buffer: %d entries\n" ..
                                    "Total: %d entries",
                                    breakdown.messageCache,
                                    breakdown.performanceHistory,
                                    breakdown.filteringBuffer,
                                    breakdown.total
                                )
                            end,
                            fontSize = "small",
                            order = 1
                        },

                        performMaintenance = {
                            type = "execute",
                            name = "|TInterface\\ICONS\\INV_Misc_Wrench_01:16|t Perform Maintenance",
                            desc = "Clean up caches and optimize memory usage",
                            func = function()
                                DebugService:PerformMaintenance()
                                self:RefreshOptions()
                                DebugService:User("Maintenance completed successfully")
                            end,
                            order = 2
                        },

                        optimizeForProduction = {
                            type = "execute",
                            name = "|TInterface\\ICONS\\INV_Misc_Gear_01:16|t Optimize for Production",
                            desc = "Disable all debug features for minimal performance impact",
                            confirm = true,
                            confirmText = "This will disable all debug features. Are you sure?",
                            func = function()
                                DebugService:OptimizeForProduction()
                                self:RefreshOptions()
                                DebugService:User("Debug system optimized for production use")
                            end,
                            order = 3
                        }
                    }
                },

                resetStats = {
                    type = "execute",
                    name = "|TInterface\\ICONS\\INV_Misc_Dust_02:16|t Reset Statistics",
                    desc = "Reset all debug statistics counters to zero",
                    func = function()
                        DebugService:ResetStatistics()
                        self:RefreshOptions()
                        DebugService:User("Debug statistics have been reset")
                    end,
                    order = 3
                },

                exportStats = {
                    type = "execute",
                    name = "|TInterface\\ICONS\\INV_Inscription_ScrollOfWisdom_01:16|t Export Statistics",
                    desc = "Copy current statistics to clipboard for analysis",
                    func = function()
                        local stats = DebugService:GetStatistics()
                        local exportText = string.format(
                            "NextKey Debug Statistics Export\n" ..
                            "Timestamp: %s\n" ..
                            "Uptime: %s\n" ..
                            "Total Messages: %d\n" ..
                            "  Errors: %d\n" ..
                            "  User: %d\n" ..
                            "  Dev: %d\n" ..
                            "  Trace: %d\n" ..
                            "Enabled Categories: %d/%d\n" ..
                            "Memory Usage: %s KB\n" ..
                            "Active Groups: %d/5",
                            date("%Y-%m-%d %H:%M:%S"),
                            self:FormatUptime(stats.uptime),
                            stats.totalMessages,
                            stats.errorCount, stats.userCount, stats.devCount, stats.traceCount,
                            stats.enabledCategories, stats.totalCategories,
                            tostring(stats.memoryUsage),
                            self:GetActiveGroupCount()
                        )

                        -- Copy to clipboard (if possible)
                        if _G.ChatEdit_InsertLink then
                            _G.ChatEdit_InsertLink(exportText)
                            DebugService:User("Statistics copied to clipboard")
                        else
                            DebugService:User("Statistics export: " .. exportText)
                        end
                    end,
                    order = 4
                }
            }
        },

        performanceMonitoring = {
            type = "group",
            name = "Performance Monitoring",
            order = 2,
            args = {
                performanceToggle = {
                    type = "toggle",
                    name = "|TInterface\\ICONS\\SPELL_HOLY_BORROWEDTIME:16|t Enable Performance Monitoring",
                    desc = "Track execution time of operations and identify performance bottlenecks",
                    get = function() return DebugService.performanceData and DebugService.performanceData.enabled or false end,
                    set = function(_, value)
                        DebugService:EnablePerformanceMonitoring(value)
                        self:RefreshOptions()
                    end,
                    width = "full",
                    order = 1
                },

                performanceStatus = {
                    type = "description",
                    name = function()
                        local perfStats = DebugService:GetPerformanceStats()
                        local statusIcon = perfStats.enabled and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:12|t" or "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:12|t"
                        local statusColor = perfStats.enabled and "|cFF00FF00" or "|cFFFF4444"
                        local statusText = perfStats.enabled and "Active" or "Inactive"

                        return string.format(
                            "%s %s%s|r\n" ..
                            "|TInterface\\ICONS\\INV_Misc_Clock_01:12|t Total Measurements: %d\n" ..
                            "|TInterface\\ICONS\\INV_Misc_Stopwatch_01:12|t Active Timers: %d\n" ..
                            "|TInterface\\ICONS\\INV_Misc_Gear_01:12|t Average Duration: %.3fms\n" ..
                            "|TInterface\\ICONS\\INV_Misc_Gear_02:12|t Max Duration: %.3fms",
                            statusIcon, statusColor, statusText,
                            perfStats.totalMeasurements,
                            perfStats.activeTimers,
                            perfStats.averageDuration,
                            perfStats.maxDuration
                        )
                    end,
                    fontSize = "medium",
                    order = 2
                },

                thresholdSettings = {
                    type = "group",
                    name = "Performance Thresholds",
                    order = 3,
                    args = {
                        warningThreshold = {
                            type = "range",
                            name = "|TInterface\\ICONS\\SPELL_HOLY_BORROWEDTIME:16|t Warning Threshold",
                            desc = "Execution time (in seconds) that triggers a performance warning",
                            min = 0.01,
                            max = 1.0,
                            step = 0.01,
                            isPercent = false,
                            get = function()
                                return DebugService.performanceData and DebugService.performanceData.thresholds and DebugService.performanceData.thresholds.warning or 0.1
                            end,
                            set = function(_, value)
                                local critical = DebugService.performanceData and DebugService.performanceData.thresholds and DebugService.performanceData.thresholds.critical or 0.5
                                DebugService:SetPerformanceThresholds(value, critical)
                                self:RefreshOptions()
                            end,
                            width = "full",
                            order = 1
                        },

                        criticalThreshold = {
                            type = "range",
                            name = "|TInterface\\ICONS\\SPELL_HOLY_BORROWEDTIME:16|t Critical Threshold",
                            desc = "Execution time (in seconds) that triggers a critical performance warning",
                            min = 0.1,
                            max = 2.0,
                            step = 0.01,
                            isPercent = false,
                            get = function()
                                return DebugService.performanceData and DebugService.performanceData.thresholds and DebugService.performanceData.thresholds.critical or 0.5
                            end,
                            set = function(_, value)
                                local warning = DebugService.performanceData and DebugService.performanceData.thresholds and DebugService.performanceData.thresholds.warning or 0.1
                                DebugService:SetPerformanceThresholds(warning, value)
                                self:RefreshOptions()
                            end,
                            width = "full",
                            order = 2
                        }
                    }
                },

                slowestOperations = {
                    type = "group",
                    name = "Slowest Operations",
                    order = 4,
                    args = {
                        slowestList = {
                            type = "description",
                            name = function()
                                local perfStats = DebugService:GetPerformanceStats()
                                if #perfStats.slowestOperations == 0 then
                                    return "|cFF888888No performance data available yet|r\nEnable performance monitoring and use the addon to generate data."
                                end

                                local text = "|cFFFFA500Top 10 Slowest Operations:|r\n"
                                for i, op in ipairs(perfStats.slowestOperations) do
                                    local durationColor = "|cFFFFFF00"
                                    if op.duration > (perfStats.thresholds and perfStats.thresholds.critical or 0.5) then
                                        durationColor = "|cFFFF0000"
                                    elseif op.duration > (perfStats.thresholds and perfStats.thresholds.warning or 0.1) then
                                        durationColor = "|cFFFFA500"
                                    end
                                    
                                    text = text .. string.format(
                                        "%d. %s |cFF888888(%s)|r - %s%.3fms|r\n",
                                        i, op.operation, op.category, durationColor, op.duration * 1000
                                    )
                                end
                                return text
                            end,
                            fontSize = "small",
                            order = 1
                        },

                        clearPerformanceData = {
                            type = "execute",
                            name = "|TInterface\\ICONS\\INV_Misc_Dust_02:16|t Clear Performance Data",
                            desc = "Clear all performance measurement history",
                            func = function()
                                DebugService.performanceData.history = {}
                                DebugService.performanceData.measurements = {}
                                self:RefreshOptions()
                                DebugService:User("Performance data cleared")
                            end,
                            order = 2
                        }
                    }
                },

                categoryBreakdown = {
                    type = "group",
                    name = "Performance by Category",
                    order = 5,
                    args = {
                        categoryList = {
                            type = "description",
                            name = function()
                                local perfStats = DebugService:GetPerformanceStats()
                                if next(perfStats.byCategory) == nil then
                                    return "|cFF888888No category performance data available|r"
                                end

                                local text = ""
                                for category, data in pairs(perfStats.byCategory) do
                                    text = text .. string.format(
                                        "|TInterface\\ICONS\\INV_Misc_Book_09:12|t |cFF00FFFF%s|r: %d calls, avg: %.3fms, max: %.3fms\n",
                                        category, data.count, data.averageDuration * 1000, data.maxDuration * 1000
                                    )
                                end
                                return text
                            end,
                            fontSize = "small",
                            order = 1
                        }
                    }
                },

                exportPerformance = {
                    type = "execute",
                    name = "|TInterface\\ICONS\\INV_Inscription_ScrollOfWisdom_01:16|t Export Performance Data",
                    desc = "Export detailed performance data for analysis",
                    func = function()
                        local perfData = DebugService:ExportPerformanceData()
                        local exportText = string.format(
                            "NextKey Performance Data Export\n" ..
                            "Timestamp: %s\n" ..
                            "Total Measurements: %d\n" ..
                            "Average Duration: %.3fms\n" ..
                            "Max Duration: %.3fms\n" ..
                            "Active Timers: %d\n" ..
                            "Thresholds: Warning=%.3fms Critical=%.3fms",
                            perfData.timestamp,
                            perfData.stats.totalMeasurements,
                            perfData.stats.averageDuration * 1000,
                            perfData.stats.maxDuration * 1000,
                            perfData.stats.activeTimers,
                            (perfData.stats.thresholds.warning or 0.1) * 1000,
                            (perfData.stats.thresholds.critical or 0.5) * 1000
                        )

                        -- Add slowest operations
                        if #perfData.stats.slowestOperations > 0 then
                            exportText = exportText .. "\n\nSlowest Operations:"
                            for i, op in ipairs(perfData.stats.slowestOperations) do
                                exportText = exportText .. string.format(
                                    "\n%d. %s (%s): %.3fms",
                                    i, op.operation, op.category, op.duration * 1000
                                )
                            end
                        end

                        -- Copy to clipboard (if possible)
                        if _G.ChatEdit_InsertLink then
                            _G.ChatEdit_InsertLink(exportText)
                            DebugService:User("Performance data copied to clipboard")
                        else
                            DebugService:User("Performance data export: " .. exportText)
                        end
                    end,
                    order = 6
                }
            }
        },

        historicalData = {
            type = "group",
            name = "Historical Data",
            order = 3,
            args = {
                peakUsage = {
                    type = "description",
                    name = function()
                        return "|TInterface\\ICONS\\INV_Misc_Statue_02:12|t |cFFFFA500Peak Usage Tracking|r\n" ..
                               "Peak Memory: Not implemented yet\n" ..
                               "Peak Messages/Min: Not implemented yet\n" ..
                               "Longest Session: Not implemented yet"
                    end,
                    fontSize = "small",
                    order = 1
                },

                clearHistory = {
                    type = "execute",
                    name = "|TInterface\\ICONS\\INV_Misc_Dust_02:16|t Clear Historical Data",
                    desc = "Clear all historical debug data and statistics",
                    confirm = true,
                    confirmText = "Are you sure you want to clear all historical debug data?",
                    func = function()
                        -- Implementation for clearing historical data
                        DebugService:User("Historical data clearing not implemented yet")
                    end,
                    order = 2
                }
            }
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