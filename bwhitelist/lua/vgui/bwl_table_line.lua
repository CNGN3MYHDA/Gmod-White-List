local PANEL = {}

AccessorFunc(PANEL, "autoColumnWidth", "AutoColumnWidth", FORCE_BOOL)

function PANEL:Init()
	self:SetPaintBackground(false)
	self.Columns = {}
	self:SetAutoColumnWidth(true)
end

function PANEL:Paint(w, h)
	// Рамка
	surface.SetDrawColor(50, 50, 50)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	// Основное окно
	surface.SetDrawColor(clr or Color(35, 35, 35))
	surface.DrawRect(1, 1, w-2, h-2)

	local x = 0

	for i=1, table.Count(self.Columns)-1 do
		local part
		if self:GetAutoColumnWidth() then
			part = w / table.Count(self.Columns)
		else
			part = self.Columns[i].width
		end
		draw.RoundedBox(0, x+part, 0, 1, h, Color(50, 50, 50))
		x = x + part
	end
end

function PANEL:SetColumnText(k, text, width)
	width = width or -1
	if ispanel(text) then
		self.Columns[k] = {width=width, pnl=text}
		text:SetParent(self)
		text.Value = text.Value or ""
		self:InvalidateLayout(true)

		return text
	else
		if !self.Columns[k] or !IsValid(self.Columns[k].pnl) then
			self.Columns[k] = {width=width, pnl=vgui.Create("BWL_Label", self)}
		end
		pnl = self.Columns[k].pnl
		pnl:SetText(tostring(text))
		pnl.Value = text
		self:InvalidateLayout(true)

		return pnl
	end
end

function PANEL:GetColumnText(k)
	return self.Columns[k].pnl and self.Columns[k].pnl.Value
end

function PANEL:SetColumnWidth(k, width)
	self.Columns[k].width = width
end

function PANEL:GetColumnWidth(k)
	return self.Columns[k].width
end

function PANEL:GetColumnValue(k)
	return self.Columns[k].pnl.Value
end

function PANEL:PerformLayout(w, h)
	local x = 0
	for k, v in pairs(self.Columns) do
		if !IsValid(v.pnl) then continue end

		local part

		if k == table.Count(self.Columns) then
			part = w - x
		elseif self:GetAutoColumnWidth() then
			part = w / table.Count(self.Columns)
		else
			part = v.width
		end
		
		v.pnl:SetSize(part, h-2)
		v.pnl:SetPos(x, 1)
		v.pnl:SetContentAlignment(5)

		x = x + part
	end
end

derma.DefineControl("BWL_TableLine", "White list menu table line", PANEL, "DPanel")