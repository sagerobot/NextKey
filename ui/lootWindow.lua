local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local Utils = NextKey222.Utils
local DungeonCards = NextKey.DungeonCards

-- MARK: Constants
local WINDOW_WIDTH = 300
local WINDOW_HEIGHT = 400
local LIST_ITEM_HEIGHT = 40

local LootWindow = {
    frame = nil,
    dungeonID = nil,
    itemFrames = {},
    preloadedItems = {
        -- Example: [dungeonID] = { itemID1, itemID2, ... }
        -- Will be populated with trinkets and special items
        [1] = { 207167, 207166 }, -- Example trinkets
    }
}

-- MARK: Item List Management

---Create a frame for displaying an item
---@param parent Frame Parent frame
---@param itemID number
---@return Frame
local function createItemFrame(parent, itemID)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth() - 20, LIST_ITEM_HEIGHT)
    
    -- Item icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(LIST_ITEM_HEIGHT - 4, LIST_ITEM_HEIGHT - 4)
    icon:SetPoint("LEFT", 2, 0)
    
    -- Item name
    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    name:SetPoint("RIGHT", -25, 0)
    name:SetJustifyH("LEFT")
    
    -- Remove button
    local removeBtn = CreateFrame("Button", nil, frame)
    removeBtn:SetSize(16, 16)
    removeBtn:SetPoint("RIGHT", -2, 0)
    removeBtn:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
    removeBtn:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
    removeBtn:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")
    
    removeBtn:SetScript("OnClick", function()
        DungeonCards:UntrackItem(LootWindow.dungeonID, itemID, true)
        LootWindow:Update()
    end)
    
    -- Load item info using C_Item API
    local item = Item:CreateFromItemID(itemID)
    if item then
        icon:SetTexture(C_Item.GetItemIconByID(itemID))
        name:SetText(item:GetItemName() or "Loading...")
        
        item:ContinueOnItemLoad(function()
            icon:SetTexture(C_Item.GetItemIconByID(itemID))
            name:SetText(item:GetItemName())
            local quality = C_Item.GetItemQualityByID(itemID)
            if quality then
                local color = ITEM_QUALITY_COLORS[quality]
                if color then
                    name:SetTextColor(color.r, color.g, color.b)
                end
            end
        end)
    end
    
    -- Tooltip
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(itemID)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return frame
end

-- MARK: Window Management
function LootWindow:Show(dungeonID)
    self.dungeonID = dungeonID
    
    if not self.frame then
        -- Create main frame
        self.frame = CreateFrame("Frame", "NextKeyLootWindow", UIParent, "BackdropTemplate")
        self.frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.frame:SetPoint("CENTER")
        self.frame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.frame:SetBackdropColor(0, 0, 0, 0.9)
        
        -- Title
        self.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.title:SetPoint("TOPLEFT", 15, -15)
        
        -- Close button
        local closeBtn = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT")
        
        -- Item input
        local inputLabel = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        inputLabel:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -20)
        inputLabel:SetText("Add Item ID:")
        
        local input = CreateFrame("EditBox", nil, self.frame, "InputBoxTemplate")
        input:SetSize(150, 20)
        input:SetPoint("LEFT", inputLabel, "RIGHT", 10, 0)
        input:SetAutoFocus(false)
        input:SetScript("OnEnterPressed", function(self)
            local itemID = tonumber(self:GetText())
            if itemID then
                DungeonCards:TrackItem(LootWindow.dungeonID, itemID, true)
                self:SetText("")
                LootWindow:Update()
            end
        end)
        
        -- Scroll frame for items
        local scrollFrame = CreateFrame("ScrollFrame", nil, self.frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", inputLabel, "BOTTOMLEFT", 0, -10)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
        
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(scrollFrame:GetWidth(), 1) -- Height will be set dynamically
        scrollFrame:SetScrollChild(content)
        
        self.content = content
    end
    
    self:Update()
    self.frame:Show()
end

function LootWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function LootWindow:Update()
    if not self.dungeonID then return end
    
    -- Update title
    local dungeon = DungeonCards:GetCard(self.dungeonID)
    self.title:SetText(dungeon.name .. " Loot")
    
    -- Clear existing items
    for _, frame in pairs(self.itemFrames) do
        frame:Hide()
    end
    wipe(self.itemFrames)
    
    -- Get tracked items
    local items = {}
    local card = DungeonCards:GetCard(self.dungeonID)
    
    -- Add preloaded items
    if self.preloadedItems[self.dungeonID] then
        for _, itemID in ipairs(self.preloadedItems[self.dungeonID]) do
            if card.trackedItems[itemID] ~= false then -- Only show if not explicitly untracked
                table.insert(items, itemID)
            end
        end
    end
    
    -- Add custom tracked items
    for itemID in pairs(card.customTrackedItems) do
        table.insert(items, itemID)
    end
    
    -- Create item frames
    local yOffset = 0
    for _, itemID in ipairs(items) do
        local frame = createItemFrame(self.content, itemID)
        frame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -yOffset)
        self.itemFrames[itemID] = frame
        yOffset = yOffset + LIST_ITEM_HEIGHT + 2
    end
    
    -- Update content height
    self.content:SetHeight(math.max(yOffset, 1))
end

function NextKey:ShowLootWindow(dungeonID)
    LootWindow:Show(dungeonID)
end

NextKey.LootWindow = LootWindow
return LootWindow