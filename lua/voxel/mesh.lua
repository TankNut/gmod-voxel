AddCSLuaFile()

local meta = voxel.Model

function meta:Rebuild()
	local mins, maxs = self.Grid:GetBounds()

	self.Mins = mins - Vector(0.5, 0.5, 0.5)
	self.Maxs = maxs + Vector(0.5, 0.5, 0.5)

	self.Radius = math.max(
		math.abs(self.Mins.x),
		math.abs(self.Mins.y),
		math.abs(self.Mins.z),
		math.abs(self.Maxs.x),
		math.abs(self.Mins.y),
		math.abs(self.Mins.z))

	if CLIENT then
		self:RebuildMesh()
	end

	hook.Run("VoxelModelLoaded", self)
end

if CLIENT then
	function meta:Draw(col)
		if not col then
			col = Vector(render.GetColorModulation())
		end

		render.SetMaterial(self.Mat)

		self.Mat:SetVector("$color2", col)
		self.Mesh:Draw()
	end

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

	function meta:RebuildMesh()
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

		local name = "voxel_" .. self.Name
		local renderTarget = GetRenderTargetEx(name,
			256, 256,
			RT_SIZE_NO_CHANGE,
			MATERIAL_RT_DEPTH_NONE,
			bit.bor(1, 256),
			0,
			IMAGE_FORMAT_BGRA8888
		)

		render.PushRenderTarget(renderTarget)
			cam.Start2D()
				local i = 1

				for k, v in pairs(colors) do
					local x = (i % 256) - 1
					local y = math.ceil(i / 256) - 1

					render.SetScissorRect(x, y, x + 1, y + 1, true)
						render.Clear(v.r, v.g, v.b, v.a)
					render.SetScissorRect(0, 0, 0, 0, false)

					colors[k] = i

					i = i + 1
				end
			cam.End2D()
		render.PopRenderTarget()

		if self.Mat then
			self.Mat:SetTexture("$basetexture", renderTarget)
		else
			self.Mat = CreateMaterial(name, "VertexLitGeneric", {
				["$basetexture"] = renderTarget:GetName(),
				["$blendtintbybasealpha"] = 1,
				["$halflambert"] = 1
			})
		end

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
					local colorIndex = colors[tostring(col)]

					local uvX = ((colorIndex % 256) - 1) / 256
					local uvY = (math.ceil(colorIndex / 256) - 1) / 256

					local offset = 0.5 / 256

					table.insert(verts, {
						pos = vertices[v] + vec,
						normal = normals[k],
						u = uvX + offset, -- Look up our uv coordinates and add half a pixel to fix some weird rounding errors
						v = uvY + offset
					})
				end
			end
		end

		self.Mesh = Mesh()
		self.Mesh:BuildFromTriangles(verts)
	end
end
