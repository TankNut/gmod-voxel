AddCSLuaFile()

DEFINE_BASECLASS("voxel_swep_base")

SWEP.Base = "voxel_swep_base"

SWEP.DrawWeaponInfoBox = false

SWEP.ViewModel = Model("models/weapons/c_smg1.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg1.mdl")

SWEP.HoldType = "pistol"
SWEP.LowerType = "normal"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "AR2",
	Automatic = true,

	ClipSize = 30,
	DefaultClip = 60,
}

SWEP.Secondary = {
	Ammo = "",
	Automatic = false,

	ClipSize = -1,
	DefaultClip = 0
}

SWEP.FireRate = 0.5

SWEP.BulletCount = 1
SWEP.Damage = 50
SWEP.Spread = 0.34

SWEP.Recoil = {
	Kick = Angle(2.86, 1.47),

	Offset = Vector(-11, 1, 1),
	Angle = Angle(0, 0, 0),

	RecoveryTime = 1
}

SWEP.AimZoom = 1.2

SWEP.AimTime = 0.3
SWEP.AimDistance = 15

SWEP.TracerName = "voxel_tracer_smg"
SWEP.TracerFrequency = 1

SWEP.MuzzleEffect = "voxel_muzzle_smg"
SWEP.MuzzleSize = 1

SWEP.VoxelData = {
	Model = "spades/semi",
	Scale = 1,

	ViewPos = {
		Pos = Vector(14, -6, -6),
		Ang = Angle()
	},

	WorldPos = {
		Pos = Vector(2, 0.5, 1),
		Ang = Angle()
	},

	LowerPos = {
		Pos = Vector(0, 5, -2),
		Ang = Angle(17, 32, 6)
	}
}

SWEP.Sounds = {
	Empty = Sound("weapons/spades/empty.wav")
}

if CLIENT then
	include("cl_view.lua")
else
	AddCSLuaFile("cl_view.lua")
end

include("sh_attack.lua")
include("sh_recoil.lua")
include("sh_sound.lua")
include("sh_think.lua")

function SWEP:Deploy()
	self:SetHoldType(self.LowerType)
	self:SetSprintState(1)

	if game.SinglePlayer() then
		self:CallOnClient("ResetViewModelData")
	elseif CLIENT then
		self:ResetViewModelData()
	end
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkVar("Float", "NWSprintState")
	self:AddNetworkVar("Float", "NWAimState")

	self:AddNetworkVar("Float", "FinishReload")
	self:AddNetworkVar("Float", "LastFire")
end

function SWEP:ShouldLower()
	local ply = self:GetOwner()

	if not IsValid(ply) or not ply:IsPlayer() then
		return false
	end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then
		return false
	end

	if ply:IsSprinting() and ply:GetVelocity():Length() > ply:GetWalkSpeed() then
		return true
	end

	return false
end

function SWEP:ShouldAim()
	if self:ShouldLower() then
		return false
	end

	local ply = self:GetOwner()

	return ply:KeyDown(IN_ATTACK2)
end

function SWEP:OnReloaded()
	self:SetWeaponHoldType(self:GetIdealHoldType())
end

local replacements = {
	-- Passive
	[ACT_HL2MP_WALK_CROUCH_PASSIVE] = ACT_HL2MP_WALK_CROUCH,
	[ACT_HL2MP_IDLE_CROUCH_PASSIVE] = ACT_HL2MP_IDLE_CROUCH
}

function SWEP:TranslateActivity(act)
	local translated

	if self:ShouldLower() and (act == ACT_MP_RELOAD_STAND or act == ACT_MP_RELOAD_CROUCH) and index[self.HoldType] then
		translated = index[self.HoldType] + 6
	end

	local custom = self:ShouldLower() and self.CustomLowerHoldType or self.CustomHoldType

	if custom[act] then
		return custom[act]
	end

	if not translated then
		translated = BaseClass.TranslateActivity(self, act)
	end

	return replacements[translated] and replacements[translated] or translated
end

function SWEP:GetAimFraction()
	return math.pow(math.sin(self:GetAimState() * math.pi * 0.5), math.pi)
end

function SWEP:GetZoom()
	return Lerp(self:GetAimFraction(), 1, self.AimZoom)
end
