local mat = Material("engine/occlusionproxy")

function SWEP:GetWorldPos()
	local ply = self:GetOwner()

	local pos = self:GetPos()
	local ang = self:GetAngles()

	if IsValid(ply) then
		local index = ply:LookupBone("ValveBiped.Bip01_R_Hand")

		pos, ang = ply:GetBonePosition(index)
		pos, ang = LocalToWorld(self.Voxel.World.Pos, self.Voxel.World.Ang, pos, ang + Angle(-10, 0, 180))
	end

	return pos, ang
end

function SWEP:DrawWorldModel()
	-- Needed for lighting
	render.ModelMaterialOverride(mat)
		self:DrawModel()
	render.ModelMaterialOverride()

	local model = self.VoxelModel

	if not IsValid(model) then
		return
	end

	local pos, ang = self:GetWorldPos()
	local matrix = Matrix()
	local scale = self.Voxel.Scale

	matrix:SetTranslation(pos)
	matrix:SetAngles(ang)
	matrix:SetScale(Vector(scale, scale, scale))

	cam.PushModelMatrix(matrix, true)
		self:DrawVoxelModel()
	cam.PopModelMatrix()

	self:PostDrawVoxelModel(matrix, false, false)
end
