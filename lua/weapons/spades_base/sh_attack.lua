AddCSLuaFile()

function SWEP:CanPrimaryAttack()
	if self:IsReloading() then
		if self.ReloadAmount > 0 then
			self:SetAbortReload(true)
		end

		return false
	end

	if self:ShouldLower() or self:GetSprintState() > 0 then
		return false
	end

	return true
end

function SWEP:UpdateAutomatic()
	if self.Firemode == 0 then
		self.Primary.Automatic = false
	else
		self.Primary.Automatic = true
	end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then
		return
	end

	self:UpdateAutomatic()

	if not self:ConsumeAmmo() then
		return
	end

	self:FireWeapon()
	self:DoRecoil()

	self:SetNextPrimaryFire(CurTime() + self.Delay)
	self:SetLastFire(CurTime())
end

function SWEP:ConsumeAmmo()
	if self:Clip1() < self.Cost then
		self:PlayWeaponSound(self.Sounds.Empty)
		self:SetNextPrimaryFire(CurTime() + 0.2)

		self:ForceStopFire()

		return false
	end

	self:TakePrimaryAmmo(self.Cost)

	return true
end

function SWEP:GetDamage()
	return self.Damage / self.Count
end

function SWEP:GetSpread()
	local spread = math.rad(self.Spread)

	return Vector(spread, spread)
end

function SWEP:FireWeapon()
	local ply = self:GetOwner()

	self:PlayWeaponSound(self.Sounds.Fire)

	ply:SetAnimation(PLAYER_ATTACK1)

	local damage = self:GetDamage()

	local bullet = {
		Num = self.Count,
		Src = ply:GetShootPos(),
		Dir = (ply:EyeAngles() + ply:GetViewPunchAngles()):Forward(),
		Spread = self:GetSpread(),
		TracerName = self.Tracer.Name,
		Tracer = self.Tracer.Name == "" and 0 or self.Tracer.Frequency,
		Force = damage * 0.25,
		Damage = damage
	}

	ply:FireBullets(bullet)

	if SERVER then
		sound.EmitHint(SOUND_COMBAT, self:GetPos(), 1500, 0.2, ply)
	end

	if self.Muzzle.Effect != "" then
		local effect = EffectData()

		effect:SetEntity(self)
		effect:SetScale(self.Muzzle.Size)
		effect:SetOrigin(self:GetPos())

		util.Effect(self.Muzzle.Effect, effect, true)
	end
end

function SWEP:SecondaryAttack()
end
