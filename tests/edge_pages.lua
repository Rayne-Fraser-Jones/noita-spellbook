-- Edge cases in the pages (found by the review):
--   * copies pages open, and a spell stored selects another page: the copies pages close (as
--     when another page is clicked);
--   * a copies page selected, and a copy of that spell stored: the page with the new copy is
--     selected, so it is in view;
--   * "< 1/25 >" on a line whose page isn't selected: "<" is dark grey and not a button (it
--     would lead to the page 1 it already shows);
--   * a spell unlocked during the run, with unowned spells shown: its placeholder appears.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
-- 400 spells named "q...", for a search with too many pages for numbers
EXTRA_ACTIONS = {}
for i = 1, 400 do EXTRA_ACTIONS[i] = { id = "Q" .. i, name = "q" .. i, sprite = "q.png", type = 6 } end
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("BOMB", 3, 16); SB.add("BOMB", 1, 2); SB.add("SPLITTER", -1, 1)
inventory_open = true; step(3)

-- copies of Bomb: 18, on two pages; page 2 selected, a 3-use Bomb stored: page 1 (where the
-- 3-use copies are) is selected
SB.show_copies(PLAYER, "BOMB"); step(4)
click = { match = "2" }; step(4)
check(SB.selected == "9:2", "copies of Bomb, page 2")
local b = in_wand("BOMB", 3, 0); step()
set_parent(b, INV_FULL); set_slot(b, 3); step(4)
check(SB.copies_of == "BOMB" and SB.selected == "9:1" and where("BOMB").total == 19, "a 3-use Bomb stored: copies page 1, which has the 3-use copies: " .. SB.selected)

-- copies of Bomb open, a Damage stored: its page, and the copies pages close
local d = in_wand("DAMAGE", -1, 0); step()
set_parent(d, INV_FULL); set_slot(d, 4); step(4)
check(SB.selected == "2:1" and not SB.copies_of and not find("button", "Copies"), "a Damage stored: its page selected, the copies pages closed")

-- a search with 25 pages, its line not selected: "<" dark grey, not a button
SB.set_hide_unowned(PLAYER, false); SB.set_search(PLAYER, "q"); step(3)
click = { match = "Projectiles" }; step(3)
check(find("button", "Search") and SB.selected == "0:1" and #SB.layout().by_type[8] >= 25, "a search with many pages, Projectiles 1 selected")
check(not find("button", "<") and find("text", "<") and find("button", ">"), "on its line: \"<\" dark grey and not a button, \">\" a button")
SB.set_search(PLAYER, ""); step(3)

-- a spell unlocked during the run (unowned spells shown, Show locked off): its placeholder appears
check(not page_str("0:1"):find("NUKE"), "Nuke not unlocked: no placeholder")
persistent_flags["card_unlocked_nuke"] = true; step(3)
check(page_str("0:1"):find("%-NUKE"), "unlocked: its placeholder appears: " .. page_str("0:1"))
print("\nall checks passed")
