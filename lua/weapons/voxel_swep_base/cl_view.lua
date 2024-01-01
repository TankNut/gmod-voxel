local mat = Material("engine/occlusionproxy")

function SWEP:GetViewPos()
	local ply = self:GetOwner()
	local vm = ply:GetViewModel()
	local pos, ang = vm:GetPos(), vm:GetAngles()

	pos, ang = LocalToWorld(self.Voxel.View.Pos, self.Voxel.View.Ang, pos, ang)

	return pos, ang
end

function SWEP:GetTracerOrigin()
	local pos, ang = self.VoxelModel:GetAttachment("muzzle")

	return LocalToWorld(pos, ang, self:GetViewPos())
end

-- Using this instead of ShouldDrawViewModel so GetViewPos can continue to update even if we're not drawing
function SWEP:ShouldHideViewModel()
	return false
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

	if self:ShouldHideViewModel() then
		return
	end

	local matrix = Matrix()
	local scale = self.Voxel.Scale

	matrix:SetTranslation(pos)
	matrix:SetAngles(ang)
	matrix:SetScale(Vector(scale, scale, scale))

	cam.PushModelMatrix(matrix, true)
		model:Draw()
	cam.PopModelMatrix()
end
