AddCSLuaFile()

function SWEP:SetupModel()
	self.VoxelModel = VoxelModel(self.Voxel.Model)
	self:SetupPhysics()

	if CLIENT then
		self:UpdateRenderBounds()
	end
end

function SWEP:SetupPhysics()
	local mins, maxs = self.VoxelModel:GetBounds()

	mins = mins * self.Voxel.Scale
	maxs = maxs * self.Voxel.Scale

	if IsValid(self.PhysCollide) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox(mins, maxs)

	if SERVER then
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
end

if CLIENT then
	function SWEP:UpdateRenderBounds()
		local mins, maxs = self.VoxelModel:GetBounds()

		self:SetRenderBounds(mins * self.Voxel.Scale, maxs * self.Voxel.Scale)
	end

	-- Designed for SWEP:PostDrawVoxelModel
	function SWEP:ViewModelAttachment(matrix, pos, ang)
		pos, ang = LocalToWorld((pos or vector_origin) * self.Voxel.Scale, ang or angle_zero, matrix:GetTranslation(), matrix:GetAngles())

		return pos, ang
	end

	function SWEP:DrawVoxelModel()
		self.VoxelModel:Draw()
	end

	function SWEP:PostDrawVoxelModel(matrix, hidden, viewmodel)
	end
end
