-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua


local events            = require 'lib.samp.events.core'
local raknet            = require 'lib.samp.raknet'
local utils             = require 'lib.samp.events.utils'
local RPC               = raknet.RPC
local PACKET            = raknet.PACKET
local OUTCOMING_RPCS    = events.INTERFACE.OUTCOMING_RPCS
local OUTCOMING_PACKETS = events.INTERFACE.OUTCOMING_PACKETS
local INCOMING_RPCS     = events.INTERFACE.INCOMING_RPCS
local INCOMING_PACKETS  = events.INTERFACE.INCOMING_PACKETS
local BitStreamIO       = events.INTERFACE.BitStreamIO


--- Сustom handlers
local function empty_writer() end

local function process_send_give_take_damage_reader(bs, take)
	local read = events.EXPORTS.bitStreamRead
	if read(bs, 'bool') ~= take then -- 'true' is take damage
		return false
	end
	local data = {
		read(bs, 'int16'), -- playerId
		read(bs, 'float'), -- damage
		read(bs, 'int32'), -- weapon
		read(bs, 'int32'), -- bodypart
	}
	return data
end

local function process_send_give_take_damage_writer(bs, data, take)
	local write = events.EXPORTS.bitStreamWrite
	write(bs, 'bool',  take) -- give or take
	write(bs, 'int16', data[1]) -- playerId
	write(bs, 'float', data[2]) -- damage
	write(bs, 'int32', data[3]) -- weapon
	write(bs, 'int32', data[4]) -- bodypart
end

local function on_init_game_reader(bs)
	local read                     = events.EXPORTS.bitStreamRead
	local settings                 = {}
	settings.zoneNames             = read(bs, 'bool')
	settings.useCJWalk             = read(bs, 'bool')
	settings.allowWeapons          = read(bs, 'bool')
	settings.limitGlobalChatRadius = read(bs, 'bool')
	settings.globalChatRadius      = read(bs, 'float')
	settings.stuntBonus            = read(bs, 'bool')
	settings.nametagDrawDist       = read(bs, 'float')
	settings.disableEnterExits     = read(bs, 'bool')
	settings.nametagLOS            = read(bs, 'bool')
	settings.tirePopping           = read(bs, 'bool')
	settings.classesAvailable      = read(bs, 'int32')
	local playerId                 = read(bs, 'int16')
	settings.showPlayerTags        = read(bs, 'bool')
	settings.playerMarkersMode     = read(bs, 'int32')
	settings.worldTime             = read(bs, 'int8')
	settings.worldWeather          = read(bs, 'int8')
	settings.gravity               = read(bs, 'float')
	settings.lanMode               = read(bs, 'bool')
	settings.deathMoneyDrop        = read(bs, 'int32')
	settings.instagib              = read(bs, 'bool')
	settings.normalOnfootSendrate  = read(bs, 'int32')
	settings.normalIncarSendrate   = read(bs, 'int32')
	settings.normalFiringSendrate  = read(bs, 'int32')
	settings.sendMultiplier        = read(bs, 'int32')
	settings.lagCompMode           = read(bs, 'int32')
	local hostName                 = read(bs, 'string8')
	local vehicleModels = {}
	for i = 0, 212 - 1 do
		vehicleModels[i] = read(bs, 'int8')
	end
	local unknown = read(bs, 'int32')
	return {playerId, hostName, settings, vehicleModels, unknown}
end

local function on_init_game_writer(bs, data)
	local write = events.EXPORTS.bitStreamWrite
	local settings = data[3]
	local vehicleModels = data[4]
	write(bs, 'bool', settings.zoneNames)
	write(bs, 'bool', settings.useCJWalk)
	write(bs, 'bool', settings.allowWeapons)
	write(bs, 'bool', settings.limitGlobalChatRadius)
	write(bs, 'float', settings.globalChatRadius)
	write(bs, 'bool', settings.stuntBonus)
	write(bs, 'float', settings.nametagDrawDist)
	write(bs, 'bool', settings.disableEnterExits)
	write(bs, 'bool', settings.nametagLOS)
	write(bs, 'bool', settings.tirePopping)
	write(bs, 'int32', settings.classesAvailable)
	write(bs, 'int16', data[1]) -- playerId
	write(bs, 'bool', settings.showPlayerTags)
	write(bs, 'int32', settings.playerMarkersMode)
	write(bs, 'int8', settings.worldTime)
	write(bs, 'int8', settings.worldWeather)
	write(bs, 'float', settings.gravity)
	write(bs, 'bool', settings.lanMode)
	write(bs, 'int32', settings.deathMoneyDrop)
	write(bs, 'bool', settings.instagib)
	write(bs, 'int32', settings.normalOnfootSendrate)
	write(bs, 'int32', settings.normalIncarSendrate)
	write(bs, 'int32', settings.normalFiringSendrate)
	write(bs, 'int32', settings.sendMultiplier)
	write(bs, 'int32', settings.lagCompMode)
	write(bs, 'string8', data[2]) -- hostName
	for i = 0, 212 - 1 do
		write(bs, 'int8', vehicleModels[i])
	end
	write(bs, 'int32', data[5]) -- unknown
end

local function on_init_menu_reader(bs)
	local read = events.EXPORTS.bitStreamRead
	local MAX_MENU_ITEMS = 12
	local MAX_MENU_LINE = 32
	local MAX_MENU_COLUMNS = 2

	local menuId       = read(bs, 'int8')
	local twoColumns   = read(bs, 'bool32')
	local menuTitle    = read(bs, 'string256')
	local x            = read(bs, 'float')
	local y            = read(bs, 'float')
	local colWidth1    = read(bs, 'float')
	local colWidth2
	if twoColumns then colWidth2 = read(bs, 'float') end
	local menu         = read(bs, 'bool32')
	local rows         = {}
	for i = 1, 12 do rows[i] = read(bs, 'int32') end

	local readColumn = function(width)
		local id = #columns + 1
		local title = read(bs, 'string256')
		local rowCount = read(bs, 'int8')
		local column = {title = title, width = width, text = {}}
		for i = 1, rowCount do
			local text = read(bs, 'string256')
			columns[id].text[i] = text
		end
		return column
	end

	local columns = {}
	columns[1] = readColumn(colWidth1)
	if twoColumns then columns[2] = readColumn(colWidth2) end

	return {menuId, menuTitle, x, y, twoColumns, columns, rows, menu}
end

local function on_init_menu_writer(bs, data)
	local write = events.EXPORTS.bitStreamWrite
	local columns = data[6]
	write(bs, 'int8', data[1])      -- menuId
	write(bs, 'bool32', data[5])    -- twoColumns
	write(bs, 'string256', data[2]) -- title
	write(bs, 'float', data[3])     -- x
	write(bs, 'float', data[4])     -- y
	-- columns width
	write(bs, 'float', columns[1].width)
	if data[5] then write(bs, 'float', columns[2].width) end
	write(bs, 'bool32', data[8]) -- menu
	 -- rows
	for i = 1, 12 do write(bs, 'int32', data[7][i]) end
	-- columns
	for i = 1, (data[5] and 2 or 1) do
		write(bs, 'string256', columns[i].title)
		write(bs, 'int8', #columns[i].text)
		for r, t in ipairs(columns[i].text) do
			write(bs, 'string256', t)
		end
	end
end

local function process_outcoming_sync_data(bs, structName)
	local data = raknetBitStreamGetDataPtr(bs) + 1
	local ffi = require 'ffi'
	require 'lib.samp.synchronization'
	return {ffi.cast('struct ' .. structName .. '*', data)}
end

local function on_markers_sync_reader(bs)
	local markers = {}
	local players = raknetBitStreamReadInt32(bs)
	for i = 1, players do
		local playerId = raknetBitStreamReadInt16(bs)
		local active = raknetBitStreamReadBool(bs)
		if active then
			table.insert(markers, {playerId = playerId, active = true,
				x = raknetBitStreamReadInt16(bs), y = raknetBitStreamReadInt16(bs), z = raknetBitStreamReadInt16(bs)})
		else
			table.insert(markers, {playerId = playerId, active = false})
		end
	end
	return {markers}
end

local function on_markers_sync_writer(bs, data)
	raknetBitStreamWriteInt32(bs, #data)
	for i = 1, #data do
		local it = data[i]
		raknetBitStreamWriteInt16(bs, it.playerId)
		raknetBitStreamWriteBool(bs, it.active)
		if it.active then
			raknetBitStreamWriteInt16(bs, it.x)
			raknetBitStreamWriteInt16(bs, it.y)
			raknetBitStreamWriteInt16(bs, it.z)
		end
	end
end

local function on_player_sync_reader(bs)
	local has_value = raknetBitStreamReadBool
	local read = events.EXPORTS.bitStreamRead
	local data = {}

	local playerId = raknetBitStreamReadInt16(bs)
	if has_value(bs) then data.leftRightKeys = raknetBitStreamReadInt16(bs) end
	if has_value(bs) then data.upDownKeys = raknetBitStreamReadInt16(bs) end
	data.keysData = raknetBitStreamReadInt16(bs)
	data.position = {x = raknetBitStreamReadFloat(bs), y = raknetBitStreamReadFloat(bs), z = raknetBitStreamReadFloat(bs)}
	data.quaternion = read(bs, 'normQuat')
	data.health, data.armor = utils.decompress_health_and_armor(raknetBitStreamReadInt8(bs))
	data.weapon = raknetBitStreamReadInt8(bs)
	data.specialAction = raknetBitStreamReadInt8(bs)
	local movespeed = read(bs, 'compressedVector')
	data.moveSpeed = {x = movespeed[1], y = movespeed[2], z = movespeed[3]}
	if has_value(bs) then
		data.surfingVehicleId = raknetBitStreamReadInt16(bs)
		data.surfingOffsets = {x = raknetBitStreamReadFloat(bs), y = raknetBitStreamReadFloat(bs), z = raknetBitStreamReadFloat(bs)}
	end
	if has_value(bs) then
		data.animationId = raknetBitStreamReadInt16(bs)
		data.animationFlags = raknetBitStreamReadInt16(bs)
	end

	return {playerId, data}
end

local function on_player_sync_writer(bs, data)
	local write = events.EXPORTS.bitStreamWrite
	local playerId = data[1]
	local data = data[2]

	raknetBitStreamWriteInt16(bs, playerId)
	raknetBitStreamWriteBool(bs, data.leftRightKeys ~= nil)
	if data.leftRightKeys then raknetBitStreamWriteInt16(bs, data.leftRightKeys) end
	raknetBitStreamWriteBool(bs, data.upDownKeys ~= nil)
	if data.upDownKeys then raknetBitStreamWriteInt16(bs, data.upDownKeys) end
	raknetBitStreamWriteInt16(bs, data.keysData)
	raknetBitStreamWriteFloat(bs, data.position.x)
	raknetBitStreamWriteFloat(bs, data.position.y)
	raknetBitStreamWriteFloat(bs, data.position.z)
	write(bs, 'normQuat', data.quaternion)
	raknetBitStreamWriteInt8(bs, utils.compress_health_and_armor(data.health, data.armor))
	raknetBitStreamWriteInt8(bs, data.weapon)
	raknetBitStreamWriteInt8(bs, data.specialAction)
	write(bs, 'compressedVector', {data.moveSpeed.x, data.moveSpeed.y, data.moveSpeed.z})
	raknetBitStreamWriteBool(bs, data.surfingVehicleId ~= nil)
	if data.surfingVehicleId then
		raknetBitStreamWriteInt16(bs, data.surfingVehicleId)
		raknetBitStreamWriteFloat(bs, data.surfingOffsets.x)
		raknetBitStreamWriteFloat(bs, data.surfingOffsets.y)
		raknetBitStreamWriteFloat(bs, data.surfingOffsets.z)
	end
	raknetBitStreamWriteBool(bs, data.animationId ~= nil)
	if data.animationId then
		raknetBitStreamWriteInt16(bs, data.animationId)
		raknetBitStreamWriteInt16(bs, data.animationFlags)
	end
end

local function on_vehicle_sync_reader(bs)
	local read = events.EXPORTS.bitStreamRead
	local data = {}

	local playerId = raknetBitStreamReadInt16(bs)
	local vehicleId = raknetBitStreamReadInt16(bs)
	data.leftRightKeys = raknetBitStreamReadInt16(bs)
	data.upDownKeys = raknetBitStreamReadInt16(bs)
	data.keysData = raknetBitStreamReadInt16(bs)
	data.quaternion = read(bs, 'normQuat')
	data.position = {x = raknetBitStreamReadFloat(bs), y = raknetBitStreamReadFloat(bs), z = raknetBitStreamReadFloat(bs)}
	local movespeed = read(bs, 'compressedVector')
	data.moveSpeed = {x = movespeed[1], y = movespeed[2], z = movespeed[3]}
	data.vehicleHealth = raknetBitStreamReadInt16(bs)
	data.playerHealth, data.armor = utils.decompress_health_and_armor(raknetBitStreamReadInt8(bs))
	data.currentWeapon = raknetBitStreamReadInt8(bs)
	data.siren = raknetBitStreamReadBool(bs)
	data.landingGear = raknetBitStreamReadBool(bs)
	if raknetBitStreamReadBool(bs) then
		data.trainSpeed = raknetBitStreamReadInt32(bs)
	end
	if raknetBitStreamReadBool(bs) then
		data.trailerId = raknetBitStreamReadInt16(bs)
	end

	return {playerId, vehicleId, data}
end

local function on_vehicle_sync_writer(bs, data)
	local write = events.EXPORTS.bitStreamWrite
	local playerId = data[1]
	local vehicleId = data[2]
	local data = data[3]

	raknetBitStreamWriteInt16(bs, playerId)
	raknetBitStreamWriteInt16(bs, vehicleId)
	raknetBitStreamWriteInt16(bs, data.leftRightKeys)
	raknetBitStreamWriteInt16(bs, data.upDownKeys)
	raknetBitStreamWriteInt16(bs, data.keysData)
	write(bs, 'normQuat', data.quaternion)
	raknetBitStreamWriteFloat(bs, data.position.x)
	raknetBitStreamWriteFloat(bs, data.position.y)
	raknetBitStreamWriteFloat(bs, data.position.z)
	write(bs, 'compressedVector', {data.moveSpeed.x, data.moveSpeed.y, data.moveSpeed.z})
	raknetBitStreamWriteInt16(bs, data.vehicleHealth)
	raknetBitStreamWriteInt8(bs, utils.compress_health_and_armor(data.playerHealth, data.armor))
	raknetBitStreamWriteInt8(bs, data.currentWeapon)
	raknetBitStreamWriteBool(bs, data.siren)
	raknetBitStreamWriteBool(bs, data.landingGear)

	raknetBitStreamWriteBool(bs, data.trainSpeed ~= nil)
	if data.trainSpeed ~= nil then
		raknetBitStreamWriteInt32(bs, data.trainSpeed)
	end
	raknetBitStreamWriteBool(bs, data.trailerId ~= nil)
	if data.trailerId ~= nil then
		raknetBitStreamWriteInt16(bs, data.trailerId)
	end
end


--- Events
-- Outgoing rpcs
OUTCOMING_RPCS[RPC.ENTERVEHICLE]         = {'onSendEnterVehicle', {vehicleId = 'int16'}, {passenger = 'bool8'}}
OUTCOMING_RPCS[RPC.CLICKPLAYER]          = {'onSendClickPlayer', {playerId = 'int16'}, {source = 'int8'}}
OUTCOMING_RPCS[RPC.CLIENTJOIN]           = {'onSendClientJoin', {version = 'int32'}, {mod = 'int8'}, {nickname = 'string8'}, {joinAuthKey = 'string8'}, {clientVer = 'string8'}}
OUTCOMING_RPCS[RPC.ENTEREDITOBJECT]      = {'onSendEnterEditObject'} -- TODO: find out
OUTCOMING_RPCS[RPC.SERVERCOMMAND]        = {'onSendCommand', {command = 'string32'}}
OUTCOMING_RPCS[RPC.SPAWN]                = {'onSendSpawn'}
OUTCOMING_RPCS[RPC.DEATH]                = {'onSendDeathNotification', {reason = 'int8'}, {killerId = 'int16'}}
OUTCOMING_RPCS[RPC.DIALOGRESPONSE]       = {'onSendDialogResponse', {dialogId = 'int16'}, {button = 'int8'}, {listboxId = 'int16'}, {input = 'string8'}}
OUTCOMING_RPCS[RPC.CLICKTEXTDRAW]        = {'onSendClickTextDraw', {textdrawId = 'int16'}}
OUTCOMING_RPCS[RPC.SCMEVENT]             = {'onSendVehicleTuningNotification', {event = 'int32'}, {vehicleId = 'int32'}, {param1 = 'int32'}, {param2 = 'int32'}}
OUTCOMING_RPCS[RPC.CHAT]                 = {'onSendChat', {message = 'string8'}}
OUTCOMING_RPCS[RPC.CLIENTCHECK]          = {'onSendClientCheckResponse', {'int8'}, {'int32'}, {'int8'}}
OUTCOMING_RPCS[RPC.DAMAGEVEHICLE]        = {'onSendVehicleDamaged', {vehicleId = 'int16'}, {panelDmg = 'int32'}, {doorDmg = 'int32'}, {lights = 'int8'}, {tires = 'int8'}}
OUTCOMING_RPCS[RPC.EDITATTACHEDOBJECT]   = {'onSendEditAttachedObject', {response = 'int32'}, {index = 'int32'}, {model = 'int32'}, {bone = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}, {rotX = 'float'}, {rotY = 'float'}, {rotZ = 'float'}, {scaleX = 'float'}, {scaleY = 'float'}, {scaleZ = 'float'}, {color1 = 'int32'}, {color2 = 'int32'}}
OUTCOMING_RPCS[RPC.EDITOBJECT]           = {'onSendEditObject', {playerObject = 'bool'}, {objectId = 'int16'}, {response = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}, {rotX = 'float'}, {rotY = 'float'}, {rotZ = 'float'}}
OUTCOMING_RPCS[RPC.SETINTERIORID]        = {'onSendInteriorChangeNotification', {interior = 'int8'}}
OUTCOMING_RPCS[RPC.MAPMARKER]            = {'onSendMapMarker', {x = 'float'}, {y = 'float'}, {z = 'float'}}
OUTCOMING_RPCS[RPC.REQUESTCLASS]         = {'onSendRequestClass', {classId = 'int32'}}
OUTCOMING_RPCS[RPC.REQUESTSPAWN]         = {'onSendRequestSpawn'}
OUTCOMING_RPCS[RPC.PICKEDUPPICKUP]       = {'onSendPickedUpPickup', {pickupId = 'int32'}}
OUTCOMING_RPCS[RPC.MENUSELECT]           = {'onSendMenuSelect', {row = 'int8'}}
OUTCOMING_RPCS[RPC.VEHICLEDESTROYED]     = {'onSendVehicleDestroyed', {vehicleId = 'int16'}}
OUTCOMING_RPCS[RPC.MENUQUIT]             = {'onSendQuitMenu'}
OUTCOMING_RPCS[RPC.EXITVEHICLE]          = {'onSendExitVehicle', {vehicleId = 'int16'}}
OUTCOMING_RPCS[RPC.UPDATESCORESPINGSIPS] = {'onSendUpdateScoresAndPings'}
OUTCOMING_RPCS[RPC.GIVETAKEDAMAGE]       = {
	{'onSendGiveDamage', -- int playerId, float damage, int weapon, int bodypart
	function(bs) return process_send_give_take_damage_reader(bs, false) end,
	function(bs, data) return process_send_give_take_damage_writer(bs, data, false) end},
	{'onSendTakeDamage', -- int playerId, float damage, int weapon, int bodypart
	function(bs) return process_send_give_take_damage_reader(bs, true) end,
	function(bs, data) return process_send_give_take_damage_writer(bs, data, true) end}
}

-- Incoming rpcs
-- int playerId, string hostName, table settings, table vehicleModels, int unknown
INCOMING_RPCS[RPC.INITGAME]                 = {'onInitGame', onInitGameReader, onInitGameWriter}
INCOMING_RPCS[RPC.SERVERJOIN]               = {'onPlayerJoin', {playerId = 'int16'}, {color = 'int32'}, {isNpc = 'bool8'}, {nickname = 'string8'}}
INCOMING_RPCS[RPC.SERVERQUIT]               = {'onPlayerQuit', {playerId = 'int16'}, {reason = 'int8'}}
INCOMING_RPCS[RPC.REQUESTCLASS]             = {'onRequestClassResponse', {canSpawn = 'bool8'}, {team = 'int8'}, {skin = 'int32'}, {unk = 'int8'}, {x = 'float'}, {y = 'float'}, {z = 'float'}, {rotation = 'float'}, {weapons = 'Int32Array3'}, {ammo = 'Int32Array3'}}
INCOMING_RPCS[RPC.REQUESTSPAWN]             = {'onRequestSpawnResponse', {response = 'bool8'}}
INCOMING_RPCS[RPC.SETPLAYERNAME] = {'onSetPlayerName', {name = 'string8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERPOS]             = {'onSetPlayerPos', {x = 'float'}, {y = 'float'}, {z = 'float'}}
INCOMING_RPCS[RPC.SETPLAYERPOSFINDZ] = {'onSetPlayerPosFindZ', {x = 'float'}, {y = 'float'}, {z = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERHEALTH]          = {'onSetPlayerHealth', {health = 'float'}}
INCOMING_RPCS[RPC.TOGGLEPLAYERCONTROLLABLE] = {'onTogglePlayerControllable', {controllable = 'bool8'}}
INCOMING_RPCS[RPC.PLAYSOUND] = {'onPlaySound', {soundId = 'int32'}, {x = 'float'}, {y = 'float'}, {z = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERWORLDBOUNDS] = {'onSetWorldBounds', {x1 = 'float'}, {y1 = 'float'}, {x2 = 'float'}, {y2 = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.GIVEPLAYERMONEY]          = {'onGivePlayerMoney', {money = 'int32'}}
INCOMING_RPCS[RPC.SETPLAYERFACINGANGLE] = {'onSetPlayerFacingAngle', {angle = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.RESETPLAYERMONEY]         = {'onResetPlayerMoney'}
INCOMING_RPCS[RPC.RESETPLAYERWEAPONS]       = {'onResetPlayerWeapons'}
INCOMING_RPCS[RPC.GIVEPLAYERWEAPON] = {'onGivePlayerWeapon', {weaponId = 'int32'}, {ammo = 'int32'}} -- TODO: test
-- INCOMING_RPCS[RPC.SETVEHICLEPARAMSEX] = {''} -- TODO: test
INCOMING_RPCS[RPC.CANCELEDIT] = {'onCancelEdit'} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERTIME] = {'onSetWorldTime', {hour = 'int8'}, {minute = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.TOGGLECLOCK] = {'onSetToggleClock', {state = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.WORLDPLAYERADD]           = {'onPlayerStreamIn', {playerId = 'int16'}, {team = 'int8'}, {model = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}, {rotation = 'float'}, {color = 'int32'}, {fightingStyle = 'int8'}}
INCOMING_RPCS[RPC.SETPLAYERSHOPNAME] = {'onSetShopName', {text = 'string8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERSKILLLEVEL] = {'onSetPlayerSkillLevel', {playerId = 'int16'}, {skill = 'int32'}, {level = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERDRUNKLEVEL] = {'onSetPlayerDrunk', {drunkLevel = 'int32'}} -- TODO: test
INCOMING_RPCS[RPC.CREATE3DTEXTLABEL]        = {'onCreate3DText', {id = 'int16'}, {color = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}, {distance = 'float'}, {testLOS = 'bool8'}, {attachedPlayerId = 'int16'}, {attachedVehicleId = 'int16'}, {text = 'encodedString4096'}}
INCOMING_RPCS[RPC.DISABLECHECKPOINT] = {'onDisableCheckpoint'} -- TODO: test
INCOMING_RPCS[RPC.SETRACECHECKPOINT] = {'onSetRaceCheckpoint', {type = 'int8'}, {x = 'float'}, {y = 'float'}, {z = 'float'}, {nextX = 'float'}, {nextY = 'float'}, {nextZ = 'float'}, {size = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.DISABLERACECHECKPOINT] = {'onDisableRaceCheckpoint'} -- TODO: test
INCOMING_RPCS[RPC.GAMEMODERESTART] = {'onGamemodeRestart'} -- TODO: test
INCOMING_RPCS[RPC.PLAYAUDIOSTREAM] = {'onPlayAudioStream', {url = 'string8'}, {position = 'vector3d'}, {radius = 'float'}, {usePosition = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.STOPAUDIOSTREAM] = {'onStopAudioStream'} -- TODO: test
INCOMING_RPCS[RPC.REMOVEBUILDINGFORPLAYER] = {'onRemoveBuilding', {modelId = 'int32'}, {position = 'vector3d'}, {radius = 'float'}} -- TODO: test
-- INCOMING_RPCS[RPC.CREATEOBJECT] = {''} -- TODO: test
INCOMING_RPCS[RPC.SETOBJECTPOS] = {'onSetObjectPosition', {objectId = 'int16'}, {position = 'vector3d'}} -- TODO: test
INCOMING_RPCS[RPC.SETOBJECTROT] = {'onSetObjectRotation', {objectId = 'int16'}, {rotation = 'vector3d'}} -- TODO: test
INCOMING_RPCS[RPC.DESTROYOBJECT] = {'onDestroyObject', {objectId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.DEATHMESSAGE] = {'onPlayerDeathNotification', {killerId = 'int16'}, {killedId = 'int16'}, {reason = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERMAPICON] = {'onSetMapIcon', {iconId = 'int8'}, {position = 'vector3d'}, {type = 'int8'}, {color = 'int32'}, {style = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.REMOVEVEHICLECOMPONENT] = {'onRemoveVehicleComponent', {vehicleId = 'int16'}, {componentId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.UPDATE3DTEXTLABEL] = {'onRemove3DTextLabel', {textLabelId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.CHATBUBBLE]               = {'onPlayerChatBubble', {playerId = 'int16'}, {color = 'int32'}, {distance = 'float'}, {duration = 'int32'}, {message = 'string8'}}
INCOMING_RPCS[RPC.UPDATETIME]               = {'onUpdateGlobalTimer', {time = 'int32'}}
INCOMING_RPCS[RPC.SHOWDIALOG]               = {'onShowDialog', {dialogId = 'int16'}, {style = 'int8'}, {title = 'string8'}, {button1 = 'string8'}, {button2 = 'string8'}, {text = 'encodedString4096'}}
INCOMING_RPCS[RPC.DESTROYPICKUP]            = {'onDestroyPickup', {id = 'int32'}}
INCOMING_RPCS[RPC.LINKVEHICLETOINTERIOR] = {'onLinkVehicleToInterior', {vehicleId = 'int16'}, {interiorId = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERARMOUR] = {'onSetPlayerArmour', {armour = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERARMEDWEAPON] = {'onSetPlayerArmedWeapon', {weaponId = 'int32'}} -- TODO: test
INCOMING_RPCS[RPC.SETSPAWNINFO]             = {'onSetSpawnInfo', {team = 'int8'}, {skin = 'int32'}, {unk = 'int8'}, {x = 'float'}, {y = 'float'}, {z = 'float'}, {rotation = 'float'}, {weapons = 'Int32Array3'}, {ammo = 'Int32Array3'}}
INCOMING_RPCS[RPC.SETPLAYERTEAM] = {'onSetPlayerTeam', {playerId = 'int16'}, {teamId = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.PUTPLAYERINVEHICLE] = {'onPutPlayerInVehicle', {vehicleId = 'int16'}, {seatId = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.REMOVEPLAYERFROMVEHICLE] = {'onRemovePlayerFromVehicle'} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERCOLOR] = {'onSetPlayerColor', {playerId = 'int16'}, {color = 'int32'}} -- TODO: test
INCOMING_RPCS[RPC.DISPLAYGAMETEXT] = {'onDisplayGameText', {style = 'int32'}, {time = 'int32'}, {text = 'string8'}}
INCOMING_RPCS[RPC.FORCECLASSSELECTION] = {'onForceClassSelection'} -- TODO: test - skip
INCOMING_RPCS[RPC.ATTACHOBJECTTOPLAYER] = {'onAttachObjectToPlayer', {objectId = 'int16'}, {playerId = 'int16'}, {offsets = 'vector3d'}, {rotation = 'vector3d'}} -- TODO: test
-- int menuId, string title, float x, float y, bool twoColumns, table columns, table rows, bool menuUnk
INCOMING_RPCS[RPC.INITMENU]                 = {'onInitMenu', onInitGameReader, onInitMenuWriter}
INCOMING_RPCS[RPC.SHOWMENU]                 = {'onShowMenu', {menuId = 'int8'}}
INCOMING_RPCS[RPC.HIDEMENU]                 = {'onHideMenu', {menuId = 'int8'}}
INCOMING_RPCS[RPC.CREATEEXPLOSION] = {'onCreateExplosion', {position = 'vector3d'}, {style = 'int32'}, {radius = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.SHOWPLAYERNAMETAGFORPLAYER] = {'onShowPlayerNameTag', {playerId = 'int16'}, {state = 'int8'}} -- TODO: test
-- INCOMING_RPCS[RPC.ATTACHCAMERATOOBJECT] = {''} -- TODO: test - skip
-- INCOMING_RPCS[RPC.INTERPOLATECAMERA] = {''} -- TODO: test - skip
-- INCOMING_RPCS[RPC.SETOBJECTMATERIAL] = {''} -- TODO: test
INCOMING_RPCS[RPC.GANGZONESTOPFLASH] = {'onGangZoneStopFlash', {zoneId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.APPLYANIMATION]           = {'onApplyPlayerAnimation', {playerId = 'int16'}, {animLib = 'string8'}, {animName = 'string8'}, {loop = 'bool'}, {lockX = 'bool'}, {lockY = 'bool'}, {freeze = 'bool'}, {time = 'int32'}}
INCOMING_RPCS[RPC.CLEARANIMATIONS]          = {'onClearPlayerAnimation', {playerId = 'int16'}}
INCOMING_RPCS[RPC.SETPLAYERSPECIALACTION] = {'onSetPlayerSpecialAction', {actionId = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERFIGHTINGSTYLE] = {'onSetPlayerFightingStyle', {playerId = 'int16'}, {styleId = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERVELOCITY] = {'onSetPlayerVelocity', {velocity = 'vector3d'}} -- TODO: test
INCOMING_RPCS[RPC.SETVEHICLEVELOCITY] = {'onSetVehicleVelocity', {vehicleId = 'int16'}, {velocity = 'vector3d'}} -- TODO: test
INCOMING_RPCS[RPC.CLIENTMESSAGE]            = {'onServerMessage', {color = 'int32'}, {text = 'string32'}}
-- INCOMING_RPCS[RPC.SETWORLDTIME] = {''} -- TODO: test - skip
INCOMING_RPCS[RPC.CREATEPICKUP]             = {'onCreatePickup', {id = 'int32'}, {model = 'int32'}, {pickupType = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}}
-- INCOMING_RPCS[RPC.MOVEOBJECT] = {''} -- TODO: test - skip
INCOMING_RPCS[RPC.ENABLESTUNTBONUSFORPLAYER] = {'onEnableStuntBonus', {state = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.TEXTDRAWSETSTRING] = {'onTextDrawSetString', {id = 'int16'}, {textLength = 'int16'}, {text = 'string32'}} -- TODO: test
INCOMING_RPCS[RPC.SETCHECKPOINT] = {'onSetCheckpoint', {position = 'vector3d'}, {radius = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.GANGZONECREATE] = {'onCreateGangZone', {zoneId = 'int16'}, {squareStart = 'vector2d'}, {squareEnd = 'vector2d'}, {color = 'int32'}} -- TODO: test
INCOMING_RPCS[RPC.PLAYCRIMEREPORT] = {'onPlayCrimeReport', {suspectId = 'int16'}, {crimeId = 'int8'}} -- TODO: test
-- INCOMING_RPCS[RPC.SETPLAYERATTACHEDOBJECT] = {''} -- TODO: test - skip
INCOMING_RPCS[RPC.GANGZONEDESTROY] = {'onGangZoneDestroy', {zoneId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.GANGZONEFLASH] = {'onGangZoneFlash', {zoneId = 'int16'}, {color = 'int32'}} -- TODO: test
INCOMING_RPCS[RPC.STOPOBJECT] = {'onStopObject', {objectId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.SETNUMBERPLATE] = {'onSetVehicleNumberPlate', {vehicleId = 'int16'}, {text = 'string8'}} -- TODO: test
INCOMING_RPCS[RPC.TOGGLEPLAYERSPECTATING] = {'onTogglePlayerSpectating', {state = 'int32'}} -- TODO: test
INCOMING_RPCS[RPC.PLAYERSPECTATEPLAYER] = {'onSpectatePlayer', {playerId = 'int16'}, {camType = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.PLAYERSPECTATEVEHICLE] = {'onSpectateVehicle', {vehicleId = 'int16'}, {camType = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERWANTEDLEVEL] = {'onSetPlayerWantedLevel', {wantedLevel = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SHOWTEXTDRAW] = {'onShowTextDraw', {textDrawId = 'int16'}, {flags = 'int8'}, {letterWidth = 'float'}, {letterHeight = 'float'}, {letterColor = 'int32'}, {lineWidth = 'float'}, {lineHeight = 'float'}, {boxColor = 'int32'}, {shadow = 'int8'},
{outline = 'int8'}, {backgroundColor = 'int32'}, {style = 'int8'}, {selectable = 'int8'}, {position = 'vector2d'}, {modelId = 'int16'}, {rotation = 'vector3d'}, {zoom = 'float'}, {color1 = 'int16'}, {color2 = 'int16'}, {text = 'string32'}} -- TODO: test - skip
INCOMING_RPCS[RPC.TEXTDRAWHIDEFORPLAYER] = {'onTextDrawHide', {textDrawId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.REMOVEPLAYERMAPICON] = {'onRemoveMapIcon', {iconId = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERAMMO] = {'onSetWeaponAmmo', {weaponId = 'int8'}, {bullets = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.SETGRAVITY]               = {'onSetGravity', {gravity = 'float'}}
INCOMING_RPCS[RPC.SETVEHICLEHEALTH]         = {'onSetVehicleHealth', {vehicleId = 'int16'}, {health = 'float'}}
INCOMING_RPCS[RPC.ATTACHTRAILERTOVEHICLE] = {'onAttachTrailerToVehicle', {trailerId = 'int16'}, {vehicleId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.DETACHTRAILERFROMVEHICLE] = {'onDetachTrailerFromVehicle', {vehicleId = 'int16'}} -- TODO: test
INCOMING_RPCS[RPC.SETWEATHER] = {'onSetWeather', {weatherId = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERSKIN] = {'onSetPlayerSkin', {playerId = 'int32'}, {skinId = 'int32'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERINTERIOR]        = {'onSetInterior', {interior = 'int8'}}
INCOMING_RPCS[RPC.SETPLAYERCAMERAPOS] = {'onSetCameraPosition', {position = 'vector3d'}} -- TODO: test
INCOMING_RPCS[RPC.SETPLAYERCAMERALOOKAT] = {'onSetCameraLookAt', {lookAtPosition = 'vector3d'}, {cutType = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETVEHICLEPOS] = {'onSetVehiclePosition', {vehicleId = 'int16'}, {position = 'vector3d'}} -- TODO: test
INCOMING_RPCS[RPC.SETVEHICLEZANGLE] = {'onSetVehicleAngle', {vehicleid = 'int16'}, {angle = 'float'}} -- TODO: test
INCOMING_RPCS[RPC.SETVEHICLEPARAMSFORPLAYER] = {'onSetVehicleParams', {vehicleId = 'int16'}, {objective = 'int8'}, {doorsLocked = 'int8'}} -- TODO: test
INCOMING_RPCS[RPC.SETCAMERABEHINDPLAYER] = {'onSetCameraBehind'} -- TODO: test
INCOMING_RPCS[RPC.CHAT]                     = {'onChatMessage', {playerId = 'int16'}, {text = 'string8'}}
INCOMING_RPCS[RPC.CONNECTIONREJECTED]       = {'onConnectionRejected', {reason = 'int8'}}
INCOMING_RPCS[RPC.WORLDPLAYERREMOVE]        = {'onPlayerStreamOut', {playerId = 'int16'}}
INCOMING_RPCS[RPC.WORLDVEHICLEADD]          = {'onVehicleStreamIn', {vehicleId = 'int16'}, {model = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}, {rotation = 'float'}, {color1 = 'int8'}, {color2 = 'int8'}, {health = 'float'}, {interior = 'int8'}, {locked = 'bool8'}, {panelDamage = 'int32'}, {doorDamage = 'int32'}, {lightsDamage = 'int8'}, {tiresDamage = 'int8'}} -- TODO: Update
INCOMING_RPCS[RPC.WORLDVEHICLEREMOVE]       = {'onVehicleStreamOut', {vehicleId = 'int16'}}
INCOMING_RPCS[RPC.WORLDPLAYERDEATH]         = {'onPlayerDeath', {playerId = 'int16'}}
INCOMING_RPCS[RPC.ENTERVEHICLE]             = {'onPlayerEnterVehicle', {playerId = 'int16'}, {vehicleId = 'int16'}, {passenger = 'bool8'}}
INCOMING_RPCS[RPC.UPDATESCORESPINGSIPS]     = {'onUpdateScoresAndPings', {playerList = 'PlayerScorePingMap'}}

-- Outgoing packets
OUTCOMING_PACKETS[PACKET.RCON_COMMAND]    = {'onSendRconCommand', {command = 'string32'}}
OUTCOMING_PACKETS[PACKET.STATS_UPDATE]    = {'onSendStatsUpdate', {money = 'int32'}, {drunkLevel = 'int32'}}
OUTCOMING_PACKETS[PACKET.PLAYER_SYNC]     = {'onSendPlayerSync',     function(bs) return process_outcoming_sync_data(bs, 'PlayerSyncData') end, empty_writer}
OUTCOMING_PACKETS[PACKET.VEHICLE_SYNC]    = {'onSendVehicleSync',    function(bs) return process_outcoming_sync_data(bs, 'VehicleSyncData') end, empty_writer}
OUTCOMING_PACKETS[PACKET.PASSENGER_SYNC]  = {'onSendPassengerSync',  function(bs) return process_outcoming_sync_data(bs, 'PassengerSyncData') end, empty_writer}
OUTCOMING_PACKETS[PACKET.AIM_SYNC]        = {'onSendAimSync',        function(bs) return process_outcoming_sync_data(bs, 'AimSyncData') end, empty_writer}
OUTCOMING_PACKETS[PACKET.UNOCCUPIED_SYNC] = {'onSendUnoccupiedSync', function(bs) return process_outcoming_sync_data(bs, 'UnoccupiedSyncData') end, empty_writer}
OUTCOMING_PACKETS[PACKET.TRAILER_SYNC]    = {'onSendTrailerSync',    function(bs) return process_outcoming_sync_data(bs, 'TrailerSyncData') end, empty_writer}
OUTCOMING_PACKETS[PACKET.BULLET_SYNC]     = {'onSendBulletSync',     function(bs) return process_outcoming_sync_data(bs, 'BulletSyncData') end, empty_writer}
OUTCOMING_PACKETS[PACKET.SPECTATOR_SYNC]  = {'onSendSpectatorSync',  function(bs) return process_outcoming_sync_data(bs, 'SpectatorSyncData') end, empty_writer}

-- Incoming packets
INCOMING_PACKETS[PACKET.PLAYER_SYNC]      = {'onPlayerSync', on_player_sync_reader, on_player_sync_writer}
INCOMING_PACKETS[PACKET.VEHICLE_SYNC]     = {'onVehicleSync', on_vehicle_sync_reader, on_vehicle_sync_writer}
INCOMING_PACKETS[PACKET.MARKERS_SYNC]     = {'onMarkersSync', on_markers_sync_reader, on_markers_sync_writer}
INCOMING_PACKETS[PACKET.AIM_SYNC]         = {'onAimSync', {playerId = 'int16'}, {data = 'AimSyncData'}}
INCOMING_PACKETS[PACKET.BULLET_SYNC]      = {'onBulletSync', {playerId = 'int16'}, {data = 'BulletSyncData'}}
INCOMING_PACKETS[PACKET.UNOCCUPIED_SYNC]  = {'onUnoccupiedSync', {playerId = 'int16'}, {data = 'UnoccupiedSyncData'}}
INCOMING_PACKETS[PACKET.TRAILER_SYNC]     = {'onTrailerSync', {playerId = 'int16'}, {data = 'TrailerSyncData'}}
INCOMING_PACKETS[PACKET.PASSENGER_SYNC]   = {'onPassengerSync', {playerId = 'int16'}, {data = 'PassengerSyncData'}}


--- Extra types
BitStreamIO.PlayerScorePingMap = {
	read = function(bs)
		local data = {}
		for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) / 10 do
			local playerId = raknetBitStreamReadInt16(bs)
			local playerScore = raknetBitStreamReadInt32(bs)
			local playerPing = raknetBitStreamReadInt32(bs)
			data[playerId] = {score = playerScore, ping = playerPing}
		end
		return data
	end,
	write = function(bs, value)
		for id, data in pairs(value) do
			raknetBitStreamWriteInt16(bs, id)
			raknetBitStreamWriteInt32(bs, data.score)
			raknetBitStreamWriteInt32(bs, data.ping)
		end
	end
}

BitStreamIO.Int32Array3 = {
	read = function(bs)
		local arr = {}
		for i = 1, 3 do arr[i] = raknetBitStreamReadInt32(bs) end
		return arr
	end,
	write = function(bs, value)
		for i = 1, 3 do raknetBitStreamWriteInt32(bs, value[i]) end
	end
}

BitStreamIO.AimSyncData = {
	read = function(bs) return utils.read_sync_data(bs, 'AimSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'AimSyncData', value) end
}

BitStreamIO.UnoccupiedSyncData = {
	read = function(bs) return utils.read_sync_data(bs, 'UnoccupiedSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'UnoccupiedSyncData', value) end
}

BitStreamIO.PassengerSyncData = {
	read = function(bs) 	return utils.read_sync_data(bs, 'PassengerSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'PassengerSyncData', value) end
}

BitStreamIO.BulletSyncData = {
	read = function(bs) return utils.read_sync_data(bs, 'BulletSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'BulletSyncData', value) end
}

BitStreamIO.TrailerSyncData = {
	read = function(bs) return utils.read_sync_data(bs, 'TrailerSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'TrailerSyncData', value) end
}

return events
