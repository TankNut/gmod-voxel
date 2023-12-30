--[[
SDK References:

FX_AR2Tracer
CFXStaticLine::Draw
--]]

EFFECT.Mat = Material("effects/gunshiptracer")
EFFECT.Speed = 8000

local function translatefov(ent, pos, inverse)
	local worldx = math.tan(LocalPlayer():GetFOV() * (math.pi / 360))
	local viewx = math.tan(ent.ViewModelFOV * (math.pi / 360))

	local factor = Vector(worldx / viewx, worldx / viewx, 0)
	local tmp = pos - EyePos()

	local eye = EyeAngles()
	local transformed = Vector(eye:Right():Dot(tmp), eye:Up():Dot(tmp), eye:Forward():Dot(tmp))

	if inverse then
		transformed.x = transformed.x / factor.x
		transformed.y = transformed.y / factor.y
	else
		transformed.x = transformed.x * factor.x
		transformed.y = transformed.y * factor.y
	end

	local out = (eye:Right() * transformed.x) + (eye:Up() * transformed.y) + (eye:Forward() * transformed.z)

	return EyePos() + out
end

function EFFECT:Init(data)
	self.Ent = data:GetEntity()

	self.Start = self:GetStartPos(self.Ent) or data:GetStart()
	self.End = data:GetOrigin()

	self.Dir = (self.End - self.Start):GetNormalized()
	self.Dist = self.Start:Distance(self.End)

	if self.Dist < 128 then
		return
	end

	self.Length = math.Rand(128, 256)
	self.Scale = self.Ent.GetTracerSize and self.Ent:GetTracerSize() or math.Rand(1.5, 3)

	self.Life = (self.Dist + self.Length) /  self.Speed

	self:SetRenderBoundsWS(self.Start, self.End)

	self.StartTime = CurTime()
end

function EFFECT:IsDrawingVM()
	return self.Ent:IsCarriedByLocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer()
end

function EFFECT:GetStartPos(ent)
	if not ent.VoxelModel then
		return
	end

	local pos, ang = ent.VoxelModel:GetAttachment("muzzle")

	if self:IsDrawingVM() then
		pos, ang = LocalToWorld(pos * ent.VoxelData.Scale, ang, ent:GetViewPos(true))

		return translatefov(ent, pos), ang
	else
		return LocalToWorld(pos * ent.VoxelData.Scale, ang, ent:GetWorldPos())
	end
end

function EFFECT:Think()
	if not self.StartTime or CurTime() > self.StartTime + self.Life then
		return false
	end

	return true
end

function EFFECT:Render()
	if not self.StartTime then
		return
	end

	local startDist = self.Speed * (CurTime() - self.StartTime)
	local endDist = startDist - self.Length

	startDist = math.max(startDist, 0)
	endDist = math.max(endDist, 0)

	if startDist == 0 and endDist == 0 then
		return
	end

	startDist = math.min(startDist, self.Dist)
	endDist = math.min(endDist, self.Dist)

	local dist = math.abs(startDist - endDist)
	local offset = dist / self.Length

	local endPos = self.Start + (self.Dir * startDist)
	local startPos = self.Start + (self.Dir * endDist)

	local halfWidth = ScrW() * 0.5

	local z = EyeAngles():Forward():Dot(startPos - EyePos())
	local screenSpaceWidth = self.Scale * halfWidth / z

	local alpha = 1
	local scale = self.Scale

	if screenSpaceWidth < 0.5 then
		alpha = math.Remap(screenSpaceWidth, 0.25, 2, 0.3, 1)
		alpha = math.Clamp(alpha, 0.25, 1)
		scale = 0.5 * z / halfWidth
	end

	local col = 64 * alpha

	render.SetMaterial(self.Mat)
	render.DrawBeam(startPos, endPos, scale, 0, offset, color_white)
	render.DrawBeam(startPos, endPos, scale * 2, 0, offset, Color(col, col, col))
end
