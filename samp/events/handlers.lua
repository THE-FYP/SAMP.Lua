-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua


local BitStreamIO = require 'lib.samp.events.bitstream_io'
local handler = {}

--- onSendGiveDamage, onSendTakeDamage
function handler.send_give_take_damage_reader(bs, take)
	local read = BitStreamIO.bs_read
	if read.bool(bs) ~= take then -- 'true' is take damage
		return false
	end
	local data = {
		read.int16(bs), -- playerId
		read.float(bs), -- damage
		read.int32(bs), -- weapon
		read.int32(bs), -- bodypart
	}
	return data
end

function handler.send_give_take_damage_writer(bs, data, take)
	local write = BitStreamIO.bs_write
	write.bool(bs, take) -- give or take
	write.int16(bs, data[1]) -- playerId
	write.float(bs, data[2]) -- damage
	write.int32(bs, data[3]) -- weapon
	write.int32(bs, data[4]) -- bodypart
end


--- OnInitGame
function handler.on_init_game_reader(bs)
	local read                     = BitStreamIO.bs_read
	local settings                 = {}
	settings.zoneNames             = read.bool(bs)
	settings.useCJWalk             = read.bool(bs)
	settings.allowWeapons          = read.bool(bs)
	settings.limitGlobalChatRadius = read.bool(bs)
	settings.globalChatRadius      = read.float(bs)
	settings.stuntBonus            = read.bool(bs)
	settings.nametagDrawDist       = read.float(bs)
	settings.disableEnterExits     = read.bool(bs)
	settings.nametagLOS            = read.bool(bs)
	settings.tirePopping           = read.bool(bs)
	settings.classesAvailable      = read.int32(bs)
	local playerId                 = read.int16(bs)
	settings.showPlayerTags        = read.bool(bs)
	settings.playerMarkersMode     = read.int32(bs)
	settings.worldTime             = read.int8(bs)
	settings.worldWeather          = read.int8(bs)
	settings.gravity               = read.float(bs)
	settings.lanMode               = read.bool(bs)
	settings.deathMoneyDrop        = read.int32(bs)
	settings.instagib              = read.bool(bs)
	settings.normalOnfootSendrate  = read.int32(bs)
	settings.normalIncarSendrate   = read.int32(bs)
	settings.normalFiringSendrate  = read.int32(bs)
	settings.sendMultiplier        = read.int32(bs)
	settings.lagCompMode           = read.int32(bs)
	local hostName                 = read.string8(bs)
	local vehicleModels = {}
	for i = 0, 212 - 1 do
		vehicleModels[i] = read.int8(bs)
	end
	local unknown = read.int32(bs)
	return {playerId, hostName, settings, vehicleModels, unknown}
end

function handler.on_init_game_writer(bs, data)
	local write = BitStreamIO.bs_write
	local settings = data[3]
	local vehicleModels = data[4]
	write.bool(bs, settings.zoneNames)
	write.bool(bs, settings.useCJWalk)
	write.bool(bs, settings.allowWeapons)
	write.bool(bs, settings.limitGlobalChatRadius)
	write.float(bs, settings.globalChatRadius)
	write.bool(bs, settings.stuntBonus)
	write.float(bs, settings.nametagDrawDist)
	write.bool(bs, settings.disableEnterExits)
	write.bool(bs, settings.nametagLOS)
	write.bool(bs, settings.tirePopping)
	write.int32(bs, settings.classesAvailable)
	write.int16(bs, data[1]) -- playerId
	write.bool(bs, settings.showPlayerTags)
	write.int32(bs, settings.playerMarkersMode)
	write.int8(bs, settings.worldTime)
	write.int8(bs, settings.worldWeather)
	write.float(bs, settings.gravity)
	write.bool(bs, settings.lanMode)
	write.int32(bs, settings.deathMoneyDrop)
	write.bool(bs, settings.instagib)
	write.int32(bs, settings.normalOnfootSendrate)
	write.int32(bs, settings.normalIncarSendrate)
	write.int32(bs, settings.normalFiringSendrate)
	write.int32(bs, settings.sendMultiplier)
	write.int32(bs, settings.lagCompMode)
	write.string8(bs, data[2]) -- hostName
	for i = 0, 212 - 1 do
		write.int8(bs, vehicleModels[i])
	end
	write.int32(bs, data[5]) -- unknown
end


--- OnInitMenu
function handler.on_init_menu_reader(bs)
	local read = BitStreamIO.bs_read
	local colWidth2
	local rows = {}
	local columns = {}

	local readColumn = function(width)
		local id = #columns + 1
		local title = read.string256(bs)
		local rowCount = read.int8(bs)
		local column = {title = title, width = width, text = {}}
		for i = 1, rowCount do
			local text = read.string256(bs)
			columns[id].text[i] = text
		end
		return column
	end

	local menuId     = read.int8(bs)
	local twoColumns = read.bool32(bs)
	local menuTitle  = read.string256(bs)
	local x          = read.float(bs)
	local y          = read.float(bs)
	local colWidth1  = read.float(bs)
	if twoColumns then
		colWidth2      = read.float(bs)
	end
	local menu       = read.bool32(bs)
	for i = 1, 12 do
		rows[i]        = read.int32(bs)
	end
	columns[1]       = readColumn(colWidth1)
	if twoColumns then
		columns[2]     = readColumn(colWidth2)
	end

	return {menuId, menuTitle, x, y, twoColumns, columns, rows, menu}
end

function handler.on_init_menu_writer(bs, data)
	local write = BitStreamIO.bs_write
	local columns = data[6]
	write.int8(bs, data[1])      -- menuId
	write.bool32(bs, data[5])    -- twoColumns
	write.string256(bs, data[2]) -- title
	write.float(bs, data[3])     -- x
	write.float(bs, data[4])     -- y
	-- columns width
	write.float(bs, columns[1].width)
	if data[5] then
		write.float(bs, columns[2].width)
	end
	write.bool32(bs, data[8]) -- menu
	 -- rows
	for i = 1, 12 do
		write.int32(bs, data[7][i])
	end
	-- columns
	for i = 1, (data[5] and 2 or 1) do
		write.string256(bs, columns[i].title)
		write.int8(bs, #columns[i].text)
		for r, t in ipairs(columns[i].text) do
			write.string256(bs, t)
		end
	end
end


--- onMarkersSync
function handler.on_markers_sync_reader(bs)
	local markers = {}
	local players = raknetBitStreamReadInt32(bs)
	for i = 1, players do
		local playerId = raknetBitStreamReadInt16(bs)
		local active = raknetBitStreamReadBool(bs)
		if active then
			local Vector3D = require 'lib.vector3d'
			local x, y, z = raknetBitStreamReadInt16(bs), raknetBitStreamReadInt16(bs), raknetBitStreamReadInt16(bs)
			table.insert(markers, {playerId = playerId, active = true, coords = Vector3D(x, y, z)})
		else
			table.insert(markers, {playerId = playerId, active = false})
		end
	end
	return {markers}
end

function handler.on_markers_sync_writer(bs, data)
	raknetBitStreamWriteInt32(bs, #data)
	for i = 1, #data do
		local it = data[i]
		raknetBitStreamWriteInt16(bs, it.playerId)
		raknetBitStreamWriteBool(bs, it.active)
		if it.active then
			raknetBitStreamWriteInt16(bs, it.coords.x)
			raknetBitStreamWriteInt16(bs, it.coords.y)
			raknetBitStreamWriteInt16(bs, it.coords.z)
		end
	end
end


--- onPlayerSync
function handler.on_player_sync_reader(bs)
	local has_value = raknetBitStreamReadBool
	local read = BitStreamIO.bs_write
	local data = {}
	local playerId = raknetBitStreamReadInt16(bs)
	if has_value(bs) then data.leftRightKeys = raknetBitStreamReadInt16(bs) end
	if has_value(bs) then data.upDownKeys = raknetBitStreamReadInt16(bs) end
	data.keysData = raknetBitStreamReadInt16(bs)
	data.position = read.vector3d(bs)
	data.quaternion = read.normQuat(bs)
	data.health, data.armor = utils.decompress_health_and_armor(raknetBitStreamReadInt8(bs))
	data.weapon = raknetBitStreamReadInt8(bs)
	data.specialAction = raknetBitStreamReadInt8(bs)
	data.moveSpeed = read.compressedVector(bs)
	if has_value(bs) then
		data.surfingVehicleId = raknetBitStreamReadInt16(bs)
		data.surfingOffsets = read.vector3d(bs)
	end
	if has_value(bs) then
		data.animationId = raknetBitStreamReadInt16(bs)
		data.animationFlags = raknetBitStreamReadInt16(bs)
	end
	return {playerId, data}
end

function handler.on_player_sync_writer(bs, data)
	local write = BitStreamIO.bs_write
	local playerId = data[1]
	local data = data[2]
	raknetBitStreamWriteInt16(bs, playerId)
	raknetBitStreamWriteBool(bs, data.leftRightKeys ~= nil)
	if data.leftRightKeys then raknetBitStreamWriteInt16(bs, data.leftRightKeys) end
	raknetBitStreamWriteBool(bs, data.upDownKeys ~= nil)
	if data.upDownKeys then raknetBitStreamWriteInt16(bs, data.upDownKeys) end
	raknetBitStreamWriteInt16(bs, data.keysData)
	write.vector3d(bs, data.position)
	write.normQuat(bs, data.quaternion)
	raknetBitStreamWriteInt8(bs, utils.compress_health_and_armor(data.health, data.armor))
	raknetBitStreamWriteInt8(bs, data.weapon)
	raknetBitStreamWriteInt8(bs, data.specialAction)
	write.compressedVector(bs, data.moveSpeed)
	raknetBitStreamWriteBool(bs, data.surfingVehicleId ~= nil)
	if data.surfingVehicleId then
		raknetBitStreamWriteInt16(bs, data.surfingVehicleId)
		write.vector3d(bs, data.surfingOffsets)
	end
	raknetBitStreamWriteBool(bs, data.animationId ~= nil)
	if data.animationId then
		raknetBitStreamWriteInt16(bs, data.animationId)
		raknetBitStreamWriteInt16(bs, data.animationFlags)
	end
end


--- onVehicleSync
function handler.on_vehicle_sync_reader(bs)
	local read = BitStreamIO.bs_read
	local data = {}
	local playerId = raknetBitStreamReadInt16(bs)
	local vehicleId = raknetBitStreamReadInt16(bs)
	data.leftRightKeys = raknetBitStreamReadInt16(bs)
	data.upDownKeys = raknetBitStreamReadInt16(bs)
	data.keysData = raknetBitStreamReadInt16(bs)
	data.quaternion = read.normQuat(bs)
	data.position = read.vector3d(bs)
	data.moveSpeed = read.compressedVector(bs)
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

function handler.on_vehicle_sync_writer(bs, data)
	local write = BitStreamIO.bs_write
	local playerId = data[1]
	local vehicleId = data[2]
	local data = data[3]
	raknetBitStreamWriteInt16(bs, playerId)
	raknetBitStreamWriteInt16(bs, vehicleId)
	raknetBitStreamWriteInt16(bs, data.leftRightKeys)
	raknetBitStreamWriteInt16(bs, data.upDownKeys)
	raknetBitStreamWriteInt16(bs, data.keysData)
	write.normQuat(bs, data.quaternion)
	write.vector3d(bs, data.position)
	write.compressedVector(bs, data.moveSpeed)
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

return handler
