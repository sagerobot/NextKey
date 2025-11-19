-- MARK: Module Definition
local _, NextKey222 = ...

--- Tooltips Module
--- Contains tooltip generation and display functions for IO gain and player data
--- Extracted from ui/main.lua lines 1236-1531
local Tooltips = {}
NextKey222.Tooltips = Tooltips

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("Tooltips", Tooltips)

-- MARK: Dependencies
local Debug = NextKey222.Debug

-- MARK: Public Interface

--- Shared tooltip handler for IO gain displays (full and compact rows)
--- @param button Frame Button or region triggering the tooltip
--- @param keyInfo table Keystone data for the row
--- @param entry table Row entry containing cached ioRange (optional)
--- @param ioRange table Range data (min/max/expected + playerBreakdown)
function Tooltips:ShowIOGainTooltip(button, keyInfo, entry, ioRange)
    if not button or not keyInfo or not ioRange then
        return
    end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

    local usedPreCalculated = entry and entry.ioGainRange ~= nil
    Debug:Dev("tooltip", " Using", usedPreCalculated and "pre-calculated" or "recalculated", "ioRange")

    if ioRange.playerBreakdown then
        local playerCount = 0
        for _ in pairs(ioRange.playerBreakdown) do
            playerCount = playerCount + 1
        end
        Debug:Dev("tooltip", " Player breakdown has", playerCount, "players")
        for playerName in pairs(ioRange.playerBreakdown) do
            Debug:Dev("tooltip", " Breakdown includes player:", playerName)
        end
    else
        Debug:Dev("tooltip", " No player breakdown available")
    end

    local dungeonName = "Unknown Dungeon"
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID) or ("Dungeon " .. keyInfo.dungeonID)
    end

    local ownerName = keyInfo.ownerName or "Unknown"
    local keystoneLevel = keyInfo.level or 0
    local headerText = string.format("%s (+%d) - %s's Key", dungeonName, keystoneLevel, ownerName:match("^([^%-]+)") or ownerName)
    GameTooltip:SetText(headerText, 1, 1, 1, 1, true)
    GameTooltip:AddLine("Group IO Gain Potential", 0.9, 0.9, 1)

    local showedBreakpoints = false
    if keystoneLevel > 0 and NextKey222.IOCalculator and ioRange.playerBreakdown then
        local breakpointRanges = self:CalculateBreakpointRanges(keyInfo, ioRange.playerBreakdown)
        if breakpointRanges then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(string.format("Untimed: +%d Group IO (+%d Avg)",
                math.floor(breakpointRanges.untimed.total or 0),
                math.floor(breakpointRanges.untimed.average or 0)), 0.8, 0.4, 0.4)
            GameTooltip:AddLine(string.format("Timed: +%d Group IO (+%d Avg)",
                math.floor(breakpointRanges.timed.total or 0),
                math.floor(breakpointRanges.timed.average or 0)), 1, 1, 0.4)
            GameTooltip:AddLine(string.format("+2: +%d Group IO (+%d Avg)",
                math.floor(breakpointRanges.plus2.total or 0),
                math.floor(breakpointRanges.plus2.average or 0)), 0.4, 1, 0.4)
            GameTooltip:AddLine(string.format("+3: +%d Group IO (+%d Avg)",
                math.floor(breakpointRanges.plus3.total or 0),
                math.floor(breakpointRanges.plus3.average or 0)), 0.2, 1, 0.2)
            showedBreakpoints = true
        end
    end

    if not showedBreakpoints then
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine(string.format("Group IO Gain: +%d", math.floor(ioRange.expected or 0)), 0, 1, 0)
        GameTooltip:AddLine(string.format("Range: +%d to +%d", math.floor(ioRange.min or 0), math.floor(ioRange.max or 0)), 0.8, 0.8, 0.8)
    end

    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("Individual Player Breakdown:", 0.9, 0.9, 0.9)

    if ioRange.playerBreakdown then
        local playerEntries = {}
        local dungeonID = keyInfo.dungeonID

        for playerName, breakdown in pairs(ioRange.playerBreakdown) do
            local entryData = {
                name = playerName,
                shortName = playerName:match("^([^%-]+)") or playerName,
                breakdown = breakdown,
                minGain = breakdown.min or 0,
                maxGain = breakdown.max or 0,
                currentIO = 0,
                bestLevel = 0,
                hasNextKey = false,
                fakeProfile = self:GetFakePlayerData(playerName)
            }

            if dungeonID and NextKey222.IOCalculator then
                entryData.currentIO = NextKey222.IOCalculator:GetPlayerDungeonScore(playerName, dungeonID) or 0
                Debug:Dev("tooltip", "Current dungeon IO for", playerName, "dungeon", dungeonID .. ":", entryData.currentIO)
            end

            if entryData.fakeProfile and entryData.fakeProfile.addonStatus then
                entryData.hasNextKey = entryData.fakeProfile.addonStatus.nextkey or false
            else
                entryData.hasNextKey = (entryData.minGain > 0 or entryData.maxGain > 0 or entryData.currentIO > 0)
            end

            local currentPlayerFull = UnitName("player") .. "-" .. GetRealmName()
            local isCurrentPlayer = (playerName == currentPlayerFull) or (playerName:match("^([^%-]+)") == UnitName("player"))
            if entryData.hasNextKey and dungeonID then
                if isCurrentPlayer then
                    entryData.bestLevel = self:GetBestLevel(dungeonID) or 0
                elseif entryData.fakeProfile and entryData.fakeProfile.dungeonScores then
                    local scoreEntry = entryData.fakeProfile.dungeonScores[dungeonID]
                    if scoreEntry then
                        entryData.bestLevel = scoreEntry.bestLevel or scoreEntry.level or 0
                    end
                end
            end

            table.insert(playerEntries, entryData)
        end

        table.sort(playerEntries, function(a, b)
            -- Sort by potential IO gain (highest first)
            local aPotential = (a.minGain or 0) + (a.maxGain or 0)
            local bPotential = (b.minGain or 0) + (b.maxGain or 0)
            
            if aPotential ~= bPotential then
                return aPotential > bPotential
            end
            
            -- Then by current IO score (lowest first - helps those who need it most)
            if a.currentIO ~= b.currentIO then
                return a.currentIO < b.currentIO
            end
            
            -- Finally by best level (lowest first)
            return (a.bestLevel or 0) < (b.bestLevel or 0)
        end)

        for _, data in ipairs(playerEntries) do
            if data.hasNextKey then
                local potentialColor = "|cff00ff00"
                if math.floor(data.minGain) == 0 and math.floor(data.maxGain) == 0 then
                    potentialColor = "|cff999999"
                end

                local bestLevelText = data.bestLevel > 0 and string.format(" |cff4aa3ff+%d|r", data.bestLevel) or ""
                local playerLine = string.format("%s: %s(+%d-%d Potential IO)|r |cffffff00(Current IO: %d)|r%s",
                    data.shortName,
                    potentialColor,
                    math.floor(data.minGain),
                    math.floor(data.maxGain),
                    math.floor(data.currentIO),
                    bestLevelText)
                GameTooltip:AddLine(playerLine, 1, 1, 1)
            else
                GameTooltip:AddLine(string.format("%s: NextKey Not Installed", data.shortName), 0.6, 0.6, 0.6)
            end
        end
    end

    GameTooltip:Show()
end

--- Shows IO gain tooltip using the centralized tooltip system (Phase 7 fix)
--- @param button Frame Button or region triggering the tooltip
--- @param keyInfo table Keystone data for the row
--- @param entry table Row entry containing cached ioRange (optional)
--- @param ioRange table Range data (min/max/expected + playerBreakdown)
function Tooltips:ShowIOGainTooltipCentralized(button, keyInfo, entry, ioRange)
    if not button or not keyInfo or not ioRange then
        Debug:Dev("tooltip", "ShowIOGainTooltipCentralized: Missing parameters - button:", button ~= nil, "keyInfo:", keyInfo ~= nil, "ioRange:", ioRange ~= nil)
        return
    end
    
    -- Use centralized tooltip system if available
    if NextKey222.Tooltip and NextKey222.Tooltip.Create then
        Debug:Dev("tooltip", "Using centralized tooltip system for IO gain")
        
        -- Build tooltip data in the format expected by the centralized system
        local tooltipData = {
            frame = button,
            title = self:BuildIOTooltipTitle(keyInfo, ioRange),
            subtitle = "Group IO Gain Potential",
            breakdown = self:BuildIOTooltipBreakdown(keyInfo, ioRange),
            totals = self:BuildIOTooltipTotals(keyInfo, ioRange)
        }
        
        Debug:Dev("tooltip", "Calling NextKey222.Tooltip:Create with TYPE_IO_GAIN")
        NextKey222.Tooltip:Create(NextKey222.Tooltip.TYPE_IO_GAIN, tooltipData)
        return
    end
    
    Debug:Dev("tooltip", "Centralized tooltip system not available, using fallback")
    -- Fallback to original implementation if centralized system not available
    self:ShowIOGainTooltip(button, keyInfo, entry, ioRange)
end

--- Builds the title for IO gain tooltip
--- @param keyInfo table Keystone data
--- @param ioRange table IO range data
--- @return string Formatted title
function Tooltips:BuildIOTooltipTitle(keyInfo, ioRange)
    local dungeonName = "Unknown Dungeon"
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID) or ("Dungeon " .. keyInfo.dungeonID)
    end
    
    local ownerName = keyInfo.ownerName or "Unknown"
    local keystoneLevel = keyInfo.level or 0
    return string.format("%s (+%d) - %s's Key", dungeonName, keystoneLevel, ownerName:match("^([^%-]+)") or ownerName)
end

--- Builds the player breakdown for IO gain tooltip
--- @param keyInfo table Keystone data
--- @param ioRange table IO range data
--- @return table Formatted breakdown data
function Tooltips:BuildIOTooltipBreakdown(keyInfo, ioRange)
    if not ioRange.playerBreakdown then
        return {}
    end
    
    local playerEntries = {}
    local dungeonID = keyInfo.dungeonID
    
    for playerName, breakdown in pairs(ioRange.playerBreakdown) do
        -- Get player profile to extract class information
        local profile = self:GetPlayerProfileCached(playerName)
        
        local entryData = {
            name = playerName,
            shortName = playerName:match("^([^%-]+)") or playerName,
            breakdown = breakdown,
            minGain = breakdown.min or 0,
            maxGain = breakdown.max or 0,
            currentIO = 0,
            bestLevel = 0,
            hasNextKey = false,
            fakeProfile = self:GetFakePlayerData(playerName),
            classToken = profile and profile.class,
            class = profile and profile.class
        }
        
        if dungeonID and NextKey222.IOCalculator then
            entryData.currentIO = NextKey222.IOCalculator:GetPlayerDungeonScore(playerName, dungeonID) or 0
        end
        
        if entryData.fakeProfile and entryData.fakeProfile.addonStatus then
            entryData.hasNextKey = entryData.fakeProfile.addonStatus.nextkey or false
        else
            entryData.hasNextKey = (entryData.minGain > 0 or entryData.maxGain > 0 or entryData.currentIO > 0)
        end
        
        local currentPlayerFull = UnitName("player") .. "-" .. GetRealmName()
        local isCurrentPlayer = (playerName == currentPlayerFull) or (playerName:match("^([^%-]+)") == UnitName("player"))
        if entryData.hasNextKey and dungeonID then
            if isCurrentPlayer then
                entryData.bestLevel = self:GetBestLevel(dungeonID) or 0
            elseif entryData.fakeProfile and entryData.fakeProfile.dungeonScores then
                local scoreEntry = entryData.fakeProfile.dungeonScores[dungeonID]
                if scoreEntry then
                    entryData.bestLevel = scoreEntry.bestLevel or scoreEntry.level or 0
                end
            end
        end
        
        table.insert(playerEntries, entryData)
    end
    
    -- Sort players by potential IO gain (highest first), then current IO (lowest first)
    table.sort(playerEntries, function(a, b)
        -- Sort by potential IO gain (highest first)
        local aPotential = (a.minGain or 0) + (a.maxGain or 0)
        local bPotential = (b.minGain or 0) + (b.maxGain or 0)
        
        if aPotential ~= bPotential then
            return aPotential > bPotential
        end
        
        -- Then by current IO score (lowest first - helps those who need it most)
        if a.currentIO ~= b.currentIO then
            return a.currentIO < b.currentIO
        end
        
        -- Finally by best level (lowest first)
        return (a.bestLevel or 0) < (b.bestLevel or 0)
    end)
    
    return playerEntries
end

--- Builds the totals section for IO gain tooltip
--- @param keyInfo table Keystone data
--- @param ioRange table IO range data
--- @return table Formatted totals data
function Tooltips:BuildIOTooltipTotals(keyInfo, ioRange)
    local keystoneLevel = keyInfo.level or 0
    
    if keystoneLevel > 0 and NextKey222.IOCalculator and ioRange.playerBreakdown then
        return self:CalculateBreakpointRanges(keyInfo, ioRange.playerBreakdown)
    end
    
    return nil
end

-- MARK: Private Helper Functions

--- Get fake player data (addon status, profiles) from DebugAdapter
--- @param playerName string Player name to check
--- @return table|nil Fake player data or nil
function Tooltips:GetFakePlayerData(playerName)
    if not playerName or not NextKey222.ProfilesService then
        return nil
    end

    -- Check if this is a fake player by getting their debug profile
    local debugProfile = NextKey222.ProfilesService:GetDebugProfile(playerName)
    if debugProfile and debugProfile.addonStatus then
        return debugProfile
    end

    return nil
end

--- Gets cached player profile
--- @param playerName string Player name
--- @return table|nil Player profile or nil
function Tooltips:GetPlayerProfileCached(playerName)
    if not playerName then return nil end
    
    -- Use UI's profile cache if available
    if NextKey222.UI and NextKey222.UI.profileCache then
        if NextKey222.UI.profileCache[playerName] then
            return NextKey222.UI.profileCache[playerName]
        end
    end

    if NextKey222.ProfilesService and NextKey222.ProfilesService.GetProfile then
        local profile = NextKey222.ProfilesService:GetProfile(playerName)
        
        -- Cache in UI's profile cache if available
        if profile and NextKey222.UI and NextKey222.UI.profileCache then
            NextKey222.UI.profileCache[playerName] = profile
        end
        
        return profile
    end

    return nil
end

--- Retrieves the player's best key level for a specific dungeon (delegates to ScoreCalculations module)
--- @param dungeonID number The dungeon ID to get the best level for
--- @return number The highest key level completed for this dungeon (0 if none)
function Tooltips:GetBestLevel(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetBestLevel(dungeonID)
    end
    -- Fallback if module not loaded
    Debug:Error("ScoreCalculations module not available")
    return 0
end

--- Calculates group IO gain totals at key breakpoints (untimed/timed/+2/+3)
--- @param keyInfo table Keystone information (expects .level and .dungeonID)
--- @param playerBreakdown table Map of playerName -> { current, range = {min, expected, max} }
--- @return table|nil { untimed={total,average}, timed={...}, plus2={...}, plus3={...} }
function Tooltips:CalculateBreakpointRanges(keyInfo, playerBreakdown)
    if not keyInfo or not playerBreakdown or not NextKey222.IOCalculator then
        return nil
    end

    local level = tonumber(keyInfo.level) or 0
    if level <= 0 then return nil end

    local count = 0
    local totals = { untimed = 0, timed = 0, plus2 = 0, plus3 = 0 }

    for _, pdata in pairs(playerBreakdown) do
        count = count + 1
        local pr = pdata.range or {}

        -- Use per-player range for untimed/timed/+3 directly (consistent with IOCalculator)
        local minGain = tonumber(pr.min) or 0
        local expectedGain = tonumber(pr.expected) or 0
        local maxGain = tonumber(pr.max) or 0

        totals.untimed = totals.untimed + math.max(0, minGain)
        totals.timed   = totals.timed   + math.max(0, expectedGain)
        totals.plus3   = totals.plus3   + math.max(0, maxGain)

        -- For +2, linearly interpolate the gain between timed (20% bonus) and 3-chest (40% bonus)
        local timedGainClamped = math.max(0, expectedGain)
        local maxGainClamped = math.max(timedGainClamped, maxGain)
        local gainPlus2 = timedGainClamped + (maxGainClamped - timedGainClamped) * 0.5
        totals.plus2 = totals.plus2 + gainPlus2
    end

    if count == 0 then return nil end

    return {
        untimed = { total = totals.untimed, average = totals.untimed / count },
        timed   = { total = totals.timed,   average = totals.timed   / count },
        plus2   = { total = totals.plus2,   average = totals.plus2   / count },
        plus3   = { total = totals.plus3,   average = totals.plus3   / count },
    }
end

-- MARK: Initialization

--- Initializes the Tooltips module
--- @return boolean true if initialization succeeded
function Tooltips:Initialize()
    Debug:Dev("tooltips", "Tooltips module initialized")
    return true
end

return Tooltips