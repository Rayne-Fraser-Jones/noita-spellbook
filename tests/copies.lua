-- Right-clicking a card opens its spell's copies pages (any spell, even one with unlimited uses): every copy, one
-- slot each (no groups, no counts), ordered by uses left as in the settings. They close when
-- another page is selected. Copies taken from them are counted as from any page.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1)
SB.add("BOMB", 3, 2); SB.add("BOMB", 1, 1); SB.add("BOMB", 0, 1)
inventory_open = true; step(3)
check(row_str() == "LIGHT_BULLET#-1 BOMB#3" and find_count("^4$"), "Projectiles 1: Bomb in one slot, 4 copies: " .. row_str())

local function right_click(slot) hover_slot(slot); step(); right_down = true; step(); right_down = false; hover_none(); step(4) end

-- a spell with unlimited uses: its copies pages too (one copy here)
right_click(1)
check(SB.selected == "9:1" and SB.copies_of == "LIGHT_BULLET" and row_str() == "LIGHT_BULLET#-1", "right-click on Spark bolt (unlimited): its copies page, one copy")
click = { match = "Projectiles" }; step(4)
check(not SB.copies_of and SB.selected == "0:1", "Projectiles clicked: closed")

right_click(2)
check(SB.selected == "9:1" and SB.shown == "9:1", "right-click on Bomb: its copies page selected and shown")
check(row_str() == "BOMB#3 BOMB#3 BOMB#1 BOMB#0", "every copy in a slot of its own, most uses first: " .. row_str())
check(not find_count("^%d$"), "no counts on a copies page")
check(find("button", "Copies") and find("text", "Copies of bomb 1"), "listed as Copies in the page list; \"Page: Copies of bomb 1\"")
check(where("BOMB").total == 4, "every copy counted once")

-- the second copy with 3 uses into a wand
local card = row()[2].e
press_on(2); set_parent(card, WAND); set_slot(card, 1); mouse_down = false; step(4)
check(group("BOMB", 3).count == 1 and where("BOMB").wand == 1 and where("BOMB").total == 4, "one copy into a wand: 1 left with 3 uses")
check(row_str() == "BOMB#3 BOMB#1 BOMB#0", "the page closes up: " .. row_str())

-- a copy back from the wand: stored, and the copies page stays selected
press_on(5); mouse_down = false; set_parent(card, INV_FULL); set_slot(card, 6); step(6)
check(group("BOMB", 3).count == 2 and where("BOMB").total == 4, "back from the wand: stored")
check(SB.selected == "9:1" and row_str() == "BOMB#3 BOMB#3 BOMB#1 BOMB#0", "the copies page stays, with it back: " .. row_str())
check(SB.home == "0:1", "and Projectiles 1 is remembered as its spell type page")

-- fewest uses first
settings["spellbook.uses_order"] = "fewest"; SB.switch_page(PLAYER, "9:1"); step(4)
check(row_str() == "BOMB#0 BOMB#1 BOMB#3 BOMB#3", "fewest uses first, as set: " .. row_str())
settings["spellbook.uses_order"] = nil

-- more copies than a row: a second page
SB.add("BOMB", 2, 14); step(4)
check(SB.layout().by_type[9][2] and #SB.layout().by_type[9][2].entries == 2, "18 copies: two pages (16 and 2)")
check(find("button", "2"), "page 2 listed after Copies")

-- another page selected: the copies pages close
click = { match = "Projectiles" }; step(4)
check(not SB.copies_of and not find("button", "Copies") and SB.selected == "0:1", "Projectiles selected: the copies pages are gone")
check(where("BOMB").total == 18, "every copy counted once: " .. where("BOMB").total)

-- every copy taken out: the copies page stays, empty, and a copy put back shows on it
SB.add("ACID_TRAIL", -1, 2); step(3); right_click(3)
check(SB.selected == "9:1" and row_str() == "ACID_TRAIL#-1 ACID_TRAIL#-1", "copies of Acid trail: " .. row_str())
local a1 = row()[1].e
press_on(1); set_parent(a1, WAND); set_slot(a1, 1); mouse_down = false; step(4)
local a2 = row()[1].e
press_on(1); set_parent(a2, WAND); set_slot(a2, 2); mouse_down = false; step(4)
check(not group("ACID_TRAIL", -1) and SB.selected == "9:1" and SB.shown == "9:1" and row_str() == "" and find("button", "Copies"),
  "both copies into the wand: the copies page stays, empty")
press_on(5); mouse_down = false; set_parent(a1, INV_FULL); set_slot(a1, 3); step(6)
check(group("ACID_TRAIL", -1).count == 1 and SB.selected == "9:1" and row_str() == "ACID_TRAIL#-1", "one put back: it shows on the copies page: " .. row_str())
click = { match = "Projectiles" }; step(4)
check(not SB.copies_of and not find("button", "Copies"), "another page clicked: closed")

-- 400 copies: 25 pages, too many numbers for one line: "< 1/25 >" instead
SB.add("SPLITTER", -1, 400); step(3)
local sp_slot; for s, c in pairs(row()) do if c.id == "SPLITTER" then sp_slot = s end end
right_click(sp_slot)
local function col(w) return w and w.color and table.concat(w.color, ",") or "none" end
check(#SB.layout().by_type[9] == 25 and col(find("text", "<")) == "0.6,0.6,0.6" and col(find("button", ">")) == "1,1,1"
  and col(find("text", "1")) == "1,0.85,0.4" and col(find("text", "/25")) == "0.6,0.6,0.6" and col(find("button", "Copies")) == "1,0.85,0.4",
  "25 copies pages: \"Copies\", under it \"< 1/25 >\": > white (< grey on page 1), the number gold (selected), \"/25\" dark grey; Copies gold (page 1's button)")
check(not find("button", "25") and find("button", ">")[4] == find("button", "Copies")[4] + 9, "no page numbers: \"< 1/25 >\" on the line under Copies")
do
  -- "<" is drawn 2 narrower than the font reports, so the number after it is 2 closer: the same
  -- visible gap on both sides
  local lt, num, total, gt = find("text", "<"), find("text", "1"), find("text", "/25"), find("button", ">")
  check(num[3] - lt[3] == 5 + 3 - 2 and gt[3] - total[3] == 15 + 3, "the gap after < is 2 less than the gap before >")
end
click = { match = ">" }; step(4)
check(SB.selected == "9:2" and find("text", "2") and find("text", "/25"), "> : page 2")
hover_name(">"); step(12)
check(SB.shown == "9:2", "resting on > : no preview, the selected page stays shown")
hover_none(); step(2)
check(not find_tip("View page: Copies of splitter 3", ""), "no tooltips on the arrows (at the screen's edge they would cover them)")
click = { match = "<" }; step(4)
check(SB.selected == "9:1" and find("text", "1"), "< : page 1 again")
check(find("text", "<") and col(find("text", "<")) == "0.6,0.6,0.6" and not find("button", "<") and col(find("button", ">")) == "1,1,1",
  "on the first page: < dark grey and not a button, > white")
click = { match = "<" }; step(4)
check(SB.selected == "9:1", "< on page 1: stays")
for _ = 1, 25 do click = { match = ">" }; step(4) end
check(SB.selected == "9:25" and find("text", "25"), "> up to the last page, then stays")
check(find("text", ">") and not find("button", ">") and col(find("button", "<")) == "1,1,1", "on the last page: > dark grey and not a button, < white")
-- clicking > up to the last page with the mouse resting on it (seen in play: the row went back to
-- the page before and stayed there until the mouse left the window). The mouse is over the
-- window too, which keeps the page last looked at shown.
click = { match = "<" }; step(4)
check(SB.selected == "9:24", "back to page 24")
local p = find("panel")
mouse_point = { p[2] + 5, p[3] + p[5] - 3 }; hover_name(">"); step(12)
check(SB.shown == "9:24", "resting on > : page 24 still shown")
click = { match = ">" }; step(20)
check(SB.selected == "9:25" and SB.shown == "9:25", "> clicked, the mouse still there: page 25 selected and shown (shown: " .. tostring(SB.shown) .. ")")
mouse_point = nil; hover_none(); step(3)
click = { match = "Copies" }; step(4)
check(SB.selected == "9:1", "the line's name: page 1")
click = { match = "Projectiles" }; step(4)
check(not SB.copies_of, "closed")

-- the copies pages aren't saved; the spell type page is
right_click(2); SB.save()
check(globals["spellbank2_selected"] == "0:1", "saved: the spell type page, not the copies page")
print("\nall checks passed")
