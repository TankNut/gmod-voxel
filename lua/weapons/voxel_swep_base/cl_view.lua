local mat = Material("engine/occlusionproxy")

function SWEP:GetViewPos()
	local ply = self:GetOwner()
	local vm = ply:GetViewModel()
	local pos, ang = vm:GetPos(), vm:GetAngles()

	pos, ang = LocalToWorld(self.VoxelData.ViewPos.Pos, self.VoxelData.ViewPos.Ang, pos, ang)

	return pos, ang
end

function SWEP:GetTracerOrigin()
	local pos, ang = self.VoxelModel:GetAttachment("muzzle")

	return LocalToWorld(pos, ang, self:GetViewPos())
end

function SWEP:PreDrawViewModel()
	-- Need to render the viewmodel for lighting
	render.ModelMaterialOverride(mat)
end

function SWEP:PostDrawViewModel()
	render.ModelMaterialOverride()

	local model = self.VoxelModel

	if not IsValid(model) then
		return
	end

	local pos, ang = self:GetViewPos()
	local matrix = Matrix()
	local scale = self.VoxelData.Scale

	matrix:SetTranslation(pos)
	matrix:SetAngles(ang)
	matrix:SetScale(Vector(scale, scale, scale))

	cam.PushModelMatrix(matrix, true)
		model:Draw()
	cam.PopModelMatrix()
end
