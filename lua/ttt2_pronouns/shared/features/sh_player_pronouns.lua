local feat = {}

feat.CreateTable = function()
	if not sql.TableExists("ttt2_user_pronouns") then
		local query = [[
CREATE TABLE IF NOT EXISTS ttt2_user_pronouns (
	steamid64 TEXT PRIMARY KEY,
	pronouns TEXT,
	r INTEGER, g INTEGER, b INTEGER, a INTEGER
) WITHOUT ROWID;
]]
		sql.Query(query)
	end
end

feat.UpdatePronouns = function(steamid64, pronouns, color)
	local query = [[
INSERT INTO ttt2_user_pronouns
	VALUES(']] .. steamid64 .. [[',']] .. pronouns .. [[',']] .. color.r .. [[',']] .. color.g .. [[',']] .. color.b .. [[',']] .. color.a .. [[')
	ON CONFLICT(steamid64) DO UPDATE SET
		pronouns = excluded.pronouns,
		r = excluded.r,
		g = excluded.g,
		b = excluded.b,
		a = excluded.a
]]
	sql.Query(query)
end

feat.RemovePronouns = function(steamid64)
	local query = ("DELETE FROM ttt2_user_pronouns WHERE steamid64 = '" .. steamid64 .. "'")
	sql.Query(query)
end

feat.GetPronouns = function(steamid, subrole)
	local query = ("SELECT pronouns, r, g, b, a FROM ttt2_user_pronouns WHERE steamid64 = '" .. steamid .. "'")

	return sql.Query(query)
end

feat.FormatName = function(steamid)
	return feat.OldNameFunc(self) .. ", yeah"
end

feat.GetDataForPlayers = function(plys)
	local joined = {}
	for _, ply in ipairs( plys ) do
		table.insert(joined, sql.SQLStr( ply:SteamID64() ))
	end
	return table.concat( joined, "," )
end

TTT2Pronouns.HookAdd( "player_connect_client", "PronounsGameEventPlayerConnectClient", function( data )
	local name = data.name			// Same as Player:Nick()

	// Player has connected; this happens instantly after they join -- do something..
	local ply = Player( data.userid )

	local plys = player.GetAll()
	local data = sql.Query("SELECT * FROM ttt2_user_pronouns WHERE steamid64 IN (" .. feat.GetDataForPlayers(plys) .. ")")

	for _, ply_data in pairs(data) do

	end

	net.Start( "PronounsPlayerPronouns" )
	net.WriteUInt( #plys, 7 )

	-- net.Send( Entity( 1 ) )
	for _, oply in ipairs( plys ) do
		net.WriteString( feat.OldNameFunc( plys ) )
		net.WriteString(  )
	end
end )

TTT2Pronouns.HookAdd("PlayerSay", "player_pronouns", function(ply, txt)
	local args = string.Split(txt, " ") or {txt}
	if args[1] == "!pronouns" then
		local color_parts = string.Split(args[3], ",")
		local color = Color(color_parts[1], color_parts[2], color_parts[3], 255)
		feat.UpdatePronouns(ply:SteamID64(), args[2], color)
	end
end)

TTT2Pronouns.HookAdd("PronounsPatchCoreTTT2", "player_pronouns", function()
	feat.CreateTable()

	if not GetConVar("sv_pronouns_pronouns_wrap_player"):GetBool() then return end

	local meta = FindMetaTable("Player")
	if SERVER then
		util.AddNetworkString( "PronounsPlayerPronouns" )
		feat.OldNameFunc = meta.Name
	end
	if CLIENT then
		feat.OldNameFunc = meta.GetName
	end

	meta.Name = feat.FormatName
	meta.GetName = feat.FormatName
	meta.Nick = feat.FormatName
end)

TTT2Pronouns.HookAdd("PronounsCreateConVars", "player_pronouns", function()
	TTT2Pronouns.MakeCVar("pronouns_auto_parse", "0")
	TTT2Pronouns.MakeCVar("pronouns_wrap_player", "0")
end)

TTT2Pronouns.HookAdd("PronounsServerAddonSettings", "player_pronouns", function(parent, general)
	TTT2Pronouns.MakeElement(general, "pronouns_auto_parse", "MakeCheckBox")
	TTT2Pronouns.MakeElement(general, "pronouns_wrap_player", "MakeCheckBox")
end)

if SERVER then
	TTT2Pronouns.HookAdd("PronounsSlowThink", "player_pronouns", feat.HurryUpTimeCheck)
end

TTT2Pronouns.AddFeature("PlayerPronouns", feat)
