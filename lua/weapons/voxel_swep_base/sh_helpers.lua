AddCSLuaFile()

function SWEP:HasCameraControl()
	local ply = self:GetOwner()

	if CLIENT and not ply:ShouldDrawLocalPlayer() then
		return true
	end

	return ply:GetViewEntity() == ply
end

function SWEP:ForceStopFire()
	local ply = self:GetOwner()

	if not IsValid(ply) or not ply:IsPlayer() then
		return
	end

	ply:ConCommand("-attack")
end
