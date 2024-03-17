BWhiteList = BWhiteList or {}

file.CreateDir("whitelist")
local LIST_PATH = "whitelist/whitelist.json"
local CONFIG_PATH = "whitelist/config.json"
local LOGS_PATH = "whitelist/logs.txt"
local LOGS_PAGE = 20
file.Delete(LOGS_PATH)

local defaultConfig = {
	VERSION = 1,							-- версия конфига (НЕ ТРОГАТЬ)
	enable = true,  						-- Включен/выключен
	reason = "You are not in white list!",  -- Причина kick'а
	forceKick = false,						-- Kick'ать игроков, если они были удалены из white list'а, пока находились на сервере
	forceKickReason = nil, 					-- Причина kick'а игрока, если он был удалён из white list'а, пока находился на сервере (nil == стандартная причина)
	writeConnectedLogs = true 				-- Записывать логи подключившихся игроков, которые в white list'е
}

local configAliases = {}

local function get(path)
	return util.JSONToTable(file.Read(path, "DATA") or "") or {}
end

local function set(path, lst)
	file.Write(path, util.TableToJSON(lst))
end

local function log(passed, name, steamID, address)
	local logStr
	if passed and BWhiteList.GetConfigValue("writeConnectedLogs") then
		logStr = "Player %s (%s) connected. Player is whitelisted!"
	else
		logStr = "Connection of player %s (%s) was cancelled. Player is not whitelisted!"
	end
	local args = {
		Color(150, 150, 200),
		"[White List] ",
		Color(200, 200, 210),
		string.format(logStr.."\n", name, steamID)
	}
	MsgC(unpack(args))

	file.Append(LOGS_PATH, string.format("time=%s;passed=%s;str=%s;name=%s;SteamID=%s;address=%s\n", os.time(), passed and 1 or 0, logStr, name, steamID, address))
end

if !file.Exists(CONFIG_PATH, "DATA") then
	set(CONFIG_PATH, defaultConfig)
end

// Добавить SteamID в white list
function BWhiteList.Add(steamID)
	assert(isstring(steamID), "steamID must be a string!")

	local lst = get(LIST_PATH)
	lst[steamID] = true
	set(LIST_PATH, lst)
end

// Удалить SteamID из white list'а
function BWhiteList.Remove(steamID)
	assert(isstring(steamID), "steamID must be a string!")

	local lst = get(LIST_PATH)
	lst[steamID] = nil
	set(LIST_PATH, lst)

	local target = player.GetBySteamID(steamID)
	if BWhiteList.GetConfigValue("forceKick") and IsValid(target) then
		target:Kick(BWhiteList.GetConfigValue("forceKickReason") or BWhiteList.GetConfigValue("reason"))
	end
end

// Получить список SteamID (в таблице являются ключами), записанные в white list
function BWhiteList.GetList()
	return get(LIST_PATH)
end

// Получить логи
function BWhiteList.GetLogs()
	local logs = {}
	local logsStr = file.Read(LOGS_PATH, "DATA")

	for k, log in pairs(string.Split(logsStr, "\n")) do
		local tbl = {}
		for _, p in pairs(string.Split(log, ";")) do
			for k, v in string.gmatch(p, "([%w_]+)%s*=%s*([%w_]+)") do
				tbl[k] = v
			end
		end
		if table.Count(tbl) > 0 then table.insert(logs, tbl) end
	end

	return logs
end

// Получить кол-во страниц логов
function BWhiteList.GetLogsPagesCount()
	return table.Count(BWhiteList.GetLogs()) / LOGS_PAGE
end

// Получить страницу логов
function BWhiteList.GetLogsPage(page)
	assert(isnumber(page), "page must be a number!")
	return BWhiteList.GetLogs()[page] or {}
end

// Получить весь конфиг
function BWhiteList.GetConfig()
	return get(CONFIG_PATH)
end

// Получить значеине из конфига по ключу
function BWhiteList.GetConfigValue(key)
	assert(isstring(key), "key must be a string!")

	return get(CONFIG_PATH)[key]
end

// Установить значение конфига
function BWhiteList.SetConfigValue(key, val)
	assert(isstring(key), "key must be a string!")

	local lst = get(CONFIG_PATH)
	lst[val] = val
end

// Запрет входа, если не в white list'е
gameevent.Listen("player_connect")
hook.Add("player_connect", "BWhiteList.Check", function(data)
	if !BWhiteList.GetConfigValue("enable") or data.bot == 1 then return end

	if !BWhiteList.GetList()[data.networkid] then
		game.KickID(data.userid, BWhiteList.GetConfigValue("reason"))
		log()
	end
end)

local version = BWhiteList.GetConfigValue("VERSION")
if !version then set(CONFIG_PATH, defaultConfig) return end
if version < defaultConfig.VERSION then
	local cfg = table.Copy(defaultConfig)
	for k, v in pairs(get(CONFIG_PATH)) do
		for curKey, aliases in pairs(configAliases) do
			if aliases[k] then
				cfg[curKey] = v
				break
			end
		end
		cfg[k] = v
	end
	set(CONFIG_PATH, cfg)
end