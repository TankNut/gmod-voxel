function SWEP:CalcViewModelView(vm, _, _, pos, ang)
	return LocalToWorld(Vector(20, -10, -10), Angle(), pos, ang)
end

function SWEP:PreDrawViewModel()
	render.ModelMaterialOverride(voxel.Mat)
	render.SetColorModulation(self:GetSelectedColor():ToVector():Unpack())
end

function SWEP:PostDrawViewModel()
	render.ModelMaterialOverride()
end

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

		if normal then
			mins = Vector(-0.5, -0.5, -0.5) * scale
			maxs = mins:GetNegated()

			local pos = ent:LocalToWorld(offset * scale + Vector(x, y, z) * scale)

			render.DrawWireframeBox(pos, ent:GetAngles(), mins, maxs, HSVToColor(hue, 1, 1), true)
		end

		if voxel.Convars.DrawOrigin:GetBool() then
			render.SetColorMaterialIgnoreZ()
			render.DrawSphere(ent:LocalToWorld(offset * scale), scale * 0.2, 20, 20)
		end
	end
end
