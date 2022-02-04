AddCSLuaFile()

-- Initial setup

local meta = setmetatable({}, {__call = function(self)
	return setmetatable({}, {__index = self})
end})

-- Functions

function meta:GetBounds()
	return self.Mins, self.Maxs
end

if CLIENT then
	function meta:Draw(submodels, drawSelf, drawDebug)
		if drawSelf and self.Mesh then
			local vMesh = self.Mesh

			render.SetMaterial(vMesh.Mat)
			vMesh.Mesh:Draw()
		end

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

			cam.PushModelMatrix(matrix, true)
				if v.Mesh then
					local vMesh = voxel.Meshes[v.Mesh]

					render.SetMaterial(vMesh.Mat)
					vMesh.Mesh:Draw()
				elseif v.Model then
					local vModel = voxel.Models[v.Model]

					vModel:Draw(vModel.Submodels, true, false)
				end
			cam.PopModelMatrix()
		end

		if drawDebug then
			for k, v in pairs(self.Attachments) do
				render.DrawLine(v.Offset, v.Offset + v.Angles:Forward(), Color(255, 0, 0), true)
				render.DrawLine(v.Offset, v.Offset + v.Angles:Right(), Color(0, 255, 0), true)
				render.DrawLine(v.Offset, v.Offset + v.Angles:Up(), Color(0, 0, 255), true)

				local matrix = cam.GetModelMatrix()

				local camang = (LocalPlayer():EyePos() - (matrix * v.Offset)):Angle()

				camang:RotateAroundAxis(camang:Forward(), 90)
				camang:RotateAroundAxis(camang:Right(), -90)

				cam.Start3D2D(matrix * v.Offset + Vector(0, 0, 3), camang, 0.1)
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

	vModel.Mesh = data.Mesh
	vModel.Offset = data.Offset or Vector()

	if data.UseMeshBounds and vModel.Mesh then
		local vMesh = assert(voxel.Meshes[data.Mesh], string.format("vModel %s references missing vMesh '%s'", name, data.Mesh))

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
