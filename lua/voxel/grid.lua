AddCSLuaFile()

local size = 255
local offset = 128
local mins = Vector(-128, -128, -128)
local maxs = Vector(127, 127, 127)

local function inRange(val, min, max)
	return val >= min and val <= max
end

local function inBounds(x, y, z)
	return inRange(x, mins.x, maxs.x) and inRange(y, mins.y, maxs.y) and inRange(z, mins.z, maxs.z)
end

local function toIndex(x, y, z)
	x = math.Round(x)
	y = math.Round(y)
	z = math.Round(z)

	assert(inBounds(x, y, z), string.format("Index out of bounds: %s %s %s", x, y, z))

	x = x + offset
	y = y + offset
	z = z + offset

	return (z * size * size) + (y * size) + x
end

local function fromIndex(index)
	local z = math.floor(index / (size * size))

	index = math.floor(index - (z * size * size))

	local y = math.floor(index / size)
	local x = math.floor(index % size)

	return x - offset, y - offset, z - offset
end

-- Initial setup

local meta = setmetatable({}, {__call = function(self)
	return setmetatable({Items = {}, Cache = {}}, {__index = self})
end})

-- Static

meta.ToIndex = toIndex
meta.FromIndex = fromIndex

-- Functions

function meta:Set(x, y, z, val)
	self.Items[toIndex(x, y, z)] = val
	self:InvalidateCache()
end

function meta:Get(x, y, z)
	if not inBounds(x, y, z) then
		return
	end

	return self.Items[toIndex(x, y, z)]
end

function meta:Has(x, y, z)
	return self:Get(x, y, z) != nil
end

function meta:Shift(x, y, z)
	local new = {}

	for index, val in pairs(self.Items) do
		local x2, y2, z2 = fromIndex(index)

		new[toIndex(x2 + x, y2 + y, z2 + z)] = val
	end

	self.Items = new
	self:InvalidateCache()
end

function meta:Rotate(ang)
	local new = {}

	for index, val in pairs(self.Items) do
		local vec = Vector(fromIndex(index))

		vec:Rotate(ang)

		new[toIndex(vec.x, vec.y, vec.z)] = val
	end

	self.Items = new
	self:InvalidateCache()
end

function meta:Clear()
	self.Items = {}
	self:InvalidateCache()
end

function meta:GetCount()
	local cache = self:GetCache("Count")

	if cache then
		return unpack(cache)
	end

	return self:WriteCache("Count", table.Count(self.Items))
end

function meta:GetBounds()
	local cache = self:GetCache("Bounds")

	if cache then
		return unpack(cache)
	end

	if table.IsEmpty(self.Items) then
		return self:WriteCache("Bounds", Vector(), Vector())
	end

	local minBounds = Vector(math.huge, math.huge, math.huge)
	local maxBounds = Vector(-math.huge, -math.huge, -math.huge)

	for index in pairs(self.Items) do
		local x, y, z = fromIndex(index)

		minBounds.x = math.min(minBounds.x, x)
		minBounds.y = math.min(minBounds.y, y)
		minBounds.z = math.min(minBounds.z, z)

		maxBounds.x = math.max(maxBounds.x, x)
		maxBounds.y = math.max(maxBounds.y, y)
		maxBounds.z = math.max(maxBounds.z, z)
	end

	return self:WriteCache("Bounds", minBounds, maxBounds)
end

function meta:GetSize()
	local cache = self:GetCache("Size")

	if cache then
		return unpack(cache)
	end

	if table.IsEmpty(self.Items) then
		return self:WriteCache("Size", Vector())
	end

	local minBounds, maxBounds = self:GetBounds()

	return self:WriteCache("Size", maxBounds - minBounds)
end

-- Caching

function meta:GetCache(index)
	return self.Cache[index]
end

function meta:WriteCache(index, ...)
	self.Cache[index] = {...}

	return ...
end

function meta:InvalidateCache()
	table.Empty(self.Cache)
end

voxel.Grid = meta
