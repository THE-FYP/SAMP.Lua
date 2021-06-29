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
		bsread.uint16(bs), -- playerId
		bsread.float(bs), -- damage
		bsread.int32(bs), -- weapon
		bsread.int32(bs), -- bodypart
		take,
	}
	return (take and 'onSendTakeDamage' or 'onSendGiveDamage'), data
end

function handler.rpc_send_give_take_damage_writer(bs, data)
	bswrite.bool(bs, data[5]) -- give or take
	bswrite.uint16(bs, data[1]) -- playerId
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
	local playerId                 = bsread.uint16(bs)
	settings.showPlayerTags        = bsread.bool(bs)
	settings.playerMarkersMode     = bsread.int32(bs)
	settings.worldTime             = bsread.uint8(bs)
	settings.worldWeather          = bsread.uint8(bs)
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
	for i = 0, 212 - 1 do
		vehicleModels[i] = bsread.uint8(bs)
	end
	settings.vehicleFriendlyFire = bsread.bool32(bs)
	return {playerId, hostName, settings, vehicleModels, settings.vehicleFriendlyFire}
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
	bswrite.uint16(bs, data[1]) -- playerId
	bswrite.bool(bs, settings.showPlayerTags)
	bswrite.int32(bs, settings.playerMarkersMode)
	bswrite.uint8(bs, settings.worldTime)
	bswrite.uint8(bs, settings.worldWeather)
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
		bswrite.uint8(bs, vehicleModels[i])
	end
	bswrite.bool32(bs, settings.vehicleFriendlyFire)
end

--- onInitMenu
function handler.rpc_init_menu_reader(bs)
	local colWidth2
	local rows = {}
	local columns = {}
	local readColumn = function(width)
		local title = bsread.fixedString32(bs)
		local rowCount = bsread.uint8(bs)
		local column = {title = title, width = width, text = {}}
		for i = 1, rowCount do
			column.text[i] = bsread.fixedString32(bs)
		end
		return column
	end
	local menuId = bsread.uint8(bs)
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
	bswrite.uint8(bs, data[1])      -- menuId
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
		bswrite.uint8(bs, #columns[i].text)
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
		local playerId = bsread.uint16(bs)
		local active = bsread.bool(bs)
		if active then
			local vector3d = require 'vector3d'
			local x, y, z = bsread.int16(bs), bsread.int16(bs), bsread.int16(bs)
			table.insert(markers, {playerId = playerId, active = true, coords = vector3d(x, y, z)})
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
		bswrite.uint16(bs, it.playerId)
		bswrite.bool(bs, it.active)
		if it.active then
			bswrite.uint16(bs, it.coords.x)
			bswrite.uint16(bs, it.coords.y)
			bswrite.uint16(bs, it.coords.z)
		end
	end
end

--- onPlayerSync
function handler.packet_player_sync_reader(bs)
	local has_value = bsread.bool
	local data = {}
	local playerId = bsread.uint16(bs)
	if has_value(bs) then data.leftRightKeys = bsread.uint16(bs) end
	if has_value(bs) then data.upDownKeys = bsread.uint16(bs) end
	data.keysData = bsread.uint16(bs)
	data.position = bsread.vector3d(bs)
	data.quaternion = bsread.normQuat(bs)
	data.health, data.armor = utils.decompress_health_and_armor(bsread.uint8(bs))
	data.weapon = bsread.uint8(bs)
	data.specialAction = bsread.uint8(bs)
	data.moveSpeed = bsread.compressedVector(bs)
	if has_value(bs) then
		data.surfingVehicleId = bsread.uint16(bs)
		data.surfingOffsets = bsread.vector3d(bs)
	end
	if has_value(bs) then
		data.animationId = bsread.uint16(bs)
		data.animationFlags = bsread.uint16(bs)
	end
	return {playerId, data}
end

function handler.packet_player_sync_writer(bs, data)
	local playerId = data[1]
	local data = data[2]
	bswrite.uint16(bs, playerId)
	bswrite.bool(bs, data.leftRightKeys ~= nil)
	if data.leftRightKeys then bswrite.uint16(bs, data.leftRightKeys) end
	bswrite.bool(bs, data.upDownKeys ~= nil)
	if data.upDownKeys then bswrite.uint16(bs, data.upDownKeys) end
	bswrite.uint16(bs, data.keysData)
	bswrite.vector3d(bs, data.position)
	bswrite.normQuat(bs, data.quaternion)
	bswrite.uint8(bs, utils.compress_health_and_armor(data.health, data.armor))
	bswrite.uint8(bs, data.weapon)
	bswrite.uint8(bs, data.specialAction)
	bswrite.compressedVector(bs, data.moveSpeed)
	bswrite.bool(bs, data.surfingVehicleId ~= nil)
	if data.surfingVehicleId then
		bswrite.uint16(bs, data.surfingVehicleId)
		bswrite.vector3d(bs, data.surfingOffsets)
	end
	bswrite.bool(bs, data.animationId ~= nil)
	if data.animationId then
		bswrite.uint16(bs, data.animationId)
		bswrite.uint16(bs, data.animationFlags)
	end
end

--- onVehicleSync
function handler.packet_vehicle_sync_reader(bs)
	local data = {}
	local playerId = bsread.uint16(bs)
	local vehicleId = bsread.uint16(bs)
	data.leftRightKeys = bsread.uint16(bs)
	data.upDownKeys = bsread.uint16(bs)
	data.keysData = bsread.uint16(bs)
	data.quaternion = bsread.normQuat(bs)
	data.position = bsread.vector3d(bs)
	data.moveSpeed = bsread.compressedVector(bs)
	data.vehicleHealth = bsread.uint16(bs)
	data.playerHealth, data.armor = utils.decompress_health_and_armor(bsread.uint8(bs))
	data.currentWeapon = bsread.uint8(bs)
	data.siren = bsread.bool(bs)
	data.landingGear = bsread.bool(bs)
	if bsread.bool(bs) then
		data.trainSpeed = bsread.int32(bs)
	end
	if bsread.bool(bs) then
		data.trailerId = bsread.uint16(bs)
	end
	return {playerId, vehicleId, data}
end

function handler.packet_vehicle_sync_writer(bs, data)
	local playerId = data[1]
	local vehicleId = data[2]
	local data = data[3]
	bswrite.uint16(bs, playerId)
	bswrite.uint16(bs, vehicleId)
	bswrite.uint16(bs, data.leftRightKeys)
	bswrite.uint16(bs, data.upDownKeys)
	bswrite.uint16(bs, data.keysData)
	bswrite.normQuat(bs, data.quaternion)
	bswrite.vector3d(bs, data.position)
	bswrite.compressedVector(bs, data.moveSpeed)
	bswrite.uint16(bs, data.vehicleHealth)
	bswrite.uint8(bs, utils.compress_health_and_armor(data.playerHealth, data.armor))
	bswrite.uint8(bs, data.currentWeapon)
	bswrite.bool(bs, data.siren)
	bswrite.bool(bs, data.landingGear)
	bswrite.bool(bs, data.trainSpeed ~= nil)
	if data.trainSpeed ~= nil then
		bswrite.int32(bs, data.trainSpeed)
	end
	bswrite.bool(bs, data.trailerId ~= nil)
	if data.trailerId ~= nil then
		bswrite.uint16(bs, data.trailerId)
	end
end

--- onVehicleStreamIn
function handler.rpc_vehicle_stream_in_reader(bs)
	local data = {modSlots = {}}
	local vehicleId = bsread.uint16(bs)
	data.type = bsread.int32(bs)
	data.position = bsread.vector3d(bs)
	data.rotation = bsread.float(bs)
	data.bodyColor1 = bsread.uint8(bs)
	data.bodyColor2 = bsread.uint8(bs)
	data.health = bsread.float(bs)
	data.interiorId = bsread.uint8(bs)
	data.doorDamageStatus = bsread.int32(bs)
	data.panelDamageStatus = bsread.int32(bs)
	data.lightDamageStatus = bsread.uint8(bs)
	data.tireDamageStatus = bsread.uint8(bs)
	data.addSiren = bsread.uint8(bs)
	for i = 1, 14 do
		data.modSlots[i] = bsread.uint8(bs)
	end
	data.paintJob = bsread.uint8(bs)
	data.interiorColor1 = bsread.int32(bs)
	data.interiorColor2 = bsread.int32(bs)
	return {vehicleId, data}
end

function handler.rpc_vehicle_stream_in_writer(bs, data)
	local vehicleId = data[1]
	local data = data[2]
	bswrite.uint16(bs, vehicleId)
	bswrite.int32(bs, data.type)
	bswrite.vector3d(bs, data.position)
	bswrite.float(bs, data.rotation)
	bswrite.uint8(bs, data.bodyColor1)
	bswrite.uint8(bs, data.bodyColor2)
	bswrite.float(bs, data.health)
	bswrite.uint8(bs, data.interiorId)
	bswrite.int32(bs, data.doorDamageStatus)
	bswrite.int32(bs, data.panelDamageStatus)
	bswrite.uint8(bs, data.lightDamageStatus)
	bswrite.uint8(bs, data.tireDamageStatus)
	bswrite.uint8(bs, data.addSiren)
	for i = 1, 14 do
		bswrite.uint8(bs, data.modSlots[i])
	end
	bswrite.uint8(bs, data.paintJob)
	bswrite.int32(bs, data.interiorColor1)
	bswrite.int32(bs, data.interiorColor2)
end

local MATERIAL_TYPE = {
	NONE = 0,
	TEXTURE = 1,
	TEXT = 2,
}

local function read_object_material(bs)
	local data = {}
	data.materialId = bsread.uint8(bs)
	data.modelId = bsread.uint16(bs)
	data.libraryName = bsread.string8(bs)
	data.textureName = bsread.string8(bs)
	data.color = bsread.int32(bs)
	data.type = MATERIAL_TYPE.TEXTURE
	return data
end

local function write_object_material(bs, data)
	bswrite.uint8(bs, data.type)
	bswrite.uint8(bs, data.materialId)
	bswrite.uint16(bs, data.modelId)
	bswrite.string8(bs, data.libraryName)
	bswrite.string8(bs, data.textureName)
	bswrite.int32(bs, data.color)
end

local function read_object_material_text(bs)
	local data = {}
	data.materialId = bsread.uint8(bs)
	data.materialSize = bsread.uint8(bs)
	data.fontName = bsread.string8(bs)
	data.fontSize = bsread.uint8(bs)
	data.bold = bsread.uint8(bs)
	data.fontColor = bsread.int32(bs)
	data.backGroundColor = bsread.int32(bs)
	data.align = bsread.uint8(bs)
	data.text = bsread.encodedString2048(bs)
	data.type = MATERIAL_TYPE.TEXT
	return data
end

local function write_object_material_text(bs, data)
	bswrite.uint8(bs, data.type)
	bswrite.uint8(bs, data.materialId)
	bswrite.uint8(bs, data.materialSize)
	bswrite.string8(bs, data.fontName)
	bswrite.uint8(bs, data.fontSize)
	bswrite.uint8(bs, data.bold)
	bswrite.int32(bs, data.fontColor)
	bswrite.int32(bs, data.backGroundColor)
	bswrite.uint8(bs, data.align)
	bswrite.encodedString2048(bs, data.text)
end

--- onSetObjectMaterial
function handler.rpc_set_object_material_reader(bs)
	local objectId = bsread.uint16(bs)
	local materialType = bsread.uint8(bs)
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
	bswrite.uint16(bs, objectId)
	if mat.type == MATERIAL_TYPE.TEXTURE then
		write_object_material(bs, mat)
	elseif mat.type == MATERIAL_TYPE.TEXT then
		write_object_material_text(bs, mat)
	end
end

--- onCreateObject
function handler.rpc_create_object_reader(bs)
	local data = {materials = {}, materialText = {}}
	local objectId = bsread.uint16(bs)
	data.modelId = bsread.int32(bs)
	data.position = bsread.vector3d(bs)
	data.rotation = bsread.vector3d(bs)
	data.drawDistance = bsread.float(bs)
	data.noCameraCol = bsread.bool8(bs)
	data.attachToVehicleId = bsread.uint16(bs)
	data.attachToObjectId = bsread.uint16(bs)
	if data.attachToVehicleId ~= 0xFFFF or data.attachToObjectId ~= 0xFFFF then
		data.attachOffsets = bsread.vector3d(bs)
		data.attachRotation = bsread.vector3d(bs)
		data.syncRotation = bsread.bool8(bs)
	end
	data.texturesCount = bsread.uint8(bs)
	while raknetBitStreamGetNumberOfUnreadBits(bs) >= 8 do
		local materialType = bsread.uint8(bs)
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
	bswrite.uint16(bs, objectId)
	bswrite.int32(bs, data.modelId)
	bswrite.vector3d(bs, data.position)
	bswrite.vector3d(bs, data.rotation)
	bswrite.float(bs, data.drawDistance)
	bswrite.bool8(bs, data.noCameraCol)
	bswrite.uint16(bs, data.attachToVehicleId)
	bswrite.uint16(bs, data.attachToObjectId)
	if data.attachToVehicleId ~= 0xFFFF or data.attachToObjectId ~= 0xFFFF then
		bswrite.vector3d(bs, data.attachOffsets)
		bswrite.vector3d(bs, data.attachRotation)
		bswrite.bool8(bs, data.syncRotation)
	end
	bswrite.uint8(bs, data.texturesCount)
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
		local playerId = bsread.uint16(bs)
		local playerScore = bsread.int32(bs)
		local playerPing = bsread.int32(bs)
		data[playerId] = {score = playerScore, ping = playerPing}
	end
	return {data}
end

function handler.rpc_update_scores_and_pings_writer(bs, data)
	for id, info in pairs(data[1]) do
		bswrite.uint16(bs, id)
		bswrite.int32(bs, info.score)
		bswrite.int32(bs, info.ping)
	end
end

function handler.packet_weapons_update_reader(bs)
	local playerTarget = bsread.uint16(bs)
	local actorTarget = bsread.uint16(bs)
	local weapons = {}
	local count = raknetBitStreamGetNumberOfUnreadBits(bs) / 32
	for i = 1, count do
		local slot = bsread.uint8(bs)
		local weapon = bsread.uint8(bs)
		local ammo = bsread.uint16(bs)
		weapons[i] = {slot = slot, weapon = weapon, ammo = ammo}
	end
	return {playerTarget, actorTarget, weapons}
end

function handler.packet_weapons_update_writer(bs, data)
	bswrite.uint16(bs, data[1])
	bswrite.uint16(bs, data[2])
	for i, weap in ipairs(data[3]) do
		bswrite.uint8(bs, weap.slot)
		bswrite.uint8(bs, weap.weapon)
		bswrite.uint16(bs, weap.ammo)
	end
end

return handler
