-- While a card is dragged out of the row (pressed, and the mouse moved with the button held), the game shows its slot empty and
-- the row isn't changed. The slot shows the copy that will take its place: the card's
-- background, the icon, its uses (top-left) and the count one less; nothing for a last copy.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1); SB.add("SPLITTER", -1, 3)
SB.add("BOMB", 3, 1); SB.add("BOMB", 1, 2)
inventory_open = true; step(3)
check(row_str() == "LIGHT_BULLET#-1 BOMB#3 SPLITTER#-1", "the row: " .. row_str())

local function images(sprite)
  local list = {}
  -- (over the spell row: not the cards at the start of the page list's lines, IDs 400 to 439)
  for _, w in ipairs(gui_log) do if w[1] == "image" and w[2] == sprite and not (w[6] and w[6] >= 400 and w[6] < 440) then list[#list + 1] = w end end
  return list
end
local function count_texts()
  local list = {}
  for _, w in ipairs(gui_log) do if w[1] == "text" and w.font == "data/fonts/font_small_numbers.xml" then list[#list + 1] = w[2] .. "@" .. w[3] .. "," .. w[4] end end
  table.sort(list)
  return table.concat(list, " ")
end
local function release() mouse_down = false; hover_none(); step(4) end
-- presses a card (the mouse over its slot), then moves the mouse 5 to the right: the game lifts
-- the card out of its slot only once the mouse moves
local function press_at(slot) local x = 191 + (slot - 1) * 20 + 9; mouse_at_ui(x, 30); press_on(slot) end
local function drag_on(slot) local x = 191 + (slot - 1) * 20 + 9; mouse_at_ui(x + 5, 30); step() end

-- Splitter, 3 copies (slot 3, its box at x 231, y 21): the next one, and 2
press_at(3)
check(#images("split.png") == 0 and count_texts():find("3@245,32"), "a press alone (the card not lifted yet): no change, still 3")
drag_on(3)
local icon, bg = images("split.png")[1], images("data/ui_gfx/inventory/item_bg_projectile.png")[1]
check(icon and icon[3] == 232 and icon[4] == 22 and bg and bg[3] == 230 and bg[4] == 20, "dragging a Splitter: the next one drawn in its slot, on its card background")
check(count_texts():find("2@245,32") and not count_texts():find("3@245"), "with the count one less (2), not 3: " .. count_texts())
check(row_str() == "LIGHT_BULLET#-1 BOMB#3 SPLITTER#-1", "the row itself isn't changed while the button is held")
release()
check(#images("split.png") == 0, "let go (the card put back): no stand-in")

-- Bomb: one copy with 3 uses, two with 1 (slot 2, box at x 211): the next one has 1 use
press_at(2); drag_on(2)
check(#images("bomb.png") == 1 and count_texts():find("1@212,22") and count_texts():find("2@225,32"),
  "dragging the 3-use Bomb: the next one shows its 1 use (top-left) and 2 left: " .. count_texts())
release()

-- the last copy: the slot shows nothing
press_at(1); drag_on(1)
check(#images("lb.png") == 0 and not count_texts():find("@205,"), "dragging the last Spark bolt: the slot stays empty")
release()

-- a copies page: one copy per slot, so the slot stays empty too
SB.show_copies(PLAYER, "SPLITTER"); step(4)
press_at(1); drag_on(1)
check(#images("split.png") == 0, "on a copies page: the slot stays empty")
release()
print("\nall checks passed")
