-- A wand spell dragged into the spell row is stored, wherever it is dropped, and the page it
-- is on is selected, so it stays in view. Dropped onto one of the spellbook's cards, the game swaps
-- the two; the spellbook takes its card back out of the wand. A spellbook card dragged onto a wand spell
-- is a swap the player meant: one copy goes into the wand, the wand's spell is stored.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
local sp = SB.add("SPLITTER", -1, 2)
inventory_open = true; step(3)
check(SB.selected == "0:1" and row_str() == "SPLITTER#-1", "Projectiles 1 shown")

-- a wand spell dropped into an empty slot: stored, and Modifiers 1 selected
local w = in_wand("DAMAGE", -1, 0)
hover_none(); step(); mouse_down = true; step()
set_parent(w, INV_FULL); set_slot(w, 5); mouse_down = false; step(4)
check(group("DAMAGE", -1) and group("DAMAGE", -1).count == 1 and ents[w].dead and where("DAMAGE").total == 1, "dropped into the row: stored")
check(SB.selected == "2:1" and SB.shown == "2:1" and row_str() == "DAMAGE#-1", "Modifiers 1 is selected and shown: " .. row_str())

-- dropped onto one of the spellbook's cards: the game swaps them; the spellbook's card comes back out
click = { match = "Projectiles" }; step(3)
local rep = row()[1].e
local b = in_wand("BOMB", 3, 0)
hover_none(); step(); mouse_down = true; step()
set_parent(rep, WAND); set_slot(rep, 1); set_parent(b, INV_FULL); set_slot(b, 1); mouse_down = false; step(4)
check(not wand_cards()[1] and sp.count == 2 and where("SPLITTER").total == 2, "the spellbook's card was taken back out of the wand; Splitter still 2")
check(group("BOMB", 3) and where("BOMB").total == 1 and SB.selected == "0:1", "the Bomb is stored, on Projectiles 1")
check(row_str() == "BOMB#3 SPLITTER#-1", "the row: " .. row_str())

-- a spellbook card dragged onto a wand spell: the swap is kept
local d = in_wand("DAMAGE", -1, 0)
rep = row()[2].e
press_on(2)
set_parent(rep, WAND); set_slot(rep, 1); set_parent(d, INV_FULL); set_slot(d, 2); mouse_down = false; step(4)
check(wand_cards()[1] and wand_cards()[1].id == "SPLITTER" and sp.count == 1, "one Splitter went into the wand")
check(group("DAMAGE", -1).count == 2 and where("DAMAGE").total == 2 and SB.selected == "2:1", "the wand's Damage is stored, and its page selected")
check(where("SPLITTER").total == 2, "every copy counted once")
print("\nall checks passed")
