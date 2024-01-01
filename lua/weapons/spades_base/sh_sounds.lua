AddCSLuaFile()

function SWEP:PlayWeaponSound(snd)
	if isfunction(snd) then
		snd = snd(self)
	end

	if snd == nil then
		return
	end

	self:EmitSound(snd)
end
