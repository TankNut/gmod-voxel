AddCSLuaFile()

local infAmmo = CreateConVar("voxel_ammo_infinite", 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Ammo mode to use for weapons. 0 = standard behavior, 1 = infinite reserves", 0, 1)

function SWEP:IsReloading()
	return self:GetFinishReload() != 0
end

function SWEP:CanReload()
	if self:GetNextPrimaryFire() > CurTime() then
		return false
	end

	if self:IsReloading() or self:Clip1() >= self.Primary.ClipSize then
		return false
	end

	if not infAmmo:GetBool() and self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then
		return false
	end

	return true
end

function SWEP:Reload()
	if not self:CanReload() then
		return
	end

	self:GetOwner():SetAnimation(PLAYER_RELOAD)

	if self.ReloadAmount > 0 then
		self:SetFinishReload(CurTime())
	else
		self:PlayWeaponSound(self.Sounds.Reload)
		self:SetFinishReload(CurTime() + self.ReloadTime)
	end
end

function SWEP:CheckReload()
	local reload = self:GetFinishReload()

	if reload > 0 and reload <= CurTime() then
		self:FinishReload()
	end
end

function SWEP:FinishReload()
	local amount = self.Primary.ClipSize - self:Clip1()
	local ply = self:GetOwner()

	if self.ReloadAmount > 0 then
		amount = math.min(amount, self.ReloadAmount)
	end

	if not infAmmo:GetBool() then
		amount = math.min(amount, ply:GetAmmoCount(self.Primary.Ammo))

		ply:RemoveAmmo(amount, self.Primary.Ammo)
	end

	if not self:GetAbortReload() then
		self:SetClip1(self:Clip1() + amount)
	end

	if self.ReloadAmount > 0 then
		if amount <= 0 or self:GetAbortReload() then
			if IsFirstTimePredicted() then
				self:PlayWeaponSound(self.Sounds.ReloadFinish)
			end

			self:SetAbortReload(false)
			self:SetFinishReload(0)
			self:SetNextPrimaryFire(CurTime() + self.ReloadTime)
		else
			if IsFirstTimePredicted() then
				self:PlayWeaponSound(self.Sounds.ReloadSingle)
			end

			self:SetFinishReload(CurTime() + self.ReloadTime)
		end
	else
		self:SetFinishReload(0)
	end

	self.Primary.Automatic = true
end
