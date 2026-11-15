-- Edge cases dragging the SPELLBOOK window (found by the review):
--   * the inventory closed in the middle of a drag: when it is opened again, the window doesn't
--     jump to the mouse (and that place isn't kept);
--   * a screen width with a fraction (some resolutions): the window dragged against the right
--     edge stays there, its place kept as whole pixels and read back.
dofile("tests/stubs.lua")
local screen_w = 640
function GuiGetScreenDimensions() return screen_w, 360 end
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1)
inventory_open = true; step(3)
local function panel() return find("panel") end
local function at() return panel()[2] .. "," .. panel()[3] end
local start = at()

-- a drag, the inventory closed with the button still held, let go, opened again elsewhere
hover_label, hover_xy = HB, { panel()[2], panel()[3] }
mouse_at_ui(panel()[2] + 20, panel()[3] + 5); step()
mouse_down = true; step(); mouse_at_ui(panel()[2] - 30, panel()[3] + 25); step()
inventory_open = false; step(); mouse_down = false; step(2)
hover_none(); mouse_at_ui(100, 300); inventory_open = true; step(3)
local saved = settings["spellbook.panel_pos"]
check(saved == nil or saved == "" or saved == at(), "opened again: the window where it was (" .. at() .. "), not at the mouse")
check(not (panel()[2] < 100 and panel()[3] > 200), "not moved to the mouse at 100,300 (" .. at() .. ")")

-- a screen 853.33 wide: dragged against the right edge, let go
screen_w = 853.3333333; step()
hover_label, hover_xy = HB, { panel()[2], panel()[3] }
mouse_at_ui(panel()[2] + 20, panel()[3] + 5); step()
mouse_down = true; step(); mouse_at_ui(2000, 100); step()
mouse_down = false; step(); hover_none(); step(2)
local x = panel()[2]
check(x == math.floor(x) and x > 700, "against the right edge, at a whole pixel: " .. at())
check(settings["spellbook.panel_pos"] == at(), "kept as " .. tostring(settings["spellbook.panel_pos"]) .. ", and read back: " .. at())

-- a button already held over the title bar when the inventory is opened isn't a press: no drag
local px, py = panel()[2], panel()[3]
inventory_open = false; step()
hover_label, hover_xy = HB, { px, py }; mouse_at_ui(px + 20, py + 5); mouse_down = true; step(2)
inventory_open = true; step(2); mouse_at_ui(px - 40, py + 30); step(2)
check(panel()[2] == px and panel()[3] == py and not SB.ui.panel_drag, "a button held when the inventory opens: no drag (" .. at() .. ")")
mouse_down = false; hover_none(); step()
print("\nall checks passed")
