function SWEP:HUDShouldDraw(element)
	if self:GetAlt() and element == "CHudWeaponSelection" then
		return false
	end

	return true
end

SWEP.Colors = {
	Background = Color(0, 0, 0, 76),
	Foreground = Color(255, 235, 20),
	ForegroundSelected = Color(255, 48, 0),
	ForegroundDisabled = Color(255, 235, 20, 20)
}

function SWEP:DrawHUD()
	local colors = self.Colors

	local size = ScreenScale(27)
	local offset = ScreenScale(9)

	local origin = ScrW() * 0.5
	local pull = (#self.Modes * (size + offset) - offset) * 0.5

	for k, v in pairs(self.Modes) do
		local x = origin + (k - 1) * (size + offset) - pull
		local y = ScrH() - offset - size

		draw.RoundedBox(8, x, y, size, size, self.Colors.Background)
		draw.SimpleText(v.Name, "HudDefault", x + size * 0.5, y + size * 0.5, k == self:GetSelectedMode() and colors.ForegroundSelected or colors.Foreground, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local x, y = offset, offset
	local mode = self.Modes[self:GetSelectedMode()]

	local lines

	if not IsValid(self:GetEditEntity()) then
		lines = {
			{Text = "Error: Not linked to an entity", Color = colors.ForegroundSelected}
		}
	else
		local func = self[string.format("Mode%sInfo", mode.Prefix)]

		if not func then
			return
		end

		lines = func(self, self:GetAlt())
	end

	if #lines < 1 then
		return
	end

	local width = 0
	local inset = ScreenScale(3)

	surface.SetFont("HudDefault")

	for _, v in pairs(lines) do
		if v == true then
			continue
		end

		local w = surface.GetTextSize(v.Text)

		width = math.max(width, w)
	end

	draw.RoundedBox(8, x, y, width + inset * 2, #lines * 22 + inset * 2, colors.Background)

	for k, v in pairs(lines) do
		if v == true then
			continue
		end

		draw.SimpleText(v.Text, "HudDefault", x + inset, y + inset + 22 * (k - 1), v.Color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	if IsValid(self:GetEditEntity()) and voxel.Convars.ExtraInfo:GetBool() then
		self:DrawExtraInfo()
	end
end

function SWEP:DrawExtraInfo()
	local ent = self:GetEditEntity()
	local colors = self.Colors

	local offset = ScreenScale(9)
	local inset = ScreenScale(3)

	local width = 0

	local normal, cursorX, cursorY, cursorZ = self:GetTrace()

	local lines = {
		{string.format("Grid size: [%i, %i, %i]", ent.Grid:GetSize():Unpack())},
		{"Voxel count: " .. ent.Grid:GetCount()},
		{string.format("Complexity: %.1i%%", ent.Grid:GetComplexity() * 100), ent.Grid:GetComplexity() > 1},
		{true},
		{string.format("Cursor position: [%i, %i, %i]",
			normal and cursorX or 0,
			normal and cursorY or 0,
			normal and cursorZ or 0)},
		{string.format("Cursor normal: [%i, %i, %i]",
			normal and normal.x or 0,
			normal and normal.y or 0,
			normal and normal.z or 0)}
	}

	for k, v in pairs(lines) do
		if v[1] == true then
			continue
		end

		local w = surface.GetTextSize(v[1])

		width = math.max(width, w)
	end

	local x = offset
	local y = (ScrH() * 0.5) - (#lines * 11) - inset

	draw.RoundedBox(8, offset, y, width + inset * 2, #lines * 22 + inset * 2, colors.Background)

	for k, v in pairs(lines) do
		if v[1] == true then
			continue
		end

		local color = colors.Foreground

		if v[2] then
			color = colors.ForegroundSelected
		end

		draw.SimpleText(v[1], "HudDefault", x + inset, y + inset + 22 * (k - 1), color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end
