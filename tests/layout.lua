-- Pages are worked out from the groups: each spell type has its own pages, one slot per spell
-- (all its groups together, showing the copy first by uses left), in the game's spell order,
-- 16 to a page. A type with nothing to show has no
-- pages. Unowned spells shown ("Hide unowned" off) give every spell in the game a slot, faded where you have none.
dofile("tests/stubs.lua")
-- 20 more projectiles, to fill a second page
EXTRA_ACTIONS = {}
for i = 1, 20 do EXTRA_ACTIONS[i] = { id = "P" .. i, name = "p" .. i, sprite = "p.png", type = 0 } end
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
inventory_open = true; step(3)
check(#SB.layout().pages == 0 and find_text("No spells yet") and row_str() == "", "an empty spellbook: no pages, an empty row")

SB.add("SPLITTER", -1, 2); SB.add("LIGHT_BULLET", -1, 1); step(3)
check(page_str("0:1") == "LIGHT_BULLET#-1 SPLITTER#-1", "Projectiles 1, in the game's order: " .. page_str("0:1"))
check(find("button", "Projectiles") and not find("button", "Projectile modifiers") and not find("button", "2"),
  "only Projectiles is listed, with no other page numbers")
check(row_str() == "LIGHT_BULLET#-1 SPLITTER#-1", "the row shows it: " .. row_str())
check(find_count("^2$"), "a group of 2 shows its count")

-- Bombs with different uses: one slot for the spell, showing the copy with the most uses, and
-- counting every copy
SB.add("BOMB", 1, 1); SB.add("BOMB", 3, 2); SB.add("BOMB", 0, 1); step(3)
check(page_str("0:1") == "LIGHT_BULLET#-1 BOMB#3 SPLITTER#-1", "one slot per spell, showing the copy with the most uses: " .. page_str("0:1"))
check(row_str() == "LIGHT_BULLET#-1 BOMB#3 SPLITTER#-1" and find_count("^4$"), "its count is every copy (4): " .. row_str())
do
  -- the count is drawn like the game's uses count: its small numbers font, its grey, no shadow,
  -- 1 in from the slot's bottom-right corner (slot 2's box starts at x 211, y 21)
  local n, texts = find("text", "4"), 0
  for _, w in ipairs(gui_log) do if w[1] == "text" and w[2] == "4" then texts = texts + 1 end end
  check(n.font == "data/fonts/font_small_numbers.xml" and table.concat(n.color, ",") == "0.85,0.82,0.81"
    and n[3] == 211 + 18 - 4 and n[4] == 21 + 11 and texts == 1, "the count: the game's small numbers font and grey, bottom-right, no shadow")
end
settings["spellbook.uses_order"] = "fewest"; step(3)
check(page_str("0:1") == "LIGHT_BULLET#-1 BOMB#0 SPLITTER#-1", "fewest uses first, if chosen: " .. page_str("0:1"))
settings["spellbook.uses_order"] = nil; step(3)

-- the copy shown leaves: the next one by uses shows in the slot
local card = row()[2].e
press_on(2); set_parent(card, 0); mouse_down = false; step(4)
press_on(2); set_parent(row()[2].e, 0); mouse_down = false; step(4)
check(not group("BOMB", 3) and row()[2].id == "BOMB" and row()[2].uses == 1 and find_count("^2$"), "both 3-use copies thrown: the 1-use copy shows, 2 left")
check(where("BOMB").total == 4, "every copy counted once")
SB.relayout(PLAYER, function() SB.change_count(group("BOMB", 1), -1); SB.change_count(group("BOMB", 0), -1) end); step(3)

-- 20 more spells: Projectiles needs a second page
for i = 1, 20 do SB.add("P" .. i, -1, 1) end
step(3)
local p1 = page_str("0:1")
check(p1:find("^LIGHT_BULLET#%-1 SPLITTER#%-1 P1#%-1") and #SB.page("0:1").entries == 16, "16 to a page: " .. p1)
check(page_str("0:2") == "P15#-1 P16#-1 P17#-1 P18#-1 P19#-1 P20#-1", "the rest on Projectiles 2: " .. page_str("0:2"))
check(find("button", "2") and not find("button", "3"), "page 2 is listed, page 3 isn't")

-- spells gone: the page closes up
SB.relayout(PLAYER, function() for i = 1, 20 do SB.change_count(group("P" .. i, -1), -1) end end)
step(3)
check(page_str("0:1") == "LIGHT_BULLET#-1 SPLITTER#-1" and not SB.layout().by_key["0:2"], "groups gone: the page closes up, page 2 is gone")

-- unowned spells shown: every spell has a slot, faded where you have none; spells not unlocked yet (Nuke
-- here) only with the "Show locked spells" setting
settings["spellbook.hide_unowned"] = false; step(3)
check(page_str("0:1"):find("^LIGHT_BULLET#%-1 %-BOMB SPLITTER#%-1 %-ACID_TRAIL %-P1 ") ~= nil, "unowned shown: no Nuke (not unlocked yet): " .. page_str("0:1"))
check(find("button", "Projectile modifiers") and find("button", "Utility"), "every type is listed")
check(row_str() == "LIGHT_BULLET#-1 . SPLITTER#-1", "the row has gaps for the spells you don't have: " .. row_str())
SB.add("NUKE", 1, 1); step(3)
check(page_str("0:1"):find("^LIGHT_BULLET#%-1 %-BOMB NUKE#1 SPLITTER#%-1") ~= nil, "a locked spell you own is shown all the same: " .. page_str("0:1"))
SB.relayout(PLAYER, function() SB.change_count(group("NUKE", 1), -1) end); step(3)
settings["spellbook.show_locked"] = true; step(3)
check(page_str("0:1"):find("^LIGHT_BULLET#%-1 %-BOMB %-NUKE SPLITTER#%-1 %-ACID_TRAIL %-P1 ") ~= nil, "Show locked spells on: Nuke too: " .. page_str("0:1"))
check(row_str() == "LIGHT_BULLET#-1 . . SPLITTER#-1", "the row: " .. row_str())
local faded = 0
for _, w in ipairs(gui_log) do if w[1] == "image" and w[2] == "nuke.png" and w[5] < 1 then faded = faded + 1 end end
check(faded == 1 and find_tip("NUKE", "^You own no copies of this spell\nNot unlocked yet$"), "a faded Nuke, not unlocked yet; its name in capitals, \"You own no copies of this spell\", no full stops")
settings["spellbook.hide_unowned"], settings["spellbook.show_locked"] = true, nil; step(3)

-- a spell from a mod that is disabled: kept, at the end of Other, drawn as a placeholder
SB.add("GONE_MOD_SPELL", -1, 3); step(3)
check(page_str("5:1") == "GONE_MOD_SPELL#-1" and find("button", "Other"), "an unknown spell goes on Other")
click = { match = "Other" }; step(3)
check(row_str() == "" and find_text("GONE_MOD_SPELL") and group("GONE_MOD_SPELL", -1).count == 3, "drawn as a placeholder, copies kept")
print("\nall checks passed")
