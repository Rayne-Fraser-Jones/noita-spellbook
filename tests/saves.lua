-- Saving and loading: groups and the selected page. Cards shown in the row when the game was
-- saved aren't counted twice. A spell refresher refills limited-use groups, combining them
-- with full ones.
dofile("tests/stubs.lua")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
globals["spellbank2_stacks"] = "BOMB#3=4;DAMAGE#-1=1"
step()
check(group("BOMB", 3).count == 4 and group("DAMAGE", -1).count == 1, "loaded: " .. globals["spellbank2_stacks"])

-- saved with the inventory open, then loaded
inventory_open = true; step(3)
click = { match = "Projectile modifiers" }; step(3)
check(row_str() == "DAMAGE#-1" and globals["spellbank2_selected"] == "2:1", "Modifiers 1 shown; the selection is saved")
SB.groups, SB.selected = {}, nil
SB.prepare(PLAYER); step(3)
check(group("BOMB", 3).count == 4 and group("DAMAGE", -1).count == 1 and where("DAMAGE").total == 1,
  "loaded: the card that was in the row isn't counted twice")
check(SB.selected == "2:1" and row_str() == "DAMAGE#-1", "the selected page comes back")

-- seen in play: a Spark bolt and an Unstable crystal, one copy each, both shown in the row; after
-- a save and load both were gone (the row's cards, killed while loading, are still listed by the
-- game until the end of the frame, and were taken for cards left on the cursor). Here a Spark
-- bolt and a 2-use Bomb
click = { match = "Projectiles" }; step(3)
SB.relayout(PLAYER, function()
  for _, g in pairs(SB.groups) do SB.change_count(g, -g.count) end
  SB.add("LIGHT_BULLET", -1, 1); SB.add("BOMB", 2, 1)
end); step(3)
check(row_str() == "LIGHT_BULLET#-1 BOMB#2", "one Spark bolt and one Bomb shown: " .. row_str())
for load = 1, 2 do
  SB.save(); SB.groups, SB.selected = {}, nil
  SB.prepare(PLAYER); step(3)
  check(globals["spellbank2_stacks"] == "BOMB#2=1;LIGHT_BULLET#-1=1" and row_str() == "LIGHT_BULLET#-1 BOMB#2"
    and where("LIGHT_BULLET").total == 1 and where("BOMB").total == 1,
    "loaded (" .. load .. "): one copy of each still, shown, counted once: " .. globals["spellbank2_stacks"])
end
SB.relayout(PLAYER, function()
  for _, g in pairs(SB.groups) do SB.change_count(g, -g.count) end
  SB.add("BOMB", 3, 4); SB.add("DAMAGE", -1, 1)
end); step(3)

-- spell refresher, during a drag: waits for the button
SB.relayout(PLAYER, function() SB.add("BOMB", 1, 2); SB.add("BOMB", -1, 1) end)
click = { match = "Projectiles" }; step(3)
local held = row()[1].e
press_on(1)
globals["spellbank_refresh_request"] = "r1"; step(3)
check(not ents[held].dead and group("BOMB", 1), "refresher during a drag: nothing changes yet")
mouse_down = false; hover_none(); step(4)
check(not group("BOMB", 1) and group("BOMB", 3).count == 6 and group("BOMB", -1).count == 1,
  "after the release: refilled and combined; unlimited stays unlimited")
check(where("BOMB").total == 7, "every copy counted once")
print("\nall checks passed")
