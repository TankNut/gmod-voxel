AddCSLuaFile()

function SWEP:Think()
	self:HoldTypeThink()

	if game.SinglePlayer() or IsFirstTimePredicted() then
		self:SetSprintState(math.Approach(self:GetSprintState(), self:ShouldLower() and 1 or 0, FrameTime() / self.AimTime))
		self:SetAimState(math.Approach(self:GetAimState(), self:ShouldAim() and 1 or 0, FrameTime() / self.AimTime))
	end
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

SWEP.SprintState = 0

function SWEP:GetSprintState()
	if not game.SinglePlayer() and CLIENT then
		return self.SprintState
	end

	return self:GetNWSprintState()
end

function SWEP:SetSprintState(state)
	if not game.SinglePlayer() and CLIENT then
		self.SprintState = state
	end

	self:SetNWSprintState(state)
end

SWEP.AimState = 0

function SWEP:GetAimState()
	if not game.SinglePlayer() and CLIENT then
		return self.AimState
	end

	return self:GetNWAimState()
end

function SWEP:SetAimState(state)
	if not game.SinglePlayer() and CLIENT then
		self.AimState = state
	end

	self:SetNWAimState(state)

	if CLIENT then
		self.BobScale = Lerp(state, 1, 0.1)
	end
end
