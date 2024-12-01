if TTT2Pronouns then TTT2Pronouns.is_reload = true end
TTT2Pronouns = TTT2Pronouns or {
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

TTT2Pronouns.file_table = {
	{name = "sh_ttt2_pronouns.lua", scope = SCOPE_SHARED},

	-- shared
	{name = "features/sh_player_pronouns.lua", scope = SCOPE_SHARED},

	-- client
}

TTT2Pronouns.file_times = {}

TTT2Pronouns.SlowThink = function()
	-- TTT2Pronouns.ScanChanges()
	hook.Run("PronounsSlowThink")
end

TTT2Pronouns.ScanChanges = function()
	for _, script in pairs(TTT2Pronouns.file_table) do
		local path = "ttt2_pronouns/"

		if script.scope == SCOPE_SHARED then
			path = path .. "shared/" .. script.name
		elseif script.scope == SCOPE_SERVER then
			path = path .. "server/" .. script.name
		elseif script.scope == SCOPE_CLIENT then
			path = path .. "client/" .. script.name
		end

		local new_time = file.Time(path, "LUA")
		if TTT2Pronouns.file_times[path] ~= new_time then
			-- print("ScanChanges: file", path, "was", TTT2Pronouns.file_times[path], "is now", new_time)
			return TTT2Pronouns.LoadFiles()
		end
	end
end

TTT2Pronouns.HookAdd = function(hook_name, hook_id, func)
	local long_id = "TTT2Pronouns_" .. hook_name
	if hook_id ~= nil and hook_id ~= "" and type(hook_id) ~= "table" then
		long_id = long_id .. hook_id
	end
	hook.Remove(hook_name, long_id)
	hook.Add(hook_name, long_id, func)
end

TTT2Pronouns.LoadFiles = function()
	for _, script in ipairs(TTT2Pronouns.file_table) do
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

		TTT2Pronouns.file_times[path] = file.Time(path, "LUA")
	end
end

TTT2Pronouns.ClearRoundData = function()
	TTT2Pronouns.RDATA = table.Copy(TTT2Pronouns.RoundDataProto)
end

TTT2Pronouns.TTTLanguageChanged = function()
	hook.Run("PronounsTTTLanguageChanged")
end

-- TTT2Pronouns.GameEventListen = function()
-- 	gameevent.Listen( "player_connect_client" )
-- end

TTT2Pronouns.Init = function()
	TTT2Pronouns.LoadFiles()

	hook.Run("PronounsCreateConVars")
	hook.Run("PronounsPatchCoreTTT2")

	TTT2Pronouns.TTTLanguageChanged()

	-- TTT2Pronouns.GameEventListen()
end

TTT2Pronouns.TTTBeginRound = function()
	TTT2Pronouns.ClearRoundData()
	local alive = util.GetAlivePlayers()
	local alive_count = #alive

	for _, ply in ipairs(alive) do
		hook.Run("PronounsTTTBeginRoundLivingPlayer", ply, alive_count)
	end

	timer.Simple(1, function()
		timer.Create("PronounsSlowThink", 1, 0, TTT2Pronouns.SlowThink)
	end)
end

TTT2Pronouns.TTTEndRound = function()
	TTT2Pronouns.ClearRoundData()
	local alive = util.GetAlivePlayers()
	local alive_count = #alive

	for _, ply in ipairs(alive) do
		hook.Run("PronounsTTTEndRoundLivingPlayer", ply, alive_count)
	end
	timer.Remove("PronounsSlowThink")
end

TTT2Pronouns.HookAdd("PostInitPostEntity", "Init", TTT2Pronouns.Init)
TTT2Pronouns.HookAdd("TTTBeginRound", "TTTBeginRound", TTT2Pronouns.TTTBeginRound)
TTT2Pronouns.HookAdd("TTTEndRound", "TTTEndRound", TTT2Pronouns.TTTEndRound)
TTT2Pronouns.HookAdd("TTTLanguageChanged", "TTTLanguageChanged", TTT2Pronouns.TTTLanguageChanged)

if TTT2Pronouns.is_reload then
	TTT2Pronouns.Init()
end