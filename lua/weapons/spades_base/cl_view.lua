DEFINE_BASECLASS("voxel_swep_base")

function SWEP:GetLowerState()
	local sprint = self.SmoothSprintState
	local deploy = math.ease.InCubic(math.Clamp(math.Remap(CurTime() - self:GetDeployTime(), 0, 0.5, 1, 0), 0, 1))

	return sprint + deploy
end

function SWEP:GetViewPos()
	local pos, ang = BaseClass.GetViewPos(self)

	pos, ang = self:GetRecoilOffset(pos, ang)

	local lowerState = self:GetLowerState()

	pos, ang = LocalToWorld(self.VoxelData.LowerPos.Pos * lowerState, self.VoxelData.LowerPos.Ang * lowerState, pos, ang)

	return pos, ang
end

function SWEP:GetVRecoilFraction()
	return math.Clamp(math.Remap(CurTime() - self:GetLastFire(), 0, 0.1, 1, 0), 0, 1)
end

function SWEP:GetVRecoilDepth()
	return math.Clamp(math.Remap(CurTime() - self:GetLastFire(), 0, self.RecoveryTime, 1, 0), 0, 1)
end

-- 0.75 inspired linear offset
function SWEP:GetRecoilOffset(pos, ang)
	local depth = self:GetVRecoilDepth()

	return LocalToWorld(Vector(
		-math.ease.InCubic(depth) * 1.1,
		math.ease.InQuart(depth) * 0.1,
		math.ease.InCubic(depth) * 0.1) * self.RecoilPunch, angle_zero, pos, ang)
end
