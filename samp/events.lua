-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua


local events            = require 'lib.samp.events_core'
local raknet            = require 'lib.samp.raknet'
local RPC               = raknet.RPC
local PACKET            = raknet.PACKET
local OUTCOMING_RPCS    = events.INTERFACE.OUTCOMING_RPCS
local OUTCOMING_PACKETS = events.INTERFACE.OUTCOMING_PACKETS
local INCOMING_RPCS     = events.INTERFACE.INCOMING_RPCS
local INCOMING_PACKETS  = events.INTERFACE.INCOMING_PACKETS
local BitStreamIO       = events.INTERFACE.BitStreamIO

--[[ custom handlers ]] --
local function processSendGiveTakeDamageReader(bs, take)
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

local function processSendGiveTakeDamageWriter(bs, data, take)
	local write = events.EXPORTS.bitStreamWrite
	write(bs, 'bool',  take) -- give or take
	write(bs, 'int16', data[1]) -- playerId
	write(bs, 'float', data[2]) -- damage
	write(bs, 'int32', data[3]) -- weapon
	write(bs, 'int32', data[4]) -- bodypart
end

local function onInitGameReader(bs)
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

local function onInitGameWriter(bs, data)
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

local function onInitMenuReader(bs)
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

local function onInitMenuWriter(bs, data)
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

local function processOutcomingSyncData(bs, structName)
	local data = raknetBitStreamGetDataPtr(bs) + 1
	local ffi = require 'ffi'
	require 'lib.samp.synchronization'
	return {ffi.cast('struct ' .. structName .. '*', data)}
end

local function emptyWriter() end

--[[ events ]]--
OUTCOMING_RPCS[RPC.ENTERVEHICLE]         = {'onSendEnterVehicle', {vehicleId = 'int16'}, {passenger = 'bool8'}}
OUTCOMING_RPCS[RPC.CLICKPLAYER]          = {'onSendClickPlayer', {playerId = 'int16'}, {source = 'int8'}}
OUTCOMING_RPCS[RPC.CLIENTJOIN]           = {'onSendClientJoin', {version = 'int32'}, {mod = 'int8'}, {nickname = 'string8'}, {joinAuthKey = 'string8'}, {clientVer = 'string8'}}
OUTCOMING_RPCS[RPC.ENTEREDITOBJECT]      = {'onSendEnterEditObject'} ---???????????
OUTCOMING_RPCS[RPC.SERVERCOMMAND]        = {'onSendCommand', {command = 'string32'}}
OUTCOMING_RPCS[RPC.SPAWN]                = {'onSendSpawn'}
OUTCOMING_RPCS[RPC.DEATH]                = {'onSendDeathNotification', {reason = 'int8'}, {killerId = 'int16'}}
OUTCOMING_RPCS[RPC.DIALOGRESPONSE]       = {'onSendDialogResponse', {dialogId = 'int16'}, {button = 'int8'}, {listboxId = 'int16'}, {input = 'string8'}}
OUTCOMING_RPCS[RPC.CLICKTEXTDRAW]        = {'onSendClickTextDraw', {textdrawId = 'int16'}}
OUTCOMING_RPCS[RPC.SCMEVENT]             = {'onSendVehicleTuningNotification', {event = 'int32'}, {vehicleId = 'int32'}, {param1 = 'int32'}, {param2 = 'int32'}}
OUTCOMING_RPCS[RPC.CHAT]                 = {'onSendChat', {message = 'string8'}}
OUTCOMING_RPCS[RPC.CLIENTCHECK]          = {'onSendClientCheckResponse', {'int8'}, {'int32'}, {'int8'}}
OUTCOMING_RPCS[RPC.DAMAGEVEHICLE]        = {'onSendVehicleDamaged', {vehicleId = 'int16'}, {panelDmg = 'int32'}, {doorDmg = 'int32'}, {lights = 'int8'}, {tires = 'int8'}}
OUTCOMING_RPCS[RPC.EDITATTACHEDOBJECT]   = {'onSendEditAttachedObject', {response = 'int32'}, {index = 'int32'}, {model = 'int32'}, {bone = 'int32'}, {posX = 'float'}, 
																		{posY = 'float'}, {posZ = 'float'}, {rotX = 'float'}, {rotY = 'float'}, {rotZ = 'float'}, 
																		{scaleX = 'float'}, {scaleY = 'float'}, {scaleZ = 'float'}, {color1 = 'int32'}, {color2 = 'int32'}}
OUTCOMING_RPCS[RPC.EDITOBJECT]           = {'onSendEditObject', {playerObject = 'bool'}, {objectId = 'int16'}, {response = 'int32'}, {posX = 'float'},
																{posY = 'float'}, {posZ = 'float'}, {rotX = 'float'}, {rotY = 'float'}, {rotZ = 'float'}}
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
OUTCOMING_RPCS[RPC.GIVETAKEDAMAGE]       = {{'onSendGiveDamage', -- int playerId, float damage, int weapon, int bodypart
																function(bs) return processSendGiveTakeDamageReader(bs, false) end,
																function(bs, data) return processSendGiveTakeDamageWriter(bs, data, false) end},
																{'onSendTakeDamage', -- int playerId, float damage, int weapon, int bodypart
																function(bs) return processSendGiveTakeDamageReader(bs, true) end,
																function(bs, data) return processSendGiveTakeDamageWriter(bs, data, true) end}}
---

-- int playerId, string hostName, table settings, table vehicleModels, int unknown
INCOMING_RPCS[RPC.INITGAME]                 = {'onInitGame', onInitGameReader, onInitGameWriter}
INCOMING_RPCS[RPC.SERVERJOIN]               = {'onPlayerJoin', {playerId = 'int16'}, {color = 'int32'}, {isNpc = 'bool8'}, {nickname = 'string8'}}
INCOMING_RPCS[RPC.SERVERQUIT]               = {'onPlayerQuit', {playerId = 'int16'}, {reason = 'int8'}}
INCOMING_RPCS[RPC.REQUESTCLASS]             = {'onRequestClassResponse', {canSpawn = 'bool8'}, {team = 'int8'}, {skin = 'int32'}, {unk = 'int8'}, {x = 'float'}, {y = 'float'},
																		 {z = 'float'}, {rotation = 'float'}, {weapons = 'int32arr3'}, {ammo = 'int32arr3'}}
INCOMING_RPCS[RPC.REQUESTSPAWN]             = {'onRequestSpawnResponse', {response = 'bool8'}}
-- INCOMING_RPCS[RPC.SETPLAYERNAME] = {''}
INCOMING_RPCS[RPC.SETPLAYERPOS]             = {'onSetPlayerPos', {x = 'float'}, {y = 'float'}, {z = 'float'}}
-- INCOMING_RPCS[RPC.SETPLAYERPOSFINDZ] = {''}
INCOMING_RPCS[RPC.SETPLAYERHEALTH]          = {'onSetPlayerHealth', {health = 'float'}}
INCOMING_RPCS[RPC.TOGGLEPLAYERCONTROLLABLE] = {'onTogglePlayerControllable', {controllable = 'bool8'}}
-- INCOMING_RPCS[RPC.PLAYSOUND] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERWORLDBOUNDS] = {''}
INCOMING_RPCS[RPC.GIVEPLAYERMONEY]          = {'onGivePlayerMoney', {money = 'int32'}}
-- INCOMING_RPCS[RPC.SETPLAYERFACINGANGLE] = {''}
INCOMING_RPCS[RPC.RESETPLAYERMONEY]         = {'onResetPlayerMoney'}
INCOMING_RPCS[RPC.RESETPLAYERWEAPONS]       = {'onResetPlayerWeapons'}
-- INCOMING_RPCS[RPC.GIVEPLAYERWEAPON] = {''}
-- INCOMING_RPCS[RPC.SETVEHICLEPARAMSEX] = {''}
-- INCOMING_RPCS[RPC.CANCELEDIT] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERTIME] = {''}
-- INCOMING_RPCS[RPC.TOGGLECLOCK] = {''}
INCOMING_RPCS[RPC.WORLDPLAYERADD]           = {'onPlayerStreamIn', {playerId = 'int16'}, {team = 'int8'}, {model = 'int32'}, {posX = 'float'}, {posY = 'float'},
																	{posZ = 'float'}, {rotation = 'float'}, {color = 'int32'}, {fightingStyle = 'int8'}}
-- INCOMING_RPCS[RPC.SETPLAYERSHOPNAME] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERSKILLLEVEL] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERDRUNKLEVEL] = {''}
INCOMING_RPCS[RPC.CREATE3DTEXTLABEL]        = {'onCreate3DText', {id = 'int16'}, {color = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}, {distance = 'float'},
																 {testLOS = 'bool8'}, {attachedPlayerId = 'int16'}, {attachedVehicleId = 'int16'}, {text = 'encodedString2048'}}
-- INCOMING_RPCS[RPC.DISABLECHECKPOINT] = {''}
-- INCOMING_RPCS[RPC.SETRACECHECKPOINT] = {''}
-- INCOMING_RPCS[RPC.DISABLERACECHECKPOINT] = {''}
-- INCOMING_RPCS[RPC.GAMEMODERESTART] = {''}
-- INCOMING_RPCS[RPC.PLAYAUDIOSTREAM] = {''}
-- INCOMING_RPCS[RPC.STOPAUDIOSTREAM] = {''}
-- INCOMING_RPCS[RPC.REMOVEBUILDINGFORPLAYER] = {''}
-- INCOMING_RPCS[RPC.CREATEOBJECT] = {''}
-- INCOMING_RPCS[RPC.SETOBJECTPOS] = {''}
-- INCOMING_RPCS[RPC.SETOBJECTROT] = {''}
-- INCOMING_RPCS[RPC.DESTROYOBJECT] = {''}
-- INCOMING_RPCS[RPC.DEATHMESSAGE] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERMAPICON] = {''}
-- INCOMING_RPCS[RPC.REMOVEVEHICLECOMPONENT] = {''}
-- INCOMING_RPCS[RPC.UPDATE3DTEXTLABEL] = {''}
INCOMING_RPCS[RPC.CHATBUBBLE]               = {'onPlayerChatBubble', {playerId = 'int16'}, {color = 'int32'}, {distance = 'float'}, {duration = 'int32'}, {message = 'string8'}}
INCOMING_RPCS[RPC.UPDATETIME]               = {'onUpdateGlobalTimer', {time = 'int32'}}
INCOMING_RPCS[RPC.SHOWDIALOG]               = {'onShowDialog', {dialogId = 'int16'}, {style = 'int8'}, {title = 'string8'}, {button1 = 'string8'}, {button2 = 'string8'}, {text = 'encodedString2048'}}
INCOMING_RPCS[RPC.DESTROYPICKUP]            = {'onDestroyPickup', {id = 'int32'}}
-- INCOMING_RPCS[RPC.LINKVEHICLETOINTERIOR] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERARMOUR] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERARMEDWEAPON] = {''}
INCOMING_RPCS[RPC.SETSPAWNINFO]             = {'onSetSpawnInfo', {team = 'int8'}, {skin = 'int32'}, {unk = 'int8'}, {x = 'float'}, {y = 'float'}, {z = 'float'},
																 {rotation = 'float'}, {weapons = 'int32arr3'}, {ammo = 'int32arr3'}}
-- INCOMING_RPCS[RPC.SETPLAYERTEAM] = {''}
-- INCOMING_RPCS[RPC.PUTPLAYERINVEHICLE] = {''}
-- INCOMING_RPCS[RPC.REMOVEPLAYERFROMVEHICLE] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERCOLOR] = {''}
-- INCOMING_RPCS[RPC.DISPLAYGAMETEXT] = {''}
-- INCOMING_RPCS[RPC.FORCECLASSSELECTION] = {''}
-- INCOMING_RPCS[RPC.ATTACHOBJECTTOPLAYER] = {''}
-- int menuId, string title, float x, float y, bool twoColumns, table columns, table rows, bool menuUnk
INCOMING_RPCS[RPC.INITMENU]                 = {'onInitMenu', onInitGameReader, onInitMenuWriter}
INCOMING_RPCS[RPC.SHOWMENU]                 = {'onShowMenu', {menuId = 'int8'}}
INCOMING_RPCS[RPC.HIDEMENU]                 = {'onHideMenu', {menuId = 'int8'}}
-- INCOMING_RPCS[RPC.CREATEEXPLOSION] = {''}
-- INCOMING_RPCS[RPC.SHOWPLAYERNAMETAGFORPLAYER] = {''}
-- INCOMING_RPCS[RPC.ATTACHCAMERATOOBJECT] = {''}
-- INCOMING_RPCS[RPC.INTERPOLATECAMERA] = {''}
-- INCOMING_RPCS[RPC.SETOBJECTMATERIAL] = {''}
-- INCOMING_RPCS[RPC.GANGZONESTOPFLASH] = {''}
INCOMING_RPCS[RPC.APPLYANIMATION]           = {'onApplyPlayerAnimation', {playerId = 'int16'}, {animLib = 'string8'}, {animName = 'string8'}, {loop = 'bool'},
																		 {lockX = 'bool'}, {lockY = 'bool'}, {freeze = 'bool'}, {time = 'int32'}}
INCOMING_RPCS[RPC.CLEARANIMATIONS]          = {'onClearPlayerAnimation', {playerId = 'int16'}}
-- INCOMING_RPCS[RPC.SETPLAYERSPECIALACTION] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERFIGHTINGSTYLE] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERVELOCITY] = {''}
-- INCOMING_RPCS[RPC.SETVEHICLEVELOCITY] = {''}
INCOMING_RPCS[RPC.CLIENTMESSAGE]            = {'onServerMessage', {color = 'int32'}, {text = 'string32'}}
-- INCOMING_RPCS[RPC.SETWORLDTIME] = {''}
INCOMING_RPCS[RPC.CREATEPICKUP]             = {'onCreatePickup', {id = 'int32'}, {model = 'int32'}, {pickupType = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}}
-- INCOMING_RPCS[RPC.MOVEOBJECT] = {''}
-- INCOMING_RPCS[RPC.ENABLESTUNTBONUSFORPLAYER] = {''}
-- INCOMING_RPCS[RPC.TEXTDRAWSETSTRING] = {''}
-- INCOMING_RPCS[RPC.SETCHECKPOINT] = {''}
-- INCOMING_RPCS[RPC.GANGZONECREATE] = {''}
-- INCOMING_RPCS[RPC.PLAYCRIMEREPORT] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERATTACHEDOBJECT] = {''}
-- INCOMING_RPCS[RPC.GANGZONEDESTROY] = {''}
-- INCOMING_RPCS[RPC.GANGZONEFLASH] = {''}
-- INCOMING_RPCS[RPC.STOPOBJECT] = {''}
-- INCOMING_RPCS[RPC.SETNUMBERPLATE] = {''}
-- INCOMING_RPCS[RPC.TOGGLEPLAYERSPECTATING] = {''}
-- INCOMING_RPCS[RPC.PLAYERSPECTATEPLAYER] = {''}
-- INCOMING_RPCS[RPC.PLAYERSPECTATEVEHICLE] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERWANTEDLEVEL] = {''}
-- INCOMING_RPCS[RPC.SHOWTEXTDRAW] = {''}
-- INCOMING_RPCS[RPC.TEXTDRAWHIDEFORPLAYER] = {''}
-- INCOMING_RPCS[RPC.REMOVEPLAYERMAPICON] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERAMMO] = {''}
INCOMING_RPCS[RPC.SETGRAVITY]               = {'onSetGravity', {gravity = 'float'}}
INCOMING_RPCS[RPC.SETVEHICLEHEALTH]         = {'onSetVehicleHealth', {vehicleId = 'int16'}, {health = 'float'}}
-- INCOMING_RPCS[RPC.ATTACHTRAILERTOVEHICLE] = {''}
-- INCOMING_RPCS[RPC.DETACHTRAILERFROMVEHICLE] = {''}
-- INCOMING_RPCS[RPC.SETWEATHER] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERSKIN] = {''}
INCOMING_RPCS[RPC.SETPLAYERINTERIOR]        = {'onSetInterior', {interior = 'int8'}}
-- INCOMING_RPCS[RPC.SETPLAYERCAMERAPOS] = {''}
-- INCOMING_RPCS[RPC.SETPLAYERCAMERALOOKAT] = {''}
-- INCOMING_RPCS[RPC.SETVEHICLEPOS] = {''}
-- INCOMING_RPCS[RPC.SETVEHICLEZANGLE] = {''}
-- INCOMING_RPCS[RPC.SETVEHICLEPARAMSFORPLAYER] = {''}
-- INCOMING_RPCS[RPC.SETCAMERABEHINDPLAYER] = {''}
INCOMING_RPCS[RPC.CHAT]                     = {'onChatMessage', {playerId = 'int16'}, {text = 'string8'}}
INCOMING_RPCS[RPC.CONNECTIONREJECTED]       = {'onConnectionRejected', {reason = 'int8'}}
INCOMING_RPCS[RPC.WORLDPLAYERREMOVE]        = {'onPlayerStreamOut', {playerId = 'int16'}}
INCOMING_RPCS[RPC.WORLDVEHICLEADD]          = {'onVehicleStreamIn', {vehicleId = 'int16'}, {model = 'int32'}, {posX = 'float'}, {posY = 'float'}, {posZ = 'float'}, {rotation = 'float'},
																	{color1 = 'int8'}, {color2 = 'int8'}, {health = 'float'}, {interior = 'int8'}, {locked = 'bool8'},
																	{panelDamage = 'int32'}, {doorDamage = 'int32'}, {lightsDamage = 'int8'}, {tiresDamage = 'int8'}}
INCOMING_RPCS[RPC.WORLDVEHICLEREMOVE]       = {'onVehicleStreamOut', {vehicleId = 'int16'}}
INCOMING_RPCS[RPC.WORLDPLAYERDEATH]         = {'onPlayerDeath', {playerId = 'int16'}}
---

OUTCOMING_PACKETS[PACKET.RCON_COMMAND]    = {'onSendRconCommand', {command = 'string32'}}
OUTCOMING_PACKETS[PACKET.STATS_UPDATE]    = {'onSendStatsUpdate', {money = 'int32'}, {drunkLevel = 'int32'}}
OUTCOMING_PACKETS[PACKET.PLAYER_SYNC]     = {'onSendPlayerSync',     function(bs) return processOutcomingSyncData(bs, 'PlayerSyncData') end, emptyWriter}
OUTCOMING_PACKETS[PACKET.VEHICLE_SYNC]    = {'onSendVehicleSync',    function(bs) return processOutcomingSyncData(bs, 'VehicleSyncData') end, emptyWriter}
OUTCOMING_PACKETS[PACKET.PASSENGER_SYNC]  = {'onSendPassengerSync',  function(bs) return processOutcomingSyncData(bs, 'PassengerSyncData') end, emptyWriter}
OUTCOMING_PACKETS[PACKET.AIM_SYNC]        = {'onSendAimSync',        function(bs) return processOutcomingSyncData(bs, 'AimSyncData') end, emptyWriter}
OUTCOMING_PACKETS[PACKET.UNOCCUPIED_SYNC] = {'onSendUnoccupiedSync', function(bs) return processOutcomingSyncData(bs, 'UnoccupiedSyncData') end, emptyWriter}
OUTCOMING_PACKETS[PACKET.TRAILER_SYNC]    = {'onSendTrailerSync',    function(bs) return processOutcomingSyncData(bs, 'TrailerSyncData') end, emptyWriter}
OUTCOMING_PACKETS[PACKET.BULLET_SYNC]     = {'onSendBulletSync',     function(bs) return processOutcomingSyncData(bs, 'BulletSyncData') end, emptyWriter}
OUTCOMING_PACKETS[PACKET.SPECTATOR_SYNC]  = {'onSendSpectatorSync',  function(bs) return processOutcomingSyncData(bs, 'SpectatorSyncData') end, emptyWriter}


--[[ custom types ]]--
BitStreamIO.playerScorePingMap = {
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

BitStreamIO.encodedString2048 = {
	read = function(bs) return raknetBitStreamDecodeString(bs, 2048) end,
	write = function(bs, value) raknetBitStreamEncodeString(bs, value) end
}

BitStreamIO.int32arr3 = {
	read = function(bs)
		local arr = {}
		for i = 1, 3 do arr[i] = raknetBitStreamReadInt32(bs) end
		return arr
	end,
	write = function(bs, value)
		for i = 1, 3 do raknetBitStreamWriteInt32(bs, value[i]) end
	end
}

BitStreamIO.string256 = {
	read = function(bs)
		return raknetBitStreamReadString(bs, 32)
	end,
	write = function(bs, value)
		if #value >= 32 then raknetBitStreamWriteString(bs, value:sub(1, 32))
		else
			raknetBitStreamWriteString(bs, value)
			for i = 1, 32 - #value do -- fill with zeros up to 32 bytes
				raknetBitStreamWriteInt8(bs, 0)
			end
		end
	end
}

return events
