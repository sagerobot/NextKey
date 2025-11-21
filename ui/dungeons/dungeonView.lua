-- MARK: Module Definition
local _, NextKey222 = ...

--- DungeonView Module
--- Contains dungeon card rendering functions for displaying seasonal dungeons
--- Extracted from ui/main.lua lines 2608-2933
local DungeonView = {}
NextKey222.DungeonView = DungeonView

-- Register with module system (MANDATORY)
NextKey222.RegisterModule("DungeonView", DungeonView)

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

--- Renders dungeon information cards for the current season
--- @param UI table The UI module instance
--- Displays dungeon names, best scores, levels, and completion data
function DungeonView:RenderDungeonCards(UI)
    if not UI.resultsFrame then
        return
    end

    -- Clear existing content completely
    UI:ClearAuxFrames()
    UI.resultsFrame:ReleaseChildren()
    
    -- Get current season dungeons
    local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}
    local seasonName = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.name or "Unknown Season"
    
    -- Update status text (removed season text to save space)
    local count = 0
    for _ in pairs(dungeons) do count = count + 1 end
    Debug:Dev("ui", string.format("Dungeon Cards: Mode: Dungeons | Count: %d", count))
    
    if not next(dungeons) then
        local none = NextKey222.UIComponents:CreateText("body", nil, {
            text = "No dungeon data available for current season.",
            width = nil -- Full width
        })
        UI.resultsFrame:AddChild(none)
        return
    end
    
    -- Sort dungeons based on current sort mode
    local sortedDungeons = {}
    for dungeonID, data in pairs(dungeons) do
        -- Get IO score for each dungeon for sorting
        local ioScore = UI:GetRaiderIODungeonScore(dungeonID)
        table.insert(sortedDungeons, {id = dungeonID, data = data, ioScore = ioScore})
    end
    
    -- Apply sorting based on current mode
    local currentSort = UI:GetCurrentSortMode()
    if currentSort == "Alphabetical" then
        table.sort(sortedDungeons, function(a, b) return a.data.name < b.data.name end)
    elseif currentSort == "HighestIO" then
        table.sort(sortedDungeons, function(a, b) return (a.ioScore or 0) > (b.ioScore or 0) end)
    elseif currentSort == "LowestIO" then
        table.sort(sortedDungeons, function(a, b) return (a.ioScore or 0) < (b.ioScore or 0) end)
    else
        -- Default to alphabetical if unknown sort mode
        table.sort(sortedDungeons, function(a, b) return a.data.name < b.data.name end)
    end
    
    -- Calculate total IO score from all dungeons
    local totalIOScore = NextKey222.Addon:GetRaiderIOTotalScore()
    
    -- Update total score display
    if UI.totalScoreLabel then
        UI.totalScoreLabel:SetText(UI:FormatColoredTotalScore(totalIOScore))
    end
    
    -- Create enhanced dungeon cards with preferences
    local useCompact = true -- Always use compact for better layout
    -- Use centralized height calculation variables (use dungeon-specific height)
    local expectedHeight = #sortedDungeons * NextKey222.UIConfig.CARD.HEIGHT_DUNGEON + NextKey222.UIConfig.CARD.HEADER_PADDING
    
    Debug:Dev("ui", " Rendering", #sortedDungeons, "enhanced dungeons with preferences")
    Debug:Dev("ui", " Expected total height:", expectedHeight, "px (window height: 640px)")
    Debug:Dev("ui", " Card height: 52px, with icons, IO scores, and preference buttons")
    Debug:Dev("ui", " Total IO Score:", totalIOScore or 0)
    
    for i, dungeon in ipairs(sortedDungeons) do
        Debug:Dev("ui", string.format("Rendering dungeon %d/%d: %s (ID: %d)", i, #sortedDungeons, dungeon.data.name, dungeon.id))
        
        local success = NextKey222.SafeRun(function()
            if useCompact then
                self:AddDungeonRowCompact(UI, dungeon.id, dungeon.data)
            else
                self:AddDungeonRow(UI, dungeon.id, dungeon.data)
            end
        end, "Render dungeon card: " .. dungeon.data.name)
        
        if not success then
            Debug:Error("Failed to render dungeon card:", dungeon.data.name)
        end
    end
    
    Debug:Dev("ui", "Finished rendering all dungeon cards")
end

--- Enhanced dungeon card with icons and IO scores - matching keystone card pattern
--- @param UI table The UI module instance
--- @param dungeonID number The dungeon ID
--- @param dungeonData table The dungeon data
function DungeonView:AddDungeonRowCompact(UI, dungeonID, dungeonData)
    -- Use CreateCardContainer like keystones do - creates proper backdrop support
    -- Use shorter height for dungeon cards (64px vs 88px for keystones)
    local container = NextKey222.UIComponents:CreateCardContainer(NextKey222.UIConfig.CARD.HEIGHT_DUNGEON, false)
    UI.resultsFrame:AddChild(container)
    
    -- Get the dedicated cardFrame and apply backdrop for visible borders (like keystone cards)
    local cardFrame = container.cardFrame or container.frame
    NextKey222.UIComponents:CreateBackdrop(cardFrame, "keystone")
    cardFrame:Show()  -- Explicitly show the cardFrame
    trackAuxFrame(UI, cardFrame)
    
    Debug:Dev("ui", "Rendering dungeon card for", dungeonData.name, "ID:", dungeonID)
    
    -- Get player's best data and IO score
    local playerScore = UI:GetDungeonScore(dungeonID)
    local bestLevel = UI:GetBestLevel(dungeonID)
    local ioScore = UI:GetDungeonIOScore(dungeonID)
    
    -- Create dungeon icon using native frame (like keystone class icons)
    local dungeonIcon = CreateFrame("Frame", nil, cardFrame)
    dungeonIcon:SetSize(NextKey222.UIConfig.ICON.SIZE, NextKey222.UIConfig.ICON.SIZE)
    -- Position dungeon icon with simple vertical centering for 75px card height
    dungeonIcon:SetPoint("TOPLEFT", cardFrame, "TOPLEFT", 12, -15)  -- 15px from top for 75px card centering
    dungeonIcon:Show()  -- Explicitly show the icon frame
    
    local texture = dungeonIcon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:Show()  -- Explicitly show the texture
    
    -- Try to get icon texture from spell ID or map art ID
    local iconSet = false
    
    -- Try spell texture first
    if dungeonData.spellID and dungeonData.spellID > 0 then
        local spellTexture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(dungeonData.spellID)
        if spellTexture and spellTexture ~= "" then
            texture:SetTexture(spellTexture)
            iconSet = true
        end
    end
    
    -- Try ChallengeMode API if spell didn't work
    if not iconSet and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local challengeModeMapID = NextKey222.DungeonUtils:ConvertToRaiderIOKeystoneID(dungeonID)
        if challengeModeMapID then
            local _, _, _, iconFileID = C_ChallengeMode.GetMapUIInfo(challengeModeMapID)
            if iconFileID and iconFileID > 0 then
                texture:SetTexture(iconFileID)
                iconSet = true
            end
        end
    end
    
    -- Try mapArtID as last resort
    if not iconSet and dungeonData.mapArtID and type(dungeonData.mapArtID) == "number" and dungeonData.mapArtID > 0 then
        texture:SetTexture(dungeonData.mapArtID)
        iconSet = true
    end
    
    -- Fallback to default dungeon icon
    if not iconSet then
        texture:SetTexture("Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider")
    end
    
    -- Dungeon name positioned relative to icon (simple vertical alignment)
    local nameLabel = NextKey222.UIComponents:CreateText("body", cardFrame, {
        text = dungeonData.name,
        fontObject = GameFontNormal,
        justifyH = "LEFT"
    })
    nameLabel.frame:SetPoint("TOPLEFT", dungeonIcon, "TOPRIGHT", 8, 0)
    nameLabel.frame:SetPoint("RIGHT", cardFrame, "RIGHT", -260, 0)
    nameLabel.frame:Show()  -- Explicitly show text
    
    -- IO Score and level display
    local scoreToDisplay = ioScore or playerScore or 0
    local infoText = ""
    local infoColor = {0.7, 0.7, 0.7}
    
    if scoreToDisplay > 0 then
        local level, chests = UI:GetDungeonLevelAndChests(dungeonID)
        local chestIndicator = ""
        if level > 0 then
            if chests >= 3 then
                chestIndicator = " | +++" .. level
            elseif chests >= 2 then
                chestIndicator = " | ++" .. level
            elseif chests >= 1 then
                chestIndicator = " | +" .. level
            else
                chestIndicator = " | " .. level
            end
        end
        infoText = string.format("%.0f IO%s", scoreToDisplay, chestIndicator)
        infoColor = UI:GetDungeonScoreColor(scoreToDisplay)
    else
        infoText = "0 IO"
        infoColor = {0.5, 0.5, 0.5}
    end
    
    local scoreLabel = NextKey222.UIComponents:CreateText("small", cardFrame, {
        text = infoText,
        fontObject = GameFontNormalSmall,
        justifyH = "LEFT"
    })
    scoreLabel.frame:SetPoint("TOPLEFT", nameLabel.frame, "BOTTOMLEFT", 0, -4)
    scoreLabel.frame:SetPoint("RIGHT", nameLabel.frame, "RIGHT", 0, 0)
    scoreLabel:SetColor(infoColor[1], infoColor[2], infoColor[3])
    scoreLabel.frame:Show()  -- Explicitly show score label
    
    -- Buttons positioned on the right with simple vertical centering
    local lootBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "select")
    lootBtn:SetText("Loot")
    lootBtn:SetSize(75, 24)
    -- Simple vertical centering for 75px card height
    lootBtn:SetPoint("TOPRIGHT", cardFrame, "TOPRIGHT", -12, -15)  -- 15px from top for 75px card centering
    lootBtn:SetScript("OnClick", function()
        NextKey222.Addon:HandleLootClick(dungeonID, dungeonData)
    end)
    lootBtn:Show()  -- Explicitly show button
    trackAuxFrame(UI, lootBtn)
    
    local teleBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "select")
    teleBtn:SetText("Teleport")
    teleBtn:SetSize(100, 24)
    teleBtn:SetPoint("RIGHT", lootBtn, "LEFT", -4, 0)
    teleBtn:SetScript("OnClick", function()
        local fakeKeyInfo = {
            dungeonID = dungeonID,
            level = 0,
            ownerName = "Dungeon Portal",
            ownerShort = "Portal",
            source = "dungeon_portal",
            class = "MAGE",
            io = 0,
            dungeonName = dungeonData.name -- Pass the correct dungeon name
        }
        NextKey222.Addon:SetTeleportTargetKey(fakeKeyInfo, { broadcast = false })
        NextKey222.Addon:ToggleTeleportWindow()
    end)
    teleBtn:Show()  -- Explicitly show button
    trackAuxFrame(UI, teleBtn)
    
    -- Preference buttons (smaller, positioned to the left of Teleport, vertically centered)
    local preference = NextKey222.ProfilesService:GetDungeonPreference(dungeonID)
    
    local dislikeBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "small")
    dislikeBtn:SetText(preference and preference.disliked and "|cFFFF0000-|r" or "-")
    dislikeBtn:SetSize(30, 24)
    -- Align with teleport button for consistent vertical centering
    dislikeBtn:SetPoint("RIGHT", teleBtn, "LEFT", -4, 0)
    dislikeBtn:SetScript("OnClick", function()
        NextKey222.ProfilesService:ToggleDungeonPreference(dungeonID, false)
        self:RenderDungeonCards(UI)
    end)
    dislikeBtn:Show()  -- Explicitly show button
    trackAuxFrame(UI, dislikeBtn)
    
    local likeBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "small")
    likeBtn:SetText(preference and preference.liked and "|cFF00FF00+|r" or "+")
    likeBtn:SetSize(30, 24)
    -- Keep like button aligned with dislike button
    likeBtn:SetPoint("RIGHT", dislikeBtn, "LEFT", -4, 0)
    likeBtn:SetScript("OnClick", function()
        NextKey222.ProfilesService:ToggleDungeonPreference(dungeonID, true)
        self:RenderDungeonCards(UI)
    end)
    likeBtn:Show()  -- Explicitly show button
    trackAuxFrame(UI, likeBtn)
    
    Debug:Dev("ui", "Completed rendering dungeon card for", dungeonData.name)
end

--- Renders a full dungeon row (non-compact mode)
--- @param UI table The UI module instance
--- @param dungeonID number The dungeon ID
--- @param dungeonData table The dungeon data
function DungeonView:AddDungeonRow(UI, dungeonID, dungeonData)
    local container = NextKey222.UIComponents:CreateFrame("dialog", nil, {
        layout = "Fill"
    })
    
    -- Get player's best scores for this dungeon
    local playerScore = UI:GetDungeonScore(dungeonID)
    local bestLevel = UI:GetBestLevel(dungeonID)
    
    -- Dungeon name and alias
    local nameText = string.format("%s (%s)", dungeonData.name, dungeonData.alias or "")
    
    -- Score information
    local scoreText = ""
    if playerScore and playerScore > 0 then
        scoreText = string.format("Score: %.0f", playerScore)
        if bestLevel and bestLevel > 0 then
            scoreText = scoreText .. string.format(" | Best: +%d", bestLevel)
        end
    else
        -- Show "Score: 0" instead of "No runs completed" to indicate earned IO
        scoreText = "Score: 0"
    end
    
    -- Loot tracking info (placeholder)
    local lootText = "Loot tracking: Not implemented yet"
    
    local content = NextKey222.UIComponents:CreateFrame("container", nil, {
        layout = "List",
        fullWidth = true
    })
    
    -- Dungeon name using component system
    local nameLabel = NextKey222.UIComponents:CreateText("header", nil, {
        text = nameText,
        width = nil, -- Full width
        fontObject = GameFontNormalLarge
    })
    content:AddChild(nameLabel)
    
    -- Score info with proper coloring using component system
    local scoreLabel = NextKey222.UIComponents:CreateText("body", nil, {
        text = scoreText,
        width = nil -- Full width
    })
    
    -- Apply RaiderIO color to the score if available
    if playerScore and playerScore > 0 and NextKey222.RaiderIO then
        local r, g, b = NextKey222.RaiderIO:GetScoreColor(playerScore)
        scoreLabel:SetColor(r, g, b)
    elseif playerScore == 0 then
        scoreLabel:SetColor(0.5, 0.5, 0.5) -- Gray for zero score
    end
    
    content:AddChild(scoreLabel)
    
    -- Loot info using component system
    local lootLabel = NextKey222.UIComponents:CreateText("small", nil, {
        text = lootText,
        width = nil -- Full width
    })
    content:AddChild(lootLabel)
    
    container:AddChild(content)
    UI.resultsFrame:AddChild(container)
end

-- MARK: Initialization

--- Initializes the DungeonView module
--- @return boolean true if initialization succeeded
function DungeonView:Initialize()
    Debug:Dev("dungeonview", "DungeonView module initialized")
    return true
end

return DungeonView