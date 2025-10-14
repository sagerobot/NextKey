# Getting Started with Ace3

Keep in mind when reading through this that Ace3 is designed to be modular: not all addons may need to use every portion of it. Feel free to pick and choose those which suit the purposes of your addon, and skip over sections relating to bits you don't need.

## Basic Addon File Setup

Start by creating a folder for the addon in `<WoW Directory>\Interface\Addons`. The name can be whatever you want as long as it's unique, so pick something descriptive of what you're writing. Within that directory, you'll then want to create some text files:

### .toc file

This file should be named the same as the folder, except with ".toc" added to the end. It's a basic text file that tells WoW what other files the addon needs to load:

```
## Interface: 40000
## Title: My Addon's Title
## Notes: Some notes about this addon.
## Author: Your Name Here
## Version: 0.1

embeds.xml

Core.lua
```

The lines which begin with `##` provide information about your addon itself to WoW - for instance, "Interface" specifies the interface version your addon was designed to be loaded with (at the time of this writing 40000), "Title" specifies how the name of the addon should be displayed in the addon window, et cetera.

After the `##` lines, the rest of the .toc file is simply a list of files that make up the addon. Using a separate file named "embeds.xml" is a fairly commonly accepted way to specify which libraries you want to embed in your addon (such as Ace3 libraries). Also, most addons will typically have at least one "main" Lua file which has the initial code to set up the addon - some people like to be consistent and call this something like "Main.lua" or "Core.lua" in every addon, others prefer to name the main code file after the addon itself, like the .toc file except with a .lua extension.

### embeds.xml

Use this xml file to specify the locations of libraries that should be loaded (typically referencing the library's own XML file via Include). As an example, using LibStub and loading a pair of Ace3 libraries from a Libs subdirectory in the addon's folder:

```xml
<Ui xsi:schemaLocation="http://www.blizzard.com/wow/ui/ ..\FrameXML\UI.xsd">
  <Script file="Libs\LibStub\LibStub.lua"/>
  <Include file="Libs\AceAddon-3.0\AceAddon-3.0.xml"/>
  <Include file="Libs\AceConsole-3.0\AceConsole-3.0.xml"/>
</Ui>
```

Additional libraries can be added by adding additional Include lines. You could also reference each library's xml file in your addon's .toc file instead, but embeds.xml helps make it clearer which parts of the code belong to the addon itself, and which are part of shared libraries.

### Core.lua

This file doesn't have to be named "Core.lua" - it can be pretty much anything with a .lua extension, as long as you reference it in your .toc file. Your .lua files will contain the actual code which runs your addon. For the basics of what should be in here to make a completely Ace3-based addon, see the section below entitled "Using AceAddon-3.0".

## Using AceAddon-3.0

### Creating an addon object

After making sure you've properly referenced the AceAddon-3.0 library, as well as LibStub (see the above sections), the main Lua file for the addon (such as Core.lua) can create an Ace3 addon instance like so:

```lua
MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon")
```

This provides you with an addon object that can be referenced for all of AceAddon's calls related to your addon. In addition, if you wish to provide certain extra functionality tied in to your addon's object, you can use "mixins" that merge in other library functions - for instance, using the following instead would give you the chat interaction abilities provided by AceConsole in addition to the AceAddon methods:

```lua
MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceConsole-3.0")
```

### Standard methods

AceAddon typically expects your addon to define (typically in your main Lua file) 3 methods that it calls at various points:

```lua
function MyAddon:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
end
```

The `OnInitialize()` method of your addon object is called by AceAddon when the addon is first loaded by the game client. It's a good time to do things like restore saved settings (see the info on AceConfig for more notes about that).

```lua
function MyAddon:OnEnable()
    -- Called when the addon is enabled
end

function MyAddon:OnDisable()
    -- Called when the addon is disabled
end
```

The `OnEnable()` and `OnDisable()` methods of your addon object are called by AceAddon when your addon is enabled/disabled by the user. Unlike `OnInitialize()`, this may occur multiple times without the entire UI being reloaded.

## Using AceConsole-3.0

### Including AceConsole functionality

As mentioned above in the AceAddon section, the easiest way to access AceConsole functionality in a fully Ace3-based addon is to simply include it as a library mixin when creating your addon object:

```lua
MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceConsole-3.0")
```

Most examples in this section will assume you've used AceConsole as a mixin. However, if you wish to access the library as a separate object, you can load it via LibStub:

```lua
MyConsole = LibStub("AceConsole-3.0")
```

### Using AceConsole for output

Output with AceConsole is simple - just call its `:Print` method with the text you want to output. If used as a mixin, AceConsole will give your addon object the `:Print` method, otherwise, use the `:Print` method of the console object you've created:

```lua
-- AceConsole used as a mixin for AceAddon
MyAddon:Print("Hello, world!")

-- AceConsole used separately
MyConsole:Print("Hello, world!")
```

By default, `:Print`'d text will go to the default chat frame. If you wish to print to a different frame, simply pass that as the first argument to `:Print`, like so:

```lua
MyAddon:Print(ChatFrame1, "Hello, World!")
```

### Using AceConsole for slash commands

To allow your addon to process slash commands, you need to register them, and provide a reference to a function that will do the processing. This is done via AceConsole's `RegisterChatCommand()` method. Note that the first argument (the command) should not include a slash. The second argument can be either a method name of your addon object or an actual function.

```lua
MyAddon:RegisterChatCommand("myslash", "MySlashProcessorFunc")

function MyAddon:MySlashProcessorFunc(input)
  -- Process the slash command ('input' contains whatever follows the slash command)
end
```

However, in many cases it may be simpler to not code the processing of slash commands by hand, and instead utilize AceConfig's ability to generate slash commands automatically. Read on for how to use AceConfig to set up addon options.

## Using AceConfig-3.0

### Creating an options table and handlers

AceConfig is designed to make it easy for you to provide access to your addon's options, while also keeping config interfaces somewhat consistent for the end user. In order to do this, AceConfig automatically generates the actual interface used to modify settings: as an addon author, you simply need to provide it with the information about what options you want to make available and how to handle working with them. This is done by defining a table which is passed to AceConfig. A basic example is shown below:

```lua
local options = {
    name = "MyAddon",
    handler = MyAddon,
    type = 'group',
    args = {
        msg = {
            type = 'input',
            name = 'My Message',
            desc = 'The message for my addon',
            set = 'SetMyMessage',
            get = 'GetMyMessage',
        },
    },
}
```

The above options table defines a single setting, "msg", which is a textual input (`type = 'input'`) setting. `set` and `get` can be either method names of your addon object (or whatever object is defined as `handler`), or full functions. Those methods or functions will be called whenever the corresponding action is requested for that setting. So they might be set up something like this:

```lua
function MyAddon:GetMyMessage(info)
    return myMessageVar
end

function MyAddon:SetMyMessage(info, input)
    myMessageVar = input
end
```

For more details on the various types of settings available and their possible modifier flags, see the [AceConfig-3.0 Options Tables](AceConfig-3.0%20Options%20Tables.md) documentation.

### Registering the options

Once the options table is defined, it needs to be registered with AceConfig. This will also automatically tie it to slash command(s) if you choose. To register it, use LibStub to obtain an AceConfig-3.0 object, and call its `RegisterOptionsTable()` method:

```lua
LibStub("AceConfig-3.0"):RegisterOptionsTable("MyAddonName", options, {"myslash", "myslashtwo"})
```

The third argument is a list of slash commands you want tied to this option set. If you don't wish to tie any slash command to your options (i.e. if you only want to use a GUI for configuration), set the third argument to `nil`.

## Using AceDB-3.0

### Preparing SavedVariables

In order to persist anything from one load of an addon to the next, the addon must specify (via the `SavedVariables` TOC field) what to save. A common convention is to use a table named the same as the addon with a "DB" suffix to store the data which should be persisted:

```
## SavedVariables: MyAddonDB
```

The above should be added to the rest of the `##` lines present in the addon's .toc file. This is necessary to persist any settings even if not using Ace; AceDB simply provides a more easily accessible layer on top of SavedVariables.

### Initializing AceDB

It is important to understand that AceDB is layered on top of SavedVariables, and thus in order for AceDB to be able to load previously saved values, it needs to be initialized after the SavedVariables values have been loaded. What this means for addon authors is that you shouldn't create your instance of AceDB in the main chunk of your addon, but instead wait to do it until `OnInitialize()` or later:

```lua
function MyAddon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MyAddonDB")
end
```

The first argument passed to `New()` should be the name of the SavedVariables you set up in the TOC. You can also pass a table specifying default values for the DB (if it doesn't already exist) and a default profile, if you wish. Also, a brief note for more advanced authors: if for some reason your addon causes `LoadAddon()` to be called in the main chunk, `OnInitialize` will fire prematurely for your addon, so you'll need to take other measures to delay initializing AceDB since SavedVariables still won't be loaded.

### Persisting data values

Once you have AceDB set up, it's fairly easy to use - AceDB makes 8 subtables available: `char`, `realm`, `class`, `race`, `faction`, `factionrealm`, `profile`, and `global`. Any keys and values of each of these tables is persisted for all loads of an addon who share that subtable. For instance, anything in the `realm` subtable will be persisted for all loads of the addon by any characters on the same realm. Most of the subtable names are self-explanatory (`factionrealm` is similar to realm, but limited to a single faction, either Alliance or Horde). The only real exception is the `profile` subtable, which allows access to user-selectable profiles.

```lua
function MyAddon:MyFunction()
    self.db.char.myVal = "My character-specific saved value"

    self.db.global.myOtherVal = "My global saved value"
end
```

### Working with profiles

Profiles allow you to easily swap between sets of saved values in the `db.profile` subtable. To set the active profile, simply use the `SetProfile()` method of the db object:

```lua
db:SetProfile("NewActiveProfile")
```

You can get the currently active profile via the `GetCurrentProfile()` method, or get a table of names (integer-indexed) and count of all existing profiles via the `GetProfiles()` method:

```lua
activeProfile = db:GetCurrentProfile()
possibleProfiles, numProfiles = db:GetProfiles()
```

Other available profile functions including copying, deleting, and resetting profiles - see the [AceDB-3.0](AceDB-3.0.md) documentation for more information.

## Using AceDBOptions-3.0

AceDBOptions provides a quick way to integrate profile management into an addon using AceDB and AceConfig, without having to worry about `SetProfile`/`GetProfiles`. It can be set up via a single function call, which returns a table which can be included into the options table passed to AceConfig:

```lua
options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
```

You can call this right before you pass your options table to AceConfig: `db` is the name of your database object from AceDB, and in this case `options.args.profile` would be where in your options table you wish the "profile" command (and subcommands) to reside.

**Note**: The options table generated is shared between all addons that use it, do not change it!

## Using AceEvent-3.0

### Including AceEvent functionality

The recommended method for utilizing AceEvent is as a mixin, like so:

```lua
MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceEvent-3.0")
```

If you're not using AceAddon, you can still embed AceEvent in an object/table via AceEvent's `Embed()` function:

```lua
LibStub("AceEvent-3.0"):Embed(MyObject)
```

If you really don't want to embed AceEvent's methods in your objects, you can get a separate AceEvent object:

```lua
local AceEvent = LibStub("AceEvent-3.0")
```

However, by not embedding you lose some functionality such as automatic deregistering of events upon disable and better error reporting. All of the following examples will assume you're embedding AceEvent, but if you're not, just replace `MyAddon:function` with `AceEvent.function` and they should still work - though you may need to provide an extra argument or two (see the [AceEvent-3.0](AceEvent-3.0.md) docs for more details).

### Subscribing to events

At its simplest, all that needs to be done to subscribe to a given event is this:

```lua
MyAddon:RegisterEvent("NAME_OF_EVENT")
```

This will register your addon to receive events with the given name, and attempt to call `MyAddon:NAME_OF_EVENT()` to process them.

```lua
function MyAddon:NAME_OF_EVENT()
    -- process the event
end
```

You can also specify a handler function or method name instead of letting AceEvent look for the default method names:

```lua
MyAddon:RegisterEvent("NAME_OF_EVENT", "MyHandlerMethod")

function MyAddon:MyHandlerMethod()
    -- now handle it!
end


MyAddon:RegisterEvent("NAME_OF_OTHER_EVENT", function() doSomethingSpiffy() end)
```

The above examples discard any arguments passed to the event. If you want to have access to them, just include the argument specifications in your handler definition. However, note that the first argument passed to any handler function is always the name of the event, and then the arguments for the event come after that:

```lua
function MyAddon:NAME_OF_EVENT(eventName, arg1, arg2, arg3)
    -- do some stuff
end

function MyAddon:NAME_OF_OTHER_EVENT(eventName, ...)
    -- do some more stuff
end
```

### Sending/receiving inter-addon messages

AceEvent also provides support for "messages", which are basically like events except instead of being triggered by the WoW client, they're triggered by other addons. This is useful if you have multiple addons which need to talk to each other. Messages are subscribed to very similarly to events (and the alternate options for specifying handlers work for `RegisterMessage`, too):

```lua
MyAddon:RegisterMessage("NAME_OF_MESSAGE")

function MyAddon:NAME_OF_MESSAGE()
    -- handle the message
end
```

Sending messages to other addons is just as simple:

```lua
MyAddon:SendMessage("NAME_OF_MESSAGE")
MyAddon:SendMessage("NAME_OF_OTHER_MESSAGE", arg1, arg2)
```

Note that messages are only for addons running on the same client! If you want to send messages between various players and their addons, you'll want to use AceComm.

## Using AceComm-3.0

### Including AceComm functionality

As with AceEvent, AceComm can be mixed in, embedded, or called as a separate object. Examples of each (pick one):

```lua
MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceComm-3.0")

LibStub("AceComm-3.0"):Embed(MyObject)

local AceComm = LibStub("AceComm-3.0")
```

Also as with AceEvent, if you use AceComm as a separate object you will lose the convenience of automatic unregistration and better error reporting.

### Sending messages to other clients

To send a message to other client(s), use the `SendCommMessage()` method. Its basic usage requires the following arguments:

| Parameter | Description |
|---|---|
| prefix | A string tag to allow recipients to watch for the messages they want to receive. Must be printable characters only (\032 - \255). |
| text | The actual data to send in a string, can be contain any characters except nil (\000). Length is not an issue, data too long to be sent in a single comm message will automatically be split and reassembled on the other end. |
| distribution | Which channel to send the message to. Available channels are "PARTY", "RAID", "BATTLEGROUND", "GUILD", and "WHISPER". |
| target | Only applicable if distribution="WHISPER", this string is the name to send the message to: "Name" or "Name-Realm". |

```lua
MyAddon:SendCommMessage("MyPrefix", "the data to send", "RAID")
MyAddon:SendCommMessage("MyPrefix", "more data to send", "WHISPER", "charname")
```

### Receiving messages from other clients

To receive messages, your addon needs to register itself as listening for the prefix of the messages it wishes to receive. This is done via the `RegisterComm()` method.

```lua
MyAddon:RegisterComm("prefix")
```

By default, AceComm will attempt to call an `OnCommReceived` method of your addon object. You can also specify a handler via either method name or function reference as the second argument to `RegisterComm()`:

```lua
MyAddon:RegisterComm("prefix2", "MySecondCommHandler")
MyAddon:RegisterComm("prefix3", function() prefixthree() end)
```

The handler is passed 4 arguments, identical to those passed to `SendCommMessage` except instead of "target", the 4th argument is a string containing the sender of the message (included regardless of the distribution type).

```lua
function MyAddon:OnCommReceived(prefix, message, distribution, sender)
    -- process the incoming message
end
```

## Using AceHook-3.0

### Including AceHook functionality

Like other Ace libraries, AceHook is best used as a mixin, because you don't want to leave hooks sitting around if the user decides to disable your addon.

```lua
MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceHook-3.0")
```

### Hooking functions

There are two common methods of hooking a function: pre-hook (regular) and post-hook (secure). Pre-hooks are called before and sometimes in place of the function which is being hooked, and in the case of "raw" pre-hooks rely on the hook handler to call the original function as it deems necessary (the default non-raw or "failsafe" hooks in Ace3 will automatically call the original function after they finish). Secure hooks, on the other hand, are executed after the hooked function has been run, and the return values of the addon-designated handler for the secure hook are discarded. Secure hooks are necessary to avoid tainting execution paths when hooking protected elements of the Blizzard UI (see [here](http://www.wowwiki.com/Secure_Execution_and_Tainting) for more details regarding tainting).

#### Standard hooking

A standard hook is placed using the `Hook()` method of AceHook, typically mixed in to the addon object. The function to be hooked can be specified as a function name (for API functions) or as an object and method name pair.

```lua
MyAddon:Hook("APIFunctionName")
MyAddon:Hook(TargetObject, "TargetMethod")
```

By default, AceHook will redirect the call to your addon's object with an identically named method to the original function call:

```lua
function MyAddon:APIFunctionName(...)
    -- handle whatever we want to do before the hooked function is called
end
```

If you want to call some other function instead, you can specify a handler. The first two examples below will call the function `handlerFunc()`, the third will call `MyAddon:handlerMethod()`:

```lua
MyAddon:Hook("APIFunctionName", handlerFunc)
MyAddon:Hook(TargetObject, "TargetMethod", handlerFunc)

MyAddon:Hook("APIFunctionName", "handlerMethod")
```

If you want to pre-hook a normally secure function, but don't mind tainting it, you can add `true` at the end of the argument list to override AceHook's normal safety check. This will taint the execution path, however:

```lua
MyAddon:Hook("APISecureFunctionName", handlerFunc, true)
```

#### Raw hooking

By default, hooks made using Ace3 will automatically call the originally hooked function as normal with its original arguments after your hook handler has run. If, however, you wish to either change the arguments to the original function with your hook handler, or perhaps not even run the original function at all, you'll need to set a raw hook instead.

Setting a raw hook as the same options as setting a regular hook, but uses `RawHook()` instead:

```lua
MyAddon:RawHook("APIFunctionName")
MyAddon:RawHook(TargetObject, "TargetMethod")
```

Remember, if you set a raw hook you need to call the original hooked function yourself unless you don't want it to run at all! Also, as with `Hook()`, adding `true` as a final argument will override AceHook's secure function checking, if you want to raw pre-hook a secure function.

The handler function would look something like this:

```lua
-- for direct function hooks
function MyAddon:APIFunctionName(...)
  -- call the original function through the self.hooks table
  self.hooks["APIFunctionName"](...)
end

-- for object hooks
function MyAddon:TargetMethod(object, ...)
  -- call the original function through the self.hooks table
  self.hooks[object]["TargetMethod"](object, ...)
end
```

You can also decide which value to return, either by directly returning the result of the original function, or returning your own value.

#### Secure hooking

Secure post-hooking also has a similar syntax to regular hooking; just remember that your handler function is being called after the hooked function has run, and anything you return will be ignored.

```lua
MyAddon:SecureHook("APISecureFunctionName")
```

### Hooking scripts

Hooking frame scripts is quite similar to hooking functions, but instead of calling `Hook()` or its variants and specifying the function to hook, you call `HookScript()` its variants and specify the frame and the script:

```lua
MyAddon:HookScript(TargetFrame, "ScriptName")
```

As with non-script hooks, the default handler is a method of your addon object with the same name as the hooked script.

Raw and secure version of script hooking are also available:

```lua
MyAddon:RawHookScript(TargetFrame, "ScriptName")
MyAddon:SecureHookScript(TargetFrame, "ScriptName")
```

### Checking to see if something is already hooked

The `IsHooked()` method allows you to check if a function is already hooked. As with `Hook()`, you can specify either a function reference or an object and method name pair. It returns two values, the first a simple boolean for whether AceHook has a hook in place, and the second a reference to the handler specified for that hook (if it exists - nil if not).

```lua
hookexists, hookhandler = MyAddon:IsHooked("APIFunctionName")
```

## Using AceLocale-3.0

### Registering translations

Setting up a given locale's translations is quite simple with AceLocale. To begin with, create a new Lua file for the locale - it's recommended that this include the locale name for ease of reference, but it's not a requirement.

You'll need to add this new file to your addon's TOC file, and make sure it comes before your main code files - otherwise, it might not be loaded before your code is trying to use it!

At the beginning of the new file, fetch a new locale set from AceLocale:

```lua
local L = LibStub("AceLocale-3.0"):NewLocale("MyAddon", "enUS", true)
```

The first argument to `NewLocale` is the name of your addon (must be consistent across all locales, so that AceLocale can associate them with your addon). The second is the locale identifier (common ones are enUS, deDE, frFR, koKR, ruRU, zhCN, and zhTW - the european english client is enGB, but AceLocale automatically loads the enUS entries for enGB). The final argument is a boolean value specifying whether the locale you're defining should be the default locale. For most addons, this will probably be `true` for enUS and `false` for every other locale.

After you've fetched the locale object, it's just a matter of setting up the table of translations:

```lua
if L then

L["identifier"] = "Translation for that identifier"
L["something"] = "Translation for something"

end
```

The `if` block is present because AceLocale will return a `nil` object if you've already defined the locale you requested an object for - this prevents problems if you accidentally try to define translations for a given locale twice.

### Using translations

In your main code file (Core.lua or whatever you've named it), ask AceLocale to give you the proper translation object:

```lua
local L = LibStub("AceLocale-3.0"):GetLocale("MyAddon", true)
```

The first argument is the same addon name that you specified in your locale file(s). The second is a boolean value specifying whether AceLocale should fail silently if locale information is found or not. `true` means no error message will be displayed if locale info cannot be loaded.

After you've acquired the translation object, it's just a matter of substituting it in wherever you previously would have used the pre-localization string:

```lua
function MyAddon:MyFunction()
    self:Print(L["identifier"])
    if userinput == L["something"] then
        doSomething()
    end
end
```

### Mixed-in variables

If you want to use text elements mixed with variables for different output you can also use functions in your locale table. So the word or text element order does not matter in your script and translations will sound more natural.

```lua
-- enUS/enGB:
L['Added X DKP to player Y.'] = function(X,Y)
  return 'Added ' .. X .. ' DKP for player ' .. Y .. '.';
end

-- deDE:
L['Added X DKP to player Y.'] = function(X,Y)
  return X .. ' DKP f\195\188r Spieler ' .. Y .. ' hinzugef\195\188gt.';
end

-- script.lua:
self:Print(L['Added X DKP to player Y.'](dkp_value, playername));
```

## Using AceSerializer-3.0

### Including AceSerializer functionality

As with the other Ace3 modules, AceSerializer-3.0 can be used as a mixin or as a separate object.

```lua
MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceSerializer-3.0")
```

### Serializing data for output

To obtain a serialized string representation of your data, just call the `Serialize()` method with all of the values you want to serialize:

```lua
MyVal1 = 23
MyVal2 = "some text"
MyVal3 = {"foo", 42, "bar"}

serializedData = MyAddon:Serialize(MyVal1, MyVal2, MyVal3)
```

### Loading data from a serialized string

To get the data that was serialized into a string back, call the `Deserialize()` method and pass it the serialized data string. It will return multiple values: the first is always a boolean indicating success (`true`) or failure (`false`). If successful, the rest of the returned values will be the original serialized data items in the same order in which they were passed to `Serialize()`. If unsuccessful, the 2nd (and only other) value returned will be a message indicating the reason for failure.

```lua
success, MyVal1, MyVal2, MyVal3 = MyAddon:Deserialize(serializedData)
if not success then
  -- handle error
end
```