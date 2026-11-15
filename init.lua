-- Spellbook: entry point. Loads the mod's files (each one's first lines say what it holds) and runs
-- the spellbook every frame, also while the game is paused by the inventory.

for _, file in ipairs({
	"core",                                  -- settings, debug log, messages, mouse buttons
	"spells", "groups", "pages",             -- the spell list, what the spellbook holds, the pages
	"cards", "row", "wands",                 -- entities: cards, the spell row's sync, wands
	"view", "game",                          -- the page selected and shown; each frame's order
	"ui/widgets", "ui/spell_row", "ui/search", "ui/panel", "ui/draw",   -- the drawing
}) do
	dofile_once("mods/spellbook/files/" .. file .. ".lua")
end

ModLuaFileAppend("data/scripts/items/spell_refresh.lua", "mods/spellbook/files/spell_refresh_append.lua")

local gui = nil
local ready = false
local inventory_was_open = false
local inventory_pause = false

local function frame()
	if gui == nil then gui = GuiCreate() end
	GuiStartFrame(gui)
	SB.read_buttons()

	local player = SB.get_player()
	if player == nil then return end
	if not ready then
		SB.prepare(player)
		ready = true
	elseif player ~= SB.player then
		-- a new player entity (polymorph and back)
		SB.player_changed(player)
		inventory_was_open = false
	end

	local open = GameIsInventoryOpen()
	SB.tick(player, open, inventory_was_open)
	if open then
		SB.draw_ui(gui, player)
	elseif inventory_was_open then
		SB.inventory_closed(player)
	end
	inventory_was_open = open
end

function OnWorldPostUpdate()
	frame()
end

-- If the game is set to pause while the inventory is open, world updates stop, so the spellbook
-- runs from the pause callback instead.
function OnPausedChanged(is_paused, is_inventory_pause)
	inventory_pause = is_paused and is_inventory_pause
end

function OnPausePreUpdate()
	if inventory_pause then
		frame()
	elseif gui ~= nil then
		GuiStartFrame(gui)
	end
end
