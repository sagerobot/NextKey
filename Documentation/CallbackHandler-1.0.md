# CallbackHandler-1.0

CallbackHandler is a back-end utility library that makes it easy for a library to fire its events to interested parties. It removes the need for addons to be aware of e.g. AceEvent.

The one remaining use for AceEvent Messages is messages that do not have a fixed source - ones that multiple libraries or addons can fire.

## Including CallbackHandler-1.0 into your project

### Are you a Library?

**if using the WoWAce repositories**

- setup an external pointing to `svn://svn.wowace.com/wow/callbackhandler/mainline/trunk/CallbackHandler-1.0` in the `.pkgmeta` file
- disable nolib creation by adding `enable-nolib-creation: no` to the `.pkgmeta` file
- set up your `<library>.toc` file to load `CallbackHandler-1.0.xml` (in case you support stand alone loading of the lib)
- don't load `CallbackHandler-1.0` via the `.xml` file ment for embedded loading of your lib
- don't set `CallbackHandler-1.0` as `X-embeded` or `OptDep`

**otherwise**

- get a copy of the current version
- copy `CallbackHandler-1.0.lua` into your library's folder
- set up your `<library>.toc` file to load `CallbackHandler-1.0.lua` (in case you support stand alone loading of the lib)
- don't load `CallbackHandler-1.0` via the `.xml` file meant for embedded loading of your lib
- don't set `CallbackHandler-1.0` as `X-embeded` or `OptDep`

### Are you an AddOn?

**if using the WoWAce repositories**

- set up an external pointing to `svn://svn.wowace.com/wow/callbackhandler/mainline/trunk/CallbackHandler-1.0` in the `.pkgmeta` file
- set up your `<addon>.toc` or `embeds.xml` file to load `CallbackHandler-1.0.xml`
- don't set `CallbackHandler-1.0` as `X-embeded` or `OptDep`

**otherwise**

- get a copy of the current version
- copy `CallbackHandler-1.0.lua` into your addon's folder or a subfolder of it
- set up your `<addon>.toc` or `embeds.xml` file to load `CallbackHandler-1.0.lua`
- don't set `CallbackHandler-1.0` as `X-embeded` or `OptDep`

## Mixing in the CallbackHandler functions in your library or AddOn

```lua
MyLib.callbacks = MyLib.callbacks or 
    LibStub("CallbackHandler-1.0"):New(MyLib)
```

This adds 3 methods to your library:

- `MyLib.RegisterCallback(self, "eventName"[, method, [arg]])`
- `MyLib.UnregisterCallback(self, "eventname")`
- `MyLib.UnregisterAllCallbacks(self)`

Make sure that the passed in `self` is your addon, and not the library itself, so the double-colon syntax will not work.

The `MyLib.callbacks` object is the callback registry itself, which you need to keep track of across in-game upgrades of your own library. (You do make sure that your library upgrades gracefully, right? ;-) )

## Firing events

Assuming your callback registry is `MyLib.callbacks`, firing named events is as easy as:

```lua
MyLib.callbacks:Fire("EventName", arg1, arg2, ...)
```

All arguments supplied to `:Fire()` are passed to the functions listening to the event.

## Advanced uses

### Renaming the methods

You can specify your own names for the methods installed by CallbackHandler:

```lua
MyLib.callbacks= MyLib.callbacks or 
    LibStub("CallbackHandler-1.0"):New(MyLib, 
        "MyRegisterFunc", 
        "MyUnregisterFunc", 
        "MyUnregisterAllFunc" or false
    )
```

Giving `false` as the name for "UnregisterAll" means that you do not want to give users access to that API at all - it will not be installed.

### Tracking events being used

In some cases, it makes sense to know which events are being requested by your users. Perhaps to enable/disable code needed to track them.

CallbackHandler will always call `callbacks:OnUsed()` and `:OnUnused()` when an event starts/stops being used:

```lua
function MyLib.callbacks:OnUsed(target, eventname)
    -- "target" is == MyLib here
    print("Someone just registered for "..eventname.."!")
end

function MyLib.callbacks:OnUnused(target, eventname)
    print("Noone wants "..eventname.." any more")
end
```

`OnUsed` is only called if the event was previously unused. `OnUnused` is only called when the last user unregisters from an event. In other words, you won't see an `OnUnused` unless `OnUsed` has been called for an event. And you won't ever see two `OnUsed` in a row without `OnUnused` in between for an event.

### Multiple event registries

As you may or may not know, CallbackHandler is the workhorse of AceEvent-3.0. It is used twice in AceEvent: once for in-game events, which cannot be fired by users, and once for "messages", which can be fired by users.

Providing multiple registries in AceEvent was as easy as:

```lua
AceEvent.events = AceEvent.events or 
    LibStub("CallbackHandler-1.0"):New(AceEvent, 
        "RegisterEvent", "UnregisterEvent", "UnregisterAllEvents"
    )

AceEvent.messages = AceEvent.messages or 
    LibStub("CallbackHandler-1.0"):New(AceEvent, 
        "RegisterMessage", "UnregisterMessage", "UnregisterAllMessages"
    )

AceEvent.SendMessage = AceEvent.messages.Fire
```

Of course, there is also some code in AceEvent to do the actual driving of in-game events (using `OnUsed` and `OnUnused`), but this is really the core of it.