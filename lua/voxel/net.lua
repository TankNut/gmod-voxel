AddCSLuaFile()

local meta = voxel.Model

if SERVER then
	util.AddNetworkString("voxel_model_request")
	util.AddNetworkString("voxel_model_data")
	util.AddNetworkString("voxel_model_save")
	util.AddNetworkString("voxel_model_list")
end

if CLIENT then
	function meta:RequestModelData()
		net.Start("voxel_model_request")
			net.WriteString(self.Name)
		net.SendToServer()
	end

	net.Receive("voxel_model_data", function()
		local path = net.ReadString()
		local model = voxel.Models[path]

		if not model then
			return
		end

		local fs = file.Open("voxel_temp.dat", "wb", "DATA")

		fs:Write(util.Decompress(net.ReadData(net.ReadUInt(16))))
		fs:Close()

		local grid, attachments = voxel.LoadFromFile("voxel_temp.dat", "DATA")

		model.Grid = grid
		model.Attachments = attachments

		model:Rebuild()

		file.Delete("voxel_temp.dat")
	end)

	net.Receive("voxel_model_list", function()
		for i = 1, net.ReadUInt(8) do
			voxel.FileList[net.ReadString()] = net.ReadBool() and "DATA" or "GAME"
		end
	end)
else
	-- Restrict SetEditEntity = basic access control
	local function getEditor(ply, owner)
		local weapon = ply:GetActiveWeapon()

		if not IsValid(weapon) or weapon:GetClass() != "voxel_tool" then
			return NULL
		end

		local editor = weapon:GetEditEntity()

		if owner and editor:GetOwningPlayer() != ply then
			return NULL
		end

		return weapon:GetEditEntity()
	end

	function meta:SendToClient(ply, refresh)
		local data = voxel.FileCache[self.Name]

		if not data or refresh then
			if file.Exists(self.File, self.Path) then
				data = util.Compress(file.Read(self.File, self.Path))

				voxel.FileCache[self.Name] = data
			else
				return
			end
		end

		net.Start("voxel_model_data")
			net.WriteString(self.Name)
			net.WriteUInt(#data, 16)
			net.WriteData(data)
		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end

	net.Receive("voxel_model_request", function(_, ply)
		local path = net.ReadString()
		local model = voxel.Models[path]

		if model then
			model:SendToClient(ply)
		end
	end)

	net.Receive("voxel_model_save", function(_, ply)
		local ent = getEditor(ply)

		if not IsValid(ent) then
			return
		end

		local path = net.ReadString()

		local model = voxel.Models[path] or voxel.Model(path)

		model.Grid = ent.Grid
		model.Attachments = ent.Attachments or model.Attachments

		model.File = "voxel/" .. path .. ".dat"
		model.Path = "DATA"

		voxel.SaveToFile(model.File, model.Grid, model.Attachments or {})

		model:Rebuild()
		model:SendToClient(nil, true)

		voxel.UpdateFileList(nil, {
			[model.File] = model.Path
		})
	end)

	function voxel.UpdateFileList(ply, tbl)
		tbl = tbl or voxel.FileList

		net.Start("voxel_model_list")
			net.WriteUInt(table.Count(tbl), 8)

			for name, path in pairs(tbl) do
				net.WriteString(name)
				net.WriteBool(path == "DATA")
			end

		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end

	net.Receive("voxel_model_list", function(_, ply)
		voxel.UpdateFileList(ply)
	end)
end
