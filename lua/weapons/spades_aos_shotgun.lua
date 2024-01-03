AddCSLuaFile()

SWEP.Base = "spades_base"

SWEP.PrintName = "Shotgun"
SWEP.Author = "TankNut"

SWEP.Category = "Ace of Spades"
SWEP.Slot = 3

SWEP.Spawnable = true

SWEP.HoldType = "shotgun"
SWEP.LowerType = "passive"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "Buckshot",

	ClipSize = 6,
	DefaultClip = 48,
}

-- -1 = automatic, 0 = semi, 1+ = burst
SWEP.Firemode = 0

SWEP.Delay = 1 -- Delay between shots in seconds, use X / 60 for rounds per minute
SWEP.Cost = 1 -- Amount of ammo taken out of the magazine per shot

SWEP.Count = 8 -- Amount of bullets per shot
SWEP.Damage = 64 -- Damage per bullet, gets divided by SWEP.Count internally (input final damage, not per-bullet damage)

SWEP.Range = 1500 -- Range in source units at which every shot lands in a SWEP.Accuracy sized circle
SWEP.Accuracy = 0 -- In source units: 12 = head sized, 24 = torso sized

SWEP.BaseSpread = 2 -- Diameter of a circle in degrees, divide by 60 for MOA. Applied separately to every bullet (use for shotguns)
SWEP.HipSpread = 1 -- Same unit as SWEP.BaseSpread, added when hipfiring
SWEP.MoveSpread = 1 -- Same unit as SWEP.BaseSpread, added when moving

SWEP.MoveSpeed = 0.6 -- Movespeed multiplier: 1 = run speed, 0 = alt-walk speed

SWEP.Recoil = {
	Kick = Angle(2.85, 1.45), -- View kick

	-- Viewmodel kick
	HipOffset = Vector(-22, 2, 2),
	HipPitch = 5,

	AimOffset = Vector(-11, 0, 0),
	AimPitch = 2.5,

	Time = 1 -- Time it takes for the viewmodel to reset
}

-- >0 for shotgun-style reloads
SWEP.ReloadAmount = 1

-- Per-round time for shotgun-style reloads
SWEP.ReloadTime = 0.5

SWEP.Sights = {
	Enabled = true,

	Time = 0.3, -- Time it takes to zoom in, also affects sprint and deploy times even if sights are disabled
	Zoom = 1.2,
	Distance = 15 -- Distance from the attachment point on the weapon model
}

SWEP.Tracer = {
	Effect = "voxel_tracer_smg",
	Frequency = 2 -- Add a tracer every X shots
}

SWEP.Muzzle = {
	Effect = "voxel_muzzle_smg",
	Size = 1.2
}

SWEP.Voxel = {
	Model = "spades/shotgun",
	Scale = 1.2,

	View = {
		Pos = Vector(13, -6, -8),
		Ang = Angle()
	},

	World = {
		Pos = Vector(6, 0.5, 1),
		Ang = Angle()
	},

	Lower = {
		Pos = Vector(0, 5, -1),
		Ang = Angle(14, 32, 6)
	}
}

SWEP.Sounds = {
	Fire = Sound("weapons/spades/shotgunshoot.wav"),
	Reload = Sound("weapons/spades/shotgunreload.wav"),
	ReloadFinish = Sound("weapons/spades/cock.wav")
}
