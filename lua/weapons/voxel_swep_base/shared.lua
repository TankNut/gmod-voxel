AddCSLuaFile()

SWEP.Base = "weapon_base"

SWEP.m_WeaponDeploySpeed = math.huge
SWEP.BaseViewModelFOV = 54

SWEP.ViewModel = Model("models/weapons/c_smg1.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg1.mdl")

SWEP.Primary = {
	Ammo = "",
	Automatic = false,

	ClipSize = -1,
	DefaultClip = 0,
}

SWEP.Secondary = {
	Ammo = "",
	Automatic = false,

	ClipSize = -1,
	DefaultClip = 0
}

SWEP.Voxel = {
	Model = "builtin/directions",
	Scale = 1,

	Offset = Vector(),

	View = {
		Pos = Vector(),
		Ang = Angle()
	},

	World = {
		Pos = Vector(),
		Ang = Angle()
	}
}

if CLIENT then
	include("cl_view.lua")
	include("cl_world.lua")
else
	AddCSLuaFile("cl_view.lua")
	AddCSLuaFile("cl_world.lua")
end

include("sh_fov.lua")
include("sh_helpers.lua")
include("sh_model.lua")

function SWEP:Initialize()
	self:SetupModel()
end

function SWEP:SetupDataTables()
	self._NetworkVars = {
		["String"] = 0,
		["Bool"]   = 0,
		["Float"]  = 0,
		["Int"]    = 0,
		["Vector"] = 0,
		["Angle"]  = 0,
		["Entity"] = 0
	}
end

function SWEP:AddNetworkVar(varType, name, extended)
	local index = assert(self._NetworkVars[varType], "Attempt to register unknown network var type " .. varType)
	local max = varType == "String" and 3 or 31

	if index > max then
		error("Network var limit exceeded for " .. varType)
	end

	self:NetworkVar(varType, index, name, extended)
	self._NetworkVars[varType] = index + 1
end

function SWEP:AddNetworkVarNotify(varType, name, callback, extended)
	self:AddNetworkVar(varType, name, extended)
	self:NetworkVarNotify(name, callback)
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end
