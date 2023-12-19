EFFECT.Mat = Material("trails/smoke")

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

	self.Start = self:GetStartPos(self.Ent)
	self.End = data:GetOrigin()
	self.Normal = (self.End - self.Start):GetNormalized()

	self.Length = self.Start:Distance(self.End)

	self:SetRenderBoundsWS(self.Start, self.End)

	self.StartTime = CurTime()
	self.DieTime = CurTime() + 0.1
end

function EFFECT:IsDrawingVM()
	return self.Ent:IsCarriedByLocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer()
end

function EFFECT:GetStartPos(ent)
	local pos, ang = ent.VoxelModel:GetAttachment("muzzle")

	if self:IsDrawingVM() then
		pos, ang = LocalToWorld(pos * ent.VoxelData.Scale, ang, ent:GetViewPos())

		return translatefov(ent, pos), ang
	else
		return LocalToWorld(pos * ent.VoxelData.Scale, ang, ent:GetWorldPos())
	end
end

function EFFECT:Think()
	if not self.DieTime or CurTime() > self.DieTime then
		return false
	end

	return true
end

local dirs = {
	Vector(1, 0, 0),
	Vector(-1, 0, 0),
	Vector(0, 1, 0),
	Vector(0, -1, 0),
	Vector(0, 0, 1),
	Vector(0, 0, -1)
}

local function getLighting(vec)
	local col = Vector()

	for _, v in pairs(dirs) do
		col = col + render.ComputeLighting(vec, v)
	end

	col:Div(6)

	local len = col:Length()

	return Color(len * 255, len * 255, len * 255)
end

local size = 2
local maxAlpha = 100

function EFFECT:Render()
	local life = math.TimeFraction(self.StartTime, self.DieTime, CurTime())
	local alpha = maxAlpha - life * maxAlpha
	local dist = self.Length / size

	render.SetMaterial(self.Mat)
	render.StartBeam(size + 1)
		for i = 0, size do
			local pos = self.Start + (self.Normal * dist) * i
			render.AddBeam(pos, 5 + 10 * life, 0, ColorAlpha(getLighting(pos), alpha))
		end
	render.EndBeam()
end
