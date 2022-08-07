AddCSLuaFile()

-- Initial setup

local meta = setmetatable({}, {__call = function(self)
	return setmetatable({}, {__index = self})
end})

-- Functions

function meta:GetBounds()
	return self.Mins, self.Maxs
end

function meta:GetVMesh()
	return voxel.GetMesh(self.Mesh)
end

if CLIENT then
	function meta:GetRenderBounds(mins, maxs, submodels)
		local transform = cam.GetModelMatrix()

		local transformMins = transform * self.Mins
		local transformMaxs = transform * self.Maxs

		mins.x = math.min(mins.x, transformMins.x, transformMaxs.x)
		mins.y = math.min(mins.y, transformMins.y, transformMaxs.y)
		mins.z = math.min(mins.z, transformMins.z, transformMaxs.z)

		maxs.x = math.max(maxs.x, transformMins.x, transformMaxs.x)
		maxs.y = math.max(maxs.y, transformMins.y, transformMaxs.y)
		maxs.z = math.max(maxs.z, transformMins.z, transformMaxs.z)

		for _, v in pairs(submodels) do
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
					cam.PushModelMatrix(matrix, true)
						subModel:GetRenderBounds(mins, maxs, subModel.Submodels)
					cam.PopModelMatrix()
				end
			end
		end
	end

	function meta:Draw(submodels, drawSelf, drawDebug)
		local vMesh = self:GetVMesh()

		if drawSelf then
			vMesh:Draw(render.GetColorModulation())
		end

		local matrix = Matrix()

		for _, v in pairs(submodels) do
			matrix:Zero()

			if v.Attachment then
				local attachment = self.Attachments[v.Attachment]

				matrix:Translate(attachment.Offset)
				matrix:Rotate(attachment.Angles)
			end

			if v.Offset then matrix:Translate(v.Offset) end
			if v.Angles then matrix:Rotate(v.Angles) end
			if v.Scale then matrix:SetScale(isnumber(v.Scale) and Vector(v.Scale, v.Scale, v.Scale) or v.Scale) end

			cam.PushModelMatrix(matrix, true)
				if v.Mesh then
					local subMesh = voxel.GetMesh(v.Mesh)

					if subMesh then
						subMesh:Draw(render.GetColorModulation())
					end
				elseif v.Model then
					local subModel = voxel.GetModel(v.Model)

					if subModel then
						subModel:Draw(subModel.Submodels, true, false)
					end
				end
			cam.PopModelMatrix()
		end

		if drawDebug then
			for k, v in pairs(self.Attachments) do
				render.DrawLine(v.Offset, v.Offset + v.Angles:Forward(), Color(255, 0, 0), true)
				render.DrawLine(v.Offset, v.Offset + v.Angles:Right(), Color(0, 255, 0), true)
				render.DrawLine(v.Offset, v.Offset + v.Angles:Up(), Color(0, 0, 255), true)

				local camMatrix = cam.GetModelMatrix()

				local camang = (LocalPlayer():EyePos() - (camMatrix * v.Offset)):Angle()

				camang:RotateAroundAxis(camang:Forward(), 90)
				camang:RotateAroundAxis(camang:Right(), -90)

				cam.Start3D2D(camMatrix * v.Offset + Vector(0, 0, 3), camang, 0.1)
					cam.IgnoreZ(true)
					render.PushFilterMag(TEXFILTER.POINT)
					render.PushFilterMin(TEXFILTER.POINT)

					draw.DrawText(k, "BudgetLabel", 0, 0, color_white, TEXT_ALIGN_CENTER)

					render.PopFilterMin()
					render.PopFilterMag()
					cam.IgnoreZ(false)
				cam.End3D2D()
			end
		end
	end
end

local function filename(path)
	return string.StripExtension(string.GetFileFromFilename(path))
end

function meta.Load(path)
	local name = filename(path)

	local vModel = meta()
	local data = include(path)

	vModel.Mesh = assert(data.Mesh, string.format("vModel %s is missing required key 'Mesh'", name))
	vModel.Offset = data.Offset or Vector()

	local vMesh = assert(voxel.GetModel(data.Mesh), string.format("vModel %s references missing vMesh '%s'", name, vModel.Mesh))

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

	vModel.Submodels = {}

	if data.Submodels then
		for k, v in pairs(data.Submodels) do
			vModel.Submodels[k] = {
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
