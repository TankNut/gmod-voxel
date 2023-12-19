AddCSLuaFile()

SWEP.Base = "spades_base"

SWEP.PrintName = "Rifle"
SWEP.Author = "TankNut"

SWEP.Category = "Ace of Spades"
SWEP.Slot = 2
SWEP.SlotPos = 11

SWEP.Spawnable = true

SWEP.HoldType = "ar2"
SWEP.LowerType = "passive"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "AR2",
	Automatic = false,

	ClipSize = 10,
	DefaultClip = 60,
}

SWEP.FireRate = 0.5

SWEP.BulletCount = 1
SWEP.Damage = 50
SWEP.Spread = 0.34

SWEP.Recoil = Angle(1.43, 0.74)
SWEP.RecoilPunch = 10
SWEP.RecoveryTime = 1

SWEP.MuzzleSize = 1

SWEP.VoxelData = {
	Model = "spades/semi",
	Scale = 1.2,

	ViewPos = {
		Pos = Vector(15, -6, -7),
		Ang = Angle()
	},

	WorldPos = {
		Pos = Vector(3, 0.5, 1),
		Ang = Angle()
	},

	LowerPos = {
		Pos = Vector(0, 5, -2),
		Ang = Angle(17, 32, 6)
	}
}

SWEP.Sounds = {
	Fire = Sound("weapons/spades/semishoot.wav")
}
