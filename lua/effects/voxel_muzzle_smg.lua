--[[
SDK References: 

CTempEnts::MuzzleFlash_SMG1_Player
FX_MuzzleEffectAttached
--]]

EFFECT.VMMats = {}
EFFECT.WMMats = {}

for i = 1, 4 do
	EFFECT.VMMats[i] = Material("effects/muzzleflash" .. i .. "_noz")
	EFFECT.WMMats[i] = Material("effects/muzzleflash" .. i)
end

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
	self.Scale = data:GetScale()

	if not IsValid(self.Ent) then
		return
	end

	if self.Ent:IsCarriedByLocalPlayer() then
		self:ParticleInitVM()
	end

	self:ParticleInitWM()
end

function EFFECT:ParticleInitVM()
	self.EmitterVM = ParticleEmitter(Vector())
	self.EmitterVM:SetNoDraw(true)

	local forward = Vector(1, 0, 0)
	local scale = math.Rand(1.25, 1.5) * self.Scale

	for i = 1, 6 do
		local offset = forward * (i * 8 * scale)
		local p = self.EmitterVM:Add(table.Random(self.VMMats), offset)

		p:SetDieTime(0.025)

		p:SetColor(255, 255, math.random(200, 255))

		local size = (math.Rand(6, 8) * (8 - i) / 6) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)

		p:SetRoll(math.random(0, 360))
	end
end

function EFFECT:ParticleInitWM()
	self.EmitterWM = ParticleEmitter(Vector())
	self.EmitterWM:SetNoDraw(true)

	local forward = Vector(1, 0, 0)
	local scale = math.Rand(self.Scale - 0.25, self.Scale + 0.25)

	for i = 1, 9 do
		local offset = forward * (i * 2 * scale)
		local p = self.EmitterWM:Add(table.Random(self.WMMats), offset)

		p:SetDieTime(0.025)

		p:SetStartAlpha(255)
		p:SetEndAlpha(128)

		local size = (math.Rand(6, 9) * (12 - i) / 9) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)

		p:SetRoll(math.random(0, 360))
	end
end

function EFFECT:IsDrawingVM()
	return self.Ent:IsCarriedByLocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer()
end

function EFFECT:GetStartPos(ent)
	local pos, ang = ent.VoxelModel:GetAttachment("muzzle")

	if self:IsDrawingVM() then
		pos, ang = LocalToWorld(pos * ent.Voxel.Scale, ang, ent:GetViewPos())

		return translatefov(ent, pos), ang
	else
		return LocalToWorld(pos * ent.Voxel.Scale, ang, ent:GetWorldPos())
	end
end

function EFFECT:Think()
	local live = false

	if not IsValid(self.Ent) then
		return false
	end

	for _, v in pairs({self.EmitterVM, self.EmitterWM}) do
		if v and v:IsValid() then
			if v:GetNumActiveParticles() == 0 then
				v:Finish()
			else
				live = true
			end
		end
	end

	return live
end

function EFFECT:Render()
	local pos, ang = self:GetStartPos(self.Ent)

	self:SetPos(pos)

	cam.Start3D(WorldToLocal(EyePos(), EyeAngles(), pos, ang))
		local emitter = self.EmitterWM

		if self:IsDrawingVM() then
			emitter = self.EmitterVM
		end

		if emitter and emitter:IsValid() then
			emitter:Draw()
		end
	cam.End3D()
end
