return {
	Mesh = "wa2000_scopeless",
	UseMeshBounds = true,

	Attachments = {
		["muzzle"] = {
			Offset = Vector(19, 0, 2),
			Angles = Angle()
		},
		["scope"] = {
			Offset = Vector(2, 0, 4),
			Angles = Angle()
		}
	},

	SubModels = {
		["scope"] = {
			Mesh = "wa2000_scope",
			Attachment = "scope"
		},
		["muzzle"] = {
			Mesh = "wa2000_muzzle",
			Attachment = "muzzle",
			Offset = Vector(0.3, 0, 0),
			Scale = 0.6
		}
	}
}
