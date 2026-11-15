-- Edge cases around the player entity being replaced (polymorph and back) and loading (found by
-- the review):
--   * polymorphed while the search box has the keyboard: the player's controls must come back
--     on the restored player, whose stored copy still has them off;
--   * one of the spellbook's cards inside a wand when the game is saved or the player is
--     replaced (a swap not yet worked out): its copy is the wand's now, so it is taken off its
--     group, not counted twice;
--   * a spell refresher picked up during a drag (it waits for the button) and the game saved
--     before it was done: it is done after loading.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("BOMB", 3, 2)
inventory_open = true; step(3)

-- a new player entity, as the game makes after polymorph (controls as given)
local function new_player(controls_on)
  local np = new_entity("player")
  add_comp(np, "Inventory2Component", { full_inventory_slots_x = 16, full_inventory_slots_y = 1 })
  local cc = add_comp(np, "ControlsComponent", { enabled = controls_on })
  local quick = new_entity("inventory_quick", np)
  local full = new_entity("inventory_full", np)
  return np, cc, full, quick
end

-- typing in the search box, then polymorphed into a sheep, then back
local b = find("input")
hover_label, hover_xy = HB, { b.x, b.y }; step(); mouse_down = true; step(); mouse_down = false; hover_none(); step()
check(comps[CONTROLS].f.enabled == false, "typing in the search box: controls off")
local sheep = new_entity("sheep")
local sheep_cc = add_comp(sheep, "ControlsComponent", { enabled = true })
for _, c in ipairs(EntityGetAllChildren(INV_FULL) or {}) do EntityKill(c) end
PLAYER = sheep; step(3)
local human, human_cc, hfull = new_player(false)   -- (its stored copy: controls still off)
PLAYER, INV_FULL = human, hfull; step(3)
check(comps[human_cc].f.enabled == true, "back from the sheep: the restored player's controls are on")
check(group("BOMB", 3).count == 2 and where("BOMB").total == 2, "the Bombs still counted once")

-- one of the spellbook's cards in a wand (a swap not yet worked out) when the game is saved
inventory_open = true; step(3)
local w = new_entity("wand", EntityGetAllChildren(human)[1]); add_tag(w, "wand")
WAND = w
local rep = row()[1].e
set_parent(rep, w); set_slot(rep, 1)
SB.save()
SB.groups = {}
SB.prepare(PLAYER); step(3)
check(where("BOMB").total == 2 and #wand_cards(w) == 1 and group("BOMB", 3).count == 1,
  "loaded with one in a wand: 1 in the spellbook, 1 in the wand (" .. where("BOMB").total .. " in all)")
-- a refresher waiting for the button when the game is saved
SB.add("BOMB", 1, 1); click = { match = "Projectiles" }; step(3)
local before = where("BOMB").total
press_on(1)
globals["spellbank_refresh_request"] = "r1"; step(2)
check(group("BOMB", 1), "a refresher during a drag: it waits")
SB.save(); SB.groups = {}
SB.prepare(PLAYER); mouse_down = false; hover_none(); step(4)
check(not group("BOMB", 1) and group("BOMB", 3) and where("BOMB").total == before, "loaded: the refresher is done, the Bombs refilled (" .. where("BOMB").total .. ")")
print("\nall checks passed")
