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
	self:DoRecoil()

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

function SWEP:SecondaryAttack()
end
