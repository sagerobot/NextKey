-- MARK: Module Definition
local _, NextKey222 = ...

local SlotManager = {}
NextKey222.SlotManager = SlotManager
NextKey222.RegisterModule("SlotManager", SlotManager)

local Debug = NextKey222.Debug

-- MARK: Initialization
function SlotManager:Initialize()
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer", "SlotManager module initialized")
        return true
    end, "SlotManager:Initialize")
end

-- MARK: Section Creation
--- Create the active pool section with group slots
-- @param rosterBoard RosterBoard instance
-- @param nativeParent Parent frame
function SlotManager:create_active_pool_section(rosterBoard, nativeParent)
    return NextKey222.SafeRun(function()
        local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
        local layout = rosterBoard:CalculateOptimalLayout()

        local padding = layout.padding or config.PADDING or 20
        local headerHeight = layout.headerHeight or config.HEADER_HEIGHT or 90
        local headerToGroupsGap = config.HEADER_TO_GROUPS_GAP or 20
        local groupHeight = config.GROUP_HEIGHT or 550
        local columnWidth = layout.columnWidth or config.COLUMN_WIDTH or 180
        local slotSpacing = layout.slotSpacing or config.SLOT_SPACING or 10
        local titleHeight = config.HEADER_LABEL_HEIGHT or 16
        local titleGap = config.HEADER_SECTION_GAP or 4
        local slotHorizontalPadding = 12

        local poolContainer = CreateFrame("Frame", nil, nativeParent)
        poolContainer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", padding, -(headerHeight + headerToGroupsGap))
        poolContainer:SetPoint("TOPRIGHT", nativeParent, "TOPRIGHT", -padding, -(headerHeight + headerToGroupsGap))
        poolContainer:SetHeight(groupHeight)
        poolContainer:Show()

        Debug:Dev("organizer_ui", "Created active pool container", poolContainer:GetName() or "anonymous")

        rosterBoard.groupBackgrounds = {}
        rosterBoard.groupSlots = {}
        rosterBoard.groupTitles = {}
        rosterBoard.groupKeystones = {}
        rosterBoard.allInteractiveFrames = {}
        rosterBoard.activePoolSection = poolContainer

        local roles = {"TANK", "HEALER", "DAMAGER", "DAMAGER", "DAMAGER"}
        local roleLabels = {"Tank", "Healer", "DPS", "DPS", "DPS"}
        local slotCount = #roles

        local verticalStart = slotSpacing + titleHeight + titleGap
        local availableHeight = groupHeight - verticalStart - slotSpacing
        local slotHeight = math.floor((availableHeight - ((slotCount - 1) * slotSpacing)) / slotCount)
        if slotHeight < 80 then
            slotHeight = 80
        end

        for groupIndex = 1, layout.groupColumns do
            local groupFrame = CreateFrame("Frame", nil, poolContainer)
            groupFrame:SetPoint("TOPLEFT", poolContainer, "TOPLEFT", (groupIndex - 1) * columnWidth, 0)
            groupFrame:SetSize(columnWidth, groupHeight)

            local bgTexture = groupFrame:CreateTexture(nil, "BACKGROUND")
            bgTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
            bgTexture:SetAllPoints()
            bgTexture:SetDrawLayer("BACKGROUND", -5)
            rosterBoard.groupBackgrounds[groupIndex] = bgTexture

            local titleLabel = groupFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            titleLabel:SetPoint("TOP", groupFrame, "TOP", 0, -slotSpacing)
            titleLabel:SetJustifyH("CENTER")
            titleLabel:SetText("M+ Grp. " .. groupIndex)
            rosterBoard.groupTitles[groupIndex] = titleLabel
            
            -- Add group control buttons if this is the last group
            if groupIndex == layout.groupColumns then
                self:add_group_control_buttons(groupFrame, groupIndex, layout.groupColumns, rosterBoard)
            end

            rosterBoard.groupKeystones[groupIndex] = {keystone = nil, playerID = nil}
            rosterBoard.groupSlots[groupIndex] = {}

            local titleLabelHeight = math.ceil(titleLabel:GetStringHeight() or titleHeight)
            local slotTopOffset = slotSpacing + titleLabelHeight + titleGap
            local slotWidth = columnWidth - (slotHorizontalPadding * 2)

            for slotIndex, role in ipairs(roles) do
                local offset = slotTopOffset + ((slotIndex - 1) * (slotHeight + slotSpacing))
                local slot = self:create_flat_role_slot(
                    groupFrame,
                    groupIndex,
                    role,
                    roleLabels[slotIndex],
                    slotIndex,
                    slotHorizontalPadding,
                    -offset,
                    slotWidth,
                    slotHeight
                )

                slot.innerPadding = 6
                rosterBoard.groupSlots[groupIndex][slotIndex] = slot
                table.insert(rosterBoard.allInteractiveFrames, slot)
            end
        end

        local benchLeftGap = config.BENCH_LEFT_GAP or 30
        local benchXOffset = (layout.groupColumns * columnWidth) + benchLeftGap
        local benchColumn = NextKey222.BenchManager:create_native_bench_column(rosterBoard, layout.benchWidth, poolContainer)
        benchColumn:ClearAllPoints()
        benchColumn:SetPoint("TOPLEFT", poolContainer, "TOPLEFT", benchXOffset, 0)
        benchColumn:SetPoint("BOTTOMRIGHT", poolContainer, "BOTTOMLEFT", benchXOffset + layout.benchWidth, 0)

        Debug:Dev("organizer_ui", "Active pool section created for", layout.groupColumns, "groups")
    end, "SlotManager:create_active_pool_section")
end

--- Create the opt-out section with horizontal scrolling
-- @param rosterBoard RosterBoard instance
-- @param nativeParent Parent frame
function SlotManager:create_opt_out_section(rosterBoard, nativeParent)
    return NextKey222.SafeRun(function()
        local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
        local layout = rosterBoard:CalculateOptimalLayout()
        local padding = layout.padding or config.PADDING or 20
        local gap = layout.groupToOptOutGap or config.GROUP_TO_OPTOUT_GAP or 20
        local optOutHeight = layout.optOutHeight or config.OPT_OUT_HEIGHT or 90

        local anchorParent = rosterBoard.activePoolSection or nativeParent

        local optOut = CreateFrame("Frame", nil, nativeParent, "BackdropTemplate")
        optOut:SetPoint("TOPLEFT", anchorParent, "BOTTOMLEFT", 0, -gap)
        optOut:SetPoint("TOPRIGHT", anchorParent, "BOTTOMRIGHT", 0, -gap)
        optOut:SetHeight(optOutHeight)
        optOut:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        optOut:Show()
        
        -- Title bar container (similar to bench)
        local titleBar = CreateFrame("Frame", nil, optOut)
        titleBar:SetPoint("TOPLEFT", 10, -10)
        titleBar:SetPoint("TOPRIGHT", -10, -10)
        titleBar:SetHeight(20)
        titleBar:Show()
        
        -- Title label (left-aligned to make room for button)
        local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleLabel:SetPoint("LEFT", titleBar, "LEFT", 0, 0)
        titleLabel:SetText("Not Playing")
        
        -- Return All button (right-aligned, small)
        local returnButton = CreateFrame("Button", nil, titleBar, "UIPanelButtonTemplate")
        returnButton:SetSize(60, 16)
        returnButton:SetPoint("RIGHT", titleBar, "RIGHT", 0, 0)
        returnButton:SetText("Return All")
        returnButton:SetNormalFontObject("GameFontNormalSmall")
        returnButton:SetEnabled(false)  -- Start disabled
        returnButton:SetScript("OnClick", function()
            self:return_all_opt_out_cards(rosterBoard)
        end)
        returnButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Return All Players", 1, 1, 1)
            GameTooltip:AddLine("Move all opt-out players back to the bench", nil, nil, nil, true)
            GameTooltip:Show()
        end)
        returnButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Store reference for enable/disable control
        optOut.returnButton = returnButton
        
        local innerPadding = math.max(12, math.floor(padding * 0.6))
        local scrollbarPadding = 18

        local scrollFrame = CreateFrame("ScrollFrame", nil, optOut, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", optOut, "TOPLEFT", innerPadding, -34)
        scrollFrame:SetPoint("BOTTOMRIGHT", optOut, "BOTTOMRIGHT", -(innerPadding + scrollbarPadding), innerPadding)
        scrollFrame:Show()
        
        -- Enable mouse wheel for horizontal scrolling
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetHorizontalScroll()
            local maxScroll = self:GetHorizontalScrollRange()
            local newScroll = math.max(0, math.min(current - (delta * 40), maxScroll))
            self:SetHorizontalScroll(newScroll)
        end)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(1, optOutHeight - (innerPadding * 2))
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:Show()
        
        -- Store references
        optOut.scrollFrame = scrollFrame
        optOut.scrollChild = scrollChild
        optOut.playerCards = {}
        optOut.frame = optOut  -- For compatibility
        optOut.innerPadding = innerPadding
        
        rosterBoard.optOutSection = optOut
        
        Debug:Dev("organizer_ui", "Created opt-out section with width", optOut:GetWidth())
        
    end, "SlotManager:create_opt_out_section")
end

-- MARK: Slot Creation
--- Create a single flat role slot
-- @param parentContainer Parent container frame
-- @param groupIndex Group number
-- @param role Role type (TANK, HEALER, DAMAGER)
-- @param roleLabel Display label
-- @param slotIndex Slot index within group
-- @param xPos X position
-- @param yPos Y position
-- @return frame Slot frame
function SlotManager:create_flat_role_slot(parentContainer, groupIndex, role, roleLabel, slotIndex, xPos, yPos, width, height)
    local organizerConfig = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}

    local slot = CreateFrame("Frame", nil, parentContainer, "BackdropTemplate")
    slot:SetPoint("TOPLEFT", parentContainer, "TOPLEFT", xPos, yPos)
    slot:SetSize(width or 150, height or organizerConfig.SLOT_HEIGHT or 96)
    slot:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    slot:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

    local borderColor = {r = 0.5, g = 0.5, b = 0.5}
    if role == "TANK" then
        borderColor = {r = 0.2, g = 0.5, b = 1.0}
    elseif role == "HEALER" then
        borderColor = {r = 0.1, g = 0.9, b = 0.1}
    elseif role == "DAMAGER" then
        borderColor = {r = 0.9, g = 0.1, b = 0.1}
    end
    slot:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, 1.0)

    local emptyLabel = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyLabel:SetPoint("CENTER")
    emptyLabel:SetText(roleLabel)
    emptyLabel:SetTextColor(0.7, 0.7, 0.7)

    slot:EnableMouse(true)
    slot:SetFrameLevel(parentContainer:GetFrameLevel() + 20)
    slot:Show()

    Debug:Dev(
        "organizer_ui",
        "Created slot",
        groupIndex,
        slotIndex,
        roleLabel,
        "size",
        slot:GetWidth(),
        "x",
        slot:GetHeight()
    )

    slot.groupIndex = groupIndex
    slot.role = role
    slot.roleLabel = roleLabel
    slot.slotIndex = slotIndex
    slot.playerCard = nil
    slot.emptyLabel = emptyLabel
    slot.isEmpty = true
    slot.frame = slot

    return slot
end

-- MARK: Card Placement
--- Place a card into a role slot
-- @param card Player card frame
-- @param slot Slot frame
function SlotManager:place_card_in_slot(card, slot)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "Placing card in slot:", slot.groupIndex, slot.roleLabel)
        
        -- Hide empty label
        if slot.emptyLabel then
            slot.emptyLabel:Hide()
        end
        
        local innerPadding = slot.innerPadding or 6
        local targetWidth = slot:GetWidth() - (innerPadding * 2)
        local targetHeight = slot:GetHeight() - (innerPadding * 2)

        -- Update card size and position for expanded mode
        card:SetParent(slot)
        card:ClearAllPoints()
        card:SetSize(targetWidth, targetHeight)
        card:SetPoint("TOPLEFT", slot, "TOPLEFT", innerPadding, -innerPadding)
        
        -- Update card metadata
        card.location = {
            type = "role_slot",
            groupIndex = slot.groupIndex,
            slotIndex = slot.slotIndex,
            role = slot.role
        }
        
        -- Update card content to expanded mode
        NextKey222.PlayerCard:UpdateCardContent(card, "expanded")
        
        -- Store in slot
        slot.playerCard = card
        slot.isEmpty = false
        
        -- Reset colors
        card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
        card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
        
        card:Show()
        
        -- CRITICAL FIX: Save to OrganizerState for persistence
        if card.playerData and card.playerData.id then
            NextKey222.OrganizerState:MoveToSlot(card.playerData.id, slot.groupIndex, slot.slotIndex)
            Debug:Dev("organizer_ui", "Saved player to OrganizerState - group", slot.groupIndex, "slot", slot.slotIndex)
        end
        
        Debug:Dev("organizer_ui", "Card placed in slot successfully")
        
        -- Update Recall All button state
        if NextKey222.BenchManager and NextKey222.BenchManager.update_recall_button_state then
            NextKey222.BenchManager:update_recall_button_state(NextKey222.RosterBoard)
        end
        
    end, "SlotManager:place_card_in_slot")
end

--- Place a card into the opt-out section
-- @param rosterBoard RosterBoard instance
-- @param card Player card frame
function SlotManager:place_card_in_opt_out(rosterBoard, card)
    return NextKey222.SafeRun(function()
        Debug:Dev("organizer_ui", "Placing card in opt-out")
        
        -- Check if card's keystone was designated
        if card.location and
           type(card.location) == "table" and
           card.location.type == "role_slot" then
            
            local groupIndex = card.location.groupIndex
            
            if NextKey222.KeystoneManager:is_keystone_designated(rosterBoard, groupIndex, card.playerData.id) then
                NextKey222.KeystoneManager:clear_group_keystone(rosterBoard, groupIndex)
                Debug:Dev("organizer", "Cleared keystone - card removed from group")
            end
        end
        
        if not rosterBoard.optOutSection or not rosterBoard.optOutSection.scrollChild then
            Debug:Error("Opt-out section not initialized")
            return
        end
        
        -- Use opt_out mode (2-line square layout)
        card:SetSize(96, 40)
        card:SetParent(rosterBoard.optOutSection.scrollChild)
        
        -- Update metadata
        card.location = {
            type = "opt_out"
        }
        
        -- Update card content to opt_out mode
        NextKey222.PlayerCard:UpdateCardContent(card, "opt_out")
        
        -- Add to opt-out array
        table.insert(rosterBoard.optOutSection.playerCards, card)
        
        -- Reset colors
        card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 0.8)
        card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
        
        -- Re-layout opt-out section horizontally
        self:layout_opt_out(rosterBoard)
        
        -- Update Return All button state
        self:update_return_button_state(rosterBoard)
        
        Debug:Dev("organizer_ui", "Card placed in opt-out successfully")
        
    end, "SlotManager:place_card_in_opt_out")
end

-- MARK: Population
--- Populate opt-out section with players
-- @param rosterBoard RosterBoard instance
-- @param players Array of playerData objects
function SlotManager:populate_opt_out(rosterBoard, players)
    if not rosterBoard.optOutSection or not rosterBoard.optOutSection.scrollChild then
        return
    end
    
    -- Clear existing cards
    for _, card in ipairs(rosterBoard.optOutSection.playerCards) do
        if card then
            card:Hide()
            card:SetParent(nil)
        end
    end
    rosterBoard.optOutSection.playerCards = {}
    
    -- Create native cards for opted-out players
    for i, playerData in ipairs(players) do
        local card = NextKey222.PlayerCard:CreateNativeCard(
            playerData,
            rosterBoard.optOutSection.scrollChild,
            "opt_out",
            "opt_out"  -- Use opt_out mode (simple two-line layout)
        )
        
        if card then
            table.insert(rosterBoard.optOutSection.playerCards, card)
        end
    end
    
    -- Layout horizontally
    self:layout_opt_out(rosterBoard)
    
    -- Update Return All button state
    self:update_return_button_state(rosterBoard)
    
    Debug:Dev("organizer_ui", "Populated opt-out with", #players, "players")
end

-- MARK: Layout Management
--- Layout opt-out cards horizontally
-- @param rosterBoard RosterBoard instance
function SlotManager:layout_opt_out(rosterBoard)
    if not rosterBoard.optOutSection or not rosterBoard.optOutSection.scrollChild or not rosterBoard.optOutSection.playerCards then
        return
    end
    
    -- MARK: Opt-Out Button Management
    --- Update the enabled/disabled state of the Return All button
    -- @param rosterBoard RosterBoard instance
    function SlotManager:update_return_button_state(rosterBoard)
        if not rosterBoard.optOutSection or not rosterBoard.optOutSection.returnButton then
            return
        end
        
        local hasOptOutCards = rosterBoard.optOutSection.playerCards and
                              #rosterBoard.optOutSection.playerCards > 0
        
        rosterBoard.optOutSection.returnButton:SetEnabled(hasOptOutCards)
        Debug:Dev("organizer_ui", "Return button state:", hasOptOutCards and "ENABLED" or "DISABLED")
    end
    
    --- Return all opt-out player cards back to the bench
    -- @param rosterBoard RosterBoard instance
    function SlotManager:return_all_opt_out_cards(rosterBoard)
        return NextKey222.SafeRun(function()
            if not rosterBoard.optOutSection or not rosterBoard.optOutSection.playerCards then
                return
            end
            
            local cards = rosterBoard.optOutSection.playerCards
            local totalCards = #cards
            
            if totalCards == 0 then
                Debug:User("No opt-out players to return")
                return
            end
            
            -- Disable button during operation
            if rosterBoard.optOutSection.returnButton then
                rosterBoard.optOutSection.returnButton:SetEnabled(false)
            end
            
            Debug:User("Returning " .. totalCards .. " opt-out players to bench...")
            
            -- Move each card back to bench
            for i = #cards, 1, -1 do
                local card = cards[i]
                
                if card and card.playerData then
                    -- Update state in OrganizerState
                    NextKey222.OrganizerState:MoveToBench(card.playerData.id)
                    
                    -- CRITICAL: Refresh card data from state before moving
                    -- This ensures role icons and preferences are up-to-date
                    local freshPlayerData = NextKey222.OrganizerState:GetPlayer(card.playerData.id)
                    if freshPlayerData then
                        -- BUG FIX: roles field reconstruction
                        -- OrganizerState may not preserve the roles array, so rebuild it
                        if not freshPlayerData.roles or #freshPlayerData.roles == 0 then
                            -- Try to get roles from multiple sources
                            if freshPlayerData.role then
                                -- Use singular role field if present
                                freshPlayerData.roles = {freshPlayerData.role}
                            else
                                -- Fallback: Get current role from profile
                                local profile = NextKey222.ProfilesService and NextKey222.ProfilesService:GetProfile(card.playerData.id)
                                if profile and profile.role then
                                    freshPlayerData.roles = {profile.role}
                                else
                                    -- Last resort: preserve existing roles or use default
                                    freshPlayerData.roles = card.playerData.roles or {"DAMAGER"}
                                end
                            end
                        end
                        
                        card.playerData = freshPlayerData
                    end
                    
                    -- Move card to bench visually
                    if NextKey222.CardMovement and NextKey222.CardMovement.place_card_in_bench then
                        NextKey222.CardMovement:place_card_in_bench(rosterBoard, card)
                    end
                    
                    Debug:Dev("organizer_ui", "Returned player to bench:", card.playerData.name)
                end
                
                -- Remove from opt-out array
                table.remove(cards, i)
            end
            
            -- Re-layout opt-out section (should be empty now)
            self:layout_opt_out(rosterBoard)
            
            -- Re-layout bench with returned cards
            if NextKey222.BenchManager and NextKey222.BenchManager.layout_bench then
                NextKey222.BenchManager:layout_bench(rosterBoard)
            end
            
            -- Update button state (should be disabled now)
            self:update_return_button_state(rosterBoard)
            
            Debug:User("Return complete!")
            
        end, "SlotManager:return_all_opt_out_cards")
    end
    
    local config = NextKey222.UIConfig and NextKey222.UIConfig.ORGANIZER or {}
    local spacing = config.BENCH_CARD_SPACING or 6
    local cardWidth = 96
    local cardHeight = 40
    local innerPadding = rosterBoard.optOutSection.innerPadding or 12
    
    Debug:Dev("organizer_ui", "Laying out", #rosterBoard.optOutSection.playerCards, "opt-out cards horizontally")
    
    local xOffset = 0
    for i, card in ipairs(rosterBoard.optOutSection.playerCards) do
        card:ClearAllPoints()
        card:SetParent(rosterBoard.optOutSection.scrollChild)
        card:SetPoint("TOPLEFT", rosterBoard.optOutSection.scrollChild, "TOPLEFT", xOffset, -innerPadding / 2)
        card:SetSize(cardWidth, cardHeight)
        card:Show()
        xOffset = xOffset + cardWidth + spacing
    end
    
    -- Update scroll child width for horizontal scrolling
    rosterBoard.optOutSection.scrollChild:SetWidth(math.max(xOffset, 1))
    rosterBoard.optOutSection.scrollChild:SetHeight(cardHeight + innerPadding)
    
    Debug:Dev("organizer_ui", "Opt-out layout complete, total width:", xOffset)
end

-- MARK: Group Control Buttons (Add/Remove)
--- Add control buttons to group title bar (only on last group)
-- @param groupFrame Parent group frame
-- @param groupIndex Current group index
-- @param totalGroups Total number of groups
-- @param rosterBoard RosterBoard instance
function SlotManager:add_group_control_buttons(groupFrame, groupIndex, totalGroups, rosterBoard)
    local config = NextKey222.UIConfig.ORGANIZER
    local buttonSize = config.GROUP_BUTTON_SIZE or 20
    local spacing = config.GROUP_BUTTON_SPACING or 3
    local margin = config.GROUP_BUTTON_RIGHT_MARGIN or 2
    
    -- Remove Group button [-]
    local removeButton = CreateFrame("Button", nil, groupFrame)
    removeButton:SetSize(buttonSize, buttonSize)
    removeButton:SetPoint("TOPRIGHT", groupFrame, "TOPRIGHT", -(buttonSize + spacing + margin), -4)
    
    -- Button background/border (using WoW's built-in minimize button texture)
    removeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    removeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    removeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    
    -- Click handler
    removeButton:SetScript("OnClick", function()
        self:on_remove_group_clicked(groupIndex, rosterBoard)
    end)
    
    -- Tooltip
    removeButton:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Remove Group " .. groupIndex, 1, 1, 1)
        GameTooltip:AddLine("Moves players to bench", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    removeButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Hide if only 1 group
    if totalGroups <= 1 then
        removeButton:Hide()
    end
    
    -- Add Group button [+]
    local addButton = CreateFrame("Button", nil, groupFrame)
    addButton:SetSize(buttonSize, buttonSize)
    addButton:SetPoint("TOPRIGHT", groupFrame, "TOPRIGHT", -margin, -4)
    
    -- Button background/border (using WoW's built-in plus button texture)
    addButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    addButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
    addButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Highlight", "ADD")
    
    -- Click handler
    addButton:SetScript("OnClick", function()
        self:on_add_group_clicked(groupIndex, rosterBoard)
    end)
    
    -- Tooltip
    addButton:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Add Group " .. (groupIndex + 1), 1, 1, 1)
        GameTooltip:AddLine("Creates new empty group", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    addButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- Disable if at max (8 groups = 40 players max)
    if totalGroups >= 8 then
        addButton:Disable()
        addButton:SetAlpha(0.5)
    end
    
    -- Store references for cleanup
    table.insert(rosterBoard.allInteractiveFrames, removeButton)
    table.insert(rosterBoard.allInteractiveFrames, addButton)
end

--- Handle add group button click
-- @param currentGroupIndex Index of group with the button
-- @param rosterBoard RosterBoard instance
function SlotManager:on_add_group_clicked(currentGroupIndex, rosterBoard)
    return NextKey222.SafeRun(function()
        -- Validate max limit (8 groups = 40 players)
        local currentCount = #rosterBoard.groupSlots
        if currentCount >= 8 then
            Debug:User("Maximum 8 groups allowed")
            return
        end
        
        Debug:Dev("organizer", "Adding group " .. (currentCount + 1))
        
        -- Set manual group count override
        rosterBoard.manualGroupCount = currentCount + 1
        
        -- Rebuild entire UI with new layout
        rosterBoard:RebuildMainFrame()
        
        Debug:User("Added group " .. (currentCount + 1))
        
    end, "SlotManager:on_add_group_clicked")
end

--- Handle remove group button click
-- @param groupIndex Index of group to remove
-- @param rosterBoard RosterBoard instance
function SlotManager:on_remove_group_clicked(groupIndex, rosterBoard)
    return NextKey222.SafeRun(function()
        -- Validate min limit
        local currentCount = #rosterBoard.groupSlots
        if currentCount <= 1 then
            Debug:User("Must have at least 1 group")
            return
        end
        
        Debug:Dev("organizer", "Removing group " .. groupIndex)
        
        -- Check if this group has players
        local hasPlayers = false
        if rosterBoard.groupSlots[groupIndex] then
            for _, slot in pairs(rosterBoard.groupSlots[groupIndex]) do
                if slot.playerCard then
                    hasPlayers = true
                    break
                end
            end
        end
        
        -- Move players to bench if needed
        if hasPlayers then
            for _, slot in pairs(rosterBoard.groupSlots[groupIndex]) do
                if slot.playerCard and slot.playerCard.playerID then
                    NextKey222.OrganizerState:MoveToBench(slot.playerCard.playerID)
                end
            end
            Debug:User("Moved players from group " .. groupIndex .. " to bench")
        end
        
        -- Set manual group count override
        rosterBoard.manualGroupCount = currentCount - 1
        
        -- Rebuild entire UI with new layout
        rosterBoard:RebuildMainFrame()
        
        Debug:User("Removed group " .. groupIndex)
        
    end, "SlotManager:on_remove_group_clicked")
end

-- MARK: Group Data
--- Get grouped players (currently returns empty)
-- @param rosterBoard RosterBoard instance
-- @return table Array of grouped players
function SlotManager:get_grouped_players(rosterBoard)
    local success, result = NextKey222.SafeRun(function()
        return {}
    end, "SlotManager:get_grouped_players")
    
    -- SafeRun now returns (success, result), so handle properly
    if success then
        return result
    else
        return {}
    end
end
