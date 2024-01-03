AddCSLuaFile()

SWEP.Base = "spades_base"

SWEP.PrintName = "Rifle"
SWEP.Author = "TankNut"

SWEP.Category = "Ace of Spades"
SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.HoldType = "ar2"
SWEP.LowerType = "passive"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "AR2",

	ClipSize = 10,
	DefaultClip = 60,
}

-- -1 = automatic, 0 = semi, 1+ = burst
SWEP.Firemode = 0

SWEP.Delay = 0.5 -- Delay between shots in seconds, use X / 60 for rounds per minute
SWEP.Cost = 1 -- Amount of ammo taken out of the magazine per shot

SWEP.Count = 1 -- Amount of bullets per shot
SWEP.Damage = 50 -- Damage per bullet, gets divided by SWEP.Count internally (input final damage, not per-bullet damage)

SWEP.Range = 2500 -- Range in source units at which every shot lands in a SWEP.Accuracy sized circle
SWEP.Accuracy = 12 -- In source units: 12 = head sized, 24 = torso sized

SWEP.BaseSpread = 1 / 60 -- Diameter of a circle in degrees, divide by 60 for MOA. Applied separately to every bullet (use for shotguns)
SWEP.HipSpread = 1.5 -- Same unit as SWEP.BaseSpread, added when hipfiring
SWEP.MoveSpread = 2 -- Same unit as SWEP.BaseSpread, added when moving

SWEP.MoveSpeed = 0.4 -- Movespeed multiplier: 1 = run speed, 0 = alt-walk speed

SWEP.Recoil = {
	Kick = Angle(1.43, 0.74), -- View kick

	-- Viewmodel kick
	HipOffset = Vector(-10, 1, 1),
	HipPitch = 4,

	AimOffset = Vector(-5, 0, 0),
	AimPitch = 2,

	Time = 1 -- Time it takes for the viewmodel to reset
}

-- >0 for shotgun-style reloads
SWEP.ReloadAmount = 0

-- Per-round time for shotgun-style reloads
SWEP.ReloadTime = 2.5

SWEP.Sights = {
	Enabled = true,

	Time = 0.3, -- Time it takes to zoom in, also affects sprint and deploy times
	Zoom = 2,
	Distance = 15 -- Distance from the attachment point on the weapon model
}

SWEP.Tracer = {
	Effect = "voxel_tracer_smg",
	Frequency = 1 -- Add a tracer every X shots
}

SWEP.Muzzle = {
	Effect = "voxel_muzzle_smg",
	Size = 1.2
}

SWEP.Voxel = {
	Model = "spades/semi",
	Scale = 1.2,

	View = {
		Pos = Vector(15, -6, -7),
		Ang = Angle()
	},

	World = {
		Pos = Vector(3, 0.5, 1),
		Ang = Angle()
	},

	Lower = {
		Pos = Vector(0, 5, -2),
		Ang = Angle(17, 32, 6)
	}
}

SWEP.Sounds = {
	Fire = Sound("weapons/spades/semishoot.wav"),
	Reload = Sound("weapons/spades/semireload.wav")
}
