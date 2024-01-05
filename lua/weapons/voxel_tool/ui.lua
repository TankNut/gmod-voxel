local persistMouse = CreateClientConVar("voxel_ui_save_mouse", "0", true, false, "", 0, 1)
local persistWindow = CreateClientConVar("voxel_ui_save_window", "0", true, false, "", 0, 1)

local function installThink(ui, ent)
	local think = ui.Think

	ui.Editor = ent

	ui.Think = function()
		-- Close if we lose our editor
		if not IsValid(ent) then
			ui:Close()

			return
		end

		think(ui)

		-- Close on escape
		if gui.IsGameUIVisible() and (not IsValid(vgui.GetKeyboardFocus()) or vgui.FocusedHasParent(ui)) then
			ui:Close()

			gui.HideGameUI()
		end
	end
end

local function isOwner(ent)
	return LocalPlayer() == ent:GetOwningPlayer()
end

function SWEP:ToggleUI()
	if IsValid(self.UI) then
		self.UI:Close()

		return
	end

	local background = vgui.Create("EditablePanel")

	background:Dock(FILL)
	background:SetWorldClicker(true)

	local ui = vgui.Create("DFrame")

	ui:SetSize(300, 320)
	ui:SetTitle("Options")
	ui:MakePopup()
	ui:Center()

	installThink(ui, self:GetEditEntity())

	ui.OnClose = function()
		background:Remove()

		if persistMouse:GetBool() then
			voxel.MousePos = {input.GetCursorPos()}
		end

		if persistWindow:GetBool() then
			voxel.WindowPos = {ui:GetPos()}
		end
	end

	ui:SetDraggable(true)
	ui:SetKeyboardInputEnabled(false)
	ui:RequestFocus()

	self.UI = ui

	self:AddMenuBar(ui)
	self:AddColorPicker(ui)

	ui:InvalidateLayout(true)
	ui:SizeToChildren(true, true)

	if persistMouse:GetBool() and voxel.MousePos then
		input.SetCursorPos(unpack(voxel.MousePos))
	end

	if persistWindow:GetBool() and voxel.WindowPos then
		ui:SetPos(unpack(voxel.WindowPos))
	end
end

function SWEP:AddMenuBar(ui)
	local bar = ui:Add("DMenuBar")

	bar:Dock(TOP)
	bar:DockMargin(-3, -6, -3, 3)

	local fileMenu = bar:AddMenu("File")
	local ent = ui.Editor
	local owner = isOwner(ent)

	fileMenu:AddOption("New", function()
		self:NewFileDialog()
	end):SetDisabled(not owner)

	fileMenu:AddOption("Open", function()
		self:OpenFileDialog()
	end):SetDisabled(not owner)

	fileMenu:AddOption("Open From Server", function()
		self:OpenRemoteDialog()
	end):SetDisabled(not owner)

	fileMenu:AddOption("Save", function()
		if ent.Grid:GetComplexity() > 1 then
			Derma_Message("Cannot save, model is too complex.", "Error", "Ok")

			return
		end

		if ent.SavePath then
			voxel.SaveToFile("voxel/" .. ent.SavePath .. ".dat", ent.Grid, ent.Attachments)

			return
		end

		self:SaveFileDialog(function(val)
			voxel.SaveToFile("voxel/" .. val .. ".dat", ent.Grid, ent.Attachments)
			ent.SavePath = val
		end)
	end)

	fileMenu:AddOption("Save As...", function()
		if ent.Grid:GetComplexity() > 1 then
			Derma_Message("Cannot save, model is too complex.", "Error", "Ok")

			return
		end

		self:SaveFileDialog(function(val)
			voxel.SaveToFile("voxel/" .. val .. ".dat", ent.Grid, ent.Attachments)
			ent.SavePath = val
		end)
	end)

	fileMenu:AddSpacer()

	fileMenu:AddOption("Save To Server", function()
		if ent.Grid:GetComplexity() > 1 then
			Derma_Message("Cannot save, model is too complex.", "Error", "Ok")

			return
		end

		self:SaveFileDialog(function(val)
			net.Start("voxel_model_save")
				net.WriteString(val)
			net.SendToServer()

			ent.SavePath = val
		end)
	end):SetDisabled(not LocalPlayer():IsSuperAdmin())

	fileMenu:AddSpacer()

	local importMenu = fileMenu:AddSubMenu("Import...")

	importMenu:SetDeleteSelf(false)
	importMenu:AddOption("Voxlap (.kv6)", function()
		self:ImportFileDialog("*.kv6", voxel.LoadKV6)
	end)

	importMenu:AddOption("MagicaVoxel (.vox)", function()
		self:ImportFileDialog("*.vox", voxel.LoadVOX)
	end)

	importMenu:AddOption("Model (.mdl)", function()
		self:FromModelDialog()
	end)

	local modelMenu = bar:AddMenu("Model")

	modelMenu:AddOption("Attachments", function()
		self:AttachmentDialog()
	end)

	local optMenu = bar:AddMenu("Options")

	do -- Scale menu
		local scaleMenu = optMenu:AddSubMenu("Set Scale")
		local scaleOptions = {}

		scaleMenu:SetDeleteSelf(false)

		local function recalculateScale(val)
			val = val or ent:GetVoxelScale()

			for _, v in pairs(scaleOptions) do
				v:SetChecked(val == v.SetValue)
			end
		end

		for k, v in pairs({1, 2, 5, 10, 15}) do
			local pnl = scaleMenu:AddOption(v, function()
				net.Start("voxel_editor_scale")
					net.WriteUInt(v, 4)
				net.SendToServer()

				recalculateScale(v)
			end)

			pnl.SetValue = v

			scaleOptions[k] = pnl
		end

		recalculateScale()
	end

	do -- Offset menu
		local offsetMenu = optMenu:AddSubMenu("Set Offset")
		local offsetOptions = {}

		offsetMenu:SetDeleteSelf(false)

		local function recalculateOffset(val)
			val = val or ent:GetVoxelOffset()

			for _, v in pairs(offsetOptions) do
				v:SetChecked(val == v.SetValue)
			end
		end

		for k, v in pairs({0, 10, 20, 25, 50}) do
			local pnl = offsetMenu:AddOption(v, function()
				net.Start("voxel_editor_offset")
					net.WriteUInt(v, 6)
				net.SendToServer()

				recalculateOffset(Vector(0, 0, v))
			end)

			pnl.SetValue = Vector(0, 0, v)

			offsetOptions[k] = pnl
		end

		recalculateOffset()
	end

	local fullbright

	fullbright = optMenu:AddOption("Fullbright", function()
		net.Start("voxel_editor_fullbright")
			net.WriteBool(not ent:GetFullbright())
		net.SendToServer()

		fullbright:SetChecked(not ent:GetFullbright())
	end)

	fullbright:SetChecked(ent:GetFullbright())

	local accessMenu = bar:AddMenu("Access")

	accessMenu:AddCVar("Just Me", "voxel_access", "0")
	accessMenu:AddCVar("Everybody", "voxel_access", "1")

	local prefMenu = bar:AddMenu("Preferences")

	prefMenu:AddCVar("Draw Model Origin", "voxel_draw_origin", "1", "0")
	prefMenu:AddCVar("Show Extra Info", "voxel_extra_info", "1", "0")
	prefMenu:AddSpacer()

	local shadeMenu = prefMenu:AddSubMenu("Shade Mode")

	shadeMenu:SetDeleteSelf(false)
	shadeMenu:AddCVar("Value (HSV)", "voxel_shade_mode", "1")
	shadeMenu:AddCVar("Lightness (HSL)", "voxel_shade_mode", "2")

	local resMenu = prefMenu:AddSubMenu("Shade Amount")

	resMenu:SetDeleteSelf(false)
	resMenu:AddCVar("1", "voxel_shade_res", "1")
	resMenu:AddCVar("0.1", "voxel_shade_res", "0.100000")
	resMenu:AddCVar("0.05", "voxel_shade_res", "0.050000")
	resMenu:AddCVar("0.025", "voxel_shade_res", "0.025000")
	resMenu:AddCVar("0.01", "voxel_shade_res", "0.010000")

	prefMenu:AddCVar("Save Mouse Position", "voxel_ui_save_mouse", "1", "0")
	prefMenu:AddCVar("Save UI Position", "voxel_ui_save_window", "1", "0")
end

function SWEP:AddColorPicker(ui)
	local mixer = ui:Add("DColorMixer")

	mixer:Dock(FILL)
	mixer:SetAlphaBar(false)

	mixer:SetColor(Color(GetConVar("voxel_col_r"):GetInt(), GetConVar("voxel_col_g"):GetInt(), GetConVar("voxel_col_b"):GetInt()))

	mixer:SetConVarR("voxel_col_r")
	mixer:SetConVarG("voxel_col_g")
	mixer:SetConVarB("voxel_col_b")

	mixer.Palette:SetCookieName("voxel_tool_color")
	mixer.Palette:SetNumRows(9)
	mixer.Palette:Reset()
end

function SWEP:NewFileDialog()
	local ui = vgui.Create("DFrame")

	ui:SetSize(400, 94)
	ui:SetTitle("Confirmation Dialog")
	ui:MakePopup()
	ui:Center()

	ui:DoModal()
	ui:SetKeyboardInputEnabled(true)

	installThink(ui, self:GetEditEntity())

	local label = ui:Add("DLabel")

	label:Dock(TOP)
	label:SetContentAlignment(5)
	label:SetText("Are you sure you want to start a new file? Any unsaved changes will be lost.")

	local buttons = ui:Add("DPanel")

	buttons:SetPaintBackground(false)
	buttons:DockMargin(0, 5, 0, 0)
	buttons:Dock(TOP)
	buttons:SetTall(22)

	local cancel = buttons:Add("DButton")

	cancel:SetText("Cancel")
	cancel:DockMargin(5, 0, 0, 0)
	cancel:Dock(RIGHT)

	cancel.DoClick = function()
		ui:Close()
	end

	local ok = buttons:Add("DButton")

	ok:SetText("Ok")
	ok:Dock(RIGHT)

	ok.DoClick = function()
		net.Start("voxel_editor_new")
		net.SendToServer()

		ui.Editor.SavePath = nil

		ui:Close()
		self.UI:Close()
	end

	ui:InvalidateLayout(true)
	ui:SizeToChildren(false, true)
end

function SWEP:OpenFileDialog()
	local ui = vgui.Create("DFrame")

	ui:SetSize(500, 300)
	ui:SetTitle("Open File")
	ui:MakePopup()
	ui:Center()

	ui:DoModal()
	ui:SetKeyboardInputEnabled(true)

	installThink(ui, self:GetEditEntity())

	ui.OnClose = function()
		self.UI:RequestFocus()
	end

	local browser = ui:Add("DFileBrowser")

	browser:Dock(FILL)

	browser:SetPath("DATA")
	browser:SetBaseFolder("voxel")
	browser:SetFileTypes("*.dat")
	browser:SetCurrentFolder("voxel")
	browser:SetOpen(true)

	browser.OnDoubleClick = function(pnl, path)
		local payload = util.Compress(file.Read(path, "DATA"))

		ui.Editor.SavePath = voxel.FormatFilename(path):gsub(".dat$", "")

		net.Start("voxel_editor_opencl")
			net.WriteUInt(#payload, 16)
			net.WriteData(payload)
		net.SendToServer()

		ui:Close()
		self.UI:Close()
	end
end

function SWEP:OpenRemoteDialog()
	local ui = vgui.Create("DFrame")

	ui:SetSize(500, 300)
	ui:SetTitle("Open Remote File")
	ui:MakePopup()
	ui:Center()

	ui:DoModal()
	ui:SetKeyboardInputEnabled(true)

	installThink(ui, self:GetEditEntity())

	ui.OnClose = function()
		self.UI:RequestFocus()
	end

	local tree = ui:Add("DTree")

	tree:Dock(FILL)

	local data = {
		Files = {},
		Folders = {},
		Lookup = {}
	}

	for name, path in pairs(voxel.FileList) do
		local current = data
		local formatted = voxel.FormatFilename(name)

		for v in formatted:gmatch("([^/]+)/") do
			if current.Lookup[v] then
				current = current.Lookup[v]

				continue
			end

			local new = {
				Name = v,
				Files = {},
				Folders = {},
				Lookup = {}
			}

			table.insert(current.Folders, new)

			current.Lookup[v] = new
			current = new
		end

		table.insert(current.Files, {
			Name = name,
			Path = path
		})
	end

	local function populate(current, node)
		for _, v in SortedPairsByMemberValue(current.Folders, "Name") do
			populate(v, node:AddNode(v.Name))
		end

		for _, v in SortedPairsByMemberValue(current.Files, "Name") do
			local option = node:AddNode(string.GetFileFromFilename(v.Name), v.Path == "DATA" and "icon16/page.png" or "icon16/world.png")

			option.Label.DoDoubleClick = function()
				ui.Editor.SavePath = voxel.FormatFilename(v.Name):gsub(".dat$", "")

				ui:Close()
				self.UI:Close()

				net.Start("voxel_editor_opensv")
					net.WriteString(v.Name)
					net.WriteBool(v.Path == "DATA")
				net.SendToServer()
			end
		end
	end

	populate(data, tree:Root())
end

function SWEP:ImportFileDialog(extensions, importer)
	local ui = vgui.Create("DFrame")

	ui:SetSize(500, 300)
	ui:SetTitle("Import File")
	ui:MakePopup()
	ui:Center()

	ui:DoModal()
	ui:SetKeyboardInputEnabled(true)

	installThink(ui, self:GetEditEntity())

	ui.OnClose = function()
		self.UI:RequestFocus()
	end

	local browser = ui:Add("DFileBrowser")

	browser:Dock(FILL)

	browser:SetPath("DATA")
	browser:SetBaseFolder("voxel-import")
	browser:SetFileTypes(extensions)
	browser:SetCurrentFolder("voxel-import")
	browser:SetOpen(true)

	browser.OnDoubleClick = function(pnl, path)
		ui.Editor.SavePath = nil

		ui:Close()
		self.UI:Close()

		local grid = importer(path, true)

		if grid:GetComplexity() > 1 then
			surface.PlaySound("buttons/button10.wav")
			notification.AddLegacy(string.format("Cannot import %s: Model is too big!", string.GetFileFromFilename(path)), NOTIFY_ERROR, 5)

			return
		end

		voxel.SaveToFile("voxel_editor_temp.dat", grid, {})

		local payload = util.Compress(file.Read("voxel_editor_temp.dat", "DATA"))

		net.Start("voxel_editor_opencl")
			net.WriteUInt(#payload, 16)
			net.WriteData(payload)
		net.SendToServer()
	end
end

function SWEP:FromModelDialog()
	local ui = vgui.Create("DFrame")

	ui:SetSize(350, 300)
	ui:SetTitle("Import Model")
	ui:MakePopup()
	ui:Center()

	ui:DoModal()
	ui:SetKeyboardInputEnabled(true)

	installThink(ui, self:GetEditEntity())

	ui.OnClose = function()
		self.UI:RequestFocus()
	end

	local entry = ui:Add("DTextEntry")

	entry:Dock(TOP)
	entry:SetPlaceholderText("Model path (copy/paste from the spawnmenu)")

	local bodygroups = ui:Add("DTextEntry")

	bodygroups:DockMargin(0, 2, 0, 0)
	bodygroups:Dock(TOP)
	bodygroups:SetPlaceholderText("Bodygroup mask (000000)")
	bodygroups.AllowInput = function(_, char)
		return tobool(string.find(char, "[^%l%d]"))
	end

	local scale = ui:Add("DNumSlider")

	scale:DockMargin(2, 0, 0, 0)
	scale:Dock(TOP)
	scale:SetText("Import scale")
	scale:SetMinMax(0, 3)
	scale:SetDefaultValue(1)
	scale:SetValue(1)

	local buttons = ui:Add("DPanel")

	buttons:SetPaintBackground(false)
	buttons:Dock(TOP)
	buttons:DockMargin(0, 5, 0, 0)
	buttons:SetTall(22)

	local cancel = buttons:Add("DButton")

	cancel:SetText("Cancel")
	cancel:DockMargin(5, 0, 0, 0)
	cancel:Dock(RIGHT)

	cancel.DoClick = function()
		ui:Close()
	end

	local ok = buttons:Add("DButton")

	ok:SetText("Ok")
	ok:Dock(RIGHT)

	ok.DoClick = function()
		local mdl = entry:GetValue()
		local mdlScale = scale:GetValue() * 0.5

		ui:Close()
		self.UI:Close()

		local grid = voxel.FromModel(mdl, mdlScale, bodygroups:GetValue())

		if grid:GetComplexity() > 1 then
			surface.PlaySound("buttons/button10.wav")
			notification.AddLegacy(string.format("Cannot import %s: Model is too big!", string.GetFileFromFilename(mdl)), NOTIFY_ERROR, 5)

			return
		end

		voxel.SaveToFile("voxel_editor_temp.dat", grid, {})

		local payload = util.Compress(file.Read("voxel_editor_temp.dat", "DATA"))

		net.Start("voxel_editor_opencl")
			net.WriteUInt(#payload, 16)
			net.WriteData(payload)
		net.SendToServer()
	end

	entry.OnEnter = function()
		ok:DoClick()
	end

	ui:InvalidateLayout(true)
	ui:SizeToChildren(false, true)
end

local blacklist = {
	["\""] = true,
	[" "] = true,
	[":"] = true,
	["."] = true
}

function SWEP:SaveFileDialog(callback)
	local ui = vgui.Create("DFrame")

	ui:SetWide(400)
	ui:SetTitle("Save As...")
	ui:MakePopup()
	ui:Center()

	ui:DoModal()
	ui:SetKeyboardInputEnabled(true)

	installThink(ui, self:GetEditEntity())

	ui.OnClose = function()
		self.UI:RequestFocus()
	end

	local entry = ui:Add("DTextEntry")

	entry:Dock(TOP)
	entry:SetPlaceholderText("File path without extension e.g. folder/example")
	entry.AllowInput = function(_, char)
		if blacklist[char] then
			return true
		end
	end

	local saved = ui.Editor.SavePath

	if saved then
		entry:SetValue(string.Replace(saved, ".dat", ""))
	end

	local buttons = ui:Add("DPanel")

	buttons:SetPaintBackground(false)
	buttons:Dock(TOP)
	buttons:DockMargin(0, 5, 0, 0)
	buttons:SetTall(22)

	local cancel = buttons:Add("DButton")

	cancel:SetText("Cancel")
	cancel:Dock(LEFT)

	cancel.DoClick = function()
		ui:Close()
	end

	local ok = buttons:Add("DButton")

	ok:SetText("Ok")
	ok:Dock(RIGHT)

	ok.DoClick = function()
		ui:Close()
		self.UI:Close()

		callback(entry:GetValue())
	end

	entry.OnEnter = function()
		ok:DoClick()
	end

	ui:InvalidateLayout(true)
	ui:SizeToChildren(false, true)
end

function SWEP:AttachmentDialog()
	local ui = vgui.Create("DFrame")

	ui:SetSize(500, 300)
	ui:SetTitle("Attachments")
	ui:MakePopup()
	ui:Center()

	ui:DoModal()
	ui:SetKeyboardInputEnabled(true)

	installThink(ui, self:GetEditEntity())

	ui.OnClose = function()
		self.UI:RequestFocus()
	end

	local buttons = ui:Add("DPanel")

	buttons:SetPaintBackground(false)
	buttons:Dock(BOTTOM)
	buttons:DockMargin(0, 5, 0, 2)
	buttons:SetTall(22)

	local newButton = buttons:Add("DButton")

	newButton:Dock(LEFT)
	newButton:DockMargin(0, 0, 5, 0)
	newButton:SetText("New...")
	newButton:SizeToContents()
	newButton:SetDisabled(true)

	local nameEntry = buttons:Add("DTextEntry")

	nameEntry:Dock(LEFT)
	nameEntry:DockMargin(0, 0, 5, 0)
	nameEntry:SetWide(200)
	nameEntry:SetPlaceholderText("Attachment Name")
	nameEntry:SetUpdateOnType(true)

	nameEntry.OnValueChange = function(_, val)
		local name = string.lower(val):Trim()

		newButton:SetDisabled(tobool(ui.Editor.Attachments[name]) or #name == 0)
		newButton:SetTooltip(newButton:GetDisabled() and "Attachment name is invalid (already exists?)" or nil)
	end

	local renameButton = buttons:Add("DButton")

	renameButton:Dock(LEFT)
	renameButton:DockMargin(0, 0, 5, 0)
	renameButton:SetText("Rename")
	renameButton:SizeToContents()
	renameButton:SetDisabled(true)

	renameButton.DoClick = function()
		local name = string.lower(nameEntry:GetValue()):Trim()

		net.Start("voxel_editor_att_rename")
			net.WriteString(ui.Attachment.Name)
			net.WriteString(name)
		net.SendToServer()

		ui.Attachment.Name = name
	end

	local deleteButton = buttons:Add("DButton")

	deleteButton:Dock(LEFT)
	deleteButton:DockMargin(0, 0, 5, 0)
	deleteButton:SetText("Delete")
	deleteButton:SizeToContents()
	deleteButton:SetDisabled(true)

	deleteButton.DoClick = function()
		nameEntry:SetValue("")

		renameButton:SetDisabled(true)
		deleteButton:SetDisabled(true)

		net.Start("voxel_editor_att_delete")
			net.WriteString(ui.Attachment.Name)
		net.SendToServer()
	end

	local propertyList = ui:Add("DProperties")

	propertyList:DockMargin(2, 1, 0, 0)
	propertyList:Dock(RIGHT)
	propertyList:SetWide(200)

	local function updateOffset(prop, val)
		if not ui.Attachment then
			return
		end

		ui.Attachment.Offset[prop] = tonumber(val) and val or 0
	end

	local function submitOffset()
		net.Start("voxel_editor_att_offset")
			net.WriteString(ui.Attachment.Name)
			net.WriteVector(ui.Attachment.Offset)
		net.SendToServer()
	end

	local offsetX = propertyList:CreateRow("Offset", "Offset: X")
	offsetX:Setup("VoxelOffset")
	offsetX.DataChanged = function(_, val) updateOffset("x", val) end
	offsetX.OnEnter = function() submitOffset() end

	local offsetY = propertyList:CreateRow("Offset", "Offset: Y")
	offsetY:Setup("VoxelOffset")
	offsetY.DataChanged = function(_, val) updateOffset("y", val) end
	offsetY.OnEnter = function() submitOffset() end

	local offsetZ = propertyList:CreateRow("Offset", "Offset: Z")
	offsetZ:Setup("VoxelOffset")
	offsetZ.DataChanged = function(_, val) updateOffset("z", val) end
	offsetZ.OnEnter = function() submitOffset() end

	local function updateAngle(prop, val)
		if not ui.Attachment then
			return
		end

		ui.Attachment.Angles[prop] = tonumber(val) and val or 0
	end

	local function submitAngle()
		net.Start("voxel_editor_att_angles")
			net.WriteString(ui.Attachment.Name)
			net.WriteAngle(ui.Attachment.Angles)
		net.SendToServer()
	end

	local angleP = propertyList:CreateRow("Angles", "Angles: Pitch")
	angleP:Setup("VoxelOffset")
	angleP.DataChanged = function(_, val) updateAngle("p", val) end
	angleP.OnEnter = function() submitAngle() end

	local angleY = propertyList:CreateRow("Angles", "Angles: Yaw")
	angleY:Setup("VoxelOffset")
	angleY.DataChanged = function(_, val) updateAngle("y", val) end
	angleY.OnEnter = function() submitAngle() end

	local angleR = propertyList:CreateRow("Angles", "Angles: Roll")
	angleR:Setup("VoxelOffset")
	angleR.DataChanged = function(_, val) updateAngle("r", val) end
	angleR.OnEnter = function() submitAngle() end

	local function setAttachment(att)
		ui.Attachment = att

		nameEntry:SetValue(att.Name)
		nameEntry:SetCaretPos(#att.Name)

		newButton:SetDisabled(true)
		renameButton:SetDisabled(false)
		deleteButton:SetDisabled(false)

		offsetX:SetValue(att.Offset.x)
		offsetY:SetValue(att.Offset.y)
		offsetZ:SetValue(att.Offset.z)

		angleP:SetValue(att.Angles.p)
		angleY:SetValue(att.Angles.y)
		angleR:SetValue(att.Angles.r)
	end

	local listView = ui:Add("DListView")

	listView:Dock(FILL)
	listView:AddColumn("Attachment"):SetFixedWidth(120)
	listView:AddColumn("Offset")
	listView:AddColumn("Angles")

	listView.OnRowSelected = function(_, index, row)
		local attachment = ui.Editor.Attachments[row.Name]

		-- Need to explicitly copy here to avoid 'false' updates for the client
		setAttachment({
			Name = row.Name,
			Offset = Vector(attachment.Offset),
			Angles = Angle(attachment.Angles)
		})
	end

	newButton.DoClick = function()
		local name = string.lower(nameEntry:GetValue()):Trim()

		if ui.Editor.Attachments[name] then
			return
		end

		net.Start("voxel_editor_att_create")
			net.WriteString(name)
		net.SendToServer()

		setAttachment({
			Name = name,
			Offset = Vector(),
			Angles = Angle()
		})
	end

	local function populate()
		listView:Clear()

		for name, data in SortedPairs(ui.Editor.Attachments) do
			local line = listView:AddLine(name,
				string.format("[%i, %i, %i]", data.Offset.x, data.Offset.y, data.Offset.z),
				string.format("[%i, %i, %i]", data.Angles.p, data.Angles.y, data.Angles.r)
			)

			line.Name = name

			if ui.Attachment and ui.Attachment.Name == name then
				line:SetSelected(true)
			end
		end
	end

	hook.Add("VoxelEditorAttachmentSync", ui, function(_, ent)
		if ent == ui.Editor then
			populate()
		end
	end)

	populate()

	ui:InvalidateLayout(true)
	ui:SizeToChildren(false, true)
end
