local PANEL = {}

local HEADER_HEIGHT = 25
local BTN_HEIGHT = HEADER_HEIGHT-2

function PANEL:Init()
	self:Center()
	self:MakePopup()

	self.headerLabel = self:Add("BWL_Label")
	self.headerLabel:SetText("White list")
	self.headerLabel:SetPos(10, HEADER_HEIGHT/2-self.headerLabel:GetTall()/2+1)

	self.closeBtn = self:Add("BWL_Button")
	self.closeBtn:SetText("×")
	self.closeBtn:SetSize(BTN_HEIGHT, BTN_HEIGHT)
	self.closeBtn:SetPos(self:GetWide()-self.closeBtn:GetWide()-2, 2)
	function self.closeBtn:DoClick()
		self:GetParent():Remove()
	end

	self.Canvas = self:Add("DPanel")
	self.Canvas:SetSize(self:GetWide()-12, self:GetTall()-HEADER_HEIGHT-12)
	self.Canvas:SetPos(6, HEADER_HEIGHT+6)
	self.Canvas:SetPaintBackground(false)
	self.Canvas.Paint = nil
end

function PANEL:SetTitle(title)
	self.headerLabel:SetText(title)
end

function PANEL:Paint(w, h)
	// Рамка
	surface.SetDrawColor(50, 50, 50)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	// Шапка
	surface.SetDrawColor(25, 25, 25)
	surface.DrawRect(1, 1, w-2, HEADER_HEIGHT)

	// Основное окно
	surface.SetDrawColor(Color(35, 35, 35))
	surface.DrawRect(1, 1+HEADER_HEIGHT, w-2, h-2-HEADER_HEIGHT)
end

function PANEL:GetCanvas()
	return self.Canvas
end

function PANEL:PerformLayout(w, h)
	self:Center()

	self.closeBtn:SetPos(w-self.closeBtn:GetWide()-2, 2)

	self.Canvas:SetSize(w-12, h-HEADER_HEIGHT-12)
	self.Canvas:SetPos(6, HEADER_HEIGHT+6)

	self.headerLabel:SetPos(10, HEADER_HEIGHT/2-self.headerLabel:GetTall()/2+1)
end

derma.DefineControl("BWL_Frame", "White list frame", PANEL, "EditablePanel")