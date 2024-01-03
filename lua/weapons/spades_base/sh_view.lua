AddCSLuaFile()
DEFINE_BASECLASS("voxel_swep_base")

function SWEP:GetAimFraction()
	return math.pow(math.sin(self:GetAimState() * math.pi * 0.5), math.pi)
end

function SWEP:GetZoom()
	return Lerp(self:GetAimFraction(), 1, self.Sights.Zoom)
end

if CLIENT then
	function SWEP:DoDrawCrosshair(x, y)
		x = x - 1
		y = y - 1

		if self:IsReloading() then
			return true
		end

		local offset = math.Round(ScrW() * 0.5 * (self:GetSpread() + self.BaseSpread) / self:GetBaseFOV())
		local fraction = math.Clamp(self:GetAimFraction() + math.ease.OutQuart(self:GetSprintState()), 0, 1)
		local alpha = (1 - fraction) * 200
		local length

		-- Outline
		surface.SetDrawColor(0, 0, 0, alpha)
		surface.DrawRect(x - 1, y - 1, 4, 4)

		length = 5

		surface.DrawRect(x - offset - length - 1, y - 1, length + 2, 4) -- Left
		surface.DrawRect(x + offset + 1, y - 1, length + 2, 4) -- Right

		length = 2

		surface.DrawRect(x - 1, y - offset - length - 1, 4, length + 2) -- Up
		surface.DrawRect(x - 1, y + offset + 1, 4, length + 2) -- Down

		-- fill
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawRect(x, y, 2, 2)

		length = 5

		surface.DrawRect(x - offset - length, y, length, 2) -- Left
		surface.DrawRect(x + offset + 2, y, length, 2) -- Right

		length = 2

		surface.DrawRect(x, y - offset - length, 2, length) -- Up
		surface.DrawRect(x, y + offset + 2, 2, length) -- Down

		return true
	end

	function SWEP:GetRecoilDepth()
		return math.Clamp(math.Remap(CurTime() - self:GetLastFire(), 0, self.Recoil.Time, 1, 0), 0, 1)
	end

	function SWEP:GetAngularRecoilDepth()
		local map = math.Remap(CurTime() - self:GetLastFire(), 0, self.Recoil.Time, 1, 0)

		return -math.ease.InBack(math.Clamp(map, 0, 1))
	end

	function SWEP:ResetViewModelData()
		self.VMData = self:GetViewModelTarget()
	end

	function SWEP:GetViewModelTarget()
		local target = {
			Pos = Vector(self.Voxel.View.Pos),
			Ang = Angle(self.Voxel.View.Ang)
		}

		-- Lower/sprint offset
		do
			local lowerState = self:GetSprintState()

			target.Pos = target.Pos + self.Voxel.Lower.Pos * lowerState
			target.Ang = target.Ang + self.Voxel.Lower.Ang * lowerState
		end

		local aimState = self:GetAimFraction()

		-- Aim offset
		if self.VoxelModel:HasAttachment("aim") then
			local offset, angles = self.VoxelModel:GetAttachment("aim")

			offset = offset * self.Voxel.Scale
			offset:Rotate(self.Voxel.View.Ang)
			offset = -(offset + self.Voxel.View.Pos) + Vector(self.Sights.Distance, 0, 0)

			target.Pos:Add(offset * aimState)
			target.Ang:Add(angles * aimState)
		end

		return target
	end

	local timescale = GetConVar("host_timescale")
	local lastDelta = SysTime()

	-- We're going to do what I call a programmer move and copy much of the logic from ArcCW instead of trying to reinvent the wheel
	function SWEP:GetViewPos(noRecoil)
		-- The target position the viewmodel transitions to
		local target = self:GetViewModelTarget()

		if not self.VMData then
			self:ResetViewModelData()
		end

		-- Constant offset applied to the resulting position
		local add = {
			Pos = Vector(),
			Ang = Angle()
		}

		local aimState = self:GetAimFraction()

		-- Recoil
		if not noRecoil then
			local depth = self:GetRecoilDepth()

			local x = math.ease.InCubic(depth) * math.Remap(aimState, 0, 1, self.Recoil.HipOffset.x, self.Recoil.AimOffset.x)
			local y = math.ease.InQuart(depth) * math.Remap(aimState, 0, 1, self.Recoil.HipOffset.y, self.Recoil.AimOffset.y)
			local z = math.ease.InCubic(depth) * math.Remap(aimState, 0, 1, self.Recoil.HipOffset.z, self.Recoil.AimOffset.z)

			add.Pos:Add(Vector(x, y, z))
			add.Ang:Add(Angle(self:GetAngularRecoilDepth() * math.Remap(aimState, 0, 1, self.Recoil.HipPitch, self.Recoil.AimPitch)))
		end

		local delta

		-- Frametime
		do
			delta = (SysTime() - lastDelta) * timescale:GetFloat()

			local comp = (1 / delta) / 66.66

			if comp < 1 then
				delta = delta * comp
			end
		end

		-- TODO: Why is the multiplayer multiplier needed?
		local speed = 15 * delta * (game.SinglePlayer() and 1 or 2)

		-- I know that this isn't the 'correct' way of using lerp but honestly I can't figure out a better way that doesn't feel stilted
		self.VMData.Pos = LerpVector(speed, self.VMData.Pos, target.Pos)
		self.VMData.Ang = LerpAngle(speed, self.VMData.Ang, target.Ang)

		local vm = self:GetOwner():GetViewModel()
		local pos, ang = LocalToWorld(self.VMData.Pos + add.Pos, self.VMData.Ang + add.Ang, vm:GetPos(), vm:GetAngles())

		return pos, ang
	end

	function SWEP:ShouldHideViewModel()
		return self:IsReloading()
	end

	local mat = Material("reticles/eotech")

	function SWEP:DrawVoxelModel()
		BaseClass.DrawVoxelModel(self)

		--self:DrawHolosight(Vector(-1, 0, 5), Vector(-1, 0, 0), 100, 1, 1, Color(0, 0, 0, 50), 2, 2, Color(255, 0, 0), mat)
	end

	function SWEP:DrawHolosight(pos, normal, distance, glassWidth, glassHeight, glassColor, sightWidth, sightHeight, sightColor, sightMaterial)
		if halo.RenderedEntity() == self then
			return
		end

		render.SetColorMaterial()

		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)

		render.SetStencilReferenceValue(0)

		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		render.ClearStencil()

		render.SetStencilEnable(true)

		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)

		-- Draw mask
		render.DrawQuadEasy(pos, normal, glassWidth, glassHeight, glassColor)

		render.SetStencilCompareFunction(STENCIL_EQUAL)

		-- Draw contents
		if sightMaterial then
			render.SetMaterial(sightMaterial)
		end

		render.DrawQuadEasy(pos + -normal * distance, normal, sightWidth * (distance / 100), sightHeight * (distance / 100), Color(255, 0, 0))

		render.SetStencilEnable(false)
	end
end
