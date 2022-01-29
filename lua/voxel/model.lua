AddCSLuaFile()

local function filename(path)
	return string.StripExtension(string.GetFileFromFilename(path))
end

-- Initial setup

local meta = voxel.Model or setmetatable({}, {__call = function(self)
	return setmetatable({}, {__index = self})
end})

table.Empty(meta)

-- Functions

function meta.Load(path)
	local model = meta()

	voxel.Models[filename(path)] = model

	return model
end

voxel.Model = meta
