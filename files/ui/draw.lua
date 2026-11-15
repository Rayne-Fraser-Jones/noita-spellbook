-- Spellbook: what is drawn each frame while the inventory is open, in order: at the spell row
-- (spell_row.lua), the SPELLBOOK panel (panel.lua) and the right-click hint (while the mouse is on
-- a limited-uses card whose copies differ in uses).
--
-- The drawing tells the rest of the mod what is under the mouse, for the next frame's presses:
-- SB.mouse (the mouse in UI pixels), SB.hover_card (one of the spellbook's cards in the row),
-- SB.hover_ui (any of the spellbook's buttons, or the panel) and SB.hover_target (the page whose
-- button is under the mouse).

local W = SB.widgets

local HINT_FROM_BOTTOM = 24   -- the right-click hint's line, from the bottom of the screen

-- The mouse position in UI pixels, worked out as Spell Lab Shugged does: the mouse's position in
-- the world, relative to the camera, scaled from the world view to the UI.
local function mouse_ui(gui)
	local wx, wy = DEBUG_GetMouseWorld()
	local cx, cy = GameGetCameraPos()
	local sw, sh = GuiGetScreenDimensions(gui)
	local rw = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")) or 427
	local rh = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")) or 242
	return (wx - cx) / rw * sw + sw * 0.5, (wy - cy) / rh * sh + sh * 0.5
end

-- Whether the mouse is on a card the right-click hint is for: one of the spellbook's cards in the
-- row, of a limited-uses spell whose copies have at least two different numbers of uses (two
-- groups), so right-clicking it to see all its copies helps to pick one.
local function hint_card()
	local kind = SB.hover_card and SB.reps[SB.hover_card]
	local g = kind and SB.groups[kind]
	if not g or not SB.limited_info(g.id) then return false end
	for _, other in pairs(SB.groups) do
		if other.id == g.id and other ~= g then return true end
	end
	return false
end

function SB.draw_ui(gui, player)
	SB.hover_ui, SB.hover_target = nil, nil
	SB.ui.hot, SB.ui.hot_next = SB.ui.hot_next or {}, {}   -- buttons the game had under the mouse last frame, and this frame
	SB.ui.lit, SB.ui.lit_next = SB.ui.lit_next or {}, {}   -- buttons lit by an area standing for them (see W.button)
	local snap = SB.row_snapshot(player)
	if not snap then return end
	local sw, sh = GuiGetScreenDimensions(gui)
	SB.mouse = { mouse_ui(gui) }
	SB.draw_spell_row(gui, player, snap)
	SB.draw_panel(gui, player, sw, sh)
	-- the right-click hint, centred at the bottom of the screen, until it has been used
	if hint_card() and SB.copies_hint_wanted() then
		local hint = "SPELLBOOK: Right-click a limited-uses spell in your inventory to see all its copies"
		W.text(gui, math.floor((sw - W.text_width(gui, hint)) / 2), sh - HINT_FROM_BOTTOM, hint, W.LABEL)
	end
end

-- The inventory was closed (see SB.inventory_closed): the drawing's own state is forgotten. A drag
-- of the panel ends, and the search box gives the keyboard back.
function SB.ui_closed()
	SB.ui.hot, SB.ui.hot_next, SB.ui.lit, SB.ui.lit_next = nil, nil, nil, nil
	SB.ui.search_focus = false
	SB.ui.panel_drag = nil
end
