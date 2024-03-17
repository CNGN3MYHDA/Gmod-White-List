local PANEL = {}

function PANEL:Init()
	self.Columns = {}
end

function PANEL:Paint(w, h)
	// Рамка
	surface.SetDrawColor(50, 50, 50)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	// Основное окно
	surface.SetDrawColor(clr or Color(35, 35, 35))
	surface.DrawRect(1, 1, w-2, h-2)  -- 3 вмсето 2 для объёма

	local part = w / table.Count(self.Columns)

	for i=1, table.Count(self.Columns)-1 do
		draw.RoundedBox(0, i*part, 0, 1, h, Color(50, 50, 50))
	end
end

function PANEL:SetColumnText(k, text)
	if ispanel(text) then
		self.Columns[k] = text
		text:SetParent(self)
		self:InvalidateLayout()
	else
		local pnl
		if !IsValid(self.Columns[k]) then
			self.Columns[k] = vgui.Create( "BWL_Label", self )
			self.Columns[k]:SetMouseInputEnabled(false)
		end
		pnl = self.Columns[k]
		pnl:SetText(tostring(text))
		pnl.Value = text

		return pnl
	end
end

function PANEL:GetColumnText(k)
	return self.Columns[k] and self.Columns[k].Value
end

function PANEL:PerformLayout(w, h)
	local part = w / table.Count(self.Columns)

	for k, v in pairs(self.Columns) do
		if !IsValid(v) then continue end
		
		if v.Value then
			local lblW, lblH = v:GetTextSize()
			local textW = (lblW+10 > part) and part-10 or lblW
			v:SetSize(textW, lblH)
			v:SetPos((k*part)-(part+textW)/2, (h-lblH)/2)
		else
			k = (k == table.Count(self.Columns)) and k-1 or k
			v:SetSize(part, h-2)
			v:SetPos(k*part, 1)
		end
	end
end

derma.DefineControl("BWL_TableLine", "White list menu table line", PANEL, "DPanel")