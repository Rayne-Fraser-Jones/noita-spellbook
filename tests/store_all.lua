-- Store all: Held wand stores every spell in the selected wand, All wands every spell in
-- all the wands; always-cast spells stay. They only work where wands can be edited: the level
-- (a Holy Mountain counts 1, each EDIT_WANDS_EVERYWHERE effect +1, each NO_WAND_EDITING effect
-- -1) must be above 0. Otherwise, or with nothing to take, they are grey text, not buttons, and
-- the tooltip says why.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
add_comp(WAND, "AbilityComponent", { ["gun_config.deck_capacity"] = 26 })
add_comp(WAND, "ItemComponent", { inventory_slot = { 0, 0 } })
local WAND2 = new_entity("wand2", INV_QUICK)
add_tag(WAND2, "wand")
add_comp(WAND2, "AbilityComponent", { ["gun_config.deck_capacity"] = 10 })
add_comp(WAND2, "ItemComponent", { inventory_slot = { 1, 0 } })
comps[EntityGetFirstComponentIncludingDisabled(PLAYER, "Inventory2Component")].f.mActiveItem = WAND
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
local always = in_wand("TELEPORT_PROJECTILE", -1, 0)
comps[EntityGetFirstComponentIncludingDisabled(always, "ItemComponent")].f.permanently_attached = true
in_wand("LIGHT_BULLET", -1, 0); in_wand("LIGHT_BULLET", -1, 1); in_wand("BOMB", 2, 3); in_wand("DAMAGE", -1, 17)
local in2 = make_card("SPLITTER", -1); set_parent(in2, WAND2)
inventory_open = true; step(3)

local function col(w) return w and w.color and table.concat(w.color, ",") or "none" end
-- the buttons' tooltips: what they do on the first line; why not, under it, while greyed out
local TIPS = { ["Held wand"] = "Store every spell in your held wand",
  ["All wands"] = "Store every spell in all your wands" }
local function greyed(label, why)
  local t = find("text", label)
  return t ~= nil and col(t) == "0.6,0.6,0.6" and not find("button", label) and find_tip(TIPS[label], why) ~= nil
end
local function usable(label) local b = find("button", label); return b ~= nil and col(b) == "1,1,1" end

-- outside a Holy Mountain: greyed out, and nothing happens
check(greyed("Held wand", "^You cannot tinker with wands here$") and greyed("All wands", "^You cannot tinker with wands here$"),
  "outside a Holy Mountain: both grey text, the tooltip says why: \"You cannot tinker with wands here\"")
check(col(find("text", "Store all: ")) == "0.8,0.8,0.8" and col(find("text", " / ")) == "0.8,0.8,0.8", "\"Store all: Held wand / All wands\", \"Store all:\" and \"/\" the grey of SPELLS")
SB.from_wands(PLAYER, "held"); step(3)
check(#(EntityGetAllChildren(WAND) or {}) == 5 and printed[#printed]:find("Holy Mountain"), "used anyway: nothing taken, a message says why")

-- the level: Tinker with Wands Everywhere and No wand editing cancel out
effects.EDIT_WANDS_EVERYWHERE, effects.NO_WAND_EDITING = 1, 1; step()
check(greyed("Held wand", "^You cannot tinker with wands here$"), "both perks, outside a Holy Mountain: level 0, blocked by No Wand Tinkering")
local hm = new_entity("workshop"); add_tag(hm, "workshop_aabb")
add_comp(hm, "HitboxComponent", { aabb_min_x = -50, aabb_max_x = 50, aabb_min_y = -50, aabb_max_y = 50 })
step()
check(usable("Held wand") and usable("All wands") and find_tip(TIPS["Held wand"], "^$") and find_tip(TIPS["All wands"], "^$"),
  "both perks, in a Holy Mountain: level 1, the buttons work (white); their tooltips one line each")
effects.EDIT_WANDS_EVERYWHERE = nil; step()
check(greyed("Held wand", "^You cannot tinker with wands here$"), "only No wand editing, in a Holy Mountain: level 0, blocked")
EntityKill(hm); effects.NO_WAND_EDITING = nil
effects.EDIT_WANDS_EVERYWHERE = 2; step()
check(usable("Held wand"), "Tinker with Wands Everywhere from two sources: level 2")
effects.EDIT_WANDS_EVERYWHERE = 1; step()

-- Held wand
click = { match = "Held wand" }; step(3)
check(group("LIGHT_BULLET", -1).count == 2 and group("BOMB", 2).count == 1 and group("DAMAGE", -1).count == 1, "the wand's spells are stored, the same ones combined")
local left = EntityGetAllChildren(WAND) or {}
check(#left == 1 and left[1] == always, "the always-cast spell stays in the wand")
check(EntityGetParent(in2) == WAND2, "the other wand is left alone")
check(printed[#printed] == "Spellbook: stored 4 spells from your held wand", "message: " .. tostring(printed[#printed]))
check(SB.selected == "0:1" and row_str() == "LIGHT_BULLET#-1 BOMB#2", "the selected page stays; the row: " .. row_str())
check(greyed("Held wand", "^Your held wand has no spells to store$") and usable("All wands"), "now the current wand is empty: greyed out; All wands still works")

-- All wands
in_wand("ACID_TRAIL", -1, 2); step()
click = { match = "All wands" }; step(3)
check(group("SPLITTER", -1) and group("ACID_TRAIL", -1) and not EntityGetAllChildren(WAND2), "All wands: every wand's spells stored")
check(printed[#printed] == "Spellbook: stored 2 spells from your wands", "message: " .. tostring(printed[#printed]))
check(greyed("All wands", "^Your wands have no spells to store$"), "all empty: greyed out")
check(where("LIGHT_BULLET").total == 2 and where("SPLITTER").total == 1, "every copy counted once")

-- no wand selected
comps[EntityGetFirstComponentIncludingDisabled(PLAYER, "Inventory2Component")].f.mActiveItem = 0; step()
check(greyed("Held wand", "Select a wand"), "no wand selected: greyed out, select a wand")
check(not find("button", "From wand"), "the old button is gone")
print("\nall checks passed")
