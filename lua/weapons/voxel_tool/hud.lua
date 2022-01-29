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
end
