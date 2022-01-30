AddCSLuaFile()

ENT.RenderGroup 			= RENDERGROUP_OPAQUE

ENT.Base 					= "base_anim"
ENT.Type 					= "anim"

ENT.PrintName 				= "Voxel Editor"
ENT.Author 					= "TankNut"

ENT.Spawnable 				= true
ENT.AdminOnly				= false

include("net.lua")

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")

	self.Grid = voxel.Grid()

	if CLIENT then
		net.Start("voxel_editor_sync")
			net.WriteEntity(self)
		net.SendToServer()
	else
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self:SetUseType(SIMPLE_USE)

		self.Grid:Set(0, 0, 0, color_white)

		self:SetOwningPlayer(self:GetCreator())
	end

	self:SetVoxelScale(2)
	self:SetVoxelOffset(Vector(0, 0, 20))
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "OwningPlayer")

	self:NetworkVar("Float", 0, "VoxelScale")

	self:NetworkVar("Vector", 0, "VoxelOffset")
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
	function ENT:Draw()
		self:DrawModel()

		local ang = self:GetAngles()

		render.SetMaterial(voxel.Mat)

		local offset, scale = self:GetOffsetData()

		for index, color in pairs(self.Grid.Items) do
			local x, y, z = voxel.Grid.FromIndex(index)
			local pos = self:LocalToWorld(offset + Vector(x, y, z) * scale)

			voxel.Mat:SetVector("$color", color:ToVector())

			local matrix = Matrix()

			matrix:SetTranslation(pos)
			matrix:SetAngles(ang)
			matrix:SetScale(Vector(scale, scale, scale))

			cam.PushModelMatrix(matrix)
				voxel.Cube:Draw()
			cam.PopModelMatrix()
		end
	end
else
	function ENT:Use(ply)
		local tool = ply:GetWeapon("voxel_tool")

		if not IsValid(tool) then
			tool = ply:Give("voxel_tool")
		end

		tool:SetEditEntity(self)

		net.Start("voxel_editor_switch")
		net.Send(ply)

		debugoverlay.Cross(ply:GetPos(), 10)
	end
end
