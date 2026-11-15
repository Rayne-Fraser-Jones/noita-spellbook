-- The panel's two boxes and their defaults. To begin with neither is ticked: a line per spell
-- type, with every unlocked spell, faded where you own none, so the panel reads as a table of
-- contents. "Merge categories" ticked: one line for all the spells, "All", in the same order as
-- the type pages give (by type, then the game's order); the Copies and Search lines are as usual.
-- "Hide unowned" ticked: only the spells you own.
dofile("tests/stubs.lua")
settings["spellbook.hide_unowned"] = nil   -- the defaults: neither box ticked
EXTRA_ACTIONS = {
  { id = "EXPLOSION", name = "Explosion", sprite = "explosion.png", type = 1 },
  { id = "ALL_SPELLS", name = "All spells", sprite = "all_spells.png", type = 5 },
  { id = "ENERGY_SHIELD", name = "Energy shield", sprite = "energy_shield.png", type = 7 },
}
-- 14 more projectiles, for a second page with unowned spells shown
for i = 1, 14 do EXTRA_ACTIONS[#EXTRA_ACTIONS + 1] = { id = "P" .. i, name = "p" .. i, sprite = "p.png", type = 0 } end
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("ENERGY_SHIELD", -1, 1); SB.add("DAMAGE", -1, 2); SB.add("EXPLOSION", -1, 1)
SB.add("BOMB", 3, 1); SB.add("LIGHT_BULLET", -1, 1)
inventory_open = true; step(3)

-- the defaults: a line per type, every unlocked spell (Nuke isn't), faded where you own none
check(find("button", "Projectiles") and find("button", "Utility") and find("button", "Passives") and not find("button", "All"),
  "to begin with: a line per type, Utility too (you own none)")
check(page_str("0:1"):find("^LIGHT_BULLET#%-1 BOMB#3 %-SPLITTER %-ACID_TRAIL %-P1 ") ~= nil and not page_str("0:1"):find("NUKE"),
  "Projectiles 1: yours and the ones you own none of: " .. page_str("0:1"))
local collapse, hide = find("button", "[ ] Merge categories"), find("button", "[ ] Hide unowned")
check(collapse and hide and collapse[3] == hide[3] and collapse[4] < hide[4]
  and table.concat(collapse.color, ",") == "0.6,0.6,0.6" and table.concat(hide.color, ",") == "0.6,0.6,0.6",
  "\"[ ] Merge categories\" above \"[ ] Hide unowned\", both unticked, dark grey")
check(find_tip("Show all spells together instead of by category", "^$") and find_tip("Hide the placeholders for spells you own no copies of", "^$"),
  "their tooltips")
local title = find("text", "SPELLBOOK")
check(collapse[4] > title[4], "under the title bar")
check(collapse[3] + #"[x] Merge categories" * 5 <= find("panel")[2] + find("panel")[4], "the panel wide enough for \"[x] Merge categories\"")

-- Hide unowned ticked: only yours (Utility goes)
click = { match = "[ ] Hide unowned" }; step(3)
check(settings["spellbook.hide_unowned"] == true and next_settings["spellbook.hide_unowned"] == true
  and find("button", "[x] Hide unowned") and not find("button", "Utility"), "Hide unowned ticked: only the spells you own (and the menu's next value)")
check(table.concat(find("button", "[x] Hide unowned").color, ",") == "1,1,1", "white while ticked")

-- Merge categories ticked: one line, All: every spell, by type, then the game's order
click = { match = "[ ] Merge categories" }; step(3)
check(settings["spellbook.merge_categories"] == true and next_settings["spellbook.merge_categories"] == true
  and find("button", "[x] Merge categories"), "Merge categories ticked (and the menu's next value)")
check(page_str("10:1") == "LIGHT_BULLET#-1 BOMB#3 EXPLOSION#-1 DAMAGE#-1 ENERGY_SHIELD#-1",
  "All 1: projectiles, static projectiles, modifiers, passives, in order: " .. page_str("10:1"))
check(SB.resolve(SB.selected) == "10:1" and row_str() == "LIGHT_BULLET#-1 BOMB#3 EXPLOSION#-1 DAMAGE#-1 ENERGY_SHIELD#-1", "the row shows it: " .. row_str())
check(find("button", "All") and not find("button", "Projectiles") and not find("button", "Projectile modifiers"), "the page list: All, no type lines")
check(find("text", "All 1"), "\"Page: All 1\" beside SPELLS")
local card, icon
for _, w in ipairs(gui_log) do if w[1] == "image" and w[6] == 410 then card = w elseif w[1] == "image" and w[6] == 430 then icon = w end end
check(card and icon and icon[2] == "all_spells.png" and card[2] == "data/ui_gfx/inventory/item_bg_other.png", "its card: the All spells spell, on its card background")

-- a spell stored: All is selected
inventory_open = false; step(2)
world_pickup("SPLITTER", -1); step(4)
check(SB.selected == "10:1" and printed[#printed]:find("%(All 1%)"), "picked up: stored, All 1 selected: " .. printed[#printed])
inventory_open = true; step(3)
check(page_str("10:1") == "LIGHT_BULLET#-1 BOMB#3 SPLITTER#-1 EXPLOSION#-1 DAMAGE#-1 ENERGY_SHIELD#-1", "in its place among the projectiles: " .. page_str("10:1"))

-- more than 16: All 2 (with unowned spells shown)
SB.set_hide_unowned(PLAYER, false); step(3)
check(#SB.layout().by_type[SB.ALL] == 2 and find("button", "2") and find("button", "1"), "unowned shown: All 1 and 2, the numbers under it")
SB.set_hide_unowned(PLAYER, true); step(3)

-- copies and search as usual: the lines All, Copies, Search
SB.show_copies(PLAYER, "DAMAGE"); step(4)
check(SB.selected == "9:1" and row_str() == "DAMAGE#-1 DAMAGE#-1", "right-click: the copies page as usual")
SB.set_search(PLAYER, "o"); step(3)
SB.show_copies(PLAYER, "DAMAGE"); step(4)
local all, copies, search = find("button", "All"), find("button", "Copies"), find("button", "Search")
check(all and copies and search and all[4] < copies[4] and copies[4] < search[4], "All, then Copies, then Search")
SB.set_search(PLAYER, ""); click = { match = "All" }; step(4)
check(SB.selected == "10:1" and not SB.copies_of, "All clicked: back to All 1, copies closed")

-- unticked again: a line per type; the selected page is the first one there is
click = { match = "[x] Merge categories" }; step(3)
check(settings["spellbook.merge_categories"] == false and find("button", "Projectiles") and find("button", "Projectile modifiers") and not find("button", "All"),
  "unticked: the type lines, no All")
check(SB.resolve(SB.selected) == "0:1" and row_str() == "LIGHT_BULLET#-1 BOMB#3 SPLITTER#-1", "All 1 is gone: the first page, Projectiles 1: " .. row_str())
click = { match = "Projectile modifiers" }; step(3)
check(SB.selected == "2:1", "Projectile modifiers 1 selected")
-- and ticked again: All 1
SB.set_merge_categories(PLAYER, true); step(3)
check(SB.resolve(SB.selected) == "10:1" and find("button", "All"), "ticked again: All 1")

-- saved and loaded: All 1 still
click = { match = "All" }; step(3)
SB.save()
check(globals["spellbank2_selected"] == "10:1", "the selection saved: " .. globals["spellbank2_selected"])
SB.groups, SB.selected = {}, nil
SB.prepare(PLAYER); step(3)
check(SB.selected == "10:1" and SB.resolve(SB.selected) == "10:1", "loaded: All 1 selected")
check(where("DAMAGE").total == 2 and where("LIGHT_BULLET").total == 1, "every copy counted once")

-- the mod settings: Merge categories above Hide unowned spells, both off to begin with
local real_dofile = dofile
dofile = function(p) if p:match("mod_settings") then return end return real_dofile(p) end
real_dofile("settings.lua")
dofile = real_dofile
local collapse_i, hide_i
for i, st in ipairs(mod_settings) do
  if st.id == "merge_categories" then collapse_i = i; check(st.ui_name == "Merge categories" and st.value_default == false, "\"Merge categories\", off to begin with") end
  if st.id == "hide_unowned" then hide_i = i; check(st.ui_name == "Hide unowned spells" and st.value_default == false, "\"Hide unowned spells\", off to begin with") end
end
check(collapse_i and hide_i and collapse_i < hide_i, "Merge categories above Hide unowned spells")
print("\nall checks passed")
