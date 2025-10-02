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

local function createScoreText(parent, score, affix)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetText(string.format("%s: %d", affix, score))
    
    -- Color based on score
    if NextKey222.RaiderIO then
        local r, g, b = NextKey222.RaiderIO:GetScoreColor(score)
        text:SetTextColor(r, g, b)
    end
    
    return text
end

local function createButton(parent, texture, tooltip)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(24, 24)
    
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(texture)
    
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return btn
end

local function createDungeonCard(parent, card)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(CARD_WIDTH, CARD_HEIGHT)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6)
    
    -- Dungeon name
    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("TOPLEFT", 10, -10)
    name:SetText(card.name)
    
    -- Score breakdown
    local fortScore = createScoreText(frame, card.fortifiedScore, "Fortified")
    fortScore:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -5)
    
    local tyrScore = createScoreText(frame, card.tyrannicalScore, "Tyrannical")
    tyrScore:SetPoint("LEFT", fortScore, "RIGHT", 10, 0)
    
    -- Best level text
    local bestLevel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bestLevel:SetPoint("TOPLEFT", fortScore, "BOTTOMLEFT", 0, -5)
    bestLevel:SetText(string.format("Best: +%d %s", card.bestLevel, card.bestLevelAffix))
    
    -- Like button
    local likeBtn = createButton(frame, "Interface/Icons/Ability_Paladin_BeaconofLight", "Like this dungeon")
    likeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
    likeBtn:SetScript("OnClick", function()
        DungeonCards:ToggleLike(card.dungeonID, NextKey.playerFullName)
        UI:UpdateCard(card.dungeonID)
    end)
    
    -- Dislike button
    local dislikeBtn = createButton(frame, "Interface/Icons/Ability_Creature_Cursed_02", "Dislike this dungeon")
    dislikeBtn:SetPoint("RIGHT", likeBtn, "LEFT", -5, 0)
    dislikeBtn:SetScript("OnClick", function()
        DungeonCards:ToggleDislike(card.dungeonID, NextKey.playerFullName)
        UI:UpdateCard(card.dungeonID)
    end)
    
    -- Loot button
    local lootBtn = createButton(frame, "Interface/Icons/INV_Misc_Bag_08", "View loot options")
    lootBtn:SetPoint("RIGHT", dislikeBtn, "LEFT", -5, 0)
    lootBtn:SetScript("OnClick", function()
        NextKey:ShowLootWindow(card.dungeonID)
    end)
    
    -- Preference tooltip
    frame:SetScript("OnEnter", function(self)
        local likes, dislikes = DungeonCards:GetPreferenceTooltip(card.dungeonID)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText(card.name)
        if likes ~= "" then
            GameTooltip:AddLine("Likes: " .. likes, 0, 1, 0)
        end
        if dislikes ~= "" then
            GameTooltip:AddLine("Dislikes: " .. dislikes, 1, 0, 0)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return frame
end

-- MARK: Main Frame
function UI:Show()
    if not self.frame then
        -- Create main frame
        self.frame = CreateFrame("Frame", "NextKeyDungeonCards", UIParent, "BackdropTemplate")
        self.frame:SetSize(CARD_WIDTH * CARDS_PER_ROW + CARD_PADDING * 3, 600)
        self.frame:SetPoint("CENTER")
        self.frame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.frame:SetBackdropColor(0, 0, 0, 0.9)
        
        -- Title
        local title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 15, -15)
        title:SetText("Dungeon Overview")
        
        -- Sort dropdown
        local sortLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sortLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
        sortLabel:SetText("Sort by:")
        
        self.sortDropdown = CreateFrame("Frame", "NextKeyDungeonSort", self.frame, "UIDropDownMenuTemplate")
        self.sortDropdown:SetPoint("LEFT", sortLabel, "RIGHT", -10, -2)
        
        UIDropDownMenu_Initialize(self.sortDropdown, function(frame, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            local methods = {
                { text = "Alphabetical", value = "alphabetical" },
                { text = "Highest Score", value = "highest" },
                { text = "Lowest Score", value = "lowest" },
                { text = "Smart Sort", value = "smart" }
            }
            
            for _, method in ipairs(methods) do
                info.text = method.text
                info.value = method.value
                info.checked = DungeonCards.sortMethod == method.value
                info.func = function(self)
                    DungeonCards:SetSortMethod(self.value)
                    UI:Update()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        -- Total score
        self.totalScore = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.totalScore:SetPoint("TOPRIGHT", -15, -15)
        
        -- Close button
        local closeBtn = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
        
        -- Scroll frame for cards
        local scrollFrame = CreateFrame("ScrollFrame", nil, self.frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", sortLabel, "BOTTOMLEFT", 0, -10)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
        
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(content)
        
        self.content = content
    end
    
    self:Update()
    self.frame:Show()
end

function UI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function UI:Update()
    local cards = DungeonCards:GetSortedCards()
    local totalScore = 0
    
    -- Clear existing cards
    for _, card in pairs(self.cards) do
        card:Hide()
    end
    wipe(self.cards)
    
    -- Create/update cards
    for i, cardData in ipairs(cards) do
        local col = (i-1) % CARDS_PER_ROW
        local row = math.floor((i-1) / CARDS_PER_ROW)
        
        local card = createDungeonCard(self.content, cardData)
        card:SetPoint("TOPLEFT", self.content, "TOPLEFT", 
            CARD_PADDING + col * (CARD_WIDTH + CARD_PADDING),
            -(CARD_PADDING + row * (CARD_HEIGHT + CARD_PADDING)))
        
        self.cards[cardData.dungeonID] = card
        totalScore = totalScore + cardData.totalScore
    end
    
    -- Update total score
    if NextKey222.RaiderIO then
        local r, g, b = NextKey222.RaiderIO:GetScoreColor(totalScore)
        self.totalScore:SetText(string.format("Total Score: %d", totalScore))
        self.totalScore:SetTextColor(r, g, b)
    else
        self.totalScore:SetText(string.format("Total Score: %d", totalScore))
    end
    
    -- Update content height
    local rows = math.ceil(#cards / CARDS_PER_ROW)
    self.content:SetHeight(rows * (CARD_HEIGHT + CARD_PADDING) + CARD_PADDING)
end

function UI:UpdateCard(dungeonID)
    if self.cards[dungeonID] then
        local cardData = DungeonCards:GetCard(dungeonID)
        local oldCard = self.cards[dungeonID]
        self.cards[dungeonID] = createDungeonCard(self.content, cardData)
        self.cards[dungeonID]:SetPoint("TOPLEFT", oldCard, "TOPLEFT")
        oldCard:Hide()
    end
end

NextKey222.Addon.DungeonCardsUI = UI
return UI