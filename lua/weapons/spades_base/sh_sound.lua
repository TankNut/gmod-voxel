AddCSLuaFile()

function SWEP:PlayEmptySound()
	self:EmitSound(self.Sounds.Empty)
end

function SWEP:PlayFireSound()
	self:EmitSound(self.Sounds.Fire)
end
