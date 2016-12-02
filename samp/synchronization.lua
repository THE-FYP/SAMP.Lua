-- This file is part of the SAMP.Lua project.
-- Licensed under the MIT License.
-- Copyright (c) 2016, FYP @ BlastHack Team <blast.hk>
-- https://github.com/THE-FYP/SAMP.Lua


local MODULE =
{
	MODULEINFO = {
		name = 'samp.synchronization',
		version = 1
	}
}
local ffi = require 'ffi'

ffi.cdef[[
struct VectorXYZ
{
	float x, y, z;
};

struct SampKeys {
	uint8_t	primaryFire : 1;
	uint8_t	horn_crouch : 1;
	uint8_t	secondaryFire_shoot : 1;
	uint8_t	accel_zoomOut : 1;
	uint8_t	enterExitCar : 1;
	uint8_t	decel_jump : 1;
	uint8_t	circleRight : 1;
	uint8_t	aim : 1;
	uint8_t	circleLeft : 1;
	uint8_t	landingGear_lookback : 1;
	uint8_t	unknown_walkSlow : 1;
	uint8_t	specialCtrlUp : 1;
	uint8_t	specialCtrlDown : 1;
	uint8_t	specialCtrlLeft : 1;
	uint8_t	specialCtrlRight : 1;
	uint8_t	_unknown : 1;
};

struct PlayerSyncData {
	uint16_t          leftRightKeys;
	uint16_t          upDownKeys;
	union {
		uint16_t        keysData;
		struct SampKeys keys;
	};
	struct VectorXYZ  position;
	float             quaternion[4];
	uint8_t           health;
	uint8_t           armor;
	uint8_t           weapon;
	uint8_t           specialAction;
	struct VectorXYZ  moveSpeed;
	struct VectorXYZ  surfingOffsets;
	uint16_t          surfingVehicleId;
	uint16_t          animationId;
	uint16_t          animationFlags;
} __attribute__ ((packed));

struct VehicleSyncData {
	uint16_t	        vehicleId;
	uint16_t          leftRightKeys;
	uint16_t          upDownKeys;
	union {
		uint16_t        keysData;
		struct SampKeys keys;
	};
	float		          quaternion[4];
	struct VectorXYZ	position;
	struct VectorXYZ	moveSpeed;
	float		          vehicleHealth;
	uint8_t		        playerHealth;
	uint8_t		        armor;
	uint8_t		        currentWeapon;
	uint8_t		        siren;
	uint8_t		        landingGearState;
	uint16_t	        trailerId;
	union {
		float		        trainSpeed;
		uint16_t				hydraThrustAngle[2];
	};
} __attribute__ ((packed));

struct PassengerSyncData
{
	uint16_t	        vehicleId;
	uint8_t		        seatId;
	uint8_t		        currentWeapon;
	uint8_t		        health;
	uint8_t		        armor;
	uint16_t          leftRightKeys;
	uint16_t          upDownKeys;
	union {
		uint16_t        keysData;
		struct SampKeys keys;
	};
	struct VectorXYZ	position;
} __attribute__ ((packed));

struct UnoccupiedSyncData
{
	uint16_t	       vehicleId;
	uint8_t		       seatId;
	struct VectorXYZ roll;
	struct VectorXYZ direction;
	struct VectorXYZ position;
	struct VectorXYZ moveSpeed;
	struct VectorXYZ turnSpeed;
	float		         vehicleHealth;
} __attribute__ ((packed));

struct TrailerSyncData
{
	uint16_t	       trailerId;
	struct VectorXYZ position;
	struct VectorXYZ roll;
	struct VectorXYZ direction;
	struct VectorXYZ speed;
	uint32_t	       unk;
} __attribute__ ((packed));

struct SpectatorSyncData
{
	uint16_t          leftRightKeys;
	uint16_t          upDownKeys;
	union {
		uint16_t        keysData;
		struct SampKeys keys;
	};
	struct VectorXYZ  position;
} __attribute__ ((packed));

struct BulletSyncData
{
	uint8_t		       targetType;
	uint16_t	       targetId;
	struct VectorXYZ origin;
	struct VectorXYZ target;
	struct VectorXYZ center;
	uint8_t		       weaponId;
} __attribute__ ((packed));

struct AimSyncData
{
	uint8_t	 	       camMode;
	struct VectorXYZ camFront;
	struct VectorXYZ camPos;
	float		         aimZ;
	uint8_t		       camExtZoom : 6;
	uint8_t		       weaponState : 2;
	uint8_t		       unknown;
} __attribute__ ((packed));
]]

return MODULE
