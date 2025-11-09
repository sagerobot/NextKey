-- MARK: Hearthstone Selector UI
-- Hearthstone toy selection window for NextKey
-- Allows users to choose which hearthstone to use in the teleport window

local _, NextKey222 = ...
local addon = NextKey222.Addon
if not addon then return end
local UI = NextKey222.UIComponents
local HearthstoneData = NextKey222.HearthstoneData

-- MARK: Constants
local UIConfig = NextKey222.UIConfig
local WINDOW_WIDTH = UIConfig.HEARTHSTONE_SELECTOR.WINDOW_WIDTH
local WINDOW_HEIGHT = UIConfig.HEARTHSTONE_SELECTOR.WINDOW_HEIGHT
local ICON_SIZE = HearthstoneData.UI.ICON_SIZE
local ICON_SPACING = HearthstoneData.UI.ICON_SPACING
local MIN_COLUMNS = UIConfig.HEARTHSTONE_SELECTOR.MIN_COLUMNS
local MAX_COLUMNS = UIConfig.HEARTHSTONE_SELECTOR.MAX_COLUMNS
local PADDING = HearthstoneData.UI.WINDOW_PADDING
local SAVE_BUTTON_HEIGHT = UIConfig.HEARTHSTONE_SELECTOR.SAVE_BUTTON_HEIGHT

-- MARK: Window State
local selectorWindow = nil
local selectedHearthstoneID = nil  -- Current selection from database
local pendingSelection = nil        -- Temporary selection before saving
local hearthstoneButtons = {}

-- MARK: Helper Functions

--- Calculate optimal columns and window dimensions based on hearthstone count
-- @param count number Number of hearthstones to display
-- @return number, number, number Window width, height, and optimal columns
local function CalculateWindowSize(count)
    -- Determine optimal columns: minimum 8, maximum 10, based on count
    local optimalColumns = MIN_COLUMNS
    if count >= MAX_COLUMNS then
        optimalColumns = MAX_COLUMNS
    elseif count > MIN_COLUMNS then
        optimalColumns = count  -- Use exact count if between min and max
    end
    
    local rows = math.ceil(count / optimalColumns)
    local width = (optimalColumns * ICON_SIZE) + ((optimalColumns - 1) * ICON_SPACING) + (PADDING * 2)
    local height = (rows * ICON_SIZE) + ((rows - 1) * ICON_SPACING) + (PADDING * 2) + 60 + SAVE_BUTTON_HEIGHT + 10 -- Title + Save button
    
    return width, height, optimalColumns
end

--- Update the visual selection indicator
-- @param highlightedID number The ID of the highlighted hearthstone
-- @param highlightedType string The type of the highlighted hearthstone
local function UpdateSelectionIndicator(highlightedID, highlightedType)
    for _, button in ipairs(hearthstoneButtons) do
        local isHighlighted = (button.hearthstoneID == highlightedID)
        
        if isHighlighted then
            -- Add gold border for highlighted item
            button:SetBackdrop({
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            button:SetBackdropBorderColor(1, 0.82, 0, 1) -- Gold color
        else
            -- Remove border for non-highlighted items
            button:SetBackdrop(nil)
        end
    end
    
    -- Update the selected label
    if selectorWindow and selectorWindow.selectedLabel then
        if highlightedID then
            -- First try to get name from our database
            local hearthstoneData = HearthstoneData.GetHearthstoneByID(highlightedID)
            local hearthstoneName
            if hearthstoneData then
                hearthstoneName = hearthstoneData.name
            else
                -- Fallback to API if not in database
                hearthstoneName = HearthstoneData.GetHearthstoneName(highlightedID, highlightedType)
            end
            selectorWindow.selectedLabel:SetText("Selected: " .. hearthstoneName)
        else
            selectorWindow.selectedLabel:SetText("Selected: None")
        end
    end
end

--- Handle hearthstone icon click (just highlights, doesn't save)
-- @param hearthstoneID number The clicked hearthstone ID
-- @param hearthstoneType string The hearthstone type
local function OnHearthstoneClick(hearthstoneID, hearthstoneType)
    -- Store pending selection (not saved until Save button clicked)
    pendingSelection = {id = hearthstoneID, type = hearthstoneType}
    
    -- Update visual indicator with both ID and type
    UpdateSelectionIndicator(hearthstoneID, hearthstoneType)
    
    -- Enable save button if it exists
    if selectorWindow and selectorWindow.saveButton then
        selectorWindow.saveButton:Enable()
        selectorWindow.saveButton:SetAlpha(1.0)
    end
    
    NextKey222.Debug:Dev("hearthstoneSelector", "Hearthstone highlighted:", hearthstoneID, "type:", hearthstoneType)
end

--- Save the pending hearthstone selection
local function SaveHearthstoneSelection()
    if not pendingSelection then
        NextKey222.Debug:Dev("hearthstoneSelector", "No pending selection to save")
        return
    end
    
    -- Save to config
    addon.db.global.teleport.selectedHearthstoneID = pendingSelection.id
    selectedHearthstoneID = pendingSelection.id
    
    NextKey222.Debug:User("Hearthstone saved:", pendingSelection.id, "type:", pendingSelection.type)
    
    -- Close window
    if selectorWindow and selectorWindow.frame then
        selectorWindow.frame:Hide()
    end
    
    -- Refresh teleport window if it's open
    if addon.RefreshTeleportWindow then
        addon:RefreshTeleportWindow()
    end
    
    -- Notify config system that options changed
    local reg = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if reg then
        reg:NotifyChange("NextKey")
    end
end

--- Set button texture with improved retry logic (adapted from HearthstoneToys)
-- @param button frame The button to set texture on
-- @param itemID number The hearthstone ID
-- @param itemType string The hearthstone type
-- @param texture string|nil The texture path (if already known)
-- @param retries number Number of retries remaining
local function SetButtonTexture(button, itemID, itemType, texture, retries)
    retries = retries or 7
    
    if not button or not button.iconTexture then
        NextKey222.Debug:Error("SetButtonTexture: Invalid button or missing iconTexture")
        return
    end
    
    if retries == 0 then
        -- If no retries left, set the default question mark texture
        button.iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        NextKey222.Debug:Dev("hearthstoneSelector", "Failed to load texture for", itemID, "after retries")
        return
    end
    
    if texture and texture ~= "" and texture ~= 0 then
        -- If texture is available, set it directly on the texture layer
        button.iconTexture:SetTexture(texture)
        NextKey222.Debug:Dev("hearthstoneSelector", "Texture loaded for", itemID, ":", texture)
    else
        -- Retry loading the texture after a short delay (longer for better reliability)
        C_Timer.After(0.7, function()
            local retryTexture = nil
            
            if itemType == "toy" then
                local _, _, toyTexture = C_ToyBox.GetToyInfo(itemID)
                retryTexture = toyTexture
            elseif itemType == "spell" then
                if C_Spell and C_Spell.GetSpellTexture then
                    retryTexture = C_Spell.GetSpellTexture(itemID)
                end
                if not retryTexture then
                    local _, _, spellTexture = GetSpellInfo(itemID)
                    retryTexture = spellTexture
                end
            elseif itemType == "item" then
                -- Request item data load FIRST (important for reliability)
                if C_Item and C_Item.RequestLoadItemDataByID then
                    C_Item.RequestLoadItemDataByID(itemID)
                end
                local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
                retryTexture = itemTexture
            end
            
            NextKey222.Debug:Dev("hearthstoneSelector", "Retry", retries - 1, "for", itemID, "texture:", retryTexture or "nil")
            
            -- Retry with decremented retries count
            SetButtonTexture(button, itemID, itemType, retryTexture, retries - 1)
        end)
    end
end

--- Create a hearthstone icon button
-- @param hearthstone table Hearthstone data (id, type, name)
-- @param parent frame The parent frame
-- @param index number The button index for positioning
-- @param columns number Number of columns for layout
-- @param totalButtons number Total number of buttons for centering calculation
-- @return frame The created button
local function CreateHearthstoneButton(hearthstone, parent, index, columns, totalButtons)
    -- Use regular Button for selection UI (not secure template)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button.hearthstoneID = hearthstone.id
    button.hearthstoneType = hearthstone.type
    
    -- Calculate position
    local row = math.floor((index - 1) / columns)
    local col = (index - 1) % columns
    local x = PADDING + (col * (ICON_SIZE + ICON_SPACING))
    local y = -PADDING - 30 - (row * (ICON_SIZE + ICON_SPACING)) -- -30 for title space
    
    -- Center the buttons if there are fewer than the maximum columns
    if totalButtons < columns and totalButtons <= MAX_COLUMNS then
        local totalWidth = (totalButtons * ICON_SIZE) + ((totalButtons - 1) * ICON_SPACING)
        local maxRowWidth = (columns * ICON_SIZE) + ((columns - 1) * ICON_SPACING)
        local centerOffset = (maxRowWidth - totalWidth) / 2
        x = x + centerOffset
    end
    
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    -- Create texture layer for the icon
    local iconTexture = button:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(button)
    button.iconTexture = iconTexture
    
    -- Set highlight and pushed textures directly on button
    local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    highlightTexture:SetAllPoints(button)
    highlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlightTexture:SetBlendMode("ADD")
    
    -- Enable mouse and clicks
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp")
    
    -- CRITICAL: Show the button immediately
    button:Show()
    
    -- Load texture with retry logic
    local initialTexture = HearthstoneData.GetHearthstoneTexture(hearthstone.id, hearthstone.type)
    NextKey222.Debug:Dev("hearthstoneSelector", "Creating button for", hearthstone.id, hearthstone.type, "initial texture:", initialTexture or "nil")
    SetButtonTexture(button, hearthstone.id, hearthstone.type, initialTexture, 7)
    
    -- Set click handler with debug output
    button:SetScript("OnClick", function(self)
        NextKey222.Debug:User("Button clicked:", hearthstone.id, hearthstone.type)
        OnHearthstoneClick(hearthstone.id, hearthstone.type)
    end)
    
    -- Tooltip on hover - use ANCHOR_CURSOR to ensure it's always on top
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        
        local name = HearthstoneData.GetHearthstoneName(hearthstone.id, hearthstone.type)
        GameTooltip:SetText(name, 1, 1, 1)
        
        if hearthstone.type == "toy" then
            GameTooltip:AddLine("Toy", 0.7, 0.7, 0.7)
        elseif hearthstone.type == "spell" then
            GameTooltip:AddLine("Spell", 0.7, 0.7, 0.7)
        elseif hearthstone.type == "item" then
            GameTooltip:AddLine("Item", 0.7, 0.7, 0.7)
        end
        
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    NextKey222.Debug:Dev("hearthstoneSelector", "Button created at index", index, "for", hearthstone.id)
    
    return button
end

--- Preload all hearthstone textures to prevent question marks on first open
-- @param hearthstones table List of hearthstone data
-- @param callback function Callback to call when preloading is complete
local function PreloadHearthstoneTextures(hearthstones, callback)
    if not hearthstones or #hearthstones == 0 then
        if callback then callback() end
        return
    end
    
    local preloadCount = 0
    local totalCount = #hearthstones
    
    NextKey222.Debug:User("Preloading", totalCount, "hearthstone textures")
    
    -- Preload function for each hearthstone
    local function PreloadSingleTexture(hearthstone)
        -- Request item data preloading for items (important for reliability)
        if hearthstone.type == "item" and C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(hearthstone.id)
        end
        
        -- Try to get the texture (this triggers loading)
        local texture = HearthstoneData.GetHearthstoneTexture(hearthstone.id, hearthstone.type)
        
        -- Increment counter and check if we're done
        preloadCount = preloadCount + 1
        if preloadCount >= totalCount then
            NextKey222.Debug:User("All hearthstone textures preloaded")
            if callback then callback() end
        end
    end
    
    -- Preload all textures with a small delay between each to prevent overwhelming the client
    for i, hearthstone in ipairs(hearthstones) do
        C_Timer.After(i * 0.05, function() -- 50ms delay between each preload
            PreloadSingleTexture(hearthstone)
        end)
    end
end

--- Populate the hearthstone grid with learned hearthstones
-- @param container frame The container frame to populate
-- @param preloadCallback function Optional callback to call after preloading and population
local function PopulateHearthstoneGrid(container, preloadCallback)
    NextKey222.Debug:User("PopulateHearthstoneGrid called, container:", container and container:GetName() or "nil")
    
    -- Check if HearthstoneData is available
    if not HearthstoneData or not HearthstoneData.GetLearnedHearthstones then
        NextKey222.Debug:Error("HearthstoneData or GetLearnedHearthstones not available!")
        return
    end
    
    -- Clear existing buttons
    for i, button in ipairs(hearthstoneButtons) do
        NextKey222.Debug:Dev("hearthstoneSelector", "Hiding old button", i)
        button:Hide()
        button:SetParent(nil)
    end
    hearthstoneButtons = {}
    
    -- Get learned hearthstones
    local learnedHearthstones = HearthstoneData.GetLearnedHearthstones()
    NextKey222.Debug:User("Found", #learnedHearthstones, "learned hearthstones")
    
    if #learnedHearthstones == 0 then
        -- Show message if no hearthstones available
        local noHearthstonesLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        noHearthstonesLabel:SetPoint("CENTER", container, "CENTER", 0, 0)
        noHearthstonesLabel:SetText("No hearthstones available")
        noHearthstonesLabel:SetTextColor(0.7, 0.7, 0.7)
        hearthstoneButtons.noHearthstonesLabel = noHearthstonesLabel
        NextKey222.Debug:User("No hearthstones available - showing message")
        if preloadCallback then preloadCallback() end
        return
    end
    
    -- Preload textures before creating buttons
    PreloadHearthstoneTextures(learnedHearthstones, function()
        -- Calculate optimal columns for this session
        local _, _, optimalColumns = CalculateWindowSize(#learnedHearthstones)
        NextKey222.Debug:User("Using", optimalColumns, "columns for", #learnedHearthstones, "hearthstones")
        
        -- Create buttons for each learned hearthstone
        for index, hearthstone in ipairs(learnedHearthstones) do
            NextKey222.Debug:User("Creating button", index, "for hearthstone:", hearthstone.id, hearthstone.type, hearthstone.name)
            local button = CreateHearthstoneButton(hearthstone, container, index, optimalColumns, #learnedHearthstones)
            button:Show()  -- CRITICAL: Explicitly show each button
            
            -- Verify button is visible
            NextKey222.Debug:User("Button", index, "shown:", button:IsShown(), "parent:", button:GetParent() and button:GetParent():GetName() or "nil")
            
            table.insert(hearthstoneButtons, button)
        end
        
        NextKey222.Debug:User("Created", #hearthstoneButtons, "hearthstone buttons total")
        
        -- Update selection indicator
        selectedHearthstoneID = addon.db.global.teleport.selectedHearthstoneID
        if selectedHearthstoneID then
            -- Find the type for the selected hearthstone
            local selectedData = HearthstoneData.GetHearthstoneByID(selectedHearthstoneID)
            if selectedData then
                UpdateSelectionIndicator(selectedHearthstoneID, selectedData.type)
            else
                UpdateSelectionIndicator(selectedHearthstoneID, "item") -- Default to item type
            end
        else
            UpdateSelectionIndicator(nil, nil)
        end
        
        if preloadCallback then preloadCallback() end
    end)
end

--- Create the hearthstone selector window
-- @return table The window object
function addon:CreateHearthstoneSelectorWindow()
    if selectorWindow and selectorWindow.frame then
        return selectorWindow
    end
    
    -- Get learned hearthstones to calculate window size
    local learnedHearthstones = HearthstoneData.GetLearnedHearthstones()
    local width, height, optimalColumns = CalculateWindowSize(#learnedHearthstones)
    NextKey222.Debug:User("Window calculated with", optimalColumns, "columns for", #learnedHearthstones, "hearthstones")
    
    -- Create main window frame
    local frame = CreateFrame("Frame", "NextKeyHearthstoneSelector", UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")  -- Above DIALOG (options menu) but below TOOLTIP
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
    frame:SetBackdropColor(HearthstoneData.UI.BACKDROP_COLOR[1], HearthstoneData.UI.BACKDROP_COLOR[2], HearthstoneData.UI.BACKDROP_COLOR[3], HearthstoneData.UI.BACKDROP_COLOR[4])
    frame:SetBackdropBorderColor(HearthstoneData.UI.BACKDROP_BORDER_COLOR[1], HearthstoneData.UI.BACKDROP_BORDER_COLOR[2], HearthstoneData.UI.BACKDROP_BORDER_COLOR[3], HearthstoneData.UI.BACKDROP_BORDER_COLOR[4])
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Select Hearthstone")
    title:SetTextColor(1, 0.82, 0) -- Gold color
    
    -- Close button using standard WoW close button textures
    local closeButton = CreateFrame("Button", nil, frame)
    closeButton:SetSize(32, 32)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Use the standard red X textures
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    
    -- Override with proper close button appearance (red X)
    closeButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
    closeButton:GetNormalTexture():SetVertexColor(1, 0, 0, 1) -- Red tint
    
    -- Make absolutely sure it's clickable and on top
    closeButton:EnableMouse(true)
    closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    closeButton:RegisterForClicks("AnyUp")
    closeButton:SetScript("OnClick", function()
        NextKey222.Debug:User("Close button clicked")
        frame:Hide()
    end)
    
    -- Add "X" text overlay for clarity
    local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeText:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(1, 0, 0, 1) -- Red X
    
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
    
    -- Create Selected display above save button
    local selectedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    selectedLabel:SetPoint("BOTTOM", frame, "BOTTOM", 0, SAVE_BUTTON_HEIGHT + 25)
    selectedLabel:SetTextColor(1, 0.82, 0) -- Gold color
    selectedLabel:SetText("Selected: None")
    
    -- Create Save button at the bottom
    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetSize(150, SAVE_BUTTON_HEIGHT)
    saveButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    saveButton:SetText("Save Hearthstone")
    saveButton:Disable()  -- Disabled until a selection is made
    saveButton:SetAlpha(0.5)  -- Dimmed when disabled
    saveButton:SetScript("OnClick", function()
        SaveHearthstoneSelection()
    end)
    
    -- Populate with hearthstones
    PopulateHearthstoneGrid(frame)
    
    -- Initialize pending selection to current selection
    pendingSelection = nil  -- No pending selection initially
    
    -- Store window reference
    selectorWindow = {
        frame = frame,
        saveButton = saveButton,
        selectedLabel = selectedLabel,
        PopulateGrid = PopulateHearthstoneGrid
    }
    
    NextKey222.Debug:Dev("hearthstoneSelector", "Hearthstone selector window created")
    return selectorWindow
end

--- Show the hearthstone selector window
function addon:ShowHearthstoneSelector()
    NextKey222.Debug:User("ShowHearthstoneSelector called")
    
    local window = addon:CreateHearthstoneSelectorWindow()
    if window and window.frame then
        NextKey222.Debug:User("Window exists, preloading textures and populating grid")
        
        -- Update window size if needed
        local learnedHearthstones = HearthstoneData.GetLearnedHearthstones()
        local width, height, optimalColumns = CalculateWindowSize(#learnedHearthstones)
        window.frame:SetSize(width, height)
        NextKey222.Debug:User("Window resized to", width, "x", height, "with", optimalColumns, "columns")
        
        -- Hide window initially until textures are preloaded
        window.frame:Hide()
        
        -- Reset pending selection
        pendingSelection = nil
        
        -- Disable save button until a selection is made
        if window.saveButton then
            window.saveButton:Disable()
            window.saveButton:SetAlpha(0.5)
        end
        
        -- Populate grid with preloading callback to show window only after textures are loaded
        PopulateHearthstoneGrid(window.frame, function()
            NextKey222.Debug:User("Grid populated with preloaded textures, showing window")
            
            -- Highlight the currently saved selection (if any)
            selectedHearthstoneID = addon.db.global.teleport.selectedHearthstoneID
            if selectedHearthstoneID then
                -- Find the type for the selected hearthstone
                local selectedData = HearthstoneData.GetHearthstoneByID(selectedHearthstoneID)
                if selectedData then
                    UpdateSelectionIndicator(selectedHearthstoneID, selectedData.type)
                else
                    UpdateSelectionIndicator(selectedHearthstoneID, "item") -- Default to item type
                end
            else
                UpdateSelectionIndicator(nil, nil)
            end
            
            -- Ensure window appears on top of options menu but below GameTooltip
            window.frame:SetFrameStrata("FULLSCREEN_DIALOG")  -- Above DIALOG (options menu) but below TOOLTIP
            window.frame:SetFrameLevel(100)
            window.frame:SetToplevel(true)
            window.frame:Show()
            window.frame:Raise()
            
            NextKey222.Debug:User("Window shown - strata:", window.frame:GetFrameStrata(), "level:", window.frame:GetFrameLevel(), "visible:", window.frame:IsShown())
            NextKey222.Debug:User("Buttons created:", #hearthstoneButtons)
        end)
    else
        NextKey222.Debug:Error("Failed to create hearthstone selector window")
    end
end

--- Hide the hearthstone selector window
function addon:HideHearthstoneSelector()
    if selectorWindow and selectorWindow.frame then
        selectorWindow.frame:Hide()
        NextKey222.Debug:Dev("hearthstoneSelector", "Hearthstone selector window hidden")
    end
end

-- MARK: Public API
addon.HearthstoneSelector = {
    Show = function() addon:ShowHearthstoneSelector() end,
    Hide = function() addon:HideHearthstoneSelector() end,
    CreateWindow = function() return addon:CreateHearthstoneSelectorWindow() end
}