AddCSLuaFile()

function SWEP:GetRecoil()
	return self.Recoil.Kick
end

function SWEP:GetRecoilMultiplier()
	local mul = 1
	local ply = self:GetOwner()
	local vel = ply:GetVelocity():Length()

	mul = mul + math.Clamp(math.Remap(vel / ply:GetWalkSpeed(), 0, 1, 0, 0.5), 0, 0.5)

	if ply:GetMoveType() != MOVETYPE_NOCLIP then
		if not ply:OnGround() then
			mul = mul + 0.5
		elseif ply:Crouching() then
			mul = mul * 0.75
		end
	end

	return mul
end

function SWEP:DoRecoil()
	local ply = self:GetOwner()

	if not IsValid(ply) or not ply:IsPlayer() then
		return
	end

	local dir = ply:GetAimVector()
	local ang = dir:Angle()

	local upLimit = Vector(dir.x, dir.y, 0):Dot(dir)

	local modP = self:GetRecoilMultiplier()
	local modY = modP * math.sqrt(1 - math.pow(dir.z, 4))

	local recoil = self:GetRecoil()

	dir:Add(ang:Up() * math.min(math.rad(recoil.p), math.max(0, upLimit)) * modP)
	dir:Add(ang:Right() * math.rad(recoil.y) * math.Rand(-1, 1) * modY)

	ang = ply:EyeAngles() - dir:Angle()

	ang.p = math.NormalizeAngle(ang.p)
	ang.y = math.NormalizeAngle(ang.y)
	ang.r = math.NormalizeAngle(ang.r)

	ply:SetViewPunchVelocity(ang * -20)

	if game.SinglePlayer() or (CLIENT and IsFirstTimePredicted()) then
		ply:SetEyeAngles(dir:Angle())
	end
end
