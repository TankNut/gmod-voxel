AddCSLuaFile()

file.CreateDir("voxel")

function voxel.SaveMesh(path, grid)
	local fs = assert(file.Open(path, "wb", "DATA"))

	fs:Write("GVOX") -- File signature
	fs:WriteByte(1) -- Version number

	-- Color table
	local colors = {}
	local lookup = {}

	for _, v in pairs(grid.Items) do
		local col = tostring(v)

		if lookup[col] then
			continue
		end

		lookup[col] = table.insert(colors, v)
	end

	fs:WriteUShort(#colors)

	for _, v in ipairs(colors) do
		fs:WriteByte(v.r)
		fs:WriteByte(v.g)
		fs:WriteByte(v.b)
		fs:WriteByte(v.a)
	end

	fs:WriteULong(grid:GetCount())

	for index, col in pairs(grid.Items) do
		local x, y, z = voxel.Grid.FromIndex(index)

		fs:WriteByte(x + 128)
		fs:WriteByte(y + 128)
		fs:WriteByte(z + 128)
		fs:WriteUShort(lookup[tostring(col)])
	end

	fs:Close()
end

function voxel.LoadMesh(path, data)
	local fs = assert(file.Open(path, "rb", data and "DATA" or "LUA"))

	assert(fs:Read(4) == "GVOX", "Invalid file signature")
	assert(fs:ReadByte() <= 1, "Unsupported file version")

	local colors = {}

	for i = 1, fs:ReadUShort() do
		colors[i] = Color(fs:ReadByte(), fs:ReadByte(), fs:ReadByte(), fs:ReadByte())
	end

	local grid = voxel.Grid()

	for i = 1, fs:ReadULong() do
		grid:Set(fs:ReadByte() - 128, fs:ReadByte() - 128, fs:ReadByte() - 128, colors[fs:ReadUShort()])
	end

	fs:Close()

	return grid
end

-- KV6

local function translateColor(tab)
	return Color(tab[3] * 1.5, tab[2] * 1.5, tab[1] * 1.5)
end

function voxel.LoadKV6(path, data)
	local fs = assert(file.Open(path, "rb", data and "DATA" or "LUA"))

	assert(fs:Read(4) == "Kvxl", "Invalid file signature")

	local size = Vector(fs:ReadULong(), fs:ReadULong(), fs:ReadULong())

	fs:Skip(3 * 4)

	local blockcount = fs:ReadULong()
	local blocks = {}

	for i = 0, blockcount - 1 do
		blocks[i] = {
			Color = {fs:ReadByte(), fs:ReadByte(), fs:ReadByte(), fs:ReadByte()},
			z = fs:ReadUShort(),
			Faces = fs:ReadByte(), -- Unused
			Lighting = fs:ReadByte() -- Unused
		}
	end

	fs:Skip(size.x * 4)

	local offsets = {}

	for i = 0, (size.x * size.y) - 1 do
		offsets[i] = fs:ReadUShort()
	end

	local grid = voxel.Grid()
	local pos = 0

	for x = 0, size.x - 1 do
		for y = 0, size.y - 1 do
			local span = offsets[x * size.y + y]
			local z = -1

			while (span - 1) >= 0 do
				local block = blocks[pos]

				z = block.z

				grid:Set(x + 1, y + 1, z + 1, translateColor(block.Color))

				pos = pos + 1
				span = span - 1
			end
		end
	end

	return grid
end
