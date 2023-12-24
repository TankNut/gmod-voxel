AddCSLuaFile()

voxel = voxel or {
	Models = {},
	FileList = {},
	FileCache = {}
}

-- Shared

file.CreateDir("voxel")
file.CreateDir("voxel-import")

include("convars.lua")
include("file.lua")
include("grid.lua")
include("import.lua")

include("model.lua")
include("mesh.lua")
include("net.lua")

include("vgui.lua")

function VoxelModel(path)
	if SERVER or voxel.Models[path] then
		return voxel.Models[path]
	end

	local model = voxel.Model(path)

	model:RequestModelData()

	return model
end

function VoxelModelExists(path)
	return tobool(voxel.Models[path])
end

function voxel.FormatFilename(name)
	local sub, count = name:StripExtension():gsub("^data_static/voxel/", "")

	if count == 0 then
		sub, count = sub:gsub("^voxel/", "")
	end

	return sub
end

-- Client

if CLIENT then
	voxel.RenderTarget = GetRenderTarget("voxel_rt", 256, 256, false)

	voxel.Mat = CreateMaterial("voxel_mat", "VertexLitGeneric", {
		["$basetexture"] = "models/debug/debugwhite",
		["$halflambert"] = 1
	})

	local vertices = {
		Vector(-0.5, -0.5, -0.5),
		Vector(0.5, -0.5, -0.5),
		Vector(0.5, 0.5, -0.5),
		Vector(-0.5, 0.5, -0.5),
		Vector(-0.5, -0.5, 0.5),
		Vector(0.5, -0.5, 0.5),
		Vector(0.5, 0.5, 0.5),
		Vector(-0.5, 0.5, 0.5)
	}

	local normals = {
		Vector(0, 0, 1),
		Vector(0, 0, -1),
		Vector(1, 0, 0),
		Vector(-1, 0, 0),
		Vector(0, 1, 0),
		Vector(0, -1, 0)
	}

	local indices = {
		{6, 5, 7, 7, 5, 8}, -- up
		{1, 2, 4, 4, 2, 3}, -- down
		{2, 6, 3, 3, 6, 7}, -- front
		{5, 1, 8, 8, 1, 4}, -- back
		{4, 3, 8, 8, 3, 7}, -- right
		{5, 6, 1, 1, 6, 2}, -- left
	}

	local verts = {}

	for k, v in pairs(indices) do
		for _, index in pairs(v) do
			table.insert(verts, {
				pos = vertices[index],
				normal = normals[k],
				u = 0.5,
				v = 0.5
			})
		end
	end

	voxel.Cube = Mesh()
	voxel.Cube:BuildFromTriangles(verts)

	net.Receive("voxel_reload", function()
		-- Placeholder
	end)

	hook.Add("InitPostEntity", "voxel", function()
		net.Start("voxel_model_list")
		net.SendToServer()
	end)
else
	util.AddNetworkString("voxel_reload")

	concommand.Add("voxel_reload", function(ply)
		if IsValid(ply) then
			net.Start("voxel_reload")
			net.Send(ply)
		else
			net.Start("voxel_reload")
			net.Broadcast()
		end
	end)

	function voxel.CreateProp(pos, ang, model, scale)
		assert(voxel.Models[model], string.format("Cannot create voxel prop: Model '%s' doesn't exist.", model))
		assert(scale > 0, "Cannot create voxel prop: Scale cannot be 0.")

		local ent = ents.Create("voxel_base_dynamic")

		ent:SetPos(pos)
		ent:SetAngles(ang)

		ent:SetVoxelModel(model)
		ent:SetVoxelScale(scale)

		ent:Spawn()
		ent:Activate()

		return ent
	end

	local loadList = {}

	local function buildList(folder, path)
		local files, folders = file.Find(folder .. "*", path)

		for _, v in pairs(files) do
			local name = folder .. v

			loadList[voxel.FormatFilename(name)] = {name, path}
			voxel.FileList[name] = path
		end

		for _, v in pairs(folders) do
			buildList(folder .. v .. "/", path)
		end
	end

	buildList("data_static/voxel/", "GAME")
	buildList("voxel/", "DATA")

	for name, data in pairs(loadList) do
		local model = voxel.Model(name)

		model.File = data[1]
		model.Path = data[2]

		local grid, attachments = voxel.LoadFromFile(data[1], data[2])

		model.Grid = grid
		model.Attachments = attachments
		model:SendToClient()
		model:Rebuild()
	end
end
