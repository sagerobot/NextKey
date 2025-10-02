# NextKey Boot Architecture Migration

## Changes Made

### Consolidated Boot Files
- **Before**: preboot.lua → boot.lua → startup.lua (3 files)
- **After**: boot.lua (1 file)

### Rationale
Analysis of major WoW addons revealed that all successful addons use single initialization files:
- **RaiderIO**: Single core.lua entry point
- **Details-Damage-Meter**: Comprehensive boot.lua handling all phases  
- **WeakAuras**: Init.lua + WeakAuras.lua pattern with single-phase boot

### Benefits
- **Industry Standard**: Aligns with established addon patterns
- **Reduced Complexity**: Easier to debug and maintain
- **Better Performance**: Fewer file loads during addon startup
- **Clearer Dependencies**: All initialization logic in one place
- **Simplified TOC**: Cleaner file loading order

### Backup Files
Original files were backed up as:
- preboot.lua → preboot.lua.bak
- boot.lua → boot.lua.bak  
- startup.lua → startup.lua.bak

### What Changed
1. **Merged Functionality**: All three files consolidated into new boot.lua
2. **Maintained Phases**: PreInit → Init → PostInit → Enable → Finalize phases preserved
3. **Preserved Module System**: NextKey222.RegisterModule() system unchanged
4. **Enhanced Registration**: Single RegisterModule function with proper validation
5. **Consolidated Slash Commands**: All slash command registration in one place

### Module Compatibility
All existing modules continue to work unchanged:
- Module registration: `NextKey222.RegisterModule("ModuleName", ModuleTable)`
- Namespace access: `NextKey222.ModuleName` 
- Phase handlers: `NextKey222.StartUp:RegisterPhaseHandler()`

### Testing
Test the consolidated boot by:
1. Launching WoW with the addon
2. Verify initialization messages in chat
3. Check `/nk status` for system readiness
4. Confirm all modules load properly

## Rollback Instructions
If issues arise, restore original files:
```bash
mv preboot.lua.bak preboot.lua
mv boot.lua.bak boot.lua  
mv startup.lua.bak startup.lua
```
Then update NextKey.toc to restore the three-file loading order.