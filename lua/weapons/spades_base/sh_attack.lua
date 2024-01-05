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
		self:PlayWeaponSound(self.Sounds.Empty, true)
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

function SWEP:GetSpread(range, accuracy)
	range = range or self.Range
	accuracy = accuracy or self.Accuracy

	local inches = accuracy * 0.75
	local yards = (range * 0.75) / 36

	local spread = (inches * 100) / yards / 60

	local hipSpread = math.Remap(self:GetAimFraction(), 0, 1, self.HipSpread, 0)

	local ply = self:GetOwner()

	local moveSpeed = ply:GetVelocity():Length()
	local maxSpeed = math.Remap(self.MoveSpeed, 0, 1, ply:GetSlowWalkSpeed(), ply:GetWalkSpeed())
	local moveSpread = math.Clamp(math.Remap(moveSpeed, 0, maxSpeed, 0, self.MoveSpread), 0, self.MoveSpread)

	return spread + hipSpread + moveSpread
end


function SWEP:ApplySpread(dir, x, y)
	local theta = math.random() * math.pi * 2
	local unit = math.Rand(-1, 1)

	x = unit * math.cos(theta) * x
	y = unit * math.sin(theta) * y

	local ang = dir:Angle()

	ang:RotateAroundAxis(ang:Right(), x)
	ang:RotateAroundAxis(ang:Up(), y)

	dir:Set(ang:Forward())

	return dir
end

function SWEP:FireWeapon()
	local ply = self:GetOwner()

	math.randomseed(ply:GetCurrentCommand():CommandNumber())

	self:PlayWeaponSound(self.Sounds.Fire)

	ply:SetAnimation(PLAYER_ATTACK1)

	local damage = self:GetDamage()

	local bullet = {
		Num = 1,
		Src = ply:GetShootPos(),
		TracerName = self.Tracer.Effect,
		Tracer = 0,
		Force = damage * 0.1,
		Damage = damage
	}

	local baseDir = (ply:GetAimVector():Angle() + ply:GetViewPunchAngles()):Forward()
	local spread = self:GetSpread()

	self:ApplySpread(baseDir, spread, spread)

	for i = 0, self.Count - 1 do
		if self.Tracer.Frequency > 0 then
			local index = self:Clip1() + 1 + i

			bullet.Tracer = (index % self.Tracer.Frequency == 0) and 1 or 0
		end

		-- Make the first bullet accurate for shotguns
		if self.Count > 0 and i == 0 then
			bullet.Dir = baseDir
		else
			bullet.Dir = self:ApplySpread(Vector(baseDir), self.BaseSpread, self.BaseSpread)
		end

		ply:FireBullets(bullet)
	end

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
