-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua


local MODULE =
{
	MODULEINFO = {
		name = 'samp.events',
		version = 1
	},
	INTERFACE = {
		OUTCOMING_RPCS    = {},
		OUTCOMING_PACKETS = {},
		INCOMING_RPCS     = {},
		INCOMING_PACKETS  = {},
		BitStreamIO       = {}
	},
	EXPORTS = {}
}

-- check dependencies
assert(isSampLoaded(), 'SA:MP is not loaded')
assert(isSampfuncsLoaded(), 'samp.events requires SAMPFUNCS')
assert(getMoonloaderVersion() >= 20, 'samp.events requires MoonLoader v.020 or greater')

local OUTCOMING_RPCS    = MODULE.INTERFACE.OUTCOMING_RPCS
local OUTCOMING_PACKETS = MODULE.INTERFACE.OUTCOMING_PACKETS
local INCOMING_RPCS     = MODULE.INTERFACE.INCOMING_RPCS
local INCOMING_PACKETS  = MODULE.INTERFACE.INCOMING_PACKETS
local BitStreamIO       = MODULE.INTERFACE.BitStreamIO

function MODULE.EXPORTS.bitStreamRead(bitstream, type)
	return BitStreamIO[type].read(bitstream)
end
local bsRead  = MODULE.EXPORTS.bitStreamRead

function MODULE.EXPORTS.bitStreamWrite(bitstream, type, value)
	return BitStreamIO[type].write(bitstream, value)
end
local bsWrite = MODULE.EXPORTS.bitStreamWrite

--[[ types ]]--
BitStreamIO.bool = {
	read = function(bs) return raknetBitStreamReadBool(bs) end,
	write = function(bs, value) return raknetBitStreamWriteBool(bs, value) end
}

BitStreamIO.int8 = {
	read = function(bs) return raknetBitStreamReadInt8(bs) end,
	write = function(bs, value) return raknetBitStreamWriteInt8(bs, value) end
}

BitStreamIO.int16 = {
	read = function(bs) return raknetBitStreamReadInt16(bs) end,
	write = function(bs, value) return raknetBitStreamWriteInt16(bs, value) end
}

BitStreamIO.int32 = {
	read = function(bs) return raknetBitStreamReadInt32(bs) end,
	write = function(bs, value) return raknetBitStreamWriteInt32(bs, value) end
}

BitStreamIO.float = {
	read = function(bs) return raknetBitStreamReadFloat(bs) end,
	write = function(bs, value) return raknetBitStreamWriteFloat(bs, value) end
}

BitStreamIO.string8 = {
	read = function(bs)
		local len = raknetBitStreamReadInt8(bs)
		if len <= 0 then return '' end
		return raknetBitStreamReadString(bs, len)
	end,
	write = function(bs, value)
		raknetBitStreamWriteInt8(bs, #value)
		raknetBitStreamWriteString(bs, value)
	end
}

BitStreamIO.string32 = {
	read = function(bs)
		local len = raknetBitStreamReadInt32(bs)
		if len <= 0 then return '' end
		return raknetBitStreamReadString(bs, len)
	end,
	write = function(bs, value)
		raknetBitStreamWriteInt32(bs, #value)
		raknetBitStreamWriteString(bs, value)
	end
}

BitStreamIO.bool8 = {
	read = function(bs)
		return raknetBitStreamReadInt8(bs) ~= 0
	end,
	write = function(bs, value)
		raknetBitStreamWriteInt8(bs, value == true and 1 or 0)
	end
}

BitStreamIO.bool32 = {
	read = function(bs)
		return raknetBitStreamReadInt32(bs) ~= 0
	end,
	write = function(bs, value)
		raknetBitStreamWriteInt32(bs, value == true and 1 or 0)
	end
}

BitStreamIO.int1 = {
	read = function(bs)
		if raknetBitStreamReadBool(bs) == true then return 1 else return 0 end
	end,
	write = function(bs, value)
		raknetBitStreamWriteBool(bs, value ~= 0 and true or false)
	end
}


local function processEvent(bs, callback, struct, ignorebits)
	local args = {}
	if bs ~= 0 then
		if ignorebits then
			-- skip packet id
			raknetBitStreamIgnoreBits(bs, ignorebits)
		end

		if type(struct[2]) == 'function' then
			args = struct[2](bs) -- call custom reading function
			if args == false then
				-- stop processing if custom reader returns false
				raknetBitStreamResetReadPointer(bs)
				return
			end
		else
			-- skip event name
			for i = 2, #struct do
				local _, t = next(struct[i]) -- type
				table.insert(args, bsRead(bs, t))
			end
		end
	end
	local result = callback(unpack(args))
	if result == false then
		return false -- consume packet
	end
	if bs ~= 0 and type(result) == 'table' then
		raknetBitStreamSetWriteOffset(bs, ignorebits or 0)
		if type(struct[3]) == 'function' then
			struct[3](bs, result) -- call custom writing function
		else
			assert(#struct - 1 == #result)
			for i = 2, #struct do
				local _, t = next(struct[i]) -- type
				bsWrite(bs, t, result[i - 1])
			end
		end
	end
end

local function processPacket(id, bs, event_table, ignorebits)
	local entry = event_table[id]
	if entry ~= nil then
		if type(entry[1]) ~= 'table' then
			if type(MODULE[entry[1]]) == 'function' then
				if processEvent(bs, MODULE[entry[1]], entry, ignorebits) == false then
					return false
				end
			end
		else
			for _, item in pairs(entry) do
				if type(MODULE[item[1]]) == 'function' then
					if processEvent(bs, MODULE[item[1]], item, ignorebits) == false then
						return false
					end
				end
			end
		end
	end
end

local function sampOnSendRpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
	if processPacket(id, bitStream, OUTCOMING_RPCS) == false then return false end
end

local function sampOnSendPacket(id, bitStream, priority, reliability, orderingChannel)
	if processPacket(id, bitStream, OUTCOMING_PACKETS, 8) == false then return false end
end

local function sampOnReceiveRpc(id, bitStream)
	if processPacket(id, bitStream, INCOMING_RPCS) == false then return false end
end

local function sampOnReceivePacket(id, bitStream)
	if processPacket(id, bitStream, INCOMING_PACKETS, 8) == false then return false end
end

addEventHandler('onSendRpc', sampOnSendRpc)
addEventHandler('onSendPacket', sampOnSendPacket)
addEventHandler('onReceiveRpc', sampOnReceiveRpc)
addEventHandler('onReceivePacket', sampOnReceivePacket)

return MODULE
