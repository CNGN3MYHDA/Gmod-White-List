local PANEL = {}

function PANEL:Init()
	self.Lines = {}
	self.Columns = {}

	self:SetPaintBackground(false)

	self.Header = self:Add("BWL_TableLine")
	self.CanVas = self:Add("BWL_Scroll")

	self:InvalidateLayout()
end

function PANEL:AddColumn(name, pos)
	if pos then
		table.insert(self.Columns, pos, name)
	else
		table.insert(self.Columns, name)
	end

	self:Rebuild()
end

function PANEL:SetColumnWidth(k, width)
	self.Header:SetAutoColumnWidth(false)
	self.Header:SetColumnWidth(k, width)
	for _, line in pairs(self.Lines) do
		line:SetAutoColumnWidth(false)
		line:SetColumnWidth(k, width)
	end
end

function PANEL:AddLine(...)
	local args = {...}

	local line = self.CanVas:Add("BWL_TableLine")
	line:SetSize(self:GetWide(), 50)
	line:SetPos(0, table.Count(self.Lines)*(50+5))

	for k, v in pairs(self.Columns) do
		line:SetColumnText(k, args[k])
	end

	line:InvalidateLayout(true)

	table.insert(self.Lines, line)

	return line
end

function PANEL:GetLines()
	return table.Copy(self.Lines)
end

function PANEL:Clear()
	for k, v in pairs(self.Lines) do
		if !IsValid(v) then continue end
		v:Remove()
	end
	table.Empty(self.Lines)
end

function PANEL:PerformLayout(w, h)
	local header = self.Header
	header:SetSize(w, 30)

	local canVas = self.CanVas
	canVas:SetSize(w, h-30-5)
	canVas:SetPos(0, 30+5)
end

function PANEL:Rebuild()
	local header = self.Header
	for k, v in pairs(self.Columns) do
		header:SetColumnText(k, v)
	end

	local lines = {}
	for k, v in pairs(self.Lines) do
		if !IsValid(v) then continue end
		local data = {}
		for i=1, #v.Columns do
			table.insert(data, v:GetColumnValue(i))
		end
		v:Remove()
		table.insert(lines, data)
	end
	self.CanVas:Clear()
	table.Empty(self.Lines)
	
	for _, v in pairs(lines) do
		while #v < #self.Columns do
			table.insert(v, "")
		end
		self:AddLine(unpack(v))
	end
end

derma.DefineControl("BWL_Table", "White list menu table", PANEL, "DPanel")