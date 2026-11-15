-- The Unlimited spells perk taken with the inventory closed (as it always is in play): the
-- groups are made unlimited, but the row stays empty while the inventory is closed. A spell
-- refresher picked up then (the same Holy Mountain) must not make a copy out of nothing.
-- (Found by the review: the row was refilled while closed, and a refresher then stored a
-- never_unlimited card in it a second time.)
dofile("tests/stubs.lua")
EXTRA_ACTIONS = {
  { id = "NEVER", name = "Never unlimited", sprite = "never.png", type = 0, max_uses = 5, never_unlimited = true },
}
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("BOMB", 3, 1); SB.add("NEVER", 2, 1)
inventory_open = true; step(3)
inventory_open = false; step(3)
check(row_str() == "", "the inventory closed: the row is empty")

comps[WORLD_STATE].f.perk_infinite_spells = true; step(3)
check(group("BOMB", -1) and not group("BOMB", 3), "the perk taken: Bomb made unlimited")
check(row_str() == "", "and the row is still empty while the inventory is closed: " .. row_str())

globals["spellbank_refresh_request"] = "r1"; step(3)
inventory_open = true; step(4)
check(group("NEVER", 5) and where("NEVER").total == 1, "a refresher, then the inventory opened: still one Never unlimited (" .. where("NEVER").total .. ")")
check(where("BOMB").total == 1, "and one Bomb")
print("\nall checks passed")
