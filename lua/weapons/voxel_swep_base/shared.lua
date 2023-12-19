AddCSLuaFile()

SWEP.Base = "weapon_base"

SWEP.ViewModel = Model("models/weapons/c_smg1.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg1.mdl")

SWEP.VoxelData = {
	Model = "",
	Scale = 1,

	Offset = Vector(),

	ViewPos = {
		Pos = Vector(),
		Ang = Angle()
	},

	WorldPos = {
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

	if index >= max then
		error("Network var limit exceeded for " .. varType)
	end

	self:NetworkVar(varType, index, name, extended)
	self._NetworkVars[varType] = index + 1
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end
