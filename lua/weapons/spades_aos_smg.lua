AddCSLuaFile()

SWEP.Base = "spades_base"

SWEP.PrintName = "SMG"
SWEP.Author = "TankNut"

SWEP.Category = "Ace of Spades"
SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.HoldType = "ar2"
SWEP.LowerType = "passive"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "SMG1",

	ClipSize = 30,
	DefaultClip = 120,
}

-- -1 = automatic, 0 = semi, 1+ = burst
SWEP.Firemode = -1

SWEP.Delay = 0.1

SWEP.Count = 1
SWEP.Damage = 29 -- Damage per shot, gets divided by count internally (input final damage, not per-pellet damage)

SWEP.Spread = 0.69

SWEP.Recoil = {
	Kick = Angle(0.6, 0.35), -- View kick

	-- Viewmodel kick
	HipOffset = Vector(-5, 0, -1),
	HipPitch = 2,

	AimOffset = Vector(-5, 0, 0),
	AimPitch = 2,

	Time = 0.5 -- Time it takes for the viewmodel to reset
}

-- >0 for shotgun-style reloads
SWEP.ReloadAmount = 0

-- Per-round time for shotgun-style reloads
SWEP.ReloadTime = 2.5

SWEP.Sights = {
	Enabled = true,

	Time = 0.3, -- Time it takes to zoom in, also affects sprint and deploy times even if sights are disabled
	Zoom = 1.2,
	Distance = 12 -- Distance from the attachment point on the weapon model
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
	Model = "spades/smg",
	Scale = 1.2,

	View = {
		Pos = Vector(15, -6, -7.5),
		Ang = Angle()
	},

	World = {
		Pos = Vector(6, 0.5, 1),
		Ang = Angle()
	},

	Lower = {
		Pos = Vector(0, 5, -2),
		Ang = Angle(17, 32, 6)
	}
}

SWEP.Sounds = {
	Fire = Sound("weapons/spades/smgshoot.wav"),
	Reload = Sound("weapons/spades/smgreload.wav")
}
