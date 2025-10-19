# NextKey Teleport Window Polish Integration Plan

## 1. Preparation
1. Open `ui/teleport.lua` (or current teleport module) and locate the AceGUI container that represents the teleport window. Note the builders for the teleport icon, optional hearthstone entry, and footer region.
2. Cross-reference the keystone card implementation (typically in `ui/main.lua` or shared component factory) to confirm styling helpers, font objects, and color constants already available.
3. Inspect the configuration panel governing the hearthstone toggle so the layout update can react to the saved variable correctly.

## 2. Title Bar Alignment
1. Replace or restyle the existing title container to display the text `NextKey` using the same accent backdrop used by the main UI header (e.g., via `Components:CreateBackdrop("HEADER", ...)`).
2. Remove the redundant top-right close button frame creation, ensuring the bottom `Close` AceGUI button remains the sole exit control.
3. Confirm the parent frame still sets `SetTitle`/`SetStatusText` appropriately for AceGUI best practices (Title aligned by AceGUI, status for footers).

## 3. Primary Teleport Card Structure
1. Create/Reuse a dedicated card builder function (e.g., `BuildTeleportCard(entryData)`) that mirrors the keystone card visual:
   - AceGUI container type `InlineGroup` or custom frame with `Components:CreateBackdrop("CARD_PRIMARY", ...)`.
   - Set layout to `"Flow"` or `"List"` to stack content vertically with deterministic padding.
2. Inside the card, add a fixed-size icon frame (`AceGUI:Create("Label")` with `SetImage`) on the left; keep the existing `OnClick` logic tied to the icon widget so teleport activation behavior is preserved.
3. On the right, add a label group with:
   - Dungeon name (`SetFontObject` to match main UI title style).
   - Keystone level/prefix owner line (use same font/color mix as main cards; leverage `Components:StyleLevelText` if available).
4. Ensure the card sets `SetFullWidth(true)` and uses consistent margins (`SetRelativeWidth`) for AceGUI layout stability.

## 4. Optional Hearthstone Card
1. Duplicate the card builder for the hearthstone entry but supply hearthstone-specific text/icon assets.
2. Enclose both cards in a vertical group (`AceGUI:Create("SimpleGroup")`) with `SetLayout("List")` so enabling/disabling the hearthstone entry automatically adjusts frame height.
3. Bind hearthstone visibility to the configuration flag (from preparation step). When disabled, release the AceGUI widget (`:ReleaseChildren()`) and update the container `DoLayout()`.

## 5. Footer Strip Instruction
1. Preserve the footer container but update its content to display the static instruction text `Click an Icon to Teleport`.
2. Use AceGUI status bar text or a dedicated label anchored above the Close button; apply the footer font style used elsewhere for consistency.
3. Verify the Close button still fits within the footer group and respects padding; set `SetFullWidth(true)` if needed to avoid misalignment.

## 6. Visual Polish & Feedback
1. Apply hover highlight behavior to card frames (e.g., `OnEnter/OnLeave` scripts toggling backdrop color) to match keystone cards.
2. Confirm icon frames use consistent border textures and spacing (reuse `Components:CreateIcon` with `ICON_TELEPORT` / `ICON_HEARTHSTONE` constants if defined).
3. Ensure font strings use AceGUI-friendly methods (`SetFontObject`) rather than direct `FontString` manipulation to stay within Ace3 patterns.

## 7. Layout & Sizing Validation
1. Set explicit minimum widths/heights on the parent window to prevent collapse when only one card is shown; rely on `SetAutoAdjustHeight(true)` for containers rather than manual frame height math.
2. Test with hearthstone disabled/enabled to confirm the window resizes seamlessly with no extra whitespace.
3. Verify the instruction footer remains visible when the window grows; adjust container order (`AddChild` sequence) if clipping occurs.

## 8. Testing Checklist ✅
1. `/nk` (or relevant slash) open teleport window with a valid teleport available; confirm icon click still initiates teleport.
2. Toggle hearthstone option in config, reload window, and confirm card appears/disappears with correct layout.
3. Attempt teleport while on cooldown to ensure existing error handling surfaces via the debug system (no regression).
4. Test on varied UI scale settings to ensure card proportions and text wrap hold.
5. Run `/reload` to confirm no leaked AceGUI widgets or nil references in the refactored layout.

## 9. Documentation & Follow-Up ✅
1. Update any relevant documentation (e.g., Phase 6 guidelines or teleport module comments) summarizing the card reuse approach.
2. If visual tweaks alter component defaults, suggest updating the memory bank context or architecture files after implementation so the polish work is captured for future sessions.

## Implementation Summary

### Completed Changes
The teleport window has been successfully refactored to use a card-based design pattern that matches the main UI:

1. **Card Builder Functions**: Created `BuildTeleportCard()` function that generates consistent card layouts for both keystone and hearthstone options.

2. **Dynamic Content Updates**: Implemented `UpdateTeleportWindowContent()` function that handles dynamic updates based on keystone data availability and hearthstone settings.

3. **Window Sizing**: The window automatically adjusts its height based on content (30px title + 60px per card + 40px footer).

4. **Visual Polish**: Added hover effects to cards that change the backdrop color when the mouse enters/leaves the card area.

5. **Testing Function**: Added `TestTeleportWindow()` function that can be used to verify the implementation works correctly.

### Key Features
- **Consistent Styling**: Cards now use the same backdrop styling as the main UI cards
- **Responsive Layout**: Window automatically adjusts size based on available content
- **Hover Effects**: Cards provide visual feedback when hovered
- **Conditional Display**: Hearthstone card only appears when enabled in settings
- **Clear Instructions**: Footer strip provides clear guidance to users

### Testing
Use the built-in test function to verify the implementation:
```
/script NextKey222.Addon:TestTeleportWindow()
```

This will test window creation, keystone data retrieval, content updates, window sizing, window toggle, and hearthstone settings.

### Future Enhancements
- Add animation transitions when cards appear
- Implement keyboard navigation
- Add support for multiple hearthstone locations
