local PANEL = {}

function PANEL:Init()
	self:SetFont("BWhiteList.Label")
	self:SetTextColor(Color(255, 255, 255))
end

function PANEL:Paint(w, h)
	local p = (self:IsDown() or self.m_bSelected) and 0 or 1
	// Рамка
	surface.SetDrawColor(50, 50, 50)
	surface.DrawOutlinedRect(0, 0, w, h, 1+p)

	// Основное окно
	surface.SetDrawColor(clr or Color(35, 35, 35))
	surface.DrawRect(1, 1, w-(2+p), h-(2+p))  -- 3 вмсето 2 для объёма
end

function PANEL:SetEnabled(bool)
	if bool then
		self:SetTextColor(Color(255, 255, 255))
	else
		self:SetTextColor(Color(100, 100, 100))
	end

	DButton.SetEnabled(self, bool)
end

derma.DefineControl("BWL_Button", "White list menu button", PANEL, "DButton")