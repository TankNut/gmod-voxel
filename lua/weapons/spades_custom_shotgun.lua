AddCSLuaFile()

SWEP.Base = "spades_base"

SWEP.PrintName = "Custom Shotgun"
SWEP.Author = "TankNut"

SWEP.Category = "Ace of Spades"
SWEP.Slot = 3
SWEP.SlotPos = 11

SWEP.Spawnable = true

SWEP.HoldType = "shotgun"
SWEP.LowerType = "passive"

SWEP.CustomHoldType = {
	[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_AR2,
	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_AR2,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_AR2,
	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_AR2,
	[ACT_MP_RUN] = ACT_HL2MP_RUN_AR2
}

SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "Buckshot",
	Automatic = false,

	ClipSize = 6,
	DefaultClip = 48,
}

SWEP.FireRate = 0.2

SWEP.BulletCount = 8
SWEP.Damage = 8
SWEP.Spread = 2.38

SWEP.Recoil = Angle(1.85, 0.95)
SWEP.RecoilPunch = 10
SWEP.RecoveryTime = 1

SWEP.TracerFrequency = 2

SWEP.MuzzleSize = 1.5

SWEP.VoxelData = {
	Model = "spades/custom/shotgun",
	Scale = 1.2,

	ViewPos = {
		Pos = Vector(13, -6, -7.5),
		Ang = Angle()
	},

	WorldPos = {
		Pos = Vector(4, 0.5, 1),
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
