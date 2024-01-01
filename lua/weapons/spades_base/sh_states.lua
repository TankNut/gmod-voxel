AddCSLuaFile()

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

function SWEP:UpdateStates()
	self:SetSprintState(math.Approach(self:GetSprintState(), self:ShouldLower() and 1 or 0, FrameTime() / self.Sights.Time))
	self:SetAimState(math.Approach(self:GetAimState(), self:ShouldAim() and 1 or 0, FrameTime() / self.Sights.Time))
end
