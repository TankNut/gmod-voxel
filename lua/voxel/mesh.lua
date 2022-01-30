AddCSLuaFile()

-- Initial setup

local meta = setmetatable({}, {__call = function(self)
	return setmetatable({}, {__index = self})
end})

-- Functions

-- Mesh making
if CLIENT then
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

	function meta:Rebuild()
		local grid = self.Grid
		local mins, maxs = grid:GetBounds()

		local colors = {}

		-- Flood fill to cull inside faces
		local fill = voxel.Grid()

		for x = mins.x, maxs.x do
			for y = mins.y, maxs.y do
				for z = mins.z, maxs.z do
					-- Doing colors in here as well so we don't have to iterate separately for that
					local col = grid:Get(x, y, z)

					if col then
						colors[tostring(col)] = col
					end

					if (x > mins.x and x < maxs.x) and
						(y > mins.y and y < maxs.y) and
						(z > mins.z and z < maxs.z) then
						continue
					end

					local function flood(vec)
						if grid:Has(vec:Unpack()) or fill:Has(vec:Unpack()) then
							return
						end

						fill:Set(vec.x, vec.y, vec.z, true)

						for _, v in pairs(normals) do
							local check = vec + v

							if check:WithinAABox(mins, maxs) then
								flood(check)
							end
						end
					end

					flood(Vector(x, y, z))
				end
			end
		end

		render.PushRenderTarget(voxel.RenderTarget)

		cam.Start2D()
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(1, 1, 256, 256)

			local i = 1

			for k, v in pairs(colors) do
				surface.SetDrawColor(v)
				surface.DrawLine(i, 1, i, 256)

				i = i + 1

				colors[k] = i
			end
		cam.End2D()

		render.PopRenderTarget()

		self.Mat = CreateMaterial("voxel_" .. string.Replace(SysTime(), ".", "_"), "VertexLitGeneric", {
			["$basetexture"] = "Models/props_c17/FurnitureFabric003a",
			["$halflambert"] = 1
		})

		timer.Simple(0, function()
			self.Mat:SetTexture("$basetexture", voxel.RenderTarget)
		end)

		local verts = {}

		for index, col in pairs(self.Grid.Items) do
			local x, y, z = voxel.Grid.FromIndex(index)

			for k, side in pairs(indices) do
				local vec = Vector(x, y, z)
				local check = vec + normals[k]

				if check:WithinAABox(mins, maxs) and (grid:Has(check:Unpack()) or not fill:Has(check:Unpack())) then
					continue
				end

				for _, v in pairs(side) do
					local offset = vec - Vector(1, 1, 1)

					table.insert(verts, {
						pos = vertices[v] + offset,
						normal = normals[k],
						u = colors[tostring(col)] / 256 + (0.5 / 256), -- Look up our uv coordinates and add half a pixel to fix some weird rounding errors
						v = 0.5 -- Just grab the middle
					})
				end
			end
		end

		self.Mesh = Mesh()
		self.Mesh:BuildFromTriangles(verts)
	end
end

function meta.FromGrid(grid)
	local model = meta()

	model.Grid = grid

	local mins, maxs = grid:GetBounds()

	model.Mins = mins - Vector(0.5, 0.5, 0.5)
	model.Maxs = maxs + Vector(0.5, 0.5, 0.5)

	if CLIENT then
		model:Rebuild()
	end

	return model
end

voxel.Mesh = meta
