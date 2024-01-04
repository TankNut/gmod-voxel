DEFINE_BASECLASS("voxel_swep_base")

function SWEP:ShouldHideViewModel()
	return self:IsReloading() or self:InScope()
end

local mat = Material("reticles/eotech")

function SWEP:DrawVoxelModel()
	BaseClass.DrawVoxelModel(self)

	--self:DrawHolosight(Vector(-1, 0, 5), Vector(-1, 0, 0), 100, 1, 1, Color(0, 0, 0, 50), 2, 2, Color(255, 0, 0), mat)
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

	render.DrawQuadEasy(pos + -normal * distance, normal, sightWidth * (distance / 100), sightHeight * (distance / 100), Color(255, 0, 0))

	render.SetStencilEnable(false)
end
