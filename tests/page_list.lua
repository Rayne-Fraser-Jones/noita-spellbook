-- The page list: rest the mouse on a page's name to look at it, click to select it. Letting go
-- of a dragged spell over a name isn't a click. "Hide unowned" switches the faded spells off and on.
-- Widget IDs don't change when the row does (the game keys hover highlights to them).
dofile("tests/stubs.lua")
-- 20 more projectiles, to fill a second page
EXTRA_ACTIONS = {}
for i = 1, 20 do EXTRA_ACTIONS[i] = { id = "P" .. i, name = "p" .. i, sprite = "p.png", type = 0 } end
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1)
for i = 1, 20 do SB.add("P" .. i, -1, 1) end
SB.add("DAMAGE", -1, 2)
inventory_open = true; step(3)
check(SB.shown == "0:1" and find("button", "Projectiles") and find("button", "2") and find("button", "Projectile modifiers"),
  "Projectiles 1 shown; Projectiles 2 and Modifiers listed")

-- colours: buttons dark grey, the selected page gold; "Page:" the grey of SPELLS, the page name gold
local function col(kind, label)
  local w = find(kind, label)
  return w and w.color and table.concat(w.color, ",") or "none"
end
local GOLD, DIM, VIEW, LABEL, WHITE = "1,0.85,0.4", "0.6,0.6,0.6", "1,1,0.7", "0.8,0.8,0.8", "1,1,1"
check(col("button", "Projectiles") == GOLD and col("button", "2") == DIM and col("button", "Projectile modifiers") == DIM
  and col("button", "[x] Hide unowned") == WHITE, "page names dark grey, the selected one gold, Hide unowned (ticked) white")
check(col("text", "Page:") == LABEL and col("text", "Projectiles 1") == GOLD, "beside SPELLS: \"Page:\" the grey of SPELLS, \"Projectiles 1\" gold")

local function ids()
  local by_label, used = {}, {}
  for _, w in ipairs(gui_log) do
    local id = (w[1] == "button" and w[5]) or (w[1] == "image" and w[6]) or nil
    if id then
      if used[id] then error("FAIL: id " .. id .. " used twice") end
      used[id] = true
      if w[1] == "button" then by_label[w[2]] = id end
    end
  end
  return by_label
end
local before = ids()

-- resting on a name: that page is shown, until the mouse leaves the list
hover_name("Projectile modifiers"); step(3)
check(SB.shown == "0:1", "not straight away")
step(8)
check(SB.shown == "2:1" and row_str() == "DAMAGE#-1" and col("text", "Projectile modifiers 1") == VIEW
  and col("text", "Page:") == LABEL and col("button", "Projectile modifiers") == WHITE,
  "after a moment: Modifiers 1 shown, its name in the hover yellow beside SPELLS; the name under the mouse white")
local during = ids()
for _, label in ipairs({ "Projectiles", "2", "Projectile modifiers", "[x] Hide unowned" }) do
  check(before[label] and before[label] == during[label], label .. " keeps its widget id")
end
hover_list_gap(); step(2)
check(SB.shown == "0:1" and SB.selected == "0:1", "off the name (still over the panel): the selected page again, at once")
hover_none(); step(10)
check(SB.shown == "0:1" and SB.selected == "0:1", "off the panel: the selected page")

-- a line's name lights up with any of its pages: with Modifiers selected, "2" under the mouse
click = { match = "Projectile modifiers" }; step(3)
hover_name("2"); step(2)
check(col("button", "Projectiles") == VIEW and col("button", "1") == DIM, "\"2\" under the mouse: the name in the hover yellow too, the 1 not")
hover_none(); step(2)
check(col("button", "Projectiles") == DIM, "and dark grey again")

-- click: selected
click = { match = "2" }; step(3)
check(SB.selected == "0:2" and SB.shown == "0:2", "clicking 2: Projectiles 2 selected")
check(col("button", "Projectiles") == GOLD and col("button", "1") == DIM and col("button", "2") == GOLD,
  "Projectiles 2 selected: the name gold too, the 1 not")
hover_name("Projectiles"); step(2)
check(col("button", "1") == VIEW and col("button", "Projectiles") == GOLD, "the name under the mouse: the 1 lights up with it (the name is still page 1's button)")
hover_none(); step(2)
click = { match = "Projectiles" }; step(3)
check(SB.selected == "0:1", "clicking Projectiles: page 1")

-- letting go of a drag over a name is not a click
press_on(1); hover_name("Projectile modifiers"); step(3); mouse_down = false; click = { match = "Projectile modifiers" }; step(3)
check(SB.selected == "0:1", "a release over Modifiers doesn't select it")
hover_none(); step(12)

-- Hide unowned unticked: the spells you own none of are shown
click = { match = "[x] Hide unowned" }; step(3)
check(settings["spellbook.hide_unowned"] == false and find("button", "[ ] Hide unowned") and find("button", "Utility"),
  "Hide unowned unticked: Utility listed too")
check(col("button", "[ ] Hide unowned") == DIM, "Hide unowned dark grey while unticked")
check(page_str("0:2") == "P13#-1 P14#-1 P15#-1 P16#-1 P17#-1 P18#-1 P19#-1 P20#-1",
  "the spells you don't have get slots too, so the rest moves along: " .. page_str("0:2"))
click = { match = "[ ] Hide unowned" }; step(3)
check(settings["spellbook.hide_unowned"] == true and not find("button", "Utility"), "Hide unowned ticked again")

-- a selected page that stops existing: the last page of its type
click = { match = "2" }; step(3)
SB.relayout(PLAYER, function() for i = 1, 20 do SB.change_count(group("P" .. i, -1), -1) end end); step(3)
check(SB.selected == "0:1" and not find("button", "2"), "Projectiles 2 gone: Projectiles 1 selected")
check(not find("tooltip", "View page: Projectiles 2"), "no tooltip on the page numbers (it would cover the panel)")
check(find("tooltip", "View page: Projectiles 1") and find("tooltip", "Hide the placeholders for spells you own no copies of"),
  "short tooltips: \"View page: Projectiles 1\", and what Hide unowned does")
print("\nall checks passed")
