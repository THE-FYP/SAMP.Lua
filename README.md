# SAMP.Lua
SAMP.Lua is a lua library for MoonLoader that adds some features to make SA:MP modding simpler.

Currently this library is work in progress. At this moment the only implemented module is SAMP.Events.

## SAMP.Events
Gives ability to handle SA:MP incoming and outcoming low-level network packets by very easy way.

### Usage
```lua
local sampev = 'lib.samp.events'

-- intercept outgoing chat messages
function sampev.onSendChat(msg)
  print('You said: ' .. msg)
end
```
You can rewrite data. Just return all arguments in the right order within a table.
```lua
function sampev.onSendChat(msg)
  return {'I said: ' .. msg}
end
```
You can also interrupt processing any packets by returning `false`.
```lua
function sampev.onSetPlayerPos(x, y, z)
  -- prevent server from changing player's position
  return false
end
```
##### Adding your own packet handler
```lua
local sampev = 'lib.samp.events'
local raknet = 'lib.samp.raknet'
sampev.INTERFACE.INCOMING_RPCS[raknet.RPC.PLAYSOUND] = {'onPlaySound', {soundId = 'int32'}, {x = 'float'}, {y = 'float'}, {z = 'float'}}

function sampev.onPlaySound(sound, x, y, z)
  -- add log message
  print(string.format('Sound %d at coords %0.2f, %0.2f, %0.2f', sound, x, y, z))
  -- and mute sound
  return false
end
```
The same way you can add your own types for more complex packet structures. See `events.lua` and `events_core.lua` for more information and examples.

## Installation
Copy the entire folder `samp` into the `moonloader/lib/` directory.

## Links
MoonLoader: http://blast.hk/moonloader/  
Official thread at BlastHack: http://blast.hk/threads/14624/
