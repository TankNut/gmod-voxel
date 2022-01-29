AddCSLuaFile()

local function toIndex(x, y, z)
	x = math.Round(x)
	y = math.Round(y)
	z = math.Round(z)

	return x .. ":" .. y .. ":" .. z
end

local function fromIndex(index)
	local arr = string.Split(index, ":")

	return tonumber(arr[1]), tonumber(arr[2]), tonumber(arr[3])
end

local function inRange(val, min, max)
	return val >= min and val <= max
end

local function inBounds(x, y, z, mins, maxs)
	return inRange(x, mins.x, maxs.x) and inRange(y, mins.y, maxs.y) and inRange(z, mins.z, maxs.z)
end

-- Initial setup

local meta = voxel.Grid or setmetatable({}, {__call = function(self, mins, maxs)
	return setmetatable({Items = {}}, {__index = self})
end})

table.Empty(meta)

-- Static

meta.ToIndex = toIndex
meta.FromIndex = fromIndex

-- Functions

function meta:Set(x, y, z, val)
	self.Items[toIndex(x, y, z)] = val
end

function meta:Get(x, y, z)
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
end

function meta:Rotate(ang)
	local new = {}

	for index, val in pairs(self.Items) do
		local vec = Vector(fromIndex(index))

		vec:Rotate(ang)

		new[toIndex(vec.x, vec.y, vec.z)] = val
	end

	self.Items = new
end

function meta:Clear()
	self.Items = {}
end

function meta:Truncate(mins, maxs)
	for index in pairs(self.Items) do
		local x, y, z = fromIndex(index)

		if not inBounds(x, y, z, mins, maxs) then
			self.Items[index] = nil
		end
	end
end

function meta:GetCount()
	return table.Count(self.Items)
end

function meta:GetBounds()
	if table.IsEmpty(self.Items) then
		return Vector(), Vector()
	end

	local mins = Vector(math.huge, math.huge, math.huge)
	local maxs = Vector(-math.huge, -math.huge, -math.huge)

	for index in pairs(self.Items) do
		local x, y, z = fromIndex(index)

		mins.x = math.min(mins.x, x)
		mins.y = math.min(mins.y, y)
		mins.z = math.min(mins.z, z)

		maxs.x = math.max(maxs.x, x)
		maxs.y = math.max(maxs.y, y)
		maxs.z = math.max(maxs.z, z)
	end

	return mins, maxs
end

function meta:GetSize()
	if table.IsEmpty(self.Items) then
		return Vector()
	end

	local mins, maxs = self:GetBounds()

	return maxs - mins + Vector(1, 1, 1)
end

voxel.Grid = meta
