-- Picked-up spells are stored with their group (same spell, same uses), and the page they are
-- on is selected. With the inventory open, the game puts a picked-up spell in the row first.
dofile("tests/stubs.lua")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
world_pickup("DAMAGE", -1); step()
check(group("DAMAGE", -1).count == 1 and row_str() == "", "picked up with the inventory closed: stored, the row stays empty")
check(SB.selected == "2:1" and printed[#printed] == "Spellbook: damage stored (Projectile modifiers 1)", "its page is selected; message: " .. printed[#printed])
world_pickup("DAMAGE", -1); world_pickup("BOMB", 3); world_pickup("BOMB", 1); step()
check(group("DAMAGE", -1).count == 2 and group("BOMB", 3).count == 1 and group("BOMB", 1).count == 1, "same uses: one group; different uses: two")
check(SB.selected == "0:1", "the last pickup's page is selected")

inventory_open = true; step(3)
check(row_str() == "BOMB#3" and find_count("^2$"), "opening the inventory shows the selected page, Bomb in one slot (2 copies): " .. row_str())
click = { match = "Projectile modifiers" }; step(3)
world_pickup("SPLITTER", -1); step(4)
check(group("SPLITTER", -1) and where("SPLITTER").total == 1 and SB.selected == "0:1" and row_str() == "BOMB#3 SPLITTER#-1",
  "picked up with the inventory open: stored, its page selected and shown: " .. row_str())
print("\nall checks passed")
