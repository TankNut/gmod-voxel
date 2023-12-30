AddCSLuaFile()

function SWEP:GetBaseFOV()
	local ply = CLIENT and LocalPlayer() or self:GetOwner()

	return ply:GetInfoNum("fov_desired", 75)
end

function SWEP:GetZoom()
	return 1
end

function SWEP:GetFOV()
	return self:GetBaseFOV() / self:GetZoom()
end

function SWEP:TranslateFOV()
	local fov = self:GetFOV()

	self.ViewModelFOV = self.BaseViewModelFOV + (self:GetBaseFOV() - fov) * 0.6

	return fov
end

function SWEP:AdjustMouseSensitivity()
	return self:HasCameraControl() and 1 / self:GetZoom() or 1
end
