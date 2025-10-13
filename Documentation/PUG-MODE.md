NextKey PUG Helper - AI Development Guide
Document Purpose: This guide details the technical and user experience requirements for the "PUG Helper" mode of the NextKey addon. It is intended for an AI Coder to generate the necessary Lua code for this feature.
Target Audience: World of Warcraft players participating in Mythic+ dungeons via the LFG ("pugging") system, who have unlocked dungeon teleports.
Core Philosophy: The PUG Helper is designed to eliminate the confusion and friction inherent in joining Mythic+ groups through the LFG tool. When a player applies to multiple groups, they lose context. This feature provides immediate, critical information upon receiving an invite and streamlines the process of getting to the dungeon, allowing the player to focus on preparing for the run. It should feel lightweight, automatic, and essential.
1. Feature Logic Flow & State Management
The PUG Helper operates as a state machine, triggered by player actions and game events.
State 1: Idle & Application Tracking
Trigger: The player opens the LFG tool (LFG_LIST_APPLICATION_LIST_UPDATED event can be monitored).
Action: "Application Sniffing"
When the player clicks "Sign Up" for a Mythic+ group, the addon must silently cache the following data into a temporary table:
dungeonID: The numeric ID of the dungeon.
dungeonName: The localized name of the dungeon (e.g., "Halls of Atonement").
keyLevel: The keystone level (e.g., 18).
leaderName: The full name of the group leader (e.g., "Warríor-Tichondrius").
groupNote: The public note/description of the group.
This cache should be a list of all pending applications. An entry should be cleared from the cache if the application is declined or delisted.
State 2: Invite Received & Context Provided
Trigger: The game fires the GROUP_INVITE event.
Action: "Invite Matching"
On GROUP_INVITE, get the name of the inviting player.
Compare the inviter's name against the leaderName field of all entries in the pending application cache.
If a match is found:
Display the Contextual Invite Notification UI. (See Section 2.1)
The notification should appear on-screen near the default Blizzard invite frame.
If no match is found, do nothing.
State 3: Group Joined & Travel Initiated
Trigger: The player accepts the invite and the GROUP_JOINED event fires.
Action: "Display Travel Assistant"
When the player successfully joins the party, hide the Contextual Invite Notification.
Immediately display the Travel Assistant UI. (See Section 2.2)
The Travel Assistant must be populated with the correct dungeon information (dungeonName, keyLevel) from the matched application cache entry.
The addon must check the player's spellbook for the corresponding dungeon teleport spell.
State 4: Dungeon Run Complete & Exit
Trigger: The CHALLENGE_MODE_COMPLETED event fires.
Action: "Display Getaway Assistant"
When the Mythic+ run ends, hide the Travel Assistant UI if it is still open.
Display the Post-Run Getaway UI. (See Section 2.3)
This UI provides simple, one-click options to leave the dungeon and party.
2. UI Component Specifications
2.1. Contextual Invite Notification
Appearance: A small, non-intrusive frame or "toast" notification.
Content:
Header Text: "NextKey Invite"
Primary Text (Large Font): {Dungeon Name} +{Key Level}
Secondary Text: "Leader: {Leader Name}"
Tertiary Text: "Note: {Group Note}"
Behavior:
Appears when a matched invite is detected.
Disappears when the invite is accepted, declined, or expires.
2.2. Travel Assistant UI
Appearance: A stylized window, themed to match the modern WoW UI. It should be movable but appear centered by default. The design should match the provided image concept.
Structure:
Header: "NextKey Travel Assistant" with a close button.
Dungeon Icon: A large, prominent icon representing the dungeon. This is the centerpiece of the UI. Use GetMapArtInfo or a similar function with the mapID to retrieve the appropriate art asset or texture.
Dungeon Name & Level (Large Font): Placed below the icon. Example: Brackenhide Hollow +18.
Destination Sub-text: "Destination: {Dungeon Name}"
Primary Action Button (Large):
Text: Teleport: {Dungeon Name}
Functionality: Casts the appropriate teleport spell.
State: Button should be enabled if the spell is known and usable (not in combat, not moving). Greyed out otherwise.
Secondary Action Button (Smaller):
Text: Ask for Summon
Functionality: Sends a pre-defined, configurable message to party chat (e.g., "Summon please?"). Must have a cooldown (e.g., 30 seconds) to prevent spam.
Tertiary Information Text (Small):
Text: Hearthstone: {Zone Name} ({Status})
Functionality: Shows the player's hearthstone location and whether it's on cooldown.
2.3. Post-Run Getaway UI
Appearance: A small, simple frame that appears after dungeon completion.
Structure:
Header Text: "Run Complete!"
Primary Button: [Teleport: Valdrakken] (Or the current expansion's main city).
Secondary Button: [Leave Group]
3. Data Requirements & Game API
Events to Monitor:
LFG_LIST_APPLICATION_LIST_UPDATED
GROUP_INVITE
GROUP_JOINED
CHALLENGE_MODE_COMPLETED
Functions to Use:
C_LFGList.GetApplicationInfo(): To get details of groups in the LFG tool.
C_Spell.IsSpellKnown(): To check for dungeon teleport spells.
CastSpellByName(): To activate teleports.
SendChatMessage(): For the "Ask for Summon" feature.
GetBindLocation() & GetItemCooldown(): For Hearthstone status.
LeaveParty(): For the "Leave Group" button.
Dungeon Data: Maintain an internal table that maps dungeonID to the required spellID for teleports and the artAssetID for the UI icon.
The War Within Season 3 Dungeon List (For internal data table):
Eco-Dome Al'dani
Ara-Kara, City of Echoes
The Dawnbreaker
Priory of the Sacred Flame
Operation: Floodgate
Halls of Atonement
Tazavesh: Streets of Wonder
Tazavesh: So'leah's Gambit
4. Configuration Options
Provide a simple section in the addon's main settings panel for:
Enable/Disable PUG Helper: A master toggle for the entire feature. (Default: Enabled).
Summon Message: An edit box to customize the "Ask for Summon" message. (Default: "Summon please?").
Summon Channel: Dropdown to select "Party" or "Whisper Leader". (Default: Party).
