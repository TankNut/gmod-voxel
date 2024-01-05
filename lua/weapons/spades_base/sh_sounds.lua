AddCSLuaFile()

function SWEP:PlayWeaponSound(snd, static)
	if isfunction(snd) then
		snd = snd(self)
	end

	if snd == nil then
		return
	end

	if static then
		self:EmitSound(snd, 75, 100, 1, CHAN_STATIC)
	else
		self:EmitSound(snd)
	end
end
