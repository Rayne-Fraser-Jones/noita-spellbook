-- A card in the spell row stands for one copy. Dragged into a wand or thrown, one copy leaves
-- the spellbook and the group's next copy shows in its place. Moved within the row, a new card is put
-- in its slot (pages are always in order): setting the moved card's slot back doesn't stick, the
-- game moves it back again (seen in play).
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1)
local sp = SB.add("SPLITTER", -1, 3)
inventory_open = true; step(3)
check(row_str() == "LIGHT_BULLET#-1 SPLITTER#-1", "the row: " .. row_str())

-- into a wand: one copy
local card = row()[2].e
press_on(2); set_parent(card, WAND); set_slot(card, 1); mouse_down = false; step(4)
check(sp.count == 2 and where("SPLITTER").wand == 1 and where("SPLITTER").total == 3, "into a wand: one copy went in, 2 left")
check(row()[2] and row()[2].id == "SPLITTER" and row()[2].e ~= card and find_count("^2$"), "the next copy shows in its slot, with its count")
check(not SB.reps[card], "the card in the wand is no longer the spellbook's")

-- thrown: one copy
card = row()[2].e
press_on(2); set_parent(card, 0); mouse_down = false; step(4)
check(sp.count == 1 and where("SPLITTER").ground == 1 and where("SPLITTER").total == 3, "thrown: one copy on the ground, 1 left")

-- the game moves the card a moment after the release: still a copy into the wand
card = row()[2].e
press_on(2); mouse_down = false; step(2); set_parent(card, WAND); set_slot(card, 2); step(4)
check(not group("SPLITTER", -1) and where("SPLITTER").wand == 2 and where("SPLITTER").total == 3,
  "the card moved into the wand two frames after the release: the last copy went in")
check(row_str() == "LIGHT_BULLET#-1", "the group is gone and its slot with it: " .. row_str())

-- moved within the row: a new card in its slot
local lb = row()[1].e
press_on(1); set_slot(lb, 6); mouse_down = false; step(4)
check(row_str() == "LIGHT_BULLET#-1" and not row()[6] and where("LIGHT_BULLET").total == 1, "moved to another slot: back in slot 1 (a new card), slot 6 empty: " .. row_str())
step(10)
check(row_str() == "LIGHT_BULLET#-1" and not row()[6], "and it stays that way: " .. row_str())

-- dropped onto another card (the game swaps them): both put back
SB.add("ACID_TRAIL", -1, 1); step(3)
check(row_str() == "LIGHT_BULLET#-1 ACID_TRAIL#-1", "a new group shows up: " .. row_str())
local a, b = row()[1].e, row()[2].e
press_on(1); set_slot(a, 2); set_slot(b, 1); mouse_down = false; step(4)
check(row_str() == "LIGHT_BULLET#-1 ACID_TRAIL#-1" and where("LIGHT_BULLET").total == 1 and where("ACID_TRAIL").total == 1,
  "two cards swapped in the row: both back in their slots (new cards): " .. row_str())
step(10)
check(row_str() == "LIGHT_BULLET#-1 ACID_TRAIL#-1", "and they stay that way: " .. row_str())

-- pressed again straight away, before the game has moved the card: nothing lost
card = row()[2].e
press_on(2); mouse_down = false; step(); hover_none(); mouse_down = true; set_parent(card, 0); step(8)
mouse_down = false; step(4)
check(not group("ACID_TRAIL", -1) and where("ACID_TRAIL").ground == 1, "thrown, then a quick click: one copy on the ground")
print("\nall checks passed")
