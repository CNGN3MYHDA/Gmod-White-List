BWhiteList.CALLBACK_LIST = 0
BWhiteList.CALLBACK_CFG = 1

// Сеть
if SERVER then
	util.AddNetworkString("BWhiteList.Msg")
	util.AddNetworkString("BWhiteList.OpenMenu")
	util.AddNetworkString("BWhiteList.Config")
	util.AddNetworkString("BWhiteList.Whitelist")
	util.AddNetworkString("BWhiteList.Logs")
	util.AddNetworkString("BWhiteList.List")
	util.AddNetworkString("BWhiteList.Callback")

	local function callback(ply, type)
		net.Start("BWhiteList.Callback")
			net.WriteUInt(type, 2)
		net.Send(ply)
	end

	BWhiteList.ListChangeCallback = function(ply)
		callback(ply, BWhiteList.CALLBACK_LIST)
	end

	net.Receive("BWhiteList.Config", function(len, ply)
		if !IsValid(ply) or !ply:IsSuperAdmin() then return end

		local isGet = net.ReadBool()
		if isGet then
			net.Start("BWhiteList.Config")
				net.WriteData(util.Compress(util.TableToJSON(BWhiteList.GetConfig())))
			net.Send(ply)
		else
			local data = net.ReadString()
			data = util.JSONToTable(data or "")
			for k, v in pairs(data or {}) do
				BWhiteList.SetConfigValue(k, v)
			end

			callback(ply, BWhiteList.CALLBACK_CFG)
		end
	end)

	net.Receive("BWhiteList.Whitelist", function(len, ply)
		if !IsValid(ply) or !ply:IsSuperAdmin() then return end

		net.Start("BWhiteList.Whitelist")
			net.WriteData(util.Compress(util.TableToJSON(BWhiteList.GetList())))
		net.Send(ply)
	end)

	net.Receive("BWhiteList.Logs", function(len, ply)
		if !IsValid(ply) or !ply:IsSuperAdmin() then return end

		local getPagesCount = net.ReadBool()
		if getPagesCount then
			net.Start("BWhiteList.Logs")
				net.WriteBool(true)
				net.WriteUInt(BWhiteList.GetLogsPagesCount(), 10)
			net.Send(ply)
		else
			local page = net.ReadUInt(10)
			net.Start("BWhiteList.Logs")
				net.WriteBool(false)
				net.WriteData(util.Compress(util.TableToJSON(BWhiteList.GetLogsPage(page))))
			net.Send(ply)
		end
	end)

	net.Receive("BWhiteList.List", function(len, ply)
		if !IsValid(ply) or !ply:IsSuperAdmin() then return end

		local isAdd = net.ReadBool()
		local steamID = net.ReadString()
		if !BWhiteList.IsSteamID(steamID) then return end

		if isAdd then
			if BWhiteList.GetList()[steamID] then
				BWhiteList.callBackMsg(ply, Color(255, 20, 20), "SteamID '"..steamID.."' already in white list!")
			else
				BWhiteList.Add(steamID)
				BWhiteList.callBackMsg(ply, "Added '"..steamID.."' to white list!")
			end
		else
			if BWhiteList.GetList()[steamID] then
				BWhiteList.Remove(steamID)
				BWhiteList.callBackMsg(ply, "Removed '"..steamID.."' from white list!")
			else
				BWhiteList.callBackMsg(ply, Color(255, 20, 20), "SteamID '"..steamID.."' not in white list!")
			end
		end

		BWhiteList.ListChangeCallback(ply)
	end)
else
	net.Receive("BWhiteList.Msg", function()
		local msg = net.ReadTable()
		MsgC(unpack(msg))
	end)

	net.Receive("BWhiteList.OpenMenu", function()
		BWhiteList.OpenMenu()
	end)

	net.Receive("BWhiteList.Config", function(len)
		if !IsValid(LocalPlayer()) or !LocalPlayer():IsSuperAdmin() then return end

		local data = net.ReadData(len)
		data = util.Decompress(data)
		data = util.JSONToTable(data or "")
		hook.Run("BWhiteList.ConfigReceive", table.Copy(data or {}))
	end)

	net.Receive("BWhiteList.Whitelist", function(len)
		if !IsValid(LocalPlayer()) or !LocalPlayer():IsSuperAdmin() then return end

		local data = net.ReadData(len)
		data = util.Decompress(data)
		data = util.JSONToTable(data or "")
		hook.Run("BWhiteList.WhitelistReceive", table.Copy(data or {}))
	end)

	net.Receive("BWhiteList.Logs", function(len)
		if !IsValid(LocalPlayer()) or !LocalPlayer():IsSuperAdmin() then return end

		local pagesCount = net.ReadBool()

		if pagesCount then
			local count = net.ReadUInt(10)
			hook.Run("BWhiteList.LogsCountReceive", count)
		else
			local data = net.ReadData(len)
			data = util.Decompress(data)
			data = util.JSONToTable(data or "")
			hook.Run("BWhiteList.LogsReceive", table.Copy(data or {}))
		end
	end)

	net.Receive("BWhiteList.Callback", function()
		hook.Run("BWhiteList.Callback", net.ReadUInt(2))
	end)
end