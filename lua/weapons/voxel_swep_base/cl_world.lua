local mat = Material("engine/occlusionproxy")

function SWEP:GetWorldPos()
	local ply = self:GetOwner()

	local pos = self:GetPos()
	local ang = self:GetAngles()

	if IsValid(ply) then
		local index = ply:LookupBone("ValveBiped.Bip01_R_Hand")

		pos, ang = ply:GetBonePosition(index)
		pos, ang = LocalToWorld(self.VoxelData.WorldPos.Pos, self.VoxelData.WorldPos.Ang, pos, ang + Angle(-10, 0, 180))
	end

	return pos, ang
end

function SWEP:DrawWorldModel()
	render.ModelMaterialOverride(mat)
		self:DrawModel()
	render.ModelMaterialOverride()

	local model, scale = self:GetVoxelModel()

	if not model then
		return
	end

	local pos, ang = self:GetWorldPos()
	local matrix = Matrix()

	matrix:SetTranslation(pos)
	matrix:SetAngles(ang)
	matrix:SetScale(Vector(scale, scale, scale))

	cam.PushModelMatrix(matrix, true)
		model:Draw({}, true)
	cam.PopModelMatrix()
end
