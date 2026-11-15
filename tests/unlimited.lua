-- The Unlimited spells perk: the game makes the cards the player has unlimited (uses -1), the
-- spell row's too, except spells it marks never_unlimited. The spellbook's other copies are
-- counts, so once the perk is taken (perk_infinite_spells in the world state), every group with
-- uses left of a spell the perk affects is combined into the spell's unlimited group, and so are
-- limited copies stored later. The row is refilled, but not while a mouse button is held. The
-- spell refresher then leaves those spells alone.
dofile("tests/stubs.lua")
EXTRA_ACTIONS = {
  { id = "NEVER", name = "Never unlimited", sprite = "never.png", type = 0, max_uses = 5, never_unlimited = true },
}
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("BOMB", 3, 2); SB.add("BOMB", 1, 1); SB.add("NEVER", 2, 1); SB.add("LIGHT_BULLET", -1, 1)
SB.add("GONE_MOD_SPELL", 2, 1)   -- from a mod that isn't loaded: left alone
inventory_open = true; step(3)
check(row_str() == "LIGHT_BULLET#-1 BOMB#3 NEVER#2", "before: " .. row_str())
local selected = SB.selected

-- the perk taken while a mouse button is held: nothing yet
mouse_down = true
comps[WORLD_STATE].f.perk_infinite_spells = true
-- (the game makes the row's Bomb card unlimited)
set_uses(row()[2].e, -1)
step(4)
check(group("BOMB", 3) and group("BOMB", 3).count == 2, "a button held: the groups wait")
mouse_down = false; step(4)

check(not group("BOMB", 3) and not group("BOMB", 1) and group("BOMB", -1) and group("BOMB", -1).count == 3,
  "let go: the Bomb groups combined into one unlimited group of 3")
check(group("NEVER", 2) and group("NEVER", 2).count == 1 and not group("NEVER", -1), "a never_unlimited spell keeps its uses")
check(group("GONE_MOD_SPELL", 2) and group("GONE_MOD_SPELL", 2).count == 1, "a spell from a mod that isn't loaded is left alone")
check(row_str() == "LIGHT_BULLET#-1 BOMB#-1 NEVER#2" and find_count("^3$"), "the row: an unlimited Bomb, counting 3: " .. row_str())
check(where("BOMB").total == 3 and where("NEVER").total == 1 and where("LIGHT_BULLET").total == 1, "every copy counted once")
check(SB.selected == selected, "the selected page stays")
local n = 0; for _ in pairs(SB.groups) do n = n + 1 end
step(10)
local n2 = 0; for _ in pairs(SB.groups) do n2 = n2 + 1 end
check(n == n2 and group("BOMB", -1).count == 3, "and it stays that way (nothing done again every frame)")

-- a limited copy stored later (picked up with the inventory closed): unlimited too
inventory_open = false; step(2)
world_pickup("BOMB", 2); step(4)
check(not group("BOMB", 2) and group("BOMB", -1).count == 4 and where("BOMB").total == 4, "a 2-use Bomb picked up: into the unlimited group (4)")

-- the spell refresher: the never_unlimited spell is refilled; Bomb stays unlimited
globals["spellbank_refresh_request"] = "r1"; step(4)
check(group("NEVER", 5) and not group("NEVER", 2) and group("BOMB", -1).count == 4 and not group("BOMB", 3),
  "the refresher: Never unlimited refilled to 5, Bomb still unlimited")

-- saved and loaded with the perk: still unlimited
SB.save()
check(globals["spellbank2_stacks"]:find("BOMB#%-1=4"), "saved: " .. globals["spellbank2_stacks"])
print("\nall checks passed")
