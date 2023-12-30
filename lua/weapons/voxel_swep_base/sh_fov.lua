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
	if self:HasCameraControl() then
		local mult = 1 - (1 / self:GetZoom())

		return 1 - mult / self:GetOwner():GetInfoNum("zoom_sensitivity_ratio", 1)
	end

	return 1
end
