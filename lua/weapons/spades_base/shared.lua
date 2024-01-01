AddCSLuaFile()

DEFINE_BASECLASS("voxel_swep_base")

SWEP.Base = "voxel_swep_base"

SWEP.DrawWeaponInfoBox = false

SWEP.HoldType = "pistol"
SWEP.LowerType = "normal"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "AR2",

	ClipSize = 30,
	DefaultClip = 60,
}

-- -1 = automatic, 0 = semi, 1+ = burst
SWEP.Firemode = 0

SWEP.Delay = 0.5
SWEP.Cost = 1 -- Amount of bullets taken per shot

SWEP.Count = 1 -- Amount of pellets per shot
SWEP.Damage = 50 -- Damage per bullet, gets divided by count internally (input final damage, not per-pellet damage)

SWEP.Spread = 0.34

SWEP.Recoil = {
	Kick = Angle(2.86, 1.47), -- View kick

	-- Viewmodel kick
	HipOffset = Vector(-11, 2, 2),
	HipPitch = 5,

	AimOffset = Vector(-5.5, 0, 0),
	AimPitch = 2.5,

	Time = 1 -- Time it takes for the viewmodel to reset
}

-- >0 for shotgun-style reloads
SWEP.ReloadAmount = 0

-- Per-round time for shotgun-style reloads
SWEP.ReloadTime = 2.5

SWEP.Sights = {
	Enabled = true,

	Time = 0.3, -- Time it takes to zoom in, also affects sprint and deploy times
	Zoom = 1.2,
	Distance = 15 -- Distance from the attachment point on the weapon model
}

SWEP.Tracer = {
	Effect = "",
	Frequency = 1 -- Add a tracer every X shots
}

SWEP.Muzzle = {
	Effect = "",
	Size = 1
}

SWEP.Voxel = {
	Lower = {
		Pos = Vector(0, 5, -2),
		Ang = Angle(17, 32, 6)
	}
}

SWEP.Sounds = {
	Empty = Sound("weapons/spades/empty.wav")
}

include("sh_attack.lua")
include("sh_holdtype.lua")
include("sh_recoil.lua")
include("sh_reload.lua")
include("sh_sounds.lua")
include("sh_states.lua")
include("sh_view.lua")

function SWEP:Deploy()
	self:SetHoldType(self.LowerType)
	self:SetSprintState(1)

	self:SetNextPrimaryFire(CurTime() + self.Sights.Time)

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

	self:AddNetworkVar("Float", "LastFire")

	self:AddNetworkVar("Float", "FinishReload")
	self:AddNetworkVar("Bool", "AbortReload")
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

function SWEP:Think()
	self:UpdateHoldType()
	self:CheckReload()

	if game.SinglePlayer() or IsFirstTimePredicted() then
		self:UpdateStates()
	end
end

function SWEP:OnReloaded()
	self:SetWeaponHoldType(self:GetIdealHoldType())
end
