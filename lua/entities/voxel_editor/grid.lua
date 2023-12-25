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
	util.AddNetworkString("voxel_editor_switch")

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
