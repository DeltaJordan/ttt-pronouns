CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.title = "pronouns_addon_info"

function CLGAMEMODESUBMENU:Populate(parent)
	local general = vgui.CreateTTT2Form(parent, "pronouns_settings_general")

	hook.Run("PronounsServerAddonSettings", parent, general)
end