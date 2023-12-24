AddCSLuaFile()

function voxel.LoadFromFile(name, path)
	local fs = assert(file.Open(name, "rb", path), "Unable to create file handle: " .. name)

	assert(fs:Read(4) == "GVOX", "Invalid file signature")
	assert(fs:ReadByte() <= 1, "Unsupported file version")

	local grid = voxel.Grid()
	local attachments = {}

	local colors = {}

	-- Color index
	for i = 1, fs:ReadUShort() do
		colors[i] = Color(fs:ReadByte(), fs:ReadByte(), fs:ReadByte(), fs:ReadByte())
	end

	-- Point list
	for i = 1, fs:ReadULong() do
		grid:Set(fs:ReadByte() - 128, fs:ReadByte() - 128, fs:ReadByte() - 128, colors[fs:ReadUShort()])
	end

	-- Attachments
	for i = 1, fs:ReadByte() do
		attachments[fs:Read(fs:ReadByte())] = {
			Offset = Vector(fs:ReadFloat(), fs:ReadFloat(), fs:ReadFloat()),
			Angles = Angle(fs:ReadFloat(), fs:ReadFloat(), fs:ReadFloat())
		}
	end

	fs:Close()

	return grid, attachments
end

function voxel.SaveToFile(name, grid, attachments)
	file.CreateDir(string.GetPathFromFilename(name))

	local fs = assert(file.Open(name, "wb", "DATA"), "Unable to create file handle: " .. name)

	fs:Write("GVOX") -- File signature
	fs:WriteByte(1) -- Version number

	-- Create color index
	local colors = {}
	local lookup = {}

	for _, v in pairs(grid.Items) do
		local col = tostring(v)

		if lookup[col] then
			continue
		end

		lookup[col] = table.insert(colors, v)
	end

	-- Write the color index
	fs:WriteUShort(#colors)

	for _, v in ipairs(colors) do
		fs:WriteByte(v.r)
		fs:WriteByte(v.g)
		fs:WriteByte(v.b)
		fs:WriteByte(v.a)
	end

	-- Write point list
	fs:WriteULong(grid:GetCount())

	for index, col in pairs(grid.Items) do
		local x, y, z = voxel.Grid.FromIndex(index)

		fs:WriteByte(x + 128)
		fs:WriteByte(y + 128)
		fs:WriteByte(z + 128)
		fs:WriteUShort(lookup[tostring(col)])
	end

	-- Write attachments
	fs:WriteByte(table.Count(attachments))

	for attachment, data in pairs(attachments) do
		-- Name
		fs:WriteByte(#attachment)
		fs:Write(attachment)

		-- Offset
		fs:WriteFloat(data.Offset.x)
		fs:WriteFloat(data.Offset.y)
		fs:WriteFloat(data.Offset.z)

		-- Angles
		fs:WriteFloat(data.Angles.p)
		fs:WriteFloat(data.Angles.y)
		fs:WriteFloat(data.Angles.r)
	end

	fs:Close()
end
