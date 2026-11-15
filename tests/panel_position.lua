-- The spellbook window: in its usual place at the top, left of the game's list of perks and
-- effects (its border ending at x 512), whatever the game lists there. Dragged by its title bar,
-- it follows the mouse and stays where it is let go, kept on the screen; the place is kept in a
-- hidden mod setting, for later runs. It is drawn in front of everything else.
dofile("tests/stubs.lua")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1); SB.add("BOMB", 3, 1); SB.add("DAMAGE", -1, 1)
inventory_open = true; step(3)
local function panel() return find("panel") end
local function at() return panel()[2] .. "," .. panel()[3] end
local W = panel()[4]

-- its usual place
check(panel()[2] + W + 2 == 512 and panel()[3] == 58, "usual place: at the top, its border ending at x 512 (" .. at() .. ", " .. W .. " wide)")
local sed = add_comp(PLAYER, "StatusEffectDataComponent", { stain_effects = { { 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6 } }, ingestion_effects = { { 0 } } })
step()
check(at() == "385,58", "the game's list of effects doesn't move it: " .. at())

-- the title bar, with SPELLBOOK in it
local title = find("text", "SPELLBOOK")
check(title and title[3] == 387 and title[4] == 60, "SPELLBOOK in the title bar: " .. (title and title[3] .. "," .. title[4] or "none"))
local bar
for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] == 202 then bar = w end end
check(bar and bar[3] == 385 and bar[4] == 58 and bar[5] == 0.22 and table.concat(bar.color, ",") == "0.85,0.6,0.25", "an amber strip over the title")
local function over_bar() hover_label, hover_xy = HB, { panel()[2], panel()[3] } end
over_bar(); step()
for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] == 202 then bar = w end end
check(bar[5] == 0.4 and table.concat(bar.color, ",") == "0.85,0.6,0.25", "stronger under the mouse")

-- in front of everything: the window's parts are all drawn in front of the spellbook's drawing
-- over the spell row (z -2000), and the window's background behind its own text
local show = find("button", "[x] Hide unowned")
check(panel().z < -2000 and show.z < panel().z and find("input").z < panel().z and title.z < panel().z,
  "the window in front of everything (z " .. panel().z .. "), its text in front of its background")

-- only the title bar starts a drag: not a press lower in the window (the game takes an
-- image's height to be its width, so a stretched transparent image over the title bar would
-- reach down over the window)
hover_none(); mouse_point = { panel()[2] + 30, panel()[3] + 40 }; mouse_at_ui(panel()[2] + 30, panel()[3] + 40); step()
mouse_down = true; step(); mouse_at_ui(panel()[2] - 70, panel()[3] + 80); step()
check(at() == "385,58", "a press 40 below the window's top, then moving: it doesn't move")
mouse_down = false; step()
-- the window as a whole is under the mouse down to its bottom (the page last looked at stays shown)
mouse_point = { panel()[2] + 5, panel()[3] + panel()[5] - 3 }; step(2)
check(SB.hover_ui == true, "the mouse near the window's bottom: over the window")
mouse_point = nil; over_bar(); step()

-- dragged by the title bar (the mouse over it): it follows the mouse
local before_row, before_page = row_str(), SB.selected
mouse_at_ui(440, 63); step()
mouse_down = true; step()
mouse_at_ui(340, 103); step()
check(at() == "285,98", "dragged 100 left and 40 down: it follows (" .. at() .. ")")
check(not settings["spellbook.panel_pos"], "not kept yet while the button is held")
hover_label, hover_xy = HB, { panel()[2], panel()[3] }
mouse_at_ui(290, 113); step()
check(at() == "235,108", "still following: " .. at())
mouse_down = false; step()
check(at() == "235,108" and settings["spellbook.panel_pos"] == "235,108", "let go: it stays there, kept in the setting")
check(row_str() == before_row and SB.selected == before_page, "the spell row and the page selected aren't changed")
mouse_at_ui(100, 200); hover_none(); step(3)
check(at() == "235,108", "the mouse moved away after letting go: it stays")

-- the next run (the setting kept): in the same place
SB.ui.panel_drag = nil; inventory_open = false; step(2); inventory_open = true; step(3)
check(at() == "235,108", "inventory closed and opened again: in the same place")

-- a press elsewhere, then moving over the title bar with the button held: no drag
mouse_at_ui(100, 300); step(); mouse_down = true; step()
over_bar(); mouse_at_ui(290, 113); step(); mouse_at_ui(150, 150); step()
mouse_down = false; hover_none(); step()
check(at() == "235,108", "pressed elsewhere, then over the title bar: it doesn't move")

-- kept on the screen
over_bar(); mouse_at_ui(290, 113); step(); mouse_down = true; step()
mouse_at_ui(-200, -200); step()
check(at() == "2,2", "dragged off the top-left: stops at the screen's edge (" .. at() .. ")")
mouse_at_ui(2000, 2000); step()
local H = panel()[5]
check(panel()[2] == 640 - 2 - W and panel()[3] == 360 - 2 - H, "dragged off the bottom-right: stops at the screen's edge (" .. at() .. ")")
mouse_down = false; hover_none(); step()
check(settings["spellbook.panel_pos"] == at(), "kept where it stopped: " .. tostring(settings["spellbook.panel_pos"]))

-- more pages make it taller: still kept on the screen
for i = 1, 6 do SB.add(({ "SPLITTER", "ACID_TRAIL", "TELEPORT_PROJECTILE", "BOMB", "DAMAGE", "LIGHT_BULLET" })[i], -1, 1) end
settings["spellbook.hide_unowned"] = false; step(3)
check(panel()[3] + panel()[5] <= 358, "taller with unowned spells shown: its bottom still on the screen (" .. at() .. ", " .. panel()[5] .. " tall)")
settings["spellbook.hide_unowned"] = true; step(3)

-- the mod settings button "Reset panel position": puts it back; greyed out while it is there
local real_dofile = dofile
dofile = function(p) if p:match("mod_settings") then return end return real_dofile(p) end
real_dofile("settings.lua")
dofile = real_dofile
mod_setting_group_x_offset = 0
local reset
for _, st in ipairs(mod_settings) do if st.id == "reset_panel_pos" then reset = st end end
gui_log = {}
click = { match = "Reset panel position" }
reset.ui_fn("spellbook", 1, false, 1, reset)
check(settings["spellbook.panel_pos"] == "" and next_settings["spellbook.panel_pos"] == "", "the button: the setting cleared")
gui_log = {}
reset.ui_fn("spellbook", 1, false, 1, reset)
check(not find("button", "Reset panel position") and find("text", "Reset panel position")
  and find_tip("Move the spellbook panel back to its usual place", "^Already in its usual place\nDrag the panel by its title bar to move it$"),
  "in its usual place: the button greyed out (plain grey text), its tooltip saying so")
step()
check(at() == "385,58", "back in its usual place")
print("\nall checks passed")
