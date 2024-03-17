local PANEL = {}

function PANEL:Init()
	self:SetTextColor(Color(255, 255, 255))
	self:SetFont("BWhiteList.Label")
end

function PANEL:SetText(text)
	DLabel.SetText(self, text)
	self:SetSize(self:GetTextSize())
end

derma.DefineControl("BWL_Label", "White list menu label", PANEL, "DLabel")