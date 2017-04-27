-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua


local BitStreamIO = require 'lib.samp.events.bitstream_io'
local utils = require 'lib.samp.events.utils'

BitStreamIO.PlayerScorePingMap = {
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

BitStreamIO.Int32Array3 = {
	read = function(bs)
		local arr = {}
		for i = 1, 3 do arr[i] = raknetBitStreamReadInt32(bs) end
		return arr
	end,
	write = function(bs, value)
		for i = 1, 3 do raknetBitStreamWriteInt32(bs, value[i]) end
	end
}

BitStreamIO.AimSyncData = {
	read = function(bs) return utils.read_sync_data(bs, 'AimSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'AimSyncData', value) end
}

BitStreamIO.UnoccupiedSyncData = {
	read = function(bs) return utils.read_sync_data(bs, 'UnoccupiedSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'UnoccupiedSyncData', value) end
}

BitStreamIO.PassengerSyncData = {
	read = function(bs) 	return utils.read_sync_data(bs, 'PassengerSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'PassengerSyncData', value) end
}

BitStreamIO.BulletSyncData = {
	read = function(bs) return utils.read_sync_data(bs, 'BulletSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'BulletSyncData', value) end
}

BitStreamIO.TrailerSyncData = {
	read = function(bs) return utils.read_sync_data(bs, 'TrailerSyncData')  end,
	write = function(bs, value) utils.write_sync_data(bs, 'TrailerSyncData', value) end
}

return BitStreamIO
