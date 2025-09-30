[5.1.7]

- Removed unused code.

[5.1.6]

- Fixed localisation error.

[5.1.5]

- Added Traditional Chinese Localisation thanks to mccma on CurseForge.

- Updated update message with localisation and a text colour change.
- Updated variable management. should no longer get lua errors.
- Updated fresh default variables.
- Updated some guild update checking to ignore my characters. (People in my guild were being told to update when they can't.)

- Fixed variable errors when a new feature is added.
- Fixed update message to only display once.
- Fixed !keys responder not working. 

[5.1.4]

- Fixed Key Tracker Cooldown showing GCD.
- Fixed nil when setting a preset in the settings.

[5.1.3]

- Removed leftover text.

[5.1.2]

- Added the Group Leader Crown Icon to the group leaders button in the Key Tracker.
- Added a Update Checker to notify you when your addon is out of date.
- Added Player Role Icons to the Key Tracker.
- Added a Right Click on the Key Tracker Frame to manually refresh your keys if you think they are not correct. (Will add prompt in future update.)

- Updated the Key Tracker teleport buttons to have a cooldown overlay.
- Updated the ElvUI Preset to closely more resemble the ElvUI style.
- Updated the Minimum and Maximum width of the Key Tracker.

- Fixed the Key Tracker mouse highlight from rendering above the borders of the buttons.
- Fixed the Presets dropdown not reflecting what preset has been selected.
- Fixed the Font Dropdown from being too large filling most of the screen to the bottom.

[5.1.1]

- Added ruRU Russian translations, thanks to Hollicsh over on CurseForge for these.
- Added a new font Geo Sans Light.

- Updated toc to 11.2.7
- Updated some version checking functions.
- Updated some variables, some are not setting on an update from 5.0.2 to 5.1.0 but are fine on a fresh install or wiping them in settings.

[5.1.0]

- Added Players Mythic Plus Rating to the Key Tracker. Uses Raider.io by default and usea a fallback to default WoW API for non Raider.io users.
- Added a Resize handle to the Key Tracker.
- Added a Button Border Colour Picker to the Settings, Frame Borders and Button Borders are now seperate.
- Added a M+ Score Checkbox for the Key Tracker.
- Added a Realm Name Checkbox for the Key Tracker.
- Added a Drag Handle Checkbox for the Key Tracker.

- Updated the Key Tracker to support the new Customisations added in 5.0.0
- Updated the Key Tracker to use one extending window.
- Updated the Key Tracker updating and refreshing for Keystones to be more accurate.
- Updated the Settings window to be slightly darker for clarity.
- Updated the Presets to Support the new Button Borders.
- Updated the Dungeon Library order to alphabetical, there were some misplaced dungeons.
- Updated the Sarasa font to the full version of it to stop players missing characters on names and other data.
- Updated the Feature Window to show for 5.1.0.
- Updated the Feature Window to reset the Key Tracker position only without a reload. New anchoring might hide it behind the Group Finder window.
- Updated zhCN localisations, thanks to TV Guardian for keeping this up to date.

- Fixed the Reset Button not resetting some variables.
- Fixed the Reset Button not resetting the position and size of the Key Tracker.
- Fixed missing Default Variable for the Login Message.
- Fixed the Teleport Buttons not showing the correct cooldown at the end of a dungeon.
- Fixed variables not updating when updating version.

- Removed the Refresh Keys button from the Key Tracker.

[5.0.2]

- Updated some Localisation strings.
- Updated Key Tracker to use new Tazavesh Icons.
- Updated Manaforge Omegae lock icon to the final boss icon, matching the others.

- Fixed Teleports not showing their cooldowns correctly once a dungeon has been completed.
- Fixed the rare occasions where text wouldn't load quick enough and show buttons with no titles or names. The default selected gamefont is used as a fallback.
- Fixed login message not registering correctly.

[5.0.1]

- Added a toggle to use standard lock icon like previous versions.
- Added a toggle to gray out text on locked portals for clearer visibility.

- Updated and renamed some functions in the background.
- Updated position logic, frames placed to the left of the right-hand side of the Group Finder, no longer move when the Group Finder is extended in width from the PvP Tab or other addons.

[5.0.0]

- Added new customisation options for your frames.
- Added 2 new icons for Tazavesh Gambit and Streets.
- Added a 'Tell Teleport Location' option to tell players when you're teleporting to the dungeon.
- Added new fonts for players to use.

-- Updated settings with new customisation options.
- Added a Presets dropdown for preset themes with the new customisations.
- Added a Frame Border Colour Picker.
- Added a Frame Background Colour Picker.
- Added a Font Colour Picker for Frame Name, Expansion Name and Dungeon Acronyms.
- Added a Frame Border Size slider.
- Added a Settings Frame Size slider.
- Added a toggle for the 'Tell Teleport Location' option.
- Added tooltip for the Settings Scale Slider.

-- Updated Key Tracker with small optimisations.
- Updated Key Tracker width to accommodate larger names and dungeon names.
- Updated Key Tracker to use the font dropdown.
- Updated the Key Tracker Refresh Keys button to have some audio feedback.
- Removed the border on the buttons for the Key Tracker
- The Key Tracker will have customisation options in a future update.

- Updated Compact Mode to be compatible with the new customisation options.
- Updated variable saving and loading.
- Updated frame positioning saving and loading.
- Updated dungeon table, icons and names.
- Updated feature with a new design.
- Updated localisations; not all are complete.
- Updated the Frame Scale slider stepping along with minimum and maximum size.
- Updated the default position of the Key Tracker to be a little more lower than the Group Finder so players don't lose it under the group finder.
- Updated the Season 3 frame visibility to be enabled by default for new and returning players. Hide this in the settings.. if you're not playing Season 3 for some reason.
- Updated client checking for font to apply the correct font based on locale.

- Fixed Season 1-3 frame not moving with the Group Finder when the PvP tab is selected.
- Fixed the teleport buttons running in combat.
- Fixed the Raid Library creating new buttons instead of reusing buttons.
- Fixed the add-on running cooldown checks in combat.
- Fixed the add-on using too much memory.
- Fixed incorrect acronym for Plaugefall.
- Fixed incorrect acronym for Plaugefall.
- Fixed the Raid Library Titles/Portals being in the wrong place.

- Removed Tray Mode.
- Removed Framepacks.
- Removed unused textures, borders and icons.
- Removed Alternative Lock Icons; they are now default icons.
- Removed add-on usage from the settings.

- More optimisations, improvements and features are on the way.

[4.0.8]

- Updated Keystone ID for the Key Tracker. PTR uses a different ID.

[4.0.7]

- Updated localization string for zhCN.

[4.0.6]

- Updated Season 3 Dungeon order, it is in the correct alphabetical order.

- With Season 3 being out now, I will be updating any issues that were not caught beforehand ASAP.

[4.0.5]

- Updated and Re-enabled Respond to !keys function.

- Modified the way the Key Tracker works for Chinese and Korean users so names show correctly. This is a temporary fix.

- Removed some localization strings.

[4.0.4]

- Added zhCN localization support, fully translated thanks to Gregory apart of the NGA forum. More support for other languages on the way.

- Updated localization support to missing strings.
- Updated Manaforge Omega Teleport Icon.
- Updated Keystone Item ID for the Key Tracker not sure why it changed.

- Disabled the "Respond to !keys" feature.

- Fixed load order for libraries and locale loading. Players without Ace on any other addons will be met with multiple errors.

[4.0.3]

- Added the framework for localization support for the retail version of the addon, nothing is fully translated yet, all clients still show in english. If you're on a Chinese or Korean client, your font will change, but still show english. If you're wanting to contribute to translations the localization page on CurseForge is available.
- Added new fonts for logogram support (Chinese and Korean).

- Removed unsed code.

If you're wanting to contribute to translations the localization page on CurseForge is available. Report any issues with the Add-On to Discord, I will be watching.

[4.0.2]

11.2 Ready.

- Updated Raid Library to have The War Within portals on top and Shadowlands on the bottom.
- Updated dungeon data and Key Tracker data.
- Updated new portal alternative lock icons.

- Localization is coming in the next few updates and is being actively worked on.

[4.0.1]

- 11.2 Update. Users still on 11.1.7 will have issues with the Key Tracker missing data.

- Renamed and added tooltip to Shift Lock Frames to Lock Frames.

- Fixed scaling issue for players who use add-ons that change the size of the dungeon finder UI.
- Fixed Key Tracker not locking with the frame/shift lock option in the settings.

- Updated Tazavesh Streets and Gambit Acronymn and internal names.
- Updated addon usage text.
- Updated tooltip text.

- Removed Season 2 Dungeon Data from the Key Tracker.

[4.0.0]

- Added Season 3 frame and portals.
- Added Toggle to Lock Frames and move with Shift instead. When frames are locked in the settings they can still be moved by holding shift and dragging them.
- Added Eco-Dome Al'dani to the Dungeon Library. (Will update to correct acronymn.)
- Added Megaforge Omega portal to Raid Library. (Will update to correct acronymn.)
- Adedd Toggle to Show/Hide daily login message.

- Updated Key Tracker for Season 3.
- Updated Feature Launch Window with new patch information.

- Fixed Tray Mode being able to be toggled/clicked by the player while in combat.

-- Mists of Pandaria Classic --

- With the release of MoP Classic came the Challenge Mode Dungeons and their respective dungeon teleports, this is a heavily stripped back version of the Add-On Currently in Retail, with room for expansion in the future. This part of the addon will be updated when needed.

- Added Challenge Mode Portals
- Added Settings Window for Challange Mode Frame

[3.1.12]

- Toc Bump
- 11.1.7 Ready

[3.1.11]

- Fixed Key Tracker displaying 'Unknown' if player didn't have a key or doesn't have an addon with the OpenLibRaid Library.

- Note: I am working on a Major Update for the Addon which should improve a lot of things about it, a lot of you have left feedback in the Discord which helps a lot to see
what you guys want out of the addon and the things I've missed that are broken. Here is a small list of things being worked on.
-- Adding a Lock to the Frames using Shift + Drag to move them around like before.
-- Hiding Teleports and their lock icons when a portal is unknown.
-- Hiding Expansion Teleports and the Frame updating Dynamically.
-- Hiding the Daily Login Message for people who do not want it showing up
-- Character Based Saving for Positions and Customization.
-- Framepack improvements, I am on the fence with removing these completly or having user submitted framepacks.
-- Localization
-- Custom/SharedMedia Fonts
-- Minimap/Addon Button
-- Improved and Expanded Key Tracker
Among other things that are coming into mind. I am one person doing this and still learning all this, so please bare with as I try and bring a smooth experince.

[3.1.10]

- Toc Bump for 11.1.7

[3.1.9]

- 11.1.5 Update.
- Updated Discord invite link.

[3.1.8]

- Fixed the Key Tracker not working in other language clients of the game other than English. The Key Tracker will have English short dungeon names for now, localization will be supported in a future update.

More Improvements and Optimizations coming.

[3.1.7]

- Fixed the Key Tracker buttons being unusable for some users.
- Fixed the Feature window having the incorrect versions, this will auto update to the version in .toc.

More Improvements and Optimizations coming.

[3.1.6]

- Ready for 11.1.5.

- Added the ability to detect when players re-roll their key at the end of the dungeon or lower their key with Lindormi and update the Key Tracker accordingly, if players have this addon. Once more players get this update this will work better and the less you need to refresh your keys.
- Added a border to the Key Tracker buttons, for those of you who don't have clean icons installed, your buttons look better, ish.

- Fixed the Key Tracker so it updates your keystone correctly once a mythic dungeon is completed.
- Fixed the Key Tracker not updating when you collect a key from Lindormi and re-rolling your key at the end of a mythic dungeon.
- Fixed the Key Tracker not detecting when you collect a keystone from the Great Vault.

- Updated the Feature launch window to the correct version. This doesn't update dynamically, will update later, it's not a big deal.

More Improvements and Optimizations coming.

[3.1.5]

This update addresses a number of issues.

- Fixed Key Tracker pulling keystone data and not filtering for party members and taking up large amounts of memory.
- Fixed Key Tracker updating keystone data excessively when it's not needed.
- Fixed Key Tracker personal key missing after a reloading your UI.
- Fixed Key Tracker Party Keys showing an empty window when not in a group.
- Fixed Key Tracker Refresh Button being pressed in combat to cause lua errors overriding combat lockdown. This will do nothing in combat from now on.
- Fixed the rare occasion where the Key Tracker could update causing lua errors when you're in combat while players are joining your group.
- Fixed the rare occasion where you logged out in a bad place, logging back into combat could cause lua errors from the Key Tracker.

- Updated the way The MOTHERLODE!! and Siege of Boralus apply their Spell ID to their buttons. I know some players are having issues with this, I am trying something different to combat this problem. Please report back if this causes more issues and if you get the error message "("Warning: Unknown faction detected! Tell The Addon Author: M+ Dungeon Teleports.")"

If people are having issues with the Add-on, please come and report them on the Discord, I will see them quicker and attend to them faster on there.

[3.1.4]

- Fix for people getting empty debug messages.

[3.1.3]

- Removed Debug print. [Sorry to those who were spammed.]

[3.1.2]

- Fixed Key Tracker Buttons trying to change in combat and giving protected function errors.
- Fixed Key Tracker Buttons not being the correct size.
- Fixed Key Tracker Party buttons being invisible but still showing hover over highlights before players were joining the party updating the list.

- More Fixes and Optimizations incoming

- Removed old texture data.

[3.1.1]

- Fixed In Combat issues with the Key Tracker.
- Fixed Key Tracker Party keys showing in a raid environment.
- Fixed Off Centre Setting Titles.
- Fixed Add-on links pop up window texture issues.

[3.1.0]

- Added a Tray Mode to the Season 1 and 2 windows. There is now button on the right hand side of your Season 1 and Season 2 portal window that minimizes or maximizes it to the window to tray your portals and hide them for when you need them to reduce visual clutter and clashes with other addons.

- Updated the Key Tracker, it now has a better appearance, tracks your own keystone more consistently and now has the ability to track party members keys when you're in a group with them, even if they don't have the addon, as long as they have Details! or any other Add-on that uses the LibOpenRaid Library which 99% of players do. The !keys button has also been changed to no longer output !keys into the chat but to manually refresh data in the group. More improvements in future updates too.

- Updated the layout of the Raid Library so portals now fit nicely and will easily expand for future portals and expansions. Adjust your custom Framepacks to fit. [New template included.]
- Updated all Framepacks for the new Raid Library Layout Update.
- Updated Settings to accommodate new options and future options.
- Updated and Improved all Icons. 
- Updated/Reset Position Variables for new update.

- Renamed Portal Library to Dungeon Library.
- Renamed Portal Library Raid to Raid Library.

- Removed Unused Framepack Data.

- Non visual/background updates to prepare for future updates and features.

[3.0.8]

- The MOTHERLODE!! is a giant pain. But now has the correct Spell ID for the correct faction. If you have just unlocked that portal make sure to reload your UI.

[3.0.7]

- Fixed Horde and Alliance dungeon Spell ID for The MOTHERLODE!!
- Fixed Incorrect Version Number.

[3.0.6]

- Fix for Cinderbrew Meadery Acronym
- Fix for continuous error when you have 'The MOTHERLODE!!' key.

[3.0.5]

- Fixed dead Discord invite link.

- Updated name 'Alternative Locked Icons' to 'Alternative Lock Icons'.
- Updated Addon Usage Text.
- Updated Daily Start-up message.

- Data Updates and Maintenance.

- Removed 'Shift' Key Movement. Frames can now be freely moved around without holding down 'Shift'.

[3.0.4]

- Updated Liberation of Undermine lock icon.
- Updated Login Information to display more useful information.

- Fixed Incorrect Spell ID for Key Tracker.
- Fixed Incorrect Spell ID tracking for Known/Unknown teleports.

[3.0.3]

- Added Liberation of Undermine to the Portal Library Raid. [Currently uses ML lock icon, will be updated later.]

- Fixed incorrect spelling and wording in the Update Splash Window.
- Fixed External Links overlapping and duplicating and now can be closed with 'esc'. Applied to the Update Splash Window links also.
- Fixed Mechagon teleport being in the incorrect place in the Portal Library.
- Fixed Karazhan teleport being in the incorrect place in the Portal Library.

Currently Known Issues

- Sometimes the Key Tracker shows no key.
- Sometimes the Cooldown Overlay Texture for the Key Tracker Button doesn't always show.

[3.0.2]

- Fix for Theatre of Pain having the incorrect Spell ID.
- Fix for Key Tracker updating Keystone Information in combat.

[3.0.1]

- Added Data for future Portal Library Raid Update.

- Fixed Season 2 Portals to be Alphabetical.
- Fixed TWW Portal Library Portals to be Alphabetical.
- Fixed External Links overlapping and duplicating and now can be closed with 'esc'.

- Removed Framepacks altering the Settings exit button.
- Removed 'RaidPortals.lua' from toc file.
- Removed all textures from Framepacks and UI that altered the Settings Exit Button, Reset Button and the Dungeon Finder Settings Button.

[3.0.0]

Whats new in 3.0.0?

- Added The War Within Season 2 Portals.
- Added All Available TWW Portals to the Portal Library, including Operation: Floodgate in 11.1 

-- Added Keystone Tracker
- Shows your current key and level.
- Teleport straight to your key with no fuss. As long as you have the portal unlocked, locked portals show in red.
- !keys button. To list party member keys. Can respond with M+DT, Astral Keys, WeakAura's or any other Addon that uses !keys.
- Still a work in progress, more Features to be added in the future. Can be toggled off.

-- Added and Updated Framepacks
- Framepacks now use a new template and location, update your custom Framepacks accordingly.
- Updated all old and new Framepacks to use new Template.
- Renamed 'Purple Glow' to 'Purple Neon'.
- Added 'Love is in the Air' Framepack.
- Added 'Noblegarden' Framepack.
- Added 'Default Borderless Frames' Framepack

-- Reworked Settings.
- Settings Button no longer is affected by Framepacks.
- Settings Button and other windows now uses the default open/close UI sound effect.
- Addon Version moved from the now removed Info Panel and shown in Settings.
- Addon Use-age settings now shown in the Settings info panel section.
- Framepacks and UI Elements no longer affect the Settings window.
- Updated UI Scale Text Information.
- Updated UI Positioning and Size.
- Updated Checkbox Texts and Formatting.
- Added a Season 2 toggle.
- Added a Keystone Tracker Toggle.
- Added a Toggle to respond to !keys with the M+ Dungeon Teleports Addon.
- Added a Discord Link to the M+ Dungeon Teleports Discord.
- Added a Curseforge Link.
- Added a Wago Link.

-- Compact Mode
- All Frames now have a Compact Mode that shrink down to maximize space.
- Compact mode does not use framepacks.

-- Alternative Lock Icons
- All Unknown/Locked portals can now displays alternative icons to the default lock icon.

-- General Additions
- Added a functions for 3.0.0 to wipe saved settings because of new file paths are incompatible with previous versions of the Addon. [Saved Settings will only be wiped if something is going to break.]
- Added Season 2 Dungeon Data.
- Added 'BlizzUI' settings button for non ElvUI users.
- Added The MOTHERLODE! Teleport to the BFA Section of the Portal Library

- General Addon Optimization. More incoming if needed.

- Moved Dungeon Data, Raid Data and Framepack Data to the Data folder.
- Moved First Launch to extensions and renamed to Feature.

- Updated for 11.1
- Updated Tooltips Information.
- Updated First Time Startup Frame Positions adjusted for Season 2 being added.
- Updated File Structure and Paths.
- Updated Portal and Framepack Tables.
- Updated Daily Launch Text.
- Updated Addon Toc file information.
- Updated First Launch window to a new features window. Shows on major updates with new features and first time use.
- Updated Button Texts
- Updated Title Texts

- Fixed Framepack Dropdown Text being incorrect again.
- Fixed Framepack Dropdown not being populated.
- Fixed Settings Button not showing it's button.
- Fixed Settings Button having overlapping textures.
- Fixed Settings Exit button from not showing.
- Fixed UI Scale Slider from not showing correct values.
- Fixed the AddOn using way more memory than it should of been.
- Fixed Red Shift Framepack missing a Texture.
- Fixed Portal Buttons not always registering a click/press.
- Fixed Combat Lockdown not always working.

- Fully Removed Info Panel.
- Fully Removed Portal Helper.
- Removed Unused Textures.
- Removed Addon Logo from root.
- Removed peepoStudy logo from root.
- Removed First Launch.

[2.1.14]

- Added Love Is In The Air Framepack

[2.1.13]

- Works on 11.1 PTR, 3.0.0 PTR Ready.

- Removed Unused Textures

- Altered some text.

[2.1.12]

- Compatable on PTR for 11.1
- Fixed Incorrect Version Number
- Fixed Errors.
- Removed Info Panel
- Removed Portal Helper

[2.1.11]

- 11.0.7 Update Day.

[2.1.10]

- Added Winter's Veil Frame Pack

[2.1.9]

- 11.0.7 Ready.

- Removed Patch Data, no longer needed for 3.0.0

[2.1.8]

- Fixed incorrect file location for textures.

- Removed old code.

[2.1.7]

- Changelog added to root directory of addon.
- Housekeeping.

[2.1.6]

- Portal Windows can no longer be lost outside of the game window bounds.


[2.1.5]

- Fixed Season 1 Frame not showing portals of you didn't know them.
- Fixed Hallow's End 'x' exit button hover over effect not showing.


[2.1.4]

- Updated First Time Frame Start up positions. [Changed due to fix below*]

- Fixed Frames not dynamically shifting with the dungeon frame size [Switching to PvP and other frames*]
- Fixed Frame and UI Packs not updating correctly.
- Fixed Hallow's End Frame Pack from displaying the incorrect overlay.
- Fixed unknown portals from not showing and leaving gaps

- Removed unused feature on Portal Library that was unintended to release.

[2.1.3]

- Updated Interface for 11.0.5

- Fixed Dropdown showing incorrect value.

[2.1.2]

- Updated Dropdown Menu to make room for more frame packs.

[2.1.1]

- Added 'Hallows End' Frame Pack

[2.1.0]

- Added 2 more slots for Custom Frame Packs for a total of 3. Custom 1, Custom 2 and Custom 3.
- Added 'Purple Glow' frame pack.

- Updated Checkbox UI
- Updated UI to follow the frame pack selection.
- Updated Portal Helper Icon
- Updated Info Icon
- Updated Button UI Assets.
- Updated Cooldown Overlay to be more transparent than a near blackout.

- Fixed Portal Button Overlays drawing in the wrong orders.
- Fixed UI Button Overlays drawing and clipping.
- Fixed Info Panel UI and Background not updating
- Fixed Portal Helper UI and Background not updating.

- Removed Original Clean [It's just a border difference]


[2.0.2] 

- Added First Time Launch Window, explaining how the addon works and how to access the settings. [This will show up for all users regardless if you already had it.]
- Added a toggle for tooltips over portals.
- Added Reset Button to reset the AddOn.

- Updated Checkboxes in Settings.
- Updated First Launch Window Positions.

- Fixed Word wrap in Info Panel.

[2.0.1]

- Added a new frame pack 'Toxic Claws'

- Settings is no longer accessible in combat.
- Custom Frame Pack option has default frames set until a custom.blp has been added by a user.
- Default frames have their opacity corrected.
- Logo's and text in the Info Panel have been corrected.
- Removed any left over Debug print.
- Info Panel's tooltip now shows.
- Info Panel and Portal Helper now have background for all preset Frame Packs.
- Portal Helper's Title is now correct.
- Info Panel and Portal Helper background now update accordingly.
- Added usage info to the Info Panel.

[2.0.0]

This update comes with a plethora of new features for customization, plenty of QoL changes as well as a few bug fixes.

Added Frame Customization [Options below, more are in the works for future updates.]
- Default
- Original (Clean)
- Red Shift
- Blue Shift
- Custom [See information below on how to add your own custom frame.]

- Added Settings button to PVEFrame an alternative to '/dp'.
- Added Portal Helper. Shows where portals were acquired from and if you can still get them. [information to be updated and improved]
- Added Info Panel for patch notes and other relevant information. 
- Added the ability to scale frames.

- Updated Lock Icon. 
- Updated AddOn .toc Logo.
- Updated AddOn ingame .toc name.
- Updated font to be 'Expressway' instead of using your default UI font, everything should be uniform with this.
- Updated buttons to be more like.. buttons. Borders, Highlights e.t.c.
- Updated login message to be once per day, not every login. Version also updates from .toc instead of manually updating.
- Updated buttons sizes to 32x32 from 28x28. 28x28 caused problems with textures and scaling, 32x32 should resolve this.
- Updated positioning of all buttons and frame sizes.
- Updated default_frames.blp and new frames to match new frame sizing.
- Updated Addon .toc Tooltip.

- Fixed Siege of Boralus portal sometimes choosing the wrong Spell ID.
- Fixed Icon for Sanctum of Domination raid portal.
- Fixed incorrect dungeon abbreviations.

To add your own custom frame, you need to use the template provided in "MDungeonTeleports\media\frames\template.png". Use this in your photo editing software of choice to create your own frames. To load this into your addon, you must save the edited template as 'custom.blp' you can use a converter such as 'BLPNG Convertor' on WoWInterface to save your file as ".blp". Once you have a file saved as 'custom.blp' you need to place it in the addon folder where you first found the template, so the path of the file should be 'MDungeonTeleports\media\frames\custom.blp'. Make sure to reload your game once you have placed the texture in the folder, then once you have reloaded, select custom in the setting of the addon and there you go, your own frames!


[1.2.8]

- Fix for [SOB] Siege of Boralus
- Fix for incorrect icon for Sanctum of Domination

[1.2.6]

- Fix for buttons not registering as clicked. Should be fixed, leave a comment if you're still having issues.

[1.2.4]

- Fix for users not being able to click the buttons. (thanks to toludin for spotting that).
- Fix for SOB (Siege of Boralus) portal not showing unlocked for Horde toons.

[1.2.3]

- New backgrounds/frames.. more to come.
- Settings updated for new updates.
- General housekeeping.

[1.2.2]

- Frames now lock to the Dungeon UI and can be moved around alongside it.
- Portal/Spellcooldowns now tracks in minutes and seconds when appropriate.
- Fixed a few oversights and problems for Portal/Spell Cooldowns.
- Removed the scaling system. (The AddOn scales with your UI, it doesn't need another scaling system, I will possibly revisit this, but for now, it's gone)
- Removed some bloat/WIP features to add for later updates.
- Borders removed temporarily.
- Set new positions on the first load-up.

[1.2.1]

- Added UI Scaling use (Shift+ScrollWheel) on the window/frame you want to scale. Reset button in settings '/dp'

[1.2.0]

- Raid Teleports Added

- Updated Locked Portal icon.
- Frames now have borders.
- Added toggle for Raid Teleports in Settings.
- Fixed Throne of the Tides (TOTT) Icon.

[1.1.1]

- Corrected dungeon abbreviations for new teleports.

[1.1.0]

- Added Cooldown Text
- Added Locked Teleports
- Added New Icon

[1.0.0]

- Release