-- MARK: Simple Drag Test
local _, NextKey222 = ...

local SimpleDragTest = {}
NextKey222.SimpleDragTest = SimpleDragTest

-- State
local testFrame = nil

-- Sub-list structures (nested within listA)
local tankSlot = {
    cards = {},
    frame = nil,
    label = nil,
    maxCapacity = 1,
    roleFilter = "TANK",
    slotName = "Tank",
    parentList = nil  -- Will be set to listA
}

local healerSlot = {
    cards = {},
    frame = nil,
    label = nil,
    maxCapacity = 1,
    roleFilter = "HEALER",
    slotName = "Healer",
    parentList = nil
}

local dpsSlots = {
    cards = {},
    frame = nil,
    label = nil,
    maxCapacity = 3,
    roleFilter = "DAMAGER",
    slotName = "DPS",
    parentList = nil
}

-- Parent list with nested sub-lists
local listA = {
    subLists = {},  -- Will contain tankSlot, healerSlot, dpsSlots
    frame = nil,
    label = nil,
    totalCapacity = 5,
    
    -- Get total cards across all sub-lists
    getTotalCards = function(self)
        local count = 0
        for _, subList in ipairs(self.subLists) do
            count = count + #subList.cards
        end
        return count
    end,
    
    -- Check if we can accept a card (finds appropriate sub-list)
    canAcceptCard = function(self, card)
        -- Check total capacity first
        if self:getTotalCards() >= self.totalCapacity then
            return false, nil, "Group full"
        end
        
        -- Find appropriate sub-list based on role
        for _, subList in ipairs(self.subLists) do
            local canAccept, reason = subList:canAcceptCard(card)
            if canAccept then
                return true, subList, nil
            end
        end
        
        return false, nil, "No suitable slot"
    end
}

-- Helper function for sub-lists to check if they can accept a card
function tankSlot:canAcceptCard(card)
    if #self.cards >= self.maxCapacity then
        return false, "Tank slot full"
    end
    if self.roleFilter and card.role ~= self.roleFilter then
        return false, "Need TANK role"
    end
    return true, nil
end

function healerSlot:canAcceptCard(card)
    if #self.cards >= self.maxCapacity then
        return false, "Healer slot full"
    end
    if self.roleFilter and card.role ~= self.roleFilter then
        return false, "Need HEALER role"
    end
    return true, nil
end

function dpsSlots:canAcceptCard(card)
    if #self.cards >= self.maxCapacity then
        return false, "DPS slots full"
    end
    if self.roleFilter and card.role ~= self.roleFilter then
        return false, "Need DAMAGER role"
    end
    return true, nil
end

-- Link sub-lists to parent
tankSlot.parentList = listA
healerSlot.parentList = listA
dpsSlots.parentList = listA
listA.subLists = {tankSlot, healerSlot, dpsSlots}

local listB = { cards = {}, frame = nil, label = nil, scrollFrame = nil, scrollChild = nil, maxCapacity = 999 }
local isDragging = false
local cardCounter = 0

-- Class colors (from WoW)
local CLASS_COLORS = {
    WARRIOR = {r=0.78, g=0.61, b=0.43},
    PALADIN = {r=0.96, g=0.55, b=0.73},
    HUNTER = {r=0.67, g=0.83, b=0.45},
    ROGUE = {r=1.00, g=0.96, b=0.41},
    PRIEST = {r=1.00, g=1.00, b=1.00},
    DEATHKNIGHT = {r=0.77, g=0.12, b=0.23},
    SHAMAN = {r=0.00, g=0.44, b=0.87},
    MAGE = {r=0.25, g=0.78, b=0.92},
    WARLOCK = {r=0.53, g=0.53, b=0.93},
    MONK = {r=0.00, g=1.00, b=0.59},
    DRUID = {r=1.00, g=0.49, b=0.04},
    DEMONHUNTER = {r=0.64, g=0.19, b=0.79},
    EVOKER = {r=0.20, g=0.58, b=0.50},
}

-- Role border colors
local ROLE_COLORS = {
    TANK = {r=0.2, g=0.5, b=1.0},
    HEALER = {r=0.1, g=0.9, b=0.1},
    DAMAGER = {r=0.9, g=0.1, b=0.1},
}

local CLASSES = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER"}
local ROLES = {"TANK", "HEALER", "DAMAGER"}

-- MARK: Create Test Window
function SimpleDragTest:Show()
    if testFrame then
        testFrame:Show()
        return
    end
    
    -- Create main window frame (taller for scrolling)
    testFrame = CreateFrame("Frame", "NextKeyDragTestFrame", UIParent, "BasicFrameTemplateWithInset")
    testFrame:SetSize(480, 320)
    testFrame:SetPoint("CENTER")
    testFrame:SetMovable(true)
    testFrame:EnableMouse(true)
    testFrame:RegisterForDrag("LeftButton")
    testFrame:SetScript("OnDragStart", testFrame.StartMoving)
    testFrame:SetScript("OnDragStop", testFrame.StopMovingOrSizing)
    
    testFrame.title = testFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    testFrame.title:SetPoint("TOP", 0, -5)
    testFrame.title:SetText("Drag Test - Class/Role Colors")
    
    -- Debug: Check if InsetFrame exists
    if not testFrame.InsetFrame then
        print("[DRAG TEST ERROR] InsetFrame doesn't exist! Creating simple container instead.")
        -- Create our own content frame
        local contentFrame = CreateFrame("Frame", nil, testFrame)
        contentFrame:SetPoint("TOPLEFT", 10, -30)
        contentFrame:SetPoint("BOTTOMRIGHT", -10, 10)
        testFrame.InsetFrame = contentFrame
    end
    
    -- Create List A (Group container with nested sub-lists)
    listA.frame = CreateFrame("Frame", nil, testFrame.InsetFrame, "BackdropTemplate")
    listA.frame:SetSize(180, 240)  -- Taller to accommodate nested slots
    listA.frame:SetPoint("LEFT", testFrame.InsetFrame, "LEFT", 20, 10)
    listA.frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    listA.label = listA.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    listA.label:SetPoint("TOP", 0, -10)
    listA.label:SetText("Group (0/5)")
    
    -- Create sub-list frames within Group
    for _, subList in ipairs(listA.subLists) do
        subList.frame = CreateFrame("Frame", nil, listA.frame, "BackdropTemplate")
        subList.frame:SetSize(160, 50)  -- Will be resized dynamically
        subList.frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 2,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        subList.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        
        -- Role-specific border colors
        local roleColor = ROLE_COLORS[subList.roleFilter]
        if roleColor then
            subList.frame:SetBackdropBorderColor(roleColor.r, roleColor.g, roleColor.b, 1.0)
        else
            subList.frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1.0)
        end
        
        subList.label = subList.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        subList.label:SetPoint("TOP", 0, -5)
        subList.label:SetText(subList.slotName .. " (0/" .. subList.maxCapacity .. ")")
    end
    
    -- Create List B with ScrollFrame (Bench - compact cards)
    listB.frame = CreateFrame("Frame", nil, testFrame.InsetFrame, "BackdropTemplate")
    listB.frame:SetSize(180, 180)
    listB.frame:SetPoint("RIGHT", testFrame.InsetFrame, "RIGHT", -20, 10)
    listB.frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    listB.label = listB.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    listB.label:SetPoint("TOP", 0, -10)
    listB.label:SetText("Bench")
    
    -- Create ScrollFrame for List B
    listB.scrollFrame = CreateFrame("ScrollFrame", nil, listB.frame, "UIPanelScrollFrameTemplate")
    listB.scrollFrame:SetPoint("TOPLEFT", 10, -30)
    listB.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    listB.scrollChild = CreateFrame("Frame", nil, listB.scrollFrame)
    listB.scrollChild:SetSize(140, 1)
    listB.scrollFrame:SetScrollChild(listB.scrollChild)
    listB.cards = {}
    
    -- Helper function to create a card
    local function CreateCard(class, role, name)
        cardCounter = cardCounter + 1
        local classColor = CLASS_COLORS[class]
        local roleColor = ROLE_COLORS[role]
        
        local card = CreateFrame("Button", nil, listB.scrollChild, "BackdropTemplate")
        card:SetSize(140, 20)  -- Start compact for bench
        card:SetMovable(true)
        card:SetResizable(false)
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 3,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        card:SetBackdropColor(classColor.r, classColor.g, classColor.b, 1.0)
        card:SetBackdropBorderColor(roleColor.r, roleColor.g, roleColor.b, 1)
        
        card.text = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.text:SetPoint("CENTER")
        card.text:SetText(name)
        
        -- Store card data
        card.class = class
        card.role = role
        card.classColor = classColor
        card.roleColor = roleColor
        card.playerName = name
        
        -- Store reference to the list TABLE
        card.listTable = listB
        
        -- Drag functionality
        card:RegisterForDrag("LeftButton")
        card:SetScript("OnDragStart", function(self)
            -- CRITICAL: Reparent to UIParent during drag to avoid ScrollFrame clipping
            self.originalParent = self:GetParent()
            self:SetParent(UIParent)
            self:SetFrameStrata("TOOLTIP")
            
            -- Store original position and index for potential rejection
            self.originalIndex = nil
            for i, c in ipairs(self.listTable.cards) do
                if c == self then
                    self.originalIndex = i
                    break
                end
            end
            
            -- Store original position coordinates
            self.originalX, self.originalY = self:GetCenter()
            
            -- Don't remove from list yet - preserve position during drag
            -- This prevents the gap from closing
            
            self:StartMoving()
            isDragging = true
            self:SetBackdropColor(self.classColor.r, self.classColor.g, self.classColor.b, 0.5)
            self:SetBackdropBorderColor(1, 1, 0, 1)
        end)
        
        card:SetScript("OnDragStop", function(self)
            if not isDragging then return end -- Guard against rogue events
            self:StopMovingOrSizing()
            isDragging = false
            
            -- Reset frame strata
            self:SetFrameStrata("MEDIUM")

            -- FIRST: Remove the card from its original list.
            for i, cardInList in ipairs(self.listTable.cards) do
                if cardInList == self then
                    table.remove(self.listTable.cards, i)
                    break
                end
            end
            
            -- Hierarchical drop target detection
            local targetList = nil
            local targetType = nil
            
            -- Check sub-lists first (highest priority)
            for _, subList in ipairs(listA.subLists) do
                if subList.frame:IsMouseOver() then
                    targetList = subList
                    targetType = "sublist"
                    print("[DRAG TEST] Mouse over " .. subList.slotName .. " slot")
                    break
                end
            end
            
            -- Check parent group if no sub-list hit
            if not targetList and listA.frame:IsMouseOver() then
                targetList = listA
                targetType = "parent"
                print("[DRAG TEST] Mouse over Group (parent) - will auto-assign")
            end
            
            -- Check bench as alternative
            if not targetList and listB.frame:IsMouseOver() then
                targetList = listB
                targetType = "bench"
                print("[DRAG TEST] Mouse over Bench")
            end
            
            if not targetList then
                print("[DRAG TEST] No valid drop target detected")
                -- Return to original list
                table.insert(self.listTable.cards, self.originalIndex, self)
                self:SetParent(self.listTable == listB and listB.scrollChild or (self.listTable.frame or listA.frame))
                self:Show()
                SimpleDragTest:LayoutList(self.listTable)
                SimpleDragTest:LayoutGroupList()
                self:SetBackdropColor(self.classColor.r, self.classColor.g, self.classColor.b, 1.0)
                self:SetBackdropBorderColor(self.roleColor.r, self.roleColor.g, self.roleColor.b, 1)
                return
            end
            
            -- Validate drop based on target type
            local isValid = false
            local rejectionReason = nil
            local actualTargetList = targetList
            
            if targetType == "sublist" then
                -- Direct drop into sub-list
                local canAccept, reason = targetList:canAcceptCard(self)
                if canAccept then
                    isValid = true
                else
                    isValid = false
                    rejectionReason = reason
                end
                
            elseif targetType == "parent" then
                -- Auto-assign to appropriate sub-list
                local canAccept, subList, reason = targetList:canAcceptCard(self)
                if canAccept then
                    isValid = true
                    actualTargetList = subList
                    print("[DRAG TEST] Auto-assigning to " .. subList.slotName)
                else
                    isValid = false
                    rejectionReason = reason
                end
                
            elseif targetType == "bench" then
                -- Bench always accepts
                isValid = true
            end
            
            if not isValid then
                -- REJECTION: Animate bounce-back
                SimpleDragTest:AnimateRejection(self, self.listTable, rejectionReason)
                print("[DRAG TEST] REJECTED: " .. (rejectionReason or "Unknown reason"))
                return
            end
            
            -- VALID DROP: Add to target list
            table.insert(actualTargetList.cards, self)
            
            -- Set parent and size based on target
            if targetType == "bench" then
                self:SetParent(listB.scrollChild)
                self:SetSize(140, 20)  -- Compact
                self.text:SetFontObject("GameFontNormalSmall")
                print("[DRAG TEST] Moving to Bench")
            else
                -- Moving to a sub-list
                self:SetParent(actualTargetList.frame)
                self:SetSize(140, 40)  -- Expanded
                self.text:SetFontObject("GameFontNormal")
                print("[DRAG TEST] Moving to " .. actualTargetList.slotName)
            end
            
            self.listTable = actualTargetList
            
            -- Show and re-layout
            self:Show()
            SimpleDragTest:LayoutGroupList()
            SimpleDragTest:LayoutList(listB)
            
            print("[DRAG TEST] Moved " .. self.playerName .. " successfully")
            
            -- Reset colors
            self:SetBackdropColor(self.classColor.r, self.classColor.g, self.classColor.b, 1.0)
            self:SetBackdropBorderColor(self.roleColor.r, self.roleColor.g, self.roleColor.b, 1)
        end)
        
        return card
    end
    
    -- Create initial cards (2 in bench)
    local card1 = CreateCard("WARRIOR", "TANK", "Tanky")
    table.insert(listB.cards, card1)
    
    local card2 = CreateCard("PRIEST", "HEALER", "Healy")
    table.insert(listB.cards, card2)
    
    -- Initial layout
    SimpleDragTest:LayoutGroupList()
    SimpleDragTest:LayoutList(listB)
    
    -- Add Card button
    local addButton = CreateFrame("Button", nil, testFrame, "UIPanelButtonTemplate")
    addButton:SetSize(100, 22)
    addButton:SetPoint("BOTTOM", testFrame, "BOTTOM", 0, 10)
    addButton:SetText("Add Card")
    addButton:SetScript("OnClick", function()
        local randomClass = CLASSES[math.random(#CLASSES)]
        local randomRole = ROLES[math.random(#ROLES)]
        local randomName = "Player" .. cardCounter
        
        local newCard = CreateCard(randomClass, randomRole, randomName)
        table.insert(listB.cards, newCard)
        SimpleDragTest:LayoutList(listB)
        
        print("[DRAG TEST] Added " .. randomName .. " (" .. randomClass .. "/" .. randomRole .. ")")
    end)
    
    testFrame:Show()
    print("[SIMPLE DRAG TEST] Window created! Try dragging cards between Group and Bench!")
    print("[SIMPLE DRAG TEST] Click 'Add Card' to add more players to the bench")
end

-- MARK: Layout System

-- Layout nested group list with sub-lists
function SimpleDragTest:LayoutGroupList()
    local yOffset = 30  -- Space below "Group" label
    local subListSpacing = 5
    
    print("[LAYOUT] Starting nested layout for Group")
    
    -- Update parent group label
    local totalCards = listA:getTotalCards()
    local statusText = "Group (" .. totalCards .. "/" .. listA.totalCapacity .. ")"
    
    -- Color code based on capacity
    if totalCards >= listA.totalCapacity then
        listA.label:SetTextColor(1.0, 0.2, 0.2)  -- Red when full
    elseif totalCards >= listA.totalCapacity - 1 then
        listA.label:SetTextColor(1.0, 0.8, 0.0)  -- Yellow when almost full
    else
        listA.label:SetTextColor(1.0, 1.0, 1.0)  -- White
    end
    listA.label:SetText(statusText)
    
    -- Layout each sub-list
    for _, subList in ipairs(listA.subLists) do
        -- Position sub-list frame
        subList.frame:ClearAllPoints()
        subList.frame:SetPoint("TOP", listA.frame, "TOP", 0, -yOffset)
        
        -- Layout cards within sub-list
        local cardYOffset = 20  -- Space below sub-list label
        for i, card in ipairs(subList.cards) do
            card:ClearAllPoints()
            card:SetPoint("TOP", subList.frame, "TOP", 0, -cardYOffset)
            cardYOffset = cardYOffset + card:GetHeight() + 2
            print("[LAYOUT] Positioned " .. card.playerName .. " in " .. subList.slotName)
        end
        
        -- Calculate sub-list height dynamically
        local minHeight = 25  -- Minimum for label + padding
        local contentHeight = #subList.cards > 0 and cardYOffset or minHeight
        subList.frame:SetHeight(math.max(minHeight, contentHeight))
        
        -- Update sub-list label
        local count = #subList.cards
        local labelText = subList.slotName .. " (" .. count .. "/" .. subList.maxCapacity .. ")"
        subList.label:SetText(labelText)
        
        -- Color code sub-list label
        if count >= subList.maxCapacity then
            subList.label:SetTextColor(1.0, 0.2, 0.2)  -- Red when full
        else
            subList.label:SetTextColor(0.8, 0.8, 0.8)  -- Gray
        end
        
        -- Advance offset for next sub-list
        yOffset = yOffset + subList.frame:GetHeight() + subListSpacing
    end
    
    -- Update parent group frame height
    listA.frame:SetHeight(yOffset + 10)
    
    print("[LAYOUT] Group layout complete: " .. totalCards .. "/" .. listA.totalCapacity)
end

-- Layout cards vertically in bench list
function SimpleDragTest:LayoutList(list)
    if list ~= listB then
        -- For group list, use LayoutGroupList instead
        SimpleDragTest:LayoutGroupList()
        return
    end
    
    local yOffset = 0
    local spacing = 3
    
    print("[LAYOUT] Starting layout for Bench with " .. #list.cards .. " cards")
    
    for i, card in ipairs(list.cards) do
        card:ClearAllPoints()
        card:SetPoint("TOP", listB.scrollChild, "TOP", 0, -yOffset)
        print("[LAYOUT] Positioned " .. card.playerName .. " in Bench at offset " .. yOffset)
        yOffset = yOffset + card:GetHeight() + spacing
    end
    
    -- Update scroll child height
    listB.scrollChild:SetHeight(math.max(yOffset, 1))
    
    -- Update bench label with count
    listB.label:SetText("Bench (" .. #listB.cards .. ")")
    
    print("[LAYOUT] Bench layout complete")
end

-- MARK: Rejection Animation
function SimpleDragTest:AnimateRejection(card, targetList, reason)
    -- Flash red to indicate rejection
    card:SetBackdropColor(1.0, 0.2, 0.2, 1.0)  -- Red background
    card:SetBackdropBorderColor(1.0, 1.0, 0.0, 1.0)  -- Yellow border
    
    -- Show rejection reason
    if reason then
        print("[DRAG TEST] REJECTION REASON: " .. reason)
    end
    
    -- Show the card for animation
    card:Show()
    
    -- Get current position for animation start
    local startX, startY = card:GetCenter()
    local targetX, targetY
    
    -- Calculate target position - use original position if available
    if card.originalX and card.originalY then
        targetX, targetY = card.originalX, card.originalY
        print("[DRAG TEST] Animating back to original position")
    else
        -- Fallback: calculate position based on original index
        if card.originalIndex and targetList == listB then
            -- Calculate position based on original index in bench
            local yOffset = (card.originalIndex - 1) * (20 + 3) + 10  -- 20px card + 3px spacing
            targetX = listB.frame:GetCenter()
            targetY = listB.scrollChild:GetTop() - yOffset
            print("[DRAG TEST] Animating back to calculated index position: " .. card.originalIndex)
        else
            -- Ultimate fallback to generic position
            targetX = listB.frame:GetCenter()
            targetY = listB.frame:GetTop() - 50
            print("[DRAG TEST] Animating back to generic position")
        end
    end
    
    -- Animation duration and steps
    local duration = 0.3  -- 300ms for smooth animation
    local steps = 15
    local stepDelay = duration / steps
    
    -- Ensure card stays visible during animation
    card:SetParent(UIParent)
    card:SetFrameStrata("TOOLTIP")
    
    -- Animate bounce-back
    local currentStep = 0
    local function AnimateStep()
        currentStep = currentStep + 1
        local progress = currentStep / steps
        
        -- Ease-out animation (slower at end)
        local easedProgress = 1 - (1 - progress) * (1 - progress)
        
        -- Calculate interpolated position
        local newX = startX + (targetX - startX) * easedProgress
        local newY = startY + (targetY - startY) * easedProgress
        
        -- Apply position
        card:ClearAllPoints()
        card:SetPoint("CENTER", UIParent, "BOTTOMLEFT", newX, newY)
        
        if currentStep >= steps then
            -- Animation complete - return card to its original list and position
            -- CRITICAL: Always set size based on target list, not original list
            -- BUT: If rejected from Group, targetList should be listB (Bench)
            -- The issue is that rejected cards are going to wrong target list
            local actualTargetList = targetList
            
            -- Fix: Ensure rejected cards return to correct parent
            if actualTargetList == listB then
                card:SetParent(listB.scrollChild)
                card:SetSize(140, 20)  -- Compact size for bench
                card.text:SetFontObject("GameFontNormalSmall")
                print("[DRAG TEST] Returning to Bench (REJECTED)")
            elseif actualTargetList.frame then
                -- Sub-list (has a frame property)
                card:SetParent(actualTargetList.frame)
                card:SetSize(140, 40)  -- Expanded size for sub-list
                card.text:SetFontObject("GameFontNormal")
                print("[DRAG TEST] Returning to " .. actualTargetList.slotName .. " (REJECTED)")
            else
                -- Fallback - shouldn't happen but handle gracefully
                card:SetParent(listB.scrollChild)
                card:SetSize(140, 20)
                card.text:SetFontObject("GameFontNormalSmall")
                print("[DRAG TEST] Fallback: Returning to Bench")
            end
            
            card:SetFrameStrata("MEDIUM")
            
            -- Insert card back at its original position if index is known
            if card.originalIndex then
                -- Adjust index if list has changed since drag started
                local adjustedIndex = math.min(card.originalIndex, #targetList.cards + 1)
                table.insert(targetList.cards, adjustedIndex, card)
                print("[DRAG TEST] Restored " .. card.playerName .. " to index " .. adjustedIndex)
            else
                table.insert(targetList.cards, card)
                print("[DRAG TEST] Added " .. card.playerName .. " to end of list")
            end
            
            card.listTable = targetList
            
            -- Re-layout lists (this will position everything correctly)
            SimpleDragTest:LayoutGroupList()
            SimpleDragTest:LayoutList(listB)
            
            -- Reset colors to normal
            card:SetBackdropColor(card.classColor.r, card.classColor.g, card.classColor.b, 1.0)
            card:SetBackdropBorderColor(card.roleColor.r, card.roleColor.g, card.roleColor.b, 1)
            
            -- Clear original position data
            card.originalIndex = nil
            card.originalX = nil
            card.originalY = nil
            
            local targetName = targetList == listB and "Bench" or (targetList.slotName or "Group")
            print("[DRAG TEST] Animation complete: " .. card.playerName .. " returned to " .. targetName)
        else
            -- Continue animation
            C_Timer.After(stepDelay, AnimateStep)
        end
    end
    
    -- Start animation
    C_Timer.After(stepDelay, AnimateStep)
end

function SimpleDragTest:Hide()
    if testFrame then
        testFrame:Hide()
    end
end

-- Register
NextKey222.RegisterModule("SimpleDragTest", SimpleDragTest)