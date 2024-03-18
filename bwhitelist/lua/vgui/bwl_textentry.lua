local PANEL = {}

function PANEL:Init()
	self:SetFont("BWhiteList.Label")
end

function PANEL:Paint(w, h)
	// Рамка
	surface.SetDrawColor(50, 50, 50)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	// Основное окно
	surface.SetDrawColor(Color(255, 255, 255))
	surface.DrawRect(1, 1, w-2, h-2)

	self:DrawTextEntryText(Color(0, 0, 0), Color(80, 80, 200), Color(0, 0, 0))
end

derma.DefineControl("BWL_TextEntry", "White list menu text entry", PANEL, "DTextEntry")