AddCSLuaFile()

-- Initial setup

local meta = voxel.Model or setmetatable({}, {__call = function(self)
	return setmetatable({}, {__index = self})
end})

-- Functions

function meta:GetVMesh()
	return voxel.GetMesh(self.Mesh)
end

-- Returns the mins and maxs as loaded
function meta:GetBounds()
	return self.Mins, self.Maxs
end

-- Returns the mins and maxs expanded to include submodels
function meta:GetComplexBounds(mins, maxs, subModels, transform)
	if not transform then
		transform = Matrix()
	end

	local transformMins = transform * self.RenderMins
	local transformMaxs = transform * self.RenderMaxs

	mins.x = math.min(mins.x, transformMins.x, transformMaxs.x)
	mins.y = math.min(mins.y, transformMins.y, transformMaxs.y)
	mins.z = math.min(mins.z, transformMins.z, transformMaxs.z)

	maxs.x = math.max(maxs.x, transformMins.x, transformMaxs.x)
	maxs.y = math.max(maxs.y, transformMins.y, transformMaxs.y)
	maxs.z = math.max(maxs.z, transformMins.z, transformMaxs.z)

	for _, v in pairs(subModels) do
		local matrix = Matrix()

		if v.Attachment then
			local attachment = self.Attachments[v.Attachment]

			matrix:Translate(attachment.Offset)
			matrix:Rotate(attachment.Angles)
		end

		if v.Offset then matrix:Translate(v.Offset) end
		if v.Angles then matrix:Rotate(v.Angles) end
		if v.Scale then matrix:SetScale(isnumber(v.Scale) and Vector(v.Scale, v.Scale, v.Scale) or v.Scale) end

		if v.Mesh then
			local subMesh = voxel.GetMesh(v.Mesh)

			if subMesh then
				local newMatrix = transform * matrix
				local newMins = newMatrix * subMesh.Mins
				local newMaxs = newMatrix * subMesh.Maxs

				mins.x = math.min(mins.x, newMins.x, newMaxs.x)
				mins.y = math.min(mins.y, newMins.y, newMaxs.y)
				mins.z = math.min(mins.z, newMins.z, newMaxs.z)

				maxs.x = math.max(maxs.x, newMins.x, newMaxs.x)
				maxs.y = math.max(maxs.y, newMins.y, newMaxs.y)
				maxs.z = math.max(maxs.z, newMins.z, newMaxs.z)
			end
		elseif v.Model then
			local subModel = voxel.GetModel(v.Model)

			if subModel then
				subModel:GetComplexBounds(mins, maxs, subModel.SubModels, transform * matrix)
			end
		end
	end
end

function meta:GetAttachment(att)
	if not self.Attachments[att] then
		return Vector(), Angle()
	end

	return self.Attachments[att].Offset, self.Attachments[att].Angles
end

if CLIENT then
	function meta:Draw(submodels, drawSelf)
		local colorMod = Vector(render.GetColorModulation())
		local vMesh = self:GetVMesh()

		if drawSelf then
			vMesh:Draw(colorMod)
		end

		local matrix = Matrix()

		for _, v in pairs(submodels) do
			matrix:Identity()

			if v.Attachment and self.Attachments[v.Attachment] then
				local attachment = self.Attachments[v.Attachment]

				matrix:Translate(attachment.Offset)
				matrix:Rotate(attachment.Angles)
			end

			if v.Offset then matrix:Translate(v.Offset) end
			if v.Angles then matrix:Rotate(v.Angles) end
			if v.Scale then matrix:SetScale(isnumber(v.Scale) and Vector(v.Scale, v.Scale, v.Scale) or v.Scale) end

			cam.PushModelMatrix(matrix, true)
				if v.Mesh then
					local submesh = voxel.GetMesh(v.Mesh)
					local col = colorMod

					if v.Color then
						col = v.Color:ToVector()
					end

					if submesh then
						submesh:Draw(col)
					end
				elseif v.Model then
					local submodel = voxel.GetModel(v.Model)

					if submodel then
						submodel:Draw(submodel.Submodels, true)
					end
				end
			cam.PopModelMatrix()
		end
	end
end

local function filename(path)
	return string.Replace(string.StripExtension(path), "voxel/models/", "")
end

function meta.Load(path)
	local name = filename(path)

	local vModel = meta()
	local data = include(path)

	vModel.Mesh = assert(data.Mesh, string.format("vModel %s is missing required key 'Mesh'", name))
	vModel.Offset = data.Offset or Vector()

	local vMesh = assert(voxel.GetMesh(data.Mesh), string.format("vModel %s references missing vMesh '%s'", name, vModel.Mesh))

	vModel.RenderMins, vModel.RenderMaxs = vMesh:GetBounds()

	if data.UseMeshBounds then
		vModel.Mins, vModel.Maxs = vMesh:GetBounds()

		vModel.Mins = vModel.Mins + vModel.Offset
		vModel.Maxs = vModel.Maxs + vModel.Offset

		if data.Mins then
			vModel.Mins = vModel.Mins - data.Mins
		end

		if data.Maxs then
			vModel.Maxs = vModel.Maxs + data.Maxs
		end
	else
		vModel.Mins = assert(data.Mins, string.format("vModel %s is missing required key 'Mins'", name))
		vModel.Maxs = assert(data.Maxs, string.format("vModel %s is missing required key 'Maxs'", name))
	end

	vModel.Attachments = {}

	if data.Attachments then
		for k, v in pairs(data.Attachments) do
			vModel.Attachments[k] = {
				Name = k,
				Offset = v.Offset or Vector(),
				Angles = v.Angles or Angle()
			}
		end
	end

	vModel.SubModels = {}

	if data.SubModels then
		for k, v in pairs(data.SubModels) do
			vModel.SubModels[k] = {
				Mesh = v.Mesh,
				Model = v.Model,
				Attachment = v.Attachment,
				Offset = v.Offset,
				Angles = v.Angles,
				Scale = v.Scale
			}
		end
	end

	voxel.Models[name] = vModel

	return vModel
end

voxel.Model = meta
