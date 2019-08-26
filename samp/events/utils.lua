-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua

local ffi = require 'ffi'
local utils = {}

function utils.decompress_health_and_armor(hpAp)
	local hp = bit.rshift(hpAp, 4)
	local armor = bit.band(hpAp, 0x0F)
	if hp == 0x0F then hp = 100
	elseif hp ~= 0 then hp = hp * 7
	end
	if armor == 0x0F then armor = 100
	elseif armor ~= 0 then armor = armor * 7
	end
	return hp, armor
end

function utils.compress_health_and_armor(hp, armor)
	local hpAp = 0
	if hp > 0 and hp < 100 then hpAp = bit.lshift(hp / 7, 4)
	elseif hp >= 100 then hpAp = 0xF0
	end
	if armor > 0 and armor < 100 then hpAp = bit.bor(hpAp, armor / 7)
	elseif armor >= 100 then hpAp = bit.bor(hpAp, 0x0F)
	end
	return hpAp
end

function utils.read_sync_data(bs, st)
	require 'samp.synchronization'
	local dataStruct = ffi.new(st .. '[1]')
	raknetBitStreamReadBuffer(bs, tonumber(ffi.cast('intptr_t', dataStruct)), ffi.sizeof(dataStruct))
	return dataStruct[0]
end

function utils.write_sync_data(bs, st, ffiobj)
	require 'samp.synchronization'
	raknetBitStreamWriteBuffer(bs, tonumber(ffi.cast('intptr_t', ffiobj)), ffi.sizeof(st))
end

function utils.process_outcoming_sync_data(bs, st)
	local data = raknetBitStreamGetDataPtr(bs) + 1
	require 'samp.synchronization'
	return {ffi.cast(st .. '*', data)}
end

return utils
