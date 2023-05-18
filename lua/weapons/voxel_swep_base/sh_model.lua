AddCSLuaFile()

function SWEP:GetVoxelModel()
	return voxel.GetModel(self.VoxelData.Model), self.VoxelData.Scale
end

function SWEP:SetupModel()
	local model, scale = self:GetVoxelModel()

	self:SetupPhysics(model, scale)

	if CLIENT then
		self:UpdateRenderBounds(model, scale)
	end
end

function SWEP:SetupPhysics(model, scale)
	local mins, maxs = model:GetBounds()

	mins = mins * scale
	maxs = maxs * scale

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
	function SWEP:UpdateRenderBounds(model, scale)
		local mins = Vector(math.huge, math.huge, math.huge)
		local maxs = Vector(-math.huge, -math.huge, -math.huge)

		model:GetComplexBounds(mins, maxs, {})

		self:SetRenderBounds(mins * scale, maxs * scale)
	end
end
