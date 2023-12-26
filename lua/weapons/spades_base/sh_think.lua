AddCSLuaFile()

function SWEP:Think()
	self:HoldTypeThink()
	self:SprintThink()
	self:AimThink()
end

function SWEP:GetIdealHoldType()
	return self:ShouldLower() and self.LowerType or self.HoldType
end

function SWEP:HoldTypeThink()
	local holdtype = self:GetHoldType()
	local target = self:GetIdealHoldType()

	if holdtype != target then
		self:SetHoldType(target)
	end
end

function SWEP:SprintThink()
	local dt = engine.TickInterval()
	local sprint = self:GetSprintState()
	local old = sprint

	if self:ShouldLower() then
		sprint = math.min(sprint + dt * 4, 1)
	else
		sprint = math.max(sprint - dt * 3, 0)
	end

	if old != sprint then
		self:SetSprintState(sprint)
	end

	if CLIENT then
		local smooth = sprint * sprint

		if smooth > self.SmoothSprintState then
			self.SmoothSprintState = self.SmoothSprintState + (smooth - self.SmoothSprintState) * (1 - math.pow(0.001, dt))
		else
			self.SmoothSprintState = self.SmoothSprintState - (self.SmoothSprintState - smooth) * (1 - math.pow(0.001, dt))
		end
	end
end

function SWEP:AimThink()
	local dt = engine.TickInterval()
	local aim = self:GetAimState()
	local old = aim

	if self:ShouldAim() then
		aim = math.min(aim + dt * (1 / self.AimTime), 1)
	else
		aim = math.max(aim - dt * (1 / self.AimTime), 0)
	end

	if old != aim then
		self:SetAimState(aim)
	end

	if CLIENT then
		local smooth = aim * aim

		if smooth > self.SmoothAimState then
			self.SmoothAimState = self.SmoothAimState + (smooth - self.SmoothAimState) * (1 - math.pow(0.001, dt))
		else
			self.SmoothAimState = self.SmoothAimState - (self.SmoothAimState - smooth) * (1 - math.pow(0.001, dt))
		end

		self.BobScale = 1 - self.SmoothAimState * 0.8
	end
end
