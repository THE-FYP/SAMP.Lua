-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua

local mod = {}
local vector3d = require 'vector3d'
local ffi = require 'ffi'

local function bitstream_read_fixed_string(bs, size)
	local buf = ffi.new('uint8_t[?]', size + 1)
	raknetBitStreamReadBuffer(bs, tonumber(ffi.cast('intptr_t', buf)), size)
	buf[size] = 0
	-- Length is not specified to throw off trailing zeros.
	return ffi.string(buf)
end

local function bitstream_write_fixed_string(bs, str, size)
	local buf = ffi.new('uint8_t[?]', size, string.sub(str, 1, size))
	raknetBitStreamWriteBuffer(bs, tonumber(ffi.cast('intptr_t', buf)), size)
end

mod.bool = {
	read = function(bs) return raknetBitStreamReadBool(bs) end,
	write = function(bs, value) return raknetBitStreamWriteBool(bs, value) end
}

mod.uint8 = {
	read = function(bs) return raknetBitStreamReadInt8(bs) end,
	write = function(bs, value) return raknetBitStreamWriteInt8(bs, value) end
}

mod.uint16 = {
	read = function(bs) return raknetBitStreamReadInt16(bs) end,
	write = function(bs, value) return raknetBitStreamWriteInt16(bs, value) end
}

mod.uint32 = {
	read = function(bs)
		local v = raknetBitStreamReadInt32(bs)
		return v < 0 and 0x100000000 + v or v
	end,
	write = function(bs, value)
		return raknetBitStreamWriteInt32(bs, value)
	end
}

mod.int8 = {
	read = function(bs)
		local v = raknetBitStreamReadInt8(bs)
		return v >= 0x80 and v - 0x100 or v
	end,
	write = function(bs, value)
		return raknetBitStreamWriteInt8(bs, value)
	end
}

mod.int16 = {
	read = function(bs)
		local v = raknetBitStreamReadInt16(bs)
		return v >= 0x8000 and v - 0x10000 or v
	end,
	write = function(bs, value)
		return raknetBitStreamWriteInt16(bs, value)
	end
}

mod.int32 = {
	read = function(bs) return raknetBitStreamReadInt32(bs) end,
	write = function(bs, value) return raknetBitStreamWriteInt32(bs, value) end
}

mod.float = {
	read = function(bs) return raknetBitStreamReadFloat(bs) end,
	write = function(bs, value) return raknetBitStreamWriteFloat(bs, value) end
}

mod.string8 = {
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

mod.string16 = {
	read = function(bs)
		local len = raknetBitStreamReadInt16(bs)
		if len <= 0 then return '' end
		return raknetBitStreamReadString(bs, len)
	end,
	write = function(bs, value)
		raknetBitStreamWriteInt16(bs, #value)
		raknetBitStreamWriteString(bs, value)
	end
}

mod.string32 = {
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

mod.bool8 = {
	read = function(bs)
		return raknetBitStreamReadInt8(bs) ~= 0
	end,
	write = function(bs, value)
		raknetBitStreamWriteInt8(bs, value == true and 1 or 0)
	end
}

mod.bool32 = {
	read = function(bs)
		return raknetBitStreamReadInt32(bs) ~= 0
	end,
	write = function(bs, value)
		raknetBitStreamWriteInt32(bs, value == true and 1 or 0)
	end
}

mod.int1 = {
	read = function(bs)
		if raknetBitStreamReadBool(bs) == true then return 1 else return 0 end
	end,
	write = function(bs, value)
		raknetBitStreamWriteBool(bs, value ~= 0 and true or false)
	end
}

mod.fixedString32 = {
	read = function(bs)
		return bitstream_read_fixed_string(bs, 32)
	end,
	write = function(bs, value)
		bitstream_write_fixed_string(bs, value, 32)
	end
}

mod.string256 = mod.fixedString32

mod.encodedString2048 = {
	read = function(bs) return raknetBitStreamDecodeString(bs, 2048) end,
	write = function(bs, value) raknetBitStreamEncodeString(bs, value) end
}

mod.encodedString4096 = {
	read = function(bs) return raknetBitStreamDecodeString(bs, 4096) end,
	write = function(bs, value) raknetBitStreamEncodeString(bs, value) end
}

mod.compressedFloat = {
	read = function(bs)
		return raknetBitStreamReadInt16(bs) / 32767.5 - 1
	end,
	write = function(bs, value)
		if value < -1 then
			value = -1
		elseif value > 1 then
			value = 1
		end
		raknetBitStreamWriteInt16(bs, (value + 1) * 32767.5)
	end
}

mod.compressedVector = {
	read = function(bs)
		local magnitude = raknetBitStreamReadFloat(bs)
		if magnitude ~= 0 then
			local readCf = mod.compressedFloat.read
			return vector3d(readCf(bs) * magnitude, readCf(bs) * magnitude, readCf(bs) * magnitude)
		else
			return vector3d(0, 0, 0)
		end
	end,
	write = function(bs, data)
		local x, y, z = data.x, data.y, data.z
		local magnitude = math.sqrt(x * x + y * y + z * z)
		raknetBitStreamWriteFloat(bs, magnitude)
		if magnitude > 0 then
			local writeCf = mod.compressedFloat.write
			writeCf(bs, x / magnitude)
			writeCf(bs, y / magnitude)
			writeCf(bs, z / magnitude)
		end
	end
}

mod.normQuat = {
	read = function(bs)
		local readBool, readShort = raknetBitStreamReadBool, raknetBitStreamReadInt16
		local cwNeg, cxNeg, cyNeg, czNeg = readBool(bs), readBool(bs), readBool(bs), readBool(bs)
		local cx, cy, cz = readShort(bs), readShort(bs), readShort(bs)
		local x = cx / 65535
		local y = cy / 65535
		local z = cz / 65535
		if cxNeg then x = -x end
		if cyNeg then y = -y end
		if czNeg then z = -z end
		local diff = 1 - x * x - y * y - z * z
		if diff < 0 then diff = 0 end
		local w = math.sqrt(diff)
		if cwNeg then w = -w end
		return {w, x, y, z}
	end,
	write = function(bs, value)
		local w, x, y, z = value[1], value[2], value[3], value[4]
		raknetBitStreamWriteBool(bs, w < 0)
		raknetBitStreamWriteBool(bs, x < 0)
		raknetBitStreamWriteBool(bs, y < 0)
		raknetBitStreamWriteBool(bs, z < 0)
		raknetBitStreamWriteInt16(bs, math.abs(x) * 65535)
		raknetBitStreamWriteInt16(bs, math.abs(y) * 65535)
		raknetBitStreamWriteInt16(bs, math.abs(z) * 65535)
		-- w is calculated on the target
	end
}

mod.vector3d = {
	read = function(bs)
		local x, y, z =
			raknetBitStreamReadFloat(bs),
			raknetBitStreamReadFloat(bs),
			raknetBitStreamReadFloat(bs)
		return vector3d(x, y, z)
	end,
	write = function(bs, value)
		raknetBitStreamWriteFloat(bs, value.x)
		raknetBitStreamWriteFloat(bs, value.y)
		raknetBitStreamWriteFloat(bs, value.z)
	end
}

mod.vector2d = {
	read = function(bs)
		local x = raknetBitStreamReadFloat(bs)
		local y = raknetBitStreamReadFloat(bs)
		return {x = x, y = y}
	end,
	write = function(bs, value)
		raknetBitStreamWriteFloat(bs, value.x)
		raknetBitStreamWriteFloat(bs, value.y)
	end
}

local function bitstream_io_interface(field)
	return setmetatable({}, {
		__index = function(t, index)
			return mod[index][field]
		end
	})
end

mod.bs_read = bitstream_io_interface('read')
mod.bs_write = bitstream_io_interface('write')

return mod
