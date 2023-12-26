AddCSLuaFile()

local meta = voxel.Model or setmetatable({}, {__call = function(self, path)
	local model = setmetatable({
		Name = path
	}, {__index = self})

	voxel.Models[path] = model

	return model
end})

voxel.Model = meta

function meta:GetBounds()
	return self.Mins or Vector(-1, -1, -1), self.Maxs or Vector(1, 1, 1)
end

function meta:IsValid()
	return SERVER or tobool(self.Mesh)
end

function meta:GetAttachment(name)
	local attachment = self.Attachments[name]

	if not attachment then
		return Vector(), Angle()
	end

	return Vector(attachment.Offset), Angle(attachment.Angles)
end
