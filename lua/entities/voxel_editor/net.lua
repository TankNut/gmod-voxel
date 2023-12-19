AddCSLuaFile()

function ENT:Set(x, y, z, color)
	self.Grid:Set(x, y, z, color)

	if SERVER then
		net.Start("voxel_editor_set")
			net.WriteEntity(self)
			net.WriteInt(x, 8)
			net.WriteInt(y, 8)
			net.WriteInt(z, 8)

			if color then
				net.WriteBool(true)
				net.WriteColor(color, true)
			else
				net.WriteBool(false)
			end
		net.Broadcast()
	end

	if color == nil and self.Grid:GetCount() == 0 then
		self:Set(0, 0, 0, color_white)
	end
end

if CLIENT then
	net.Receive("voxel_editor_set", function()
		local ent = net.ReadEntity()

		if not IsValid(ent) then
			return
		end

		local x = net.ReadInt(8)
		local y = net.ReadInt(8)
		local z = net.ReadInt(8)

		if net.ReadBool() then
			ent.Grid:Set(x, y, z, net.ReadColor(true))
		else
			ent.Grid:Set(x, y, z, nil)
		end
	end)

	net.Receive("voxel_editor_shift", function()
		local ent = net.ReadEntity()

		if not IsValid(ent) then
			return
		end

		local x = net.ReadInt(8)
		local y = net.ReadInt(8)
		local z = net.ReadInt(8)

		ent.Grid:Shift(x, y, z)
	end)

	net.Receive("voxel_editor_sync", function()
		local ent = net.ReadEntity()

		local fs = file.Open("voxel_editor_temp.dat", "wb", "DATA")

		fs:Write(util.Decompress(net.ReadData(net.ReadUInt(16))))
		fs:Close()

		local grid, attachments = voxel.LoadFromFile("voxel_editor_temp.dat", "DATA")

		ent.Grid = grid
		ent.Attachments = attachments
	end)

	net.Receive("voxel_editor_switch", function()
		timer.Simple(0, function()
			local weapon = LocalPlayer():GetWeapon("voxel_tool")

			if IsValid(weapon) then
				input.SelectWeapon(weapon)
			end
		end)
	end)
else
	util.AddNetworkString("voxel_editor_set")
	util.AddNetworkString("voxel_editor_shift")
	util.AddNetworkString("voxel_editor_sync")
	util.AddNetworkString("voxel_editor_switch")

	util.AddNetworkString("voxel_editor_new")
	util.AddNetworkString("voxel_editor_opencl")
	util.AddNetworkString("voxel_editor_opensv")

	util.AddNetworkString("voxel_editor_scale")
	util.AddNetworkString("voxel_editor_offset")

	net.Receive("voxel_editor_sync", function(_, ply)
		local ent = net.ReadEntity()

		if not IsValid(ent) or ent:GetClass() != "voxel_editor" then
			return
		end

		ent:SyncToPlayer(ply)
	end)

	net.Receive("voxel_editor_new", function(_, ply)
		local ent = net.ReadEntity()

		if not IsValid(ent) or ent:GetClass() != "voxel_editor" then
			return
		end

		if ent:GetOwningPlayer() != ply then
			return
		end

		ent.Grid = voxel.Grid()
		ent.Grid:Set(0, 0, 0, color_white)
		table.Empty(ent.Attachments)

		ent:SyncToPlayer()
	end)

	net.Receive("voxel_editor_opencl", function(_, ply)
		local ent = net.ReadEntity()

		if not IsValid(ent) or ent:GetClass() != "voxel_editor" then
			return
		end

		if ent:GetOwningPlayer() != ply then
			return
		end

		local size = net.ReadUInt(16)

		file.Write("voxel_editor_temp.dat", util.Decompress(net.ReadData(size)))

		local grid, attachments = voxel.LoadFromFile("voxel_editor_temp.dat", "DATA")

		ent.Grid = grid
		ent.Attachments = attachments
		ent:SyncToPlayer()
	end)

	net.Receive("voxel_editor_opensv", function(_, ply)
		local ent = net.ReadEntity()

		if not IsValid(ent) or ent:GetClass() != "voxel_editor" then
			return
		end

		if ent:GetOwningPlayer() != ply then
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

		ent.Grid = grid
		ent.Attachments = attachments
		ent:SyncToPlayer()
	end)

	net.Receive("voxel_editor_scale", function(_, ply)
		local ent = net.ReadEntity()

		if not IsValid(ent) or ent:GetClass() != "voxel_editor" then
			return
		end

		if ent:GetOwningPlayer() != ply then
			return
		end

		ent:SetVoxelScale(net.ReadUInt(4))
	end)

	net.Receive("voxel_editor_offset", function(_, ply)
		local ent = net.ReadEntity()

		if not IsValid(ent) or ent:GetClass() != "voxel_editor" then
			return
		end

		if ent:GetOwningPlayer() != ply then
			return
		end

		ent:SetVoxelOffset(Vector(0, 0, net.ReadUInt(6)))
	end)

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

	function ENT:Shift(x, y, z)
		self.Grid:Shift(x, y, z)

		net.Start("voxel_editor_shift")
			net.WriteEntity(self)

			net.WriteInt(x, 8)
			net.WriteInt(y, 8)
			net.WriteInt(z, 8)
		net.Broadcast()
	end

	function ENT:Rotate(ang)
		self.Grid:Rotate(ang)
		self:SyncToPlayer()
	end

	function ENT:RotateAround(ang, x, y, z)
		self.Grid:Shift(-x, -y, -z)
		self.Grid:Rotate(ang)
		self.Grid:Shift(x, y, z)

		self:SyncToPlayer()
	end
end
