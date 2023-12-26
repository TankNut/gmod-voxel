AddCSLuaFile()

function SWEP:CanPrimaryAttack()
	if self:ShouldLower() or self:GetSprintState() > 0 then
		return false
	end

	return true
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then
		return
	end

	self:FireWeapon()
	self:ApplyRecoil()

	self:SetNextPrimaryFire(CurTime() + self.FireRate)
	self:SetLastFire(CurTime())
end

function SWEP:GetDamage()
	return self.Damage
end

function SWEP:GetSpread()
	local spread = math.rad(self.Spread)

	return Vector(spread, spread)
end

function SWEP:FireWeapon()
	local ply = self:GetOwner()

	self:PlayFireSound()

	ply:SetAnimation(PLAYER_ATTACK1)

	local damage = self:GetDamage()

	local bullet = {
		Num = self.BulletCount,
		Src = ply:GetShootPos(),
		Dir = (ply:EyeAngles() + ply:GetViewPunchAngles()):Forward(),
		Spread = self:GetSpread(),
		TracerName = self.TracerName,
		Tracer = self.TracerName == "" and 0 or self.TracerFrequency,
		Force = damage * 0.25,
		Damage = damage
	}

	ply:FireBullets(bullet)

	if SERVER then
		sound.EmitHint(SOUND_COMBAT, self:GetPos(), 1500, 0.2, ply)
	end

	if self.MuzzleEffect then
		local effect = EffectData()

		effect:SetEntity(self)
		effect:SetScale(self.MuzzleSize)
		effect:SetOrigin(self:GetPos())

		util.Effect(self.MuzzleEffect, effect, true)
	end
end

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

function SWEP:ApplyRecoil()
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

function SWEP:SecondaryAttack()
end
