-- A new player entity (as after polymorph and back) takes over the row without counting the
-- spellbook's cards again.
dofile("tests/stubs.lua")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("BOMB", 3, 3)
inventory_open = true; step(3)
local np = new_entity("player")
add_comp(np, "Inventory2Component", { full_inventory_slots_x = 16, full_inventory_slots_y = 1 })
add_comp(np, "ControlsComponent", { enabled = true })
new_entity("inventory_quick", np)
local nfull = new_entity("inventory_full", np)
for _, c in ipairs(EntityGetAllChildren(INV_FULL) or {}) do
  local id, u, x = card_info(c)
  local copy = make_card(id, u); set_parent(copy, nfull)
  comps[EntityGetFirstComponentIncludingDisabled(copy, "ItemComponent")].f.inventory_slot = { x, 0 }
  for _, comp in ipairs(ents[c].comps) do
    if comps[comp].type == "VariableStorageComponent" then add_comp(copy, "VariableStorageComponent", { name = comps[comp].f.name }) end
  end
end
EntityKill(PLAYER); for _, c in ipairs(EntityGetAllChildren(INV_FULL) or {}) do EntityKill(c) end
PLAYER, INV_FULL = np, nfull
step(4)
check(group("BOMB", 3).count == 3 and row_str() == "BOMB#3", "new player entity: still 3 Bombs, shown in the row")
print("\nall checks passed")
