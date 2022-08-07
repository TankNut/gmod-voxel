AddCSLuaFile()

voxel.Convars = {}

if CLIENT then
	voxel.Convars.ShadeMode = CreateClientConVar("voxel_shade_mode", "1", true, true, "", 1, 2)
	voxel.Convars.ShadeRes = CreateClientConVar("voxel_shade_res", "0.05", true, true, "", 0, 1)

	voxel.Convars.Access = CreateClientConVar("voxel_access", "0", true, true, "", 0, 1)

	voxel.Convars.DrawOrigin = CreateClientConVar("voxel_draw_origin", "1", true, false, "", 0, 1)

	voxel.Convars.ColorR = CreateClientConVar("voxel_col_r", 255, true, true, "", 0, 255)
	voxel.Convars.ColorG = CreateClientConVar("voxel_col_g", 255, true, true, "", 0, 255)
	voxel.Convars.ColorB = CreateClientConVar("voxel_col_b", 255, true, true, "", 0, 255)
	voxel.Convars.ColorA = CreateClientConVar("voxel_col_a", 255, true, true, "", 0, 255)
end
