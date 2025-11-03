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
        print("[ORGANIZER DIAGNOSTIC] CreateActivePoolSection (FLAT) called")
        print("[ORGANIZER DIAGNOSTIC] Parent frame strata:", nativeParent:GetFrameStrata(), "level:", nativeParent:GetFrameLevel())
        
        -- Create a pure native container frame
        local poolContainer = CreateFrame("Frame", nil, nativeParent)
        poolContainer:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 10, -90)  -- Below header
        poolContainer:SetPoint("BOTTOMRIGHT", nativeParent, "BOTTOMRIGHT", -10, 120)  -- Above opt-out
        poolContainer:Show()
        print("[ORGANIZER DIAGNOSTIC] Pool container created - Strata:", poolContainer:GetFrameStrata(), "Level:", poolContainer:GetFrameLevel())
        
        Debug:Dev("organizer_ui", "Created pool container with flat architecture")
        
        local layout = rosterBoard:CalculateOptimalLayout()
        print("[ORGANIZER DIAGNOSTIC] Layout - groups:", layout.groupColumns)
        
        -- Initialize arrays
        rosterBoard.groupBackgrounds = {}
        rosterBoard.groupSlots = {}
        rosterBoard.groupTitles = {}
        rosterBoard.groupKeystones = {}
        rosterBoard.allInteractiveFrames = {}
        
        -- Create visual backgrounds and interactive slots (all as siblings)
        local columnWidth = 170
        local columnSpacing = 10
        
        for groupIndex = 1, layout.groupColumns do
            local groupXOffset = (groupIndex - 1) * (columnWidth + columnSpacing)
            
            print("[ORGANIZER DIAGNOSTIC] Creating group", groupIndex, "at xOffset:", groupXOffset)
            
            -- Create visual background texture (non-interactive)
            local bgTexture = poolContainer:CreateTexture(nil, "BACKGROUND")
            bgTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
            bgTexture:SetPoint("TOPLEFT", poolContainer, "TOPLEFT", groupXOffset, 0)
            bgTexture:SetSize(columnWidth, 550)
            bgTexture:SetDrawLayer("BACKGROUND", -5)  -- Way back
            rosterBoard.groupBackgrounds[groupIndex] = bgTexture
            
            -- Create title label (sibling of slots)
            local titleLabel = poolContainer:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            titleLabel:SetPoint("TOPLEFT", poolContainer, "TOPLEFT", groupXOffset + (columnWidth / 2), -10)
            titleLabel:SetJustifyH("CENTER")
            titleLabel:SetText("M+ Grp. " .. groupIndex)
            titleLabel:SetDrawLayer("ARTWORK", 5)  -- Above backgrounds, below slots
            rosterBoard.groupTitles[groupIndex] = titleLabel  -- Store for later updates
            
            -- Initialize keystone data
            rosterBoard.groupKeystones[groupIndex] = {keystone = nil, playerID = nil}
            
            -- Create role slots as direct children of poolContainer (NOT nested)
            rosterBoard.groupSlots[groupIndex] = {}
            local roles = {"TANK", "HEALER", "DAMAGER", "DAMAGER", "DAMAGER"}
            local roleLabels = {"Tank", "Healer", "DPS", "DPS", "DPS"}
            
            for slotIndex, role in ipairs(roles) do
                local slotYOffset = 35 + ((slotIndex - 1) * 98)  -- Title space + (slot height + spacing)
                
                local slot = self:create_flat_role_slot(
                    poolContainer,
                    groupIndex,
                    role,
                    roleLabels[slotIndex],
                    slotIndex,
                    groupXOffset + 10,  -- X: column offset + padding
                    -slotYOffset         -- Y: negative for downward positioning
                )
                
                rosterBoard.groupSlots[groupIndex][slotIndex] = slot
                table.insert(rosterBoard.allInteractiveFrames, slot)  -- Strong reference
                
                print("[ORGANIZER DIAGNOSTIC] Created slot", groupIndex, slotIndex, roleLabels[slotIndex], "at:", groupXOffset + 10, -slotYOffset)
            end
        end
        
        print("[ORGANIZER DIAGNOSTIC] Created", #rosterBoard.groupSlots, "groups with", #rosterBoard.allInteractiveFrames, "total slots")
        
        -- Create bench (also as sibling) - DELEGATE TO BENCHMANAGER
        local benchXOffset = layout.groupColumns * (columnWidth + columnSpacing)
        local benchColumn = NextKey222.BenchManager:create_native_bench_column(rosterBoard, layout.benchWidth, poolContainer)
        benchColumn:SetPoint("TOPLEFT", poolContainer, "TOPLEFT", benchXOffset, 0)
        
        rosterBoard.activePoolSection = poolContainer
        
        Debug:Dev("organizer_ui", "Active pool section created with flat architecture")
        
    end, "SlotManager:create_active_pool_section")
end

--- Create the opt-out section with horizontal scrolling
-- @param rosterBoard RosterBoard instance
-- @param nativeParent Parent frame
function SlotManager:create_opt_out_section(rosterBoard, nativeParent)
    return NextKey222.SafeRun(function()
        -- Create pure native opt-out frame
        local optOut = CreateFrame("Frame", nil, nativeParent, "BackdropTemplate")
        optOut:SetPoint("BOTTOMLEFT", nativeParent, "BOTTOMLEFT", 10, 15)
        optOut:SetPoint("BOTTOMRIGHT", nativeParent, "BOTTOMRIGHT", -10, 15)
        optOut:SetHeight(95)
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
        
        -- Create native scroll frame inside (HORIZONTAL scrolling)
        local scrollFrame = CreateFrame("ScrollFrame", nil, optOut, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
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
        scrollChild:SetSize(1, 30)  -- Start with minimal width, height for single row
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:Show()
        
        -- Store references
        optOut.scrollFrame = scrollFrame
        optOut.scrollChild = scrollChild
        optOut.playerCards = {}
        optOut.frame = optOut  -- For compatibility
        
        rosterBoard.optOutSection = optOut
        
        Debug:Dev("organizer_ui", "Created FULLY NATIVE opt-out section with horizontal scrolling")
        
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
function SlotManager:create_flat_role_slot(parentContainer, groupIndex, role, roleLabel, slotIndex, xPos, yPos)
    -- Create slot frame as direct child of poolContainer (NOT nested in column)
    local slot = CreateFrame("Frame", nil, parentContainer, "BackdropTemplate")
    slot:SetSize(150, 95)
    slot:SetPoint("TOPLEFT", parentContainer, "TOPLEFT", xPos, yPos)
    slot:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    slot:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    
    -- Role-colored border
    local borderColor = {r=0.5, g=0.5, b=0.5}
    if role == "TANK" then
        borderColor = {r=0.2, g=0.5, b=1.0}
    elseif role == "HEALER" then
        borderColor = {r=0.1, g=0.9, b=0.1}
    elseif role == "DAMAGER" then
        borderColor = {r=0.9, g=0.1, b=0.1}
    end
    slot:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, 1.0)
    
    -- Empty label
    local emptyLabel = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyLabel:SetPoint("CENTER")
    emptyLabel:SetText(roleLabel)
    emptyLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Enable mouse for drop detection (CRITICAL)
    slot:EnableMouse(true)
    slot:SetFrameLevel(parentContainer:GetFrameLevel() + 50)  -- WAY above parent
    slot:Show()
    
    print("[SLOT DIAGNOSTIC]", roleLabel, "Level:", slot:GetFrameLevel(), "Parent level:", parentContainer:GetFrameLevel())
    Debug:Dev("organizer_ui", "Created FLAT slot:", groupIndex, slotIndex, roleLabel, "Strata:", slot:GetFrameStrata(), "Level:", slot:GetFrameLevel())
    
    -- Store metadata
    slot.groupIndex = groupIndex
    slot.role = role
    slot.roleLabel = roleLabel
    slot.slotIndex = slotIndex
    slot.playerCard = nil
    slot.emptyLabel = emptyLabel
    slot.isEmpty = true
    slot.frame = slot  -- For compatibility
    
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
        
        -- Update card size and position for expanded mode
        card:SetSize(145, 90)  -- Expanded
        card:SetParent(slot)
        card:ClearAllPoints()
        card:SetPoint("CENTER", slot, "CENTER", 0, 0)
        
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
        card:SetSize(90, 40)  -- Opt-out size (square-ish for 2-line)
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
    
    local xOffset = 0
    local spacing = 5
    local cardWidth = 90  -- Opt-out width (square-ish)
    local cardHeight = 40  -- Opt-out height (2-line)
    
    Debug:Dev("organizer_ui", "Laying out", #rosterBoard.optOutSection.playerCards, "opt-out cards horizontally")
    
    for i, card in ipairs(rosterBoard.optOutSection.playerCards) do
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", rosterBoard.optOutSection.scrollChild, "TOPLEFT", xOffset, 0)
        card:SetSize(cardWidth, cardHeight)
        card:SetParent(rosterBoard.optOutSection.scrollChild)
        card:Show()
        xOffset = xOffset + cardWidth + spacing
    end
    
    -- Update scroll child width for horizontal scrolling
    rosterBoard.optOutSection.scrollChild:SetWidth(math.max(xOffset, 1))
    rosterBoard.optOutSection.scrollChild:SetHeight(cardHeight + 10)
    
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