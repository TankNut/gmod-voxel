AddCSLuaFile()

voxel = voxel or {
	Meshes = {},
	Models = {}
}

-- Shared

include("convars.lua")
include("file.lua")
include("grid.lua")
include("mesh.lua")
include("model.lua")

function voxel.GetMesh(vMesh)
	return voxel.Meshes[vMesh]
end

function voxel.GetModel(vModel)
	return voxel.Models[vModel]
end

function voxel.LoadMeshes()
	table.Empty(voxel.Meshes)

	local function load(folder)
		local files, folders = file.Find(folder .. "*.lua", "LUA")

		for _, v in pairs(files) do
			local path = folder .. v

			AddCSLuaFile(path)
			voxel.Mesh.Load(path)
		end

		for _, v in pairs(folders) do
			load(folder .. v .. "/")
		end
	end

	load("voxel/meshes/")
end

function voxel.LoadModels()
	table.Empty(voxel.Models)

	local function load(folder)
		local files, folders = file.Find(folder .. "*.lua", "LUA")

		for _, v in pairs(files) do
			local path = folder .. v

			AddCSLuaFile(path)
			voxel.Model.Load(path)
		end

		for _, v in pairs(folders) do
			load(folder .. v .. "/")
		end
	end

	load("voxel/models/")
end

voxel.LoadMeshes()
voxel.LoadModels()

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
else
	function voxel.CreateProp(pos, ang, model, scale)
		assert(voxel.GetModel(model), string.format("Cannot create voxel prop: Model '%s' doesn't exist.", model))
		assert(scale > 0, "Cannot create voxel prop: Scale cannot be 0.")

		local ent = ents.Create("voxel_base")

		ent:SetPos(pos)
		ent:SetAngles(ang)

		ent:SetVoxelModel(model)
		ent:SetVoxelScale(scale)

		ent:Spawn()
		ent:Activate()

		return ent
	end
end
