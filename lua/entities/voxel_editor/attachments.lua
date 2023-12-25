AddCSLuaFile()

if SERVER then
	util.AddNetworkString("voxel_editor_att_create")
	util.AddNetworkString("voxel_editor_att_rename")
	util.AddNetworkString("voxel_editor_att_delete")

	util.AddNetworkString("voxel_editor_att_offset")
	util.AddNetworkString("voxel_editor_att_angles")

	net.Receive("voxel_editor_att_create", function(_, ply)
		local ent = voxel.GetEditor(ply)

		if not IsValid(ent) then
			return
		end

		local name = string.lower(net.ReadString()):Trim()

		if ent.Attachments[name] then
			return
		end

		ent.Attachments[name] = {
			Offset = Vector(),
			Angles = Angle()
		}

		ent:SyncAttachments()
	end)

	net.Receive("voxel_editor_att_offset", function(_, ply)
		local ent = voxel.GetEditor(ply)

		if not IsValid(ent) then
			return
		end

		local name = net.ReadString()

		if not ent.Attachments[name] then
			return
		end

		ent.Attachments[name].Offset = net.ReadVector()
		ent:SyncAttachments()
	end)

	net.Receive("voxel_editor_att_angles", function(_, ply)
		local ent = voxel.GetEditor(ply)

		if not IsValid(ent) then
			return
		end

		local name = net.ReadString()

		if not ent.Attachments[name] then
			return
		end

		ent.Attachments[name].Angles = net.ReadAngle()
		ent:SyncAttachments()
	end)

	net.Receive("voxel_editor_att_rename", function(_, ply)
		local ent = voxel.GetEditor(ply)

		if not IsValid(ent) then
			return
		end

		local old = net.ReadString()
		local new = string.lower(net.ReadString()):Trim()

		local attachment = ent.Attachments[old]

		if not attachment then
			return
		end

		ent.Attachments[old] = nil
		ent.Attachments[new] = attachment
		ent:SyncAttachments()
	end)

	net.Receive("voxel_editor_att_delete", function(_, ply)
		local ent = voxel.GetEditor(ply)

		if not IsValid(ent) then
			return
		end

		local name = net.ReadString()

		if not ent.Attachments[name] then
			return
		end

		ent.Attachments[name] = nil
		ent:SyncAttachments()
	end)
end
