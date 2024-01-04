AddCSLuaFile()

if CLIENT then
	net.Receive("voxel_editor_sync", function()
		local ent = net.ReadEntity()

		if not IsValid(ent) then
			return
		end

		local fs = file.Open("voxel_editor_temp.dat", "wb", "DATA")

		fs:Write(util.Decompress(net.ReadData(net.ReadUInt(16))))
		fs:Close()

		local grid, attachments = voxel.LoadFromFile("voxel_editor_temp.dat", "DATA")

		ent.Grid = grid
		ent.Attachments = attachments
	end)

	net.Receive("voxel_editor_sync_att", function()
		local ent = net.ReadEntity()

		if not IsValid(ent) then
			return
		end

		table.Empty(ent.Attachments)

		local count = net.ReadUInt(8)

		for i = 1, count do
			ent.Attachments[net.ReadString()] = {
				Offset = net.ReadVector(),
				Angles = net.ReadAngle()
			}
		end

		hook.Run("VoxelEditorAttachmentSync", ent)
	end)

	net.Receive("voxel_editor_owner", function()
		surface.PlaySound("buttons/button14.wav")
		notification.AddLegacy("You now own this entity.", NOTIFY_GENERIC, 5)
	end)
else
	util.AddNetworkString("voxel_editor_owner")

	util.AddNetworkString("voxel_editor_sync")
	util.AddNetworkString("voxel_editor_sync_att")

	util.AddNetworkString("voxel_editor_new")
	util.AddNetworkString("voxel_editor_opencl")
	util.AddNetworkString("voxel_editor_opensv")

	util.AddNetworkString("voxel_editor_scale")
	util.AddNetworkString("voxel_editor_offset")

	function ENT:SyncToPlayer(ply)
		voxel.SaveToFile("voxel_editor_temp.dat", self.Grid, self.Attachments)

		local data = util.Compress(file.Read("voxel_editor_temp.dat", "DATA"))

		net.Start("voxel_editor_sync")
			net.WriteEntity(self)

			net.WriteUInt(#data, 16)
			net.WriteData(data)

		if ply == nil then
			net.Broadcast()
		else
			net.Send(ply)
		end
	end

	-- Only used for broadcasts, per-player syncs are handled through SyncToPlayer
	function ENT:SyncAttachments()
		net.Start("voxel_editor_sync_att")
			net.WriteEntity(self)
			net.WriteUInt(table.Count(self.Attachments), 8)

			for k, v in pairs(self.Attachments) do
				net.WriteString(k)
				net.WriteVector(v.Offset)
				net.WriteAngle(v.Angles)
			end
		net.Broadcast()
	end

	net.Receive("voxel_editor_sync", function(_, ply)
		local ent = net.ReadEntity()

		if not IsValid(ent) or ent:GetClass() != "voxel_editor" then
			return
		end

		if voxel.RateLimit(ply, "EditorSync" .. ent:EntIndex()) then
			return
		end

		ent:SyncToPlayer(ply)
	end)

	-- 'file' operations
	net.Receive("voxel_editor_new", function(_, ply)
		if voxel.RateLimit(ply, "EditorNewFile") then
			return
		end

		local ent = voxel.GetEditor(ply, true)

		if not IsValid(ent) then
			return
		end

		ent.Grid = voxel.Grid()
		ent.Grid:Set(0, 0, 0, color_white)
		table.Empty(ent.Attachments)

		ent:SyncToPlayer()
	end)

	net.Receive("voxel_editor_opencl", function(_, ply)
		if voxel.RateLimit(ply, "EditorOpenCL", 2) then
			return
		end

		local ent = voxel.GetEditor(ply, true)

		if not IsValid(ent) then
			return
		end

		local size = net.ReadUInt(16)

		file.Write("voxel_editor_temp.dat", util.Decompress(net.ReadData(size)))

		local grid, attachments = voxel.LoadFromFile("voxel_editor_temp.dat", "DATA")

		if grid:GetComplexity() > 1 then
			return
		end

		ent.Grid = grid
		ent.Attachments = attachments
		ent:SyncToPlayer()
	end)

	net.Receive("voxel_editor_opensv", function(_, ply)
		if voxel.RateLimit(ply, "EditorOpenSV") then
			return
		end

		local ent = voxel.GetEditor(ply, true)

		if not IsValid(ent) then
			return
		end

		local name = net.ReadString()
		local path = net.ReadBool() and "DATA" or "GAME"

		if string.Right(name, 4) != ".dat" then
			return
		elseif path == "DATA" and not string.find(name, "^voxel/") then
			return
		elseif path == "GAME" and not string.find(name, "^data_static/voxel/") then
			return
		end

		if not file.Exists(name, path) then
			return
		end

		local grid, attachments = voxel.LoadFromFile(name, path)

		-- Your server, your responsibility

		ent.Grid = grid
		ent.Attachments = attachments
		ent:SyncToPlayer()
	end)

	-- Editor options
	net.Receive("voxel_editor_scale", function(_, ply)
		local ent = voxel.GetEditor(ply, true)

		if not IsValid(ent) then
			return
		end

		ent:SetVoxelScale(net.ReadUInt(4))
	end)

	net.Receive("voxel_editor_offset", function(_, ply)
		local ent = voxel.GetEditor(ply, true)

		if not IsValid(ent) then
			return
		end

		ent:SetVoxelOffset(Vector(0, 0, net.ReadUInt(6)))
	end)
end
