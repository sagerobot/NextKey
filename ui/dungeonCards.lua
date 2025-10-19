local _, NextKey222 = ...
local NextKey = NextKey222.Addon

if not NextKey then
    return
end

local Utils = NextKey222.Utils
local DungeonCards = NextKey.DungeonCards

if not DungeonCards then
    error("NextKey: DungeonCards module not loaded - check TOC file order")
    return
end

-- Get dropdown menu functions
local UIDropDownMenu_Initialize = _G.UIDropDownMenu_Initialize
local UIDropDownMenu_CreateInfo = _G.UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = _G.UIDropDownMenu_AddButton

-- MARK: UI Components
local UI = {
    frame = nil,
    cards = {},
    sortDropdown = nil,
    totalScore = nil
}

-- MARK: Card Template
-- Use centralized UI configuration
local UIConfig = NextKey222.UIConfig
local CARD_WIDTH = UIConfig.DUNGEON_CARDS.CARD_WIDTH
local CARD_HEIGHT = UIConfig.DUNGEON_CARDS.CARD_HEIGHT
local CARD_PADDING = UIConfig.DUNGEON_CARDS.CARD_PADDING
local CARDS_PER_ROW = UIConfig.DUNGEON_CARDS.CARDS_PER_ROW

local CARD_WIDTH_COMPACT = UIConfig.DUNGEON_CARDS.CARD_WIDTH_COMPACT
local CARD_HEIGHT_COMPACT = UIConfig.DUNGEON_CARDS.CARD_HEIGHT_COMPACT
local CARDS_PER_ROW_COMPACT = UIConfig.DUNGEON_CARDS.CARDS_PER_ROW_COMPACT

-- Helper function to create the score breakdown section
local function createScoreBreakdown(parent, card, isCompact)
    local scoreContainer = NextKey222.UIComponents:CreateFrame("container", parent, {
        layout = "Flow",
        fullWidth = true,
        height = isCompact and 15 or 20
    })

    local fortScore = NextKey222.UIComponents:CreateText(isCompact and "small" or "score", scoreContainer, {
        text = string.format("F: %d", card.fortifiedScore),
        justifyH = "LEFT",
        relativeWidth = 0.5
    })
    scoreContainer:AddChild(fortScore)

    local tyrScore = NextKey222.UIComponents:CreateText(isCompact and "small" or "score", scoreContainer, {
        text = string.format("T: %d", card.tyrannicalScore),
        justifyH = "LEFT",
        relativeWidth = 0.5
    })
    scoreContainer:AddChild(tyrScore)
    
    return scoreContainer
end

-- MARK: Main Frame
function UI:Show()
    if not self.frame then
        -- Create main window using AceGUI Frame with Components styling
        local mainContainer = NextKey222.UIComponents:CreateFrame("window", nil, {
            width = CARD_WIDTH * CARDS_PER_ROW + CARD_PADDING * 3, -- Initial width
            height = 600,
            colorScheme = "standard"
        })
        
        local frame = mainContainer.frame
        frame:SetName("NextKeyDungeonCards")
        frame:SetPoint("CENTER")
        
        self.frame = frame
        self.mainContainer = mainContainer
        
        -- Title
        local title = NextKey222.UIComponents:CreateText("header", frame, { text = "Dungeon Overview", width = 200, justifyH = "LEFT" })
        title.frame:SetPoint("TOPLEFT", 15, -15)
        self.title = title
        
        -- Sort Label
        local sortLabel = NextKey222.UIComponents:CreateText("label", frame, { text = "Sort by:", justifyH = "LEFT" })
        sortLabel.frame:SetPoint("TOPLEFT", title.frame, "BOTTOMLEFT", 0, -10)
        self.sortLabel = sortLabel
        
        -- Sort Dropdown
        local sortDropdown = NextKey222.UIComponents:CreateDropdown("primary", frame, {
            width = 150,
            list = {
                ["alphabetical"] = "Alphabetical", ["highest"] = "Highest Score",
                ["lowest"] = "Lowest Score", ["smart"] = "Smart Sort"
            },
            value = DungeonCards.sortMethod or "smart",
            onValueChanged = function(_, _, value)
                DungeonCards:SetSortMethod(value)
                self:Update()
            end
        })
        sortDropdown.frame:SetPoint("LEFT", sortLabel.frame, "RIGHT", -10, -2)
        self.sortDropdown = sortDropdown
        
        -- Total Score
        local totalScore = NextKey222.UIComponents:CreateText("large", frame, { text = "Total Score: 0", justifyH = "RIGHT", color = {0, 1, 0} })
        totalScore.frame:SetPoint("TOPRIGHT", -15, -15)
        self.totalScore = totalScore
        
        -- Close Button
        local closeBtn = NextKey222.UIComponents:CreateButton("small", frame, { text = "×", onClick = function() self:Hide() end })
        closeBtn.frame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        closeBtn.frame:SetFrameLevel(frame:GetFrameLevel() + 10)
        self.closeButton = closeBtn
        
        -- Scroll Frame
        local scrollFrame = NextKey222.UIComponents:CreateScrollFrame("primary", frame, { layout = "Flow" })
        scrollFrame.frame:SetPoint("TOPLEFT", sortLabel.frame, "BOTTOMLEFT", 0, -10)
        scrollFrame.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
        self.scrollFrame = scrollFrame
        
        mainContainer:AddChild(title)
        mainContainer:AddChild(sortLabel)
        mainContainer:AddChild(sortDropdown)
        mainContainer:AddChild(totalScore)
        mainContainer:AddChild(closeBtn)
        mainContainer:AddChild(scrollFrame)
    end
    
    self:Update()
    self.frame:Show()
end

function UI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Add cleanup function for proper AceGUI container management
function UI:Cleanup()
    if self.mainContainer then
        self.mainContainer:ReleaseChildren()
        self.mainContainer:Release()
        self.mainContainer = nil
    end
    self.frame = nil
    self.title = nil
    self.sortLabel = nil
    self.sortDropdown = nil
    self.totalScore = nil
    self.closeButton = nil
    self.scrollFrame = nil
    self.content = nil
end

function UI:Update()
    if not self.scrollFrame then return end

    local cards = DungeonCards:GetSortedCards()
    local totalScore = 0
    local useCompactMode = NextKey222.ConfigurationContext:ShouldUseCompactMode()

    -- Adjust layout based on mode
    local cardWidth = useCompactMode and CARD_WIDTH_COMPACT or CARD_WIDTH
    local cardHeight = useCompactMode and CARD_HEIGHT_COMPACT or CARD_HEIGHT
    local cardsPerRow = useCompactMode and CARDS_PER_ROW_COMPACT or CARDS_PER_ROW
    local frameWidth = cardWidth * cardsPerRow + CARD_PADDING * (cardsPerRow + 1)

    self.mainContainer:SetWidth(frameWidth)
    self.scrollFrame:SetWidth(frameWidth - 30)
    self.scrollFrame:SetLayout("Flow")

    self.scrollFrame:ReleaseChildren()
    wipe(self.cards)

    for _, cardData in ipairs(cards) do
        -- Use CreateCardContainer like keystone cards do - this creates proper backdrop support
        local cardContainer = NextKey222.UIComponents:CreateCardContainer(cardHeight, useCompactMode)
        
        -- Get the dedicated cardFrame and apply backdrop for visible borders
        local cardFrame = cardContainer.cardFrame or cardContainer.frame
        NextKey222.UIComponents:CreateBackdrop(cardFrame, useCompactMode and "keystone_compact" or "keystone")

        if useCompactMode then
            self:PopulateCardCompact(cardContainer, cardData)
        else
            self:PopulateCard(cardContainer, cardData)
        end

        self.scrollFrame:AddChild(cardContainer)
        self.cards[cardData.dungeonID] = cardContainer
        totalScore = totalScore + cardData.totalScore
    end

    -- Update total score
    if NextKey222.RaiderIO then
        local r, g, b = NextKey222.RaiderIO:GetScoreColor(totalScore)
        self.totalScore:SetText(string.format("Total Score: %d", totalScore))
        self.totalScore:SetColor(r, g, b)
    else
        self.totalScore:SetText(string.format("Total Score: %d", totalScore))
        self.totalScore:SetColor(0, 1, 0)
    end
end

-- Populate card with native frames like keystone cards for consistent styling
function UI:PopulateCard(cardContainer, card)
    -- Use the dedicated cardFrame that has backdrop applied
    local cardFrame = cardContainer.cardFrame or cardContainer.frame
    
    -- Create dungeon icon using native frame (like keystone class icons)
    local dungeonIcon = CreateFrame("Frame", nil, cardFrame)
    dungeonIcon:SetSize(40, 40)
    dungeonIcon:SetPoint("TOPLEFT", cardFrame, "TOPLEFT", 12, -12)
    
    local texture = dungeonIcon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    
    -- Try to get icon texture from spell ID or map art ID
    local iconSet = false
    if NextKey.PortalData and NextKey.PortalData.dungeons and NextKey.PortalData.dungeons[card.dungeonID] then
        local dungeonData = NextKey.PortalData.dungeons[card.dungeonID]
        
        -- Try spell texture first
        if dungeonData.spellID and dungeonData.spellID > 0 then
            local spellTexture = GetSpellTexture(dungeonData.spellID)
            if spellTexture and spellTexture ~= "" then
                texture:SetTexture(spellTexture)
                iconSet = true
            end
        end
        
        -- Try ChallengeMode API if spell didn't work
        if not iconSet and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
            local challengeModeMapID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(card.dungeonID)
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
    end
    
    -- Fallback to default dungeon icon
    if not iconSet then
        texture:SetTexture("Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider")
    end
    
    -- Create text labels positioned relative to icon (like keystone cards)
    local nameText = NextKey222.UIComponents:CreateText("header", cardFrame, {
        text = card.name,
        justifyH = "LEFT"
    })
    nameText.frame:SetPoint("TOPLEFT", dungeonIcon, "TOPRIGHT", 8, -2)
    nameText.frame:SetPoint("RIGHT", cardFrame, "RIGHT", -140, 0)
    
    local bestText = NextKey222.UIComponents:CreateText("body", cardFrame, {
        text = string.format("Best: +%d %s", card.bestLevel, card.bestLevelAffix),
        justifyH = "LEFT"
    })
    bestText.frame:SetPoint("TOPLEFT", nameText.frame, "BOTTOMLEFT", 0, -4)
    bestText.frame:SetPoint("RIGHT", nameText.frame, "RIGHT", 0, 0)
    
    -- Score breakdown
    local scoreText = NextKey222.UIComponents:CreateText("body", cardFrame, {
        text = string.format("F: %d  T: %d", card.fortifiedScore, card.tyrannicalScore),
        justifyH = "LEFT"
    })
    scoreText.frame:SetPoint("TOPLEFT", bestText.frame, "BOTTOMLEFT", 0, -4)
    scoreText.frame:SetPoint("RIGHT", bestText.frame, "RIGHT", 0, 0)
    
    -- Buttons positioned on the right (like keystone select button)
    local lootBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "small")
    lootBtn:SetText("Loot")
    lootBtn:SetSize(60, 24)
    lootBtn:SetPoint("TOPRIGHT", cardFrame, "TOPRIGHT", -12, -12)
    lootBtn:SetScript("OnClick", function()
        NextKey:ShowLootWindow(card.dungeonID)
    end)
    
    local dislikeBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "small")
    dislikeBtn:SetText("-")
    dislikeBtn:SetSize(30, 24)
    dislikeBtn:SetPoint("RIGHT", lootBtn, "LEFT", -4, 0)
    dislikeBtn:SetScript("OnClick", function()
        DungeonCards:ToggleDislike(card.dungeonID, NextKey.playerFullName)
        self:UpdateCard(card.dungeonID)
    end)
    
    local likeBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "small")
    likeBtn:SetText("+")
    likeBtn:SetSize(30, 24)
    likeBtn:SetPoint("RIGHT", dislikeBtn, "LEFT", -4, 0)
    likeBtn:SetScript("OnClick", function()
        DungeonCards:ToggleLike(card.dungeonID, NextKey.playerFullName)
        self:UpdateCard(card.dungeonID)
    end)
    
    -- Tooltip
    cardFrame:SetScript("OnEnter", function()
        local likes, dislikes = DungeonCards:GetPreferenceTooltip(card.dungeonID)
        GameTooltip:SetOwner(cardFrame, "ANCHOR_CURSOR")
        GameTooltip:SetText(card.name)
        if likes ~= "" then GameTooltip:AddLine("Likes: " .. likes, 0, 1, 0) end
        if dislikes ~= "" then GameTooltip:AddLine("Dislikes: " .. dislikes, 1, 0, 0) end
        GameTooltip:Show()
    end)
    cardFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function UI:PopulateCardCompact(cardContainer, card)
    -- Use the dedicated cardFrame that has backdrop applied
    local cardFrame = cardContainer.cardFrame or cardContainer.frame

    -- Create dungeon icon using native frame (compact size)
    local dungeonIcon = CreateFrame("Frame", nil, cardFrame)
    dungeonIcon:SetSize(32, 32)
    dungeonIcon:SetPoint("TOPLEFT", cardFrame, "TOPLEFT", 8, -6)
    
    local texture = dungeonIcon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    
    -- Try to get icon texture from spell ID or map art ID
    local iconSet = false
    if NextKey.PortalData and NextKey.PortalData.dungeons and NextKey.PortalData.dungeons[card.dungeonID] then
        local dungeonData = NextKey.PortalData.dungeons[card.dungeonID]
        
        -- Try spell texture first
        if dungeonData.spellID and dungeonData.spellID > 0 then
            local spellTexture = GetSpellTexture(dungeonData.spellID)
            if spellTexture and spellTexture ~= "" then
                texture:SetTexture(spellTexture)
                iconSet = true
            end
        end
        
        -- Try ChallengeMode API if spell didn't work
        if not iconSet and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
            local challengeModeMapID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(card.dungeonID)
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
    end
    
    -- Fallback to default dungeon icon
    if not iconSet then
        texture:SetTexture("Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider")
    end

    -- Compact single-line text positioned relative to icon
    local infoText = string.format("%s | Best: +%d %s | F: %d T: %d",
        card.name, card.bestLevel, card.bestLevelAffix, card.fortifiedScore, card.tyrannicalScore)
    
    local mainText = NextKey222.UIComponents:CreateText("small", cardFrame, {
        text = infoText,
        justifyH = "LEFT"
    })
    mainText.frame:SetPoint("TOPLEFT", dungeonIcon, "TOPRIGHT", 6, -2)
    mainText.frame:SetPoint("RIGHT", cardFrame, "RIGHT", -12, 0)

    -- Tooltip for preferences
    cardFrame:SetScript("OnEnter", function()
        local likes, dislikes = DungeonCards:GetPreferenceTooltip(card.dungeonID)
        GameTooltip:SetOwner(cardFrame, "ANCHOR_CURSOR")
        GameTooltip:SetText(card.name)
        if likes ~= "" then GameTooltip:AddLine("Likes: " .. likes, 0, 1, 0) end
        if dislikes ~= "" then GameTooltip:AddLine("Dislikes: " .. dislikes, 1, 0, 0) end
        GameTooltip:Show()
    end)
    cardFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function UI:UpdateCard(dungeonID)
    if self.cards[dungeonID] then
        local cardData = DungeonCards:GetCard(dungeonID)
        local oldCard = self.cards[dungeonID]
        local useCompactMode = NextKey222.ConfigurationContext:ShouldUseCompactMode()

        local cardHeight = useCompactMode and CARD_HEIGHT_COMPACT or CARD_HEIGHT

        -- Use CreateCardContainer like the Update function does
        local newCard = NextKey222.UIComponents:CreateCardContainer(cardHeight, useCompactMode)
        
        -- Apply backdrop for visible borders
        local cardFrame = newCard.cardFrame or newCard.frame
        NextKey222.UIComponents:CreateBackdrop(cardFrame, useCompactMode and "keystone_compact" or "keystone")

        if useCompactMode then
            self:PopulateCardCompact(newCard, cardData)
        else
            self:PopulateCard(newCard, cardData)
        end

        self.scrollFrame:ReplaceChild(oldCard, newCard)
        self.cards[dungeonID] = newCard
    end
end

NextKey222.Addon.DungeonCardsUI = UI
return UI
