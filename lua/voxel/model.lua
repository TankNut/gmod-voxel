AddCSLuaFile()

local function filename(path)
	return string.StripExtension(string.GetFileFromFilename(path))
end

-- Initial setup

local meta = setmetatable({}, {__call = function(self)
	return setmetatable({}, {__index = self})
end})

-- Functions

function meta.Load(path)
	local model = meta()

	voxel.Models[filename(path)] = model

	return model
end

voxel.Model = meta
