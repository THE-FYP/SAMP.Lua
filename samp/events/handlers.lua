-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua

local bs_io = require 'samp.events.bitstream_io'
local utils = require 'samp.events.utils'
local bsread, bswrite = bs_io.bs_read, bs_io.bs_write
local handler = {}

--- onSendGiveDamage, onSendTakeDamage
function handler.rpc_send_give_take_damage_reader(bs)
	local take = bsread.bool(bs) -- 'true' is take damage
	local data = {
		bsread.int16(bs), -- playerId
		bsread.float(bs), -- damage
		bsread.int32(bs), -- weapon
		bsread.int32(bs), -- bodypart
		take,
	}
	return (take and 'onSendTakeDamage' or 'onSendGiveDamage'), data
end

function handler.rpc_send_give_take_damage_writer(bs, data)
	bswrite.bool(bs, data[5]) -- give or take
	bswrite.int16(bs, data[1]) -- playerId
	bswrite.float(bs, data[2]) -- damage
	bswrite.int32(bs, data[3]) -- weapon
	bswrite.int32(bs, data[4]) -- bodypart
end

--- onInitGame
function handler.rpc_init_game_reader(bs)
	local settings                 = {}
	settings.zoneNames             = bsread.bool(bs)
	settings.useCJWalk             = bsread.bool(bs)
	settings.allowWeapons          = bsread.bool(bs)
	settings.limitGlobalChatRadius = bsread.bool(bs)
	settings.globalChatRadius      = bsread.float(bs)
	settings.stuntBonus            = bsread.bool(bs)
	settings.nametagDrawDist       = bsread.float(bs)
	settings.disableEnterExits     = bsread.bool(bs)
	settings.nametagLOS            = bsread.bool(bs)
	settings.tirePopping           = bsread.bool(bs)
	settings.classesAvailable      = bsread.int32(bs)
	local playerId                 = bsread.int16(bs)
	settings.showPlayerTags        = bsread.bool(bs)
	settings.playerMarkersMode     = bsread.int32(bs)
	settings.worldTime             = bsread.int8(bs)
	settings.worldWeather          = bsread.int8(bs)
	settings.gravity               = bsread.float(bs)
	settings.lanMode               = bsread.bool(bs)
	settings.deathMoneyDrop        = bsread.int32(bs)
	settings.instagib              = bsread.bool(bs)
	settings.normalOnfootSendrate  = bsread.int32(bs)
	settings.normalIncarSendrate   = bsread.int32(bs)
	settings.normalFiringSendrate  = bsread.int32(bs)
	settings.sendMultiplier        = bsread.int32(bs)
	settings.lagCompMode           = bsread.int32(bs)
	local hostName                 = bsread.string8(bs)
	local vehicleModels = {}
	for i = 1, 212 do
		vehicleModels[i] = bsread.int8(bs)
	end
	settings.vehicleFriendlyFire = bsread.int32(bs)
	return {playerId, hostName, settings, vehicleModels}
end

function handler.rpc_init_game_writer(bs, data)
	local settings = data[3]
	local vehicleModels = data[4]
	bswrite.bool(bs, settings.zoneNames)
	bswrite.bool(bs, settings.useCJWalk)
	bswrite.bool(bs, settings.allowWeapons)
	bswrite.bool(bs, settings.limitGlobalChatRadius)
	bswrite.float(bs, settings.globalChatRadius)
	bswrite.bool(bs, settings.stuntBonus)
	bswrite.float(bs, settings.nametagDrawDist)
	bswrite.bool(bs, settings.disableEnterExits)
	bswrite.bool(bs, settings.nametagLOS)
	bswrite.bool(bs, settings.tirePopping)
	bswrite.int32(bs, settings.classesAvailable)
	bswrite.int16(bs, data[1]) -- playerId
	bswrite.bool(bs, settings.showPlayerTags)
	bswrite.int32(bs, settings.playerMarkersMode)
	bswrite.int8(bs, settings.worldTime)
	bswrite.int8(bs, settings.worldWeather)
	bswrite.float(bs, settings.gravity)
	bswrite.bool(bs, settings.lanMode)
	bswrite.int32(bs, settings.deathMoneyDrop)
	bswrite.bool(bs, settings.instagib)
	bswrite.int32(bs, settings.normalOnfootSendrate)
	bswrite.int32(bs, settings.normalIncarSendrate)
	bswrite.int32(bs, settings.normalFiringSendrate)
	bswrite.int32(bs, settings.sendMultiplier)
	bswrite.int32(bs, settings.lagCompMode)
	bswrite.string8(bs, data[2]) -- hostName
	for i = 1, 212 do
		bswrite.int8(bs, vehicleModels[i])
	end
	bswrite.int32(bs, settings.vehicleFriendlyFire)
end

--- onInitMenu
function handler.rpc_init_menu_reader(bs)
	local colWidth2
	local rows = {}
	local columns = {}
	local readColumn = function(width)
		local title = bsread.fixedString32(bs)
		local rowCount = bsread.int8(bs)
		local column = {title = title, width = width, text = {}}
		for i = 1, rowCount do
			column.text[i] = bsread.fixedString32(bs)
		end
		return column
	end
	local menuId = bsread.int8(bs)
	local twoColumns = bsread.bool32(bs)
	local menuTitle = bsread.fixedString32(bs)
	local x = bsread.float(bs)
	local y = bsread.float(bs)
	local colWidth1 = bsread.float(bs)
	if twoColumns then
		colWidth2 = bsread.float(bs)
	end
	local menu = bsread.bool32(bs)
	for i = 1, 12 do
		rows[i] = bsread.int32(bs)
	end
	columns[1] = readColumn(colWidth1)
	if twoColumns then
		columns[2] = readColumn(colWidth2)
	end
	return {menuId, menuTitle, x, y, twoColumns, columns, rows, menu}
end

function handler.rpc_init_menu_writer(bs, data)
	local columns = data[6]
	bswrite.int8(bs, data[1])      -- menuId
	bswrite.bool32(bs, data[5])    -- twoColumns
	bswrite.fixedString32(bs, data[2]) -- title
	bswrite.float(bs, data[3])     -- x
	bswrite.float(bs, data[4])     -- y
	-- columns width
	bswrite.float(bs, columns[1].width)
	if data[5] then
		bswrite.float(bs, columns[2].width)
	end
	bswrite.bool32(bs, data[8]) -- menu
	 -- rows
	for i = 1, 12 do
		bswrite.int32(bs, data[7][i])
	end
	-- columns
	for i = 1, (data[5] and 2 or 1) do
		bswrite.fixedString32(bs, columns[i].title)
		bswrite.int8(bs, #columns[i].text)
		for r, t in ipairs(columns[i].text) do
			bswrite.fixedString32(bs, t)
		end
	end
end

--- onMarkersSync
function handler.packet_markers_sync_reader(bs)
	local markers = {}
	local players = bsread.int32(bs)
	for i = 1, players do
		local playerId = bsread.int16(bs)
		local active = bsread.bool(bs)
		if active then
			local coords = bsread.shortVector3d(bs)
			table.insert(markers, {playerId = playerId, active = true, coords = coords})
		else
			table.insert(markers, {playerId = playerId, active = false})
		end
	end
	return {markers}
end

function handler.packet_markers_sync_writer(bs, data)
	bswrite.int32(bs, #data)
	for i = 1, #data do
		local it = data[i]
		bswrite.int16(bs, it.playerId)
		bswrite.bool(bs, it.active)
		if it.active then
			bswrite.shortVector3d(data.coords)
		end
	end
end

--- onPlayerSync
function handler.packet_player_sync_reader(bs)
	local has_value = bsread.bool
	local data = utils.create_sync_data('PlayerSyncData')
	local playerId = bsread.int16(bs)
	if has_value(bs) then
		data.leftRightKeys = bsread.int16(bs)
	else
		data.leftRightKeys = 0
	end
	if has_value(bs) then
		data.upDownKeys = bsread.int16(bs)
	else
		data.upDownKeys = 0
	end
	data.keysData = bsread.int16(bs)
	local pos = bsread.vector3d(bs)
	data.position = {pos.x, pos.y, pos.z}
	data.quaternion = bsread.normQuat(bs)
	data.health, data.armor = utils.decompress_health_and_armor(bsread.int8(bs))
	data.weapon, data.specialKey = utils.decompress_weapon_and_special_key(bsread.int8(bs))
	data.specialAction = bsread.int8(bs)
	local speed = bsread.compressedVector(bs)
	data.moveSpeed = {speed.x, speed.y, speed.z}
	if has_value(bs) then
		data.surfingVehicleId = bsread.int16(bs)
		local surf = bsread.vector3d(bs)
		data.surfingOffsets = {surf.x, surf.y, surf.z}
	else
		data.surfingVehicleId = 0
	end
	if has_value(bs) then
		data.animationData = bsread.int32(bs)
	end
	return {playerId, data}
end

function handler.packet_player_sync_writer(bs, data)
	local playerId = data[1]
	local data = data[2]
	bswrite.int16(bs, playerId)
	bswrite.bool(bs, data.leftRightKeys ~= 0)
	if data.leftRightKeys ~= 0 then
		bswrite.int16(bs, data.leftRightKeys)
	end
	bswrite.bool(bs, data.upDownKeys ~= 0)
	if data.upDownKeys ~= 0 then
		bswrite.int16(bs, data.upDownKeys)
	end
	bswrite.int16(bs, data.keysData)
	bswrite.vector3d(bs, data.position)
	local quat = data.quaternion
	bswrite.normQuat(bs, {quat[0], quat[1], quat[2], quat[3]})
	bswrite.int8(bs, utils.compress_health_and_armor(data.health, data.armor))
	bswrite.int8(bs, utils.compress_weapon_and_special_key(data.weapon, data.specialKey))
	bswrite.int8(bs, data.specialAction)
	bswrite.compressedVector(bs, data.moveSpeed)
	bswrite.bool(bs, data.surfingVehicleId ~= 0)
	if data.surfingVehicleId ~= 0 then
		bswrite.int16(bs, data.surfingVehicleId)
		bswrite.vector3d(bs, data.surfingOffsets)
	end
	bswrite.bool(bs, data.animationData ~= 0)
	if data.animationData ~= 0 then
		bswrite.int32(bs, data.animationData)
	end
end

--- onVehicleSync
function handler.packet_vehicle_sync_reader(bs)
	local data = utils.create_sync_data('VehicleSyncData')
	local playerId = bsread.int16(bs)
	data.vehicleId = bsread.int16(bs)
	data.leftRightKeys = bsread.int16(bs)
	data.upDownKeys = bsread.int16(bs)
	data.keysData = bsread.int16(bs)
	data.quaternion = bsread.normQuat(bs)
	local pos = bsread.vector3d(bs)
	data.position = {pos.x, pos.y, pos.z}
	local speed = bsread.compressedVector(bs)
	data.moveSpeed = {speed.x, speed.y, speed.z}
	data.vehicleHealth = bsread.int16(bs)
	data.playerHealth, data.armor = utils.decompress_health_and_armor(bsread.int8(bs))
	data.weapon, data.specialKey = utils.decompress_weapon_and_special_key(bsread.int8(bs))
	data.siren = bsread.bool(bs)
	data.landingGearState = bsread.bool(bs)
	if bsread.bool(bs) then
		data.trainSpeed = bsread.float(bs)
	else
		data.trainSpeed = 0
	end
	if bsread.bool(bs) then
		data.trailerId = bsread.int16(bs)
	else
		data.trailerId = 0
	end
	return {playerId, data.vehicleId, data}
end

function handler.packet_vehicle_sync_writer(bs, data)
	local playerId = data[1]
	local vehicleId = data[2]
	local data = data[3]
	bswrite.int16(bs, playerId)
	bswrite.int16(bs, vehicleId)
	bswrite.int16(bs, data.leftRightKeys)
	bswrite.int16(bs, data.upDownKeys)
	bswrite.int16(bs, data.keysData)
	local quat = data.quaternion
	bswrite.normQuat(bs, {quat[0], quat[1], quat[2], quat[3]})
	bswrite.vector3d(bs, data.position)
	bswrite.compressedVector(bs, data.moveSpeed)
	bswrite.int16(bs, data.vehicleHealth)
	bswrite.int8(bs, utils.compress_health_and_armor(data.playerHealth, data.armor))
	bswrite.int8(bs, utils.compress_weapon_and_special_key(data.weapon, data.specialKey))
	bswrite.bool(bs, data.siren)
	bswrite.bool(bs, data.landingGearState)
	bswrite.bool(bs, data.trainSpeed ~= 0.0)
	if data.trainSpeed ~= 0.0 then
		bswrite.float(bs, data.trainSpeed)
	end
	bswrite.bool(bs, data.trailerId ~= 0)
	if data.trailerId ~= 0 then
		bswrite.int16(bs, data.trailerId)
	end
end

--- onVehicleStreamIn
function handler.rpc_vehicle_stream_in_reader(bs)
	local data = {modSlots = {}}
	local vehicleId = bsread.int16(bs)
	data.type = bsread.int32(bs)
	data.position = bsread.vector3d(bs)
	data.rotation = bsread.float(bs)
	data.interiorColor1 = bsread.int8(bs)
	data.interiorColor2 = bsread.int8(bs)
	data.health = bsread.float(bs)
	data.interiorId = bsread.int8(bs)
	data.doorDamageStatus = bsread.int32(bs)
	data.panelDamageStatus = bsread.int32(bs)
	data.lightDamageStatus = bsread.int8(bs)
	data.tireDamageStatus = bsread.int8(bs)
	data.addSiren = bsread.int8(bs)
	for i = 1, 14 do
		data.modSlots[i] = bsread.int8(bs)
	end
	data.paintJob = bsread.int8(bs)
	data.bodyColor1 = bsread.int32(bs)
	data.bodyColor2 = bsread.int32(bs)
	return {vehicleId, data}
end

function handler.rpc_vehicle_stream_in_writer(bs, data)
	local vehicleId = data[1]
	local data = data[2]
	bswrite.int16(bs, vehicleId)
	bswrite.int32(bs, data.type)
	bswrite.vector3d(bs, data.position)
	bswrite.float(bs, data.rotation)
	bswrite.int8(bs, data.interiorColor1)
	bswrite.int8(bs, data.interiorColor2)
	bswrite.float(bs, data.health)
	bswrite.int8(bs, data.interiorId)
	bswrite.int32(bs, data.doorDamageStatus)
	bswrite.int32(bs, data.panelDamageStatus)
	bswrite.int8(bs, data.lightDamageStatus)
	bswrite.int8(bs, data.tireDamageStatus)
	bswrite.int8(bs, data.addSiren)
	for i = 1, 14 do
		bswrite.int8(bs, data.modSlots[i])
	end
	bswrite.int8(bs, data.paintJob)
	bswrite.int32(bs, data.bodyColor1)
	bswrite.int32(bs, data.bodyColor2)
end

local MATERIAL_TYPE = {
	NONE = 0,
	TEXTURE = 1,
	TEXT = 2,
}

local function read_object_material(bs)
	local data = {}
	data.materialId = bsread.int8(bs)
	data.modelId = bsread.int16(bs)
	data.libraryName = bsread.string8(bs)
	data.textureName = bsread.string8(bs)
	data.color = bsread.int32(bs)
	data.type = MATERIAL_TYPE.TEXTURE
	return data
end

local function write_object_material(bs, data)
	bswrite.int8(bs, data.type)
	bswrite.int8(bs, data.materialId)
	bswrite.int16(bs, data.modelId)
	bswrite.string8(bs, data.libraryName)
	bswrite.string8(bs, data.textureName)
	bswrite.int32(bs, data.color)
end

local function read_object_material_text(bs)
	local data = {}
	data.materialId = bsread.int8(bs)
	data.materialSize = bsread.int8(bs)
	data.fontName = bsread.string8(bs)
	data.fontSize = bsread.int8(bs)
	data.bold = bsread.int8(bs)
	data.fontColor = bsread.int32(bs)
	data.backGroundColor = bsread.int32(bs)
	data.align = bsread.int8(bs)
	data.text = bsread.encodedString2048(bs)
	data.type = MATERIAL_TYPE.TEXT
	return data
end

local function write_object_material_text(bs, data)
	bswrite.int8(bs, data.type)
	bswrite.int8(bs, data.materialId)
	bswrite.int8(bs, data.materialSize)
	bswrite.string8(bs, data.fontName)
	bswrite.int8(bs, data.fontSize)
	bswrite.int8(bs, data.bold)
	bswrite.int32(bs, data.fontColor)
	bswrite.int32(bs, data.backGroundColor)
	bswrite.int8(bs, data.align)
	bswrite.encodedString2048(bs, data.text)
end

--- onSetObjectMaterial
function handler.rpc_set_object_material_reader(bs)
	local objectId = bsread.int16(bs)
	local materialType = bsread.int8(bs)
	local material
	if materialType == MATERIAL_TYPE.TEXTURE then
		material = read_object_material(bs)
	elseif materialType == MATERIAL_TYPE.TEXT then
		material = read_object_material_text(bs)
	end
	local ev = materialType == MATERIAL_TYPE.TEXTURE and 'onSetObjectMaterial' or 'onSetObjectMaterialText'
	return ev, {objectId, material}
end

function handler.rpc_set_object_material_writer(bs, data)
	local objectId = data[1]
	local mat = data[2]
	bswrite.int16(bs, objectId)
	if mat.type == MATERIAL_TYPE.TEXTURE then
		write_object_material(bs, mat)
	elseif mat.type == MATERIAL_TYPE.TEXT then
		write_object_material_text(bs, mat)
	end
end

--- onCreateObject
function handler.rpc_create_object_reader(bs)
	local data = {materials = {}, materialText = {}}
	local objectId = bsread.int16(bs)
	data.modelId = bsread.int32(bs)
	data.position = bsread.vector3d(bs)
	data.rotation = bsread.vector3d(bs)
	data.drawDistance = bsread.float(bs)
	data.noCameraCol = bsread.bool8(bs)
	data.attachToVehicleId = bsread.int16(bs)
	data.attachToObjectId = bsread.int16(bs)
	if data.attachToVehicleId ~= 0xFFFF or data.attachToObjectId ~= 0xFFFF then
		data.attachOffsets = bsread.vector3d(bs)
		data.attachRotation = bsread.vector3d(bs)
		data.syncRotation = bsread.bool8(bs)
	end
	data.texturesCount = bsread.int8(bs)
	while raknetBitStreamGetNumberOfUnreadBits(bs) >= 8 do
		local materialType = bsread.int8(bs)
		if materialType == MATERIAL_TYPE.TEXTURE then
			table.insert(data.materials, read_object_material(bs))
		elseif materialType == MATERIAL_TYPE.TEXT then
			table.insert(data.materialText, read_object_material_text(bs))
		end
	end
	data.materials_text = data.materialText -- obsolete
	return {objectId, data}
end

function handler.rpc_create_object_writer(bs, data)
	local objectId = data[1]
	local data = data[2]
	bswrite.int16(bs, objectId)
	bswrite.int32(bs, data.modelId)
	bswrite.vector3d(bs, data.position)
	bswrite.vector3d(bs, data.rotation)
	bswrite.float(bs, data.drawDistance)
	bswrite.bool8(bs, data.noCameraCol)
	bswrite.int16(bs, data.attachToVehicleId)
	bswrite.int16(bs, data.attachToObjectId)
	if data.attachToVehicleId ~= 0xFFFF or data.attachToObjectId ~= 0xFFFF then
		bswrite.vector3d(bs, data.attachOffsets)
		bswrite.vector3d(bs, data.attachRotation)
		bswrite.bool8(bs, data.syncRotation)
	end
	bswrite.int8(bs, data.texturesCount)
	for _, it in ipairs(data.materials) do
		write_object_material(bs, it)
	end
	for _, it in ipairs(data.materialText) do
		write_object_material_text(bs, it)
	end
end

function handler.rpc_update_scores_and_pings_reader(bs)
	local data = {}
	for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) / 10 do
		local playerId = bsread.int16(bs)
		local playerScore = bsread.int32(bs)
		local playerPing = bsread.int32(bs)
		data[playerId] = {score = playerScore, ping = playerPing}
	end
	return {data}
end

function handler.rpc_update_scores_and_pings_writer(bs, data)
	for id, info in pairs(data[1]) do
		bswrite.int16(bs, id)
		bswrite.int32(bs, info.score)
		bswrite.int32(bs, info.ping)
	end
end

function handler.packet_weapons_update_reader(bs)
	local playerTarget = bsread.int16(bs)
	local actorTarget = bsread.int16(bs)
	local weapons = {}
	local count = raknetBitStreamGetNumberOfUnreadBits(bs) / 32
	for i = 1, count do
		local slot = bsread.int8(bs)
		local weapon = bsread.int8(bs)
		local ammo = bsread.int16(bs)
		weapons[i] = {slot = slot, weapon = weapon, ammo = ammo}
	end
	return {playerTarget, actorTarget, weapons}
end

function handler.packet_weapons_update_writer(bs, data)
	bswrite.int16(bs, data[1])
	bswrite.int16(bs, data[2])
	for i, weap in ipairs(data[3]) do
		bswrite.int8(bs, weap.slot)
		bswrite.int8(bs, weap.weapon)
		bswrite.int16(bs, weap.ammo)
	end
end

return handler
