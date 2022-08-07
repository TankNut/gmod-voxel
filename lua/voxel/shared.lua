AddCSLuaFile()

voxel = voxel or {}

-- Shared

include("convars.lua")
include("file.lua")
include("grid.lua")
include("mesh.lua")
include("model.lua")

function voxel.LoadMeshes()
	voxel.Meshes = {}

	for _, v in pairs(file.Find("voxel/meshes/*.lua", "LUA")) do
		local path = "voxel/meshes/" .. v

		AddCSLuaFile(path)
		voxel.Mesh.Load(path)
	end
end

function voxel.LoadModels()
	voxel.Models = {}

	for _, v in pairs(file.Find("voxel/models/*.lua", "LUA")) do
		local path = "voxel/models/" .. v

		AddCSLuaFile(path)
		voxel.Model.Load(path)
	end
end

voxel.LoadMeshes()
voxel.LoadModels()

function voxel.GetMesh(vMesh)
	return voxel.Meshes[vMesh]
end

function voxel.GetModel(vModel)
	return voxel.Models[vModel]
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
end
