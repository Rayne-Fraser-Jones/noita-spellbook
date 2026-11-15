-- The arrow at the right end of the panel's title bar: up while the panel is open; clicked, the
-- panel collapses to its title bar and the arrow points down; clicked again, the whole panel is
-- back. A press on the arrow doesn't drag the panel. Collapsing gives back the search box's
-- keyboard. The panel stays collapsed in later runs (a hidden mod setting).
dofile("tests/stubs.lua")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1); SB.add("DAMAGE", -1, 1)
inventory_open = true; step(3)
local function panel() return find("panel") end
local function image(id) for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] == id then return w end end end
-- the arrow's four rows, top to bottom: their widths (in pixels; the stand-in's white pixel is 20 wide)
local function arrow_rows()
  local rows = {}
  for i = 0, 3 do local w = image(230 + i); if w then rows[#rows + 1] = { y = w[4], width = math.floor(w.sx * 20 + 0.5), x = w[3] } end end
  table.sort(rows, function(a, b) return a.y < b.y end)
  local o = {}
  for i, r in ipairs(rows) do o[i] = r.width end
  return table.concat(o, ","), rows
end
local function press_arrow()
  local p = panel()
  hover_label, hover_xy = HB, { p[2] + p[4] - 13, p[3] }; step()
  mouse_down = true; step(); mouse_down = false; step(); hover_none(); step(2)
end

local full_h = panel()[5]
local widths, rows = arrow_rows()
check(widths == "1,3,5,7", "open: the arrow points up (" .. widths .. ")")
check(rows[4].x >= panel()[2] + panel()[4] - 13 and rows[4].x + 7 <= panel()[2] + panel()[4] and rows[1].y > panel()[3] and rows[4].y < panel()[3] + 13,
  "at the right end of the title bar")
check(find_tip("Collapse the panel", "^$"), "its tooltip")
local x0, y0 = panel()[2], panel()[3]

-- the search box has the keyboard; then the arrow clicked: collapsed
local b = find("input")
hover_label, hover_xy = HB, { b.x, b.y }; step(); mouse_down = true; step(); mouse_down = false; hover_none(); step()
check(SB.ui.search_focus == true and comps[CONTROLS].f.enabled == false, "the search box has the keyboard")
press_arrow()
check(settings["spellbook.panel_collapsed"] == true and next_settings["spellbook.panel_collapsed"] == true, "clicked: collapsed (kept in the setting)")
check(panel()[5] == 14 and panel()[4] > 0 and find("text", "SPELLBOOK") and not find("button", "Projectiles") and not find("input"),
  "only the title bar: no page list, no search box (" .. panel()[5] .. " tall)")
check(arrow_rows() == "7,5,3,1" and find_tip("Expand the panel", "^$"), "the arrow points down, with its tooltip")
check(panel()[2] == x0 and panel()[3] == y0 and not SB.ui.panel_drag, "the press on the arrow didn't drag it")
check(SB.ui.search_focus == false and comps[CONTROLS].f.enabled == true, "the search box gave the keyboard back: controls on")
check(SB.shown == "0:1" and row_str() == "LIGHT_BULLET#-1", "the row still shows the page")

-- kept when the inventory is closed and opened again
inventory_open = false; step(2); inventory_open = true; step(3)
check(panel()[5] == 14 and not find("button", "Projectiles"), "still collapsed when opened again")

-- the title bar still drags it
hover_label, hover_xy = HB, { panel()[2], panel()[3] }; mouse_at_ui(panel()[2] + 5, panel()[3] + 5); step()
mouse_down = true; step(); mouse_at_ui(x0 - 40 + 5, y0 + 30 + 5); step(); mouse_down = false; step(); hover_none(); step()
check(panel()[2] == x0 - 40 and panel()[3] == y0 + 30, "collapsed, dragged by its title bar: " .. panel()[2] .. "," .. panel()[3])

-- clicked again: the whole panel
press_arrow()
check(settings["spellbook.panel_collapsed"] == false and panel()[5] == full_h and find("button", "Projectiles") and find("input"), "clicked again: the whole panel")
check(arrow_rows() == "1,3,5,7", "the arrow points up again")

-- the hidden setting in settings.lua
local real_dofile = dofile
dofile = function(p) if p:match("mod_settings") then return end return real_dofile(p) end
real_dofile("settings.lua")
dofile = real_dofile
local found
for _, st in ipairs(mod_settings) do if st.id == "panel_collapsed" then found = st end end
check(found and found.hidden and found.value_default == false, "a hidden setting, off to begin with")
print("\nall checks passed")
