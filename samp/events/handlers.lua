-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua


local BitStreamIO = require 'lib.samp.events.bitstream_io'
local utils = require 'lib.samp.events.utils'
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


--- onInitGame
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


--- onInitMenu
function handler.on_init_menu_reader(bs)
	local read = BitStreamIO.bs_read
	local colWidth2
	local rows = {}
	local columns = {}

	local readColumn = function(width)
		local title = read.string256(bs)
		local rowCount = read.int8(bs)
		local column = {title = title, width = width, text = {}}
		for i = 1, rowCount do
			column.text[i] = read.string256(bs)
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
	local read = BitStreamIO.bs_read
	local markers = {}
	local players = read.int32(bs)
	for i = 1, players do
		local playerId = read.int16(bs)
		local active = read.bool(bs)
		if active then
			local Vector3D = require 'lib.vector3d'
			local x, y, z = read.int16(bs), read.int16(bs), read.int16(bs)
			table.insert(markers, {playerId = playerId, active = true, coords = Vector3D(x, y, z)})
		else
			table.insert(markers, {playerId = playerId, active = false})
		end
	end
	return {markers}
end

function handler.on_markers_sync_writer(bs, data)
	local write = BitStreamIO.bs_write
	write.int32(bs, #data)
	for i = 1, #data do
		local it = data[i]
		write.int16(bs, it.playerId)
		write.bool(bs, it.active)
		if it.active then
			write.int16(bs, it.coords.x)
			write.int16(bs, it.coords.y)
			write.int16(bs, it.coords.z)
		end
	end
end


--- onPlayerSync
function handler.on_player_sync_reader(bs)
	local read = BitStreamIO.bs_read
	local has_value = read.bool
	local data = {}
	local playerId = read.int16(bs)
	if has_value(bs) then data.leftRightKeys = read.int16(bs) end
	if has_value(bs) then data.upDownKeys = read.int16(bs) end
	data.keysData = read.int16(bs)
	data.position = read.vector3d(bs)
	data.quaternion = read.normQuat(bs)
	data.health, data.armor = utils.decompress_health_and_armor(read.int8(bs))
	data.weapon = read.int8(bs)
	data.specialAction = read.int8(bs)
	data.moveSpeed = read.compressedVector(bs)
	if has_value(bs) then
		data.surfingVehicleId = read.int16(bs)
		data.surfingOffsets = read.vector3d(bs)
	end
	if has_value(bs) then
		data.animationId = read.int16(bs)
		data.animationFlags = read.int16(bs)
	end
	return {playerId, data}
end

function handler.on_player_sync_writer(bs, data)
	local write = BitStreamIO.bs_write
	local playerId = data[1]
	local data = data[2]
	write.int16(bs, playerId)
	write.bool(bs, data.leftRightKeys ~= nil)
	if data.leftRightKeys then write.int16(bs, data.leftRightKeys) end
	write.bool(bs, data.upDownKeys ~= nil)
	if data.upDownKeys then write.int16(bs, data.upDownKeys) end
	write.int16(bs, data.keysData)
	write.vector3d(bs, data.position)
	write.normQuat(bs, data.quaternion)
	write.int8(bs, utils.compress_health_and_armor(data.health, data.armor))
	write.int8(bs, data.weapon)
	write.int8(bs, data.specialAction)
	write.compressedVector(bs, data.moveSpeed)
	write.bool(bs, data.surfingVehicleId ~= nil)
	if data.surfingVehicleId then
		write.int16(bs, data.surfingVehicleId)
		write.vector3d(bs, data.surfingOffsets)
	end
	write.bool(bs, data.animationId ~= nil)
	if data.animationId then
		write.int16(bs, data.animationId)
		write.int16(bs, data.animationFlags)
	end
end


--- onVehicleSync
function handler.on_vehicle_sync_reader(bs)
	local read = BitStreamIO.bs_read
	local data = {}
	local playerId = read.int16(bs)
	local vehicleId = read.int16(bs)
	data.leftRightKeys = read.int16(bs)
	data.upDownKeys = read.int16(bs)
	data.keysData = read.int16(bs)
	data.quaternion = read.normQuat(bs)
	data.position = read.vector3d(bs)
	data.moveSpeed = read.compressedVector(bs)
	data.vehicleHealth = read.int16(bs)
	data.playerHealth, data.armor = utils.decompress_health_and_armor(read.int8(bs))
	data.currentWeapon = read.int8(bs)
	data.siren = read.bool(bs)
	data.landingGear = read.bool(bs)
	if read.bool(bs) then
		data.trainSpeed = read.int32(bs)
	end
	if read.bool(bs) then
		data.trailerId = read.int16(bs)
	end
	return {playerId, vehicleId, data}
end

function handler.on_vehicle_sync_writer(bs, data)
	local write = BitStreamIO.bs_write
	local playerId = data[1]
	local vehicleId = data[2]
	local data = data[3]
	write.int16(bs, playerId)
	write.int16(bs, vehicleId)
	write.int16(bs, data.leftRightKeys)
	write.int16(bs, data.upDownKeys)
	write.int16(bs, data.keysData)
	write.normQuat(bs, data.quaternion)
	write.vector3d(bs, data.position)
	write.compressedVector(bs, data.moveSpeed)
	write.int16(bs, data.vehicleHealth)
	write.int8(bs, utils.compress_health_and_armor(data.playerHealth, data.armor))
	write.int8(bs, data.currentWeapon)
	write.bool(bs, data.siren)
	write.bool(bs, data.landingGear)
	write.bool(bs, data.trainSpeed ~= nil)
	if data.trainSpeed ~= nil then
		write.int32(bs, data.trainSpeed)
	end
	write.bool(bs, data.trailerId ~= nil)
	if data.trailerId ~= nil then
		write.int16(bs, data.trailerId)
	end
end


--- onVehicleSteamIn
function handler.on_vehicle_stream_in_reader(bs)
	local read = BitStreamIO.bs_read
	local data = {modSlots = {}}
	local vehicleId = read.int16(bs)
	data.type = read.int32(bs)
	data.position = read.vector3d(bs)
	data.rotation = read.float(bs)
	data.interiorColor1 = read.int8(bs)
	data.interiorColor2 = read.int8(bs)
	data.health = read.float(bs)
	data.interiorId = read.int8(bs)
	data.doorDamageStatus = read.int32(bs)
	data.panelDamageStatus = read.int32(bs)
	data.lightDamageStatus = read.int8(bs)
	data.tireDamageStatus = read.int8(bs)
	data.addSiren = read.int8(bs)
	for i = 1, 14 do data.modSlots[i] = read.int8(bs) end --- fix it
	data.paintJob = read.int8(bs)
	data.bodyColor1 = read.int32(bs)
	data.bodyColor2 = read.int32(bs)
	data.unk = read.int8(bs)
	return {vehicleId, data}
end

function handler.on_vehicle_stream_in_writer(bs, data)
	local write = BitStreamIO.bs_write
	local vehicleId = data[1]
	local data = data[2]
	write.int16(bs, vehicleId)
	write.int32(bs, data.type)
	write.vector3d(bs, data.position)
	write.float(bs, data.rotation)
	write.int8(bs, data.interiorColor1)
	write.int8(bs, data.interiorColor2)
	write.float(bs, data.health)
	write.int8(bs, data.interiorId)
	write.int32(bs, data.doorDamageStatus)
	write.int32(bs, data.panelDamageStatus)
	write.int8(bs, data.lightDamageStatus)
	write.int8(bs, data.tireDamageStatus)
	write.int8(bs, data.addSiren)
	for i = 1, 14 do write.int8(bs, data.modSlots[i]) end --- fix it
	write.int8(bs, data.paintJob)
	write.int32(bs, data.bodyColor1)
	write.int32(bs, data.bodyColor2)
	write.int8(bs, data.unk)
end


--- onShowTextDraw
function handler.on_show_textdraw_reader(bs)
	local read = BitStreamIO.bs_read
	local data = {}
	local textdrawId = read.int16(bs)
	data.flags = read.int8(bs)
	data.letterWidth = read.float(bs)
	data.letterHeight = read.float(bs)
	data.letterColor = read.int32(bs)
	data.lineWidth = read.float(bs)
	data.lineHeight = read.float(bs)
	data.boxColor = read.int32(bs)
	data.shadow = read.int8(bs)
	data.outline = read.int8(bs)
	data.backgroundColor = read.int32(bs)
	data.style = read.int8(bs)
	data.selectable = read.int8(bs)
	data.position = read.vector2d(bs)
	data.modelId = read.int16(bs)
	data.rotation = read.vector3d(bs)
	data.zoom = read.float(bs)
	data.color = read.int32(bs)
	data.text = read.string16(bs)
	return {textdrawId, data}
end

function handler.on_show_textdraw_writer(bs, data)
	local write = BitStreamIO.bs_write
	local textdrawId = data[1]
	local data = data[2]
	write.int16(bs, textdrawId)
	write.int8(bs, data.flags)
	write.float(bs, data.letterWidth)
	write.float(bs, data.letterHeight)
	write.int32(bs, data.letterColor)
	write.float(bs, data.lineWidth)
	write.float(bs, data.lineHeight)
	write.int32(bs, data.boxColor)
	write.int8(bs, data.shadow)
	write.int8(bs, data.outline)
	write.int32(bs, data.backgroundColor)
	write.int8(bs, data.style)
	write.int8(bs, data.selectable)
	write.vector2d(bs, data.position)
	write.int16(bs, data.modelId)
	write.vector3d(bs, data.rotation)
	write.float(bs, data.zoom)
	write.int32(bs, data.color)
	write.string16(bs, data.text)
end

local function read_object_material(bs)
	local read = BitStreamIO.bs_read
	local data = {}
	data.materialId = read.int8(bs)
	data.modelId = read.int16(bs)
	data.libraryName = read.string8(bs)
	data.textureName = read.string8(bs)
	data.color = read.int32(bs)
	return data
end

local function write_object_material(bs, data)
	local write = BitStreamIO.bs_write
	write.int8(bs, 1)
	write.int8(bs, data.materialId)
	write.int16(bs, data.modelId)
	write.string8(bs, data.libraryName)
	write.string8(bs, data.textureName)
	write.int32(bs, data.color)
end

local function read_object_material_text(bs)
	local read = BitStreamIO.bs_read
	local data = {}
	data.materialId = read.int8(bs)
	data.materialSize = read.int8(bs)
	data.fontName = read.string8(bs)
	data.fontSize = read.int8(bs)
	data.bold = read.int8(bs)
	data.fontColor = read.int32(bs)
	data.backGroundColor = read.int32(bs)
	data.align = read.int8(bs)
	data.text = read.encodedString2048(bs)
	return data
end

local function write_object_material_text(bs, data)
	local write = BitStreamIO.bs_write
	write.int8(bs, 2)
	write.int8(bs, data.materialId)
	write.int8(bs, data.materialSize)
	write.string8(bs, data.fontName)
	write.int8(bs, data.fontSize)
	write.int8(bs, data.bold)
	write.int32(bs, data.fontColor)
	write.int32(bs, data.backGroundColor)
	write.int8(bs, data.align)
	write.encodedString2048(bs, data.text)
end


--- onSetObjectMaterial
function handler.on_set_object_material_reader(bs, t)
	local read = BitStreamIO.bs_read
	local objectId = read.int16(bs)
	local actionType = read.int8(bs)
	if actionType ~= t then return false end
	local material
	if actionType == 1 then
		material = read_object_material(bs)
	elseif actionType == 2 then
		material = read_object_material_text(bs)
	end
	return {objectId, material}
end

function handler.on_set_object_material_writer(bs, data, t)
	local write = BitStreamIO.bs_write
	local objectId = data[1]
	local data = data[2]
	write.int16(bs, objectId)
	if t == 1 then
		write_object_material(bs, data)
	elseif t == 2 then
		write_object_material_text(bs, data)
	end
end


--- onCreateObject
function handler.on_create_object_reader(bs)
	local read = BitStreamIO.bs_read
	local data = {materials = {}, materials_text = {}}
	local objectId = read.int16(bs)
	data.modelId = read.int32(bs)
	data.position = read.vector3d(bs)
	data.rotation = read.vector3d(bs)
	data.drawDistance = read.float(bs)
	data.unk1 = read.int8(bs)
	data.attachToVehicleId = read.int16(bs)
	data.attachToPlayerId = read.int16(bs)
	if data.attachToVehicleId ~= 65535 or data.attachToPlayerId ~= 65535 then
		data.attachOffsets = read.vector3d(bs)
		data.attachRotation = read.vector3d(bs)
		data.unk2 = read.int8(bs)
	end
	data.texturesCount = read.int8(bs)

	local actionType = 0
	while raknetBitStreamGetNumberOfUnreadBits(bs) > 0 do
		actionType = read.int8(bs)
		if actionType == 1 then
			table.insert(data.materials, read_object_material(bs))
		elseif actionType == 2 then
			table.insert(data.materials_text, read_object_material_text(bs))
		end
	end
	return {objectId, data}
end

function handler.on_create_object_writer(bs, data)
	local write = BitStreamIO.bs_write
	local objectId = data[1]
	local data = data[2]
	write.int16(bs, objectId)
	write.int32(bs, data.modelId)
	write.vector3d(bs, data.position)
	write.vector3d(bs, data.rotation)
	write.float(bs, data.drawDistance)
	write.int8(bs, data.unk1)
	write.int16(bs, data.attachToVehicleId)
	write.int16(bs, data.attachToPlayerId)
	if data.attachToVehicleId ~= 65535 or data.attachToPlayerId ~= 65535 then
		write.vector3d(bs, data.attachOffsets)
		write.vector3d(bs, data.attachRotation)
		write.int8(bs, data.unk2)
	end
	write.int8(bs, data.texturesCount)

	for _, it in ipairs(data.materials) do
		write_object_material(bs, it)
	end	
	for _, it in ipairs(data.materials_text) do
		write_object_material_text(bs, it)
	end
end

return handler
