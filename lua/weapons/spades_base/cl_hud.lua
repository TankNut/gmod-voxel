function SWEP:InScope()
	return self.Sights.Scoped and self:GetAimState() > 0.5
end

local scope = Material("gmod/scope")

function SWEP:DrawScope(x, y)
	local screenW = ScrW()
	local screenH = ScrH()

	local h = screenH
	local w = (4 / 3) * h

	local dw = (screenW - w) * 0.5

	local midX = screenW * 0.5
	local midY = screenH * 0.5

	surface.SetMaterial(scope)
	surface.SetDrawColor(0, 0, 0)

	surface.DrawLine(0, midY, screenW, midY)
	surface.DrawLine(midX, 0, midX, screenH)

	surface.DrawRect(0, 0, dw, h)
	surface.DrawRect(w + dw, 0, dw, h)

	surface.DrawTexturedRect(dw, 0, w, h)
end

local debugConvar = voxel.Convars.Developer

function SWEP:DoDrawCrosshair(x, y)
	if self:InScope() then
		self:DrawScope(x, y)

		if not debugConvar:GetBool() then
			return true
		end
	end

	x = x - 1
	y = y - 1

	if self:IsReloading() then
		return true
	end

	local offset = math.Round(ScrW() * 0.5 * (self:GetSpread() + self.BaseSpread) / self:GetFOV())
	local fraction = math.Clamp(self:GetAimFraction() + math.ease.OutQuart(self:GetSprintState()), 0, 1)
	local alpha = debugConvar:GetBool() and 255 or (1 - fraction) * 200
	local length

	if alpha == 0 then
		return true
	end

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
