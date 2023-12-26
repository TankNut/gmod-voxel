DEFINE_BASECLASS("voxel_swep_base")

function SWEP:GetLowerFraction()
	local sprint = self.SmoothSprintState
	local deploy = math.ease.InCubic(math.Clamp(math.Remap(CurTime() - self:GetDeployTime(), 0, 0.5, 1, 0), 0, 1))

	return sprint + deploy
end

function SWEP:GetAimFraction()
	return math.ease.OutCubic(self.SmoothAimState)
end

function SWEP:GetLowerPos(pos, ang)
	local lowerState = self:GetLowerFraction()

	pos = pos + self.VoxelData.LowerPos.Pos * lowerState
	ang = ang + self.VoxelData.LowerPos.Ang * lowerState

	return pos, ang
end

function SWEP:GetAimPos(pos, ang)
	local aimState = self:GetAimFraction()
	local offset, angles = self.VoxelModel:GetAttachment("aim")

	if offset != vector_origin then
		offset = offset * self.VoxelData.Scale
		offset = -(offset + self.VoxelData.ViewPos.Pos) + Vector(self.AimDistance, 0, 0)

		pos = pos + offset * aimState
		ang = ang + angles * aimState
	end

	return pos, ang
end

function SWEP:GetRecoilDepth()
	return math.Clamp(math.Remap(CurTime() - self:GetLastFire(), 0, self.Recoil.RecoveryTime, 1, 0), 0, 1)
end

-- 0.75 inspired linear offset
function SWEP:GetVMRecoil(pos, ang)
	local aim = self:GetAimFraction()

	-- Recoil
	local depth = self:GetRecoilDepth()

	local x = math.ease.InCubic(depth) * math.Remap(aim, 0, 1, self.Recoil.Hipfire.Offset.x, self.Recoil.Aim.Offset.x)
	local y = math.ease.InQuart(depth) * math.Remap(aim, 0, 1, self.Recoil.Hipfire.Offset.y, self.Recoil.Aim.Offset.y)
	local z = math.ease.InCubic(depth) * math.Remap(aim, 0, 1, self.Recoil.Hipfire.Offset.z, self.Recoil.Aim.Offset.z)

	local offset = Vector(x, y, z)
	local angle = Angle(-math.ease.InBack(depth) * math.Remap(aim, 0, 1, self.Recoil.Hipfire.Angle.p, self.Recoil.Aim.Angle.p))

	return pos + offset, ang + angle
end

function SWEP:GetViewPos()
	local tPos, tAng = Vector(), Angle()

	tPos = self.VoxelData.ViewPos.Pos
	tAng = self.VoxelData.ViewPos.Ang

	tPos, tAng = self:GetLowerPos(tPos, tAng)
	tPos, tAng = self:GetAimPos(tPos, tAng)

	tPos, tAng = self:GetVMRecoil(tPos, tAng)

	local vm = self:GetOwner():GetViewModel()
	local pos, ang = vm:GetPos(), vm:GetAngles()

	return LocalToWorld(tPos, tAng, pos, ang)
end
