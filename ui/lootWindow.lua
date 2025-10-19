local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local Utils = NextKey222.Utils
local DungeonCards = NextKey.DungeonCards

-- MARK: Constants
local UIConfig = NextKey222.UIConfig
local WINDOW_WIDTH = UIConfig.LOOT_WINDOW.WINDOW_WIDTH
local WINDOW_HEIGHT = UIConfig.LOOT_WINDOW.WINDOW_HEIGHT
local LIST_ITEM_HEIGHT = UIConfig.LOOT_WINDOW.LIST_ITEM_HEIGHT

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

-- createItemFrame function removed - now using AceGUI components directly in Update()

-- MARK: Window Management
function LootWindow:Show(dungeonID)
    self.dungeonID = dungeonID
    
    if not self.frame then
        -- Create main window using AceGUI Frame with Components styling
        local mainContainer = NextKey222.UIComponents:CreateFrame("window", nil, {
            width = WINDOW_WIDTH,
            height = WINDOW_HEIGHT,
            colorScheme = "standard"
        })
        
        local frame = mainContainer.frame
        frame:SetName("NextKeyLootWindow")
        frame:SetPoint("CENTER")
        
        -- Store both the native frame and the AceGUI container
        self.frame = frame
        self.mainContainer = mainContainer
        
        -- Create title using AceGUI Label with Components styling
        self.title = NextKey222.UIComponents:CreateText("header", frame, {
            text = "",
            width = WINDOW_WIDTH - 30,
            justifyH = "LEFT"
        })
        local titleFrame = self.title.frame
        titleFrame:SetPoint("TOPLEFT", 15, -15)
        
        -- Create close button using AceGUI with Components styling
        local closeBtn = NextKey222.UIComponents:CreateButton("small", frame, {
            text = "×",
            onClick = function()
                LootWindow:Hide()
            end
        })
        local closeFrame = closeBtn.frame
        closeFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        closeFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
        self.closeButton = closeBtn
        
        -- Create item input label using AceGUI Label with Components styling
        local inputLabel = NextKey222.UIComponents:CreateText("label", frame, {
            text = "Add Item ID:",
            justifyH = "LEFT"
        })
        local inputLabelFrame = inputLabel.frame
        inputLabelFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, -20)
        self.inputLabel = inputLabel
        
        -- Create input edit box using AceGUI EditBox
        local input = NextKey222.UIComponents:CreateDropdown("compact", frame, {
            label = "",
            width = 150
        })
        -- Note: Using AceGUI EditBox would require additional implementation
        -- For now, we'll create a native EditBox and style it with Components
        local nativeInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        nativeInput:SetSize(150, 20)
        nativeInput:SetPoint("LEFT", inputLabelFrame, "RIGHT", 10, 0)
        nativeInput:SetAutoFocus(false)
        
        -- Apply Components backdrop styling to the EditBox
        NextKey222.UIComponents:ConfigureBackdrop(nativeInput, "compact", {
            colorScheme = "light"
        })
        
        nativeInput:SetScript("OnEnterPressed", function(self)
            local itemID = tonumber(self:GetText())
            if itemID then
                DungeonCards:TrackItem(LootWindow.dungeonID, itemID, true)
                self:SetText("")
                LootWindow:Update()
            end
        end)
        
        nativeInput:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:ClearFocus()
        end)
        
        self.input = nativeInput
        
        -- Create scroll frame using AceGUI ScrollFrame with Components styling
        NextKey222.Debug:Dev("components", "Creating Loot Window scroll frame")
        local scrollFrame = NextKey222.UIComponents:CreateScrollFrame("primary", frame, {
            width = WINDOW_WIDTH - 60,
            height = WINDOW_HEIGHT - 120,
            layout = "List"
        })
        
        -- CRITICAL: Ensure scroll frame is hidden during initialization
        if scrollFrame and scrollFrame.frame then
            NextKey222.Debug:Dev("components", "Loot Window scrollFrame created - forcing HIDDEN during init")
            scrollFrame.frame:Hide()
        end
        
        local scrollFrameFrame = scrollFrame.frame
        scrollFrameFrame:SetPoint("TOPLEFT", inputLabelFrame, "BOTTOMLEFT", 0, -10)
        scrollFrameFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)
        
        self.scrollFrame = scrollFrame
        self.content = scrollFrame -- Use scrollFrame as content container
        
        -- Add all AceGUI widgets to main container for proper cleanup
        mainContainer:AddChild(self.title)
        mainContainer:AddChild(closeBtn)
        mainContainer:AddChild(inputLabel)
        mainContainer:AddChild(scrollFrame)
    end
    
    self:Update()
    self.frame:Show()
end

function LootWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Add cleanup function for proper AceGUI container management
function LootWindow:Cleanup()
    if self.mainContainer then
        self.mainContainer:ReleaseChildren()
        self.mainContainer:Release()
        self.mainContainer = nil
    end
    self.frame = nil
    self.title = nil
    self.closeButton = nil
    self.inputLabel = nil
    self.input = nil
    self.scrollFrame = nil
    self.content = nil
end

function LootWindow:Update()
    if not self.dungeonID then return end
    
    -- Update title
    local dungeon = DungeonCards:GetCard(self.dungeonID)
    if dungeon and dungeon.name then
        self.title:SetText(dungeon.name .. " Loot")
    end
    
    -- Clear existing items
    for _, frame in pairs(self.itemFrames) do
        frame:Hide()
    end
    wipe(self.itemFrames)
    
    -- Clear existing AceGUI children from scroll frame
    if self.scrollFrame then
        self.scrollFrame:ReleaseChildren()
    end
    
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
    
    -- Create item frames using AceGUI containers
    local yOffset = 0
    for _, itemID in ipairs(items) do
        -- Create item container using AceGUI SimpleGroup
        local itemContainer = NextKey222.UIComponents:CreateFrame("container", nil, {
            width = WINDOW_WIDTH - 80,
            height = LIST_ITEM_HEIGHT,
            colorScheme = "light"
        })
        
        -- Position the item container
        local itemFrame = itemContainer.frame
        itemFrame:SetPoint("TOPLEFT", self.scrollFrame.frame, "TOPLEFT", 10, -yOffset)
        
        -- Create item icon using AceGUI Icon with enhanced styling
        local itemIcon = NextKey222.UIComponents:CreateIcon("item", itemContainer, {
            imagePath = C_Item.GetItemIconByID(itemID) or "Interface/Icons/INV_Misc_QuestionMark",
            size = {LIST_ITEM_HEIGHT - 4, LIST_ITEM_HEIGHT - 4},
            onEnter = function()
                GameTooltip:SetOwner(itemIcon.frame, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemID)
                GameTooltip:Show()
            end,
            onLeave = function()
                GameTooltip:Hide()
            end
        })
        itemIcon.frame:SetPoint("LEFT", itemFrame, "LEFT", 2, 0)
        
        -- Create item name using AceGUI Label with enhanced styling
        local itemName = NextKey222.UIComponents:CreateText("body", itemContainer, {
            text = "Loading...",
            width = WINDOW_WIDTH - 120,
            justifyH = "LEFT",
            color = {1, 1, 1}
        })
        itemName.frame:SetPoint("LEFT", itemIcon.frame, "RIGHT", 5, 0)
        
        -- Create remove button using AceGUI Button with enhanced styling
        local removeBtn = NextKey222.UIComponents:CreateButton("small", itemContainer, {
            text = "×",
            onClick = function()
                DungeonCards:UntrackItem(LootWindow.dungeonID, itemID, true)
                LootWindow:Update()
            end,
            onEnter = function()
                GameTooltip:SetOwner(removeBtn.frame, "ANCHOR_RIGHT")
                GameTooltip:SetText("Remove Item")
                GameTooltip:AddLine("Click to remove this item from tracking", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end,
            onLeave = function()
                GameTooltip:Hide()
            end
        })
        removeBtn.frame:SetPoint("RIGHT", itemFrame, "RIGHT", -2, 0)
        removeBtn.frame:SetFrameLevel(itemFrame:GetFrameLevel() + 5)
        
        -- Load item info asynchronously with enhanced error handling
        local item = Item:CreateFromItemID(itemID)
        if item then
            itemName:SetText(item:GetItemName() or "Loading...")
            
            item:ContinueOnItemLoad(function()
                local itemNameText = item:GetItemName()
                local itemIconPath = C_Item.GetItemIconByID(itemID)
                local itemQuality = C_Item.GetItemQualityByID(itemID)
                
                -- Update item name
                if itemNameText then
                    itemName:SetText(itemNameText)
                else
                    itemName:SetText("Unknown Item")
                end
                
                -- Update item quality color
                if itemQuality and ITEM_QUALITY_COLORS[itemQuality] then
                    local color = ITEM_QUALITY_COLORS[itemQuality]
                    itemName:SetColor(color.r, color.g, color.b)
                else
                    itemName:SetColor(1, 1, 1) -- Default white for unknown quality
                end
                
                -- Update item icon
                if itemIconPath then
                    itemIcon:SetImage(itemIconPath)
                else
                    itemIcon:SetImage("Interface/Icons/INV_Misc_QuestionMark")
                end
            end)
        else
            -- Fallback for invalid item IDs
            itemName:SetText("Invalid Item ID")
            itemName:SetColor(1, 0.2, 0.2) -- Red for errors
            itemIcon:SetImage("Interface/Icons/INV_Misc_QuestionMark")
        end
        
        -- Container-level tooltip (backup for icon tooltip)
        itemFrame:SetScript("OnEnter", function()
            if not GameTooltip:IsOwned() then
                GameTooltip:SetOwner(itemFrame, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemID)
                GameTooltip:Show()
            end
        end)
        itemFrame:SetScript("OnLeave", function()
            if GameTooltip:IsOwned(itemFrame) then
                GameTooltip:Hide()
            end
        end)
        
        -- Add to scroll frame and track
        self.scrollFrame:AddChild(itemContainer)
        self.itemFrames[itemID] = itemFrame
        
        yOffset = yOffset + LIST_ITEM_HEIGHT + 2
    end
    
    -- Update scroll frame content height
    if self.scrollFrame then
        local totalHeight = math.max(yOffset, 1)
        self.scrollFrame.frame:SetHeight(totalHeight)
    end
end

function NextKey:ShowLootWindow(dungeonID)
    LootWindow:Show(dungeonID)
end

NextKey.LootWindow = LootWindow
return LootWindow