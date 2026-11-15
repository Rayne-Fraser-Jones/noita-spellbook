-- The search box: typing selects a page "Search 'text' 1" with the spells whose name holds the
-- text (any case), grouped as usual; with unowned spells shown, the ones you have none of too, faded.
-- Clearing it goes back to the spell type page. While the box has the keyboard, the player's
-- controls are off, so typing doesn't work the game's keys; they come back when it loses the
-- keyboard, when the inventory closes, and when a run saved meanwhile is loaded.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1); SB.add("BOMB", 3, 2); SB.add("BOMB", 1, 1); SB.add("DAMAGE", -1, 1)
inventory_open = true; step(3)
SB.switch_page(PLAYER, "2:1"); step(3)
check(find("input") and find_text("^Search%.%.%.$"), "an empty search box, saying Search...")

-- the mouse over the box (the transparent image over it)
local function over_box() local b = find("input"); hover_label, hover_xy = HB, { b.x, b.y } end
local function click_box() over_box(); step(); mouse_down = true; step(); mouse_down = false; hover_none(); step() end
-- keys, by SDL scancode: a key goes down for a frame (with Shift for a capital)
local CODES = { [" "] = 44, ["-"] = 45 }
for i = 0, 25 do CODES[string.char(97 + i)] = 4 + i end
local function tap(code, shift) keys_down[code] = true; keys_down[225] = shift or nil; step(); keys_down[code] = nil; keys_down[225] = nil; step() end
-- clicks into the box if needed, deletes what is there (holding Backspace), types s
local function type_text(s)
  if not SB.ui.search_focus then click_box() end
  if SB.search_text ~= "" then keys_down[42] = true; step(18 + 3 * #SB.search_text + 3); keys_down[42] = nil; step() end
  for ch in s:gmatch(".") do tap(CODES[ch:lower()], ch ~= ch:lower()) end
  step(3)
end

-- the mouse over the box without a click (running with the inventory open): it takes no typing
-- (seen in play: holding A typed "aaaa")
over_box(); step(); tap(4); tap(4)
check(SB.search_text == "" and find("input").options[1] == 2 and not SB.ui.search_focus,
  "the mouse over the box, no click: nothing typed (the game's box is drawn non-interactive)")
hover_none(); step()
type_text("BoM")
check(SB.selected == "8:1" and SB.shown == "8:1" and row_str() == "BOMB#3", "\"BoM\": its search page, one slot per spell as usual: " .. row_str())
check(find("text", "Search 'BoM' 1") and find("button", "Search") and find_count("^3$"), "\"Page: Search 'BoM' 1\", listed as Search; the count shown (3)")
check(not find_text("^Search%.%.%.$"), "no Search... while there is text")

-- copies taken from a search page are counted as from any page
local card = row()[1].e
press_on(1); set_parent(card, WAND); set_slot(card, 1); mouse_down = false; step(4)
check(group("BOMB", 3).count == 1 and where("BOMB").total == 3 and row_str() == "BOMB#3", "one copy into a wand from the search page")

-- unowned spells shown: the spells you have none of too, faded
type_text("t")
check(page_str("8:1") == "LIGHT_BULLET#-1", "\"t\", Hide unowned: only yours: " .. page_str("8:1"))
SB.set_hide_unowned(PLAYER, false); step(3)
check(page_str("8:1") == "LIGHT_BULLET#-1 -SPLITTER -ACID_TRAIL -TELEPORT_PROJECTILE",
  "unowned shown: faded ones too: " .. page_str("8:1"))
SB.set_hide_unowned(PLAYER, true); step(3)

-- no results: an empty page
type_text("zzz")
check(SB.selected == "8:1" and row_str() == "" and find("text", "Search 'zzz' 1"), "no results: an empty search page")

-- the order in the window: the spell types, then Copies, then Search, then the search box
-- (typing a search closes the copies pages, so they are opened after it)
SB.show_copies(PLAYER, "BOMB"); type_text("bomb")
check(not SB.copies_of and SB.selected == "8:1", "copies open, then typing a search: the search page, and the copies pages close")
SB.show_copies(PLAYER, "BOMB"); step(4)
local proj, copies, search, input = find("button", "Projectiles"), find("button", "Copies"), find("button", "Search"), find("input")
check(proj and copies and search and proj[4] < copies[4] and copies[4] < search[4] and search[4] < input.y,
  "Proj, then Copies, then Search, then the search box at the bottom")

-- cleared: back to the page before
click = { match = "Search" }; step(4)
type_text("")
check(SB.selected == "2:1" and SB.shown == "2:1" and not find("button", "Search"), "cleared: Modifiers 1 again, no Search line")

-- right-click on the box clears it
type_text("bomb"); mouse_down = true; step(); mouse_down = false; step(2)
over_box(); step(); right_down = true; step(); right_down = false; hover_none(); step(3)
check(SB.search_text == "" and SB.selected == "2:1", "right-click on the box: cleared")
-- while it has the keyboard too (seen in play: typed, then right-clicked, and nothing happened).
-- The game's GUI may not follow the mouse then, so where the mouse is comes from its position
-- in the world (which does follow it, seen in the debug log)
type_text("bomb")
check(SB.ui.search_focus and SB.search_text == "bomb", "typed \"bomb\": the box has the keyboard")
local b = find("input")
hover_none(); mouse_at_ui(b.x + 300, b.y + 5); step(); right_down = true; step(); right_down = false; step(2)
check(SB.search_text == "bomb", "a right-click elsewhere while it has the keyboard: not cleared")
mouse_at_ui(b.x + 10, b.y + 5); step(); right_down = true; step(); right_down = false; step(2)
check(SB.search_text == "" and SB.ui.search_focus, "a right-click on the box while it has the keyboard: cleared, and it keeps the keyboard")
tap(CODES.d)
check(SB.search_text == "d", "so typing can start again straight away: " .. SB.search_text)
mouse_down = true; step(); mouse_down = false; step(); type_text(""); mouse_down = true; step(); mouse_down = false; step(2)

-- the keyboard: controls off while the box has it
local controls = function() return comps[CONTROLS].f.enabled end
click_box()
check(controls() == false and globals["spellbank2_controls_off"] == "1", "clicked into the box: controls off")
-- (the white frame: the images with IDs 341 to 344)
local function frame()
  local n = 0
  for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] and w[6] > 340 and w[6] < 345 then n = n + 1 end end
  return n
end
local box = find("input")
local top; for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] and w[6] > 340 and w[6] < 345 then top = top or w end end
local right; for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] and w[6] > 340 and w[6] < 345 and w[3] > box.x then right = w end end
check(frame() == 4 and top[3] == box.x and top[4] == box.y and right[3] == box.x + box.w - 1,
  "and its border lights up: a white frame of 4 lines at the box's edges, as wide as the box is drawn")
hover_input = false; step(); mouse_down = true; step(); mouse_down = false; step()
check(controls() == true and globals["spellbank2_controls_off"] == "", "clicked elsewhere: controls on")
check(frame() == 0, "and the white frame is gone")
-- with the controls off, the game's GUI may still see the mouse over the box (seen in play: a
-- click elsewhere didn't give the keyboard back): any click while it has the keyboard does
click_box(); over_box(); step(); mouse_down = true; step(); mouse_down = false; hover_none(); step()
check(not SB.ui.search_focus and controls() == true, "a click while it has the keyboard, the GUI seeing the mouse over the box: keyboard back")
click_box()
keys_down[40] = true; step(); keys_down[40] = nil; step()
check(controls() == true, "Enter: controls on")
click_box()
inventory_open = false; step(2)
check(controls() == true, "inventory closed while typing: controls on")

-- the transparent image that tells when the mouse is on the box is as tall as the box (seen in
-- play: the box counted as under the mouse all the way down to the bottom of the screen). If the
-- game reports no height for the box (or a strange one), its usual height is used: an image's
-- height scale of 0 means "the same as its width scale", a square as tall as the box is wide
local function hit_h()   -- the height the squares over the box cover (IDs 740 and up)
  local top, bottom
  for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] and w[6] >= 740 and w[6] < 760 then
    top = math.min(top or w[4], w[4]); bottom = math.max(bottom or 0, w[4] + w.sy * 18)
  end end
  return bottom - top
end
inventory_open = true; step(3)
check(math.abs(hit_h() - 11) < 0.01, "the box's hit area as tall as the box (" .. hit_h() .. ")")
input_reported_h = 0; step()
check(math.abs(hit_h() - 11) < 0.01, "the game reporting no height: the usual 11 (" .. hit_h() .. ")")
input_reported_h = 400; step()
check(math.abs(hit_h() - 11) < 0.01, "or a strange one: the usual 11 (" .. hit_h() .. ")")
input_reported_h = 11; step()
-- the mouse below the box (seen in play: the tooltip showed, and clicks counted, 85 below it: the
-- game takes an image's height to be its width)
local b = find("input")
mouse_point = { b.x + 20, b.y + 40 }; step()
mouse_down = true; step(); mouse_down = false; step()
check(not SB.ui.search_focus, "a click 40 below the box: it doesn't take the keyboard")
mouse_point = { b.x + 90, b.y + 5 }; step(); mouse_down = true; step(); mouse_down = false; step()
check(SB.ui.search_focus, "a click on the box, near its right end: it takes the keyboard")
mouse_down = true; step(); mouse_down = false; mouse_point = nil; step()
inventory_open = false; step(2)

-- the keys are read by the spellbook, so typing works wherever the mouse is
inventory_open = true; step(3)
type_text(""); hover_none()
tap(CODES.s); tap(CODES.p); step(2)
check(SB.search_text == "sp" and SB.selected == "8:1", "typed with the mouse off the box: \"sp\"")
keys_down[CODES.l] = true; step(5); keys_down[CODES.l] = nil; step()
check(SB.search_text == "spl", "a key held down types once")
tap(CODES.i); tap(CODES.t)
check(SB.search_text == "split", "more typing adds to it: " .. SB.search_text)
local cursor; for _, w in ipairs(gui_log) do if w[1] == "image" and w[2] == "data/debug/whitebox.png" and w[3] > find("input").x + 1 and w[3] < find("input").x + 70 then cursor = w end end
check(cursor ~= nil or math.floor(SB.frame / 30) % 2 == 1, "a cursor is drawn after the text (it blinks)")

-- Backspace: one character per press; held, it repeats
keys_down[42] = true; step()
check(SB.search_text == "spli", "Backspace pressed: one character gone: " .. SB.search_text)
step(10)
check(SB.search_text == "spli", "held a moment: nothing more yet")
step(10)
check(#SB.search_text < 4, "held longer: it repeats: \"" .. SB.search_text .. "\"")
step(20)
check(SB.search_text == "", "held on: everything gone")
keys_down[42] = nil; step()
mouse_down = true; step(); mouse_down = false; step()
check(not SB.ui.search_focus, "clicked elsewhere: the keyboard back")
tap(CODES.a)
check(SB.search_text == "", "keys typed after that don't go in the box")
inventory_open = false; step(2)

-- a run saved while typing: controls back on when loaded
globals["spellbank2_controls_off"] = "1"; comps[CONTROLS].f.enabled = false
SB.prepare(PLAYER)
check(controls() == true and globals["spellbank2_controls_off"] == "", "loaded with the controls off: back on")
print("\nall checks passed")
