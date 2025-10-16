-- MARK: Tooltip Configuration System
-- Centralized tooltip management with consistent styling and positioning
-- Phase 7: Enhanced tooltip configuration system

local _, NextKey222 = ...

local Tooltip = {}
NextKey222.Tooltip = Tooltip

-- Register with module system
NextKey222.RegisterModule("Tooltip", Tooltip)

-- MARK: Tooltip Type Constants
-- Standardized tooltip types for consistent configuration

Tooltip.TYPE_PLAYER = "player"
Tooltip.TYPE_KEYSTONE = "keystone"
Tooltip.TYPE_DUNGEON = "dungeon"
Tooltip.TYPE_IO_GAIN = "io_gain"
Tooltip.TYPE_ITEM = "item"
Tooltip.TYPE_GENERIC = "generic"

-- MARK: Tooltip Configuration Templates
-- Standardized configurations for different tooltip types

Tooltip.configs = {
    [Tooltip.TYPE_PLAYER] = {
        anchor = "ANCHOR_RIGHT",
        showTitle = true,
        titleColor = {1, 1, 1},
        showLines = true,
        lineSpacing = 2,
        padding = 10,
        maxWidth = 300,
        backgroundColor = {0, 0, 0, 0.9},
        borderColor = {0.5, 0.5, 0.5, 1},
        fields = {
            "name",
            "spec",
            "role",
            "io",
            "capabilities"
        }
    },
    
    [Tooltip.TYPE_KEYSTONE] = {
        anchor = "ANCHOR_RIGHT",
        showTitle = true,
        titleColor = {1, 1, 1},
        showLines = true,
        lineSpacing = 2,
        padding = 10,
        maxWidth = 350,
        backgroundColor = {0, 0, 0, 0.9},
        borderColor = {0.5, 0.5, 0.5, 1},
        fields = {
            "dungeon",
            "level",
            "owner",
            "ioGain"
        }
    },
    
    [Tooltip.TYPE_DUNGEON] = {
        anchor = "ANCHOR_RIGHT",
        showTitle = true,
        titleColor = {1, 1, 1},
        showLines = true,
        lineSpacing = 2,
        padding = 10,
        maxWidth = 320,
        backgroundColor = {0, 0, 0, 0.9},
        borderColor = {0.5, 0.5, 0.5, 1},
        fields = {
            "name",
            "score",
            "bestLevel",
            "chests"
        }
    },
    
    [Tooltip.TYPE_IO_GAIN] = {
        anchor = "ANCHOR_RIGHT",
        showTitle = true,
        titleColor = {1, 1, 1},
        showLines = true,
        lineSpacing = 2,
        padding = 10,
        maxWidth = 400,
        backgroundColor = {0, 0, 0, 0.9},
        borderColor = {0.5, 0.5, 0.5, 1},
        fields = {
            "title",
            "subtitle",
            "breakdown",
            "totals"
        }
    },
    
    [Tooltip.TYPE_ITEM] = {
        anchor = "ANCHOR_RIGHT",
        showTitle = true,
        titleColor = {1, 1, 1},
        showLines = true,
        lineSpacing = 2,
        padding = 10,
        maxWidth = 300,
        backgroundColor = {0, 0, 0, 0.9},
        borderColor = {0.5, 0.5, 0.5, 1},
        fields = {
            "name",
            "quality",
            "type",
            "description"
        }
    },
    
    [Tooltip.TYPE_GENERIC] = {
        anchor = "ANCHOR_RIGHT",
        showTitle = true,
        titleColor = {1, 1, 1},
        showLines = true,
        lineSpacing = 2,
        padding = 10,
        maxWidth = 250,
        backgroundColor = {0, 0, 0, 0.9},
        borderColor = {0.5, 0.5, 0.5, 1},
        fields = {
            "title",
            "description"
        }
    }
}

-- MARK: Tooltip Content Builders
-- Functions to build content for different tooltip types

Tooltip.contentBuilders = {
    [Tooltip.TYPE_PLAYER] = function(data, config)
        local lines = {}
        
        -- Player name (with class color if available)
        if data.name then
            local color = {1, 1, 1}
            if data.classToken and _G.RAID_CLASS_COLORS[data.classToken] then
                local classColor = _G.RAID_CLASS_COLORS[data.classToken]
                color = {classColor.r, classColor.g, classColor.b}
            end
            table.insert(lines, {
                text = data.name,
                color = color,
                font = GameFontNormal
            })
        end
        
        -- Specialization
        if data.specName then
            table.insert(lines, {
                text = "Specialization: " .. data.specName,
                color = {0.8, 0.8, 0.8},
                font = GameFontNormalSmall
            })
        end
        
        -- Role
        if data.role then
            local roleColor = {0.8, 0.8, 0.8}
            if data.role == "TANK" then
                roleColor = {0.2, 0.6, 1}
            elseif data.role == "HEALER" then
                roleColor = {0.2, 1, 0.2}
            elseif data.role == "DAMAGER" then
                roleColor = {1, 0.2, 0.2}
            end
            table.insert(lines, {
                text = "Role: " .. data.role,
                color = roleColor,
                font = GameFontNormalSmall
            })
        end
        
        -- IO Score
        if data.io and data.io > 0 then
            table.insert(lines, {
                text = string.format("Total IO: %.0f", data.io),
                color = {0, 1, 0},
                font = GameFontNormalSmall
            })
        end
        
        -- Capabilities (Heroism/Battle Res)
        if data.hasHeroism or data.hasBattleRes then
            local capabilities = {}
            if data.hasHeroism then table.insert(capabilities, "Heroism") end
            if data.hasBattleRes then table.insert(capabilities, "Battle Res") end
            if #capabilities > 0 then
                table.insert(lines, {
                    text = "Provides: " .. table.concat(capabilities, ", "),
                    color = {0.9, 0.9, 0.3},
                    font = GameFontNormalSmall
                })
            end
        end
        
        return lines
    end,
    
    [Tooltip.TYPE_KEYSTONE] = function(data, config)
        local lines = {}
        
        -- Dungeon name and level
        if data.dungeonName and data.level then
            table.insert(lines, {
                text = string.format("%s (+%d)", data.dungeonName, data.level),
                color = {1, 1, 1},
                font = GameFontNormal
            })
        end
        
        -- Owner
        if data.ownerName then
            table.insert(lines, {
                text = "Owner: " .. data.ownerName,
                color = {0.8, 0.8, 0.8},
                font = GameFontNormalSmall
            })
        end
        
        -- IO Gain Potential
        if data.ioGain and data.ioGain > 0 then
            table.insert(lines, {
                text = string.format("IO Gain Potential: +%.0f", data.ioGain),
                color = {0, 1, 0},
                font = GameFontNormalSmall
            })
        end
        
        return lines
    end,
    
    [Tooltip.TYPE_DUNGEON] = function(data, config)
        local lines = {}
        
        -- Dungeon name
        if data.name then
            table.insert(lines, {
                text = data.name,
                color = {1, 1, 1},
                font = GameFontNormal
            })
        end
        
        -- Score
        if data.score and data.score > 0 then
            local scoreColor = {0.8, 0.8, 0.8}
            if NextKey222.RaiderIO and NextKey222.RaiderIO.GetScoreColor then
                local r, g, b = NextKey222.RaiderIO:GetScoreColor(data.score)
                scoreColor = {r, g, b}
            end
            table.insert(lines, {
                text = string.format("Score: %.0f", data.score),
                color = scoreColor,
                font = GameFontNormalSmall
            })
        end
        
        -- Best level
        if data.bestLevel and data.bestLevel > 0 then
            table.insert(lines, {
                text = string.format("Best Level: +%d", data.bestLevel),
                color = {0.4, 1, 0.9},
                font = GameFontNormalSmall
            })
        end
        
        -- Chests
        if data.chests and data.chests > 0 then
            local chestText = ""
            if data.chests >= 3 then
                chestText = "+++"
            elseif data.chests >= 2 then
                chestText = "++"
            else
                chestText = "+"
            end
            table.insert(lines, {
                text = string.format("Chests: %s%d", chestText, data.bestLevel or 0),
                color = {0.9, 0.9, 0.3},
                font = GameFontNormalSmall
            })
        end
        
        return lines
    end,
    
    [Tooltip.TYPE_IO_GAIN] = function(data, config)
        local lines = {}
        
        -- Title
        if data.title then
            table.insert(lines, {
                text = data.title,
                color = {1, 1, 1},
                font = GameFontNormal
            })
        end
        
        -- Subtitle
        if data.subtitle then
            table.insert(lines, {
                text = data.subtitle,
                color = {0.9, 0.9, 1},
                font = GameFontNormalSmall
            })
        end
        
        -- Breakdown
        if data.breakdown then
            table.insert(lines, {
                text = " ",
                color = {1, 1, 1},
                font = GameFontNormalSmall
            })
            table.insert(lines, {
                text = "Individual Player Breakdown:",
                color = {0.9, 0.9, 0.9},
                font = GameFontNormalSmall
            })
            
            for _, player in ipairs(data.breakdown) do
                local playerColor = {0.8, 0.8, 0.8}
                if player.hasNextKey then
                    playerColor = {0, 1, 0}
                else
                    playerColor = {0.6, 0.6, 0.6}
                end
                
                local playerText = string.format("%s: %s(+%d-%d Potential IO)",
                    player.shortName,
                    player.hasNextKey and "" or "|cff999999",
                    math.floor(player.minGain),
                    math.floor(player.maxGain)
                )
                
                table.insert(lines, {
                    text = playerText,
                    color = playerColor,
                    font = GameFontNormalSmall
                })
            end
        end
        
        -- Totals
        if data.totals then
            table.insert(lines, {
                text = " ",
                color = {1, 1, 1},
                font = GameFontNormalSmall
            })
            
            if data.totals.untimed then
                table.insert(lines, {
                    text = string.format("Untimed: +%d Group IO (+%d Avg)",
                        math.floor(data.totals.untimed.total or 0),
                        math.floor(data.totals.untimed.average or 0)),
                    color = {0.8, 0.4, 0.4},
                    font = GameFontNormalSmall
                })
            end
            
            if data.totals.timed then
                table.insert(lines, {
                    text = string.format("Timed: +%d Group IO (+%d Avg)",
                        math.floor(data.totals.timed.total or 0),
                        math.floor(data.totals.timed.average or 0)),
                    color = {1, 1, 0.4},
                    font = GameFontNormalSmall
                })
            end
            
            if data.totals.plus2 then
                table.insert(lines, {
                    text = string.format("+2: +%d Group IO (+%d Avg)",
                        math.floor(data.totals.plus2.total or 0),
                        math.floor(data.totals.plus2.average or 0)),
                    color = {0.4, 1, 0.4},
                    font = GameFontNormalSmall
                })
            end
            
            if data.totals.plus3 then
                table.insert(lines, {
                    text = string.format("+3: +%d Group IO (+%d Avg)",
                        math.floor(data.totals.plus3.total or 0),
                        math.floor(data.totals.plus3.average or 0)),
                    color = {0.2, 1, 0.2},
                    font = GameFontNormalSmall
                })
            end
        end
        
        return lines
    end,
    
    [Tooltip.TYPE_ITEM] = function(data, config)
        local lines = {}
        
        -- Item name (with quality color)
        if data.name then
            local color = {1, 1, 1}
            if data.quality and ITEM_QUALITY_COLORS[data.quality] then
                local qualityColor = ITEM_QUALITY_COLORS[data.quality]
                color = {qualityColor.r, qualityColor.g, qualityColor.b}
            end
            table.insert(lines, {
                text = data.name,
                color = color,
                font = GameFontNormal
            })
        end
        
        -- Item type
        if data.type then
            table.insert(lines, {
                text = "Type: " .. data.type,
                color = {0.8, 0.8, 0.8},
                font = GameFontNormalSmall
            })
        end
        
        -- Description
        if data.description then
            table.insert(lines, {
                text = data.description,
                color = {0.7, 0.7, 0.7},
                font = GameFontNormalSmall
            })
        end
        
        return lines
    end,
    
    [Tooltip.TYPE_GENERIC] = function(data, config)
        local lines = {}
        
        -- Title
        if data.title then
            table.insert(lines, {
                text = data.title,
                color = {1, 1, 1},
                font = GameFontNormal
            })
        end
        
        -- Description
        if data.description then
            table.insert(lines, {
                text = data.description,
                color = {0.8, 0.8, 0.8},
                font = GameFontNormalSmall
            })
        end
        
        return lines
    end
}

-- MARK: Tooltip Positioning System
-- Smart positioning to avoid screen edges

Tooltip.positioning = {
    -- Calculate optimal anchor point based on cursor position
    GetOptimalAnchor = function(frame)
        if not frame then return "ANCHOR_RIGHT" end
        
        local x, y = GetCursorPosition()
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()
        
        -- Convert to UI coordinates
        x = x / screenWidth * UIParent:GetScale()
        y = y / screenHeight * UIParent:GetScale()
        
        -- Determine best anchor based on position
        local anchor = "ANCHOR_RIGHT"
        
        -- If too close to right edge, anchor to left
        if x > screenWidth - 200 then
            anchor = "ANCHOR_LEFT"
        end
        
        -- If too close to bottom edge, anchor above
        if y < 200 then
            anchor = anchor == "ANCHOR_LEFT" and "ANCHOR_TOPLEFT" or "ANCHOR_TOPRIGHT"
        end
        
        -- If too close to top edge, anchor below
        if y > screenHeight - 200 then
            anchor = anchor == "ANCHOR_LEFT" and "ANCHOR_BOTTOMLEFT" or "ANCHOR_BOTTOMRIGHT"
        end
        
        return anchor
    end,
    
    -- Adjust tooltip position to stay within screen bounds
    AdjustPosition = function(tooltip, frame)
        if not tooltip or not frame then return end
        
        local tooltipWidth = tooltip:GetWidth()
        local tooltipHeight = tooltip:GetHeight()
        local frameLeft = frame:GetLeft()
        local frameBottom = frame:GetBottom()
        local frameRight = frame:GetRight()
        local frameTop = frame:GetTop()
        
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()
        
        -- Adjust horizontal position if needed
        if frameRight + tooltipWidth > screenWidth then
            tooltip:ClearAllPoints()
            tooltip:SetPoint("RIGHT", frame, "LEFT", -5, 0)
        end
        
        -- Adjust vertical position if needed
        if frameBottom - tooltipHeight < 0 then
            tooltip:ClearAllPoints()
            tooltip:SetPoint("BOTTOM", frame, "TOP", 0, 5)
        end
    end
}

-- MARK: Tooltip Creation and Management
-- Main functions for creating and managing tooltips

--- Creates a tooltip with the specified type and data
-- @param tooltipType string The type of tooltip to create
-- @param data table The data to populate the tooltip with
-- @param config table Optional configuration overrides
-- @return table The created tooltip (GameTooltip object)
function Tooltip:Create(tooltipType, data, config)
    if not tooltipType or not data then
        Debug:Error("Tooltip:Create - Missing tooltipType or data")
        return nil
    end
    
    -- Get configuration for this tooltip type
    local tooltipConfig = self.configs[tooltipType]
    if not tooltipConfig then
        Debug:Error("Tooltip:Create - Unknown tooltip type:", tooltipType)
        tooltipConfig = self.configs[self.TYPE_GENERIC]
    end
    
    -- Apply configuration overrides
    if config then
        for k, v in pairs(config) do
            tooltipConfig[k] = v
        end
    end
    
    -- Create GameTooltip
    local tooltip = GameTooltip
    tooltip:ClearLines()
    
    -- Set owner and anchor
    local frame = data.frame or data.owner or UIParent
    local anchor = tooltipConfig.anchor or "ANCHOR_RIGHT"
    
    -- Use smart positioning if enabled
    if tooltipConfig.smartPositioning then
        anchor = self.positioning.GetOptimalAnchor(frame)
    end
    
    tooltip:SetOwner(frame, anchor)
    
    -- Build content
    local contentBuilder = self.contentBuilders[tooltipType]
    if contentBuilder then
        local lines = contentBuilder(data, tooltipConfig)
        
        -- Add lines to tooltip
        for i, line in ipairs(lines) do
            if i == 1 and tooltipConfig.showTitle then
                -- Title line
                tooltip:AddLine(line.text, line.color[1], line.color[2], line.color[3], true)
            else
                -- Regular line
                tooltip:AddLine(line.text, line.color[1], line.color[2], line.color[3])
            end
        end
    else
        -- Fallback to simple text
        tooltip:SetText(data.title or "Tooltip", 1, 1, 1)
    end
    
    -- Apply styling
    if tooltipConfig.backgroundColor then
        tooltip:SetBackdropColor(unpack(tooltipConfig.backgroundColor))
    end
    
    if tooltipConfig.borderColor then
        tooltip:SetBackdropBorderColor(unpack(tooltipConfig.borderColor))
    end
    
    -- Show tooltip
    tooltip:Show()
    
    -- Adjust position if needed
    if tooltipConfig.smartPositioning then
        self.positioning.AdjustPosition(tooltip, frame)
    end
    
    return tooltip
end

--- Attaches a tooltip to a frame with automatic show/hide
-- @param frame Frame The frame to attach tooltip to
-- @param tooltipType string The type of tooltip to create
-- @param data table The data to populate the tooltip with
-- @param config table Optional configuration overrides
function Tooltip:Attach(frame, tooltipType, data, config)
    if not frame then
        Debug:Error("Tooltip:Attach - Missing frame")
        return
    end
    
    -- Store tooltip data on the frame
    frame._nkTooltipData = data
    frame._nkTooltipType = tooltipType
    frame._nkTooltipConfig = config
    
    -- Set up show/hide scripts
    frame:SetScript("OnEnter", function()
        if frame._nkTooltipData and frame._nkTooltipType then
            self:Create(frame._nkTooltipType, frame._nkTooltipData, frame._nkTooltipConfig)
        end
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Updates an existing tooltip attached to a frame
-- @param frame Frame The frame with attached tooltip
-- @param data table The new data to populate the tooltip with
function Tooltip:Update(frame, data)
    if not frame then
        Debug:Error("Tooltip:Update - Missing frame")
        return
    end
    
    -- Update stored data
    frame._nkTooltipData = data
    
    -- If tooltip is currently visible, update it
    if GameTooltip:GetOwner() == frame then
        if frame._nkTooltipType then
            self:Create(frame._nkTooltipType, frame._nkTooltipData, frame._nkTooltipConfig)
        end
    end
end

--- Removes a tooltip from a frame
-- @param frame Frame The frame to remove tooltip from
function Tooltip:Detach(frame)
    if not frame then return end
    
    -- Clear tooltip data
    frame._nkTooltipData = nil
    frame._nkTooltipType = nil
    frame._nkTooltipConfig = nil
    
    -- Clear scripts
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)
    
    -- Hide tooltip if currently shown
    if GameTooltip:GetOwner() == frame then
        GameTooltip:Hide()
    end
end

-- MARK: Module Initialization
function Tooltip:Initialize()
    Debug:Dev("tooltip", "Tooltip module initialized")
    return true
end

return Tooltip