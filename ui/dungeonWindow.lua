local _, NextKey222 = ...
local Debug = NextKey222 and NextKey222.Debug
local AceGUI = LibStub and LibStub("AceGUI-3.0")

-- MARK: Module Definition

--- DungeonWindow - Completely independent dungeon view window
--- No shared state with keystone window
--- Manages its own frame, controls, and rendering
local DungeonWindow = {
    frame = nil,
    resultsFrame = nil,
    controls = nil,
    sortDropdown = nil,
    totalScoreLabel = nil,
    
    -- Context for sorting system
    context = nil,  -- Will be set to Sorting.contexts.DUNGEONS during initialization
}

NextKey222.DungeonWindow = DungeonWindow
NextKey222.RegisterModule("DungeonWindow", DungeonWindow)

-- MARK: Private Helpers

local function log_dev(...)
    if Debug and Debug.Dev then
        Debug:Dev("dungeonwindow", ...)
    end
end

local function log_error(...)
    if Debug and Debug.Error then
        Debug:Error(...)
    end
end

local function trackAuxFrame(frame)
    if NextKey222.Utilities then
        NextKey222.Utilities:TrackAuxFrame(frame)
    end
end

-- MARK: Frame Creation

--- Creates the dedicated dungeon window frame
function DungeonWindow:CreateFrame()
    if self.frame then
        log_dev("Dungeon window frame already exists")
        return self.frame
    end

    if not AceGUI then
        log_error("DungeonWindow: AceGUI-3.0 not available")
        return
    end

    log_dev("Creating independent dungeon window frame")

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("NextKey - Dungeons")
    frame:SetLayout("Flow")
    frame:SetWidth(NextKey222.UIConfig.WINDOW.WIDTH or 600)
    frame:SetHeight(NextKey222.UIConfig.WINDOW.DUNGEON_HEIGHT or 788)
    frame:EnableResize(false)
    frame:Hide()
    
    -- Set status text using centralized UIConfig system
    local UIConfig = NextKey222 and NextKey222.UIConfig
    if UIConfig and UIConfig.GetStatusMessage then
        frame:SetStatusText(UIConfig:GetStatusMessage("DUNGEON_WINDOW"))
    else
        -- Fallback if UIConfig not available
        local version = "v0.5.32"
        if NextKey and NextKey.version_full then
            version = NextKey.version_full
        elseif NextKey and NextKey.version then
            version = "v" .. NextKey.version
        end
        frame:SetStatusText(version)
    end

    -- Apply backdrop with configurable opacity
    if NextKey222.UIComponents then
        local opacity = NextKey222.UIConfig and NextKey222.UIConfig.WINDOW
            and NextKey222.UIConfig.WINDOW.BACKDROP_OPACITY or 0.95
        
        NextKey222.UIComponents:ConfigureBackdrop(frame, "dialog", {
            colorScheme = "dark",
            customBgColor = {0, 0, 0, opacity}
        })
    end

    -- Close callback
    frame:SetCallback("OnClose", function(widget)
        self:OnClose()
    end)

    self.frame = frame
    log_dev("Dungeon window frame created")

    -- Create header with text and refresh button (matches main window)
    self:CreateHeader()

    -- Create controls (sort dropdown + total score label)
    self:CreateControls()

    -- Create dedicated resultsFrame
    self:CreateResultsFrame()

    -- Create back button
    self:CreateBackButton()

    return frame
end

--- Creates header with text and refresh button (matches main window)
function DungeonWindow:CreateHeader()
    if not self.frame or not NextKey222.UIComponents then
        return
    end

    local headerContainer = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })
    
    local headerText = NextKey222.UIComponents:CreateText("body", nil, {
        text = "Choose a sort mode; results area below.",
        width = 520,
    })
    headerContainer:AddChild(headerText)
    
    -- FUNDAMENTAL FIX: Use AceGUI Icon widget instead of Button + manual texture
    -- This prevents texture leakage because AceGUI properly manages Icon lifecycle
    local icon = NextKey222.UIComponents:CreateIcon("small", nil, {
        imagePath = "Interface\\Icons\\Ability_Repair",
        size = { 28, 28 },
        onClick = function()
            self:Render()
        end,
        onEnter = function(widget)
            GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
            GameTooltip:SetText("Refresh Data", 1, 1, 1)
            GameTooltip:AddLine("Update dungeon scores", nil, nil, nil, true)
            GameTooltip:Show()
        end,
        onLeave = function()
            GameTooltip:Hide()
        end,
    })
    
    headerContainer:AddChild(icon)
    self.frame:AddChild(headerContainer)
    
    -- Store references for cleanup
    self.headerContainer = headerContainer
    self.refreshButton = icon
    
    log_dev("Dungeon window header created")
end

--- Creates dungeon-specific controls
function DungeonWindow:CreateControls()
    if not self.frame or not NextKey222.UIComponents then
        return
    end

    local controlsContainer = NextKey222.UIComponents:CreateFrame("container", nil, {
        fullWidth = true,
        layout = "Flow",
    })

    -- Sort dropdown
    local dropdown = NextKey222.UIComponents:CreateDropdown("primary", nil, {
        label = "Sort Mode",
        width = 200,
        onValueChanged = function(_, _, key)
            self:OnSortChanged(key)
        end,
    })

    -- Set dungeon-specific sort options
    dropdown:SetList({
        Alphabetical = "Alphabetical",
        HighestIO = "Highest IO Score",
        LowestIO = "Lowest IO Score"
    })

    -- Get current sort mode from saved variables
    local currentSort = self:GetCurrentSortMode()
    dropdown:SetValue(currentSort)

    controlsContainer:AddChild(dropdown)
    self.sortDropdown = dropdown

    -- Total score label
    local scoreLabel = NextKey222.UIComponents:CreateText("large", nil, {
        text = "",
        width = 120,
        fontObject = GameFontNormalLarge,
        color = { 1, 0.8, 0 },
    })

    controlsContainer:AddChild(scoreLabel)
    self.totalScoreLabel = scoreLabel

    self.frame:AddChild(controlsContainer)
    self.controls = controlsContainer

    log_dev("Dungeon controls created")
end

--- Creates dedicated resultsFrame for dungeon cards
function DungeonWindow:CreateResultsFrame()
    if not self.frame or not NextKey222.UIComponents then
        return
    end

    local scroll = NextKey222.UIComponents:CreateScrollFrame("primary", nil, {
        fullWidth = true,
        fullHeight = false,
        layout = "List",
    })

    if NextKey222.UIConfig and NextKey222.UIConfig.WINDOW then
        local height = NextKey222.UIConfig.WINDOW.SCROLL_FRAME_HEIGHT_DUNGEON or 450
        scroll:SetHeight(height)
    end

    self.frame:AddChild(scroll)
    self.resultsFrame = scroll

    log_dev("Dungeon window resultsFrame created")
end

--- Creates back to keystones button
function DungeonWindow:CreateBackButton()
    if not self.frame or not NextKey222.UIComponents then
        return
    end

    local btn = NextKey222.UIComponents:CreateButton("primary_action", nil, {
        text = "Back to Keystones",
        fullWidth = true,
        size = {
            (NextKey222.UIConfig and NextKey222.UIConfig.WINDOW and NextKey222.UIConfig.WINDOW.WIDTH or 580),
            (NextKey222.UIConfig and NextKey222.UIConfig.WINDOW and NextKey222.UIConfig.WINDOW.BOTTOM_BUTTON_HEIGHT or 24),
        },
        onClick = function()
            -- Close dungeon window first
            if self.frame and self.frame.Hide then
                self.frame:Hide()
            end
            
            -- Then open keystone window
            if NextKey222.UI and NextKey222.UI.ShowMainFrame then
                NextKey222.UI:ShowMainFrame()
            end
        end,
    })

    self.frame:AddChild(btn)
    log_dev("Back button created")
end

-- MARK: Rendering

--- Renders dungeon cards (completely independent of keystone window)
function DungeonWindow:Render()
    if not self.resultsFrame then
        log_error("DungeonWindow:Render - no resultsFrame")
        return
    end

    -- Clear existing content
    self.resultsFrame:ReleaseChildren()
    -- NOTE: Do NOT call FrameRegistry:ClearAll() here - it's shared with the keystone window
    -- and would clear frames from both windows. Only clear on window close.

    -- Get current season dungeons
    local dungeons = NextKey222.Addon.PortalData and NextKey222.Addon.PortalData.dungeons or {}

    if not next(dungeons) then
        local none = NextKey222.UIComponents:CreateText("body", nil, {
            text = "No dungeon data available for current season.",
            width = nil
        })
        self.resultsFrame:AddChild(none)
        return
    end

    -- Sort dungeons
    local sortedDungeons = self:SortDungeons(dungeons)

    -- Calculate and display total IO score
    local totalIOScore = NextKey222.Addon:GetRaiderIOTotalScore()
    if self.totalScoreLabel and NextKey222.ScoreCalculations then
        self.totalScoreLabel:SetText(NextKey222.ScoreCalculations:FormatColoredTotalScore(totalIOScore))
    end

    log_dev("Rendering", #sortedDungeons, "dungeon cards")

    -- Render each dungeon card
    for i, dungeon in ipairs(sortedDungeons) do
        local success = NextKey222.SafeRun(function()
            self:RenderDungeonCard(dungeon.id, dungeon.data)
        end, "Render dungeon card: " .. dungeon.data.name)

        if not success then
            log_error("Failed to render dungeon card:", dungeon.data.name)
        end
    end

    log_dev("Finished rendering all dungeon cards")
end

--- Sorts dungeons based on current sort mode
function DungeonWindow:SortDungeons(dungeons)
    local sorted = {}

    for dungeonID, data in pairs(dungeons) do
        local ioScore = self:GetDungeonIOScore(dungeonID)
        table.insert(sorted, {id = dungeonID, data = data, ioScore = ioScore})
    end

    local currentSort = self:GetCurrentSortMode()

    if currentSort == "Alphabetical" then
        table.sort(sorted, function(a, b) return a.data.name < b.data.name end)
    elseif currentSort == "HighestIO" then
        table.sort(sorted, function(a, b) return (a.ioScore or 0) > (b.ioScore or 0) end)
    elseif currentSort == "LowestIO" then
        table.sort(sorted, function(a, b) return (a.ioScore or 0) < (b.ioScore or 0) end)
    else
        -- Default to alphabetical
        table.sort(sorted, function(a, b) return a.data.name < b.data.name end)
    end

    return sorted
end

--- Renders a single dungeon card
function DungeonWindow:RenderDungeonCard(dungeonID, dungeonData)
    local container = NextKey222.UIComponents:CreateCardContainer(NextKey222.UIConfig.CARD.HEIGHT_DUNGEON, false)
    self.resultsFrame:AddChild(container)

    local cardFrame = container.cardFrame or container.frame
    NextKey222.UIComponents:CreateBackdrop(cardFrame, "keystone")
    cardFrame:Show()
    trackAuxFrame(cardFrame)

    log_dev("Rendering dungeon card for", dungeonData.name, "ID:", dungeonID)

    -- Get player's best data
    local playerScore = self:GetDungeonScore(dungeonID)
    local bestLevel = self:GetBestLevel(dungeonID)
    local ioScore = self:GetDungeonIOScore(dungeonID)

    -- Create dungeon icon
    local dungeonIcon = CreateFrame("Frame", nil, cardFrame)
    dungeonIcon:SetSize(NextKey222.UIConfig.ICON.SIZE, NextKey222.UIConfig.ICON.SIZE)
    dungeonIcon:SetPoint("TOPLEFT", cardFrame, "TOPLEFT", 12, -15)
    dungeonIcon:Show()

    local texture = dungeonIcon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:Show()

    -- Try to get icon texture
    local iconSet = false

    if dungeonData.spellID and dungeonData.spellID > 0 then
        local spellTexture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(dungeonData.spellID)
        if spellTexture and spellTexture ~= "" then
            texture:SetTexture(spellTexture)
            iconSet = true
        end
    end

    if not iconSet and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local challengeModeMapID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(dungeonID)
        if challengeModeMapID then
            local _, _, _, iconFileID = C_ChallengeMode.GetMapUIInfo(challengeModeMapID)
            if iconFileID and iconFileID > 0 then
                texture:SetTexture(iconFileID)
                iconSet = true
            end
        end
    end

    if not iconSet and dungeonData.mapArtID and type(dungeonData.mapArtID) == "number" and dungeonData.mapArtID > 0 then
        texture:SetTexture(dungeonData.mapArtID)
        iconSet = true
    end

    if not iconSet then
        texture:SetTexture("Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider")
    end

    -- Dungeon name
    local nameLabel = NextKey222.UIComponents:CreateText("body", cardFrame, {
        text = dungeonData.name,
        fontObject = GameFontNormal,
        justifyH = "LEFT"
    })
    nameLabel.frame:SetPoint("TOPLEFT", dungeonIcon, "TOPRIGHT", 8, 0)
    nameLabel.frame:SetPoint("RIGHT", cardFrame, "RIGHT", -260, 0)
    nameLabel.frame:Show()

    -- IO Score and level display
    local scoreToDisplay = ioScore or playerScore or 0
    local infoText = ""
    local infoColor = {0.7, 0.7, 0.7}

    if scoreToDisplay > 0 then
        local level, chests = self:GetDungeonLevelAndChests(dungeonID)
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
        infoColor = self:GetDungeonScoreColor(scoreToDisplay)
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
    scoreLabel.frame:Show()

    -- Loot button
    local lootBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "select")
    lootBtn:SetText("Loot")
    lootBtn:SetSize(75, 24)
    lootBtn:SetPoint("TOPRIGHT", cardFrame, "TOPRIGHT", -12, -15)
    lootBtn:SetScript("OnClick", function()
        NextKey222.Addon:HandleLootClick(dungeonID, dungeonData)
    end)
    lootBtn:Show()
    trackAuxFrame(lootBtn)

    -- Teleport button
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
            dungeonName = dungeonData.name
        }
        NextKey222.Addon:SetTeleportTargetKey(fakeKeyInfo, { broadcast = false })
        NextKey222.Addon:ToggleTeleportWindow()
    end)
    teleBtn:Show()
    trackAuxFrame(teleBtn)

    -- Preference buttons
    local preference = NextKey222.ProfilesService:GetDungeonPreference(dungeonID)

    local dislikeBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "small")
    dislikeBtn:SetText(preference and preference.disliked and "|cFFFF0000-|r" or "-")
    dislikeBtn:SetSize(30, 24)
    dislikeBtn:SetPoint("RIGHT", teleBtn, "LEFT", -4, 0)
    dislikeBtn:SetScript("OnClick", function()
        NextKey222.ProfilesService:ToggleDungeonPreference(dungeonID, false)
        self:Render()
    end)
    dislikeBtn:Show()
    trackAuxFrame(dislikeBtn)

    local likeBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "small")
    likeBtn:SetText(preference and preference.liked and "|cFF00FF00+|r" or "+")
    likeBtn:SetSize(30, 24)
    likeBtn:SetPoint("RIGHT", dislikeBtn, "LEFT", -4, 0)
    likeBtn:SetScript("OnClick", function()
        NextKey222.ProfilesService:ToggleDungeonPreference(dungeonID, true)
        self:Render()
    end)
    likeBtn:Show()
    trackAuxFrame(likeBtn)

    log_dev("Completed rendering dungeon card for", dungeonData.name)
end

-- MARK: Score Calculation Helpers

function DungeonWindow:GetDungeonScore(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetDungeonScore(dungeonID)
    end
    return 0
end

function DungeonWindow:GetBestLevel(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetBestLevel(dungeonID)
    end
    return 0
end

function DungeonWindow:GetDungeonIOScore(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetDungeonIOScore(dungeonID)
    end
    return 0
end

function DungeonWindow:GetDungeonLevelAndChests(dungeonID)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetDungeonLevelAndChests(dungeonID)
    end
    return 0, 0
end

function DungeonWindow:GetDungeonScoreColor(score)
    if NextKey222.ScoreCalculations then
        return NextKey222.ScoreCalculations:GetDungeonScoreColor(score)
    end
    return {0.5, 0.5, 0.5}
end

-- MARK: Public Interface

--- Shows the dungeon window
function DungeonWindow:Show()
    if not self.frame then
        self:CreateFrame()
    end

    if not self.frame then
        log_error("DungeonWindow:Show - frame creation failed")
        return
    end

    self.frame:Show()
    log_dev("Dungeon window shown")

    -- Render dungeon cards
    self:Render()
end

--- Hides the dungeon window
function DungeonWindow:Hide()
    if self.frame then
        self.frame:Hide()
        log_dev("Dungeon window hidden")
    end
end

--- Toggles the dungeon window
function DungeonWindow:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

--- Checks if dungeon window is visible
function DungeonWindow:IsVisible()
    return self.frame and self.frame:IsShown() or false
end

-- MARK: Event Handlers

function DungeonWindow:OnClose()
    log_dev("Dungeon window closed")

    -- Clean up dungeon window's own frames only
    if self.resultsFrame and self.resultsFrame.ReleaseChildren then
        self.resultsFrame:ReleaseChildren()
    end

    -- Release frame
    if AceGUI and self.frame then
        AceGUI:Release(self.frame)
    end

    -- Clear all references to prevent reuse on next open
    self.frame = nil
    self.resultsFrame = nil
    self.controls = nil
    self.sortDropdown = nil
    self.totalScoreLabel = nil
    self.headerContainer = nil
    self.refreshButton = nil
    
    -- If BOTH windows are now closed, clean up the shared FrameRegistry
    local keystoneWindowClosed = not NextKey222.UI or not NextKey222.UI.mainFrame or not NextKey222.UI.mainFrame:IsShown()
    if keystoneWindowClosed and NextKey222.FrameRegistry and NextKey222.FrameRegistry.ClearAll then
        log_dev("Both windows closed - clearing shared FrameRegistry")
        NextKey222.FrameRegistry:ClearAll()
    end
end

function DungeonWindow:OnSortChanged(sortMode)
    -- Save sort mode
    self:SetCurrentSortMode(sortMode)

    -- Re-render
    self:Render()
end

-- MARK: Saved Variables

function DungeonWindow:GetCurrentSortMode()
    local addon = NextKey222.Addon
    if addon and addon.db and addon.db.char and addon.db.char.dungeonSortMode then
        return addon.db.char.dungeonSortMode
    end
    return "Alphabetical"
end

function DungeonWindow:SetCurrentSortMode(mode)
    local addon = NextKey222.Addon
    if addon and addon.db and addon.db.char then
        addon.db.char.dungeonSortMode = mode
    end
end

-- MARK: Initialization

function DungeonWindow:Initialize()
    -- Set context for sorting system
    if NextKey222.Sorting and NextKey222.Sorting.contexts then
        self.context = NextKey222.Sorting.contexts.DUNGEONS
        log_dev("DungeonWindow context set to:", self.context)
    else
        log_dev("WARNING: Sorting service not available during DungeonWindow initialization")
    end
    
    log_dev("DungeonWindow module initialized")
    return true
end

return DungeonWindow