AddCSLuaFile()

-- KV6

local function translateColor(tab)
	return Color(tab[3] * 1.5, tab[2] * 1.5, tab[1] * 1.5)
end

function voxel.LoadKV6(path)
	local fs = assert(file.Open(path, "rb", "DATA"), "Unable to create file handle: " .. path)

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

-- VOX

local voxPalette = {
	0x00000000, 0xffffffff, 0xffccffff, 0xff99ffff, 0xff66ffff, 0xff33ffff, 0xff00ffff, 0xffffccff, 0xffccccff, 0xff99ccff, 0xff66ccff, 0xff33ccff, 0xff00ccff, 0xffff99ff, 0xffcc99ff, 0xff9999ff,
	0xff6699ff, 0xff3399ff, 0xff0099ff, 0xffff66ff, 0xffcc66ff, 0xff9966ff, 0xff6666ff, 0xff3366ff, 0xff0066ff, 0xffff33ff, 0xffcc33ff, 0xff9933ff, 0xff6633ff, 0xff3333ff, 0xff0033ff, 0xffff00ff,
	0xffcc00ff, 0xff9900ff, 0xff6600ff, 0xff3300ff, 0xff0000ff, 0xffffffcc, 0xffccffcc, 0xff99ffcc, 0xff66ffcc, 0xff33ffcc, 0xff00ffcc, 0xffffcccc, 0xffcccccc, 0xff99cccc, 0xff66cccc, 0xff33cccc,
	0xff00cccc, 0xffff99cc, 0xffcc99cc, 0xff9999cc, 0xff6699cc, 0xff3399cc, 0xff0099cc, 0xffff66cc, 0xffcc66cc, 0xff9966cc, 0xff6666cc, 0xff3366cc, 0xff0066cc, 0xffff33cc, 0xffcc33cc, 0xff9933cc,
	0xff6633cc, 0xff3333cc, 0xff0033cc, 0xffff00cc, 0xffcc00cc, 0xff9900cc, 0xff6600cc, 0xff3300cc, 0xff0000cc, 0xffffff99, 0xffccff99, 0xff99ff99, 0xff66ff99, 0xff33ff99, 0xff00ff99, 0xffffcc99,
	0xffcccc99, 0xff99cc99, 0xff66cc99, 0xff33cc99, 0xff00cc99, 0xffff9999, 0xffcc9999, 0xff999999, 0xff669999, 0xff339999, 0xff009999, 0xffff6699, 0xffcc6699, 0xff996699, 0xff666699, 0xff336699,
	0xff006699, 0xffff3399, 0xffcc3399, 0xff993399, 0xff663399, 0xff333399, 0xff003399, 0xffff0099, 0xffcc0099, 0xff990099, 0xff660099, 0xff330099, 0xff000099, 0xffffff66, 0xffccff66, 0xff99ff66,
	0xff66ff66, 0xff33ff66, 0xff00ff66, 0xffffcc66, 0xffcccc66, 0xff99cc66, 0xff66cc66, 0xff33cc66, 0xff00cc66, 0xffff9966, 0xffcc9966, 0xff999966, 0xff669966, 0xff339966, 0xff009966, 0xffff6666,
	0xffcc6666, 0xff996666, 0xff666666, 0xff336666, 0xff006666, 0xffff3366, 0xffcc3366, 0xff993366, 0xff663366, 0xff333366, 0xff003366, 0xffff0066, 0xffcc0066, 0xff990066, 0xff660066, 0xff330066,
	0xff000066, 0xffffff33, 0xffccff33, 0xff99ff33, 0xff66ff33, 0xff33ff33, 0xff00ff33, 0xffffcc33, 0xffcccc33, 0xff99cc33, 0xff66cc33, 0xff33cc33, 0xff00cc33, 0xffff9933, 0xffcc9933, 0xff999933,
	0xff669933, 0xff339933, 0xff009933, 0xffff6633, 0xffcc6633, 0xff996633, 0xff666633, 0xff336633, 0xff006633, 0xffff3333, 0xffcc3333, 0xff993333, 0xff663333, 0xff333333, 0xff003333, 0xffff0033,
	0xffcc0033, 0xff990033, 0xff660033, 0xff330033, 0xff000033, 0xffffff00, 0xffccff00, 0xff99ff00, 0xff66ff00, 0xff33ff00, 0xff00ff00, 0xffffcc00, 0xffcccc00, 0xff99cc00, 0xff66cc00, 0xff33cc00,
	0xff00cc00, 0xffff9900, 0xffcc9900, 0xff999900, 0xff669900, 0xff339900, 0xff009900, 0xffff6600, 0xffcc6600, 0xff996600, 0xff666600, 0xff336600, 0xff006600, 0xffff3300, 0xffcc3300, 0xff993300,
	0xff663300, 0xff333300, 0xff003300, 0xffff0000, 0xffcc0000, 0xff990000, 0xff660000, 0xff330000, 0xff0000ee, 0xff0000dd, 0xff0000bb, 0xff0000aa, 0xff000088, 0xff000077, 0xff000055, 0xff000044,
	0xff000022, 0xff000011, 0xff00ee00, 0xff00dd00, 0xff00bb00, 0xff00aa00, 0xff008800, 0xff007700, 0xff005500, 0xff004400, 0xff002200, 0xff001100, 0xffee0000, 0xffdd0000, 0xffbb0000, 0xffaa0000,
	0xff880000, 0xff770000, 0xff550000, 0xff440000, 0xff220000, 0xff110000, 0xffeeeeee, 0xffdddddd, 0xffbbbbbb, 0xffaaaaaa, 0xff888888, 0xff777777, 0xff555555, 0xff444444, 0xff222222, 0xff111111
}

local function HexToRGB(hex)
	local r = bit.rshift(bit.band(hex, 0xff0000), 16)
	local g = bit.rshift(bit.band(hex, 0x00ff00), 8)
	local b = bit.band(hex, 0x0000ff)

	return Color(r, g, b)
end

for k, v in ipairs(voxPalette) do
	voxPalette[k] = HexToRGB(v)
end

local function readChunk(fs)
	local data = {
		ID = fs:Read(4),
		Bytes = fs:ReadLong(),
		Children = fs:ReadLong(),
		Offset = fs:Tell()
	}

	return data
end

local function readChunks(fs)
	local chunks = {}

	chunks.MAIN = readChunk(fs)

	while true do
		local chunk = readChunk(fs)

		if not chunks[chunk.ID] then
			chunks[chunk.ID] = chunk
		end

		fs:Skip(chunk.Bytes)

		if fs:EndOfFile() then
			break
		end
	end

	return chunks
end

function voxel.LoadVOX(path)
	local fs = assert(file.Open(path, "rb", "DATA"), "Unable to create file handle: " .. path)

	assert(fs:Read(4) == "VOX ", "Invalid file signature")

	fs:Read(4) -- Version

	local chunks = readChunks(fs)
	local palette = table.Copy(voxPalette)

	if chunks.RGBA then
		fs:Seek(chunks.RGBA.Offset)

		for i = 1, 256 do
			local r = fs:ReadByte()
			local g = fs:ReadByte()
			local b = fs:ReadByte()
			local a = fs:ReadByte()

			palette[i] = Color(r, g, b, a)
		end
	end

	local grid = voxel.Grid()

	fs:Seek(chunks.XYZI.Offset)

	for i = 1, fs:ReadLong() do
		grid:Set(fs:ReadByte(), fs:ReadByte(), fs:ReadByte(), palette[fs:ReadByte()])
	end

	return grid
end

-- Mdl
if CLIENT then
	local steps = 6

	local function voxelize(grid, scale, t1, t2, t3)
		local p1 = t1.pos * scale
		local p2 = t2.pos * scale
		local p3 = t3.pos * scale

		t1.uv = Vector(t1.u, t1.v)
		t2.uv = Vector(t2.u, t2.v)
		t3.uv = Vector(t3.u, t3.v)

		local b1 = p2 - p1
		local len1 = b1:Length()
		local b2 = p3 - p1
		local len2 = b2:Length()

		local u1 = t2.uv - t1.uv
		local u2 = t3.uv - t1.uv

		for l1 = 0, 1, 1 / (len1 * steps) do
			for l2 = 0, 1, 1 / (len2 * steps) do
				if l1 + l2 <= 1 then
					local res = (b1 * l1) + (b2 * l2)
					local pos = p1 + res

					local uv = t1.uv + (u1 * l1) + (u2 * l2)

					local x = math.floor(uv.x * 1024)
					local y = math.floor(uv.y * 1024)

					local col = grid:Get(pos.x, pos.y, pos.z)

					if col then
						table.insert(col, Color(render.ReadPixel(x, y)))
					else
						grid:Set(pos.x, pos.y, pos.z, {Color(render.ReadPixel(x, y))})
					end
				end
			end
		end

		for k, v in pairs(grid.Items) do
			if v.r then
				continue
			end

			local r = 0
			local g = 0
			local b = 0

			for _, col in pairs(v) do
				r = r + col.r * col.r
				g = g + col.g * col.g
				b = b + col.b * col.b
			end

			grid.Items[k] = Color(math.sqrt(r / #v), math.sqrt(g / #v), math.sqrt(b / #v))
		end
	end

	local rt = GetRenderTarget("voxel_from_model", 1024, 1024)

	function voxel.FromModel(mdl, scale)
		local grid = voxel.Grid()
		local data = util.GetModelMeshes(mdl)

		local buffer = {}

		for _, iMesh in pairs(data) do
			cam.Start2D()
			render.PushRenderTarget(rt)
				render.Clear(255, 255, 255, 255, true, true)

				render.SuppressEngineLighting(true)
				render.SetMaterial(Material(iMesh.material))
				render.DrawScreenQuad()
				render.SuppressEngineLighting(false)

				render.CapturePixels()
			render.PopRenderTarget()
			cam.End2D()

			for i = 1, #iMesh.triangles do
				local offset = i % 3

				if offset == 0 then
					voxelize(grid, scale, buffer[1], buffer[2], iMesh.triangles[i])
				else
					buffer[offset] = iMesh.triangles[i]
				end
			end
		end

		return grid
	end
end
