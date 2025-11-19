local _, NextKey222 = ...
local NextKey = NextKey222.Addon
local Utils = NextKey222.Utils
local ItemUtils = NextKey222.ItemUtils
local DungeonCards = NextKey.DungeonCards
local UIComponents = NextKey222.UIComponents

-- MARK: Constants
local UIConfig = NextKey222.UIConfig
local WINDOW_WIDTH = UIConfig.LOOT_WINDOW.WINDOW_WIDTH
local WINDOW_HEIGHT = UIConfig.LOOT_WINDOW.WINDOW_HEIGHT
local ICON_SIZE = 32
local ICON_SPACING = 8
local PADDING = 15
local ROW_HEIGHT = UIConfig.LOOT_WINDOW.LIST_ITEM_HEIGHT
local MIN_COLUMNS = 1
local MAX_COLUMNS = 1  -- Single column layout for loot items

local LootWindow = {
    frame = nil,
    dungeonID = nil,
    itemButtons = {},
    scrollChild = nil,
}

-- MARK: Helper Functions

--- Calculate window height based on item count
-- @param count number Number of items to display
-- @return number Window height
local function CalculateWindowHeight(count)
    count = math.max(count or 0, 0)
    if count == 0 then
        return 175
    end
    
    local baseHeight = 213   -- Perfect height for a single item
    local perItemDelta = 68  -- Amount to add/remove per additional item card
    return baseHeight + ((count - 1) * perItemDelta)
end

--- Set button texture with retry logic (from hearthstone selector)
-- @param button frame The button to set texture on
-- @param itemID number The item ID
-- @param retries number Number of retries remaining
local function SetItemTexture(button, itemID, retries)
    retries = retries or 7
    
    if not button or not button.iconTexture then
        NextKey222.Debug:Error("SetItemTexture: Invalid button or missing iconTexture")
        return
    end
    
    if retries == 0 then
        -- If no retries left, set the default question mark texture
        button.iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        NextKey222.Debug:Dev("lootwindow", "Failed to load texture for item", itemID, "after retries")
        return
    end
    
    -- Try to get the item icon
    local texture = C_Item.GetItemIconByID(itemID)
    
    if texture and texture ~= "" and texture ~= 0 then
        -- If texture is available, set it directly
        button.iconTexture:SetTexture(texture)
        NextKey222.Debug:Dev("lootwindow", "Texture loaded for item", itemID, ":", texture)
    else
        -- Retry loading the texture after a delay
        C_Timer.After(0.7, function()
            -- Request item data load (important for reliability)
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(itemID)
            end
            
            local retryTexture = C_Item.GetItemIconByID(itemID)
            NextKey222.Debug:Dev("lootwindow", "Retry", retries - 1, "for item", itemID, "texture:", retryTexture or "nil")
            
            -- Retry with decremented retries count
            SetItemTexture(button, itemID, retries - 1)
        end)
    end
end

--- Preload item textures to prevent question marks
-- @param itemIDs table List of item IDs
-- @param callback function Callback to call when preloading is complete
local function PreloadItemTextures(itemIDs, callback)
    if not itemIDs or #itemIDs == 0 then
        if callback then callback() end
        return
    end
    
    local preloadCount = 0
    local totalCount = #itemIDs
    
    NextKey222.Debug:Dev("lootwindow", "Preloading", totalCount, "item textures")
    
    local function PreloadSingleItem(itemID)
        -- Request item data preloading
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
        
        -- Try to get the texture (this triggers loading)
        local _ = C_Item.GetItemIconByID(itemID)
        
        preloadCount = preloadCount + 1
        if preloadCount >= totalCount then
            NextKey222.Debug:Dev("lootwindow", "All item textures preloaded")
            if callback then callback() end
        end
    end
    
    -- Preload all textures with a small delay between each
    for i, itemID in ipairs(itemIDs) do
        C_Timer.After(i * 0.05, function()
            PreloadSingleItem(itemID)
        end)
    end
end

--- Create an item row with native frames (following hearthstone selector pattern)
-- @param itemID number The item ID
-- @param isProtected boolean Whether the item is protected (default item)
-- @param isCustom boolean Whether the item is custom (user-added)
-- @param parent frame The parent frame
-- @param yOffset number The Y offset for positioning
-- @return frame The created item row frame
local function CreateItemRow(itemEntry, parent)
    local itemID = itemEntry.itemID
    local itemData = itemEntry.itemData or {}
    local isTracked = itemEntry.isTracked

    NextKey222.Debug:Dev("lootwindow", "Creating item row for itemID:", itemID, "tracked:", isTracked)

    local parentWidth = parent:GetWidth()
    if not parentWidth or parentWidth == 0 then
        parentWidth = WINDOW_WIDTH - (PADDING * 2)
    end
    local rowWidth = parentWidth - 10

    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(rowWidth, ROW_HEIGHT)
    row:EnableMouse(true)

    row:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    local function applyHighlight(active)
        if active then
            row:SetBackdropColor(0.12, 0.12, 0.12, 0.95)
            row:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        else
            row:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
            row:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.8)
        end
    end
    applyHighlight(false)

    row:SetScript("OnEnter", function()
        applyHighlight(true)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        
        -- Use enhanced item link with Hero track bonus IDs
        local enhancedLink = ItemUtils:BuildEnhancedItemLink(itemID, "HERO_TRACK")
        GameTooltip:SetHyperlink(enhancedLink)
        
        -- Note: Removed hardcoded Hero track ilvl lines
        -- The tooltip now shows correct Hero 1/8 → 8/8 info automatically from bonus IDs
        GameTooltip:Show()
    end)

    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
        applyHighlight(false)
    end)

    row:SetScript("OnMouseUp", function(selfRow, button)
        if button == "LeftButton" then
            LootWindow:ToggleItemTracking(itemID, itemData, selfRow.isTracked, selfRow)
        end
    end)

    local iconFrame = CreateFrame("Frame", nil, row)
    iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
    iconFrame:SetPoint("LEFT", row, "LEFT", 6, 0)

    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    iconFrame.iconTexture = iconTexture
    SetItemTexture(iconFrame, itemID, 7)

    iconFrame:SetScript("OnEnter", function()
        local enterHandler = row:GetScript("OnEnter")
        if enterHandler then enterHandler(row) end
    end)
    iconFrame:SetScript("OnLeave", function()
        local leaveHandler = row:GetScript("OnLeave")
        if leaveHandler then leaveHandler(row) end
    end)
    iconFrame:SetScript("OnMouseUp", function(_, button)
        local clickHandler = row:GetScript("OnMouseUp")
        if clickHandler then clickHandler(row, button) end
    end)

    local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", iconFrame, "RIGHT", 10, 10)
    nameLabel:SetPoint("RIGHT", row, "RIGHT", -140, 10)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetText("Loading...")
    nameLabel:SetTextColor(1, 1, 1)

    local metaLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    metaLabel:SetPoint("LEFT", iconFrame, "RIGHT", 10, -2)
    metaLabel:SetPoint("RIGHT", row, "RIGHT", -140, -2)
    metaLabel:SetJustifyH("LEFT")
    metaLabel:SetTextColor(0.75, 0.75, 0.75)
    metaLabel:SetText(itemData.slot or "")

    local runCounterLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    runCounterLabel:SetPoint("LEFT", iconFrame, "RIGHT", 10, -18)
    runCounterLabel:SetPoint("RIGHT", row, "RIGHT", -140, -18)
    runCounterLabel:SetJustifyH("LEFT")
    runCounterLabel:SetTextColor(0.85, 0.85, 0.85)

    local statusIcon = row:CreateTexture(nil, "OVERLAY")
    statusIcon:SetSize(18, 18)
    statusIcon:SetPoint("RIGHT", row, "RIGHT", -16, 0)

    local statusLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLabel:SetPoint("RIGHT", statusIcon, "LEFT", -6, 0)
    statusLabel:SetJustifyH("RIGHT")
    statusLabel:SetTextColor(0.8, 0.8, 0.8)

    -- Always display item names in Epic (purple) quality color
    local epicColor = ItemUtils:GetEpicQualityColor()
    
    -- Create Item object with enhanced link for proper quality and ilvl display
    local enhancedLink = ItemUtils:BuildEnhancedItemLink(itemID, "HERO_TRACK")
    local item = Item:CreateFromItemLink(enhancedLink)
    
    if item then
        local initialName = item:GetItemName()
        if initialName then
            nameLabel:SetText(initialName)
        end

        item:ContinueOnItemLoad(function()
            local itemNameText = item:GetItemName()
            
            -- Always use Epic (purple) color for M+ loot window items
            nameLabel:SetTextColor(epicColor.r, epicColor.g, epicColor.b)

            if itemNameText then
                nameLabel:SetText(itemNameText)
            end
        end)
    else
        nameLabel:SetText(itemData.name or ("Item " .. itemID))
        nameLabel:SetTextColor(1, 0.2, 0.2) -- Red for error case
    end

    local function UpdateRunCounter()
        if not row.isTracked then
            runCounterLabel:SetText("Runs: -- | Drop: --")
            return
        end

        local runs = DungeonCards:GetRunCount(LootWindow.dungeonID, itemID)
        local dropChance = DungeonCards:CalculateDropChance(runs)
        runCounterLabel:SetText(string.format("Runs: %d | Drop: %.1f%%", runs, dropChance))
    end

    local function SetTrackedState(tracked)
        row.isTracked = tracked

        if tracked then
            statusIcon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            statusIcon:SetVertexColor(0.2, 0.9, 0.2)
            statusLabel:SetText("Tracked")
            statusLabel:SetTextColor(0.3, 0.9, 0.3)
        else
            statusIcon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
            statusIcon:SetVertexColor(0.85, 0.85, 0.85)
            statusLabel:SetText("Click to track")
            statusLabel:SetTextColor(0.75, 0.75, 0.75)
        end

        UpdateRunCounter()
    end

    row.updateRunCounter = UpdateRunCounter
    row.SetTrackedState = SetTrackedState
    row.itemID = itemID
    row.itemData = itemData
    row.isCustomOnly = not not itemEntry.isCustomOnly

    SetTrackedState(isTracked)

    row:Show()

    return row
end
-- MARK: Window Management

function LootWindow:Show(dungeonID)
    self.dungeonID = dungeonID
    
    if not self.frame then
        -- Create main window frame using native CreateFrame (like hearthstone selector)
        local frame = CreateFrame("Frame", "NextKeyLootWindow", UIParent, "BackdropTemplate")
        frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
        frame:SetPoint("CENTER", UIParent, "CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(100)
        frame:SetToplevel(true)
        frame:SetClampedToScreen(true)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        
        -- Apply backdrop
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        
        -- Drag functionality
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
        end)
        
        -- Escape key to close
        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:Hide()
            end
        end)
        frame:EnableKeyboard(true)
        
        self.frame = frame
        
        -- Create title
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        title:SetPoint("TOP", frame, "TOP", 0, -15)
        title:SetText("")
        title:SetTextColor(1, 0.82, 0) -- Gold color
        self.title = title
        
        -- Create close button
        local closeButton = CreateFrame("Button", nil, frame)
        closeButton:SetSize(32, 32)
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
        closeButton:EnableMouse(true)
        closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
        closeButton:RegisterForClicks("AnyUp")
        
        -- Add "X" text
        local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        closeText:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
        closeText:SetText("×")
        closeText:SetTextColor(1, 0, 0, 1)
        
        closeButton:SetScript("OnClick", function()
            NextKey222.Debug:User("Close button clicked")
            frame:Hide()
        end)
        
        closeButton:Show()
        self.closeButton = closeButton
        
        -- Create manual dropdown toggle button (styled)
        local toggleBtn = UIComponents:CreateButtonLegacy(frame, UIComponents.BUTTON_SELECT)
        toggleBtn:SetSize(90, 24)
        toggleBtn:ClearAllPoints()
        toggleBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -50)
        toggleBtn:SetText("Manual")
        UIComponents:ConfigureBackdrop(toggleBtn, UIComponents.BACKDROP_COMPACT, { colorScheme = "dark" })
        toggleBtn:Show()
        self.toggleBtn = toggleBtn

        -- Create dropdown label
        local dropdownLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dropdownLabel:ClearAllPoints()
        dropdownLabel:SetPoint("TOPLEFT", toggleBtn, "BOTTOMLEFT", 0, -12)
        dropdownLabel:SetText("Add Item:")
        dropdownLabel:SetTextColor(1, 1, 1)
        self.dropdownLabel = dropdownLabel
        
        -- Create dropdown widget
        local dropdown = CreateFrame("Frame", "NextKeyLootDropdown", frame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", dropdownLabel, "RIGHT", 10, 0)
        dropdown:SetSize(150, 32)
        UIDropDownMenu_SetWidth(dropdown, 220)
        UIDropDownMenu_JustifyText(dropdown, "LEFT")
        
        -- Store dropdown reference
        self.dropdown = dropdown
        
        -- Create manual input label (hidden by default)
        local manualLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        manualLabel:SetPoint("LEFT", dropdown, "LEFT", 0, 0)
        manualLabel:SetText("Item ID:")
        manualLabel:SetTextColor(1, 1, 1)
        manualLabel:Hide()
        self.manualLabel = manualLabel
        
        -- Create input edit box (hidden by default)
        local inputBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        inputBox:SetSize(100, 20)
        inputBox:SetPoint("LEFT", manualLabel, "RIGHT", 10, 0)
        inputBox:SetAutoFocus(false)
        inputBox:Hide()
        
        inputBox:SetScript("OnEnterPressed", function(self)
            local itemID = tonumber(self:GetText())
            if itemID then
                -- Validate item exists
                local itemExists = C_Item.DoesItemExistByID(itemID)
                if not itemExists then
                    NextKey222.Debug:User("Invalid item ID:", itemID)
                    self:SetText("")
                    return
                end
                
                -- Check if item is from this dungeon
                local isFromDungeon = NextKey:IsItemFromDungeon(LootWindow.dungeonID, itemID)
                
                if isFromDungeon then
                    -- Item is from this dungeon, add it
                    DungeonCards:TrackItem(LootWindow.dungeonID, itemID, true, "Unknown")
                    DungeonCards:SaveLootTracking()
                    self:SetText("")
                    LootWindow:Update()
                else
                    -- Item not from this dungeon, show warning
                    -- For now, just track it anyway (simplified approach)
                    DungeonCards:TrackItem(LootWindow.dungeonID, itemID, true, "Unknown")
                    DungeonCards:SaveLootTracking()
                    self:SetText("")
                    LootWindow:Update()
                    NextKey222.Debug:User("Tracked item from different dungeon:", itemID)
                end
            end
        end)
        
        inputBox:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:ClearFocus()
        end)
        
        self.input = inputBox
        
        toggleBtn:SetScript("OnClick", function()
            if dropdown:IsVisible() then
                -- Switch to manual mode
                dropdown:Hide()
                manualLabel:Show()
                inputBox:Show()
                toggleBtn:SetText("Dropdown")
                inputBox:SetFocus()
            else
                -- Switch to dropdown mode
                dropdown:Show()
                manualLabel:Hide()
                inputBox:Hide()
                inputBox:ClearFocus()
                toggleBtn:SetText("Manual")
            end
        end)
        
        -- Create content container (no scroll bar needed with dynamic sizing)
        local contentContainer = CreateFrame("Frame", nil, frame)
        contentContainer:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", 0, -10)
        contentContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING)
        
        contentContainer:Show()
        
        self.scrollChild = contentContainer
        
        NextKey222.Debug:Dev("lootwindow", "Loot window created with native frames")
    end
    
    self:Update()
    self.frame:Show()
    
    -- Force loot window to the top-most strata/level so it appears above the main window
    self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    local parentLevel = UIParent and UIParent:GetFrameLevel() or 0
    self.frame:SetFrameLevel(math.max(self.frame:GetFrameLevel() or 0, parentLevel + 500))
    self.frame:Raise()
end

function LootWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function LootWindow:Update()
    if not self.dungeonID then return end
    
    -- Clear any existing item buttons FIRST to prevent stale data
    if self.itemButtons then
        for _, button in ipairs(self.itemButtons) do
            if button then
                button:Hide()
                button:SetParent(nil)
                button:ClearAllPoints()
                button:SetScript("OnEnter", nil)
                button:SetScript("OnLeave", nil)
                button:SetScript("OnMouseUp", nil)
            end
        end
    end
    self.itemButtons = {}
    
    -- Get dungeon name from portal data with fallback
    local dungeonName = nil
    if NextKey.PortalData and NextKey.PortalData.dungeons and NextKey.PortalData.dungeons[self.dungeonID] then
        dungeonName = NextKey.PortalData.dungeons[self.dungeonID].name
    end
    
    -- Fallback to a generic name if not found
    if not dungeonName then
        dungeonName = "Dungeon " .. self.dungeonID
        NextKey222.Debug:Dev("lootwindow", "Dungeon name not found for ID", self.dungeonID, "using fallback:", dungeonName)
    end
    
    -- Ensure dungeonName is never nil before calling GetCard
    if not dungeonName then
        dungeonName = "Unknown Dungeon"
        NextKey222.Debug:Error("lootwindow", "dungeonName is still nil after fallback for dungeonID:", self.dungeonID)
    end
    
    -- Get card once and reuse it (ensure dungeonName is available)
    local card = DungeonCards:GetCard(self.dungeonID, dungeonName)
    if card and card.name then
        self.title:SetText(card.name .. " Loot")
    end
    
    -- Update dropdown
    self:UpdateDropdown()
    
    local items = {}
    local invalidCustomItems = {}
    local removedInvalidItems = false
    
    NextKey222.Debug:Dev("lootwindow", "Update called for dungeonID:", self.dungeonID, "dungeonName:", dungeonName)
    
    local dungeonLoot = nil
    if NextKey.LootData and NextKey.LootData.dungeons then
        dungeonLoot = NextKey.LootData.dungeons[self.dungeonID]
    end
    
    if dungeonLoot and dungeonLoot.items then
        for itemID, itemInfo in pairs(dungeonLoot.items) do
            local isTrackedItem = (card.trackedItems and card.trackedItems[itemID]) or (card.customTrackedItems and card.customTrackedItems[itemID]) or false
            if itemInfo.featured or isTrackedItem then
                table.insert(items, {
                    itemID = itemID,
                    itemData = itemInfo,
                    isTracked = isTrackedItem,
                })
            end
        end
    end
    
    -- Include any tracked items that are not in the seasonal data (manual additions)
    if card.customTrackedItems then
        for itemID in pairs(card.customTrackedItems) do
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(itemID)
            end
            
            if C_Item and C_Item.DoesItemExistByID and not C_Item.DoesItemExistByID(itemID) then
                invalidCustomItems[itemID] = true
            else
                local alreadyListed = false
                for _, existing in ipairs(items) do
                    if existing.itemID == itemID then
                        alreadyListed = true
                        break
                    end
                end
                
                if not alreadyListed then
                    table.insert(items, {
                        itemID = itemID,
                        itemData = { name = ("Tracked Item " .. itemID), slot = "Custom" },
                        isTracked = true,
                        isCustomOnly = true,
                    })
                end
            end
        end
    end
    
    if next(invalidCustomItems) then
        for itemID in pairs(invalidCustomItems) do
            NextKey222.Debug:Dev("lootwindow", "Removing invalid custom tracked item", itemID, "for dungeonID", self.dungeonID)
            DungeonCards:UntrackItem(self.dungeonID, itemID, true)
        end
        removedInvalidItems = true
    end
    
    if card.trackedItems then
        for itemID in pairs(card.trackedItems) do
            local alreadyListed = false
            for _, existing in ipairs(items) do
                if existing.itemID == itemID then
                    alreadyListed = true
                    existing.isTracked = true
                    break
                end
            end
            
            if not alreadyListed then
                table.insert(items, {
                    itemID = itemID,
                    itemData = { name = ("Tracked Item " .. itemID), slot = "Default" },
                    isTracked = true,
                })
            end
        end
    end
    
    table.sort(items, function(a, b)
        local slotA = (a.itemData and a.itemData.slot) or ""
        local slotB = (b.itemData and b.itemData.slot) or ""
        if slotA ~= slotB then
            return slotA < slotB
        end
        
        local nameA = (a.itemData and a.itemData.name) or ("Item " .. a.itemID)
        local nameB = (b.itemData and b.itemData.name) or ("Item " .. b.itemID)
        return nameA < nameB
    end)
    
    -- Preload and render
    local allItemIDs = {}
    for _, itemData in ipairs(items) do
        table.insert(allItemIDs, itemData.itemID)
    end
    
    NextKey222.Debug:Dev("lootwindow", "Total items to render:", #items, "itemIDs to preload:", #allItemIDs)
    
    if #items == 0 then
        NextKey222.Debug:Dev("lootwindow", "No items to display - showing empty state")
        -- Could add empty state message here if needed
        if removedInvalidItems then
            DungeonCards:SaveLootTracking()
        end
        return
    end
    
    PreloadItemTextures(allItemIDs, function()
        NextKey222.Debug:Dev("lootwindow", "Preload completed, rendering item list")
        self:RenderItemList(items)
        if removedInvalidItems then
            DungeonCards:SaveLootTracking()
        end
    end)
end

function LootWindow:UpdateDropdown()
    if not self.dropdown or not self.dungeonID then return end
    
    local dropdownItems = NextKey:GetDropdownItems(self.dungeonID)
    
    -- Clear existing dropdown items
    UIDropDownMenu_Initialize(self.dropdown, function()
        for _, entry in ipairs(dropdownItems) do
            local displayName = entry.data.name
            if entry.trackLabel ~= "" then
                displayName = displayName .. " " .. entry.trackLabel
            end
            
            local info = UIDropDownMenu_CreateInfo()
            info.text = displayName
            info.value = entry.itemID
            info.disabled = entry.isTracked
            info.func = function()
                if not entry.isTracked then
                    -- Add to custom tracking
                    DungeonCards:TrackItem(self.dungeonID, entry.itemID, true, "Unknown")
                    DungeonCards:SaveLootTracking()
                    self:Update()
                end
            end
            
            -- Add icon if available
            local icon = C_Item.GetItemIconByID(entry.itemID)
            if icon then
                info.icon = icon
            end
            
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set initial selection
    if #dropdownItems > 0 then
        UIDropDownMenu_SetSelectedID(self.dropdown, 1)
    end
end

function LootWindow:ToggleItemTracking(itemID, itemData, isTracked, row)
    if not self.dungeonID then return end
    
    local dungeonName = nil
    if NextKey.PortalData and NextKey.PortalData.dungeons then
        local portalInfo = NextKey.PortalData.dungeons[self.dungeonID]
        dungeonName = portalInfo and portalInfo.name or nil
    end
    
    if isTracked then
        NextKey222.Debug:Dev("lootwindow", "Untracking item", itemID, "for dungeonID", self.dungeonID)
        DungeonCards:UntrackItem(self.dungeonID, itemID, true)
    else
        local resolvedName = dungeonName or (itemData and itemData.name) or ("Dungeon " .. self.dungeonID)
        NextKey222.Debug:Dev("lootwindow", "Tracking item", itemID, "for dungeonID", self.dungeonID, "name:", resolvedName)
        DungeonCards:TrackItem(self.dungeonID, itemID, true, resolvedName)
    end
    
    DungeonCards:SaveLootTracking()
    
    local shouldRefresh = true
    if row and row.SetTrackedState then
        row.SetTrackedState(not isTracked)
        shouldRefresh = false
    end
    
    if row and row.isCustomOnly and isTracked then
        -- Removing a custom-only item requires rebuilding the list
        shouldRefresh = true
    end
    
    if shouldRefresh then
        self:Update()
    else
        self:UpdateDropdown()
    end
end

function LootWindow:RenderItemList(items)
    local itemCount = #items
    NextKey222.Debug:Dev("lootwindow", "RenderItemList called with", itemCount, "items")
    
    -- Adjust overall window height based on visible item count
    local newHeight = CalculateWindowHeight(itemCount)
    if self.frame then
        self.frame:SetHeight(newHeight)
    end
    
    local parent = self.scrollChild
    
    local newButtons = {}
    local oldButtons = self.itemButtons or {}
    
    local previousRow = nil
    for i, itemInfo in ipairs(items) do
        NextKey222.Debug:Dev("lootwindow", "Creating row", i, "of", itemCount, "for itemID:", itemInfo.itemID)
        
        local row = CreateItemRow(itemInfo, parent)
        row:ClearAllPoints()
        row:SetHeight(ROW_HEIGHT)
        
        if i == 1 then
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        else
            row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -ICON_SPACING)
        end
        row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        
        table.insert(newButtons, row)
        previousRow = row
    end
    
    for _, button in ipairs(oldButtons) do
        if button then
            button:Hide()
            button:SetParent(nil)
        end
    end
    
    self.itemButtons = newButtons
    
    NextKey222.Debug:Dev("lootwindow", "RenderItemList completed for", itemCount, "items")
end

function NextKey:ShowLootWindow(dungeonID)
    LootWindow:Show(dungeonID)
end

NextKey.LootWindow = LootWindow
return LootWindow

