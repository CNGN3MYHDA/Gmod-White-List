BWhiteList = BWhiteList or {}
local frame

surface.CreateFont("BWhiteList.Label", {
	font = "Arial",
	size = 17
})

local HEADER_HEIGHT = 25
local BTN_HEIGHT = HEADER_HEIGHT-2

local function requireConfig()
	net.Start("BWhiteList.Config")
		net.WriteBool(true)
	net.SendToServer()
end

local function setConfigVal(key, val)
	net.Start("BWhiteList.Config")
		net.WriteBool(false)
		net.WriteString(util.TableToJSON({[key]=val}))
	net.SendToServer()
end

local function requireList()
	net.Start("BWhiteList.Whitelist")
	net.SendToServer()
end

local function requireLogsPage(page)
	net.Start("BWhiteList.Logs")
		net.WriteBool(false)
		net.WriteUInt(page, 10)
	net.SendToServer()
end

local function requireLogsCount()
	net.Start("BWhiteList.Logs")
		net.WriteBool(false)
	net.SendToServer()
end

function BWhiteList.OpenMenu()
	local scrw, scrh = ScrW(), ScrH()
	if IsValid(frame) then frame:Remove() end

	// Основа
	frame = vgui.Create("BWL_Frame")
	frame:SetSize(scrw/1.2, scrh/1.2)
	frame:SetTitle("White List - v0.1 - ALPHA | By Bost")

	local toRemove = {}
	function frame:OnRemove()
		hook.Remove("BWhiteList.ConfigReceive", "MenuUpdate")
		hook.Remove("BWhiteList.WhitelistReceive", "MenuUpdate")
		hook.Remove("BWhiteList.LogsCountReceive", "MenuUpdate")
		hook.Remove("BWhiteList.LogsReceive", "MenuUpdate")
		for _, v in pairs(toRemove) do
			if IsValid(v) then v:Remove() end
		end
	end

	// Панель категории
	local categoryCanvas = frame:GetCanvas()

	// Кнопки изменения категории
	local categoriesBtns = frame:Add("DPanel")
	categoriesBtns:SetPaintBackground(false)
	categoriesBtns:SetTall(BTN_HEIGHT)
	categoriesBtns:SetY(2)
	function categoriesBtns:Rebuid(w, h)
		local btnW
		for _, v in pairs(self:GetChildren()) do
			btnW = (v:GetWide() > (btnW or 0)) and v:GetWide() or btnW
		end

		for _, v in pairs(self:GetChildren()) do
			v:SetSize(btnW, self:GetTall())
		end

		for k, v in pairs(self:GetChildren()) do
			k=k-1
			v:SetPos(k*(btnW+2))
		end

		self:SetWide(self:ChildCount()*(btnW+2)-2)
		self:SetX((frame:GetWide()-self:GetWide())/2)
	end

	local updateButton = frame:Add("BWL_Button")
	updateButton:SetText("⭯")
	updateButton:SetSize(BTN_HEIGHT, BTN_HEIGHT)
	updateButton:SetPos(frame:GetWide()-updateButton:GetWide()*2-4, 2)
	function updateButton:DoClick()
		for _, v in pairs(categoriesBtns:GetChildren()) do
			if v.Selected then
				categoryCanvas:Clear()
				v.BuildCategoty()
			end
		end
	end

	// Добавить кнопку категории
	local function addCategotyBtn(name, buildCategory, destroyCategory)
		local CBtn = categoriesBtns:Add("BWL_Button")
		CBtn:SetText(name)
		CBtn:SetWide(CBtn:GetTextSize()+10)
		CBtn.BuildCategoty = buildCategory
		CBtn.DestroyCategoty = destroyCategory

		function CBtn:DoClick()
			if self.Selected then return end
			self:SetTextColor(Color(100, 100, 200))
			for _, btn in pairs(categoriesBtns:GetChildren()) do
				if btn == self then continue end
				self:SetTextColor(Color(255, 255, 255))
				btn.Selected = false
				btn:DestroyCategoty()
			end
			categoryCanvas:Clear()
			self.Selected = true
			self:BuildCategoty()
		end

		categoriesBtns:Rebuid()
	end

	// Установить текст по центру
	local function categoryCenterText(text)
		local lbl = categoryCanvas:Add("BWL_Label")
		lbl:SetText(text)
		lbl:Center()
	end

	// Категории
	addCategotyBtn("White List", function()
		if !LocalPlayer():IsSuperAdmin() then
			categoryCenterText("No access!")
			timer.Simple(3, BWhiteList.CloseMenu)
			return
		else
			requireList()
			categoryCenterText("Please wait...")
		end

		hook.Add("BWhiteList.WhitelistReceive", "MenuUpdate", function(lst)
			categoryCanvas:Clear()

			local addBtn = categoryCanvas:Add("BWL_Button")
			addBtn:SetText("Add to white list")
			addBtn:SetSize(categoryCanvas:GetWide(), 30)
			addBtn:SetPos(0, categoryCanvas:GetTall()-addBtn:GetTall())
			function addBtn:DoClick()
				self:SetEnabled(false)
				BWhiteList.Quest("Enter SteamID", BWhiteList.IsSteamID, "Invalid SteamID!", function(sid)
					RunConsoleCommand("whitelist", "add", string.Trim(sid))
					updateButton:DoClick()
					if IsValid(self) then self:SetEnabled(true) end
				end, function() if IsValid(self) then self:SetEnabled(true) end end)
			end

			local tbl = categoryCanvas:Add("BWL_Table")
			tbl:SetSize(categoryCanvas:GetWide(), categoryCanvas:GetTall()-addBtn:GetTall()-5)
			tbl:AddColumn("Player")
			tbl:AddColumn("SteamID")
			tbl:AddColumn("Controls")

			local offlinePlayers = {}
			
			for sID, _ in pairs(lst) do
				local ply = player.GetBySteamID(sID)
				local name = IsValid(ply) and ply:Nick() or "Player offline"

				local lbl = vgui.Create( "BWL_Label", self )
				lbl:SetText(name)
				lbl.Value = name
				lbl:SetTextColor(IsValid(ply) and Color(20, 255, 20) or Color(255, 20, 20))

				local controls = vgui.Create("DPanel")
				controls:SetPaintBackground(false)

				local CopyNameBtn = controls:Add("BWL_Button")
				CopyNameBtn:SetText("Copy Name")
				CopyNameBtn:SetEnabled(IsValid(ply))
				function CopyNameBtn:DoClick()
					SetClipboardText(name)
				end

				local CopySIDBtn = controls:Add("BWL_Button")
				CopySIDBtn:SetText("Copy SteamID")
				function CopySIDBtn:DoClick()
					SetClipboardText(sID)
				end

				local RemoveBtn = controls:Add("BWL_Button")
				RemoveBtn:SetText("Remove")
				function RemoveBtn:DoClick()
					RunConsoleCommand("whitelist", "remove", sID)
					updateButton:DoClick()
				end

				function controls:PerformLayout(w, h)
					CopyNameBtn:SetSize(controls:GetWide()/2, controls:GetTall()/2)
					CopyNameBtn:SetPos(1, controls:GetTall()/2)

					CopySIDBtn:SetSize(controls:GetWide()/2, controls:GetTall()/2)
					CopySIDBtn:SetPos(controls:GetWide()/2+1, controls:GetTall()/2)

					RemoveBtn:SetSize(controls:GetWide(), controls:GetTall()/2)
					RemoveBtn:SetPos(0, 0)
				end

				local line = tbl:AddLine(lbl, sID, controls)
				line.PlayerSteamID64 = util.SteamIDTo64(sID)
				line.PlayerOnline = IsValid(ply)

				if !IsValid(ply) then table.insert(offlinePlayers, line.PlayerSteamID64) end
			end

			BWhiteList.GetPlayerNameBySteamID(offlinePlayers, function(names)
				if !IsValid(tbl) then return end
				for k, v in pairs(tbl:GetLines()) do
					if v.PlayerOnline then continue end
					v:SetColumnText(1, names[v.PlayerSteamID64])
				end
			end)
		end)
	end, function()
		hook.Remove("BWhiteList.ConfigReceive", "MenuUpdate")
		hook.Remove("BWhiteList.LogsCountReceive", "MenuUpdate")
		hook.Remove("BWhiteList.LogsReceive", "MenuUpdate")
	end)

	addCategotyBtn("Config", function()
		if !LocalPlayer():IsSuperAdmin() then
			categoryCenterText("No access!")
			timer.Simple(3, BWhiteList.CloseMenu)
			return
		else
			categoryCenterText("Not implemented")
			return
		end

		hook.Add("BWhiteList.ConfigReceive", "MenuUpdate", function()
			categoryCanvas:Clear()
		end)
	end, function()
		hook.Remove("BWhiteList.WhitelistReceive", "MenuUpdate")
		hook.Remove("BWhiteList.LogsCountReceive", "MenuUpdate")
		hook.Remove("BWhiteList.LogsReceive", "MenuUpdate")
	end)

	addCategotyBtn("Logs", function()
		if !LocalPlayer():IsSuperAdmin() then
			categoryCenterText("No access!")
			timer.Simple(3, BWhiteList.CloseMenu)
			return
		else
			categoryCenterText("Not implemented")
			return
		end

		hook.Add("BWhiteList.LogsReceive", "MenuUpdate", function()
			categoryCanvas:Clear()
		end)
	end, function()
		hook.Remove("BWhiteList.WhitelistReceive", "MenuUpdate")
		hook.Remove("BWhiteList.ConfigReceive", "MenuUpdate")
	end)

	local firstCategoty = categoriesBtns:GetChildren()[1]
	if IsValid(firstCategoty) then firstCategoty:DoClick() end
end

function BWhiteList.CloseMenu()
	if IsValid(frame) then frame:Remove() end
end

// Закрытие при изменении прав
hook.Add("CAMI.PlayerUsergroupChanged", "BWhiteList.CheckPermissions", function(ply, old, new, source)
	if ply != LocalPlayer() then return end

	if !ply:IsSuperAdmin() then BWhiteList.CloseMenu() end
end)

function BWhiteList.Quest(text, check, failMsg, successCallBack, cancelCallBack)
	local scrw, scrh = ScrW(), ScrH()

	local frame = vgui.Create("BWL_Frame")
	frame:SetSize(scrw/2, scrh/4)
	frame:SetTitle("White List - Question")
	frame:InvalidateLayout(true)

	local canvas = frame:GetCanvas()

	local entry = canvas:Add("DTextEntry")
	entry:SetSize(500, 30)
	entry:SetPos((canvas:GetWide()-entry:GetWide())/2, (canvas:GetTall()-entry:GetTall())/2)
	entry:SetFont("BWhiteList.Label")
	function entry:Paint(w, h)
		// Рамка
		surface.SetDrawColor(50, 50, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		// Основное окно
		surface.SetDrawColor(Color(255, 255, 255))
		surface.DrawRect(1, 1, w-2, h-2)

		self:DrawTextEntryText(Color(0, 0, 0), Color(80, 80, 200), Color(0, 0, 0))
	end

	local lbl = canvas:Add("BWL_Label")
	lbl:SetText(text)
	lbl:SetPos((canvas:GetWide()-lbl:GetWide())/2, (canvas:GetTall()/2-lbl:GetTall())/2)

	local confirm = canvas:Add("BWL_Button")
	confirm:SetText("Confirm")
	local lblW = confirm:GetTextSize()+10
	confirm:SetSize(lblW, BTN_HEIGHT)
	confirm:SetPos(canvas:GetWide()/2-confirm:GetWide()*2, canvas:GetTall()*0.75)
	function confirm:DoClick()
		local val = entry:GetText()
		if check and !check(val) then BWhiteList.Message(failMsg) return end
		if successCallBack then successCallBack(val) end
		self:GetParent():GetParent():Remove()
	end

	local cancel = canvas:Add("BWL_Button")
	cancel:SetText("Cancel")
	cancel:SetSize(lblW, BTN_HEIGHT)
	cancel:SetPos(canvas:GetWide()/2+cancel:GetWide(), canvas:GetTall()*0.75)
	function cancel:DoClick()
		if cancelCallBack then cancelCallBack() end
		self:GetParent():GetParent():Remove()
	end

	return frame
end

function BWhiteList.Message(text)
	local scrw, scrh = ScrW(), ScrH()

	local frame = vgui.Create("BWL_Frame")
	frame:SetSize(scrw/2, scrh/4)
	frame:SetTitle("White List - Message")
	frame:InvalidateLayout(true)

	local canvas = frame:GetCanvas()

	local lbl = canvas:Add("BWL_Label")
	lbl:SetText(text)
	lbl:SetPos((canvas:GetWide()-lbl:GetWide())/2, canvas:GetTall()/2-lbl:GetTall())

	//frame:SetSize(math.Clamp(lbl:GetWide(), scrw/2, scrw), scrh/3+(#string.Split(lbl:GetText(), "\n")-1)*lbl:GetTall())

	local confirm = canvas:Add("BWL_Button")
	confirm:SetText("OK")
	local lblW = confirm:GetTextSize()+10
	confirm:SetSize(lblW, BTN_HEIGHT)
	confirm:SetPos((canvas:GetWide()-confirm:GetWide())/2, canvas:GetTall()*0.75)
	function confirm:DoClick()
		frame:Remove()
	end
end