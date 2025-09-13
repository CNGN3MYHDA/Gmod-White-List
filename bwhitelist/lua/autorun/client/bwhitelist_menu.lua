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

local function setConfig(cfg)
	net.Start("BWhiteList.Config")
		net.WriteBool(false)
		net.WriteString(util.TableToJSON(cfg))
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
		net.WriteBool(true)
	net.SendToServer()
end

function BWhiteList.OpenMenu()
	local scrw, scrh = ScrW(), ScrH()
	if IsValid(frame) then frame:Remove() timer.Simple(0.1, BWhiteList.OpenMenu) return end

	// Основа
	frame = vgui.Create("BWL_Frame")
	frame:SetSize(scrw/1.2, scrh/1.2)
	frame:SetTitle("White List - v1.2.1 | By Bost")
	frame:InvalidateLayout(true)

	local toRemove = {}

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

	function frame:OnRemove()
		for _, btn in pairs(categoriesBtns:GetChildren()) do
			btn:DestroyCategoty()
		end

		for _, v in pairs(toRemove) do
			if IsValid(v) then v:Remove() end
		end
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
			categoryCenterText("Receiving...")
			requireList()
		end

		hook.Add("BWhiteList.WhitelistReceive", "MenuUpdate", function(lst)
			categoryCanvas:Clear()

			local addBtn = categoryCanvas:Add("BWL_Button")
			addBtn:SetText("Add to white list")
			addBtn:SetSize(categoryCanvas:GetWide(), 30)
			addBtn:SetPos(0, categoryCanvas:GetTall()-addBtn:GetTall())
			function addBtn:DoClick()
				frame:SetMouseInputEnabled(false)
				BWhiteList.Quest("Enter SteamID", function(sID) return BWhiteList.IsSteamID(string.Trim(sID)) end, "Invalid SteamID!", function(sid)
					if IsValid(frame) then frame:SetMouseInputEnabled(true) end
					categoryCanvas:Clear()
					categoryCenterText("Executing...")
					hook.Add("BWhiteList.Callback", "MenuUpdate", function()
						hook.Remove("BWhiteList.Callback", "MenuUpdate")
						if IsValid(frame) then
							updateButton:DoClick()
						end
					end)
					RunConsoleCommand("whitelist", "add", string.Trim(sid))
				end, function() if IsValid(frame) then frame:SetMouseInputEnabled(true) end end)
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

				local lbl = vgui.Create("BWL_Label")
				lbl:SetText(name)
				lbl:SetContentAlignment(5)
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
					categoryCanvas:Clear()
					categoryCenterText("Executing...")
					hook.Add("BWhiteList.Callback", "MenuUpdate", function()
						hook.Remove("BWhiteList.Callback", "MenuUpdate")
						if IsValid(frame) then
							updateButton:DoClick()
						end
					end)
					RunConsoleCommand("whitelist", "remove", sID)
				end

				function controls:PerformLayout(w, h)
					CopyNameBtn:SetSize(controls:GetWide()/2, controls:GetTall()/2)
					CopyNameBtn:SetPos(1, controls:GetTall()/2)

					CopySIDBtn:SetSize(controls:GetWide()/2, controls:GetTall()/2)
					CopySIDBtn:SetPos(controls:GetWide()/2+1, controls:GetTall()/2)

					RemoveBtn:SetSize(controls:GetWide()-1, controls:GetTall()/2)
					RemoveBtn:SetPos(1, 0)
				end

				local line = tbl:AddLine(lbl, sID, controls)
				line.PlayerSteamID64 = util.SteamIDTo64(sID) or ""
				line.PlayerOnline = IsValid(ply)

				if !IsValid(ply) then offlinePlayers[line] = line.PlayerSteamID64 end
			end

			for line, sid64 in pairs(offlinePlayers) do
				if sid64 == "" then line:SetColumnText("Unknown") continue end
				steamworks.RequestPlayerInfo(sid64, function(name)
					if !IsValid(tbl) then return end
					line:SetColumnText(1, name)
				end)
			end
		end)
	end, function()
		hook.Remove("BWhiteList.ConfigReceive", "WhitelistReceive")
		hook.Remove("BWhiteList.Callback", "MenuUpdate")
	end)

	addCategotyBtn("Config", function()
		if !LocalPlayer():IsSuperAdmin() then
			categoryCenterText("No access!")
			timer.Simple(3, BWhiteList.CloseMenu)
			return
		else
			categoryCenterText("Receiving...")
			requireConfig()
		end

		hook.Add("BWhiteList.ConfigReceive", "MenuUpdate", function(cfg)
			categoryCanvas:Clear()
			if table.IsEmpty(cfg) then categoryCenterText("Error! Please restart the server") return end
			local oldCfg = table.Copy(cfg)

			local canvas = categoryCanvas:Add("BWL_Scroll")
			canvas:SetSize(categoryCanvas:GetWide(), categoryCanvas:GetTall() - 35)

			local saveBtn = categoryCanvas:Add("BWL_Button")
			saveBtn:SetText("Save")
			saveBtn:SetEnabled(false)
			saveBtn:SetSize(categoryCanvas:GetWide(), 30)
			saveBtn:SetPos(0, categoryCanvas:GetTall()-30)
			function saveBtn:DoClick()
				categoryCanvas:Clear()
				categoryCenterText("Executing...")
				hook.Add("BWhiteList.Callback", "MenuUpdate", function()
					hook.Remove("BWhiteList.Callback", "MenuUpdate")
					if IsValid(frame) then
						updateButton:DoClick()
					end
				end)
				setConfig(cfg)
			end

			local function detectChanges()
				for k, v in pairs(cfg) do
					if oldCfg[k] != v then saveBtn:SetEnabled(true) return end
				end
				saveBtn:SetEnabled(false)
			end

			// General
			local generalCategory = canvas:Add("BWL_CollapsibleCategory")
			generalCategory:SetSize(canvas:GetWide(), 30)
			generalCategory:SetText("General")

			local enableBtn = generalCategory:AddItem("BWL_CheckBox")
			enableBtn:SetText("Enable")
			enableBtn:SetChecked(cfg.enable)
			function enableBtn:OnChanged()
				cfg.enable = self:GetChecked()
				detectChanges()
			end

			local kickReason = generalCategory:AddItem("EditablePanel")
			generalCategory:InvalidateLayout(true)
			local kickReasonLbl = kickReason:Add("BWL_Label")
			kickReasonLbl:SetText("Kick reason: ")
			kickReasonLbl:SetY((kickReason:GetTall()-kickReasonLbl:GetTall())/2)

			local kickReasonEntry = kickReason:Add("BWL_TextEntry")
			kickReasonEntry:SetValue(cfg.reason or "")
			kickReasonEntry:SetSize(kickReason:GetWide()-kickReasonLbl:GetWide()-5, kickReason:GetTall())
			kickReasonEntry:SetPos(kickReasonLbl:GetWide() + 5, 0)
			function kickReasonEntry:OnChange()
				cfg.reason = self:GetValue()
				detectChanges()
			end

			local forceKickBtn = generalCategory:AddItem("BWL_CheckBox")
			forceKickBtn:SetText("Kick a player after being removed from the whitelist")
			forceKickBtn:SetChecked(cfg.forceKick)
			function forceKickBtn:OnChanged()
				cfg.forceKick = self:GetChecked()
				detectChanges()
			end

			// Logs
			local logsCategory = canvas:Add("BWL_CollapsibleCategory")
			logsCategory:SetSize(canvas:GetWide(), 30)
			logsCategory:SetText("Logs")

			function logsCategory:Think()
				self:SetPos(0, generalCategory:GetTall()+5)
			end

			local writeConnectedBtn = logsCategory:AddItem("BWL_CheckBox")
			writeConnectedBtn:SetText("Log connections of whitelisted players")
			writeConnectedBtn:SetChecked(cfg.writeConnectedLogs)
			function writeConnectedBtn:OnChanged()
				cfg.writeConnectedLogs = self:GetChecked()
				detectChanges()
			end

			local writeNotConnectedBtn = logsCategory:AddItem("BWL_CheckBox")
			writeNotConnectedBtn:SetText("Log canceled connections of players not whitelisted")
			writeNotConnectedBtn:SetChecked(cfg.writeNotConnectedLogs)
			function writeNotConnectedBtn:OnChanged()
				cfg.writeNotConnectedLogs = self:GetChecked()
				detectChanges()
			end

			local oneLogOnSessionBtn = logsCategory:AddItem("BWL_CheckBox")
			oneLogOnSessionBtn:SetText("Delete the log after each server start")
			oneLogOnSessionBtn:SetChecked(cfg.oneLogOnSession)
			function oneLogOnSessionBtn:OnChanged()
				cfg.oneLogOnSession = self:GetChecked()
				detectChanges()
			end
		end)
	end, function()
		hook.Remove("BWhiteList.ConfigReceive", "MenuUpdate")
		hook.Remove("BWhiteList.Callback", "MenuUpdate")
	end)

	addCategotyBtn("Logs", function()
		if !LocalPlayer():IsSuperAdmin() then
			categoryCenterText("No access!")
			timer.Simple(3, BWhiteList.CloseMenu)
			return
		else
			categoryCenterText("Receiving...")
			requireLogsCount()
		end

		hook.Add("BWhiteList.LogsCountReceive", "MenuUpdate", function(pagesCount)
			if pagesCount < 1 then categoryCanvas:Clear() categoryCenterText("No logs") return end

			requireLogsPage(1)
			local page = 1

			hook.Add("BWhiteList.LogsReceive", "MenuUpdate", function(logs)
				categoryCanvas:Clear()

				local nextPageBtn = categoryCanvas:Add("BWL_Button")
				nextPageBtn:SetText(">")
				nextPageBtn:SetSize(30, 30)
				nextPageBtn:SetPos(categoryCanvas:GetWide()-30, categoryCanvas:GetTall()-30)
				function nextPageBtn:DoClick()
					local nextPage = page + 1
					if nextPage > pagesCount then return end
					requireLogsPage(nextPage)
					page = page + 1
				end

				local pageLbl = categoryCanvas:Add("BWL_Label")
				pageLbl:SetText(tostring(page).."/"..pagesCount)
				pageLbl:SetSize(math.max(pageLbl:GetWide()+10, nextPageBtn:GetWide()), nextPageBtn:GetTall())
				pageLbl:SetContentAlignment(5)
				pageLbl:SetPos(nextPageBtn:GetX()-pageLbl:GetWide()-2, categoryCanvas:GetTall()-15-pageLbl:GetTall()/2)
				function pageLbl:Paint(w, h)
					// Рамка
					surface.SetDrawColor(50, 50, 50)
					surface.DrawOutlinedRect(0, 0, w, h, 1)

					// Основное окно
					surface.SetDrawColor(clr or Color(35, 35, 35))
					surface.DrawRect(1, 1, w-2, h-2)
				end

				local prevPageBtn = categoryCanvas:Add("BWL_Button")
				prevPageBtn:SetText("<")
				prevPageBtn:SetSize(30, 30)
				prevPageBtn:SetPos(pageLbl:GetX()-prevPageBtn:GetWide()-2, categoryCanvas:GetTall()-30)
				function prevPageBtn:DoClick()
					local prevPage = page - 1
					if prevPage < 1 then return end
					requireLogsPage(prevPage)
					page = page - 1
				end

				-- local searchEntry = categoryCanvas:Add("BWL_TextEntry")
				-- searchEntry:SetSize(prevPageBtn:GetX() - 5, 30)
				-- searchEntry:SetPos(0, categoryCanvas:GetTall()-searchEntry:GetTall())

				-- local searchBtn = categoryCanvas:Add("BWL_Button")
				-- searchBtn:SetText("<")
				-- searchBtn:SetSize(30, 30)
				-- searchBtn:SetPos(0, categoryCanvas:GetTall()-30)
				-- function searchBtn:DoClick()
					
				-- end

				local tbl = categoryCanvas:Add("BWL_Table")
				tbl:SetSize(categoryCanvas:GetWide(), categoryCanvas:GetTall()-nextPageBtn:GetTall()-5)
				tbl:AddColumn("Time")
				tbl:AddColumn("Log")

				local max = 0
				local infoOpened = false

				for _, log in pairs(logs) do
					local curTime = os.date("*t")
					local time = tonumber(log.time)
					if time then
						time = os.date("*t", time)
						if time.year < curTime.year then
							local diff = curTime.year-time.year
							if diff == 1 then
								time = "Last year"
							else
								time = diff.." years"
							end
						elseif time.month < curTime.month then
							local diff = curTime.month-time.month
							if diff == 1 then
								time = "Last month"
							else
								time = diff.." months"
							end
						elseif time.yday < curTime.yday then
							local diff = curTime.yday-time.yday
							if diff == 1 then
								time = "Yesterday"
							else
								time = diff.." days"
							end
						else
							time.hour = (time.hour < 10) and "0"..time.hour or time.hour
							time.min = (time.min < 10) and "0"..time.min or time.min
							time = time.hour..":"..time.min
						end
					else
						time = "???"
					end

					local name = log.name
					local steamID = log.SteamID
					local address = log.address
					local fStr = log.str

					local line = tbl:AddLine(time, string.format(fStr, name, steamID))
					local column2 = line.Columns[2].pnl
					column2:SetMouseInputEnabled(true)
					column2:SetTextColor((tonumber(log.passed) == 1) and Color(20, 255, 20) or Color(255, 20, 20))
					column2:SetKeyboardInputEnabled(true)
					column2:SetCursor("hand")
					column2.DoClick = function()
						if infoOpened then return end
						infoOpened = true
						frame:SetMouseInputEnabled(false)
						local logMsg = vgui.Create("BWL_Frame")
						logMsg:SetSize(scrw/2, scrh/3)
						logMsg:Center()
						logMsg:InvalidateLayout(true)
						function logMsg:OnRemove()
							infoOpened = false
							frame:SetMouseInputEnabled(true)
						end
						local canvas = logMsg:GetCanvas()

						local msgScroll = canvas:Add("BWL_Scroll")
						msgScroll:SetSize(canvas:GetSize())

						local vals = {}
						local function addVal(name, val)
							val = tostring(val)

							local pnl = msgScroll:Add("DPanel")
							pnl:SetPaintBackground(false)
							pnl:SetSize(msgScroll:GetWide(), 30)
							pnl:SetPos(0, table.Count(vals)*(30+2))

							local lbl = pnl:Add("BWL_Label")
							lbl:SetText(name..": "..val)
							lbl:SetPos(5, 15-lbl:GetTall()/2)

							local copyBtn = pnl:Add("BWL_Button")
							copyBtn:SetText("Copy")
							copyBtn:SetSize(60, 25)
							copyBtn:SetPos(lbl:GetX()+lbl:GetWide()+10, 2.5)
							function copyBtn:DoClick()
								SetClipboardText(val)
							end
							table.insert(vals, pnl)
						end

						addVal("Name", name)
						addVal("SteamID", steamID)
						addVal("Address", address)
						addVal("Time", tostring(log.time) and os.date("%H:%M:%S - %d.%m.%Y", tostring(log.time)) or "???")
					end

					local pnl = line.Columns[1].pnl
					local lblW = pnl.GetTextSize and pnl:GetTextSize() or pnl:GetWide()
					max = (max < lblW) and lblW or max
				end

				tbl:SetColumnWidth(1, max+20)
			end)
		end)
	end, function()
		hook.Remove("BWhiteList.LogsReceive", "MenuUpdate")
		hook.Remove("BWhiteList.LogsCountReceive", "MenuUpdate")
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
	function frame:OnRemove()
		if cancelCallBack then cancelCallBack() end
	end

	local canvas = frame:GetCanvas()

	local entry = canvas:Add("BWL_TextEntry")
	entry:SetSize(500, 30)
	entry:SetPos((canvas:GetWide()-entry:GetWide())/2, (canvas:GetTall()-entry:GetTall())/2)

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