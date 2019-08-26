-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua

local MODULE = {
	MODULEINFO = {
		name = 'samp.events',
		version = 2
	},
	INTERFACE = {
		OUTCOMING_RPCS    = {},
		OUTCOMING_PACKETS = {},
		INCOMING_RPCS     = {},
		INCOMING_PACKETS  = {}
	},
	EXPORTS = {}
}

-- check dependencies
assert(isSampLoaded(), 'SA-MP is not loaded')
assert(isSampfuncsLoaded(), 'samp.events requires SAMPFUNCS')
assert(getMoonloaderVersion() >= 20, 'samp.events requires MoonLoader v.020 or greater')

local BitStreamIO            = require 'samp.events.bitstream_io'
MODULE.INTERFACE.BitStreamIO = BitStreamIO


local function read_data(bs, dataType)
	if type(dataType) ~= 'table' then
		return BitStreamIO[dataType].read(bs)
	else -- process nested structures
		local values = {}
		for _, it in ipairs(dataType) do
			local name, t = next(it)
			values[name] = read_data(bs, t)
		end
		return values
	end
end

local function write_data(bs, dataType, value)
	if type(dataType) ~= 'table' then
		BitStreamIO[dataType].write(bs, value)
	else -- process nested structures
		for _, it in ipairs(dataType) do
			local name, t = next(it)
			write_data(bs, t, value[name])
		end
	end
end

local function process_event(bs, callback, struct, ignorebits)
	local args = {}
	if bs ~= 0 then
		if ignorebits then
			raknetBitStreamIgnoreBits(bs, ignorebits)
		end
		if type(struct[2]) == 'function' then
			local r1, r2 = struct[2](bs) -- call custom reading function
			if type(callback) == 'table' and type(r1) == 'string' then
				callback = callback[r1]
				if callback then
					args = r2
				else
					return
				end
			else
				args = r1
			end
		else
			-- skip event name
			for i = 2, #struct do
				local _, t = next(struct[i]) -- type
				table.insert(args, read_data(bs, t))
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
				write_data(bs, t, result[i - 1])
			end
		end
	end
end

local function process_packet(id, bs, event_table, ignorebits)
	local entry = event_table[id]
	if entry ~= nil then
		local key = entry[1]
		local callback = nil
		if type(key) == 'table' then
			for i, name in ipairs(key) do
				if type(MODULE[name]) == 'function' then
					if not callback then callback = {} end
					callback[name] = MODULE[name]
				end
			end
		elseif type(MODULE[key]) == 'function' then
			callback = MODULE[key]
		end
		if callback then
			return process_event(bs, callback, entry, ignorebits)
		end
	end
end


local interface = MODULE.INTERFACE
local function samp_on_send_rpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
	return process_packet(id, bitStream, interface.OUTCOMING_RPCS)
end

local function samp_on_send_packet(id, bitStream, priority, reliability, orderingChannel)
	return process_packet(id, bitStream, interface.OUTCOMING_PACKETS, 8)
end

local function samp_on_receive_rpc(id, bitStream)
	return process_packet(id, bitStream, interface.INCOMING_RPCS)
end

local function samp_on_receive_packet(id, bitStream)
	return process_packet(id, bitStream, interface.INCOMING_PACKETS, 8)
end

addEventHandler('onSendRpc', samp_on_send_rpc)
addEventHandler('onSendPacket', samp_on_send_packet)
addEventHandler('onReceiveRpc', samp_on_receive_rpc)
addEventHandler('onReceivePacket', samp_on_receive_packet)

return MODULE
