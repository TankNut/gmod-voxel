--[[
SDK References: 

CTempEnts::MuzzleFlash_Combine_Player
CTempEnts::MuzzleFlash_Combine_NPC
--]]

EFFECT.VMMats = {}
EFFECT.WMMats = {}

EFFECT.StriderMuzzle = Material("effects/strider_muzzle")

for i = 1, 2 do
	EFFECT.VMMats[i] = Material("effects/combinemuzzle" .. i .. "_noz")
	EFFECT.WMMats[i] = Material("effects/combinemuzzle" .. i)
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

	if self.Ent:IsCarriedByLocalPlayer() then
		self:ParticleInitVM()
	end

	self:ParticleInitWM()
end

function EFFECT:ParticleInitVM()
	self.EmitterVM = ParticleEmitter(Vector())
	self.EmitterVM:SetNoDraw(true)

	local forward = Vector(1, 0, 0)
	local scale = math.Rand(2, 2.25) * self.Scale

	for i = 1, 5 do
		local offset = forward * (i * 4 * scale)
		local p = self.EmitterVM:Add(table.Random(self.VMMats), offset)

		p:SetDieTime(0.025)

		p:SetColor(255, 255, math.random(200, 255))

		local size = (math.Rand(6, 8) * (12 - i) / 12) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)

		p:SetRoll(math.random(0, 360))
	end

	local p = self.EmitterVM:Add(table.Random(self.VMMats), Vector())

	p:SetDieTime(0.025)

	p:SetColor(255, 255, 255)

	p:SetStartAlpha(math.random(64, 128))
	p:SetEndAlpha(32)

	local size = math.Rand(10, 16) * self.Scale

	p:SetStartSize(size)
	p:SetEndSize(size)

	p:SetRoll(math.random(0, 360))
end

function EFFECT:ParticleInitWM()
	self.EmitterWM = ParticleEmitter(Vector())
	self.EmitterWM:SetNoDraw(true)

	local forward = Vector(1, 0, 0)
	local scale = math.Rand(1, 1.5) * self.Scale
	local burst = math.Rand(50, 150)

	local length = 6

	local function createParticle(offset, dir)
		local p = self.EmitterWM:Add(table.Random(self.WMMats), offset)

		p:SetDieTime(0.1)

		p:SetVelocity(dir * burst)

		p:SetColor(255, 255, 255)

		p:SetStartAlpha(255)
		p:SetEndAlpha(0)

		p:SetRoll(math.random(0, 360))

		return p
	end

	-- Front flash
	for i = 1, length - 1 do
		local p = createParticle(forward * (i * 2 * scale), forward)
		local size = (math.Rand(6, 8) * (length * 1.25 - i) / length) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)
	end

	-- Diagonal flashes
	local left = Vector(0, -1, -1)

	for i = 1, length - 1 do
		local p = createParticle(left * (i * scale), left * 0.25)
		local size = (math.Rand(2, 4) * (length - i) / (length * 0.5)) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)
	end

	local right = Vector(0, 1, -1)

	for i = 1, length - 1 do
		local p = createParticle(right * (i * scale), right * 0.25)
		local size = (math.Rand(2, 4) * (length - i) / (length * 0.5)) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)
	end

	local up = Vector(0, 0, 1)

	for i = 1, length - 1 do
		local p = createParticle(up * (i * scale), up * 0.25)
		local size = (math.Rand(2, 4) * (length - i) / (length * 0.5)) * scale

		p:SetStartSize(size)
		p:SetEndSize(size)
	end

	local p = self.EmitterWM:Add(self.StriderMuzzle, Vector())

	p:SetDieTime(math.Rand(0.3, 0.4))

	p:SetColor(255, 255, 255)

	p:SetStartAlpha(255)
	p:SetEndAlpha(0)

	p:SetStartSize(math.Rand(12, 16) * scale)
	p:SetEndSize(0)

	p:SetRoll(math.random(0, 360))
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
