# RaiderIO Developer API

RaiderIO provides a developer-friendly API for accessing player scores and profiles within World of Warcraft addons. This documentation outlines the available methods and data structures for addon developers.

## Getting Started

The API is accessible through the global `RaiderIO` table. If the documentation appears out-of-date, you can refer to the source code which is annotated for the VSCode Lua language server extension.

## Core Methods

### GetProfile

Returns `nil` or a `RaiderIOProfile` table.

```lua
RaiderIO.GetProfile("target")
RaiderIO.GetProfile("Name", "Realm"[, region])
```

## Data Structures

### RaiderIOProfile

Base profile table containing data based on loaded providers.

```lua
{
  success = boolean,                                    -- Profile load status
  region = "us" | "kr" | "eu" | "tw" | "cn",          -- Player region
  faction = 1 | 2,                                     -- Player faction
  name = "Name",                                       -- Character name
  realm = "Realm",                                     -- Character realm
  mythicKeystoneProfile = RaiderIOMythicKeystoneProfile | nil,
  raidProfile = RaiderIORaidProfile | nil,
  recruitmentProfile = RaiderIORecruitmentProfile | nil
}
```

### RaiderIOMythicKeystoneProfile

Mythic+ specific profile data.

```lua
{
  -- Core Data
  hasRenderableData = boolean,           -- If false, treat table as nil (outdated data)
  currentScore = number,                 -- Current season M+ score
  previousScore = number,                -- Previous season M+ score
  previousScoreSeason = number,          -- Season number for previous score
  
  -- Role Information
  currentRoleOrdinalIndex = number,
  previousRoleOrdinalIndex = number,
  mainCurrentRoleOrdinalIndex = number,
  mainPreviousRoleOrdinalIndex = number,
  
  -- Main Character Data
  mainCurrentScore = number | nil,
  mainPreviousScore = number | nil,
  mainPreviousScoreSeason = number,
  
  -- Keystone Run Counts
  keystoneFivePlus = number,            -- Number of +5 or higher completed
  keystoneTenPlus = number,             -- Number of +10 or higher completed
  keystoneFifteenPlus = number,         -- Number of +15 or higher completed
  keystoneTwentyPlus = number,          -- Number of +20 or higher completed
  
  -- Dungeon Data Arrays
  fortifiedDungeons = number[],
  fortifiedDungeonTimes = number[],
  fortifiedDungeonUpgrades = number[],
  tyrannicalDungeons = number[],
  tyrannicalDungeonTimes = number[],
  tyrannicalDungeonUpgrades = number[],
  
  -- Best Run Information
  fortifiedMaxDungeon = RaiderIOMythicKeystoneDungeon,
  fortifiedMaxDungeonIndex = number,
  fortifiedMaxDungeonLevel = number,
  tyrannicalMaxDungeon = RaiderIOMythicKeystoneDungeon,
  tyrannicalMaxDungeonIndex = number,
  tyrannicalMaxDungeonLevel = number,
  
  -- Role-specific Data
  mplusCurrent = RaiderIOMythicKeystoneRoleInfo,
  mplusMainCurrent = RaiderIOMythicKeystoneRoleInfo,
  mplusMainPrevious = RaiderIOMythicKeystoneRoleInfo,
  mplusPrevious = RaiderIOMythicKeystoneRoleInfo,
  
  -- Sorted Collections
  sortedDungeons = RaiderIOMythicKeystoneDungeonProfile[],
  sortedMilestones = Milestone[],
  
  -- Dynamic Weekly Affix Data (set via metatable)
  dungeons = number[],
  dungeonTimes = number[],
  dungeonUpgrades = number[],
  maxDungeon = RaiderIOMythicKeystoneDungeon,
  maxDungeonIndex = number,
  maxDungeonLevel = number
}
```

### RaiderIOMythicKeystoneDungeonProfile

Individual dungeon run profile.

```lua
{
  dungeon = RaiderIOMythicKeystoneDungeon,  -- Dungeon information
  level = number,                            -- Keystone level
  chests = 0 | 1 | 2 | 3,                   -- Number of medals/chests earned
  fractionalTime = number                    -- Time completion ratio (0.0 to 1.0)
}
```

### RaiderIOMythicKeystoneDungeon

Dungeon static information.

```lua
{
  index = number,                     -- Dungeon index
  id = number,                        -- Dungeon ID
  instance_map_id = number,           -- Map ID
  keystone_instance = number,         -- Keystone instance ID
  lfd_activity_ids = number[],        -- LFD activity IDs
  name = string,                      -- Full dungeon name
  shortName = string,                 -- Abbreviated name
  shortNameLocale = string,           -- Localized abbreviated name
  timers = number[]                   -- Timer thresholds
}
```

### RaiderIOMythicKeystoneRole

Role specification structure.

```lua
{
  [1] = "tank" | "healer" | "dps",    -- Role type
  [2] = "full" | "partial"            -- Role completion status
}
```
}

RaiderIOMythicKeystoneRoleInfo

{
  roles = RaiderIOMythicKeystoneRole[]
  score = number
  season = number | nil
}

RaiderIORaidProfile

{
  hasRenderableData = boolean - if false pretend the table was nil instead (the database is outdated so we don't want to show inaccurate data)
  progress = RaiderIORaidProfileProgress[]
  previousProgress = RaiderIORaidProfileProgress[]
  sortedProgress = RaiderIORaidProfileSortedProgress[]
  raidProgress = RaiderIORaidProfileRaidProgress[]
}

RaiderIORaidProfileProgress

{
  difficulty = 1 | 2 | 3
  progressCount = number
  raid = RaiderIORaidProfileRaid
  killsPerBoss = table<bossIndex, killCount>
}

RaiderIORaidProfileSortedProgress

{
  isMainProgress = boolean
  isProgress = boolean
  isProgressPrev = boolean
  obsolete = boolean
  progress = RaiderIORaidProfileProgress[]
  tier = number
}

RaiderIORaidProfileRaidProgressInfo

{
  count = number
  difficulty = number
  killed = boolean
}

RaiderIORaidProfileRaidProgress

{
  current = boolean
  fated = string
  progress = RaiderIORaidProfileRaidProgressInfo
  progressCount = number
  raid = RaiderIORaidProfileRaid
  show = boolean
}

RaiderIORaidProfileRaidDungeon

{
  index = number
  id = number
  instance_map_id = number
  lfd_activity_ids = number[]
  name = string
  shortName = string
  shortNameLocale = string
}

RaiderIORaidProfileRaid

{
  dungeon = RaiderIORaidProfileRaidDungeon
  id = number
  mapId = number
  name = string
  shortName = string
  bossCount = number
  ordinal = number
}

RaiderIORecruitmentProfile

{
  hasRenderableData = boolean - if false pretend the table was nil instead (the database is outdated so we don't want to show inaccurate data)
  entityType = number
  title = string[] - this locale key will yield the actual label from the locale table
  titleIndex = number
  tank = boolean
  healer = boolean
  dps = boolean
}

RaiderIO.ShowProfile

Updates a tooltip widget and appends the character profile just like how RaiderIO does to the regular tooltips. This function uses the same arguments as RaiderIO.GetProfile except the first is the tooltip widget.

RaiderIO.ShowProfile(tooltip, ...) => true | false - depending on if the tooltip was altered or not

RaiderIO.GetScoreColor

Returns the colors for a given score.

RaiderIO.GetScoreColor(score) => red, green, blue - in the range of 0.0 to 1.0

Deprecated

Please refrain from using these API as they will be removed in future updates.

RaiderIO.ProfileOutput
RaiderIO.TooltipProfileOutput
RaiderIO.DataProvider
RaiderIO.HasPlayerProfile
RaiderIO.GetPlayerProfile
RaiderIO.ShowTooltip
RaiderIO.GetRaidDifficultyColor
RaiderIO.GetScore
