AddCSLuaFile()

ENT.RenderGroup 	= RENDERGROUP_BOTH

ENT.Base 			= "base_anim"
ENT.Type 			= "anim"

ENT.Spawnable 		= true

ENT.CopySubmodels 	= true

ENT.Model 			= "wa2000"
ENT.Scale 			= 1

ENT.Debug 			= true

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	self:SetupPhysics()

	self:DrawShadow(false)
	self:EnableCustomCollisions(true)

	if CLIENT then
		if self.CopySubmodels then
			self.Submodels = table.Copy(self:GetVModel().Submodels)
		else
			self.Submodels = {}
		end

		self:UpdateRenderBounds()
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

	if SERVER then
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
end

function ENT:GetVModel()
	return voxel.GetModel(self.Model)
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

function ENT:GetVAttachment(attachment)
	attachment = self:GetVModel().Attachments[attachment]

	return LocalToWorld(attachment.Offset * self.Scale, attachment.Angles, self:GetPos(), self:GetAngles())
end

if CLIENT then
	function ENT:GetVRenderBounds()
		local mins = Vector(math.huge, math.huge, math.huge)
		local maxs = Vector(-math.huge, -math.huge, -math.huge)

		self:GetVModel():GetRenderBounds(mins, maxs, self.Submodels)

		return mins, maxs
	end

	function ENT:UpdateRenderBounds()
		self:SetRenderBounds(self:GetVRenderBounds())
	end

	function ENT:Draw()
		self:DrawModel()

		local matrix = self:GetWorldTransformMatrix()

		matrix:SetScale(Vector(self.Scale, self.Scale, self.Scale))

		cam.PushModelMatrix(matrix, true)
			local color = self:GetColor()

			render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
				self:GetVModel():Draw(self.Submodels, false)
			render.SetColorModulation(1, 1, 1)

			local vModel = self:GetVModel()

			for k, v in pairs(vModel.Attachments) do
				render.DrawLine(v.Offset, v.Offset + v.Angles:Forward(), Color(255, 0, 0), false)
				render.DrawLine(v.Offset, v.Offset + v.Angles:Right(), Color(0, 255, 0), false)
				render.DrawLine(v.Offset, v.Offset + v.Angles:Up(), Color(0, 0, 255), false)

				local camMatrix = cam.GetModelMatrix()

				local camang = (LocalPlayer():EyePos() - (camMatrix * v.Offset)):Angle()

				camang:RotateAroundAxis(camang:Forward(), 90)
				camang:RotateAroundAxis(camang:Right(), -90)

				cam.Start3D2D(camMatrix * v.Offset + Vector(0, 0, 3), camang, 0.1)
					cam.IgnoreZ(true)
					render.PushFilterMag(TEXFILTER.POINT)
					render.PushFilterMin(TEXFILTER.POINT)

					draw.DrawText(k, "BudgetLabel", 0, 0, color_white, TEXT_ALIGN_CENTER)

					render.PopFilterMin()
					render.PopFilterMag()
					cam.IgnoreZ(false)
				cam.End3D2D()
			end
		cam.PopModelMatrix()
	end

	function ENT:DrawTranslucent()
		self:Draw()
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

		matrix:SetScale(Vector(self.Scale, self.Scale, self.Scale))

		return {
			Mesh = renderMesh,
			Material = renderMat,
			Matrix = matrix
		}
	end
end
