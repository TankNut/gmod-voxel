AddCSLuaFile()
DEFINE_BASECLASS("spades_base")

SWEP.Base = "spades_base"

SWEP.PrintName = "Weapon Designer"

SWEP.Category = "Ace of Spades"
SWEP.Slot = 5

SWEP.Spawnable = true

SWEP.Primary.DefaultClip = 0

SWEP.Tracer = {
	Effect = "voxel_tracer_smg",
	Frequency = 1
}

SWEP.Muzzle = {
	Effect = "voxel_muzzle_smg",
	Size = 1
}

SWEP.Sounds = {
	ReloadSingle = Sound("weapons/spades/shotgunreload.wav"),
	ReloadFinish = Sound("weapons/spades/cock.wav")
}

function SWEP:Initialize()
	BaseClass.Initialize(self)

	self:UpdateAll()
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	-- Model data
	self:AddNetworkVarNotify("String", "NWVoxelModel", self.NetModelData)
	self:AddNetworkVarNotify("Float", "NWVoxelScale", self.NetModelData)

	-- View data
	self:AddNetworkVarNotify("Vector", "NWViewPos", self.NetViewData)
	self:AddNetworkVarNotify("Angle", "NWViewAng", self.NetViewData)

	self:AddNetworkVarNotify("Vector", "NWWorldPos", self.NetViewData)
	self:AddNetworkVarNotify("Angle", "NWWorldAng", self.NetViewData)

	self:AddNetworkVarNotify("Vector", "NWLowerPos", self.NetViewData)
	self:AddNetworkVarNotify("Angle", "NWLowerAng", self.NetViewData)

	-- Holdtypes
	self:AddNetworkVarNotify("Int", "NWHoldType", self.NetHoldType)
	self:AddNetworkVarNotify("Int", "NWLowerType", self.NetHoldType)

	-- Ammo data
	self:AddNetworkVarNotify("Int", "NWAmmo", self.NetAmmo)
	self:AddNetworkVarNotify("Int", "NWClipSize", self.NetAmmo)
	self:AddNetworkVarNotify("Int", "NWCost", self.NetAmmo)

	-- Main stats
	self:AddNetworkVarNotify("Int", "NWFiremode", self.NetStats)

	self:AddNetworkVarNotify("Float", "NWDelay", self.NetStats)
	self:AddNetworkVarNotify("Int", "NWCount", self.NetStats)
	self:AddNetworkVarNotify("Int", "NWDamage", self.NetStats)

	self:AddNetworkVarNotify("Int", "NWRange", self.NetStats)
	self:AddNetworkVarNotify("Int", "NWAccuracy", self.NetStats)

	self:AddNetworkVarNotify("Float", "NWBaseSpread", self.NetStats)
	self:AddNetworkVarNotify("Float", "NWHipSpread", self.NetStats)
	self:AddNetworkVarNotify("Float", "NWMoveSpread", self.NetStats)

	self:AddNetworkVarNotify("Float", "NWMoveSpeed", self.NetStats)

	-- Recoil
	self:AddNetworkVarNotify("Angle", "NWKick", self.NetRecoil)

	self:AddNetworkVarNotify("Vector", "NWHipOffset", self.NetRecoil)
	self:AddNetworkVarNotify("Float", "NWHipPitch", self.NetRecoil)

	self:AddNetworkVarNotify("Vector", "NWAimOffset", self.NetRecoil)
	self:AddNetworkVarNotify("Float", "NWAimPitch", self.NetRecoil)

	self:AddNetworkVarNotify("Float", "NWRecoilTime", self.NetRecoil)

	-- Reloading
	self:AddNetworkVarNotify("Int", "NWReloadAmount", self.NetReload)
	self:AddNetworkVarNotify("Float", "NWReloadTime", self.NetReload)

	-- Sights
	self:AddNetworkVarNotify("Bool", "NWSightEnabled", self.NetSights)

	self:AddNetworkVarNotify("Float", "NWSightTime", self.NetSights)
	self:AddNetworkVarNotify("Float", "NWSightZoom", self.NetSights)
	self:AddNetworkVarNotify("Float", "NWSightDistance", self.NetSights)

	-- Sounds
	self:AddNetworkVarNotify("String", "NWFireSound", self.NetSounds)
	self:AddNetworkVarNotify("String", "NWReloadSound", self.NetSounds)

	-- Set defaults
	if SERVER then
		self:SetNWViewPos(Vector(20, -8, -5))
		self:SetNWWorldPos(Vector(3, 0.5, 1))

		self:SetNWLowerPos(Vector(0, 5, -2))
		self:SetNWLowerAng(Angle(17, 32, 6))

		self:SetNWHoldType(1)
		self:SetNWLowerType(1)

		self:SetNWAmmo(game.GetAmmoID("Pistol"))
		self:SetNWCost(1)

		self:SetNWDelay(0.1)
		self:SetNWCount(1)
		self:SetNWDamage(10)

		self:SetNWRange(1000)
		self:SetNWAccuracy(12)

		self:SetNWMoveSpeed(0.8)

		self:SetNWRecoilTime(0.5)

		self:SetNWReloadTime(2.5)

		self:SetNWFireSound("Weapon_Pistol.Single")
		self:SetNWReloadSound("Weapon_Pistol.NPC_Reload")
	end
end

function SWEP:UpdateAll()
	self:NetViewData()
	self:NetHoldType()
	self:NetAmmo()
	self:NetStats()
	self:NetRecoil()
	self:NetReload()
	self:NetSights()
	self:NetSounds()
end

function SWEP:OnReloaded()
	BaseClass.OnReloaded(self)

	self:UpdateAll()
end

function SWEP:GetUpdatedVar(var, name, new)
	return var == name and new or self["Get" .. var](self)
end

function SWEP:NetModelData(name, _, new)
	self.Voxel.Model = self:GetUpdatedVar("NWVoxelModel", name, new)
	self.Voxel.Scale = self:GetUpdatedVar("NWVoxelScale", name, new)

	self:SetupModel()
end

function SWEP:NetViewData(name, _, new)
	self.Voxel.View.Pos = self:GetUpdatedVar("NWViewPos", name, new)
	self.Voxel.View.Ang = self:GetUpdatedVar("NWViewAng", name, new)

	self.Voxel.World.Pos = self:GetUpdatedVar("NWWorldPos", name, new)
	self.Voxel.World.Ang = self:GetUpdatedVar("NWWorldAng", name, new)

	self.Voxel.Lower.Pos = self:GetUpdatedVar("NWLowerPos", name, new)
	self.Voxel.Lower.Ang = self:GetUpdatedVar("NWLowerAng", name, new)
end

local flip = function(tab)
	local res = {}

	for k, v in pairs(tab) do
		res[v] = k
	end

	return res
end

local holdTypes = {
	"pistol",
	"smg",
	"grenade",
	"ar2",
	"shotgun",
	"rpg",
	"physgun",
	"crossbow",
	"melee",
	"slam",
	"normal",
	"fist",
	"melee2",
	"passive",
	"knife",
	"duel",
	"camera",
	"magic",
	"revolver"
}

local holdTypesToIndex = flip(holdTypes)

function SWEP:NetHoldType(name, _, new)
	self.HoldType = holdTypes[self:GetUpdatedVar("NWHoldType", name, new)]
	self.LowerType = holdTypes[self:GetUpdatedVar("NWLowerType", name, new)]
end

function SWEP:NetAmmo(name, _, new)
	self.Primary.Ammo = game.GetAmmoName(self:GetUpdatedVar("NWAmmo", name, new))
	self.Primary.ClipSize = self:GetUpdatedVar("NWClipSize", name, new)
	self.Cost = self:GetUpdatedVar("NWCost", name, new)

	if SERVER then
		self:SetClip1(self.Primary.ClipSize)
	end
end

function SWEP:NetStats(name, _, new)
	self.Firemode = self:GetUpdatedVar("NWFiremode", name, new)
	self.Delay = self:GetUpdatedVar("NWDelay", name, new)

	self.Count = self:GetUpdatedVar("NWCount", name, new)
	self.Damage = self:GetUpdatedVar("NWDamage", name, new)

	self.Range = self:GetUpdatedVar("NWRange", name, new)
	self.Accuracy = self:GetUpdatedVar("NWAccuracy", name, new)

	self.BaseSpread = self:GetUpdatedVar("NWBaseSpread", name, new)
	self.HipSpread = self:GetUpdatedVar("NWHipSpread", name, new)
	self.MoveSpread = self:GetUpdatedVar("NWMoveSpread", name, new)

	self.MoveSpeed = self:GetUpdatedVar("NWMoveSpeed", name, new)
end

function SWEP:NetRecoil(name, _, new)
	self.Recoil.Kick = self:GetUpdatedVar("NWKick", name, new)

	self.Recoil.HipOffset = self:GetUpdatedVar("NWHipOffset", name, new)
	self.Recoil.HipPitch = self:GetUpdatedVar("NWHipPitch", name, new)

	self.Recoil.AimOffset = self:GetUpdatedVar("NWAimOffset", name, new)
	self.Recoil.AimPitch = self:GetUpdatedVar("NWAimPitch", name, new)

	self.Recoil.Time = self:GetUpdatedVar("NWRecoilTime", name, new)
end

function SWEP:NetReload(name, _, new)
	self.ReloadAmount = self:GetUpdatedVar("NWReloadAmount", name, new)
	self.ReloadTime = self:GetUpdatedVar("NWReloadTime", name, new)
end

function SWEP:NetSights(name, _, new)
	self.Sights.Enabled = self:GetUpdatedVar("NWSightEnabled", name, new)

	self.Sights.Time = self:GetUpdatedVar("NWSightTime", name, new)
	self.Sights.Zoom = self:GetUpdatedVar("NWSightZoom", name, new)
	self.Sights.Distance = self:GetUpdatedVar("NWSightDistance", name, new)
end

function SWEP:NetSounds(name, _, new)
	self.Sounds.Fire = self:GetUpdatedVar("NWFireSound", name, new)
	self.Sounds.Reload = self:GetUpdatedVar("NWReloadSound", name, new)
end

local template = [[
AddCSLuaFile()

SWEP.Base = "spades_base"

SWEP.PrintName = "Unnamed Weapon"
SWEP.Author = "$author"

SWEP.Category = "Voxel"
SWEP.Slot = 2

SWEP.Spawnable = true

SWEP.HoldType = "$holdtype"
SWEP.LowerType = "$lowertype"

SWEP.CustomHoldType = {}
SWEP.CustomLowerType = {}

SWEP.Primary = {
	Ammo = "$ammo",

	ClipSize = $clipsize,
	DefaultClip = 0,
}

-- -1 = automatic, 0 = semi, 1+ = burst
SWEP.Firemode = $firemode
]]

if CLIENT then
	function SWEP:Generate()
		return string.gsub(template, "$(%a+)", {
			author = self:GetOwner():Nick(),
			holdtype = self.HoldType,
			lowertype = self.LowerType,
			ammo = self.Primary.Ammo,
			clipsize = self.Primary.ClipSize,
			firemode = self.Firemode
		})
	end
else
	function SWEP:LoadFromClass(class)
		local data = weapons.Get(class)

		if not data or not data.SpadesWeapon then
			return
		end

		-- Model data
		self:SetNWVoxelModel(data.Voxel.Model)
		self:SetNWVoxelScale(data.Voxel.Scale)

		-- View data
		self:SetNWViewPos(data.Voxel.View.Pos)
		self:SetNWViewAng(data.Voxel.View.Ang)

		self:SetNWWorldPos(data.Voxel.World.Pos)
		self:SetNWWorldAng(data.Voxel.World.Ang)

		self:SetNWLowerPos(data.Voxel.Lower.Pos)
		self:SetNWLowerAng(data.Voxel.Lower.Ang)

		-- Holdtypes
		self:SetNWHoldType(holdTypesToIndex[data.HoldType])
		self:SetNWLowerType(holdTypesToIndex[data.LowerType])

		-- Ammo data
		self:SetNWAmmo(game.GetAmmoID(data.Primary.Ammo))
		self:SetNWClipSize(data.Primary.ClipSize)
		self:SetNWCost(data.Cost)

		-- Main stats
		self:SetNWFiremode(data.Firemode)

		self:SetNWDelay(data.Delay)
		self:SetNWCount(data.Count)
		self:SetNWDamage(data.Damage)

		self:SetNWRange(data.Range)
		self:SetNWAccuracy(data.Accuracy)

		self:SetNWBaseSpread(data.BaseSpread)
		self:SetNWHipSpread(data.HipSpread)
		self:SetNWMoveSpread(data.MoveSpread)

		self:SetNWMoveSpeed(data.MoveSpeed)

		-- Recoil
		self:SetNWKick(data.Recoil.Kick)

		self:SetNWHipOffset(data.Recoil.HipOffset)
		self:SetNWHipPitch(data.Recoil.HipPitch)

		self:SetNWAimOffset(data.Recoil.AimOffset)
		self:SetNWAimPitch(data.Recoil.AimPitch)

		self:SetNWRecoilTime(data.Recoil.Time)

		-- Reloading
		self:SetNWReloadAmount(data.ReloadAmount)
		self:SetNWReloadTime(data.ReloadTime)

		-- Sights
		self:SetNWSightEnabled(data.Sights.Enabled)

		self:SetNWSightTime(data.Sights.Time)
		self:SetNWSightZoom(data.Sights.Zoom)
		self:SetNWSightDistance(data.Sights.Distance)

		-- Sounds
		self:SetNWFireSound(data.Sounds.Fire)
		self:SetNWReloadSound(data.Sounds.Reload or "")
	end
end
