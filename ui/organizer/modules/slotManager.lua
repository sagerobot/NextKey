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
        local groupHeight = config.GROUP_HEIGHT or 550
        local columnWidth = layout.columnWidth or config.COLUMN_WIDTH or 180
        local slotSpacing = layout.slotSpacing or config.SLOT_SPACING or 10
        local titleHeight = config.HEADER_LABEL_HEIGHT or 16
        local titleGap = config.HEADER_SECTION_GAP or 4
        local slotHorizontalPadding = 12

        local poolContainer = CreateFrame("Frame", nil, nativeParent)
        poolContainer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", padding, -headerHeight)
        poolContainer:SetPoint("TOPRIGHT", nativeParent, "TOPRIGHT", -padding, -headerHeight)
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

        local benchXOffset = (layout.groupColumns * columnWidth) + padding
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
        
        -- Title label
        local titleLabel = optOut:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleLabel:SetPoint("TOP", 0, -10)
        titleLabel:SetText("Not Playing")
        
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
        
        Debug:Dev("organizer_ui", "Card placed in slot successfully")
        
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
            "compact"  -- Use compact mode (same as bench)
        )
        
        if card then
            table.insert(rosterBoard.optOutSection.playerCards, card)
        end
    end
    
    -- Layout horizontally
    self:layout_opt_out(rosterBoard)
    
    Debug:Dev("organizer_ui", "Populated opt-out with", #players, "players")
end

-- MARK: Layout Management
--- Layout opt-out cards horizontally
-- @param rosterBoard RosterBoard instance
function SlotManager:layout_opt_out(rosterBoard)
    if not rosterBoard.optOutSection or not rosterBoard.optOutSection.scrollChild or not rosterBoard.optOutSection.playerCards then
        return
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
