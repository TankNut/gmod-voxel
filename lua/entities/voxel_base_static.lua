AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.VoxelData = {
	Model = "builtin/directions",
	Scale = 1,

	Offset = Vector()
}

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")

	self:DrawShadow(false)
	self:EnableCustomCollisions(true)

	self.VoxelModel = VoxelModel(self.VoxelData.Model)
	self:SetupVoxelModel()

	hook.Add("VoxelModelLoaded", self, self.VoxelModelLoaded)
end

function ENT:VoxelModelLoaded(model)
	if model.Name == self.VoxelData.Model then
		self:SetupVoxelModel()
	end
end

function ENT:SetupVoxelModel()
	self.VoxelModel = VoxelModel(self.VoxelData.Model)

	self:SetupPhysics()

	if CLIENT then
		self:UpdateRenderBounds()
	end
end

function ENT:SetupPhysics()
	local mins, maxs = self.VoxelModel:GetBounds()

	mins = (mins + self.VoxelData.Offset) * self.VoxelData.Scale
	maxs = (maxs + self.VoxelData.Offset) * self.VoxelData.Scale

	if IsValid(self.PhysCollide) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox(mins, maxs)

	if SERVER then
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			self:ConfigurePhysics(phys)
		end
	end
end

if SERVER then
	function ENT:ConfigurePhysics(phys)
		phys:EnableMotion(false)
		phys:SetMass(self.VoxelModel.Grid:GetCount() * (self.VoxelData.Scale^3) * 0.01)
	end
end

function ENT:GetVAttachment(name)
	local attachment = self.VoxelModel.Attachments[name]

	if not attachment then
		return self:GetPos(), self:GetAngles()
	end

	return LocalToWorld((attachment.Offset + self.VoxelData.Offset) * self.VoxelData.Scale, attachment.Angles, self:GetPos(), self:GetAngles())
end

function ENT:TestCollision(start, delta, isbox, extends)
	if not IsValid(self.PhysCollide) then
		return
	end

	local max = extends
	local min = -extends

	max.z = max.z - min.z
	min.z = 0

	local hit, norm, frac = self.PhysCollide:TraceBox(self:GetPos(), self:GetAngles(), start, start + delta, min, max)

	if not hit then
		return
	end

	return {
		HitPos = hit,
		Normal = norm,
		Fraction = frac
	}
end

if CLIENT then
	function ENT:UpdateRenderBounds()
		local mins, maxs = self.VoxelModel:GetBounds()

		self:SetRenderBounds(mins * self.VoxelData.Scale, maxs * self.VoxelData.Scale)
	end

	function ENT:GetRenderMesh()
		if not IsValid(self.VoxelModel) then
			return
		end

		local matrix = Matrix()
		local scale = self.VoxelData.Scale

		matrix:SetScale(Vector(scale, scale, scale))
		matrix:Translate(self.VoxelData.Offset)

		return {
			Mesh = self.VoxelModel.Mesh,
			Material = self.VoxelModel.Mat,
			Matrix = matrix
		}
	end
end
