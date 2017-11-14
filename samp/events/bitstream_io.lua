-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua


local Vector3D = require 'lib.vector3d'
local BitStreamIO = {}

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

BitStreamIO.string16 = {
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

BitStreamIO.string256 = {
	read = function(bs)
		local str = raknetBitStreamReadString(bs, 32)
		local zero = string.find(str, '\0', 1, true)
		return zero and str:sub(1, zero - 1) or str
	end,
	write = function(bs, value)
		if #value >= 32 then raknetBitStreamWriteString(bs, value:sub(1, 32))
		else
			raknetBitStreamWriteString(bs, value .. string.rep('\0', 32 - #value))
		end
	end
}

BitStreamIO.encodedString2048 = {
	read = function(bs) return raknetBitStreamDecodeString(bs, 2048) end,
	write = function(bs, value) raknetBitStreamEncodeString(bs, value) end
}

BitStreamIO.encodedString4096 = {
	read = function(bs) return raknetBitStreamDecodeString(bs, 4096) end,
	write = function(bs, value) raknetBitStreamEncodeString(bs, value) end
}

BitStreamIO.compressedFloat = {
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

BitStreamIO.compressedVector = {
	read = function(bs)
		local magnitude = raknetBitStreamReadFloat(bs)
		if magnitude ~= 0 then
			local readCf = BitStreamIO.compressedFloat.read
			return Vector3D(readCf(bs) * magnitude, readCf(bs) * magnitude, readCf(bs) * magnitude)
		else
			return Vector3D(0, 0, 0)
		end
	end,
	write = function(bs, data)
		local x, y, z = data.x, data.y, data.z
		local magnitude = math.sqrt(x * x + y * y + z * z)
		raknetBitStreamWriteFloat(bs, magnitude)
		if magnitude > 0 then
			local writeCf = BitStreamIO.compressedFloat.write
			writeCf(bs, x / magnitude)
			writeCf(bs, y / magnitude)
			writeCf(bs, z / magnitude)
		end
	end
}

BitStreamIO.normQuat = {
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
		-- w is calculates on the target
	end
}

BitStreamIO.vector3d = {
	read = function(bs)
		local x, y, z =
			raknetBitStreamReadFloat(bs),
			raknetBitStreamReadFloat(bs),
			raknetBitStreamReadFloat(bs)
		return Vector3D(x, y, z)
	end,
	write = function(bs, value)
		raknetBitStreamWriteFloat(bs, value.x)
		raknetBitStreamWriteFloat(bs, value.y)
		raknetBitStreamWriteFloat(bs, value.z)
	end
}

BitStreamIO.vector2d = {
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

function bitstream_io_interface(field)
	return setmetatable({}, {
		__index = function(t, index)
			return BitStreamIO[index][field]
		end
	})
end

BitStreamIO.bs_read = bitstream_io_interface('read')
BitStreamIO.bs_write = bitstream_io_interface('write')

return BitStreamIO
