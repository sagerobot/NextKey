# NextKey UI Main.lua Debug Migration Script
# This script replaces all old debug patterns with new Debug service calls

$file = "c:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\NextKey\ui\main.lua"
$content = Get-Content $file -Raw

# Replace NextKey222.Debug:Print calls with Debug:Dev
$content = $content -replace 'NextKey222\.Debug:Print\("ui",', 'Debug:Dev("ui",'
$content = $content -replace 'NextKey222\.Debug:Print\("tooltip",', 'Debug:Dev("tooltip",'
$content = $content -replace 'NextKey222\.Debug:Print\("teleport",', 'Debug:Dev("teleport",'

# Replace [KEY DEBUG], [SORT DEBUG], [RENDER DEBUG] patterns
$content = $content -replace 'NextKey222\.Addon:Print\("\[KEY DEBUG\]', 'Debug:Dev("ui", "[KEY DEBUG]'
$content = $content -replace 'NextKey222\.Addon:Print\("\[SORT DEBUG\]', 'Debug:Dev("ui", "[SORT DEBUG]'
$content = $content -replace 'NextKey222\.Addon:Print\("\[RENDER DEBUG\]', 'Debug:Dev("ui", "[RENDER DEBUG]'
$content = $content -replace 'NextKey222\.Addon:Print\("\[Score Debug\]', 'Debug:Dev("ui", "[Score Debug]'

# Replace TOOLTIP DEBUG patterns
$content = $content -replace 'print\("NextKey TOOLTIP DEBUG:', 'Debug:Dev("tooltip",'
$content = $content -replace 'TOOLTIP DEBUG:', ''

# Replace TOGGLE DEBUG patterns
$content = $content -replace 'print\("NextKey TOGGLE DEBUG:', 'Debug:Dev("ui",'
$content = $content -replace 'TOGGLE DEBUG:', ''

# Replace generic Debug: prefixed messages
$content = $content -replace 'NextKey222\.Addon:Print\("Debug:', 'Debug:Dev("ui",'
$content = $content -replace 'addon:Print\("Debug:', 'Debug:Dev("ui",'

# Replace ERROR messages
$content = $content -replace 'NextKey222\.Addon:Print\("ERROR:', 'Debug:Error('

# Replace remaining NextKey222.Addon:Print with Debug:Dev
$content = $content -replace 'NextKey222\.Addon:Print\("Dungeon Cards:', 'Debug:Dev("ui", "Dungeon Cards:'
$content = $content -replace 'NextKey222\.Addon:Print\("ToggleViewMode', 'Debug:Dev("ui", "ToggleViewMode'
$content = $content -replace 'NextKey222\.Addon:Print\("Switching to dungeon view"\)', 'Debug:Dev("ui", "Switching to dungeon view")'

# Replace Failed to render messages
$content = $content -replace 'NextKey222\.Addon:Print\("Failed to render', 'Debug:Error("Failed to render'
$content = $content -replace 'NextKey222\.Addon:Print\(string\.format\("\[RENDER DEBUG\] Successfully rendered', 'Debug:Dev("ui", string.format("[RENDER DEBUG] Successfully rendered'

# Save the file
$content | Set-Content $file -NoNewline

Write-Host "UI main.lua debug migration complete!"
