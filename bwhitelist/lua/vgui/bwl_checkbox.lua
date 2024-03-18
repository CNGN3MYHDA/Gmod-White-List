local PANEL = {}

AccessorFunc(PANEL, "checked", "Checked", FORCE_BOOL)

function PANEL:Init()
	self:SetPaintBackground(false)

	self.Btn = self:Add("DButton")
	local btn = self.Btn
	btn:SetText("")
	function btn:Paint(w, h)
		// Рамка
		surface.SetDrawColor(50, 50, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		// Основное окно
		surface.SetDrawColor(clr or Color(35, 35, 35))
		surface.DrawRect(1, 1, w-2, h-2)

		if self:GetParent():GetChecked() then
			local p = self.m_bSelected and 1 or 0
			surface.SetDrawColor(255, 255, 255)
			surface.DrawRect(3+p, 3+p, w-6-p, h-6-p)
		end
	end

	function btn:DoClick()
		local parent = self:GetParent()
		parent:SetChecked(!parent:GetChecked())
		parent:OnChanged(parent:GetChecked())
	end

	self.Text = self:Add("BWL_Label")
	self.Text:SetText("")
end

function PANEL:PerformLayout(w, h)
	local btn = self.Btn
	btn:SetSize(self:GetTall(), self:GetTall())
	btn:SetPos(0, 0)

	local lbl = self.Text
	lbl:SetPos(btn:GetWide() + 10, (self:GetTall()-lbl:GetTall())/2)
end

function PANEL:SetText(text)
	self.Text:SetText(text)
end

function PANEL:GetText()
	return self.Text:GetText()
end

function PANEL:OnChanged()

end

derma.DefineControl("BWL_CheckBox", "White list menu checkbox", PANEL, "DPanel")