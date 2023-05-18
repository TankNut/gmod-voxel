local mat = Material("engine/occlusionproxy")

function SWEP:GetViewPos()
	local ply = self:GetOwner()
	local vm = ply:GetViewModel()
	local pos, ang = vm:GetPos(), vm:GetAngles()

	pos, ang = LocalToWorld(self.VoxelData.ViewPos.Pos, self.VoxelData.ViewPos.Ang, pos, ang)

	return pos, ang
end

function SWEP:GetTracerOrigin()
	local pos, ang = self:GetVoxelModel():GetAttachment("muzzle")

	return LocalToWorld(pos, ang, self:GetViewPos())
end

function SWEP:PreDrawViewModel()
	local model, scale = self:GetVoxelModel()

	if not model then
		return
	end

	local pos, ang = self:GetViewPos()
	local matrix = Matrix()

	matrix:SetTranslation(pos)
	matrix:SetAngles(ang)
	matrix:SetScale(Vector(scale, scale, scale))

	cam.PushModelMatrix(matrix, true)
		model:Draw({}, true)
	cam.PopModelMatrix()

	render.ModelMaterialOverride(mat)
end

function SWEP:PostDrawViewModel()
	render.ModelMaterialOverride()

	local model, scale = self:GetVoxelModel()

	if not model then
		return
	end

	local pos, ang = self:GetViewPos()
	local matrix = Matrix()

	matrix:SetTranslation(pos)
	matrix:SetAngles(ang)
	matrix:SetScale(Vector(scale, scale, scale))

	cam.PushModelMatrix(matrix, true)
		model:Draw({}, true)
	cam.PopModelMatrix()
end
