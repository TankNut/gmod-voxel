AddCSLuaFile()
DEFINE_BASECLASS("voxel_swep_base")

SWEP.SpadesWeapon = true

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

SWEP.Delay = 0.5 -- Delay between shots in seconds, use X / 60 for rounds per minute
SWEP.Cost = 1 -- Amount of bullets taken out of the magazine per shot

SWEP.Count = 1 -- Amount of bullets per shot
SWEP.Damage = 50 -- Damage per bullet, gets divided by SWEP.Count internally (input final damage, not per-bullet damage)

SWEP.Range = 800 -- Range in source units at which every shot lands in a SWEP.Accuracy radius circle
SWEP.Accuracy = 12 -- In source units: 6 = head sized, 12 = torso sized

SWEP.BaseSpread = 1 / 60 -- Diameter of a circle in degrees, divide by 60 for MOA. Applied separately to every bullet (use for shotguns)
SWEP.HipSpread = 1 -- Same unit as SWEP.BaseSpread, added when hipfiring
SWEP.MoveSpread = 1 -- Same unit as SWEP.BaseSpread, added when moving

SWEP.MoveSpeed = 1 -- Movespeed multiplier: 1 = run speed, 0 = alt-walk speed

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
	Distance = 15, -- Distance from the attachment point on the weapon model

	Scoped = false
}

SWEP.Tracer = {
	Effect = "",
	Frequency = 1 -- Add a tracer every X shots
}

SWEP.Muzzle = {
	Effect = "",
	Size = 1
}

SWEP.Laser = {
	Enabled = false,
	Attachment = "muzzle",

	Beam = Material("effects/laser1"),
	BeamColor = Color(255, 0, 0),
	BeamWidth = 1,

	Sprite = Material("sprites/light_glow02_add"),
	SpriteColor = Color(255, 0, 0),
	SpriteWidth = 4
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

AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_laser.lua")
AddCSLuaFile("cl_model.lua")

if CLIENT then
	include("cl_hud.lua")
	include("cl_laser.lua")
	include("cl_model.lua")
end

include("sh_attack.lua")
include("sh_holdtype.lua")
include("sh_recoil.lua")
include("sh_reload.lua")
include("sh_sounds.lua")
include("sh_states.lua")
include("sh_view.lua")

function SWEP:Initialize()
	BaseClass.Initialize(self)

	if CLIENT and self.Laser then
		self.PixVis = util.GetPixelVisibleHandle()
	end

	hook.Add("PostDrawTranslucentRenderables", self, function()
		local ply = self:GetOwner()

		if not IsValid(ply) or ply:GetActiveWeapon() == self then
			self:PostDrawTranslucentRenderables() -- Updates through reloads
		end
	end)
end

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

	if CLIENT and self.Laser and not self.PixVis then
		self.PixVis = util.GetPixelVisibleHandle()
	end
end

hook.Add("SetupMove", "spades_base", function(ply, mv, cmd)
	local wep = ply:GetActiveWeapon()

	if not IsValid(wep) or not wep.SpadesWeapon then
		return
	end

	if wep:GetAimFraction() > 0 then
		local baseSpeed = ply:GetWalkSpeed()
		local maxSpeed = math.Remap(wep.MoveSpeed, 0, 1, ply:GetSlowWalkSpeed(), baseSpeed)

		local speed = math.Remap(wep:GetAimFraction(), 0, 1, baseSpeed, maxSpeed)

		if speed < mv:GetMaxClientSpeed() then
			mv:SetMaxSpeed(speed)
			mv:SetMaxClientSpeed(speed)
		end
	end
end)
