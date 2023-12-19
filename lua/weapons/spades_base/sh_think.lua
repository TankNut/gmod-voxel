AddCSLuaFile()

function SWEP:Think()
	self:HoldTypeThink()
	self:SprintThink()
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
