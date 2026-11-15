-- Spellbook: what every part of the mod shares: the SB table, the mod settings, the debug log,
-- messages and the mouse buttons.

SB = SB or {}
SB.frame = SB.frame or 0   -- frames run so far (counted by SB.tick); the debug log's clock

-- Mod settings ---------------------------------------------------------------------------
-- (the ids are those in settings.lua)

function SB.setting(id) return ModSettingGet("spellbook." .. id) end

-- Changes a setting, in the mod settings menu too (otherwise the menu puts the old value back
-- when it is next closed).
function SB.set_setting(id, value)
	ModSettingSet("spellbook." .. id, value)
	if ModSettingSetNextValue then ModSettingSetNextValue("spellbook." .. id, value, false) end
end

-- (the two boxes in the panel are worded as what ticking them does: both are off to begin with)
function SB.categorize() return SB.setting("merge_categories") ~= true end   -- a line per spell type, unless "Merge categories"
function SB.show_unowned() return SB.setting("hide_unowned") ~= true end        -- placeholders, unless "Hide unowned spells"
function SB.show_locked() return SB.setting("show_locked") == true end      -- "Show locked spells"
function SB.fewest_first() return SB.setting("uses_order") == "fewest" end  -- "Least uses on top"

-- Debug log ------------------------------------------------------------------------------
-- While "Debug log" is on. The normal game (noita.exe) doesn't write Lua's print to
-- logger.txt (seen in play: nothing arrived), so the last LOG_LINES lines are also kept in a
-- global value, which is saved with the run in save00/world_state.xml on save and quit. print
-- still reaches logger.txt in noita_dev.exe.

local LOG_KEY, LOG_LINES = "spellbank2_debug_log", 400

function SB.log(msg)
	if SB.setting("debug_log") ~= true then return end
	local line = SB.frame .. ": " .. msg
	print("[spellbook] " .. line)
	if not SB.log_lines then
		-- carry on from what an earlier session saved
		SB.log_lines = {}
		for l in string.gmatch(GlobalsGetValue(LOG_KEY, ""), "[^\n]+") do SB.log_lines[#SB.log_lines + 1] = l end
		SB.log_lines[#SB.log_lines + 1] = "---- game started (frame numbers start again) ----"
	end
	SB.log_lines[#SB.log_lines + 1] = line
	while #SB.log_lines > LOG_LINES do table.remove(SB.log_lines, 1) end
	GlobalsSetValue(LOG_KEY, table.concat(SB.log_lines, "\n"))
end

-- A message at the bottom left of the screen, like the game's own.
function SB.message(text) GamePrint("Spellbook: " .. text) end

-- Mouse buttons --------------------------------------------------------------------------

SB.MOUSE_LEFT, SB.MOUSE_RIGHT = 1, 2

-- Whether a mouse button is held right now. While one is, the spell row is never changed: the
-- game may be in the middle of a drag.
function SB.button_held()
	return InputIsMouseButtonDown(SB.MOUSE_LEFT) or InputIsMouseButtonDown(SB.MOUSE_RIGHT)
end

-- The buttons this frame, and which went down or up since the frame before, as
-- SB.buttons = { left, right, pressed, released, right_pressed }. Read once a frame, before
-- anything else (init.lua), so every part of the mod sees the same press. A button already held
-- when the inventory is opened is not a press.
function SB.read_buttons()
	local last = SB.buttons or {}
	local left, right = InputIsMouseButtonDown(SB.MOUSE_LEFT), InputIsMouseButtonDown(SB.MOUSE_RIGHT)
	SB.buttons = {
		left = left, right = right,
		pressed = left and not last.left,
		released = last.left == true and not left,
		right_pressed = right and not last.right,
	}
end
