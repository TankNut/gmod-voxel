AddCSLuaFile()

function SWEP:HasCameraControl()
	local ply = self:GetOwner()

	if CLIENT and not ply:ShouldDrawLocalPlayer() then
		return true
	end

	return ply:GetViewEntity() == ply
end
