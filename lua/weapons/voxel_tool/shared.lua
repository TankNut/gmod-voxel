AddCSLuaFile()

SWEP.PrintName 				= "Voxel Tool"
SWEP.Author 				= "TankNut"

SWEP.RenderGroup 			= RENDERGROUP_OPAQUE

SWEP.Slot 					= 5
SWEP.SlotPos 				= 10

SWEP.DrawCrosshair 			= true

SWEP.ViewModel 				= Model("models/hunter/blocks/cube025x025x025.mdl")
SWEP.WorldModel 			= ""

SWEP.UseHands 				= false

SWEP.AutoSwitchTo 			= false
SWEP.AutoSwitchFrom 		= false

SWEP.Primary.ClipSize 		= -1
SWEP.Primary.DefaultClip 	= -1
SWEP.Primary.Ammo 			= ""
SWEP.Primary.Automatic 		= false

SWEP.Secondary.ClipSize 	= -1
SWEP.Secondary.DefaultClip 	= -1
SWEP.Secondary.Ammo 		= ""
SWEP.Secondary.Automatic 	= false

SWEP.Modes = {
	{Name = "BUILD", Prefix = "Build"},
	{Name = "SHIFT", Prefix = "Shift"},
	{Name = "ROTATE", Prefix = "Rotate"},
	{Name = "PAINT", Prefix = "Paint"},
	{Name = "SHADE", Prefix = "Shade"}
}

SWEP.Min = -128
SWEP.Max = 127

include("modes.lua")

AddCSLuaFile("draw.lua")
AddCSLuaFile("hud.lua")
AddCSLuaFile("ui.lua")

if CLIENT then
	include("draw.lua")
	include("hud.lua")
	include("ui.lua")
end

function SWEP:Initialize()
	if CLIENT then
		hook.Add("PostDrawOpaqueRenderables", self, function()
			self:PostDrawOpaqueRenderables() -- Updates through reloads
		end)
	else
		hook.Add("AllowPlayerPickup", self, function(_, ply)
			if ply:GetActiveWeapon() == self then
				return false
			end
		end)
	end

	self:SetSelectedMode(1)
end

function SWEP:SetupDataTables()
	self:NetworkVar("Entity", 0, "EditEntity")

	self:NetworkVar("Int", 0, "SelectedMode")
end

function SWEP:PrimaryAttack()
	local ent = self:GetEditEntity()

	if not IsValid(ent) then
		return
	end

	local normal, x, y, z = self:GetTrace()
	local alt = self:GetAlt()

	local mode = self.Modes[self:GetSelectedMode()]

	local func = self[string.format("Mode%sPrimary", mode.Prefix)]

	if func then
		func(self, ent, normal, x, y, z, alt)
	end
end

function SWEP:SecondaryAttack()
	local ent = self:GetEditEntity()

	if not IsValid(ent) then
		return
	end

	local normal, x, y, z = self:GetTrace()
	local alt = self:GetAlt()

	local mode = self.Modes[self:GetSelectedMode()]

	local func = self[string.format("Mode%sSecondary", mode.Prefix)]

	if func then
		func(self, ent, normal, x, y, z, alt)
	end
end

function SWEP:Reload()
	if game.SinglePlayer() then
		self:CallOnClient("Reload")
	end

	if SERVER or self.Reloaded then
		return
	end

	if IsValid(self:GetEditEntity()) then
		self:ToggleUI()
	end

	self.Reloaded = true
end

function SWEP:Think()
	local ply = self:GetOwner()

	if not IsValid(ply) then
		return
	end

	if CLIENT and self.Reloaded and not input.IsKeyDown(input.GetKeyCode(input.LookupBinding("+reload"))) then -- Because ply:KeyDown(IN_RELOAD) doesn't work reliably... for some reason
		self.Reloaded = nil
	end

	if CLIENT and game.SinglePlayer() then
		return
	end

	local cmd = ply:GetCurrentCommand()

	if self:GetAlt() and cmd then
		local delta = cmd:GetMouseWheel()

		if delta != 0 then
			delta = math.Clamp(delta, -1, 1)

			local mode = self:GetSelectedMode() - delta

			if mode > #self.Modes then
				mode = 1
			elseif mode < 1 then
				mode = #self.Modes
			end

			self:SetSelectedMode(mode)
		end
	end
end

function SWEP:GetAlt()
	return self:GetOwner():KeyDown(IN_USE)
end

local function inRange(val, min, max)
	return val >= min and val <= max
end

function SWEP:CheckBounds(x, y, z)
	return inRange(x, self.Min, self.Max) and inRange(x, self.Min, self.Max) and inRange(x, self.Min, self.Max)
end

function SWEP:GetSelectedColor()
	local ply = self:GetOwner()

	if not IsValid(ply) then
		return color_white
	end

	return Color(ply:GetInfoNum("voxel_col_r", 255), ply:GetInfoNum("voxel_col_g", 255),ply:GetInfoNum("voxel_col_b", 255))
end

function SWEP:GetTrace()
	local ent = self:GetEditEntity()

	if not IsValid(ent) then
		return
	end

	local ply = self:GetOwner()
	local pos = ply:GetShootPos()
	local dir = ply:GetAimVector()
	local ang = ent:GetAngles()

	local dist = ply:GetEyeTrace().Fraction * 32768

	local scale = ent:GetVoxelScale()
	local offset = ent:GetVoxelOffset()

	local mins = Vector(-0.5, -0.5, -0.5) * scale
	local maxs = mins:GetNegated()

	local closest = math.huge
	local data

	for index, col in pairs(ent.Grid.Items) do
		local x, y, z = voxel.Grid.FromIndex(index)

		local origin = ent:LocalToWorld(offset + Vector(x, y, z) * scale)
		local hit, normal, frac = util.IntersectRayWithOBB(pos, dir * dist, origin, ang, mins, maxs)

		if hit and frac < closest then
			closest = frac
			data = {normal, x, y, z}
		end
	end

	if data then
		return unpack(data)
	end
end
