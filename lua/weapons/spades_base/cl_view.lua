DEFINE_BASECLASS("voxel_swep_base")

function SWEP:GetRecoilDepth()
	return math.Clamp(math.Remap(CurTime() - self:GetLastFire(), 0, self.Recoil.RecoveryTime, 1, 0), 0, 1)
end

function SWEP:GetAngularRecoilDepth()
	local map = math.Remap(CurTime() - self:GetLastFire(), 0, self.Recoil.RecoveryTime, 1, 0)

	return -math.ease.InBack(math.Clamp(map, 0, 1))
end

function SWEP:ResetViewModelData()
	self.VMData = self:GetViewModelTarget()
end

function SWEP:GetViewModelTarget()
	local target = {
		Pos = Vector(self.VoxelData.ViewPos.Pos),
		Ang = Angle(self.VoxelData.ViewPos.Ang)
	}

	-- Lower/sprint offset
	do
		local lowerState = self:GetSprintState()

		target.Pos = target.Pos + self.VoxelData.LowerPos.Pos * lowerState
		target.Ang = target.Ang + self.VoxelData.LowerPos.Ang * lowerState
	end

	local aimState = self:GetAimFraction()

	-- Aim offset
	if self.VoxelModel:HasAttachment("aim") then
		local offset, angles = self.VoxelModel:GetAttachment("aim")

		offset = offset * self.VoxelData.Scale
		offset = -(offset + self.VoxelData.ViewPos.Pos) + Vector(self.AimDistance, 0, 0)

		target.Pos:Add(offset * aimState)
		target.Ang:Add(angles * aimState)
	end

	return target
end

local timescale = GetConVar("host_timescale")
local lastDelta = SysTime()

-- We're going to do what I call a programmer move and copy much of the logic from ArcCW instead of trying to reinvent the wheel
function SWEP:GetViewPos(noRecoil)
	-- The target position the viewmodel transitions to
	local target = self:GetViewModelTarget()

	if not self.VMData then
		self:ResetViewModelData()
	end

	-- Constant offset applied to the resulting position
	local add = {
		Pos = Vector(),
		Ang = Angle()
	}

	local aimState = self:GetAimFraction()

	-- Recoil
	if not noRecoil then
		local depth = self:GetRecoilDepth()

		local x = math.ease.InCubic(depth) * self.Recoil.Offset.x * (1 - aimState * 0.5)
		local y = math.ease.InQuart(depth) * self.Recoil.Offset.y * (1 - aimState)
		local z = math.ease.InCubic(depth) * self.Recoil.Offset.z * (1 - aimState)

		add.Pos:Add(Vector(x, y, z))
		add.Ang:Add(Angle(self:GetAngularRecoilDepth() * self.Recoil.Angle.p * (1 - aimState * 0.5)))
	end

	local delta

	-- Frametime
	do
		delta = (SysTime() - lastDelta) * timescale:GetFloat()

		local comp = (1 / delta) / 66.66

		if comp < 1 then
			delta = delta * comp
		end
	end

	-- TODO: Why is the multiplayer multiplier needed?
	local speed = 15 * delta * (game.SinglePlayer() and 1 or 2)

	-- I know that this isn't the 'correct' way of using lerp but honestly I can't figure out a better way that doesn't feel stilted
	self.VMData.Pos = LerpVector(speed, self.VMData.Pos, target.Pos)
	self.VMData.Ang = LerpAngle(speed, self.VMData.Ang, target.Ang)

	local vm = self:GetOwner():GetViewModel()
	local pos, ang = LocalToWorld(self.VMData.Pos + add.Pos, self.VMData.Ang + add.Ang, vm:GetPos(), vm:GetAngles())

	return pos, ang
end

function SWEP:ShouldHideViewModel()
	return false
end
