# NextKey Loot Targeting System - DRY Implementation Plan

**Created**: October 19, 2025  
**Version**: 0.2.0.1  
**Phase**: Phase 3 - Major Feature Implementation  
**Code Reuse Target**: ~95%  
**Estimated Time**: 5-6 hours

---

## Executive Summary

Transform the placeholder loot window into a fully functional loot tracking system by **reusing existing proven patterns** from `ui/hearthstoneSelector.lua` and `data/portals.lua`. This plan prioritizes code reuse, maintainability, and consistency with NextKey's architectural standards.

---

## Design Goals

1. **Maximum Code Reuse**: Leverage existing patterns from hearthstoneSelector and portals
2. **Generic Data Structure**: No hardcoded item lists, season-aware like dungeons
3. **Protected vs Custom Items**: Clear distinction with appropriate UI affordances
4. **Performance**: Item preloading to prevent question marks
5. **User Experience**: Simple, intuitive interface matching existing patterns

---

## Pattern Analysis & Reuse

### 1. HearthstoneSelector Pattern (ui/hearthstoneSelector.lua)

**Reusable patterns:**
- `PreloadHearthstoneTextures()` → `PreloadItemTextures()`
- `SetButtonTexture()` with retry logic → `SetItemIconTexture()`
- Save/Select button pattern → Track/Untrack pattern

### 2. Portals Data Pattern (data/portals.lua)

**Reusable structure:**
```lua
portalData["TWW_S3"] = { dungeons = {...} }
↓ BECOMES ↓
lootData["TWW_S3"] = { dungeons = { [503] = { defaultItems = {...} } } }
```

### 3. DungeonCards Tracking (core/dungeonCards.lua)

**Already implemented (lines 167-192):**
- `TrackItem(dungeonID, itemID, isCustom)` ✅
- `UntrackItem(dungeonID, itemID, isCustom)` ✅
- `trackedItems / customTrackedItems` separation ✅

### 4. Component Factory System

Use throughout: `Components:CreateIcon()`, `Components:CreateButton()`, `Components:CreateText()`, `Components:CreateScrollFrame()`

---

## Implementation Phases

### Phase 1: Create data/loot.lua (30 min)

**New file following portals.lua pattern:**

```lua
local _, NextKey222 = ...
local NextKey = NextKey222.Addon
if not NextKey then return end

local lootData = {
    ["TWW_S3"] = {
        name = "The War Within Season 3",
        dungeons = {
            [503] = { defaultItems = {221023, 219314} }, -- Ara-Kara trinkets
            [524] = { defaultItems = {225577, 221159} }, -- Dawnbreaker weapons
            -- Add other dungeons...
        }
    }
}

local activeSeasonKey = "TWW_S3"
NextKey.LootData = lootData[activeSeasonKey]
NextKey.CurrentLootSeasonKey = activeSeasonKey
NextKey.AllLootData = lootData

function NextKey:GetDefaultLootItems(dungeonID)
    if self.LootData and self.LootData.dungeons and self.LootData.dungeons[dungeonID] then
        return self.LootData.dungeons[dungeonID].defaultItems or {}
    end
    return {}
end

return lootData
```

**Update NextKey.toc:** Add `data/loot.lua` after `data/portals.lua`

---

### Phase 2: Add Item Preloading (30 min)

**Add to ui/lootWindow.lua after line 24:**

```lua
-- MARK: Item Texture Preloading
local function PreloadItemTextures(itemIDs, callback)
    if not itemIDs or #itemIDs == 0 then
        if callback then callback() end
        return
    end
    
    local preloadCount = 0
    local totalCount = #itemIDs
    
    local function PreloadSingleItem(itemID)
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
        local _ = C_Item.GetItemIconByID(itemID)
        
        preloadCount = preloadCount + 1
        if preloadCount >= totalCount then
            if callback then callback() end
        end
    end
    
    for i, itemID in ipairs(itemIDs) do
        C_Timer.After(i * 0.05, function()
            PreloadSingleItem(itemID)
        end)
    end
end
```

---

### Phase 3: Enhance Update() Function (45 min)

**Replace ui/lootWindow.lua Update() function (lines 164-325):**

Key changes:
1. Get default items from `NextKey:GetDefaultLootItems(dungeonID)`
2. Mark items as `isProtected` (default) or `isCustom` (user-added)
3. Preload all items before rendering
4. Call new `RenderItemList()` function

```lua
function LootWindow:Update()
    if not self.dungeonID then return end
    
    local dungeon = DungeonCards:GetCard(self.dungeonID)
    if dungeon and dungeon.name then
        self.title:SetText(dungeon.name .. " Loot")
    end
    
    if self.scrollFrame then
        self.scrollFrame:ReleaseChildren()
    end
    
    local items = {}
    local card = DungeonCards:GetCard(self.dungeonID)
    
    -- Add default items (protected)
    local defaultItems = NextKey:GetDefaultLootItems(self.dungeonID)
    for _, itemID in ipairs(defaultItems) do
        if card.trackedItems[itemID] ~= false then
            table.insert(items, {itemID = itemID, isProtected = true, isCustom = false})
        end
    end
    
    -- Add custom items (removable)
    for itemID in pairs(card.customTrackedItems) do
        table.insert(items, {itemID = itemID, isProtected = false, isCustom = true})
    end
    
    -- Preload and render
    local allItemIDs = {}
    for _, itemData in ipairs(items) do
        table.insert(allItemIDs, itemData.itemID)
    end
    
    PreloadItemTextures(allItemIDs, function()
        self:RenderItemList(items)
    end)
end

function LootWindow:RenderItemList(items)
    local yOffset = 0
    for _, itemData in ipairs(items) do
        self:CreateItemRow(itemData.itemID, itemData.isProtected, itemData.isCustom, yOffset)
        yOffset = yOffset + LIST_ITEM_HEIGHT + 2
    end
    
    if self.scrollFrame then
        self.scrollFrame.frame:SetHeight(math.max(yOffset, 1))
    end
end
```

---

### Phase 4: Update CreateItemRow() (1 hour)

**Enhance ui/lootWindow.lua CreateItemRow():**

Key features:
- Use component factory for all UI elements
- Add protected icon (lock) for default items
- Show remove button only for custom items
- Proper tooltips on all elements

```lua
function LootWindow:CreateItemRow(itemID, isProtected, isCustom, yOffset)
    local itemContainer = NextKey222.UIComponents:CreateFrame("container", nil, {
        width = WINDOW_WIDTH - 80,
        height = LIST_ITEM_HEIGHT,
        colorScheme = "light"
    })
    
    local itemFrame = itemContainer.frame
    itemFrame:SetPoint("TOPLEFT", self.scrollFrame.frame, "TOPLEFT", 10, -yOffset)
    
    -- Item icon
    local itemIcon = NextKey222.UIComponents:CreateIcon("item", itemContainer, {
        imagePath = C_Item.GetItemIconByID(itemID) or "Interface/Icons/INV_Misc_QuestionMark",
        size = {LIST_ITEM_HEIGHT - 4, LIST_ITEM_HEIGHT - 4},
        onEnter = function()
            GameTooltip:SetOwner(itemIcon.frame, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)
            GameTooltip:Show()
        end,
        onLeave = function() GameTooltip:Hide() end
    })
    itemIcon.frame:SetPoint("LEFT", itemFrame, "LEFT", 2, 0)
    
    -- Item name
    local itemName = NextKey222.UIComponents:CreateText("body", itemContainer, {
        text = "Loading...",
        width = WINDOW_WIDTH - 160,
        justifyH = "LEFT",
        color = {1, 1, 1}
    })
    itemName.frame:SetPoint("LEFT", itemIcon.frame, "RIGHT", 5, 0)
    
    -- Protected icon (for default items)
    if isProtected then
        local protectedIcon = NextKey222.UIComponents:CreateIcon("small", itemContainer, {
            imagePath = "Interface/RAIDFRAME/ReadyCheck-Ready",
            size = {16, 16}
        })
        protectedIcon.frame:SetPoint("LEFT", itemName.frame, "RIGHT", 4, 0)
        protectedIcon.frame:SetAlpha(0.6)
    end
    
    -- Remove button (for custom items only)
    if not isProtected and isCustom then
        local removeBtn = NextKey222.UIComponents:CreateButton("small", itemContainer, {
            text = "×",
            onClick = function()
                DungeonCards:UntrackItem(self.dungeonID, itemID, true)
                DungeonCards:SaveLootTracking()
                self:Update()
            end
        })
        removeBtn.frame:SetPoint("RIGHT", itemFrame, "RIGHT", -2, 0)
    end
    
    -- Load item info asynchronously
    local item = Item:CreateFromItemID(itemID)
    if item then
        item:ContinueOnItemLoad(function()
            local itemNameText = item:GetItemName()
            local itemQuality = C_Item.GetItemQualityByID(itemID)
            
            if itemNameText then
                itemName:SetText(itemNameText)
            end
            
            if itemQuality and ITEM_QUALITY_COLORS[itemQuality] then
                local color = ITEM_QUALITY_COLORS[itemQuality]
                itemName:SetColor(color.r, color.g, color.b)
            end
        end)
    end
    
    self.scrollFrame:AddChild(itemContainer)
    self.itemFrames[itemID] = itemFrame
end
```

**Update input box OnEnterPressed (line 94):**
```lua
nativeInput:SetScript("OnEnterPressed", function(self)
    local itemID = tonumber(self:GetText())
    if itemID then
        DungeonCards:TrackItem(LootWindow.dungeonID, itemID, true)
        DungeonCards:SaveLootTracking() -- NEW: Save after adding
        self:SetText("")
        LootWindow:Update()
    end
end)
```

---

### Phase 5: Integration (15 min)

**Add to ui/main.lua or boot.lua:**

```lua
function NextKey:HandleLootClick(dungeonID, dungeonData)
    if not self.LootWindow then
        NextKey222.Debug:Error("LootWindow module not available")
        return
    end
    
    NextKey222.Debug:Dev("ui", "Opening loot window for dungeon:", dungeonID, dungeonData.name)
    self.LootWindow:Show(dungeonID)
end
```

**Verify core/dungeonCards.lua has tracking methods** ✅ Already implemented (no changes needed)

---

### Phase 6: Persistence (30 min)

**Update core/config.lua Defaults (lines 202-216):**

```lua
char = {
    liveRuns = {},
    keystoneHistory = {},
    preferences = {},
    dungeonPreferences = {},
    
    -- Loot tracking
    targetedItems = {},      -- Keep for backward compatibility
    dungeonRunCounts = {},   -- Keep for existing
    lootTracking = {         -- NEW: Structured per-dungeon tracking
        -- [dungeonID] = {
        --     defaultItems = {[itemID] = true/false},
        --     customItems = {[itemID] = true}
        -- }
    },
    
    mythicPlus = { activeSeason = nil, seasons = {} },
    seasonData = { currentSeason = nil, dungeonScores = {}, runCounts = {} }
}
```

**Add to core/dungeonCards.lua (after line 327):**

```lua
-- MARK: Loot Tracking Persistence

function DungeonCards:SaveLootTracking()
    if not NextKey.db or not NextKey.db.char then return end
    
    local lootData = {}
    for dungeonID, card in pairs(self.dungeons) do
        if next(card.trackedItems) or next(card.customTrackedItems) then
            lootData[dungeonID] = {
                defaultItems = {},
                customItems = {}
            }
            
            for itemID, tracked in pairs(card.trackedItems) do
                lootData[dungeonID].defaultItems[itemID] = tracked
            end
            
            for itemID in pairs(card.customTrackedItems) do
                lootData[dungeonID].customItems[itemID] = true
            end
        end
    end
    
    NextKey.db.char.lootTracking = lootData
end

function DungeonCards:LoadLootTracking()
    if not NextKey.db or not NextKey.db.char then return end
    
    local lootData = NextKey.db.char.lootTracking
    if not lootData then return end
    
    for dungeonID, tracking in pairs(lootData) do
        local card = self:GetCard(dungeonID)
        
        if tracking.defaultItems then
            for itemID, tracked in pairs(tracking.defaultItems) do
                card.trackedItems[itemID] = tracked
            end
        end
        
        if tracking.customItems then
            for itemID in pairs(tracking.customItems) do
                card.customTrackedItems[itemID] = true
            end
        end
    end
end
```

**Update DungeonCards:Init() (line 329):**
Add `self:LoadLootTracking()` after `self:LoadPreferences()`

---

## Testing Strategy

### Test Cases

**1. Item Display**
- [ ] Default items appear with no question marks
- [ ] Item names and quality colors correct
- [ ] Protected icon visible on default items

**2. Custom Items**
- [ ] Can add via item ID input
- [ ] Custom items show remove button
- [ ] Remove button works correctly

**3. Protection**
- [ ] Default items have no remove button
- [ ] Custom items can be removed
- [ ] Lock icon has tooltip

**4. Persistence**
- [ ] Data persists across /reload
- [ ] Multiple dungeons have separate lists
- [ ] Untracked defaults stay untracked

**5. Integration**
- [ ] Loot button works from dungeon cards
- [ ] Window title shows correct dungeon
- [ ] Appropriate items display

### Test Commands

```lua
-- Open loot window for Ara-Kara
/run NextKey222.Addon:HandleLootClick(503, {name="Ara-Kara, City of Echoes"})

-- Check saved data
/run for id, data in pairs(NextKey222.Addon.db.char.lootTracking) do print("Dungeon:", id) end

-- Clear loot tracking (reset)
/run NextKey222.Addon.db.char.lootTracking = {}; print("Cleared")
```

---

## Timeline & Priority

| Phase | Task | Time | Dependencies |
|-------|------|------|--------------|
| 1 | Create data/loot.lua | 30 min | Research items |
| 2 | Add preloading | 30 min | Phase 1 |
| 3 | Enhance Update() | 45 min | Phase 1, 2 |
| 4 | Update CreateItemRow() | 1 hour | Phase 3 |
| 5 | Integration | 15 min | Phase 4 |
| 6 | Persistence | 30 min | Phase 4 |
| 7 | Testing | 1 hour | All phases |
| 8 | Documentation | 30 min | Phase 7 |

**Total**: 5-6 hours

---

## Success Criteria

### Functional
- [ ] Default items display with proper icons (no question marks)
- [ ] Protected indicator shows for default items
- [ ] Users can add/remove custom items
- [ ] All tracking persists across sessions
- [ ] Multiple dungeons have separate lists

### Technical
- [ ] 95%+ code reuse from existing patterns
- [ ] Component factory used throughout
- [ ] Proper error handling
- [ ] No memory leaks

### UX
- [ ] Intuitive interface
- [ ] Clear protected vs custom distinction
- [ ] Immediate feedback on actions
- [ ] Proper tooltips

---

## Key Architectural Decisions

### Code Reuse Breakdown

| Component | Reuse | Source |
|-----------|-------|--------|
| Data Structure | 100% | data/portals.lua |
| Preloading | 95% | ui/hearthstoneSelector.lua |
| UI Components | 100% | Component factory |
| Tracking | 100% | core/dungeonCards.lua |
| Persistence | 80% | SavedVariables pattern |

**Overall**: ~95% code reuse

### Design Philosophy

**Consistency Over Innovation**:
- Use proven patterns from existing modules
- Don't reinvent working solutions
- Maintain architectural consistency
- Prioritize maintainability

---

## Documentation Updates

### Files to Update

1. **CURRENT_STATUS_REQUIREMENTS.md**: Mark loot window as completed
2. **README.md**: Add loot targeting usage section
3. **CHANGELOG.md**: Add version entry with new features
4. **NextKey.toc**: Add data/loot.lua

---

## Common Pitfalls to Avoid

1. ❌ Don't hardcode item lists - use data/loot.lua
2. ❌ Don't skip preloading - prevents question marks
3. ❌ Don't forget to save after changes
4. ❌ Don't mix protected/custom logic
5. ❌ Don't create custom frames - use components

---

## Future Enhancements (Out of Scope)

- Boss assignment for items
- Drop rate percentages
- "Already have" checkbox
- Weekly loot lockout tracking
- Wishlist priority sorting
- Share wishlist with party

---

**Ready for Implementation**: ✅ Yes  
**Next Step**: Switch to Code mode and begin Phase 1