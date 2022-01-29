AddCSLuaFile()

-- Build

function SWEP:ModeBuildPrimary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	ent:Set(x, y, z, nil)
end

function SWEP:ModeBuildSecondary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	x = x + normal.x
	y = y + normal.y
	z = z + normal.z

	if not self:CheckBounds(x, y, z) then
		return
	end

	ent:Set(x, y, z, self:GetSelectedColor())
end

function SWEP:ModeBuildInfo(alt)
	local colors = self.Colors
	local color = self:GetTrace() and colors.Foreground or colors.ForegroundDisabled

	return {
		{Text = "Left: Remove voxel", Color = color},
		{Text = "Right: Add voxel", Color = color},
		true,
		{Text = "Reload: Open UI", Color = colors.Foreground}
	}
end

-- Shift

function SWEP:ModeShiftPrimary(ent, normal, x, y, z, alt)
	if not normal or CLIENT then
		return
	end

	normal:Negate()

	if alt then
		normal:Mul(5)
	end

	local mins, maxs = ent.Grid:GetBounds()

	if not self:CheckBounds((mins + normal):Unpack()) or not self:CheckBounds((maxs + normal):Unpack()) then
		return
	end

	ent:Shift(normal.x, normal.y, normal.z)
end

function SWEP:ModeShiftSecondary(ent, normal, x, y, z, alt)
	if not normal or CLIENT then
		return
	end

	if alt then
		normal:Mul(5)
	end

	local mins, maxs = ent.Grid:GetBounds()

	if not self:CheckBounds((mins + normal):Unpack()) or not self:CheckBounds((maxs + normal):Unpack()) then
		return
	end

	ent:Shift(normal.x, normal.y, normal.z)
end

function SWEP:ModeShiftInfo(alt)
	local colors = self.Colors
	local color = self:GetTrace() and colors.Foreground or colors.ForegroundDisabled

	return {
		{Text = string.format("Left: Push x%s", alt and 5 or 1), Color = color},
		{Text = string.format("Right: Pull x%s", alt and 5 or 1), Color = color},
		true,
		{Text = "Reload: Open UI", Color = colors.Foreground}
	}
end

-- Rotate

function SWEP:ModeRotatePrimary(ent, normal, x, y, z, alt)
	if not normal or CLIENT then
		return
	end

	local ang = Angle()

	ang:RotateAroundAxis(normal, 90)

	if alt then
		ent:RotateAround(ang, x, y, z)
	else
		ent:Rotate(ang)
	end
end

function SWEP:ModeRotateSecondary(ent, normal, x, y, z, alt)
	if not normal or CLIENT then
		return
	end

	local ang = Angle()

	ang:RotateAroundAxis(normal, -90)

	if alt then
		ent:RotateAround(ang, x, y, z)
	else
		ent:Rotate(ang)
	end
end

function SWEP:ModeRotateInfo(alt)
	local colors = self.Colors
	local color = self:GetTrace() and colors.Foreground or colors.ForegroundDisabled

	return {
		{Text = string.format("Left: %s CCW", alt and "Pivot" or "Rotate"), Color = color},
		{Text = string.format("Left: %s CW", alt and "Pivot" or "Rotate"), Color = color},
		true,
		{Text = "Reload: Open UI", Color = colors.Foreground}
	}
end

-- Paint

function SWEP:ModePaintPrimary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	ent:Set(x, y, z, self:GetSelectedColor())
end

if CLIENT then
	hook.Add("PostRender", "voxel_tool", function()
		render.UpdateScreenEffectTexture()
	end)

	function SWEP:PickScreenColor()
		render.PushRenderTarget(render.GetScreenEffectTexture())
			render.CapturePixels()

			local x, y = ScrW() * 0.5, ScrH() * 0.5
			local r, g, b = 0, 0, 0

			if self:GetAlt() then
				local k = 0

				for i = x - 3, x + 4  do
					for j = y - 3, y + 4 do
						local r2, g2, b2 = render.ReadPixel(i, j)

						r = r + r2
						g = g + g2
						b = b + b2

						k = k + 1
					end
				end

				r = r / k
				g = g / k
				b = b / k
			else
				r, g, b = render.ReadPixel(ScrW() * 0.5, ScrH() * 0.5)
			end

			RunConsoleCommand("voxel_col_r", r)
			RunConsoleCommand("voxel_col_g", g)
			RunConsoleCommand("voxel_col_b", b)
		render.PopRenderTarget()
	end
end

function SWEP:ModePaintSecondary(ent, normal, x, y, z, alt)
	local ply = self:GetOwner()

	if not normal then
		if SERVER then
			self:CallOnClient("PickScreenColor")
		end

		return
	end

	local col = ent.Grid:Get(x, y, z)

	ply:ConCommand("voxel_col_r " .. col.r)
	ply:ConCommand("voxel_col_g " .. col.g)
	ply:ConCommand("voxel_col_b " .. col.b)
end

function SWEP:ModePaintInfo(alt)
	local colors = self.Colors

	local world = not tobool(self:GetTrace())
	local pick = string.format("Right: Pick%s color", (alt and world) and " average" or "")

	return {
		{Text = "Left: Apply color", Color = world and colors.ForegroundDisabled or colors.Foreground},
		{Text = pick, Color = colors.Foreground},
		true,
		{Text = "Reload: Open UI", Color = colors.Foreground}
	}
end

-- Shade

local funcs = {
	{ColorToHSV, HSVToColor},
	{ColorToHSL, HSLToColor}
}

function SWEP:ModeShadePrimary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	local ply = self:GetOwner()

	local func = funcs[ply:GetInfoNum("voxel_shade_mode", 1)]
	local hue, sat, val = func[1](ent.Grid:Get(x, y, z))

	local res = ply:GetInfoNum("voxel_shade_res", 0.1)

	if alt then
		sat = math.Clamp(sat + res, 0, 1)
	else
		val = math.Clamp(val + res, 0, 1)
	end

	local color = func[2](hue, sat, val)

	ent:Set(x, y, z, Color(color.r, color.g, color.b))
end

function SWEP:ModeShadeSecondary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	local ply = self:GetOwner()

	local func = funcs[ply:GetInfoNum("voxel_shade_mode", 1)]
	local hue, sat, val = func[1](ent.Grid:Get(x, y, z))

	local res = ply:GetInfoNum("voxel_shade_res", 0.1)

	if alt then
		sat = math.Clamp(sat - res, 0, 1)
	else
		val = math.Clamp(val - res, 0, 1)
	end

	local color = func[2](hue, sat, val)

	ent:Set(x, y, z, Color(color.r, color.g, color.b))
end

function SWEP:ModeShadeInfo(alt)
	local colors = self.Colors
	local color = self:GetTrace() and colors.Foreground or colors.ForegroundDisabled

	local val = alt and "saturation" or "brightness"

	return {
		{Text = "Left: Increase " .. val, Color = color},
		{Text = "Right: Decrease " .. val, Color = color},
		true,
		{Text = "Reload: Open UI", Color = colors.Foreground}
	}
end
