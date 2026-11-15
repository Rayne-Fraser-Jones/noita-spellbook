-- Spellbook's mod settings, in the game's mod_settings format. The mod reads them as
-- "spellbook.<id>" (SB.setting, in files/core.lua).
dofile("data/scripts/lib/mod_settings.lua")

local mod_id = "spellbook"
local PANEL_POS = "spellbook.panel_pos"
mod_settings_version = 5
mod_settings =
{
	{
		id = "merge_categories",
		ui_name = "Merge categories",
		ui_description = "Show all spells together instead of by category\nThe same as the 'Merge categories' box in the spellbook panel",
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "hide_unowned",
		ui_name = "Hide unowned spells",
		ui_description = "Hide the placeholders for spells you own no copies of\nThe same as the 'Hide unowned' box in the spellbook panel",
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "show_locked",
		ui_name = "Show locked spells",
		ui_description = "With 'Hide unowned' off, also show spells you haven't unlocked yet",
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "uses_order",
		ui_name = "Show limited-uses spells with",
		ui_description = "Which copy of a limited-uses spell its slot shows\nRight-click a limited-uses spell to see all its copies",
		value_default = "most",
		values = { { "most", "Most uses on top" }, { "fewest", "Least uses on top" } },
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		-- turned off by the spellbook the first time a card is right-clicked
		id = "show_copies_hint",
		ui_name = "Show right-click hint",
		ui_description = "A hint about right-clicking a limited-uses spell\nTurns off once you've done it",
		value_default = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		-- (hidden: where the spellbook panel was dragged to, "x,y"; empty for its usual place)
		id = "panel_pos",
		value_default = "",
		hidden = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		-- (hidden: whether the spellbook panel is collapsed to its title bar, by the arrow on it)
		id = "panel_collapsed",
		value_default = false,
		hidden = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "reset_panel_pos",
		ui_name = "Reset panel position",
		ui_description = "Move the spellbook panel back to its usual place",
		not_setting = true,
		-- a button while the panel has been moved; dark grey text while it is in its usual place
		ui_fn = function(_, gui, _, im_id, setting)
			local v = ModSettingGetNextValue(PANEL_POS)
			if v ~= nil and v ~= "" then
				if GuiButton(gui, im_id, mod_setting_group_x_offset, 0, setting.ui_name) then
					ModSettingSetNextValue(PANEL_POS, "", false)
					ModSettingSet(PANEL_POS, "")
				end
				GuiTooltip(gui, setting.ui_description, "Drag the panel by its title bar to move it")
			else
				GuiColorSetForNextWidget(gui, 0.6, 0.6, 0.6, 1)
				GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)
				GuiTooltip(gui, setting.ui_description, "Already in its usual place\nDrag the panel by its title bar to move it")
			end
		end,
	},
	{
		id = "debug_log",
		ui_name = "Debug log",
		ui_description = "Records what the spellbook does, for reporting a problem\nSaved with the run when you save and quit",
		value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
}

function ModSettingsUpdate( init_scope )
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end
