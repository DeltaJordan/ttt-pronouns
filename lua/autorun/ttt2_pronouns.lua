if TTT2PRONOUNS then TTT2PRONOUNS.is_reload = true end
TTT2PRONOUNS = TTT2PRONOUNS or {
	is_reload = false,

	CVARS = {},
	RDATA = {}, -- round data
	PDATA = {}, -- persistent data

	RoundDataProto = {},

	Features = {},
	Mechanics = {},
	-- HookBay = {},
	-- RoleHooks = {},
}

local SCOPE_CLIENT = 1
local SCOPE_SERVER = 2
local SCOPE_SHARED = 3

TTT2PRONOUNS.file_table = {
	{name = "sh_ttt2_pronouns.lua", scope = SCOPE_SHARED},

	-- shared
	{name = "features/sh_player_pronouns.lua", scope = SCOPE_SHARED},

	-- client
}

TTT2PRONOUNS.file_times = {}

TTT2PRONOUNS.ScanChanges = function()
	for _, script in pairs(TTT2PRONOUNS.file_table) do
		local path = "ttt2_pronouns/"

		if script.scope == SCOPE_SHARED then
			path = path .. "shared/" .. script.name
		elseif script.scope == SCOPE_SERVER then
			path = path .. "server/" .. script.name
		elseif script.scope == SCOPE_CLIENT then
			path = path .. "client/" .. script.name
		end

		local new_time = file.Time(path, "LUA")
		if TTT2PRONOUNS.file_times[path] ~= new_time then
			-- print("ScanChanges: file", path, "was", TTT2PRONOUNS.file_times[path], "is now", new_time)
			return TTT2PRONOUNS.LoadFiles()
		end
	end
end

TTT2PRONOUNS.HookAdd = function(hook_name, hook_id, func)
	local long_id = "TTT2PRONOUNS_" .. hook_name
	if hook_id ~= nil and hook_id ~= "" and type(hook_id) ~= "table" then
		long_id = long_id .. hook_id
	end
	hook.Remove(hook_name, long_id)
	hook.Add(hook_name, long_id, func)
end

TTT2PRONOUNS.LoadFiles = function()
	for _, script in ipairs(TTT2PRONOUNS.file_table) do
		local path = "ttt2_pronouns/"

		if script.scope == SCOPE_SHARED then
			path = path .. "shared/" .. script.name
		elseif script.scope == SCOPE_SERVER then
			path = path .. "server/" .. script.name
		elseif script.scope == SCOPE_CLIENT then
			path = path .. "client/" .. script.name
		end

		if SERVER and (script.scope == SCOPE_CLIENT or script.scope == SCOPE_SHARED) then
			AddCSLuaFile(path)
		end

		if script.scope == SCOPE_SHARED or (SERVER and script.scope == SCOPE_SERVER) or (CLIENT and script.scope == SCOPE_CLIENT) then
			include(path)
		end

		TTT2PRONOUNS.file_times[path] = file.Time(path, "LUA")
	end
end

TTT2PRONOUNS.ClearRoundData = function()
	TTT2PRONOUNS.RDATA = table.Copy(TTT2PRONOUNS.RoundDataProto)
end

TTT2PRONOUNS.TTTLanguageChanged = function()
	hook.Run("PronounsTTTLanguageChanged")
end

-- TTT2PRONOUNS.GameEventListen = function()
-- 	gameevent.Listen( "player_connect_client" )
-- end

TTT2PRONOUNS.Init = function()
	TTT2PRONOUNS.LoadFiles()

	hook.Run("PronounsCreateConVars")
	hook.Run("PronounsPatchCoreTTT2")

	TTT2PRONOUNS.TTTLanguageChanged()

	-- TTT2PRONOUNS.GameEventListen()
end

TTT2PRONOUNS.TTTBeginRound = function()
	TTT2PRONOUNS.ClearRoundData()
	local alive = util.GetAlivePlayers()
	local alive_count = #alive

	for _, ply in ipairs(alive) do
		hook.Run("PronounsTTTBeginRoundLivingPlayer", ply, alive_count)
	end

	timer.Simple(1, function()
		timer.Create("PronounsSlowThink", 1, 0, TTT2PRONOUNS.SlowThink)
	end)
end

TTT2PRONOUNS.TTTEndRound = function()
	TTT2PRONOUNS.ClearRoundData()
	local alive = util.GetAlivePlayers()
	local alive_count = #alive

	for _, ply in ipairs(alive) do
		hook.Run("PronounsTTTEndRoundLivingPlayer", ply, alive_count)
	end
	timer.Remove("PronounsSlowThink")
end

TTT2PRONOUNS.HookAdd("PostInitPostEntity", "Init", TTT2PRONOUNS.Init)
TTT2PRONOUNS.HookAdd("TTTBeginRound", "TTTBeginRound", TTT2PRONOUNS.TTTBeginRound)
TTT2PRONOUNS.HookAdd("TTTEndRound", "TTTEndRound", TTT2PRONOUNS.TTTEndRound)
TTT2PRONOUNS.HookAdd("TTTLanguageChanged", "TTTLanguageChanged", TTT2PRONOUNS.TTTLanguageChanged)

if TTT2PRONOUNS.is_reload then
	TTT2PRONOUNS.Init()
end