AddCSLuaFile()

function SWEP:SetupModel()
	self.VoxelModel = VoxelModel(self.VoxelData.Model)

	self:SetupPhysics()

	if CLIENT then
		self:UpdateRenderBounds()
	end
end

function SWEP:SetupPhysics()
	local mins, maxs = self.VoxelModel:GetBounds()

	mins = (mins + self.VoxelData.Offset) * self.VoxelData.Scale
	maxs = (maxs + self.VoxelData.Offset) * self.VoxelData.Scale

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

		self:SetRenderBounds(mins * self.VoxelData.Scale, maxs * self.VoxelData.Scale)
	end
end
