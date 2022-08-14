AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.CopySubModels = true

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")

	self:DrawShadow(false)
	self:EnableCustomCollisions(true)

	if CLIENT then
		self.SubModels = {}
	end

	self:SetupVoxelModel(self:GetVoxelModel(), self:GetVoxelScale())
end

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "VoxelModel")
	self:NetworkVar("Float", 0, "VoxelScale")

	self:NetworkVarNotify("VoxelModel", self.NotifyChanged)
	self:NetworkVarNotify("VoxelScale", self.NotifyChanged)

	if SERVER and self.VoxelModel then
		self:SetVoxelModel(self.VoxelModel)
		self:SetVoxelScale(self.VoxelScale)
	end
end

function ENT:SetupPhysics(model, scale)
	local mins, maxs = voxel.GetModel(model):GetBounds()

	mins = mins * scale
	maxs = maxs * scale

	if IsValid(self.PhysCollide) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox(mins, maxs)

	if SERVER then
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			self:ConfigurePhysics(phys, model, scale)
		end
	end
end

if SERVER then
	function ENT:ConfigurePhysics(phys, model, scale)
		phys:EnableMotion(false)

		local vModel = voxel.GetModel(model)

		phys:SetMass(vModel:GetVMesh().Grid:GetCount() * (scale^3) * 0.01)
	end
end

function ENT:NotifyChanged(name, old, new)
	if old == new then
		return
	end

	local model = name == "VoxelModel" and new or self:GetVoxelModel()
	local scale = name == "VoxelScale" and new or self:GetVoxelScale()

	if model != "" and scale != 0 then
		self:SetupVoxelModel(model, scale)
	end
end

function ENT:SetupVoxelModel(model, scale)
	self:SetupPhysics(model, scale)

	if CLIENT then
		if self.CopySubModels then
			self.SubModels = table.Copy(voxel.GetModel(model).SubModels)
		end

		self:UpdateRenderBounds(model, scale)
	end
end

function ENT:GetVModel()
	return voxel.GetModel(self:GetVoxelModel())
end

function ENT:GetVAttachment(attachment)
	attachment = self:GetVModel().Attachments[attachment]

	return LocalToWorld(attachment.Offset * self:GetVoxelScale(), attachment.Angles, self:GetPos(), self:GetAngles())
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
	function ENT:UpdateRenderBounds(model, scale)
		local mins = Vector(math.huge, math.huge, math.huge)
		local maxs = Vector(-math.huge, -math.huge, -math.huge)

		voxel.GetModel(model):GetComplexBounds(mins, maxs, self.SubModels)

		self:SetRenderBounds(mins * scale, maxs * scale)
	end

	function ENT:Draw()
		self:DrawModel()

		local matrix = self:GetWorldTransformMatrix()
		local scale = self:GetVoxelScale()

		matrix:SetScale(Vector(scale, scale, scale))

		cam.PushModelMatrix(matrix, true)
			local color = self:GetColor()

			render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
				self:GetVModel():Draw(self.SubModels)
			render.SetColorModulation(1, 1, 1)
		cam.PopModelMatrix()
	end

	function ENT:GetRenderMesh()
		local vModel = self:GetVModel()
		local vMesh = vModel:GetVMesh()

		local renderMesh
		local renderMat

		if vMesh then
			renderMesh = vMesh.Mesh
			renderMat = vMesh.Mat
		else
			renderMesh = voxel.Cube
			renderMat = voxel.Mat
		end

		local matrix = Matrix()
		local scale = self:GetVoxelScale()

		matrix:SetScale(Vector(scale, scale, scale))
		matrix:Translate(vModel.Offset)

		return {
			Mesh = renderMesh,
			Material = renderMat,
			Matrix = matrix
		}
	end
end
