AddCSLuaFile()

SWEP.Base = "spades_base"

SWEP.PrintName = "Shotgun"
SWEP.Author = "TankNut"

SWEP.Category = "Ace of Spades"
SWEP.Slot = 3
SWEP.SlotPos = 10

SWEP.Spawnable = true

SWEP.HoldType = "shotgun"
SWEP.LowerType = "passive"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "Buckshot",
	Automatic = false,

	ClipSize = 6,
	DefaultClip = 48,
}

SWEP.FireRate = 1

SWEP.BulletCount = 8
SWEP.Damage = 16
SWEP.Spread = 1.38

SWEP.Recoil = Angle(2.85, 1.45)
SWEP.RecoilPunch = 20
SWEP.RecoveryTime = 1

SWEP.TracerFrequency = 2

SWEP.MuzzleSize = 1.5

SWEP.VoxelData = {
	Model = "spades/shotgun",
	Scale = 1.2,

	ViewPos = {
		Pos = Vector(13, -6, -8),
		Ang = Angle()
	},

	WorldPos = {
		Pos = Vector(6, 0.5, 1),
		Ang = Angle()
	},

	LowerPos = {
		Pos = Vector(0, 5, -1),
		Ang = Angle(14, 32, 6)
	}
}

SWEP.Sounds = {
	Fire = Sound("weapons/spades/shotgunshoot.wav")
}