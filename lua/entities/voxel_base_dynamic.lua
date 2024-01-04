AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.DisableDuplicator = true

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")

	self:DrawShadow(false)
	self:EnableCustomCollisions(true)

	self:SetupVoxelModel()

	hook.Add("VoxelModelLoaded", self, self.VoxelModelLoaded)
end

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "VoxelModel")
	self:NetworkVar("Int", 0, "VoxelScale")
	self:NetworkVar("Vector", 0, "VoxelOffset")

	self:NetworkVarNotify("VoxelModel", self.NotifyChanged)
	self:NetworkVarNotify("VoxelScale", self.NotifyChanged)
	self:NetworkVarNotify("VoxelOffset", self.NotifyChanged)
end

function ENT:NotifyChanged(name, old, new)
	if old == new then
		return
	end

	if name == "VoxelModel" then
		self:SetupVoxelModel(new)
	elseif name == "VoxelScale" then
		self:SetupVoxelModel(nil, new)
	elseif name == "VoxelOffset" then
		self:SetupVoxelModel(nil, nil, new)
	end
end

function ENT:VoxelModelLoaded(model)
	if model == self.VoxelModel then
		self:SetupVoxelModel()
	end
end

function ENT:SetupVoxelModel(model, scale, offset)
	model = model or self:GetVoxelModel()
	scale = scale or self:GetVoxelScale()
	offset = offset or self:GetVoxelOffset()

	if model == "" or scale == 0 then
		return
	end

	self.VoxelModel = VoxelModel(model)
	self.VoxelScale = scale
	self.VoxelOffset = offset

	if not IsValid(self.VoxelModel) then
		return
	end

	self:SetupPhysics()

	if CLIENT then
		self:UpdateRenderBounds()
	end
end

function ENT:SetupPhysics()
	local mins, maxs = self.VoxelModel:GetBounds()

	mins = (mins + self.VoxelOffset) * self.VoxelScale
	maxs = (maxs + self.VoxelOffset) * self.VoxelScale

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
		phys:SetMass(self.VoxelModel.Grid:GetCount() * (self.VoxelScale^3) * 0.01)
	end
end

function ENT:GetVAttachment(name)
	local attachment = self.VoxelModel.Attachments[name]

	if not attachment then
		return self:GetPos(), self:GetAngles()
	end

	return LocalToWorld((attachment.Offset + self.VoxelOffset) * self.VoxelScale, attachment.Angles, self:GetPos(), self:GetAngles())
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

		self:SetRenderBounds(mins * self.VoxelScale, maxs * self.VoxelScale)
	end

	function ENT:GetRenderMesh()
		if not IsValid(self.VoxelModel) then
			return
		end

		local matrix = Matrix()

		matrix:SetScale(Vector(self.VoxelScale, self.VoxelScale, self.VoxelScale))
		matrix:Translate(self.VoxelOffset)

		return {
			Mesh = self.VoxelModel.Mesh,
			Material = self.VoxelModel.Mat,
			Matrix = matrix
		}
	end
end
