# **M+ Group Organizer \- Product Requirements Document**

# **1\. Overview**

### **1.1. Introduction**

This document outlines the requirements for the "M+ Group Organizer," a new feature module for the existing addon. This feature is designed to replace the current "compact mode" UI that activates for groups of 6 or more players.  
When the group/raid size exceeds 5 players, the addon's main window will transition from the 5-man "Keystone Card" optimizer to this new "Roster Board" interface. This provides leaders with a powerful tool to organize multiple M+ groups, while also allowing other raid members to view the organization process in semi-real-time.

### **1.2. Problem Statement**

Organizing multiple M+ groups from a large pool of players is a chaotic and time-consuming manual process. It involves:

* Verbally polling participants for interest, roles, and character choice.  
* Juggling alts, keystones, and player preferences (e.g., in voice chat or spreadsheets).  
* Manually building balanced groups, which is prone to error.  
* The current "compact mode" is too simple and does not provide the necessary organization tools for large-scale group building.

This feature aims to solve these problems by providing a centralized, interactive UI that supports both manual and automated group-building workflows.

### **1.3. Goals & Objectives**

* **Provide a centralized UI:** Create a single "Roster Board" interface to manage all potential M+ participants.  
* **Integrate with existing UI:** Replace the current 6+ player "compact mode" with this new Roster Board view.  
* **Support flexible workflows:** Allow leaders to build groups 100% manually via drag-and-drop or use a powerful optimizer to do it for them.  
* **Enable leader control:** Ensure the optimizer's results are not final; leaders must have the ability to fine-tune and manually adjust any automated groupings.  
* **Designate Group Keystones:** Allow the Organizer or the optimizer to select a specific player's keystone as the one the group will be formed around.  
* **Provide transparency:** Allow non-leader participants to see a read-only "spectator" view of the Roster Board as it's being built.  
* **Accurately poll participants:** Gather detailed preferences for participation, character selection (including alts), and role priority.  
* **Streamline communication:** Allow the leader to announce the final group compositions to various chat channels with a single click.

## **2\. User Personas**

* **Group Leader / Raid Assistant (The "Organizer"):** The primary user. They need control, flexibility, and clear information to build effective groups quickly.  
* **Raid Member (The "Participant"):** Any player in the group with the addon. They need a simple way to communicate their preferences and a clear way to see the results.  
* **Auto-Detected User:** A player in the group *without* the addon. The system must automatically identify them and create a basic card so the Organizer can manually manage them.

## **3\. User Stories**

### **3.1. Organizer (Leader/Assistant)**

* **As an Organizer,** when my group grows to 6 or more players, I want the addon UI to automatically become an interactive "Roster Board."  
* **As an Organizer, I want** to poll all raid members to see who wants to play, what role they prefer, and on which character.  
* **As an Organizer, I want** to see all interested players on a "Bench" and manually drag-and-drop their cards into groups.  
* **As an Organizer, I want** to see players who decline or are switching alts in a separate "not playing" area at the bottom of the screen.  
* **As an Organizer, I want** to run an optimizer to automatically sort players into groups *and* designate the best keystone for each group.  
* **As an Organizer, I want** to manually adjust the groups *after* the optimizer has run, including changing which keystone the group is using.  
* **As an Organizer, I want** the addon to **automatically detect** members *without* the addon and create a basic player card for them on the 'Bench' so I can manage them manually.  
* **As an Organizer,** when I have a number of players not divisible by 5, I want to choose how the optimizer forms partial groups (e.g., maximize full groups, or distribute players evenly).  
* **As an Organizer, when forming partial groups, I want to specify if those groups are allowed to PUG their own Tank or Healer, since DPS are easier to find.**  
* **As an Organizer, I want** to announce the final, locked-in groups to Raid, Instance, and Guild chat.

### **3.2. Participant (Raid Member)**

* **As a Participant, I want** to receive a clear pop-up asking if I want to join M+ runs.  
* **As a Participant, I want** to be able to opt-out if I am not interested.  
* **As a Participant, I want** to select my alt character because it has a better keystone or is better geared. Or I prefer to play them for any reason.  
* **As a Participant, I want** to indicate that I *prefer* to do one role like, DPS but am *willing* to heal (or tank) if the group needs it.  
* **As a Participant,** when I open the main addon window in a large group, I want to see a read-only view of the Roster Board so I can watch the groups being formed.

## **4\. Core Feature Requirements**

### **4.1. Access & Initiation**

* **Conditional UI Fork:** The addon's main UI will now have two primary states based on group size:  
  * **1-5 Players (Party):** The existing 5-man "Keystone Card" optimization UI will be displayed.  
  * **6+ Players (Group/Raid):** The main UI will automatically switch to the new "Roster Board" view.  
* **View-Level Access Control:** The Roster Board itself will have two distinct states based on player status:  
  * **Organizer View (Leader/Assistant):** The full, interactive Roster Board. All controls (drag-and-drop, polling, optimization, announcing) are enabled.  
  * **Participant View (Standard Member):** A read-only "spectator" view. The participant can see the board and all player card movements in real-time, but all interactive controls are disabled.

### **4.2. Main UI: The Roster Board**

The Roster Board is the central interactive UI for this feature. It will be a multi-column, drag-and-drop interface.

* **Default View:** This board is the main UI for groups of 6+.  
* **Vertical Columns (Active Pool):**  
  * **Group 1, Group 2... (etc.):** A series of columns, each with 5 clearly marked slots (e.g., Tank, Healer, DPS, DPS, DPS). The header for each column will have a default title (e.g., "M+ Grp. 1") which will update to display the selected keystone's name and level (e.g., "ARA: \+10") when a keystone is designated for the group.  
  * **The 'Bench' (Pending / Pool):** A single, large scrollable column with no player limit. This is the default holding area for all players who opt-in or are manually added.  
* **Horizontal Row (Inactive Pool) :**  
  * **The 'Opt-Out' Row:** A single, wide, scrollable row positioned horizontally underneath all Group and Bench columns.  
  * This area will contain the Player Cards of participants who have declined the survey or whose main character is benched because they selected an alt.  
  * This row has no player limit and will scroll horizontally if needed.  
* **Interaction (Organizer View):** All "Player Cards" (see 4.3) are draggable between all columns and the 'Opt-Out' row. Dragging will be constrained by role (e.g., a non-Tank cannot be placed in a Tank slot).

### **4.3. Player Cards**

Each participant will be represented by a compact, draggable card.

* **Data Displayed:**  
  * Player Name (and Alt Name, if applicable), color-coded by Class.  
  * Selected Role(s), with a visual indicator for preference (e.g., (P) for Primary, (S) for Secondary, (F) for Fill).  
  * Current M+ Keystone (Dungeon abbreviation and level). If a keystone is present, a small, clickable "star" icon will be displayed next to it.  
  * Overall Mythic+ Rating.  
* **Temporary Player Cards:** When a participant selects an alt, a "temporary fake player" card is created on the board. This card is visually identical and contains all the cloned data of the alt (see 4.5).  
* **Keystone Designation:**  
  * When a Player Card is placed into a Group column, the Organizer can click the "star" icon on that card.  
  * Clicking the star designates that player's keystone as the "group keystone."  
  * This action will update the header of the Group column to display the keystone's name and level (e.g., "MDI: \+10").  
  * Only one keystone can be designated per group (clicking a new star will override the previous selection for that group).

### **4.4. The Participant Survey**

* **Trigger:** A "Poll Group" button in the Organizer's wizard will send a SendAddonMessage request.  
* **Recipient UI:** Any raid member with the addon will receive a pop-up window.  
* **Survey Options:**  
  1. **Participation:** Clear buttons for **Opt-In** or **Opt-Out**.  
  2. **Character Selection (if Opt-In):** A card list allowing the choice between their current character or any of their saved, max-level alts. The list will display the keystone for each character if they have one, or display no keystone if they dont have one or a reset has happened (server resets clear keystones every Tuesday).  
  3. **Role Selection (if Opt-In):** Checkboxes for Tank, Healer, and DPS. For each role checked, a dropdown/selector will appear to set preference: Allow selecting the same preference for multiple roles to treat them the same. Fill indicates that the player would prefer not to play but can if needed, this greys out a small icon on the player card that shows roles.  
     * **Will Play** (Default)  
     * **Fill**  
* **Response Handling:**  
  * **Opt-In (Current Character):** Creates a Player Card and places it on the Organizer's 'Bench'.  
  * **Opt-In (Alt Character):**  
    1. Creates a "temporary fake player" card for the **alt** and places it on the 'Bench'.  
    2. Creates a standard Player Card for the **main character** and places it in the 'Opt-Out' **row**.  
  * **Opt-Out:** Creates a Player Card and places it on the Organizer's 'Opt-Out' **row**.

### **4.5. Data & Logic**

* **Account-Wide Character Storage:** The addon's saved variables will be expanded to store a list of all of a user's max-level characters.  
* **Stored Data per Character:**  
  * Character Name & Realm  
  * Class and roles played(this will have to be a new setting in the options menu per character)  
  * Current M+ Keystone  
  * Overall M+ Rating  
  * **Individual Dungeon M+ Scores**.  
* **Temporary Player Logic:** When a participant selects an alt in the survey, the system uses this stored data to create the "temporary fake player" card. This ensures the Organizer's optimizer has full, accurate data (including individual dungeon scores) for the chosen alt.  
* **Roster Board Synchronization:**  
  * To enable the read-only view, the Organizer's addon will broadcast state updates via SendAddonMessage to all other addon users whenever a change is made (e.g., a card is moved, optimizer results are complete, poll is started).  
  * Participant addons will listen for these state updates and refresh their (read-only) Roster Board UI to mirror the Organizer's view in near real-time.

### **4.6. Workflows**

#### **4.6.1. Manual Mode & Auto-Detection**

* This is the default state of the Roster Board for the Organizer.  
* When the "Poll Group" button is pressed (or the board is first loaded), the addon will **simultaneously:**  
  1. Send the poll request to all raid members *with* the addon.  
  2. Scan the raid roster for members *without* the addon.  
* **Automatic Card Creation:** For members *without* the addon, the system will automatically:  
  1. Create a "Non-Addon Player Card" using data from APIs and libraries (e.g., LibOpenRaid, WoW API).  
  2. Populate this card with all available data (Name, Realm, Class, Role, M+ Rating).  
  3. Place this card on the 'Bench'. A visual indicator (e.g., small icon on player cards with a hover tooltip in the Bench title bar that has the same icon acting as a key) to show this player was not polled.  
* **Organizer Workflow:** The Organizer will see the 'Bench' populate with cards from both poll respondents and auto-detected users. They can then:  
  1. Drag-and-drop all cards into Group columns or the 'Opt-Out' **row**. (They will need to verbally confirm with auto-detected users if they wish to play).  
  2. Designate a group's keystone by clicking the "star" icon on any player card within that group.

#### **4.6.2. Optimizer Mode**

* The Organizer's view will contain a control panel for the Optimizer.  
* **Controls:**  
  * **Mode Selection:** A dropdown to select the algorithm (see 4.7).  
  * **Partial Group Strategy:** A dropdown to select how to handle remainders when the 'Bench' is not divisible by 5\.  
    * **Maximize Full Groups (Default):** Creates as many 5-player groups as possible. All remaining players are placed into a single partial group, which must PUG any missing roles.  
    * **Distribute Evenly:** Attempts to create as many *viable partial groups* (e.g., 4 or 5 players) as possible. Viability is determined by the "PUG Preferences" settings.  
  * **PUG Preferences:** This section will be visible to modify the "Distribute Evenly" logic. (It may be hidden by default and only appear if "Distribute Evenly" is selected).  
    * \[ \] **Allow groups to PUG Tanks**  
    * \[ \] **Allow groups to PUG Healers**  
    * *(Note: It is assumed all partial groups are willing to PUG DPS.)*  
  * **"Optimize Groups" Button:** This button processes all Player Cards currently on the 'Bench', sorts them into the Group columns, and *automatically designates the optimal keystone for each group* based on the selected mode. The group column headers will update accordingly. Cards that cannot be placed will remain on the 'Bench'.  
  * **Note:** Auto-detected "Non-Addon Player Cards" will be included in the optimization based on their API-fetched data.  
* **Fine-Tuning:** After the optimizer runs, the Organizer retains full control. They can make any final adjustments by dragging cards between groups, swapping them with the 'Bench', or moving them to the 'Opt-Out' **row**.

### **4.7. Optimizer Algorithms (v1.0)**

The optimizer will support the three pre-defined modes. (Full specifications in the algorithm design document). The execution of these algorithms will be influenced by the "Partial Group Strategy" and "PUG Preferences" settings selected by the Organizer.

1. **Mode 1: Max Power (Greedy Maximization, Tends to form "A \- Teams" who gain the most IO and other groups gain less)**  
   * **Objective:** To maximize the sum of all IO gain across all formed groups.  
2. **Mode 2: Balanced (Fair Distribution)**  
   * **Objective:** To create groups of the most similar strength possible (IO gain \+ preference). When using "Distribute Evenly," this mode will now heavily rely on the "PUG Preferences" to form viable partial groups.  
3. **Mode 3: Vault Completion (Preference Maximization)**  
   * **Objective:** To maximize the number of groups that meet baseline requirements, prioritizing player happiness (preferences) over IO score.

### **4.8. Communication**

* The Organizer's view will feature an "Announce Groups" button.  
* Next to the button will be checkboxes for announcement destinations:  
  * \[ \] Raid Chat/Instance Chat  
  * \[ \] Guild Chat  
* Clicking the button will format the rosters from the Group columns and post them to all selected chat channels.

## **5\. Out of Scope (Future Considerations)**

The following features will not be included in v1.0 but may be considered for future releases:

* Whispering assignments directly to individual players.  
* "Social Preference" features (e.g., "Keep Player A with Player B," "Separate Player C and D").  
* Saving and loading Roster Board layouts that dynamically adjust to fill gaps. This could be used for dedicated groups in high end guilds who need to optimally fill a empty spot.