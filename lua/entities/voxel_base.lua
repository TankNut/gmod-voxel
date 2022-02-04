AddCSLuaFile()

ENT.RenderGroup 	= RENDERGROUP_OPAQUE

ENT.Base 			= "base_anim"
ENT.Type 			= "anim"

ENT.Spawnable 		= true

ENT.Model 			= "wa2000"
ENT.Scale 			= 1

ENT.Debug 			= true

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	self:SetupPhysics()

	self:DrawShadow(false)
	self:EnableCustomCollisions(true)

	if CLIENT then
		self.Submodels = table.Copy(self:GetVModel().Submodels)
	end
end

function ENT:SetupPhysics()
	local mins, maxs = self:GetVModel():GetBounds()

	mins = mins * self.Scale
	maxs = maxs * self.Scale

	if IsValid(self.PhysCollide) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox(mins, maxs)

	if CLIENT then
		self:SetRenderBounds(mins, maxs)
	else
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
end

function ENT:GetVModel()
	return voxel.Models[self.Model]
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
	function ENT:Draw()
		self:DrawModel()

		local matrix = self:GetWorldTransformMatrix()

		matrix:SetScale(Vector(self.Scale, self.Scale, self.Scale))

		cam.PushModelMatrix(matrix, true)
			self:GetVModel():Draw(self.Submodels, false, self.Debug)
		cam.PopModelMatrix()
	end

	function ENT:GetRenderMesh()
		local vModel = self:GetVModel()
		local vMesh = voxel.Meshes[vModel.Mesh]

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

		matrix:SetScale(Vector(self.Scale, self.Scale, self.Scale))

		return {
			Mesh = renderMesh,
			Material = renderMat,
			Matrix = matrix
		}
	end
end
