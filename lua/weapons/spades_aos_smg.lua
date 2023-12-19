AddCSLuaFile()

SWEP.Base = "spades_base"

SWEP.PrintName = "SMG"
SWEP.Author = "TankNut"

SWEP.Category = "Ace of Spades"
SWEP.Slot = 2
SWEP.SlotPos = 10

SWEP.Spawnable = true

SWEP.HoldType = "ar2"
SWEP.LowerType = "passive"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "SMG1",
	Automatic = true,

	ClipSize = 30,
	DefaultClip = 120,
}

SWEP.FireRate = 0.1

SWEP.BulletCount = 1
SWEP.Damage = 29
SWEP.Spread = 0.69

SWEP.Recoil = Angle(0.36, 0.37)
SWEP.RecoilPunch = 10
SWEP.RecoveryTime = 0.5

SWEP.TracerFrequency = 2

SWEP.MuzzleSize = 0.75

SWEP.VoxelData = {
	Model = "spades/smg",
	Scale = 1.2,

	ViewPos = {
		Pos = Vector(14, -6, -7.5),
		Ang = Angle()
	},

	WorldPos = {
		Pos = Vector(6, 0.5, 1),
		Ang = Angle()
	},

	LowerPos = {
		Pos = Vector(0, 5, -2),
		Ang = Angle(17, 32, 6)
	}
}

SWEP.Sounds = {
	Fire = Sound("weapons/spades/smgshoot.wav")
}
