# Wasteful Refresh Investigation & Fix

## Problem

Debug logs show constant keystone processing even when nothing is changing. The addon is doing wasteful work on every `GROUP_ROSTER_UPDATE` event.

## Root Causes

### 1. GROUP_ROSTER_UPDATE fires constantly
WoW fires this event for many reasons that don't affect the addon:
- Player moves zones
- Someone's online status flickers
- Internal WoW updates
- NO actual group composition changes

### 2. Double refresh on same event
Both `events/handlers.lua` AND `ui/main.lua` register for `GROUP_ROSTER_UPDATE` and both trigger refreshes.

### 3. RefreshResults() bypasses render-skipping
`RefreshResults()` clears caches and forces re-scanning, bypassing the smart render-skipping logic in `RenderResults()`.

## Current Flow (Wasteful)

```
GROUP_ROSTER_UPDATE fires
  ↓
events/handlers.lua → ProcessRosterUpdate() → RefreshResults()
  ↓                                              ↓
Clears caches                              Rescans keystones
  ↓                                              ↓
ui/main.lua → GROUP_ROSTER_UPDATE → RefreshResults() (AGAIN!)
  ↓
RenderResults() (cache already cleared, can't skip)
  ↓
Full re-render (even if nothing changed)
```

## Proposed Fix

### Change 1: Only refresh UI when data actually changes

```lua
-- events/handlers.lua
function Events:ProcessRosterUpdate()
    -- ... existing code ...
    
    -- OLD: Always refresh UI
    if NextKey222.UI and NextKey222.UI:IsMainFrameVisible() then
        NextKey.SafeRun(function()
            NextKey222.UI:RefreshResults()  -- Forces refresh!
        end, "Auto refresh UI on group change")
    end
    
    -- NEW: Let RenderResults() skip if nothing changed
    if NextKey222.UI and NextKey222.UI:IsMainFrameVisible() then
        NextKey.SafeRun(function()
            NextKey222.UI:RenderResults()  -- Can skip if no changes
        end, "Auto refresh UI on group change")
    end
end
```

### Change 2: Remove duplicate GROUP_ROSTER_UPDATE handler in UI

```lua
-- ui/main.lua Initialize()
-- OLD: Duplicate registration
rosterChangeFrame.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
rosterChangeFrame.frame:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then
        UI:OnGroupRosterUpdate()
        -- Also triggers RefreshResults() - DUPLICATE!
    end
end)

-- NEW: Remove GROUP_ROSTER_UPDATE, keep only UI mode switching logic
-- events/handlers.lua already handles roster updates
-- UI only needs to check for mode switching (5-man vs raid)
```

### Change 3: Make GetAvailableKeys() check for actual changes

The keystone hash is good, but we need to prevent unnecessary scans:

```lua
-- core/keystones.lua (or wherever GetAvailableKeys lives)
function Keystones:GetAvailableKeys()
    local currentHash = self:GetGroupKeystoneHash()
    
    -- Skip scan if hash hasn't changed
    if self.lastKeystoneHash == currentHash then
        return self.cachedKeys or {}
    end
    
    -- Hash changed - do the scan
    self.lastKeystoneHash = currentHash
    local keys = self:ScanAllKeystones()
    self.cachedKeys = keys
    return keys
end
```

## Expected Impact

- **90% reduction** in unnecessary UI renders when window is open
- **No more constant keystone processing** when nothing changes
- Render-skipping logic actually works as intended
- Still updates immediately when:
  - Player actually joins/leaves
  - Keystone actually changes
  - User manually refreshes

## Testing

1. Open `/nk` window
2. Enable debug: `keystones` category
3. Stand still, don't change group
4. **Before fix**: Constant "Processing keystones" spam
5. **After fix**: Silent (only updates on actual changes)