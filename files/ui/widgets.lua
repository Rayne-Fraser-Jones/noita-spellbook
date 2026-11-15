-- Spellbook: what the drawing shares: the game's inventory positions, colours, layers, widget IDs,
-- and small drawing helpers (text, images, buttons, areas that tell where the mouse is).
--
-- Tooltips have no full stops; a second sentence goes on its own line.

SB.ui = SB.ui or {}             -- the drawing's own state (the panel's drag, the search box, ...)
SB.widgets = SB.widgets or {}
local W = SB.widgets

W.NON_INTERACTIVE = (GUI_OPTION and GUI_OPTION.NonInteractive) or 2
W.NO_SOUND = GUI_OPTION and GUI_OPTION.NoSound
W.HITBOX = "mods/spellbook/files/slot_hitbox.png"   -- transparent, 18 x 18
W.HITBOX_SIZE = 18
W.WHITE_PIXEL = "data/debug/whitebox.png"   -- the game's own plain white image (as Advanced Spell Inventory uses)
W.LINE_H = 11                               -- height of a line of text

-- The game's spell row, in UI pixels (640 x 360), measured from screenshots: the first slot's box,
-- the distance between slots, and a slot box's size.
W.ROW_X, W.ROW_Y, W.PITCH, W.SLOT_BOX = 191, 21, 20, 18
-- A card's background, by spell type (the game's own; 20 x 20, drawn 1 up and left of the slot box)
W.CARD_BG = {}
for t, name in pairs({ [0] = "projectile", "static_projectile", "modifier", "draw_many", "material", "other", "utility", "passive" }) do
	W.CARD_BG[t] = "data/ui_gfx/inventory/item_bg_" .. name .. ".png"
end
-- The game's font for a card's uses count (data/fonts/font_small_numbers.xml: white digits 4
-- wide, the last column blank, 6 tall), and the grey the game draws it in (measured: 218, 210, 207)
W.COUNT_FONT = "data/fonts/font_small_numbers.xml"
W.COUNT_DIGIT_W, W.COUNT_DIGIT_H = 4, 6
local COUNT_COLOR = { 0.85, 0.82, 0.81 }

-- Colours: buttons are dark grey, and the game's hover yellow while the mouse is on them; the
-- selected page is gold, and a box white while it is ticked. Text that only informs is dark grey.
W.GOLD  = { 1, 0.85, 0.4 }
W.DIM   = { 0.6, 0.6, 0.6 }
W.VIEW  = { 1, 1, 0.7 }        -- the game's own yellow for a button under the mouse (measured: 252, 252, 176)
W.LABEL = { 0.8, 0.8, 0.8 }    -- the grey of the inventory's own WANDS, ITEMS and SPELLS (measured: 200 of 255)
W.WHITE = { 1, 1, 1 }
W.TITLE_TINT = { 0.85, 0.6, 0.25 }   -- the panel's title bar: amber (a muted gold)

-- Layers: lower z is drawn in front; negative values sit above the vanilla inventory. The panel is
-- in front of everything else, the spellbook's own drawing over the spell row included. W.z is the
-- layer text() and button() draw at when none is given: Z_PANEL while the panel is drawn.
W.Z_HUD, W.Z_PANEL = -2000, -2500
W.z = W.Z_HUD

-- Widget IDs. The game keys a widget's hover highlight to its ID, so an ID depends only on what
-- the widget is (a button, a slot, a page), never on how many widgets were drawn before it;
-- otherwise a change in the spell row would move the highlight to another button.
W.ID = {
	HIDE_UNOWNED = 102, FROM_HELD = 103, FROM_ALL = 104, SEARCH = 105, MERGE = 106,
	PANEL = 201, TITLE_BAR = 202, TITLE_LINE = 204,
	ARROW_HIT = 206, ARROW = 230,       -- + 0..3: the title bar's arrow, its rows
	PAGE_PREV = 300, PAGE_NEXT = 320,   -- + type: the "<" and ">" of a line with too many pages
	SEARCH_FRAME = 340,                 -- + 1..4: the white frame around the search box
	SEARCH_CURSOR = 346,
	DRAG_BG = 360, DRAG_ICON = 361,     -- the next copy drawn in the slot of a card being dragged
	ROW_CARD = 400, ROW_ICON = 420,     -- + type: the card at the start of a line of the page list
	FIRST_NUM = 600, ROW_BUTTON = 620,  -- + type: a line's "1", and the button over its card
	LIST_HIT = 700, TITLE_HIT = 720, SEARCH_HIT = 740,   -- + 0..19: see hit_area
	SLOT_HITBOX = 1000, SLOT_FADED = 2000,               -- + slot
	PAGE = 10000,                       -- + type * 1000 + page number
}

-- Helpers ------------------------------------------------------------------------------------

function W.text_width(gui, s)
	local w = GuiGetTextDimensions(gui, s)
	return w
end

-- Whether the mouse is over the widget just drawn.
function W.hovered(gui)
	local _, _, hovered = GuiGetPreviousWidgetInfo(gui)
	return hovered
end

-- Text that only shows.
function W.text(gui, x, y, s, color, z)
	GuiZSetForNextWidget(gui, z or W.z)
	GuiOptionsAddForNextWidget(gui, W.NON_INTERACTIVE)
	if color then GuiColorSetForNextWidget(gui, color[1], color[2], color[3], 1) end
	GuiText(gui, x, y, s)
end

-- Text the mouse can be over (for a tooltip): returns whether it is.
function W.label(gui, x, y, s, color, z)
	GuiZSetForNextWidget(gui, z or W.z)
	if color then GuiColorSetForNextWidget(gui, color[1], color[2], color[3], 1) end
	GuiText(gui, x, y, s)
	local hovered = W.hovered(gui)
	if hovered then SB.hover_ui = true end
	return hovered
end

-- A number in the game's small numbers font and grey, no shadow, like a card's uses count.
function W.small_number(gui, x, y, s, z)
	GuiZSetForNextWidget(gui, z)
	GuiOptionsAddForNextWidget(gui, W.NON_INTERACTIVE)
	GuiColorSetForNextWidget(gui, COUNT_COLOR[1], COUNT_COLOR[2], COUNT_COLOR[3], 1)
	GuiText(gui, x, y, s, 1, W.COUNT_FONT, true)
end

-- An image that only shows. scale_y: as scale_x if not given.
function W.image(gui, id, x, y, sprite, alpha, z, color, scale_x, scale_y)
	GuiZSetForNextWidget(gui, z or W.z)
	GuiOptionsAddForNextWidget(gui, W.NON_INTERACTIVE)
	if color then GuiColorSetForNextWidget(gui, color[1], color[2], color[3], 1) end
	if scale_y then
		GuiImage(gui, id, x, y, sprite, alpha, scale_x, scale_y)
	else
		GuiImage(gui, id, x, y, sprite, alpha, scale_x or 1)
	end
end

-- A filled rectangle: the white pixel image, scaled to it.
function W.rect(gui, id, x, y, w, h, alpha, z, color)
	local size = GuiGetImageDimensions(gui, W.WHITE_PIXEL, 1) or 20
	W.image(gui, id, x, y, W.WHITE_PIXEL, alpha, z, color, w / size, h / size)
end

-- A transparent area that tells when the mouse is over it; returns whether it is. The game
-- counts an image as under the mouse within a square as wide as it is drawn, whatever its height
-- scale (seen in play: a transparent image drawn 98 x 11 over the search box counted as under the
-- mouse 85 below it), so the area is made of squares as big as its shorter side, overlapping at
-- the end (IDs id, id + 1, ...). tip: a tooltip for it ({ title, text }), on every square.
function W.hit_area(gui, id, x, y, w, h, z, tip)
	local size = math.min(w, h)
	if size <= 0 then return false end
	local n = math.ceil(math.max(w, h) / size - 0.001)
	local over = false
	for i = 0, n - 1 do
		local sx, sy = x, y
		if w >= h then sx = math.min(x + i * size, x + w - size) else sy = math.min(y + i * size, y + h - size) end
		GuiZSetForNextWidget(gui, z)
		if W.NO_SOUND then GuiOptionsAddForNextWidget(gui, W.NO_SOUND) end
		GuiImage(gui, id + i, sx, sy, W.HITBOX, 1, size / W.HITBOX_SIZE, size / W.HITBOX_SIZE)
		if W.hovered(gui) then over = true end
		if tip then GuiTooltip(gui, tip[1], tip[2] or "") end
	end
	return over
end

-- Letting go of a dragged spell over a button isn't a click on it: the game reports one (seen in
-- play), so clicks are ignored for 2 frames after such a release.
local function just_released() return SB.drag_released ~= nil and SB.frame - SB.drag_released <= 2 end

-- Whether the mouse (SB.mouse, UI pixels) is in an area. Worked out from the mouse's position,
-- not from the game's hover report, so of areas that touch exactly one holds the mouse (the game
-- counted two touching transparent images as both under the mouse at their shared edge, and an
-- image behind a button as not under it while the button was; seen in play).
function W.mouse_in(x, y, w, h)
	local m = SB.mouse
	return m ~= nil and m[1] >= x and m[1] < x + w and m[2] >= y and m[2] < y + h
end

-- A text button. Returns clicked, hovered. color is the button's colour, except in gold: while the
-- game has the mouse on it (known from the previous frame) it is asked for in white, as the game
-- then draws it in its hover yellow (seen in play), and white keeps that yellow at full
-- brightness; while it is only lit (SB.ui.lit: the mouse in an area that stands for it, not on its
-- text), it is drawn in that same yellow, so it looks the same either way.
function W.button(gui, id, x, y, label, color)
	GuiZSetForNextWidget(gui, W.z)
	if color ~= W.GOLD then
		if SB.ui.hot and SB.ui.hot[id] then color = W.WHITE
		elseif SB.ui.lit and SB.ui.lit[id] then color = W.VIEW end
	end
	if color then GuiColorSetForNextWidget(gui, color[1], color[2], color[3], 1) end
	local clicked = GuiButton(gui, id, x, y, label) and not just_released()
	local hovered = W.hovered(gui)
	if hovered then SB.hover_ui = true; SB.ui.hot_next[id] = true end
	return clicked, hovered
end

-- A transparent button over 18 x 18 pixels (a card's picture). Returns clicked, hovered.
function W.hitbox_button(gui, id, x, y, z)
	GuiZSetForNextWidget(gui, z)
	if W.NO_SOUND then GuiOptionsAddForNextWidget(gui, W.NO_SOUND) end
	local clicked = GuiImageButton(gui, id, x, y, "", W.HITBOX) and not just_released()
	local hovered = W.hovered(gui)
	if hovered then SB.hover_ui = true; SB.ui.hot_next[id] = true end
	return clicked, hovered
end
