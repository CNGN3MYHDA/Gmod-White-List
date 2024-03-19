BWhiteList = BWhiteList or {}
local API_KEY = "A7B330BA9E2866723EF8888E6AE7092D"  -- Сделай вид, что этого тут нет

// Проверить: является ли аргумент SteamID
function BWhiteList.IsSteamID(str)
	if !isstring(str) then return false end
	str = str:upper()
	if str:match("^STEAM_%d:%d:%d%d%d%d%d%d%d%d%d$") then
		return true
	else
		return false
	end
end

// Получить имя игрока по SteamID
function BWhiteList.GetPlayerNameBySteamID(steamIDs, callback)
	assert(isstring(steamIDs) or istable(steamIDs), "steamIDs must be table")
	assert(isfunction(callback), "callback must be a function")

	local oldSteamIds = table.Copy(steamIDs)

	local url = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key="..API_KEY.."&steamids=" .. table.concat(steamIDs, ",")

	http.Fetch(url, function(body, size, headers, code)
		local data = util.JSONToTable(body)
		
		local names = {}
		if data and data.response and data.response.players and #data.response.players > 0 then
			for _, ply in pairs(data.response.players) do
				names[ply.steamid] = ply.personaname
			end
		end

		for k, v in pairs(oldSteamIds) do
			if !names[v] then names[v] = "Unknown" end
		end

		callback(names)
	end, function(err)
		print("[White List] Error fetching player data: " .. err)

		local names = {}
		for k, v in pairs(oldSteamIds) do
			names[v] = "Unknown"
		end

		callback(names)
	end)
end

// Разделить строку на аргументы
local function SplitByArgs(strargs)
	local args = {}
	local argOpenedBy = " "
	local arg = ""

	for i=1, strargs:len() do
		local letter = strargs[i]
		if letter == "\"" then
			if argOpenedBy == " " then
				if arg:len() == 0 then
					argOpenedBy = letter
					continue
				else
					table.insert(args, arg)
					arg = ""
					argOpenedBy = letter
				end
			else
				if argOpenedBy then
					table.insert(args, arg)
					arg = ""
					argOpenedBy = nil
				else
					argOpenedBy = letter
				end
			end
		elseif letter == " " then
			if argOpenedBy == " " then
				if arg:len() == 0 then
					continue
				else
					table.insert(args, arg)
					arg = ""
					argOpenedBy = letter
				end
			elseif !argOpenedBy then
				argOpenedBy = letter
			else
				arg = arg .. letter
			end
		else
			arg = arg .. letter
		end
	end

	if arg:len() > 0 then table.insert(args, arg) end

	return args
end

// Заключить аргументы в кавычки и соеденить в одну строку 
local function argsConcat(args)
	local str = ""
	for _, arg in pairs(args) do
		str = str.." \""..arg.."\""
	end
	return str
end

// Ответное сообщение
local function callBackMsg(ply, ...)
	local args = {...}
	table.insert(args, 1, Color(150, 150, 200))
	table.insert(args, 2, "[White List] ")
	table.insert(args, 3, Color(200, 200, 210))
	table.insert(args, "\n")

	if SERVER then
		if IsValid(ply) then
			net.Start("BWhiteList.Msg")
				net.WriteTable(args)
			net.Send(ply)
		else
			MsgC(unpack(args))
		end
	else
		MsgC(unpack(args))
	end
end

// Методы (подкоманды) для команды whitelist
local methods = {
	add = {
		autoComplete = function(cmd, args)
			return {cmd.." \"SteamID\""}
		end,
		callback = function(ply, args)
			if CLIENT then return end
			local steamID = args[1] or ""
			steamID = steamID:upper()
			if !BWhiteList.IsSteamID(steamID) then callBackMsg(ply, Color(255, 20, 20), "Invalid SteamID!") return end

			if !BWhiteList.GetList()[steamID] then
				BWhiteList.Add(steamID)
				callBackMsg(ply, "Added '"..steamID.."' to white list!")
			else
				callBackMsg(ply, Color(255, 20, 20), "SteamID '"..steamID.."' already in white list!")
			end
		end,
		canUse = function(ply)
			if IsValid(ply) and !ply:IsSuperAdmin() then callBackMsg(ply, Color(255, 20, 20), "No access!") return false end
		end
	},
	remove = {
		autoComplete = function(cmd, args)
			if CLIENT then return end
			local steamID = args[1] or ""
			steamID = steamID:lower()

			local tbl = {}
			for sID, _ in pairs(BWhiteList.GetList()) do
				if sID:lower():find(steamID) then
					table.insert(tbl, cmd.." \""..sID.."\"")
				end
			end

			return tbl
		end,
		callback = function(ply, args)
			if CLIENT then return end
			local steamID = args[1] or ""
			steamID = steamID:upper()
			if !BWhiteList.IsSteamID(steamID) then callBackMsg(ply, Color(255, 20, 20), "Invalid SteamID!") return end

			if BWhiteList.GetList()[steamID] then
				BWhiteList.Remove(steamID)
				callBackMsg(ply, "Removed '"..steamID.."' from white list!")
			else
				callBackMsg(ply, Color(255, 20, 20), "SteamID '"..steamID.."' not in white list!")
			end
		end,
		canUse = function(ply)
			if IsValid(ply) and !ply:IsSuperAdmin() then callBackMsg(ply, Color(255, 20, 20), "No access!") return false end
		end
	},
	openmenu = {
		callback = function(ply, args)
			if CLIENT then return end
			net.Start("BWhiteList.OpenMenu")
			net.Send(ply)
		end,
		canUse = function(ply)
			if IsValid(ply) and !ply:IsSuperAdmin() then callBackMsg(ply, Color(255, 20, 20), "No access!") return false end
		end
	}
}

concommand.Add("whitelist", function(ply, cmd, args, strargs)
	args = SplitByArgs(strargs)
	local method = args[1]
	if !method then callBackMsg(ply, Color(255, 20, 20), "Method required!") return end

	method = methods[method]

	if !method then callBackMsg(ply, Color(255, 20, 20), "Method '"..args[1].."' not allowed!") return end
	if method.canUse and method.canUse(ply) == false then return end

	table.remove(args, 1)
	method.callback(ply, args)
end,
function(cmd, strargs)
	args = SplitByArgs(strargs)
	local method = args[1] or ""
	method = methods[method]

	if method and method.canUse and method.canUse(ply) != false and method.autoComplete then
		cmd = cmd.." \""..table.remove(args, 1).."\""
		return method.autoComplete(cmd, args)
	end

	local tbl = {}
	method = args[1] or ""
	method = method:lower()
	for m, _ in pairs(methods) do
		if m:lower():find(method) then
			table.insert(tbl, cmd.." \""..m.."\"")
		end
	end

	return tbl
end)


// Debug
--[[
	local function dbg(t, ...)
		print(string.format(t, ...))
	end

	local function SplitByArgs(strargs)
		dbg("-------------------------------------------")
		local args = {}
		local argOpenedBy = " "
		local arg = ""

		for i=1, strargs:len() do
			local letter = strargs[i]
			if letter == "\"" then
				dbg("QUOTE")

				if argOpenedBy == " " then
					if arg:len() == 0 then
						dbg("OPENED BY SPACE. REOPNING")
						argOpenedBy = letter
						continue
					else
						dbg("ARG CLOSE. ARG = '%s'", arg)
						table.insert(args, arg)
						arg = ""
						argOpenedBy = letter
						dbg("ARG OPENED")
					end
				else
					if argOpenedBy then
						dbg("ARG CLOSE. ARG = '%s'", arg)
						table.insert(args, arg)
						arg = ""
						argOpenedBy = nil
					else
						dbg("ARG OPENED")
						argOpenedBy = letter
					end
				end
			elseif letter == " " then
				dbg("SPACE")

				if argOpenedBy == " " then
					dbg("OPENED BY SPACE")
					if arg:len() == 0 then
						dbg("TRASH SPACE")
						continue
					else
						dbg("ARG CLOSE. ARG = '%s'", arg)
						table.insert(args, arg)
						arg = ""
						argOpenedBy = letter
						dbg("ARG OPENED")
					end
				elseif !argOpenedBy then
					dbg("ARG OPENED")
					argOpenedBy = letter
				else
					dbg("OPENED BY = '%s'. ADDING LETTER '%s'", argOpenedBy, letter)
					arg = arg .. letter
				end
			else
				dbg("ADDING LETTER '%s'", letter)
				arg = arg .. letter
			end
			dbg("-------------------")
		end

		if arg:len() > 0 then table.insert(args, arg) end

		return args
	end

	local function IsSteamID(str)
		if str:match("^STEAM_%d:%d:%d%d%d%d%d%d%d%d%d$") then
			return true
		else
			return false
		end
	end
	
	if CLIENT then
		local args = 'add s'
		print(table.ToString(SplitByArgs(args), nil, true))

		--print(IsSteamID("STEAM_0:1:628245049"))
	end
]]