-- The hint at the bottom of the screen, "Right-click a limited-uses spell in your inventory to see
-- all its copies", shows while the mouse is on one of the spellbook's cards in the spell row of a
-- limited-uses spell whose copies have at least two different numbers of uses, and the mod setting
-- "Show right-click hint" is on (as it is to begin with). The
-- first right-click on a card turns the setting off; it can be turned on or off in the mod
-- settings at any time.
dofile("tests/stubs.lua")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
local HINT = "^SPELLBOOK: Right%-click a limited%-uses spell in your inventory to see all its copies$"
step()
SB.add("LIGHT_BULLET", -1, 2); SB.add("BOMB", 3, 2)
inventory_open = true; step(3)
check(row_str() == "LIGHT_BULLET#-1 BOMB#3", "Spark bolt (unlimited) and Bomb (3 uses) in the row: " .. row_str())
check(not find_text(HINT), "the inventory open, the mouse on no card: no hint")
hover_slot(1); step()
check(not find_text(HINT), "on Spark bolt (unlimited uses): no hint")
hover_slot(2); step()
check(not find_text(HINT), "on Bomb, every copy with 3 uses: no hint (its copies are all the same)")
hover_none(); SB.add("BOMB", 1, 1); step(3)
check(row_str() == "LIGHT_BULLET#-1 BOMB#3", "a 1-use Bomb too: the row still shows the 3-use one")
hover_slot(2); step()
local h = find_text(HINT)
check(h and h[4] == 360 - 24 and h[3] > 100 and h[3] < 320, "on Bomb, copies with 3 and 1 uses: the hint, centred at the bottom of the screen")
hover_none(); step()
check(not find_text(HINT), "off the card: gone again")

-- right-click a card: its copies, and the setting turned off
hover_slot(2); step(); right_down = true; step(); right_down = false; step(4)
check(SB.copies_of == "BOMB" and not find_text(HINT), "right-clicked Bomb: copies shown, the hint gone (the mouse still on a Bomb)")
check(settings["spellbook.show_copies_hint"] == false and next_settings["spellbook.show_copies_hint"] == false,
  "the setting turned off (and the menu's next value, so closing the menu doesn't undo it)")
hover_none(); click = { match = "Projectiles" }; step(3)
inventory_open = false; step(2); inventory_open = true; step(3)
hover_slot(2); step()
check(not find_text(HINT), "the inventory opened again, on Bomb: still gone")

-- the mod settings: an on/off setting, on to begin with
local real_dofile = dofile
dofile = function(p) if p:match("mod_settings") then return end return real_dofile(p) end
real_dofile("settings.lua")
dofile = real_dofile
local st
for _, s in ipairs(mod_settings) do if s.id == "show_copies_hint" then st = s end end
check(st and st.ui_name == "Show right-click hint" and st.value_default == true and not st.hidden and not st.ui_fn,
  "\"Show right-click hint\", an on/off setting in the mod settings, on to begin with")
settings["spellbook.show_copies_hint"] = true; step(3)
check(find_text(HINT), "turned on in the mod settings, on Bomb: the hint is back")
settings["spellbook.show_copies_hint"] = false; step(3)
check(not find_text(HINT), "turned off in the mod settings: gone, without a right-click")
hover_none(); step()
print("\nall checks passed")
