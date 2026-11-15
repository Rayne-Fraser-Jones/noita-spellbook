-- The page list with a spell list the size of the game's (422 spells), unowned spells shown: every
-- type and its page numbers fit on one line, and the list on the screen.
dofile("tests/stubs.lua")
-- letters 5 wide, digits 6 (with their spacing, measured from screenshots): a little wider than the game's
function GuiGetTextDimensions(g, s) local _, digits = s:gsub("%d", ""); return #s * 5 + digits, 9 end
local real = dofile_once
local counts = { [0] = 125, [1] = 40, [2] = 140, [3] = 20, [4] = 30, [5] = 40, [6] = 30, [7] = 12 }   -- 9 modifier pages, as in play
function dofile_once(p)
  if p:match("gun_actions") then
    actions = {}
    for t = 0, 7 do
      for i = 1, counts[t] do actions[#actions + 1] = { id = "S" .. t .. "_" .. i, name = "s" .. i, sprite = "x.png", type = t } end
    end
  else real(p) end
end
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
settings["spellbook.hide_unowned"] = false
step(); inventory_open = true; step(3)
-- each type: its name, and under it its page numbers, all on one line
local px, right, bottom = find("panel")[2], 0, 0
local function label_y(l) for _, w in ipairs(gui_log) do if w[1] == "button" and w[2] == l then return w[4] end end end
local function nums_y(l)   -- the y of every page number under the type's name (one value if all on one line)
  local ys, n = {}, 0
  for _, w in ipairs(gui_log) do
    if w[1] == "button" and w[3] >= px and w[2]:match("^%d+$") and w[4] > label_y(l) and w[4] <= label_y(l) + 9 then
      if not ys[w[4]] then ys[w[4]] = true; n = n + 1 end
    end
  end
  return n, next(ys)
end
for _, w in ipairs(gui_log) do
  if w[1] == "button" and w[3] >= px then right = math.max(right, w[3] + #w[2] * 5); bottom = math.max(bottom, w[4]) end
end
local TYPES = { "Projectiles", "Static projectiles", "Projectile modifiers", "Multicasts", "Materials", "Other", "Utility", "Passives" }
check(#SB.layout().by_type[0] == 8 and #SB.layout().by_type[2] == 9 and find("button", "9"), "125 projectiles: 8 pages; 140 modifiers: 9")
local one_line = true
for t, l in ipairs(TYPES) do
  local n, y = nums_y(l)
  local pages = #SB.layout().by_type[t - 1]
  if not label_y(l) or (pages == 1 and n ~= 0) or (pages > 1 and (n ~= 1 or y ~= label_y(l) + 9)) then
    one_line = false; print("  " .. l .. ": " .. pages .. " pages, " .. n .. " lines of numbers")
  end
end
check(one_line, "every type with more than one page: its page numbers on one line, under its name (none for one page: Passives)")
check(bottom + 11 <= 360 and right <= 640, "the list fits on the screen (bottom " .. bottom .. ", right edge " .. right .. ")")
-- the page numbers are spaced the same on every line, by the gap that fits the longest
local function num_x(n, row_y)
  for _, w in ipairs(gui_log) do if w[1] == "button" and w[2] == n and w[4] == row_y then return w[3] end end
end
local pitch = {}
for _, l in ipairs({ "Projectiles", "Static projectiles", "Projectile modifiers", "Other" }) do local y = label_y(l) + 9; pitch[l] = num_x("3", y) - num_x("2", y) end
check(pitch["Projectiles"] == pitch["Projectile modifiers"] and pitch["Static projectiles"] == pitch["Projectile modifiers"] and pitch["Other"] == pitch["Projectile modifiers"],
  "the same spacing on every line (" .. pitch["Projectiles"] .. ", " .. pitch["Static projectiles"] .. ", " .. pitch["Projectile modifiers"] .. ", " .. pitch["Other"] .. ")")
click = { match = "Projectile modifiers" }; step(3)
local faded = 0
for _, w in ipairs(gui_log) do if w[1] == "image" and w[2] == "x.png" and w[5] < 1 then faded = faded + 1 end end
check(SB.selected == "2:1" and row_str() == "" and faded == 16, "Projectile modifiers 1, with none owned: 16 faded spells")
print("\nall checks passed")
