-- Double-clicking a spell in a wand stores it, and selects the page it is on. The spellbook finds
-- the spell under the mouse from the measured wand panels (wands without always-cast spells,
-- with at most 26 slots), and only where the game lets you edit wands.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
add_comp(WAND, "AbilityComponent", { ["gun_config.deck_capacity"] = 10 })
add_comp(WAND, "ItemComponent", { inventory_slot = { 0, 0 } })
effects.EDIT_WANDS_EVERYWHERE = 1
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
local function over_wand_slot(slot) hover_none(); mouse_at_ui(26 + (slot - 1) * 20 + 9, 81 + 9) end
local function clicks(gap)
  mouse_down = true; step(); mouse_down = false; step(gap or 3)
  mouse_down = true; step(); mouse_down = false; step(4)
end
step()
SB.add("SPLITTER", -1, 1)
inventory_open = true; step(3)

local w = in_wand("DAMAGE", -1, 2); step()
over_wand_slot(3); step(); clicks()
check(ents[w].dead and group("DAMAGE", -1) and where("DAMAGE").total == 1, "double-clicked: stored, gone from the wand")
check(SB.selected == "2:1" and SB.shown == "2:1", "and its page, Modifiers 1, selected and shown")

-- two clicks too far apart: nothing
local w2 = in_wand("LIGHT_BULLET", -1, 4); step()
over_wand_slot(5); step(); clicks(40)
check(EntityGetParent(w2) == WAND and not group("LIGHT_BULLET", -1), "two clicks 40 frames apart: not a double-click")

-- a click on one spell, then on another: nothing
local w3 = in_wand("ACID_TRAIL", -1, 5); step(40)
over_wand_slot(5); step(); mouse_down = true; step(); mouse_down = false; step(2)
over_wand_slot(6); step(); mouse_down = true; step(); mouse_down = false; step(4)
check(EntityGetParent(w2) == WAND and EntityGetParent(w3) == WAND, "clicks on two different spells: nothing stored")

-- where wands can't be edited: a message, and the spell stays
effects.EDIT_WANDS_EVERYWHERE = nil; step(40)
over_wand_slot(5); step(); clicks()
check(EntityGetParent(w2) == WAND and printed[#printed]:find("only be edited in a Holy Mountain"), "outside a Holy Mountain: stays, with a message")

-- Tinker with Wands Everywhere and No wand editing cancel out (level 0 outside a Holy Mountain)
effects.EDIT_WANDS_EVERYWHERE, effects.NO_WAND_EDITING = 1, 1; step(40)
over_wand_slot(5); step(); clicks()
check(EntityGetParent(w2) == WAND and printed[#printed]:find("blocked by"), "both perks: stays, with a message")
effects.NO_WAND_EDITING = nil; step(40)
over_wand_slot(5); step(); clicks()
check(ents[w2].dead and group("LIGHT_BULLET", -1), "No wand editing gone: double-click works again")
print("\nall checks passed")
