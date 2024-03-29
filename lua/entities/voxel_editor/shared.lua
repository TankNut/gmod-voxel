AddCSLuaFile()

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName = "Editor"
ENT.Category = "Voxel"

ENT.Author = "TankNut"

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.DisableDuplicator = true

include("attachments.lua")
include("grid.lua")
include("net.lua")

local spawnOffset = 75

function ENT:SpawnFunction(ply, tr, class)
	local ent = ents.Create(class)

	ent:Spawn()
	ent:Activate()

	if not IsValid(ent) then
		return
	end

	local dist = tr.StartPos:Distance(tr.HitPos)
	local radius = ent:GetModelRadius()
	local max = spawnOffset + radius

	local pos

	if dist > max then
		pos = tr.StartPos + tr.Normal * spawnOffset
	else
		pos = tr.HitPos - tr.Normal * radius
	end

	local ang = Angle(0, ply:EyeAngles().y + 180, 0):SnapTo("y", 90)

	ent:SetPos(pos)
	ent:SetAngles(ang)

	local phys = ent:GetPhysicsObject()

	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	ent:SetOwningPlayer(ply)
	ent:Use(ply)

	return ent
end

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")

	self.Grid = voxel.Grid()
	self.Attachments = {}

	if CLIENT then
		net.Start("voxel_editor_sync")
			net.WriteEntity(self)
		net.SendToServer()
	else
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self:SetUseType(SIMPLE_USE)

		self.Grid:Set(0, 0, 0, color_white)
	end

	self:SetVoxelScale(2)
	self:SetVoxelOffset(Vector(0, 0, 20))
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "OwningPlayer")

	self:NetworkVar("Float", 0, "VoxelScale")
	self:NetworkVar("Vector", 0, "VoxelOffset")

	self:NetworkVar("Bool", 0, "Fullbright")

	self:NetworkVar("Bool", 1, "MirrorX")
	self:NetworkVar("Bool", 2, "MirrorY")
	self:NetworkVar("Bool", 3, "MirrorZ")
end

function ENT:GetOffsetData()
	return self:GetVoxelOffset(), self:GetVoxelScale()
end

function ENT:Think()
	if CLIENT then
		local minsSelf, maxsSelf = self:GetModelBounds()
		local minsGrid, maxsGrid = self.Grid:GetBounds()

		local offset, scale = self:GetOffsetData()

		minsGrid = (minsGrid + Vector(0.5, 0.5, 0.5)) * scale + offset
		maxsGrid = (maxsGrid + Vector(0.5, 0.5, 0.5)) * scale + offset

		local mins = Vector(math.min(minsSelf.x, minsGrid.x), math.min(minsSelf.y, minsGrid.y), math.min(minsSelf.z, minsGrid.z))
		local maxs = Vector(math.max(maxsSelf.x, maxsGrid.x), math.max(maxsSelf.y, maxsGrid.y), math.max(maxsSelf.z, maxsGrid.z))

		self:SetRenderBounds(mins, maxs)
	end
end

if CLIENT then
	local rgbToVec = 1 / 255

	-- Sweet mother of re-use
	local vec = Vector()
	local matrix = Matrix()
	local scaleVec = Vector()
	local colorVec = Vector()

	local fromIndex = voxel.Grid.FromIndex

	function ENT:Draw()
		self:DrawModel()

		render.SetMaterial(voxel.Mat)

		local offset, scale = self:GetOffsetData()

		scaleVec:SetUnpacked(scale, scale, scale)

		local weapon = LocalPlayer():GetActiveWeapon()
		local mask = IsValid(weapon) and weapon:GetClass() == "voxel_tool" and weapon:GetSelectedMode() == 6
		local fullbright = self:GetFullbright()

		if fullbright then
			render.SuppressEngineLighting(true)
		end

		for index, color in pairs(self.Grid.Items) do
			local x, y, z = fromIndex(index)

			vec:SetUnpacked(x, y, z)
			vec:Mul(scale)
			vec:Add(offset)

			if mask then
				colorVec:SetUnpacked(color.a * rgbToVec, color.a * rgbToVec, color.a * rgbToVec)
			else
				colorVec:SetUnpacked(color.r * rgbToVec, color.g * rgbToVec, color.b * rgbToVec)
			end

			voxel.Mat:SetVector("$color2", colorVec)

			matrix:SetTranslation(self:LocalToWorld(vec))
			matrix:SetAngles(self:GetAngles())
			matrix:SetScale(scaleVec)

			cam.PushModelMatrix(matrix)
				voxel.Cube:Draw()

				if not fullbright then
					render.RenderFlashlights(function() voxel.Cube:Draw() end)
				end
			cam.PopModelMatrix()
		end

		render.SuppressEngineLighting(false)
	end
else
	function ENT:CheckAccess(ply)
		local owner = self:GetOwningPlayer()

		if not IsValid(owner) then
			self:SetOwningPlayer(ply)

			net.Start("voxel_editor_owner")
			net.Send(ply)

			return true
		end

		if ply:IsAdmin() then
			return true
		end

		return owner:GetInfoNum("voxel_access", 0) == 1
	end

	function ENT:Use(ply)
		if not self:CheckAccess(ply) then
			return
		end

		local tool = ply:GetWeapon("voxel_tool")

		if not IsValid(tool) then
			tool = ply:Give("voxel_tool")
		end

		tool:SetEditEntity(self)

		ply:SelectWeapon("voxel_tool")
	end
end
