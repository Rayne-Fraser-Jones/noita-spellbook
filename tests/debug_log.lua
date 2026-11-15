-- The debug log. The normal game doesn't write Lua's print to logger.txt (seen in play), so
-- the log is also kept in a global value, saved with the run (save00/world_state.xml). It
-- keeps the last 400 lines and carries on from an earlier session.
dofile("tests/stubs.lua")
add_tag(WAND, "wand")
dofile(MOD_ROOT .. "init.lua")
dofile("tests/helpers.lua")
local KEY = "spellbank2_debug_log"
local function lines() local n = 0 for _ in string.gmatch(globals[KEY] or "", "[^\n]+") do n = n + 1 end return n end
step()
SB.add("BOMB", 3, 2)
inventory_open = true; step(3)
check((globals[KEY] or "") == "", "debug log off: nothing kept")

settings["spellbook.debug_log"] = true
print = function() end
globals[KEY] = "1: from last time"
local card = row()[1].e
press_on(1); set_parent(card, WAND); mouse_down = false; step(4)
local log = globals[KEY]
check(log:find("^1: from last time\n%-%-%-%- game started"), "carries on from the lines an earlier session saved")
check(log:find("mouse pressed on bomb"), "the press")
check(log:find("bomb: one copy went into a wand, 1 left"), "and what the spellbook did")
for i = 1, 500 do SB.log("line " .. i) end
check(lines() == 400 and globals[KEY]:find("line 500$") and not globals[KEY]:find("line 100\n"), "only the last 400 lines are kept")
print("\nall checks passed")
