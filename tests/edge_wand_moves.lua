-- Edge cases moving spells between wands and the spellbook (found by the review):
--   * a click on a wand spell, then a drag of it soon after (to another slot): a move, not a
--     double-click; and a drag, then a click: not a double-click either;
--   * one of the spellbook's cards moved into an empty wand slot without the press on it being
--     seen (the mouse reached it in the same frame, or a gamepad): one copy goes into the wand.
--     Only a wand spell arriving in the card's slot at the same time makes it a swap (the
--     spellbook's card is then taken back out).
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
add_comp(WAND, "AbilityComponent", { ["gun_config.deck_capacity"] = 10 })
add_comp(WAND, "ItemComponent", { inventory_slot = { 0, 0 } })
effects.EDIT_WANDS_EVERYWHERE = 1
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
local function at_wand_slot(slot) mouse_at_ui(26 + (slot - 1) * 20 + 9, 81 + 9) end
step()
SB.add("SPLITTER", -1, 3)
inventory_open = true; step(3)

-- a click, then a drag to slot 6
local w = in_wand("DAMAGE", -1, 2); step()
hover_none(); at_wand_slot(3); step()
mouse_down = true; step(); mouse_down = false; step(3)
mouse_down = true; step()
for i = 1, 10 do mouse_at_ui(26 + 2 * 20 + 9 + i * 6, 90); step() end
set_slot(w, 6); mouse_down = false; step(4)
check(not ents[w].dead and EntityGetParent(w) == WAND and not group("DAMAGE", -1), "a click, then a drag to another slot: moved, not stored")

-- a drag, then a click on it at its new place: not a double-click
at_wand_slot(6); step()
mouse_down = true; step(); at_wand_slot(4); step(); set_slot(w, 4); mouse_down = false; step(3)
at_wand_slot(4); step(); mouse_down = true; step(); mouse_down = false; step(4)
check(not ents[w].dead and EntityGetParent(w) == WAND and not group("DAMAGE", -1), "a drag, then one click: not a double-click")
-- (two clicks still are)
mouse_down = true; step(); mouse_down = false; step(3); mouse_down = true; step(); mouse_down = false; step(4)
check(ents[w].dead and group("DAMAGE", -1), "two clicks: a double-click, stored")

-- a double-click whose release comes on a frame with no player entity (the spellbook doesn't
-- run then): the release is still seen on the next frame, and the spell stored
local w2 = in_wand("ACID_TRAIL", -1, 2); step()
hover_none(); at_wand_slot(3); step()
mouse_down = true; step(); mouse_down = false; step(3); mouse_down = true; step()
local me = PLAYER; PLAYER = nil; mouse_down = false; step(); PLAYER = me
step(4)
check(ents[w2].dead and group("ACID_TRAIL", -1), "released on a frame without a player: still a double-click, stored")

-- one of the spellbook's cards moved into an empty wand slot, the press on it not seen
click = { match = "Projectiles" }; step(3)
local sp = group("SPLITTER", -1)
local card; for _, c in pairs(row()) do if c.id == "SPLITTER" then card = c.e end end
hover_none(); step(); mouse_down = true; step()
set_parent(card, WAND); set_slot(card, 1); mouse_down = false; step(4)
check(wand_cards()[1] and wand_cards()[1].id == "SPLITTER" and sp.count == 2 and where("SPLITTER").total == 3,
  "a card moved into an empty wand slot, its press not seen: one copy in the wand, 2 left")

-- the same with no mouse button at all (a gamepad)
for _, c in pairs(row()) do if c.id == "SPLITTER" then card = c.e end end
set_parent(card, WAND); set_slot(card, 2); step(4)
check(wand_cards()[2] and wand_cards()[2].id == "SPLITTER" and sp.count == 1 and where("SPLITTER").total == 3,
  "moved with no mouse button (a gamepad): one more in the wand, 1 left")
print("\nall checks passed")
