-- Groups: every copy of one spell with one exact number of uses left is in one group, however it
-- arrives (picked up, from a wand, back from the ground), and a copy whose uses change moves to
-- the group for its new uses. Unlimited copies (-1) of a limited spell are a group of their own.
-- On a page, all the groups of a spell share one slot: it shows the copy first by uses left,
-- and counts every copy.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()

-- picked up with the inventory closed
world_pickup("BOMB", 3); step(); world_pickup("BOMB", 3); step(); world_pickup("BOMB", 2); step()
check(group("BOMB", 3).count == 2 and group("BOMB", 2).count == 1 and #groups_of("BOMB") == 2, "pickups: 3, 3, 2 uses: two groups (2 and 1)")

inventory_open = true; step(3)
check(row_str() == "BOMB#3" and find_count("^3$"), "the row: one slot for Bomb, showing a 3-use copy, counting all 3: " .. row_str())

-- a copy with 2 uses from a wand joins its group, wherever it is dropped
local w = in_wand("BOMB", 2, 0); step()
press_on(5); mouse_down = false; set_parent(w, INV_FULL); set_slot(w, 9); step(6)
check(group("BOMB", 2).count == 2 and #groups_of("BOMB") == 2, "from a wand with 2 uses: joins the group of 2 (now 2)")

-- picked up with the inventory open (the game puts it in a free slot first)
world_pickup("BOMB", 3); step(6)
check(group("BOMB", 3).count == 3 and row_str() == "BOMB#3" and find_count("^5$"), "picked up with the inventory open: the group of 3 uses is now 3, 5 Bombs in all: " .. row_str())

-- a copy goes into a wand, is used once there, and comes back with 1 use: a new group
local card = row()[1].e
press_on(1); set_parent(card, WAND); set_slot(card, 1); mouse_down = false; step(4)
check(group("BOMB", 3).count == 2, "one copy with 3 uses into the wand")
set_uses(card, 1)
press_on(6); mouse_down = false; set_parent(card, INV_FULL); set_slot(card, 12); step(6)
check(group("BOMB", 1).count == 1 and group("BOMB", 3).count == 2 and row_str() == "BOMB#3", "back with 1 use: a group of its own, in the same slot: " .. row_str())

-- a card in the row whose uses change there (as the game's refill would): it moves group
local c3 = row()[1].e
set_uses(c3, 2); step(6)
check(group("BOMB", 3).count == 1 and group("BOMB", 2).count == 3, "a card's uses changed in the row: moved from the group of 3 to the group of 2")

-- thrown and picked up again: the same group (fewest uses first, so the slot shows the 1-use copy)
settings["spellbook.uses_order"] = "fewest"; step(4)
card = row()[1].e
check(row()[1].uses == 1, "fewest uses first: the slot shows the 1-use copy")
press_on(1); set_parent(card, 0); mouse_down = false; step(4)
check(not group("BOMB", 1) and where("BOMB").ground == 1, "the 1-use copy thrown: its group is gone")
inventory_open = false; step(2)
set_parent(card, INV_FULL); set_slot(card, 1); step(2)
check(group("BOMB", 1).count == 1 and where("BOMB").ground == 0, "picked up again: back in a group of 1 use")
settings["spellbook.uses_order"] = nil

-- unlimited copies of a limited spell (Unlimited Spells perk): a group of their own, first
world_pickup("BOMB", -1); step()
check(group("BOMB", -1).count == 1 and page_str("0:1") == "BOMB#-1" and #groups_of("BOMB") == 4, "an unlimited copy: a group of its own, the one the slot shows (unlimited counts as the most uses): " .. page_str("0:1"))
check(where("BOMB").total == 6 and group("BOMB", 3).count == 1 and group("BOMB", 2).count == 3, "every copy counted once: " .. where("BOMB").total)
print("\nall checks passed")
