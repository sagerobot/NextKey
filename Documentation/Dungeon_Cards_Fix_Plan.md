# Dungeon Cards Fix - Implementation Plan

## Problem Summary

Dungeon cards and keystone cards use completely different creation patterns, resulting in:
1. **Missing borders** - Dungeon cards don't have visible borders like keystone cards
2. **Wrong icons** - Dungeon cards show player class/role icons instead of dungeon icons
3. **Inconsistent styling** - Different button styles, layouts, and visual appearance

## Root Cause Analysis

### Keystone Cards (Correct Pattern)
Location: [`ui/main.lua:1626-1810`](../ui/main.lua:1626-1810)

```lua
-- Creates proper card with backdrop support
local container = NextKey222.UIComponents:CreateCardContainer(88, false)
local cardFrame = container.cardFrame or container.frame
local frame = NextKey222.UIComponents:CreateBackdrop(cardFrame, "keystone")

-- Icons created with native frames
local icon = NextKey222.UIComponents:CreateClassIcon(frame, classToken, 32, playerData)
local roleIcon = NextKey222.UIComponents:CreateRoleIcon(frame, entry.role, 16)
```

### Dungeon Cards (Incorrect Pattern)  
Location: [`ui/dungeonCards.lua:181-262`](../ui/dungeonCards.lua:181-262)

```lua
-- Uses wrong container type - no cardFrame, no backdrop
local cardContainer = NextKey222.UIComponents:CreateFrame("panel", nil, {
    width = cardWidth,
    height = cardHeight,
    colorScheme = "standard",
    showBorder = true  // ❌ This config doesn't exist in the API
})

-- Icons created with AceGUI widgets (wrong approach)
local dungeonIcon = NextKey222.UIComponents:CreateIcon("dungeon", leftSection, { size = {40, 40} })
```

## Implementation Steps

### Step 1: Update `UI:Update()` Function (Lines 161-208)
Replace the card creation pattern to match keystones:

```lua
for _, cardData in ipairs(cards) do
    -- ✅ Use CreateCardContainer like keystones do
    local cardContainer = NextKey222.UIComponents:CreateCardContainer(cardHeight, useCompactMode)
    self.scrollFrame:AddChild(cardContainer)
    
    -- ✅ Get the dedicated cardFrame and apply backdrop
    local cardFrame = cardContainer.cardFrame or cardContainer.frame
    NextKey222.UIComponents:CreateBackdrop(cardFrame, useCompactMode and "keystone_compact" or "keystone")
    
    -- Now populate with dungeon-specific content
    if useCompactMode then
        self:PopulateCardCompact(cardContainer, cardData)
    else
        self:PopulateCard(cardContainer, cardData)
    end
    
    self.cards[cardData.dungeonID] = cardContainer
    totalScore = totalScore + cardData.totalScore
end
```

### Step 2: Update `UI:PopulateCard()` Function (Lines 211-262)
Replace AceGUI icons with native frame icons:

```lua
function UI:PopulateCard(cardContainer, card)
    local cardFrame = cardContainer.cardFrame or cardContainer.frame
    
    -- ✅ Create dungeon icon using native frame (like class icons)
    local dungeonIcon = CreateFrame("Frame", nil, cardFrame)
    dungeonIcon:SetSize(40, 40)
    dungeonIcon:SetPoint("TOPLEFT", cardFrame, "TOPLEFT", 12, -12)
    
    local texture = dungeonIcon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    
    -- Get dungeon icon texture
    local iconSet = false
    if NextKey.PortalData and NextKey.PortalData.dungeons[card.dungeonID] then
        local dungeonData = NextKey.PortalData.dungeons[card.dungeonID]
        
        -- Try spell texture
        if dungeonData.spellID and dungeonData.spellID > 0 then
            local spellTexture = GetSpellTexture(dungeonData.spellID)
            if spellTexture then
                texture:SetTexture(spellTexture)
                iconSet = true
            end
        end
        
        -- Try ChallengeMode API
        if not iconSet and C_ChallengeMode then
            local mapID = NextKey222.Utils:ConvertToRaiderIOKeystoneID(card.dungeonID)
            if mapID then
                local _, _, _, iconFileID = C_ChallengeMode.GetMapUIInfo(mapID)
                if iconFileID then
                    texture:SetTexture(iconFileID)
                    iconSet = true
                end
            end
        end
        
        -- Try mapArtID
        if not iconSet and dungeonData.mapArtID then
            texture:SetTexture(dungeonData.mapArtID)
            iconSet = true
        end
    end
    
    -- Fallback
    if not iconSet then
        texture:SetTexture("Interface\\Icons\\Achievement_Dungeon_GloryoftheRaider")
    end
    
    -- Rest of the card content positioning...
    -- (nameText, scoreText, buttons positioned relative to cardFrame)
end
```

### Step 3: Update `UI:PopulateCardCompact()` Similarly
Apply the same pattern for compact cards with smaller icon size (32x32).

### Step 4: Button Creation
Ensure buttons use the same legacy button pattern as keystones:

```lua
-- ✅ Like button (matches keystone pattern)
local likeBtn = NextKey222.UIComponents:CreateButtonLegacy(cardFrame, "small")
likeBtn:SetText(preference and preference.liked and "|cFF00FF00+|r" or "+")
likeBtn:SetPoint("TOPRIGHT", cardFrame, "TOPRIGHT", -12, -12)
likeBtn:SetScript("OnClick", function()
    NextKey222.ProfilesService:ToggleDungeonPreference(card.dungeonID, true)
    self:Update()
end)
```

## Expected Results

After implementation:
1. ✅ Dungeon cards will have visible borders (using keystone backdrop)
2. ✅ Each dungeon shows its unique icon
3. ✅ Buttons match keystone card styling  
4. ✅ Layout matches keystone card structure
5. ✅ Visual consistency across all card types

## Testing Checklist

- [ ] `/reload` to load changes
- [ ] Open NextKey: `/nk`
- [ ] Switch to Dungeons View
- [ ] Verify each dungeon has:
  - [ ] Visible border around card
  - [ ] Unique dungeon icon (not class/role)
  - [ ] Properly styled buttons
  - [ ] Consistent spacing and layout
- [ ] Test compact mode (if >5 dungeons)
- [ ] Test preference buttons (+/-)
- [ ] Test teleport and loot buttons

## Files to Modify

1. [`ui/dungeonCards.lua`](../ui/dungeonCards.lua) - Main file with all changes

## References

- Keystone card implementation: [`ui/main.lua:1626-1810`](../ui/main.lua:1626-1810)
- Component factory: [`ui/components.lua:932-976`](../ui/components.lua:932-976)
- CreateBackdrop: [`ui/components.lua:773-780`](../ui/components.lua:773-780)