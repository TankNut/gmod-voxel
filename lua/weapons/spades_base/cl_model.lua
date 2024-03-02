DEFINE_BASECLASS("voxel_swep_base")

function SWEP:ShouldHideViewModel()
	return self:IsReloading() or self:InScope()
end

function SWEP:DrawVoxelModel()
	BaseClass.DrawVoxelModel(self)

	if self.Sights.Holosight then
		local pos, ang = self.VoxelModel:GetAttachment(self.Sights.Attachment)

		self:DrawHolosight(pos, -ang:Forward(), 100, self.Sights.GlassSize.x, self.Sights.GlassSize.y, self.Sights.GlassColor, self.Sights.HoloSize.x, self.Sights.HoloSize.y, self.Sights.HoloColor, self.Sights.HoloMaterial)
	end
end

function SWEP:DrawHolosight(pos, normal, distance, glassWidth, glassHeight, glassColor, sightWidth, sightHeight, sightColor, sightMaterial)
	if halo.RenderedEntity() == self then
		return
	end

	render.SetColorMaterial()

	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)

	render.SetStencilReferenceValue(0)

	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	render.ClearStencil()

	render.SetStencilEnable(true)

	render.SetStencilReferenceValue(1)
	render.SetStencilCompareFunction(STENCIL_ALWAYS)

	-- Draw mask
	render.DrawQuadEasy(pos, normal, glassWidth, glassHeight, glassColor)

	render.SetStencilCompareFunction(STENCIL_EQUAL)

	-- Draw contents
	if sightMaterial then
		render.SetMaterial(sightMaterial)
	end

	render.DrawQuadEasy(pos + -normal * distance, normal, sightWidth * (distance / 100), sightHeight * (distance / 100), sightColor)

	render.SetStencilEnable(false)
end
