local function rotatePoint(point, center, angle)
    local s = math.sin(math.rad(angle))
    local c = math.cos(math.rad(angle))

    -- Переносим точку в начало координат
    local translatedPoint = {
        x = point.x - center.x,
        y = point.y - center.y
    }

    -- Поворачиваем точку
    local xNew = translatedPoint.x * c - translatedPoint.y * s
    local yNew = translatedPoint.x * s + translatedPoint.y * c

    -- Переносим обратно к исходной точке
    local rotatedPoint = {
        x = xNew + center.x,
        y = yNew + center.y
    }

    return rotatedPoint
end

local PANEL = {}

AccessorFunc(PANEL, "expanded", "Expanded", FORCE_BOOL)
AccessorFunc(PANEL, "headerTall", "HeaderTall", FORCE_NUMBER)

function PANEL:Init()
	self:SetPaintBackground(false)

	self:SetTall(30)
	self:SetHeaderTall(30)

	self.Btn = self:Add("BWL_Button")
	self.Btn:SetText("")
	function self.Btn:DoClick()
		self:GetParent():Toggle()
	end
	local oldPaint = self.Btn.Paint
	self.Btn.rotate = 0
	function self.Btn:Paint(w, h)
		oldPaint(self, w, h)

		w = self:GetParent():GetHeaderTall()/2
		h = w
		local center = {x = w/2+10, y = h/2+10}
		w = w - 1
		h = h - 3
		local triangle = {
			{x = 11, y = 13},
			{x = w+10, y = 13},
			{x = w/2+10, y = h+10}
		}

		surface.SetDrawColor(255, 255, 255)
		draw.NoTexture()
		surface.DrawPoly({
			rotatePoint(triangle[1], center, self.rotate),
			rotatePoint(triangle[2], center, self.rotate),
			rotatePoint(triangle[3], center, self.rotate),
		})
	end

	self.Text = self:Add("BWL_Label")

	self.Canvas = self:Add("DPanel")
	function self.Canvas:Paint(w, h)
		// Рамка
		surface.SetDrawColor(50, 50, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		// Основное окно
		surface.SetDrawColor(Color(35, 35, 35))
		surface.DrawRect(1, 1, w-2, h-2)
	end
end

function PANEL:SetExpanded(expanded, noAnim)
	if self.expanded == expanded then return end
	self.expanded = expanded

	local tall = self:GetInnerTall()
	local headerTall = self:GetHeaderTall() - 1

	if expanded then
		local expand = self:NewAnimation(0.2, 0, 1)

		expand.Think = function(anim, pnl, fraction)
			pnl:SetTall(Lerp(fraction, headerTall, headerTall+tall))
		end

		local rotate = self.Btn:NewAnimation(0.2, 0, 1)

		rotate.Think = function(anim, pnl, fraction)
			pnl.rotate = Lerp(fraction, 0, 180)
		end
	else
		local contract = self:NewAnimation(0.2, 0, 1)

		contract.Think = function(anim, pnl, fraction)
			pnl:SetTall(Lerp(fraction, headerTall+tall, headerTall))
		end

		local rotate = self.Btn:NewAnimation(0.2, 0, 1)

		rotate.Think = function(anim, pnl, fraction)
			pnl.rotate = Lerp(fraction, 180, 0)
		end
	end
end

function PANEL:Toggle(noAnim)
	self:SetExpanded(!self:GetExpanded(), noAnim)
end

function PANEL:GetCanvas()
	return self.Canvas
end

function PANEL:GetInnerTall()
	local h = 5
	for k, v in pairs(self.Canvas:GetChildren()) do
		h = h + v:GetTall() + 5
	end
	return h
end

function PANEL:AddItem(pnl)
	if isstring(pnl) then
		pnl = vgui.Create(pnl, self:GetCanvas())
	else
		pnl:SetParent(self:GetCanvas())
	end

	self:GetCanvas():SetTall(self:GetInnerTall())

	return pnl
end

function PANEL:SetText(text)
	self.Text:SetText(text)
end

function PANEL:GetText()
	return self.Text:GetText()
end

function PANEL:PerformLayout(w, h)
	local btn = self.Btn
	btn:SetPos(0, 0)
	btn:SetSize(w, self:GetHeaderTall())

	local lbl = self.Text
	lbl:SetPos(self:GetHeaderTall()/2+20, (self:GetHeaderTall()-lbl:GetTall())/2)

	local canvas = self.Canvas
	canvas:SetWide(w)
	canvas:SetPos(0, self:GetHeaderTall()-2)

	local y = 5
	for _, v in pairs(canvas:GetChildren()) do
		v:SetWide(canvas:GetWide()-10)
		v:SetPos(5, y)
		y = y + v:GetTall() + 5
	end
end

derma.DefineControl("BWL_CollapsibleCategory", "White list menu collapsible category", PANEL, "DPanel")