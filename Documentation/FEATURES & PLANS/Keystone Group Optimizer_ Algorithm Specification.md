# **Keystone Group Optimizer: Algorithm Specification**

Version: 1.3  
Author: (Your Name Here)  
Date: October 22, 2025

## **1.0 Introduction**

### **1.1 Purpose of this Document**

This document serves as the single source of truth for the design, logic, and mathematical implementation of the Keystone Group Optimizer (KGO) feature. It provides a detailed, technical breakdown of the three core operating modes, the data structures required, and the specific algorithms to be implemented for the "NextKey" addon.

### **1.2 The Core Problem**

The KGO feature aims to solve the complex combinatorial problem of organizing a pool of players (n) into optimal 5-player Mythic+ groups. "Optimal" is a subjective term, so the feature provides three distinct modes to cater to the most common goals of an organized group:

1. Maximizing total potential Raider.IO score gain. (A team, B team, C team)  
2. Creating balanced groups of similar strength. (Equal teams)  
3. Ensuring the maximum number of groups complete a "vault" run (+10 or higher).

### **1.3 Overview of the Three Modes**

1. **Mode 1: Max Power:** A greedy algorithm that finds the single best group (highest possible IO gain, strongly penalized by "Dislikes"), forms it, and then repeats.  
2. **Mode 2: Balanced:** A fair distribution algorithm that ranks all players by their total potential (IO gain \+ weighted preference), drafts them into balanced teams, and then optimizes the keystone choice within each team.  
3. **Mode 3: Vault Completion:** A checklist-based algorithm that ignores IO gain and instead forms the maximum number of groups, prioritizing the "happiest" groups (highest raw preference score, thus avoiding "Dislikes") first.

## **2.0 Core Data Structures & Definitions**

These are the fundamental data structures and functions used across all three modes.

### **2.1 Data Structures**

#### **2.1.1 Player Object (p)**

A Player object must contain the following properties:

* id: A unique identifier (e.g., "Name-Realm").  
* roles: A list of strings representing all performable roles (e.g., \["Tank"\], \["Healer"\], \["DPS"\], \["Tank", "DPS"\]). *(Developer Note: This should be derived automatically from the player's class and known specializations, not manual input.)*  
* utils: A list of strings representing provided utilities (e.g., \["Lust", "Brez"\], \["Brez"\], \[\]). *(Developer Note: This should also be derived automatically from class/spec.)*  
* keystone: A Keystone object they own.  
* scores: A map (or dictionary) of \[dungeon\_id: score\] for their current best score in each dungeon.  
* preferences: A map of \[dungeon\_id: preference\_value\] where preference\_value is \-1 (Dislike), 0 (Neutral), or 1 (Like).  
* rankScore: (Used by Mode 2\) A temporary variable to store their calculated rank.

#### **2.1.2 Keystone Object (k)**

A Keystone object must contain:

* dungeon\_id: A unique ID for the dungeon.  
* level: The keystone level (integer).  
* owner\_id: The id of the player who owns this key.

#### **2.1.3 Group Object (g)**

A Group object represents a final, formed group:

* players: A list containing 5 Player objects.  
* chosen\_keystone: The Keystone object the group will run.  
* total\_gain: The calculated total IO gain for this group.  
* total\_score: The final score (Gain \+ Preference) used for sorting.

### **2.2 Core Mathematical Functions**

These two functions are the atoms of the entire addon.

#### **2.2.1 V(d, l) \- Base Value Function**

This function returns the **base IO score** (as a number) for completing dungeon d at keystone level l, assuming an on-time completion with no time bonus or penalty.  
This is not a single lookup table but a hybrid function:

1. **For levels 2-20:** The function retrieves the base score from a static lookup table (the dungeonMatrix) that contains the base, min, and max scores for these levels.  
2. For levels 21 and higher: The function calculates the base score using a formula:  
   base\_score \= 145 \+ (level \* 15\) \+ 40  
* **Implementation:** This function must contain the dungeonMatrix lookup table for levels 2-20 and implement the formula for levels 21+.  
* **Example:** V(7, 15\) might return 225.0 (from the table). V(7, 21\) would calculate 145 \+ (21 \* 15\) \+ 40 \= 500\.

*(Note: The CalculateDungeonScore logic, which adds time-based bonuses or penalties, is used for calculating scores of completed runs, such as for populating the p.scores map. The V(d, l) function, for the purpose of potential gain, correctly just returns the base score.)*

#### **2.2.2 Gain(p, k) \- Player Gain Function**

This function calculates the potential IO score gain for a single player p from running a specific keystone k. This is the core of all score-based calculations.  
**Formula:**  
$\\text{Gain}(p, k) \= \\max(0, V(k.dungeon\\\_id, k.level) \- p.scores\[k.dungeon\\\_id\])$

* p.scores\[k.dungeon\_id\] fetches the player's current best score for that specific dungeon. If they have no score, this value is 0\.  
* V(k.dungeon\_id, k.level) gets the base score for that keystone.  
* max(0, ...) ensures the gain is never negative. If the run is not an upgrade, the gain is 0\.

### **2.3 Global Constraints (User-Defined)**

The addon UI must provide these controls:

* **Role Requirements (Hard Constraint):** 1 Tank, 1 Healer, 3 DPS. This is non-negotiable and built into all modes.  
* **Utility Requirements (Toggleable Hard Constraints):**  
  * \[ \] Require Lust/Heroism: If checked, a group is only valid if it has at least one player with "Lust" in their utils list.  
  * \[ \] Require Battle Rez: If checked, a group is only valid if it has at least one player with "Brez" in their utils list.  
* **Preference Weights (Sliders for Mode 1 & 2):**  
  * LikeBonus: A user-set number (e.g., 0-10, default: 1). This is the IO point value *added* for a "Like".  
  * DislikePenalty: A user-set number (e.g., 0-100, default: 25). This is the IO point value *subtracted* for a "Dislike".  
  * *(Note: Mode 3 ignores these sliders and uses the raw \-1/0/+1 values).*

## **3.0 Mode 1: Max Power (Greedy Maximization)**

### **3.1 Objective**

To maximize the **sum of all IO gain** across all formed groups. This mode finds the single best group (based on combined IO gain *and* preference), forms it, and then repeats the process on the remaining players.

### **3.2 High-Level Algorithm (Main Loop)**

This algorithm is a greedy, iterative process.  
function Mode1\_FindAllGroups(PlayerPool, Constraints):  
    FinalGroups \= \[\]  
    LeftoverPlayers \= PlayerPool.copy()

    while true:  
        // Find the single best group from the remaining players  
        BestGroup \= Find\_Best\_Possible\_Group(LeftoverPlayers, Constraints)

        if BestGroup is null:  
            // No more valid groups can be formed  
            break  
        else:  
            // Add the best group to our list  
            FinalGroups.add(BestGroup)  
            // Remove those 5 players from the pool for the next iteration  
            LeftoverPlayers.remove(BestGroup.players)

    return FinalGroups, LeftoverPlayers

### **3.3 Core Function: Find\_Best\_Possible\_Group**

This function iterates through every keystone and finds the highest-scoring 5-player group that can be formed for that keystone, factoring in both IO gain and preference.  
function Find\_Best\_Possible\_Group(PlayerPool, Constraints):  
    BestOverallGroup \= null  
    MaxFinalScore \= \-Infinity // Use \-Infinity to handle large penalties

    // 1\. Get all available keystones from the pool  
    AllKeystones \= \[p.keystone for p in PlayerPool\]

    // 2\. Iterate through every available keystone as the potential run  
    for keystone\_to\_run in AllKeystones:

        // 3\. Generate all valid 5-player combinations for this key  
        ValidGroupsForThisKey \= Generate\_Valid\_Combinations(PlayerPool, Constraints)

        // 4\. For each valid group, calculate its Final Score  
        for group in ValidGroupsForThisKey:  
              
            CurrentGain \= 0  
            PreferenceScore \= 0  
            for player in group:  
                CurrentGain \+= Gain(player, keystone\_to\_run)  
                  
                pref \= player.preferences.get(keystone\_to\_run.dungeon\_id, 0\)  
                if pref \== 1:  
                    PreferenceScore \+= Constraints.LikeBonus  
                elif pref \== \-1:  
                    PreferenceScore \-= Constraints.DislikePenalty

            // 5\. Calculate the weighted Final Score  
            FinalScore \= CurrentGain \+ PreferenceScore

            // 6\. Check if this is the best group found so far  
            if FinalScore \> MaxFinalScore:  
                MaxFinalScore \= FinalScore  
                BestOverallGroup \= {  
                    players: group,  
                    chosen\_keystone: keystone\_to\_run,  
                    total\_gain: CurrentGain,  
                    total\_score: FinalScore  
                }

    return BestOverallGroup

### **3.4 Helper Function: Generate\_Valid\_Combinations**

This function is the combinatorial engine.  
* **Developer Note:** A naive implementation with nested loops is insufficient as it cannot correctly handle players with flexible roles. The recommended approach is a **recursive backtracking algorithm**. The function would build a group one slot at a time (Tank, Healer, DPS1, DPS2, DPS3), passing the list of remaining available players to the next level of recursion to ensure no player is selected twice.

function Generate\_Valid\_Combinations(PlayerPool, Constraints):  
    // 1\. Create lists for each role from the pool  
    // Note: Players with flex roles appear in multiple lists  
    TankList \= \[p for p in PlayerPool if "Tank" in p.roles\]  
    HealerList \= \[p for p in PlayerPool if "Healer" in p.roles\]  
    DPSList \= \[p for p in PlayerPool if "DPS" in p.roles\]

    AllCombinations \= \[\]

    // 2\. Generate all 1T/1H/3D combinations (using a recursive helper) 
    RecursiveCombinationGenerator(TankList, HealerList, DPSList, ...)

    // 3\. Filter this list by utility constraints  
    ValidCombinations \= \[\]  
    for group in AllCombinations:  
        if Check\_Utility(group, Constraints):  
            ValidCombinations.add(group)

    return ValidCombinations

function Check\_Utility(group, Constraints):  
    if Constraints.RequireLust and not any("Lust" in p.utils for p in group):  
        return false  
    if Constraints.RequireBrez and not any("Brez" in p.utils for p in group):  
        return false  
    return true // All checks passed


### **3.5 Strengths & Use Cases**

* **Strengths:** Guarantees the "A-Team" is formed, maximizing the potential of the single highest key, while allowing "Dislikes" to be a strong deterrent.  
* **Use Cases:** Pushing for a seasonal "best" run, high-score vault slots, competitive environments.

### **3.6 Weaknesses**

* Still creates unbalanced groups by design.  
* May "use up" all the utility (e.g., all Tanks or all Lusts) in the first group, preventing other groups from forming.

## **4.0 Mode 2: Balanced (Fair Distribution)**

### **4.1 Objective**

To create groups of the most similar strength possible, where "strength" is a combination of potential IO gain and player preference.

### **4.2 High-Level Algorithm (Three-Phase Process)**

This is not an iterative loop; it's a one-shot process that forms all groups simultaneously.  
function Mode2\_FindAllGroups(PlayerPool, Constraints):  
    // Phase 1: Rank every player  
    RankedPlayers \= Calculate\_Player\_RankScores(PlayerPool, Constraints)

    // Phase 2: Draft players into balanced teams  
    NumGroups \= floor(len(PlayerPool) / 5\)  
    Teams \= Execute\_RoleConstrained\_Snake\_Draft(RankedPlayers, NumGroups)

    // Phase 3: Optimize keystones within each team  
    FinalGroups \= \[\]  
    for team in Teams:  
        FinalizedGroup \= Optimize\_Team\_Keystone(team, Constraints)  
        if FinalizedGroup is not null:  
            FinalGroups.add(FinalizedGroup)

    LeftoverPlayers \= ... // (Players not drafted)  
    return FinalGroups, LeftoverPlayers

### **4.3 Core Function 1: Calculate\_Player\_RankScores**

This function assigns a "Rank Score" to each player based on their total potential contribution (Gain \+ Preference).  
function Calculate\_Player\_RankScores(PlayerPool, Constraints):  
    AllKeystones \= \[p.keystone for p in PlayerPool\]  
    RankedPlayerList \= \[\]

    for player in PlayerPool:  
        TotalScore \= 0  
        // Calculate this player's score against EVERY key  
        for keystone in AllKeystones:  
            GainScore \= Gain(player, keystone)  
              
            PreferenceScore \= 0  
            pref \= player.preferences.get(keystone.dungeon\_id, 0\)  
            if pref \== 1:  
                PreferenceScore \= Constraints.LikeBonus  
            elif pref \== \-1:  
                PreferenceScore \= \-Constraints.DislikePenalty

            TotalScore \+= (GainScore \+ PreferenceScore)  
          
        player.rankScore \= TotalScore  
        RankedPlayerList.add(player)

    // Sort players from highest rank score to lowest  
    RankedPlayerList.sort(by=rankScore, order=descending)  
    return RankedPlayerList

### **4.4 Core Function 2: Execute\_RoleConstrained\_Snake\_Draft**

This function distributes players into teams while ensuring role balance. A standard snake draft is insufficient as it can lead to teams with no tanks or healers.  
function Execute\_RoleConstrained\_Snake\_Draft(RankedPlayers, NumGroups):  
    // 1\. Separate players into lists by role. Players with flex roles appear in multiple lists.  
    Tanks \= sorted(\[p for p in RankedPlayers if "Tank" in p.roles\], by=rankScore)  
    Healers \= sorted(\[p for p in RankedPlayers if "Healer" in p.roles\], by=rankScore)  
    DPS \= sorted(\[p for p in RankedPlayers if "DPS" in p.roles\], by=rankScore)

    // 2\. Draft each role category using a snake draft to distribute talent.  
    Teams \= \[\[\] for i in 1 to NumGroups\]  
    UsedPlayerIDs \= set()

    // Draft Tanks  
    DraftRole(Teams, Tanks, 1, UsedPlayerIDs) // 1 Tank per team

    // Draft Healers  
    DraftRole(Teams, Healers, 1, UsedPlayerIDs) // 1 Healer per team

    // Draft DPS  
    DraftRole(Teams, DPS, 3, UsedPlayerIDs) // 3 DPS per team

    return Teams

// Helper for the draft process
function DraftRole(Teams, RolePool, countPerTeam, UsedPlayerIDs):
    // Snake draft logic here, adding `countPerTeam` players to each team
    // while ensuring a player from UsedPlayerIDs is not selected twice.

### **4.5 Core Function 3: Optimize\_Team\_Keystone**

This function takes a drafted 5-player team, validates its roles, and finds the best keystone for *that specific team* to run (based on Gain \+ Preference).  
function Optimize\_Team\_Keystone(team, Constraints):  
    // 1\. (Role validation is now mostly handled by the draft, but a final check is good practice)
    if not Is\_Role\_Valid(team, Constraints.Utility): return null 

    // 2\. Find the best key for this valid team  
    TeamKeystones \= \[p.keystone for p in team\]  
    BestTeamScore \= \-Infinity  
    BestKeystone \= null  
    BestGain \= 0

    for keystone in TeamKeystones:  
        CurrentGain \= 0  
        PreferenceScore \= 0  
        for player in team:  
            CurrentGain \+= Gain(player, keystone)

            pref \= player.preferences.get(keystone.dungeon\_id, 0\)  
            if pref \== 1:  
                PreferenceScore \+= Constraints.LikeBonus  
            elif pref \== \-1:  
                PreferenceScore \-= Constraints.DislikePenalty  
          
        FinalScore \= CurrentGain \+ PreferenceScore  
          
        if FinalScore \> BestTeamScore:  
            BestTeamScore \= FinalScore  
            BestGain \= CurrentGain  
            BestKeystone \= keystone

    return {  
        players: team,  
        chosen\_keystone: BestKeystone,  
        total\_gain: BestGain,  
        total\_score: BestTeamScore  
    }

### **4.6 Strengths & Use Cases**

* **Strengths:** Produces groups of very similar potential, factoring in both IO gain and player happiness. The role-constrained draft ensures all teams are viable.  
* **Use Cases:** The default mode for most guild runs, community nights, and alt runs.

### **4.7 Weaknesses**

* The draft, while role-constrained, does not guarantee a perfectly even distribution of utility (Lust/Brez). One team may end up with all the utility while another has none, though this is less likely than with a simple draft.

## **5.0 Mode 3: Vault Completion (Preference Maximization)**

### **5.1 Objective**

To maximize the **number of formed groups** that meet the baseline checklist, while prioritizing the "happiest" groups first. IO score is **completely ignored**.  
**Checklist:**

1. Group has 1 Tank, 1 Healer, 3 DPS.  
2. Group is using a keystone of level 10 or higher.  
3. (If Toggled) Group has Lust.  
4. (If Toggled) Group has Brez.

### **5.2 High-Level Algorithm (Greedy Maximization by Preference)**

This is an iterative process. It finds the *happiest* valid group, forms it, and then repeats. *(This logic is unchanged, as it already prioritizes avoiding \-1 scores).*  
function Mode3\_FindAllGroups(PlayerPool, Constraints):  
    FinalGroups \= \[\]  
    LeftoverPlayers \= PlayerPool.copy()  
      
    // 1\. Filter keystones ONCE at the start  
    ValidKeystones \= \[p.keystone for p in PlayerPool if p.keystone.level \>= 10\]  
      
    while true:  
        // Find the group with the highest preference score  
        BestGroup \= Find\_Happiest\_Valid\_Group(LeftoverPlayers, ValidKeystones, Constraints)

        if BestGroup is null:  
            // No more valid groups can be formed  
            break  
        else:  
            FinalGroups.add(BestGroup)  
            // Remove players and the used keystone  
            LeftoverPlayers.remove(BestGroup.players)  
            ValidKeystones.remove(BestGroup.chosen\_keystone)  
      
    return FinalGroups, LeftoverPlayers

### **5.3 Core Function: Find\_Happiest\_Valid\_Group**

This function finds the single best group, where "best" is defined as the highest sum of raw player preferences (-1, 0, or \+1).  
function Find\_Happiest\_Valid\_Group(PlayerPool, ValidKeystones, Constraints):  
      
    BestOverallGroup \= null  
    MaxPreferenceScore \= \-Infinity // \-5 is worst possible, so \-Inf is safe

    // 1\. Generate all possible 1T/1H/3D combinations  
    AllCombinations \= Generate\_All\_Role\_Combinations(PlayerPool) // A variant of Generate\_Valid\_Combinations

    // 2\. Iterate through keystones first  
    for keystone in ValidKeystones:  
        // 3\. Then iterate through groups  
        for group in AllCombinations:  
              
            // 4\. Check if this group is valid for this key  
            if keystone.owner\_id not in \[p.id for p in group\]:  
                continue // This group can't use this key

            // 5\. Check utilities  
            if Check\_Utility(group, Constraints):  
                // This group is valid, now calculate its preference score  
                CurrentPreference \= 0  
                for player in group:  
                    // Use the raw \-1, 0, or \+1  
                    CurrentPreference \+= player.preferences.get(keystone.dungeon\_id, 0\)

                if CurrentPreference \> MaxPreferenceScore:  
                    MaxPreferenceScore \= CurrentPreference  
                    BestOverallGroup \= {  
                        players: group,  
                        chosen\_keystone: keystone,  
                        total\_gain: 0, // IO is not tracked  
                        total\_score: CurrentPreference  
                    }

    // 6\. If we loop through everything and find nothing:  
    return BestOverallGroup

### **5.4 Strengths & Use Cases**

* **Strengths:** Fast, simple, and optimizes for player happiness, which is the main goal of vault runs. It naturally avoids "Disliked" dungeons as they give a negative score.  
* **Use Cases:** Weekly vault runs, gearing alt characters, low-stress runs.

### **5.5 Weaknesses**

* The "greedy" logic can be inefficient for *maximizing the number* of groups. It might form one "very happy" group that uses the only Tank, preventing any other groups from forming.

## **6.0 Implementation Notes & Edge Cases**

### **6.1 Handling Flexible Roles (Multi-spec Players)**

To correctly handle players who can perform multiple roles (e.g., a Paladin who can Tank, Heal, and DPS), the combination generation algorithm must be carefully designed. When building a potential group, a player can only fill one slot.

For example, in `Generate_Valid_Combinations`, if a player is selected from the `TankList`, they must be excluded from the `HealerList` and `DPSList` for the remainder of that specific combination's generation. A recursive backtracking approach is a natural fit for this problem, as it can maintain a set of "used players" at each level of recursion.

### **6.2 Handling PUG Placeholders**

(Unchanged from v1.0)

### **6.3 Performance Considerations**

(Unchanged from v1.0)

The exhaustive search required by **Mode 1: Max Power** presents a significant performance challenge within the WoW addon environment. A naive implementation of `Find_Best_Possible_Group` would attempt to check a massive number of `(group, keystone)` combinations in a single frame, leading to a "Script ran for too long" error and crashing the client.

To mitigate this, the algorithm must be implemented as a pausable, on-demand process controlled by the user.

#### **6.3.1 On-Demand Execution via Optimizer Wizard**

Instead of running automatically, the KGO feature will be invoked through a dedicated UI window, the "Group Optimizer Wizard." This approach addresses the performance issues in several ways:

1.  **User-Driven Calculation:** The expensive optimization algorithms will only run when a user explicitly opens the wizard and clicks a "Calculate" button. This prevents background processing from impacting normal gameplay.

2.  **Stateful, Pausable Algorithm:** The core `Find_Best_Possible_Group` function will be re-architected as a state machine.
    *   **State:** The current state of the calculation will be saved between steps. This includes the list of remaining players, the list of keystones left to evaluate, the last combination checked, and the best group found so far.
    *   **Batch Processing:** The calculation will be broken into discrete chunks. A user will click a "Process Next Batch" button to execute one chunk of work (e.g., evaluating all combinations for a single keystone, or evaluating a fixed number of combinations).
    *   **Progress Feedback:** The UI will provide a progress bar and status updates (e.g., "Evaluated 500/10,000 combinations...") so the user understands the state of the calculation.

3.  **Resource Management:** While the Optimizer Wizard is open and actively calculating, other background features that consume resources will be temporarily disabled. This includes:
    *   Real-time IO score updates in tooltips.
    *   Automatic UI refreshes in response to group roster changes.

This multi-step, on-demand implementation allows for the use of the more accurate "Max Power" algorithm in a safe and responsive manner, giving the user control over the performance impact.

### **6.4 Data Acquisition**

Acquiring the data for the `Player` object requires querying multiple sources in a specific order of priority. The implementation should be robust to handle cases where a source is unavailable.

1.  **Player Preferences (`preferences` map):** This data must be loaded from the addon's own SavedVariables (`NextKeyDB.char.preferences`). This is the highest priority data as it directly impacts scoring.
2.  **Player Scores (`scores` map):** Score data should be sourced with the following fallback chain:
    a. From the addon's internal cache/database, which is populated by the `ProfilesService`.
    b. From the live Raider.IO addon, if installed and available.
    c. From LibOpenRaid, if installed and available.
    d. From the Blizzard Mythic+ API (`C_MythicPlus.GetMythicPlusRatingSummary`).
3.  **Keystones (`keystone` object):** Sourced via the existing keystone detection logic (Blizzard API, LibOpenRaid, bag scanning).
4.  **Roles & Utilities (`roles`, `utils` lists):** Determined by the player's class and current specialization via the Blizzard API (`UnitClass`, `GetSpecialization`).

**End of Document**