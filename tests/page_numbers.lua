-- A line's page numbers: the area of each reaches halfway into the gap on either side, so the
-- areas touch and a sweep along the numbers never leaves them. Resting on one for a moment shows
-- its page; once a page is shown that way, moving onto another number shows that one at once;
-- leaving the numbers shows the selected page again at once. A click in a number's area (its gap
-- too) selects it.
dofile("tests/stubs.lua")
-- 40 more projectiles: Projectiles 1, 2 and 3
EXTRA_ACTIONS = {}
for i = 1, 40 do EXTRA_ACTIONS[i] = { id = "P" .. i, name = "p" .. i, sprite = "p.png", type = 0 } end
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
step()
SB.add("LIGHT_BULLET", -1, 1)
for i = 1, 40 do SB.add("P" .. i, -1, 1) end
SB.add("DAMAGE", -1, 1)
inventory_open = true; step(3)
click = { match = "Projectile modifiers" }; step(3)
check(SB.selected == "2:1" and find("button", "3"), "Modifiers 1 selected; Projectiles has pages 1 to 3")

local one, two, three = find("button", "1"), find("button", "2"), find("button", "3")
local y = one[4] + 3
-- the mouse at a point (both as the game reports images under it, and as its position)
local function at(x, yy) mouse_point = { x, yy or y }; mouse_at_ui(x, yy or y) end
local W1 = 5   -- the stand-in's text is 5 wide a character
check(two[3] > one[3] + W1 and three[3] > two[3] + W1, "gaps between the numbers' text (" .. one[3] .. ", " .. two[3] .. ", " .. three[3] .. ")")

-- in the gap just right of the 1, resting: Projectiles 1
at(one[3] + W1 + 0.5); step(2)
check(SB.shown == "2:1", "not straight away")
step(9)
check(SB.shown == "0:1", "in the gap after the 1, resting: Projectiles 1 shown")
check(table.concat(find("button", "1").color, ",") == "1,1,0.7", "the 1 lit up in the hover yellow (the mouse is in its area, not on its text)")
-- along to the gap just left of the 2, then the 3: each shown at once
at(two[3] - 0.5); step(2)
check(SB.shown == "0:2", "in the gap before the 2: Projectiles 2 shown at once")
local function colour(label) return table.concat(find("button", label).color, ",") end
check(colour("2") == "1,1,0.7" and colour("1") == "0.6,0.6,0.6", "only the 2 lit, in the hover yellow; the 1 dark grey (" .. colour("1") .. ")")
-- on the 2's text (the game has the mouse on the button): the 2 only, not the line's first page
hover_name("2"); at(two[3] + 1); step(2)
check(colour("2") == "1,1,1" and colour("1") == "0.6,0.6,0.6" and colour("Projectiles") == "1,1,0.7",
  "on the 2's text: the 2 (white, for the game's yellow) and the name (it stands for the line); not the 1")
hover_none()
-- the edge between the 1's and the 2's areas: one of them only
at(two[3] - (two[3] - one[3] - W1) / 2); step(2)
check(not (colour("1") ~= "0.6,0.6,0.6" and colour("2") ~= "0.6,0.6,0.6"), "at the edge between two areas: never both lit")

at(three[3] + 1); step(2)
check(SB.shown == "0:3", "on the 3: Projectiles 3 shown at once")
-- off the numbers (below the panel): the selected page at once
at(one[3], 340); step(2)
check(SB.shown == "2:1", "off the numbers: the selected page again at once")
-- and resting is needed again before a page is shown
at(two[3] + 1); step(2)
check(SB.shown == "2:1", "back on a number: not straight away")
step(9)
check(SB.shown == "0:2", "after a moment: Projectiles 2")

-- a click in the gap before the 3 selects Projectiles 3
at(three[3] - 0.5); step(2)
mouse_down = true; step(); mouse_down = false; step(3)
check(SB.selected == "0:3", "a click in the gap before the 3: Projectiles 3 selected")
at(-1000, -1000); step(2)

-- Anywhere else on a line (the panel's whole width, the lines touching) stands for its first page,
-- except that the last number's area reaches the panel's right edge (under the name's height).
-- (the lines' tops: the Projectiles name is at its line's top, the lone Modifiers name 5 below)
local proj, mods = find("button", "Projectiles")[4], find("button", "Projectile modifiers")[4] - 5
local right = find("panel")[2] + find("panel")[4] - 1
check(mods - proj == 20, "the lines 20 apart (" .. proj .. ", " .. mods .. ")")
click = { match = "2" }; step(3)
check(SB.selected == "0:2", "Projectiles 2 selected")
-- the right end of the Modifiers line, past its name, resting: Modifiers 1
at(right, mods + 2); step(11)
check(SB.shown == "2:1", "the right end of the Modifiers line, resting: Modifiers 1 shown")
check(table.concat(find("button", "Projectile modifiers").color, ",") == "1,1,0.7", "its name lit up in the hover yellow")
-- up into the Projectiles line, its last pixel row, at the right end: the last number's area
at(right, mods - 0.5); step(2)
check(SB.shown == "0:3" and table.concat(find("button", "3").color, ",") == "1,1,0.7",
  "the bottom of the Projectiles line at the right end: the last number's area, Projectiles 3 at once")
-- higher, right of the name: the line, Projectiles 1
at(right, proj + 2); step(2)
check(SB.shown == "0:1", "right of the Projectiles name: Projectiles 1 at once")
at(right, mods + 0.5); step(2)
check(SB.shown == "2:1", "the top of the Modifiers line: Modifiers 1 at once (no gap between the lines)")
-- the left edge of the Projectiles line, beside its card: Projectiles 1
at(find("panel")[2] + 0.5, proj + 10); step(2)
check(SB.shown == "0:1", "the left edge of the Projectiles line: Projectiles 1")
-- the 3's area is page 3, not page 1
at(three[3] + 1, y); step(2)
check(SB.shown == "0:3" and table.concat(find("button", "1").color, ",") == "0.6,0.6,0.6",
  "on the 3: Projectiles 3, and the first page's parts not lit by the line")
-- a click on the empty right end of the Modifiers line selects Modifiers 1
at(right, mods + 15); step(2)
mouse_down = true; step(); mouse_down = false; step(3)
check(SB.selected == "2:1", "a click on the right end of the Modifiers line: Modifiers 1 selected")
at(-1000, -1000); step(2)
print("\nall checks passed")
