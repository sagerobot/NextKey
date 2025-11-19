-- MARK: Module Definition
local _, NextKey222 = ...

--- KeystoneCards Module
--- Contains keystone card rendering functions for displaying player keystones
--- Extracted from ui/main.lua lines 1958-2429
local KeystoneCards = {}
NextKey222.KeystoneCards = KeystoneCards

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("KeystoneCards", KeystoneCards)

-- MARK: Dependencies
local Debug = NextKey222.Debug

-- MARK: Private Helper Functions

--- Track auxiliary frames for cleanup (delegates to Utilities module)
--- @param self table UI module instance (unused, kept for compatibility)
--- @param frame table Frame to track
local function trackAuxFrame(self, frame)
    if NextKey222.Utilities then
        NextKey222.Utilities:TrackAuxFrame(frame)
    else
        -- Fallback if module not loaded
        Debug:Error("Utilities module not available - frame tracking may fail")
    end
end

-- MARK: Public Interface

--- Creates and renders a keystone card for a single player entry
--- @param UI table The UI module instance
--- @param entry table The keystone data containing player info, key details, and scores
--- Handles both real player keystones and fake player data for testing
function KeystoneCards:AddKeyRow(UI, entry)
    local keyInfo = entry.key
    
    -- Get dungeon name
    local dungeonName = "No Keystone"
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID)
        if not dungeonName or dungeonName == "" then
            dungeonName = "Unknown Dungeon (ID:" .. keyInfo.dungeonID .. ")"
        end
    else
        keyInfo.level = 0
    end
    
    -- Normalize player name and get score using components
    if not NextKey222.UIComponents then
        Debug:Error(" UIComponents not loaded! Check load order.")
        return
    end
    
    local ownerName = NextKey222.UIComponents:NormalizePlayerName(keyInfo.ownerName)
    local score = NextKey222.UIComponents:GetPlayerScore(keyInfo)
    local classToken = keyInfo.class or "WARRIOR"
    
    -- Create container using component factory
    local container = NextKey222.UIComponents:CreateCardContainer(88, false)
    UI.resultsFrame:AddChild(container)
    
    -- Create backdrop using component factory
    local cardFrame = container.cardFrame or container.frame
    local frame = NextKey222.UIComponents:CreateBackdrop(cardFrame, "keystone")
    trackAuxFrame(UI, cardFrame)
    
    -- Create class icon using component factory with player data for tooltip
    local playerData = {
        ownerName = ownerName,
        classToken = classToken,
        specName = entry.specName,
        specID = entry.specID,
        role = entry.role,
        hasHeroism = entry.hasHeroism,
        hasBattleRes = entry.hasBattleRes
    }
    local icon = NextKey222.UIComponents:CreateNativeClassIcon(frame, classToken, NextKey222.UIConfig.ICON.SIZE, playerData)
    -- Position class icon with simple vertical centering (using positive offset for downward positioning)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -20)  -- 20px from top for visual centering
    
    -- Create role icon using component factory
    local roleIcon = NextKey222.UIComponents:CreateNativeRoleIcon(frame, entry.role, NextKey222.UIConfig.ICON.ROLE_SIZE)
    roleIcon:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, 0)
    
    -- Create formatted player name text using component system
    local nameText = NextKey222.UIComponents:CreateText("body", frame, {
        text = NextKey222.UIComponents:FormatPlayerNameWithScore(ownerName, classToken, score),
        fontObject = GameFontNormal,
        justifyH = "LEFT"
    })

    -- Add prominent IO gain display based on algorithm metadata
    local ioGainText = nil
    local regularViewIORange = nil  -- Store ioRange in outer scope for button creation later
    local currentSortMode = UI:GetCurrentSortMode()
    
    -- Check if current algorithm wants IO tooltips displayed
    local showIOTooltips = false
    if NextKey222.Sorting and NextKey222.Sorting.GetAlgorithm then
        local algorithm = NextKey222.Sorting:GetAlgorithm(currentSortMode)
        if algorithm and algorithm.showIOTooltips ~= nil then
            showIOTooltips = algorithm.showIOTooltips
        end
    end
    
    if showIOTooltips and entry.ioGainRange then
        -- PERFORMANCE: Only show IO gain if we already calculated it during sorting
        -- Don't recalculate here - use pre-calculated data only
        local ioRange = entry.ioGainRange
        regularViewIORange = ioRange
        local expectedGain = ioRange.expected or 0
        local hasPotentialGain = expectedGain > 0
        
        ioGainText = NextKey222.UIComponents:CreateText("large", frame, {
            text = string.format("|cff%s+%d IO|r",
                hasPotentialGain and "00ff00" or "999999",
                math.floor(expectedGain)),
            fontObject = GameFontNormalLarge,
            justifyH = "RIGHT",
            color = hasPotentialGain and {0, 1, 0} or {0.6, 0.6, 0.6}
        })
        -- Don't position yet - will position relative to Select button after it's created
    end

    local levelText = NextKey222.UIComponents:CreateText("small", frame, {
        text = string.format("Keystone: %s |cff4aa3ff+%d|r", dungeonName, keyInfo.level or 0),
        fontObject = GameFontHighlightSmall,
        justifyH = "LEFT"
    })

    local bestText = nil
    local bestLevel = UI.GetSeasonBestLevel and UI:GetSeasonBestLevel(keyInfo.dungeonID)
    if bestLevel and bestLevel > 0 then
        bestText = NextKey222.UIComponents:CreateText("small", frame, {
            text = string.format("Your best: |cff4aa3ff+%d|r", bestLevel),
            fontObject = GameFontHighlightSmall,
            justifyH = "LEFT"
        })
    end

    -- Create select button using component factory
    local selectBtn = NextKey222.UIComponents:CreateNativeButton(frame, "select")
    -- Position button with simple vertical centering
    selectBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -20)  -- 20px from top for visual centering
    
    -- Now position IO gain text to the LEFT of Select button (if it exists)
    if ioGainText then
        ioGainText.frame:SetPoint("RIGHT", selectBtn, "LEFT", -8, 0)
        
        Debug:Dev("ui", "[IO Tooltip] Creating tooltip button for IO gain text")
        Debug:Dev("ui", "[IO Tooltip] ioGainText width:", ioGainText:GetStringWidth(), "height:", ioGainText:GetStringHeight())
        
        -- Create native button frame for reliable mouse event handling
        local ioGainButton = CreateFrame("Button", nil, frame)
        ioGainButton:SetAllPoints(ioGainText.frame)
        ioGainButton:SetFrameLevel(frame:GetFrameLevel() + 2) -- Higher frame level to be above everything
        ioGainButton:EnableMouse(true) -- CRITICAL: Enable mouse events
        ioGainButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        
        -- PERFORMANCE FIX: Throttle tooltip updates to prevent FPS drops
        local lastTooltipUpdate = 0
        local TOOLTIP_THROTTLE = 0.1 -- 100ms minimum between updates
        
        ioGainButton:SetScript("OnEnter", function(btn)
            local now = GetTime()
            if now - lastTooltipUpdate < TOOLTIP_THROTTLE then
                return -- Throttle tooltip updates
            end
            lastTooltipUpdate = now
            
            Debug:Dev("ui", "[IO Tooltip] Mouse entered button - showing tooltip")
            if NextKey222.Tooltips then
                NextKey222.Tooltips:ShowIOGainTooltipCentralized(btn, keyInfo, entry, regularViewIORange)
            end
        end)
        
        ioGainButton:SetScript("OnLeave", function(btn)
            Debug:Dev("ui", "[IO Tooltip] Mouse left button - hiding tooltip")
            GameTooltip_Hide()
        end)
        
        ioGainButton:Show()
        trackAuxFrame(UI, ioGainButton)
        
        Debug:Dev("ui", "[IO Tooltip] Native button created - frame level:", ioGainButton:GetFrameLevel())
        Debug:Dev("ui", "[IO Tooltip] Button visible:", ioGainButton:IsVisible() and "YES" or "NO")
        Debug:Dev("ui", "[IO Tooltip] Button mouse enabled:", ioGainButton:IsMouseEnabled() and "YES" or "NO")
    end
    selectBtn:SetWidth(110)
    selectBtn:SetHeight(24)
    trackAuxFrame(UI, selectBtn)

    -- Position all text elements with simple vertical alignment
    nameText.frame:ClearAllPoints()
    nameText.frame:SetPoint("TOPLEFT", roleIcon, "TOPRIGHT", 8, 0)
    nameText.frame:SetPoint("TOPRIGHT", selectBtn, "TOPLEFT", -12, 0)

    levelText.frame:ClearAllPoints()
    levelText.frame:SetPoint("TOPLEFT", nameText.frame, "BOTTOMLEFT", 0, -4)
    levelText.frame:SetPoint("TOPRIGHT", nameText.frame, "BOTTOMRIGHT", 0, -4)

    if bestText then
        bestText.frame:ClearAllPoints()
        bestText.frame:SetPoint("TOPLEFT", levelText.frame, "BOTTOMLEFT", 0, -4)
        bestText.frame:SetPoint("TOPRIGHT", levelText.frame, "BOTTOMRIGHT", 0, -4)
    end

    -- Configure button state and behavior
    local isLeader = NextKey222.Addon:IsLeaderOrSolo()
    local isSelected = NextKey222.Addon.IsKeySelected and NextKey222.Addon:IsKeySelected(keyInfo)
    
    if isSelected then
        selectBtn:SetText("Selected")
        selectBtn:Disable()
        selectBtn:SetAlpha(0.85)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("This keystone is currently selected for teleports.")
            GameTooltip:Show()
        end)
    elseif isLeader then
        selectBtn:Enable()
        selectBtn:SetAlpha(1)
        selectBtn:SetScript("OnClick", function()
            NextKey222.Addon:SetTeleportTargetKey(keyInfo, { broadcast = true })
        end)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Set this keystone as the teleport target.")
            GameTooltip:AddLine("Shares the selection with party members running NextKey.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
    else
        selectBtn:Disable()
        selectBtn:SetAlpha(0.4)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Only the party leader can select a key.")
            GameTooltip:Show()
        end)
    end
    selectBtn:SetScript("OnLeave", GameTooltip_Hide)

    -- Debug helper: allow removing individual fake players directly from the card
    if UI:IsDebugMode() and NextKey222.FakePlayerService and ownerName and NextKey222.FakePlayerService:IsFakePlayer(ownerName) then
        local deleteBtn = NextKey222.UIComponents:CreateNativeButton(frame, "select")
        deleteBtn:SetText("Delete")
        deleteBtn:SetSize(selectBtn:GetWidth(), selectBtn:GetHeight())
        -- Position Delete button directly below Select with minimal spacing for vertical centering
        deleteBtn:SetPoint("TOP", selectBtn, "BOTTOM", 0, -4)
        deleteBtn:SetScript("OnClick", function()
            UI:HandleDeleteFakePlayer(ownerName)
        end)
        deleteBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove this fake player")
            GameTooltip:Show()
        end)
        deleteBtn:SetScript("OnLeave", GameTooltip_Hide)
        trackAuxFrame(UI, deleteBtn)
    end
end

--- Creates and renders a compact keystone card for high player counts
--- @param UI table The UI module instance
--- @param entry table The keystone data containing player info, key details, and scores
--- Uses aliases and condensed layout to save vertical space
function KeystoneCards:AddKeyRowCompact(UI, entry)
    local keyInfo = entry.key
    
    -- Get dungeon name
    local dungeonName = "No Key"
    if keyInfo.dungeonID and keyInfo.dungeonID > 0 then
        dungeonName = NextKey222.Addon:GetDungeonName(keyInfo.dungeonID)
        if not dungeonName or dungeonName == "" then
            dungeonName = "Unknown Dungeon (ID:" .. keyInfo.dungeonID .. ")"
        end
    end
    
    -- Use component system for consistent processing
    if not NextKey222.UIComponents then
        Debug:Error(" UIComponents not loaded! Check load order.")
        return
    end
    
    local ownerName = NextKey222.UIComponents:NormalizePlayerName(keyInfo.ownerName)
    local score = NextKey222.UIComponents:GetPlayerScore(keyInfo)
    local classToken = keyInfo.class or "WARRIOR"
    
    -- Create compact container
    local container = NextKey222.UIComponents:CreateCardContainer(28, true)
    UI.resultsFrame:AddChild(container)
    
    -- Create compact backdrop
    local cardFrame = container.cardFrame or container.frame
    local frame = NextKey222.UIComponents:CreateBackdrop(cardFrame, "keystone_compact")
    trackAuxFrame(UI, cardFrame)
    
    -- Create smaller class icon with player data for tooltip
    local playerData = {
        ownerName = ownerName,
        classToken = classToken,
        specName = entry.specName,
        specID = entry.specID,
        role = entry.role,
        hasHeroism = entry.hasHeroism,
        hasBattleRes = entry.hasBattleRes
    }
    local icon = NextKey222.UIComponents:CreateNativeClassIcon(frame, classToken, 20, playerData)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
    
    -- Create role icon for compact view (smaller size)
    local roleIcon = NextKey222.UIComponents:CreateNativeRoleIcon(frame, entry.role, 12)
    roleIcon:SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0)
    
    -- Create compact single-line text using component system
    local nameDisplay = NextKey222.UIComponents:FormatPlayerNameWithScore(ownerName, classToken, score)
    local keyDisplay = NextKey222.UIComponents:FormatKeystoneDisplay(dungeonName, keyInfo.level)
    
    -- Determine IO gain display state for compact view
    local currentSortMode = UI:GetCurrentSortMode()
    local compactIORange = nil
    local showCompactIO = false
    
    -- Check if current algorithm wants IO tooltips displayed
    local showIOTooltips = false
    if NextKey222.Sorting and NextKey222.Sorting.GetAlgorithm then
        local algorithm = NextKey222.Sorting:GetAlgorithm(currentSortMode)
        if algorithm and algorithm.showIOTooltips ~= nil then
            showIOTooltips = algorithm.showIOTooltips
        end
    end
    
    if showIOTooltips and entry.ioGainRange then
        -- PERFORMANCE: Only show IO gain if we already calculated it during sorting
        -- Don't recalculate here - use pre-calculated data only
        compactIORange = entry.ioGainRange
        showCompactIO = true
    end

    local fullText = string.format("%s | %s", nameDisplay, keyDisplay)
    
    local mainText = NextKey222.UIComponents:CreateText("small", frame, {
        text = fullText,
        fontObject = GameFontNormalSmall,
        justifyH = "LEFT"
    })
    mainText.frame:SetPoint("TOPLEFT", roleIcon, "TOPRIGHT", 4, 0)

    local isFakePlayer = UI:IsDebugMode()
        and NextKey222.FakePlayerService
        and ownerName
        and NextKey222.FakePlayerService:IsFakePlayer(ownerName)

    -- Create compact select button
    local selectBtn = NextKey222.UIComponents:CreateNativeButton(frame, "select_compact")
    selectBtn:ClearAllPoints()
    selectBtn:SetPoint("RIGHT", frame, "RIGHT", -6, 0)
    if isFakePlayer then
        selectBtn:SetText("Sel")
        selectBtn:SetSize(56, 18)
    else
        selectBtn:SetText("Select")
        selectBtn:SetSize(82, 22)
    end
    trackAuxFrame(UI, selectBtn)

    -- Configure compact button state
    local isLeader = NextKey222.Addon:IsLeaderOrSolo()
    local isSelected = NextKey222.Addon.IsKeySelected and NextKey222.Addon:IsKeySelected(keyInfo)
    
    if isSelected then
        if isFakePlayer then
            selectBtn:SetText("Sel")
            selectBtn:SetWidth(56)
            selectBtn:SetHeight(18)
        else
            selectBtn:SetText("Selected")
            selectBtn:SetWidth(82)
            selectBtn:SetHeight(22)
        end
        selectBtn:Disable()
        selectBtn:SetAlpha(0.85)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("This keystone is currently selected for teleports.")
            GameTooltip:Show()
        end)
    elseif isLeader then
        selectBtn:Enable()
        selectBtn:SetScript("OnClick", function()
            NextKey222.Addon:SetTeleportTargetKey(keyInfo, { broadcast = true })
        end)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Set this keystone as the teleport target.")
            GameTooltip:AddLine("Shares the selection with party members running NextKey.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
    else
        selectBtn:Disable()
        selectBtn:SetAlpha(0.4)
        selectBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Only the party leader can select a key.")
            GameTooltip:Show()
        end)
    end
    selectBtn:SetScript("OnLeave", GameTooltip_Hide)

    local deleteBtn = nil
    if isFakePlayer then
        deleteBtn = NextKey222.UIComponents:CreateNativeButton(frame, "select_compact")
        deleteBtn:SetText("Del")
        deleteBtn:SetSize(52, 18)
        deleteBtn:ClearAllPoints()
        deleteBtn:SetPoint("RIGHT", selectBtn, "LEFT", -4, 0)
        deleteBtn:SetScript("OnClick", function()
            UI:HandleDeleteFakePlayer(ownerName)
        end)
        deleteBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove this fake player")
            GameTooltip:Show()
        end)
        deleteBtn:SetScript("OnLeave", GameTooltip_Hide)
        trackAuxFrame(UI, deleteBtn)
    end

    local textRightAnchor = deleteBtn or selectBtn
    mainText.frame:ClearAllPoints()
    mainText.frame:SetPoint("TOPLEFT", roleIcon, "TOPRIGHT", 4, 0)
    mainText.frame:SetPoint("RIGHT", textRightAnchor, "LEFT", -8, 0)
    local leftEdge = roleIcon and roleIcon:GetRight() or 0
    local rightEdge = textRightAnchor and textRightAnchor:GetLeft() or 0
    local calculatedWidth = rightEdge > leftEdge and (rightEdge - leftEdge - 8) or nil
    if calculatedWidth and calculatedWidth > 0 then
        if mainText.SetWidth then
            mainText:SetWidth(calculatedWidth)
        end
        if mainText.frame.SetWidth then
            mainText.frame:SetWidth(calculatedWidth)
        end
        if mainText.label and mainText.label.SetWidth then
            mainText.label:SetWidth(calculatedWidth)
        end
    else
        local fallbackWidth = frame:GetWidth() - selectBtn:GetWidth() - 16
        if deleteBtn then
            fallbackWidth = fallbackWidth - deleteBtn:GetWidth() - 4
        end
        fallbackWidth = math.max(fallbackWidth, 0)
        if mainText.SetWidth then
            mainText:SetWidth(fallbackWidth)
        end
        if mainText.frame.SetWidth then
            mainText.frame:SetWidth(fallbackWidth)
        end
        if mainText.label and mainText.label.SetWidth then
            mainText.label:SetWidth(fallbackWidth)
        end
    end
    if mainText.label and mainText.label.SetWordWrap then
        mainText.label:SetWordWrap(false)
    end

    if showCompactIO and compactIORange then
        local anchorButton = deleteBtn or selectBtn
        local expectedGain = compactIORange.expected or 0
        local hasPotentialGain = expectedGain > 0
        
        local ioGainText = NextKey222.UIComponents:CreateText("small", frame, {
            text = string.format("|cff%s+%d IO|r",
                hasPotentialGain and "00ff00" or "999999",
                math.floor(expectedGain)),
            fontObject = GameFontNormalSmall,
            justifyH = "RIGHT",
            color = hasPotentialGain and {0, 1, 0} or {0.6, 0.6, 0.6}
        })
        ioGainText.frame:SetPoint("RIGHT", anchorButton, "LEFT", -6, 0)

        Debug:Dev("ui", "[Compact IO Tooltip] Creating tooltip button for compact IO gain text")
        Debug:Dev("ui", "[Compact IO Tooltip] compactIORange exists:", compactIORange ~= nil)
        
        -- Create native button frame for reliable mouse event handling (same as regular view)
        local ioGainButton = CreateFrame("Button", nil, frame)
        ioGainButton:SetPoint("TOPLEFT", ioGainText.frame, "TOPLEFT", -2, 2)
        ioGainButton:SetPoint("BOTTOMRIGHT", ioGainText.frame, "BOTTOMRIGHT", 2, -2)
        ioGainButton:SetFrameLevel(frame:GetFrameLevel() + 2) -- Higher frame level to be above everything
        ioGainButton:EnableMouse(true) -- CRITICAL: Enable mouse events
        ioGainButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        
        -- PERFORMANCE FIX: Throttle compact tooltip updates to prevent FPS drops
        local lastCompactTooltipUpdate = 0
        local COMPACT_TOOLTIP_THROTTLE = 0.1 -- 100ms minimum between updates
        
        ioGainButton:SetScript("OnEnter", function(btn)
            local now = GetTime()
            if now - lastCompactTooltipUpdate < COMPACT_TOOLTIP_THROTTLE then
                return -- Throttle tooltip updates
            end
            lastCompactTooltipUpdate = now
            
            Debug:Dev("ui", "[Compact IO Tooltip] Mouse entered compact button - showing tooltip")
            if NextKey222.Tooltips then
                NextKey222.Tooltips:ShowIOGainTooltipCentralized(btn, keyInfo, entry, compactIORange)
            end
        end)
        
        ioGainButton:SetScript("OnLeave", function(btn)
            Debug:Dev("ui", "[Compact IO Tooltip] Mouse left compact button - hiding tooltip")
            GameTooltip_Hide()
        end)
        
        ioGainButton:Show()
        trackAuxFrame(UI, ioGainButton)
        
        Debug:Dev("ui", "[Compact IO Tooltip] Native compact button created - frame level:", ioGainButton:GetFrameLevel())
        Debug:Dev("ui", "[Compact IO Tooltip] Compact button visible:", ioGainButton:IsVisible() and "YES" or "NO")
        Debug:Dev("ui", "[Compact IO Tooltip] Compact button mouse enabled:", ioGainButton:IsMouseEnabled() and "YES" or "NO")
    end
end

-- MARK: Initialization

--- Initializes the KeystoneCards module
--- @return boolean true if initialization succeeded
function KeystoneCards:Initialize()
    Debug:Dev("keystonecards", "KeystoneCards module initialized")
    return true
end

return KeystoneCards