-- Each line of the page list starts with a card, as the inventory draws one: the type's card
-- background (20 x 20) with the icon of a spell typical of the type (16 x 16, 2 in). The
-- Copies line shows the spell whose copies are open; the Search line has a magnifying glass on
-- the inventory's empty slot box. Lines are 20 apart (4 between the cards' pictures); beside the
-- card, the type's name and under it its page numbers, from 1; with only one page, just the name,
-- centred on the card. The card, the name and the "1"
-- are one button for the line's first page: any of them under the mouse lights up all three,
-- for the selected page they are gold, each has the page's tooltip, and a click on any selects it.
dofile("tests/stubs.lua")
EXTRA_ACTIONS = {
  { id = "EXPLOSION", name = "Explosion", sprite = "explosion.png", type = 1 },
  { id = "HOMING", name = "Homing", sprite = "homing.png", type = 2 },
  { id = "BURST_2", name = "Double spell", sprite = "burst_2.png", type = 3 },
  { id = "MATERIAL_WATER", name = "Water", sprite = "material_water.png", type = 4 },
  { id = "ALPHA", name = "Alpha", sprite = "alpha.png", type = 5 },
  { id = "LONG_DISTANCE_CAST", name = "Long-distance cast", sprite = "long_distance_cast.png", type = 6 },
  { id = "ENERGY_SHIELD", name = "Energy shield", sprite = "energy_shield.png", type = 7 },
}
-- 14 more projectiles: with unowned spells shown, more than 16, two pages
for i = 1, 14 do EXTRA_ACTIONS[#EXTRA_ACTIONS + 1] = { id = "P" .. i, name = "p" .. i, sprite = "p.png", type = 0 } end
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("BOMB", 3, 1); SB.add("DAMAGE", -1, 1)
settings["spellbook.hide_unowned"] = false
inventory_open = true; step(3)

local function image(id) for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] == id then return w end end end
local BG = "data/ui_gfx/inventory/item_bg_"
local expect = {
  [0] = { "lb.png", "projectile", "Projectiles" }, { "explosion.png", "static_projectile", "Static projectiles" }, { "homing.png", "modifier", "Projectile modifiers" },
  { "burst_2.png", "draw_many", "Multicasts" }, { "material_water.png", "material", "Materials" }, { "alpha.png", "other", "Other" },
  { "long_distance_cast.png", "utility", "Utility" }, { "energy_shield.png", "passive", "Passives" },
}
local first_y
for t = 0, 7 do
  local card, icon, name = image(400 + t), image(420 + t), find("button", expect[t][3])
  first_y = first_y or (card and card[4])
  check(card and icon and name and card[2] == BG .. expect[t][2] .. ".png" and icon[2] == expect[t][1]
    and icon[3] == card[3] + 2 and icon[4] == card[4] + 2 and card[4] == first_y + 20 * t
    and name[3] == card[3] + 21 and name[4] == card[4] + (t == 0 and 0 or 5),
    expect[t][3] .. ": " .. expect[t][1] .. " on its card background, 20 below the line above, the name beside it"
      .. (t == 0 and " at its top (two pages: the numbers under it)" or ", centred (one page: no numbers)"))
  if t > 0 then
    local nums = 0
    for _, w in ipairs(gui_log) do if w[1] == "button" and w[4] == card[4] + 9 then nums = nums + 1 end end
    check(nums == 0, "  no \"1\" under it")
  end
end

-- the Copies line: the spell whose copies are open; the Search line: a magnifying glass on the
-- inventory's empty slot box
SB.show_copies(PLAYER, "BOMB"); step(4)
local card, icon = image(409), image(429)
check(card and icon and icon[2] == "bomb.png" and card[2] == BG .. "projectile.png"
  and icon[3] == card[3] + 2 and icon[4] == card[4] + 2, "Copies: the Bomb, on its card background")
SB.set_search(PLAYER, "o"); step(3)
card, icon = image(408), image(428)
check(find("button", "Search") and card and icon and icon[2] == "mods/spellbook/files/search_icon.png" and card[2] == "data/ui_gfx/inventory/full_inventory_box.png",
  "Search: a magnifying glass, on the inventory's empty slot box")
local search_line = find("button", "Search")
check(search_line[3] == card[3] + 21 and search_line[4] == card[4] + 5, "the name beside it, centred (one page), as on the other lines")

-- the page numbers under the name, from 1
SB.set_search(PLAYER, ""); step(3)
local function on_line(label)   -- the buttons on the line under a name, left to right
  local y, list = find("button", label)[4] + 9, {}
  for _, w in ipairs(gui_log) do if w[1] == "button" and w[4] == y then list[#list + 1] = w end end
  table.sort(list, function(a, b) return a[3] < b[3] end)
  return list, find("button", label)
end
local nums, name = on_line("Projectiles")
local labels = {}; for i, w in ipairs(nums) do labels[i] = w[2] end
check(table.concat(labels, " ") == "1 2" and nums[1][3] == name[3], "Projectiles: \"1 2\" under its name, starting where it starts: " .. table.concat(labels, " "))

-- the first page's button: the card, the name and the "1"
local function col(w) return w and w.color and table.concat(w.color, ",") or "none" end
local GOLD_C, DIM_C, VIEW_C, WHITE_C = "1,0.85,0.4", "0.6,0.6,0.6", "1,1,0.7", "1,1,1"
local function parts(label) local n, nm = on_line(label); return nm, n[1] end
click = { match = "Static projectiles" }; step(3)
local nm, one = parts("Projectiles")
check(col(nm) == DIM_C and col(one) == DIM_C, "Projectiles 1 not selected: its name and 1 dark grey")
local cardb; for _, w in ipairs(gui_log) do if w[1] == "imagebutton" and w[5] == 620 then cardb = w end end
check(cardb and cardb[2] == HB and cardb[3] == image(400)[3] + 1 and cardb[4] == image(400)[4] + 1, "a button over the card's picture")
hover_label, hover_xy = HB, { cardb[3], cardb[4] }; step(2)
nm, one = parts("Projectiles")
check(col(nm) == VIEW_C and col(one) == VIEW_C and SB.hover_target == "0:1", "the card under the mouse: the name and 1 in the hover yellow, the page looked at")
hover_name("Projectiles"); step(2)
nm, one = parts("Projectiles")
check(col(nm) == WHITE_C and col(one) == VIEW_C, "the name under the mouse: it lights up (the game's yellow over white), and the 1 too")
hover_none(); step(2)
local tips = 0; for _, w in ipairs(gui_log) do if w[1] == "tooltip" and w[2] == "View page: Projectiles 1" then tips = tips + 1 end end
check(tips == 1, "the tooltip on the card only, none on the name (it would cover the cards) or the 1 (" .. tips .. ")")
click = { match = HB }; step(3)
nm, one = parts("Projectiles")
check(SB.selected == "0:1" and col(nm) == GOLD_C and col(one) == GOLD_C, "the card clicked: Projectiles 1 selected, its name and 1 gold")
click = { match = "Static projectiles" }; step(3)
click = { match = "1" }; step(3)
check(SB.selected == "0:1", "the 1 clicked: selected")
click = { match = "2" }; step(3)
nm, one = parts("Projectiles")
check(SB.selected == "0:2" and col(nm) == GOLD_C and col(one) == DIM_C and col(find("button", "2")) == GOLD_C, "the 2 clicked: page 2 gold, and the line's name (it stands for the line); the 1 dark grey")

-- the search box as wide as the panel inside
local box, panel = find("input"), find("panel")
check(box.w == panel[4] - 4 and box.x == panel[2] + 2, "the search box as wide as the window inside (" .. box.w .. ")")
print("\nall checks passed")
