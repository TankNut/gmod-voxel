DEFINE_BASECLASS("voxel_swep_base")

function SWEP:GetLowerFraction()
	local sprint = self:GetSprintState()
	local deploy = math.Clamp(math.Remap(CurTime() - self:GetDeployTime(), 0, 0.5, 1, 0), 0, 1)

	return math.Clamp(sprint + deploy, 0, 1)
end

function SWEP:GetAimFraction()
	return math.pow(math.sin(self:GetAimState() * math.pi * 0.5), math.pi)
end

function SWEP:GetRecoilDepth()
	return math.Clamp(math.Remap(CurTime() - self:GetLastFire(), 0, self.Recoil.RecoveryTime, 1, 0), 0, 1)
end

function SWEP:GetAngularRecoilDepth()
	local map = math.Remap(CurTime() - self:GetLastFire(), 0, self.Recoil.RecoveryTime, 1, 0)

	return -math.ease.InBack(math.Clamp(map, 0, 1))
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
	local angle = Angle(self:GetAngularRecoilDepth() * math.Remap(aim, 0, 1, self.Recoil.Hipfire.Angle.p, self.Recoil.Aim.Angle.p))

	return pos + offset, ang + angle
end

local timescale = GetConVar("host_timescale")
local lastFrameTime = SysTime()

function SWEP:FrameTime(comp)
	local delta = (SysTime() - lastFrameTime) * timescale:GetFloat()

	-- Stabilizes delta if our FPS is too low
	if comp then
		local target = (1 / delta) / 66.66

		if target < 1 then
			delta = delta * target
		end
	end

	lastFrameTime = SysTime()

	return delta
end

-- We're going to do what I call a programmer move and copy much of the logic from ArcCW instead of trying to reinvent the wheel
function SWEP:GetViewPos(noRecoil)
	local target = {
		Pos = Vector(self.VoxelData.ViewPos.Pos),
		Ang = Angle(self.VoxelData.ViewPos.Ang)
	}

	local add = {
		Pos = Vector(),
		Ang = Angle()
	}

	-- Lower/sprint offset
	do
		local lowerState = self:GetLowerFraction()

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

	-- Recoil
	if not noRecoil then
		local depth = self:GetRecoilDepth()

		local x = math.ease.InCubic(depth) * math.Remap(aimState, 0, 1, self.Recoil.Hipfire.Offset.x, self.Recoil.Aim.Offset.x)
		local y = math.ease.InQuart(depth) * math.Remap(aimState, 0, 1, self.Recoil.Hipfire.Offset.y, self.Recoil.Aim.Offset.y)
		local z = math.ease.InCubic(depth) * math.Remap(aimState, 0, 1, self.Recoil.Hipfire.Offset.z, self.Recoil.Aim.Offset.z)

		add.Pos:Add(Vector(x, y, z))
		add.Ang:Add(Angle(self:GetAngularRecoilDepth() * math.Remap(aimState, 0, 1, self.Recoil.Hipfire.Angle.p, self.Recoil.Aim.Angle.p)))
	end

	if not self.VMData then
		self.VMData = {
			Pos = Vector(target.Pos),
			Ang = Angle(target.Ang)
		}
	end

	-- TODO: Why is the multiplayer multiplier needed?
	local speed = 15 * self:FrameTime(true) * (game.SinglePlayer() and 1 or 2)

	-- I know that this isn't the 'correct' way of using lerp but honestly I can't figure out a better way that doesn't feel stilted
	self.VMData.Pos = LerpVector(speed, self.VMData.Pos, target.Pos)
	self.VMData.Ang = LerpAngle(speed, self.VMData.Ang, target.Ang)

	local vm = self:GetOwner():GetViewModel()
	local pos, ang = LocalToWorld(self.VMData.Pos + add.Pos, self.VMData.Ang + add.Ang, vm:GetPos(), vm:GetAngles())

	return pos, ang
end
