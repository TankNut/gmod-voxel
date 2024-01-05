function SWEP:ShouldDrawLaser(viewmodel)
	if not IsValid(self:GetOwner()) then
		return false, true
	end

	if self:IsReloading() then
		return false, not viewmodel
	end

	if self:GetSprintState() > 0 then
		return false, true
	end

	return true, true
end

function SWEP:DrawViewModelLaser(matrix)
	local beam, sprite = self:ShouldDrawLaser(true)

	if not beam and not sprite then
		return
	end

	local pos, ang = self:ViewModelAttachment(matrix, self.VoxelModel:GetAttachment(self.Laser.Attachment))

	if beam then
		local ply = self:GetOwner()
		local tr = util.TraceLine({
			start = EyePos(),
			endpos = EyePos() + (ply:GetAimVector():Angle() + ply:GetViewPunchAngles()):Forward() * 32768,
			filter = {ply},
			mask = MASK_SHOT
		})

		local hit = tr.StartPos + tr.Normal * math.max(tr.Fraction * 32768, 100)
		local trueHit = tr.StartPos + tr.Normal * tr.Fraction * 32768

		local length = pos:Distance(hit)

		-- Pull it back so the start of the laser is behind the player's eye
		if self:InScope() then
			pos = pos - ang:Forward() * 100
		end

		render.SetMaterial(self.Laser.Beam)
		render.StartBeam(2)
			render.AddBeam(pos, self.Laser.BeamWidth, 0, self.Laser.BeamColor)
			render.AddBeam(hit, self.Laser.BeamWidth, length / 819.6, self.Laser.BeamColor)
		render.EndBeam()

		render.SetMaterial(self.Laser.Sprite)
		render.DrawSprite(trueHit, self.Laser.SpriteWidth, self.Laser.SpriteWidth, self.Laser.SpriteColor)
	end

	if sprite and not self:InScope() then
		render.SetMaterial(self.Laser.Sprite)
		render.DrawSprite(pos, self.Laser.SpriteWidth, self.Laser.SpriteWidth, self.Laser.SpriteColor)
	end
end

function SWEP:DrawWorldModelLaser(matrix)
	local beam, sprite = self:ShouldDrawLaser(false)

	if not beam and not sprite then
		return
	end

	local pos = self:ViewModelAttachment(self.StoredMatrix, self.VoxelModel:GetAttachment(self.Laser.Attachment))

	if beam then
		local ply = self:GetOwner()

		local tr = util.TraceLine({
			start = ply:GetShootPos(),
			endpos = ply:GetShootPos() + (ply:GetAimVector():Angle() + ply:GetViewPunchAngles()):Forward() * 32768,
			filter = {ply},
			mask = MASK_SHOT
		})

		local hit = tr.HitPos - tr.Normal * 2
		local length = pos:Distance(hit)

		render.SetMaterial(self.Laser.Beam)
		render.StartBeam(2)
			render.AddBeam(pos, self.Laser.BeamWidth, 0, self.Laser.BeamColor)
			render.AddBeam(hit, self.Laser.BeamWidth, length / 819.6, self.Laser.BeamColor)
		render.EndBeam()

		render.SetMaterial(self.Laser.Sprite)
		render.DrawSprite(hit, self.Laser.SpriteWidth, self.Laser.SpriteWidth, self.Laser.SpriteColor)
	end

	if sprite then
		local alpha = util.PixelVisible(pos, self.Laser.SpriteWidth * 0.5, self.PixVis)

		cam.IgnoreZ(true)

		render.SetMaterial(self.Laser.Sprite)
		render.DrawSprite(pos, self.Laser.SpriteWidth, self.Laser.SpriteWidth, Color(self.Laser.SpriteColor.r * alpha, self.Laser.SpriteColor.g * alpha, self.Laser.SpriteColor.b * alpha))
	end
end

function SWEP:PostDrawTranslucentRenderables()
	if not self.Laser.Enabled or not self.StoredMatrix then
		return
	end

	self:DrawWorldModelLaser(self.StoredMatrix)
end

function SWEP:PostDrawVoxelModel(matrix, hidden, viewmodel)
	if not self.Laser.Enabled then
		return
	end

	if viewmodel then
		self.StoredMatrix = nil
	else
		self.StoredMatrix = matrix

		return
	end

	self:DrawViewModelLaser(matrix)
end
