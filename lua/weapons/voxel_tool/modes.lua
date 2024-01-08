AddCSLuaFile()

function SWEP:CallMirrored(ent, x, y, z, callback)
	local tab = {{x, y, z}}

	if ent:GetMirrorX() then
		table.insert(tab, {-x, y, z})
	end

	if ent:GetMirrorY() then
		for _, v in pairs(table.Copy(tab)) do
			table.insert(tab, {v[1], -v[2], v[3]})
		end
	end

	if ent:GetMirrorZ() then
		for _, v in pairs(table.Copy(tab)) do
			table.insert(tab, {v[1], v[2], -v[3]})
		end
	end

	local mask = {}

	for _, v in pairs(tab) do
		local index = voxel.Grid.ToIndex(v[1], v[2], v[3])

		if mask[index] then
			continue
		end

		mask[index] = true
		print(v[1], v[2], v[3])
		callback(v[1], v[2], v[3])
	end
end

-- Build

function SWEP:ModeBuildPrimary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	self:CallMirrored(ent, x, y, z, function(x2, y2, z2)
		ent:Set(x2, y2, z2, nil)
	end)
end

function SWEP:ModeBuildSecondary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	local pickColor = ent.Grid:Get(x, y, z)

	x = x + normal.x
	y = y + normal.y
	z = z + normal.z

	self:CallMirrored(ent, x, y, z, function(x2, y2, z2)
		if not self:CheckBounds(x2, y2, z2) then
			return
		end

		ent:Set(x2, y2, z2, alt and pickColor or self:GetSelectedColor())
	end)
end

function SWEP:ModeBuildInfo(alt)
	local colors = self.Colors
	local color = self:GetTrace() and colors.Foreground or colors.ForegroundDisabled

	return {
		{Text = "Left: Remove voxel", Color = color},
		{Text = string.format("Right: %s voxel", alt and "Extend" or "Add"), Color = color},
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
		{Text = string.format("Right: %s CW", alt and "Pivot" or "Rotate"), Color = color},
		true,
		{Text = "Reload: Open UI", Color = colors.Foreground}
	}
end

-- Paint

function SWEP:ModePaintPrimary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	self:CallMirrored(ent, x, y, z, function(x2, y2, z2)
		ent:Set(x2, y2, z2, self:GetSelectedColor())
	end)
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

	color = Color(color.r, color.g, color.b)

	self:CallMirrored(ent, x, y, z, function(x2, y2, z2)
		ent:Set(x2, y2, z2, color)
	end)
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

	color = Color(color.r, color.g, color.b)

	self:CallMirrored(ent, x, y, z, function(x2, y2, z2)
		ent:Set(x2, y2, z2, color)
	end)
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

-- Mask

function SWEP:ModeMaskPrimary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	if alt then
		local a = self:GetSelectedColor().r

		for _, v in pairs(ent.Grid.Items) do
			v.a = a
		end

		ent:SyncToPlayer()
	else
		local color = ColorAlpha(ent.Grid:Get(x, y, z), self:GetSelectedColor().r)

		self:CallMirrored(ent, x, y, z, function(x2, y2, z2)
			ent:Set(x2, y2, z2, color)
		end)
	end
end

function SWEP:ModeMaskSecondary(ent, normal, x, y, z, alt)
	if not normal then
		return
	end

	local col = ent.Grid:Get(x, y, z)
	local ply = self:GetOwner()

	ply:ConCommand("voxel_col_r " .. col.a)
	ply:ConCommand("voxel_col_g " .. col.a)
	ply:ConCommand("voxel_col_b " .. col.a)
end

function SWEP:ModeMaskInfo(alt)
	local colors = self.Colors
	local color = self:GetTrace() and colors.Foreground or colors.ForegroundDisabled

	local val = alt and " to everything" or ""

	return {
		{Text = "Left: Apply mask" .. val, Color = color},
		{Text = "Right: Copy mask", Color = color},
		true,
		{Text = "Reload: Open UI", Color = colors.Foreground}
	}
end
