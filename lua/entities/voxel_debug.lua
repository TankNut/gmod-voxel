AddCSLuaFile()

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName = "Model Viewer"
ENT.Category = "Voxel"

ENT.Author = "TankNut"

ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")

	self:DrawShadow(false)
	self:EnableCustomCollisions(true)

	self:SetupVoxelModel(self:GetVoxelModel(), self:GetVoxelScale())
end

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "VoxelModel")

	self:NetworkVar("Int", 0, "VoxelScale")

	self:NetworkVar("Bool", 0, "DrawOrigin")
	self:NetworkVar("Bool", 1, "DrawAttachments")
	self:NetworkVar("Bool", 2, "DrawSubModels")

	self:NetworkVarNotify("VoxelModel", self.NotifyChanged)
	self:NetworkVarNotify("VoxelScale", self.NotifyChanged)

	if SERVER then
		self:SetVoxelModel("builtin/directions")
		self:SetVoxelScale(1)

		self:SetDrawOrigin(true)
		self:SetDrawAttachments(false)
		self:SetDrawSubModels(true)
	end
end

function ENT:SetupPhysics(model, scale)
	local mins, maxs = voxel.GetModel(model):GetBounds()

	mins = mins * scale
	maxs = maxs * scale

	if IsValid(self.PhysCollide) then
		self.PhysCollide:Destroy()
	end

	self.PhysCollide = CreatePhysCollideBox(mins, maxs)

	if SERVER then
		self:PhysicsInitBox(mins, maxs)
		self:SetSolid(SOLID_VPHYSICS)

		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()

		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
end

function ENT:NotifyChanged(name, old, new)
	if old == new then
		return
	end

	self:SetupVoxelModel(
		name == "VoxelModel" and new or self:GetVoxelModel(),
		name == "VoxelScale" and new or self:GetVoxelScale())
end

function ENT:SetupVoxelModel(model, scale)
	self:SetupPhysics(model, scale)

	if CLIENT then
		self:UpdateRenderBounds(model, scale)
	end
end

function ENT:GetVModel()
	return voxel.GetModel(self:GetVoxelModel())
end

function ENT:TestCollision(start, delta, isbox, extends)
	if not IsValid(self.PhysCollide) then
		return
	end

	local max = extends
	local min = -extends

	max.z = max.z - min.z
	min.z = 0

	local hit, norm, frac = self.PhysCollide:TraceBox(self:GetPos(), self:GetAngles(), start, start + delta, min, max)

	if not hit then
		return
	end

	return {
		HitPos = hit,
		Normal = norm,
		Fraction = frac
	}
end

function ENT:GetVAttachment(attachment)
	attachment = self:GetVModel().Attachments[attachment]

	return LocalToWorld(attachment.Offset * self:GetVoxelScale(), attachment.Angles, self:GetPos(), self:GetAngles())
end

if CLIENT then
	function ENT:UpdateRenderBounds(model, scale)
		local mins = Vector(math.huge, math.huge, math.huge)
		local maxs = Vector(-math.huge, -math.huge, -math.huge)

		local vModel = voxel.GetModel(model)

		vModel:GetComplexBounds(mins, maxs, vModel.SubModels)

		self:SetRenderBounds(mins * scale, maxs * scale)
	end

	function ENT:Draw()
		self:DrawModel()

		local matrix = self:GetWorldTransformMatrix()
		local scale = self:GetVoxelScale()

		matrix:SetScale(Vector(scale, scale, scale))

		cam.PushModelMatrix(matrix, true)
			local color = self:GetColor()
			local vModel = self:GetVModel()
			local subModels = self:GetDrawSubModels() and vModel.SubModels or {}

			render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
				vModel:Draw(subModels)
			render.SetColorModulation(1, 1, 1)

			if self:GetDrawOrigin() then
				render.SetColorMaterialIgnoreZ()
				render.DrawSphere(vector_origin, 0.2, 20, 20)

				render.DrawLine(vector_origin, vector_origin + Vector(1, 0, 0), Color(255, 0, 0), false)
				render.DrawLine(vector_origin, vector_origin + Vector(0, -1, 0), Color(0, 255, 0), false)
				render.DrawLine(vector_origin, vector_origin + Vector(0, 0, 1), Color(0, 0, 255), false)
			end

			if self:GetDrawAttachments() then
				for k, v in pairs(vModel.Attachments) do
					render.DrawLine(v.Offset, v.Offset + v.Angles:Forward(), Color(255, 0, 0), false)
					render.DrawLine(v.Offset, v.Offset + v.Angles:Right(), Color(0, 255, 0), false)
					render.DrawLine(v.Offset, v.Offset + v.Angles:Up(), Color(0, 0, 255), false)

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
		cam.PopModelMatrix()
	end

	function ENT:GetRenderMesh()
		local vModel = self:GetVModel()
		local vMesh = vModel:GetVMesh()

		local renderMesh
		local renderMat

		if vMesh then
			renderMesh = vMesh.Mesh
			renderMat = vMesh.Mat
		else
			renderMesh = voxel.Cube
			renderMat = voxel.Mat
		end

		local matrix = Matrix()
		local scale = self:GetVoxelScale()

		matrix:SetScale(Vector(scale, scale, scale))
		matrix:Translate(vModel.Offset)

		return {
			Mesh = renderMesh,
			Material = renderMat,
			Matrix = matrix
		}
	end

	net.Receive("voxel_debug_menu", function()
		local ent = net.ReadEntity()
		local dMenu = DermaMenu()

		dMenu:AddOption("Draw Origin", function()
			net.Start("voxel_debug_origin")
				net.WriteEntity(ent)
			net.SendToServer()
		end):SetChecked(ent:GetDrawOrigin())

		dMenu:AddOption("Draw Attachments", function()
			net.Start("voxel_debug_attachments")
				net.WriteEntity(ent)
			net.SendToServer()
		end):SetChecked(ent:GetDrawAttachments())

		dMenu:AddOption("Draw SubModels", function()
			net.Start("voxel_debug_submodels")
				net.WriteEntity(ent)
			net.SendToServer()
		end):SetChecked(ent:GetDrawSubModels())

		dMenu:AddSpacer()

		local modelMenu = dMenu:AddSubMenu("Model")

		for _, v in SortedPairsByValue(table.GetKeys(voxel.Models)) do
			modelMenu:AddOption(v, function()
				net.Start("voxel_debug_model")
					net.WriteEntity(ent)
					net.WriteString(v)
				net.SendToServer()
			end):SetChecked(ent:GetVoxelModel() == v)
		end

		local scaleMenu = dMenu:AddSubMenu("Scale")

		for k, v in pairs({1, 2, 5, 10, 15}) do
			scaleMenu:AddOption(v, function()
				net.Start("voxel_debug_scale")
					net.WriteEntity(ent)
					net.WriteUInt(v, 4)
				net.SendToServer()
			end):SetChecked(ent:GetVoxelScale() == v)
		end

		dMenu:Open(ScrW() * 0.5, ScrH() * 0.5)
	end)
else
	util.AddNetworkString("voxel_debug_menu")

	util.AddNetworkString("voxel_debug_origin")
	util.AddNetworkString("voxel_debug_attachments")
	util.AddNetworkString("voxel_debug_submodels")

	util.AddNetworkString("voxel_debug_model")
	util.AddNetworkString("voxel_debug_scale")

	function ENT:Use(ply)
		self.LastPlayer = ply

		net.Start("voxel_debug_menu")
			net.WriteEntity(self)
		net.Send(ply)
	end

	net.Receive("voxel_debug_origin", function(_, ply)
		local ent = net.ReadEntity()

		if IsValid(ent.LastPlayer) and ent.LastPlayer != ply then
			return
		end

		ent:SetDrawOrigin(not ent:GetDrawOrigin())
	end)

	net.Receive("voxel_debug_attachments", function(_, ply)
		local ent = net.ReadEntity()

		if IsValid(ent.LastPlayer) and ent.LastPlayer != ply then
			return
		end

		ent:SetDrawAttachments(not ent:GetDrawAttachments())
	end)

	net.Receive("voxel_debug_submodels", function(_, ply)
		local ent = net.ReadEntity()

		if IsValid(ent.LastPlayer) and ent.LastPlayer != ply then
			return
		end

		ent:SetDrawSubModels(not ent:GetDrawSubModels())
	end)

	net.Receive("voxel_debug_model", function(_, ply)
		local ent = net.ReadEntity()

		if IsValid(ent.LastPlayer) and ent.LastPlayer != ply then
			return
		end

		local model = net.ReadString()

		if model == ent:GetVoxelModel() or not voxel.Models[model] then
			return
		end

		ent:SetVoxelModel(model)
	end)

	net.Receive("voxel_debug_scale", function(_, ply)
		local ent = net.ReadEntity()

		if IsValid(ent.LastPlayer) and ent.LastPlayer != ply then
			return
		end

		local scale = net.ReadUInt(4)

		if scale == ent:GetVoxelScale() then
			return
		end

		ent:SetVoxelScale(scale)
	end)
end
