AddCSLuaFile()

if SERVER then
	return
end

local PANEL = {}

function PANEL:Init()
end

function PANEL:Setup(vars)
	self:Clear()

	local text = self:Add("DTextEntry")

	text:SetNumeric(true)
	text:SetPaintBackground(false)
	text:SetUpdateOnType(true)
	text:Dock(FILL)

	self.IsEditing = function()
		return text:IsEditing()
	end

	self.IsEnabled = function()
		return text:IsEnabled()
	end

	self.SetEnabled = function(_, b)
		text:SetEnabled(b)
	end

	-- Set the value
	self.SetValue = function(_, val)
		text:SetText(util.TypeToString(val))
	end

	text.OnValueChange = function(_, newval)
		self:ValueChanged(newval)
	end

	text.OnEnter = function(_, newval)
		if self.m_pRow.OnEnter then
			self.m_pRow:OnEnter(newval)
		end
	end
end

derma.DefineControl("DProperty_VoxelOffset", "", PANEL, "DProperty_Generic")
