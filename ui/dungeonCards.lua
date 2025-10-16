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
local CARD_WIDTH = 300
local CARD_HEIGHT = 80
local CARD_PADDING = 10
local CARDS_PER_ROW = 2

-- createScoreText and createButton functions removed - now using AceGUI components directly in PopulateCard

-- createDungeonCard function removed - now using PopulateCard with AceGUI components

-- MARK: Main Frame
function UI:Show()
    if not self.frame then
        -- Create main window using AceGUI Frame with Components styling
        local mainContainer = NextKey222.UIComponents:CreateFrame("window", nil, {
            width = CARD_WIDTH * CARDS_PER_ROW + CARD_PADDING * 3,
            height = 600,
            colorScheme = "standard"
        })
        
        local frame = mainContainer.frame
        frame:SetName("NextKeyDungeonCards")
        frame:SetPoint("CENTER")
        
        -- Store both the native frame and the AceGUI container
        self.frame = frame
        self.mainContainer = mainContainer
        
        -- Create title using AceGUI Label with Components styling
        local title = NextKey222.UIComponents:CreateText("header", frame, {
            text = "Dungeon Overview",
            width = 200,
            justifyH = "LEFT"
        })
        local titleFrame = title.frame
        titleFrame:SetPoint("TOPLEFT", 15, -15)
        self.title = title
        
        -- Create sort label using AceGUI Label with Components styling
        local sortLabel = NextKey222.UIComponents:CreateText("label", frame, {
            text = "Sort by:",
            justifyH = "LEFT"
        })
        local sortLabelFrame = sortLabel.frame
        sortLabelFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -10)
        self.sortLabel = sortLabel
        
        -- Create sort dropdown using AceGUI Dropdown with Components styling
        local sortDropdown = NextKey222.UIComponents:CreateDropdown("primary", frame, {
            width = 150,
            label = "",
            list = {
                ["alphabetical"] = "Alphabetical",
                ["highest"] = "Highest Score",
                ["lowest"] = "Lowest Score",
                ["smart"] = "Smart Sort"
            },
            value = DungeonCards.sortMethod or "smart",
            onValueChanged = function(widget, value, text)
                DungeonCards:SetSortMethod(value)
                UI:Update()
            end
        })
        local sortDropdownFrame = sortDropdown.frame
        sortDropdownFrame:SetPoint("LEFT", sortLabelFrame, "RIGHT", -10, -2)
        self.sortDropdown = sortDropdown
        
        -- Create total score using AceGUI Label with Components styling
        local totalScore = NextKey222.UIComponents:CreateText("large", frame, {
            text = "Total Score: 0",
            justifyH = "RIGHT",
            color = {0, 1, 0}
        })
        local totalScoreFrame = totalScore.frame
        totalScoreFrame:SetPoint("TOPRIGHT", -15, -15)
        self.totalScore = totalScore
        
        -- Create close button using AceGUI with Components styling
        local closeBtn = NextKey222.UIComponents:CreateButton("small", frame, {
            text = "×",
            onClick = function()
                UI:Hide()
            end
        })
        local closeFrame = closeBtn.frame
        closeFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        closeFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
        self.closeButton = closeBtn
        
        -- Create scroll frame using AceGUI ScrollFrame with Components styling
        local scrollFrame = NextKey222.UIComponents:CreateScrollFrame("primary", frame, {
            width = CARD_WIDTH * CARDS_PER_ROW + CARD_PADDING * 3 - 60,
            height = 500,
            layout = "Flow"
        })
        local scrollFrameFrame = scrollFrame.frame
        scrollFrameFrame:SetPoint("TOPLEFT", sortLabelFrame, "BOTTOMLEFT", 0, -10)
        scrollFrameFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
        
        self.scrollFrame = scrollFrame
        self.content = scrollFrame -- Use scrollFrame as content container
        
        -- Add all AceGUI widgets to main container for proper cleanup
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
    local cards = DungeonCards:GetSortedCards()
    local totalScore = 0
    
    -- Clear existing cards
    for _, card in pairs(self.cards) do
        if card and card.Hide then
            card:Hide()
        end
    end
    wipe(self.cards)
    
    -- Clear existing AceGUI children from scroll frame
    if self.scrollFrame then
        self.scrollFrame:ReleaseChildren()
    end
    
    -- Create/update cards using AceGUI containers
    for i, cardData in ipairs(cards) do
        local col = (i-1) % CARDS_PER_ROW
        local row = math.floor((i-1) / CARDS_PER_ROW)
        
        -- Create card container using AceGUI InlineGroup
        local cardContainer = NextKey222.UIComponents:CreateFrame("panel", nil, {
            width = CARD_WIDTH,
            height = CARD_HEIGHT,
            colorScheme = "standard"
        })
        
        -- Position the card container (using native frame positioning for layout)
        local cardFrame = cardContainer.frame
        cardFrame:SetPoint("TOPLEFT", self.scrollFrame.frame, "TOPLEFT",
            CARD_PADDING + col * (CARD_WIDTH + CARD_PADDING),
            -(CARD_PADDING + row * (CARD_HEIGHT + CARD_PADDING)))
        
        -- Add card content using the existing createDungeonCard logic but adapted for AceGUI
        self:PopulateCard(cardContainer, cardData)
        
        -- Add to scroll frame and track
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
    
    -- Update scroll frame content height
    local rows = math.ceil(#cards / CARDS_PER_ROW)
    local totalHeight = rows * (CARD_HEIGHT + CARD_PADDING) + CARD_PADDING
    if self.scrollFrame then
        self.scrollFrame.frame:SetHeight(totalHeight)
    end
end

-- Populate card with AceGUI components
function UI:PopulateCard(cardContainer, card)
    local cardFrame = cardContainer.frame
    
    -- Create dungeon name using AceGUI Label with Components styling
    local name = NextKey222.UIComponents:CreateText("header", cardContainer, {
        text = card.name,
        width = CARD_WIDTH - 20,
        justifyH = "LEFT"
    })
    local nameFrame = name.frame
    nameFrame:SetPoint("TOPLEFT", cardFrame, "TOPLEFT", 10, -10)
    
    -- Create score breakdown using AceGUI Labels with Components styling
    local fortScore = NextKey222.UIComponents:CreateText("score", cardContainer, {
        text = string.format("Fortified: %d", card.fortifiedScore),
        justifyH = "LEFT"
    })
    local fortScoreFrame = fortScore.frame
    fortScoreFrame:SetPoint("TOPLEFT", nameFrame, "BOTTOMLEFT", 0, -5)
    
    local tyrScore = NextKey222.UIComponents:CreateText("score", cardContainer, {
        text = string.format("Tyrannical: %d", card.tyrannicalScore),
        justifyH = "LEFT"
    })
    local tyrScoreFrame = tyrScore.frame
    tyrScoreFrame:SetPoint("LEFT", fortScoreFrame, "RIGHT", 10, 0)
    
    -- Create best level text using AceGUI Label with Components styling
    local bestLevel = NextKey222.UIComponents:CreateText("body", cardContainer, {
        text = string.format("Best: +%d %s", card.bestLevel, card.bestLevelAffix),
        justifyH = "LEFT"
    })
    local bestLevelFrame = bestLevel.frame
    bestLevelFrame:SetPoint("TOPLEFT", fortScoreFrame, "BOTTOMLEFT", 0, -5)
    
    -- Create like button using AceGUI Button with Components styling
    local likeBtn = NextKey222.UIComponents:CreateButton("icon", cardContainer, {
        imagePath = "Interface/Icons/Ability_Paladin_BeaconofLight",
        onClick = function()
            DungeonCards:ToggleLike(card.dungeonID, NextKey.playerFullName)
            UI:UpdateCard(card.dungeonID)
        end,
        onEnter = function()
            GameTooltip:SetOwner(likeBtn.frame, "ANCHOR_RIGHT")
            GameTooltip:SetText("Like this dungeon")
            GameTooltip:Show()
        end,
        onLeave = function()
            GameTooltip:Hide()
        end
    })
    local likeFrame = likeBtn.frame
    likeFrame:SetPoint("BOTTOMRIGHT", cardFrame, "BOTTOMRIGHT", -30, 10)
    
    -- Create dislike button using AceGUI Button with Components styling
    local dislikeBtn = NextKey222.UIComponents:CreateButton("icon", cardContainer, {
        imagePath = "Interface/Icons/Ability_Creature_Cursed_02",
        onClick = function()
            DungeonCards:ToggleDislike(card.dungeonID, NextKey.playerFullName)
            UI:UpdateCard(card.dungeonID)
        end,
        onEnter = function()
            GameTooltip:SetOwner(dislikeBtn.frame, "ANCHOR_RIGHT")
            GameTooltip:SetText("Dislike this dungeon")
            GameTooltip:Show()
        end,
        onLeave = function()
            GameTooltip:Hide()
        end
    })
    local dislikeFrame = dislikeBtn.frame
    dislikeFrame:SetPoint("RIGHT", likeFrame, "LEFT", -5, 0)
    
    -- Create loot button using AceGUI Button with Components styling
    local lootBtn = NextKey222.UIComponents:CreateButton("icon", cardContainer, {
        imagePath = "Interface/Icons/INV_Misc_Bag_08",
        onClick = function()
            NextKey:ShowLootWindow(card.dungeonID)
        end,
        onEnter = function()
            GameTooltip:SetOwner(lootBtn.frame, "ANCHOR_RIGHT")
            GameTooltip:SetText("View loot options")
            GameTooltip:Show()
        end,
        onLeave = function()
            GameTooltip:Hide()
        end
    })
    local lootFrame = lootBtn.frame
    lootFrame:SetPoint("RIGHT", dislikeFrame, "LEFT", -5, 0)
    
    -- Add preference tooltip to card container
    cardFrame:SetScript("OnEnter", function()
        local likes, dislikes = DungeonCards:GetPreferenceTooltip(card.dungeonID)
        GameTooltip:SetOwner(cardFrame, "ANCHOR_CURSOR")
        GameTooltip:SetText(card.name)
        if likes ~= "" then
            GameTooltip:AddLine("Likes: " .. likes, 0, 1, 0)
        end
        if dislikes ~= "" then
            GameTooltip:AddLine("Dislikes: " .. dislikes, 1, 0, 0)
        end
        GameTooltip:Show()
    end)
    cardFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function UI:UpdateCard(dungeonID)
    if self.cards[dungeonID] then
        local cardData = DungeonCards:GetCard(dungeonID)
        local oldCard = self.cards[dungeonID]
        
        -- Create new card container
        local newCard = NextKey222.UIComponents:CreateFrame("panel", nil, {
            width = CARD_WIDTH,
            height = CARD_HEIGHT,
            colorScheme = "standard"
        })
        
        -- Position at same location as old card
        local newCardFrame = newCard.frame
        newCardFrame:SetPoint("TOPLEFT", oldCard.frame, "TOPLEFT")
        
        -- Populate new card
        self:PopulateCard(newCard, cardData)
        
        -- Replace in scroll frame
        if self.scrollFrame then
            self.scrollFrame:RemoveChild(oldCard)
            self.scrollFrame:AddChild(newCard)
        end
        
        -- Update tracking
        self.cards[dungeonID] = newCard
        
        -- Clean up old card
        if oldCard and oldCard.Release then
            oldCard:Release()
        end
    end
end

NextKey222.Addon.DungeonCardsUI = UI
return UI