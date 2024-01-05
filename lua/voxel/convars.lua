AddCSLuaFile()

voxel.Convars = {}

voxel.Convars.Developer = CreateConVar("voxel_debug", 0, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enables a number of debug features for weapons.", 0, 1)

if CLIENT then
	voxel.Convars.ShadeMode = CreateClientConVar("voxel_shade_mode", 1, true, true, "", 1, 2)
	voxel.Convars.ShadeRes = CreateClientConVar("voxel_shade_res", 0.05, true, true, "", 0, 1)

	voxel.Convars.Access = CreateClientConVar("voxel_access", 0, true, true, "", 0, 1)

	voxel.Convars.DrawOrigin = CreateClientConVar("voxel_draw_origin", 1, true, false, "", 0, 1)
	voxel.Convars.DrawAttachments = CreateClientConVar("voxel_draw_attachments", 1, true, false, "", 0, 1)
	voxel.Convars.ExtraInfo = CreateClientConVar("voxel_extra_info", 1, true, false, "", 0, 1)

	voxel.Convars.ColorR = CreateClientConVar("voxel_col_r", 255, true, true, "", 0, 255)
	voxel.Convars.ColorG = CreateClientConVar("voxel_col_g", 255, true, true, "", 0, 255)
	voxel.Convars.ColorB = CreateClientConVar("voxel_col_b", 255, true, true, "", 0, 255)
end
