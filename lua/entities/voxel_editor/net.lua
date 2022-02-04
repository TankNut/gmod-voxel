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
				net.WriteColor(color, false)
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
			ent.Grid:Set(x, y, z, net.ReadColor(false))
		else
			ent.Grid:Set(x, y, z, nil)
		end
	end)

	net.Receive("voxel_editor_sync", function()
		local ent = net.ReadEntity()

		if not IsValid(ent) then
			return
		end

		local colors = {}

		for i = 1, net.ReadUInt(16) do
			colors[i] = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
		end

		local grid = voxel.Grid()

		for i = 1, net.ReadUInt(24) do
			grid:Set(net.ReadInt(8), net.ReadInt(8), net.ReadInt(8), colors[net.ReadUInt(16)])
		end

		ent.Grid = grid
	end)

	net.Receive("voxel_editor_switch", function()
		input.SelectWeapon(LocalPlayer():GetWeapon("voxel_tool"))
	end)
else
	util.AddNetworkString("voxel_editor_set")
	util.AddNetworkString("voxel_editor_sync")
	util.AddNetworkString("voxel_editor_switch")
	util.AddNetworkString("voxel_editor_new")
	util.AddNetworkString("voxel_editor_opencl")
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

		file.Write("voxel_temp.dat", net.ReadData(size))

		ent.Grid = voxel.LoadGrid("voxel_temp.dat", true)
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
		net.Start("voxel_editor_sync")
			net.WriteEntity(self)

			local colors = {}
			local lookup = {}

			for _, v in pairs(self.Grid.Items) do
				local col = tostring(v)

				if lookup[col] then
					continue
				end

				lookup[col] = table.insert(colors, v)
			end

			net.WriteUInt(#colors, 16)

			for _, v in ipairs(colors) do
				net.WriteUInt(v.r, 8)
				net.WriteUInt(v.g, 8)
				net.WriteUInt(v.b, 8)
				net.WriteUInt(v.a, 8)
			end

			net.WriteUInt(self.Grid:GetCount(), 24)

			for index, col in pairs(self.Grid.Items) do
				local x, y, z = voxel.Grid.FromIndex(index)

				net.WriteInt(x, 8)
				net.WriteInt(y, 8)
				net.WriteInt(z, 8)
				net.WriteUInt(lookup[tostring(col)], 16)
			end

		if ply == nil then
			net.Broadcast()
		else
			net.Send(ply)
		end
	end

	function ENT:Shift(x, y, z)
		self.Grid:Shift(x, y, z)
		self:SyncToPlayer()
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
