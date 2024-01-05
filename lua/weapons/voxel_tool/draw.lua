function SWEP:CalcViewModelView(vm, _, _, pos, ang)
	return LocalToWorld(Vector(20, -10, -10), Angle(), pos, ang)
end

function SWEP:PreDrawViewModel()
	render.ModelMaterialOverride(voxel.Mat)

	local fullbright = IsValid(self:GetEditEntity()) and self:GetEditEntity():GetFullbright() or false

	if fullbright then
		render.SuppressEngineLighting(true)
	end

	voxel.Mat:SetVector("$color2", self:GetSelectedColor():ToVector())
end

function SWEP:PostDrawViewModel()
	render.ModelMaterialOverride()

	render.SuppressEngineLighting(false)
end

function SWEP:GetWorldPos()
	local ply = self:GetOwner()

	local pos = self:GetPos()
	local ang = self:GetAngles()

	if IsValid(ply) then
		local index = ply:LookupBone("ValveBiped.Bip01_R_Hand")

		pos, ang = ply:GetBonePosition(index)
		pos, ang = LocalToWorld(Vector(3, 0, 0), Angle(0, 15), pos, ang + Angle(-10, 0, 180))
	end

	return pos, ang
end

local mat = Material("engine/occlusionproxy")

function SWEP:DrawWorldModel()
	render.ModelMaterialOverride(mat)
		self:DrawModel()
	render.ModelMaterialOverride()

	local pos, ang = self:GetWorldPos()
	local matrix = Matrix()

	matrix:SetTranslation(pos)
	matrix:SetAngles(ang)
	matrix:SetScale(Vector(10, 10, 10))

	voxel.Mat:SetVector("$color2", self:GetSelectedColor():ToVector())

	render.SetMaterial(voxel.Mat)

	local fullbright = IsValid(self:GetEditEntity()) and self:GetEditEntity():GetFullbright() or false

	if fullbright then
		render.SuppressEngineLighting(true)
	end

	cam.PushModelMatrix(matrix, true)
		voxel.Cube:Draw()
	cam.PopModelMatrix()

	render.SuppressEngineLighting(false)
end

local minBounds = Vector(-0.5, -0.5, -0.5)
local maxBounds = Vector(0.5, 0.5, 0.5)

local colorR = Color(255, 0, 0)
local colorG = Color(0, 255, 0)
local colorB = Color(0, 0, 255)

function SWEP:PostDrawOpaqueRenderables(depth, skybox)
	if skybox then
		return
	end

	if not self:IsCarriedByLocalPlayer() or LocalPlayer():GetActiveWeapon() != self then
		return
	end

	local ent = self:GetEditEntity()

	if IsValid(ent) then
		local mins, maxs = ent:GetModelBounds()

		local hue = CurTime() * (360 / 10) % 360

		render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), mins, maxs, HSVToColor(hue, 1, 1), true)

		local normal, x, y, z = self:GetTrace()
		local offset, scale = ent:GetOffsetData()

		if voxel.Convars.DrawOrigin:GetBool() then
			render.SetColorMaterialIgnoreZ()

			local pos = ent:LocalToWorld(offset)

			render.DrawSphere(ent:LocalToWorld(offset), scale * 0.2, 20, 20)

			render.DrawLine(pos, pos + ent:GetForward() * scale, colorR)
			render.DrawLine(pos, pos + ent:GetRight() * scale, colorG)
			render.DrawLine(pos, pos + ent:GetUp() * scale, colorB)
		end

		if voxel.Convars.DrawAttachments:GetBool() then
			for name, data in pairs(ent.Attachments) do
				local pos = ent:LocalToWorld(offset + data.Offset * scale)
				local dir = ent:LocalToWorldAngles(data.Angles)

				render.DrawLine(pos, pos + dir:Forward() * scale, colorR)
				render.DrawLine(pos, pos + dir:Right() * scale, colorG)
				render.DrawLine(pos, pos + dir:Up() * scale, colorB)

				local ang = (EyePos() - pos + Vector(0, 0, 3)):Angle()

				ang:RotateAroundAxis(ang:Forward(), 90)
				ang:RotateAroundAxis(ang:Right(), -90)

				cam.Start3D2D(pos + Vector(0, 0, 3), ang, 0.1)
					cam.IgnoreZ(true)

					render.PushFilterMag(TEXFILTER.POINT)
					render.PushFilterMin(TEXFILTER.POINT)

					draw.DrawText(name, "BudgetLabel", 0, 0, color_white, TEXT_ALIGN_CENTER)

					render.PopFilterMin()
					render.PopFilterMag()

					cam.IgnoreZ(false)
				cam.End3D2D()
			end
		end

		if normal then
			mins = minBounds * scale
			maxs = maxBounds * scale

			local pos = ent:LocalToWorld(offset + Vector(x, y, z) * scale)

			render.DrawWireframeBox(pos, ent:GetAngles(), mins, maxs, HSVToColor(hue, 1, 1), true)
		end
	end
end
