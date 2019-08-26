# SAMP.Lua
SAMP.Lua is a lua library for MoonLoader that adds some features to make SA:MP modding simpler.

Currently this library is work in progress. At this moment the only implemented module is SAMP.Events.

## SAMP.Events
Gives ability to handle SA:MP incoming and outcoming low-level network packets by very easy way.

### Usage
```lua
local sampev = require 'samp.events'

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
function sampev.onSetPlayerPos(position)
  -- prevent server from changing player's position
  return false
end
```
##### Adding your own packet handler
```lua
local sampev = require 'samp.events'
local raknet = require 'samp.raknet'
sampev.INTERFACE.INCOMING_RPCS[raknet.RPC.PLAYSOUND] = {'onPlaySound', {soundId = 'int32'}, {coordinates = 'vector3d'}}

function sampev.onPlaySound(sound, coords)
  -- add log message
  print(string.format('Sound %d at coords %0.2f, %0.2f, %0.2f', sound, coords.x, coords.y, coords.z))
  -- and mute sound
  return false
end
```
The same way you can add your own types for more complex packet structures. See source code for more information and examples.

## Installation
Copy the entire folder `samp` into the `moonloader/lib/` directory.

## Links
MoonLoader: http://blast.hk/moonloader/  
Official thread at BlastHack: http://blast.hk/threads/14624/

## Credits
[FYP](https://github.com/THE-FYP), [MISTER_GONWIK](https://github.com/MISTERGONWIK) and contributors.
