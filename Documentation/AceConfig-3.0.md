# AceConfig-3.0

AceConfig-3.0 wrapper library.
Provides an API to register an options table with the config registry, as well as associate it with a slash command.

## AceConfig:RegisterOptionsTable(appName, options [, slashcmd])

Register a option table with the AceConfig registry.
You can supply a slash command (or a table of slash commands) to register with AceConfigCmd directly.

### Parameters

- `appName`: The application name for the config table.
- `options`: The option table (or a function to generate one on demand). [AceConfig-3.0 Options Tables](AceConfig-3.0%20Options%20Tables.md)
- `slashcmd`: A slash command to register for the option table, or a table of slash commands.

### Usage

```lua
local AceConfig = LibStub("AceConfig-3.0")
AceConfig:RegisterOptionsTable("MyAddon", myOptions, {"/myslash", "/my"})
```