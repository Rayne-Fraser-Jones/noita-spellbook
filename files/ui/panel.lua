-- Spellbook: the SPELLBOOK panel: a title bar to drag it by (with an arrow that collapses the
-- panel to it), the "Merge categories" and "Hide
-- unowned" boxes, the page list (one line per kind of page that has pages: each spell type, or All, then
-- Copies and Search), and the search box at the bottom.

local W = SB.widgets

-- The panel's usual place: at the top, below the gold counter, its right border at about x 512,
-- left of the game's list of perks and effects down the right edge (their names reach about x 519,
-- seen in screenshots). The game's first wands have only a few slots, so their panels stay well
-- left of it; it can be dragged anywhere else by its title bar, and is kept on the screen.
local PANEL_RIGHT = 512    -- the right end of its border, in its usual place
local PANEL_TOP = 58       -- its top, in its usual place
local PANEL_BORDER = 2     -- the game's panel graphic draws its border 2 outside the area given (seen in screenshots)
local TITLE_H = 13         -- the title bar's height
local PANEL_PAD = 3        -- space inside the panel above and below the title and page list
local PANEL_PAD_X = 2      -- and to their left and right
local LIST_W = 77          -- the least width of the page list's text (wider if a line's name needs it)
local LINE_H = W.LINE_H

-- Each line of the page list starts with a card, drawn as the inventory draws one (20 x 20, its
-- picture 16 x 16, 2 in from its edges): the icon of a spell typical of the line's type on the
-- type's card background. Beside it the line's name, and under that its page numbers; with only
-- one page, just the name, centred on the card.
local ROW_H = 20              -- height of a line: 4 between the cards' pictures
local ICON_COL = 21           -- from the card's left edge to the text: 3 after its picture
local NAME_IN_ROW = 0         -- the name's top below the card's (the font's letters start about 2
                              -- below a text's top and are about 6 tall)
local NUMS_IN_ROW = 9         -- the page numbers' top below the card's
local NAME_ALONE_IN_ROW = 5   -- the name's top below the card's when it is alone: centred on it
local TYPE_ICONS = { [0] = "LIGHT_BULLET", "EXPLOSION", "HOMING", "BURST_2", "MATERIAL_WATER", "ALPHA", "LONG_DISTANCE_CAST", "ENERGY_SHIELD",
	[SB.ALL] = "ALL_SPELLS" }   -- the All line: the game's "All spells" spell
-- The Search line: a magnifying glass (the mod's own, drawn in the game's style) on the
-- inventory's empty slot box: plain, and not a spell type's colour. The Copies line shows the
-- spell whose copies are open.
local SPECIAL_BG = "data/ui_gfx/inventory/full_inventory_box.png"
local SPECIAL_ICONS = { [SB.SEARCH] = "mods/spellbook/files/search_icon.png" }
local NUM_GAPS = { 3, 2, 1 }    -- space between page numbers: the widest that fits every line
local LEFT_ARROW_TRIM = 2       -- the font reports "<" 2 wider than it draws it (measured: 6 to the
                                -- number after it, against 4 from the number to ">"), so what
                                -- follows it moves 2 closer

-- Where it is -------------------------------------------------------------------------------------
-- Its usual place, or where it was last dragged to (kept in a hidden mod setting, "x,y", so it
-- stays there in later runs). x, y is the top-left of its area; the border is drawn 2 outside.

local function panel_place(width)
	local x, y = string.match(tostring(SB.setting("panel_pos") or ""), "^(%-?[%d%.]+),(%-?[%d%.]+)$")
	if x and tonumber(x) and tonumber(y) then return tonumber(x), tonumber(y) end
	return PANEL_RIGHT - PANEL_BORDER - width, PANEL_TOP
end

-- (whole pixels: the screen's size can have a fraction)
local function keep_on_screen(x, y, width, height, sw, sh)
	x = math.floor(math.max(PANEL_BORDER, math.min(x, sw - PANEL_BORDER - width)))
	y = math.floor(math.max(PANEL_BORDER, math.min(y, sh - PANEL_BORDER - height)))
	return x, y
end

-- The panel's top-left this frame. While it is dragged (SB.ui.panel_drag: where the mouse holds it)
-- it follows the mouse; where it is let go is kept.
local function place_panel(width, height, sw, sh)
	local d = SB.ui.panel_drag
	if not (d and SB.mouse) then
		SB.ui.panel_drag = nil
		local x0, y0 = panel_place(width)
		return keep_on_screen(x0, y0, width, height, sw, sh)
	end
	local px, py = math.floor(SB.mouse[1] - d[1] + 0.5), math.floor(SB.mouse[2] - d[2] + 0.5)
	px, py = keep_on_screen(px, py, width, height, sw, sh)
	if not SB.buttons.left then
		SB.ui.panel_drag = nil
		SB.set_setting("panel_pos", px .. "," .. py)
		SB.log("spellbook panel moved to " .. px .. "," .. py)
	end
	return px, py
end

-- Collapsed: only the title bar is drawn (kept in a hidden mod setting, so it stays so in later
-- runs). Collapsing gives back the search box's keyboard, as the box isn't drawn to do it.
local function panel_collapsed() return SB.setting("panel_collapsed") == true end
local function set_panel_collapsed(player, on)
	SB.set_setting("panel_collapsed", on)
	SB.log("spellbook panel " .. (on and "collapsed" or "expanded"))
	if on and SB.ui.search_focus then
		SB.ui.search_focus = false
		SB.set_controls(player, true)
	end
end

-- The arrow at the right end of the title bar: up while the panel is open, down while it is
-- collapsed; the title grey, white under the mouse. A triangle 7 wide and 4 tall made of 1-pixel
-- rows, in a square as tall as the title bar. Returns whether it was pressed.
local ARROW_W, ARROW_H = 7, 4
local function collapse_arrow(gui, x, y, collapsed)
	local box_x = x - TITLE_H
	local hovered = W.hit_area(gui, W.ID.ARROW_HIT, box_x, y, TITLE_H, TITLE_H, W.Z_PANEL + 18,
		{ collapsed and "Expand the panel" or "Collapse the panel" })
	if hovered then SB.hover_ui = true end
	local ax, ay = box_x + math.floor((TITLE_H - ARROW_W) / 2), y + math.floor((TITLE_H - ARROW_H) / 2) + 1
	for i = 0, ARROW_H - 1 do
		local w = 2 * (collapsed and (ARROW_H - 1 - i) or i) + 1   -- the point at the top (up) or the bottom (down)
		W.rect(gui, W.ID.ARROW + i, ax + (ARROW_W - w) / 2, ay + i, w, 1, 1, W.Z_PANEL + 24, hovered and W.WHITE or W.LABEL)
	end
	return hovered and SB.buttons.pressed
end

-- The title bar: an amber strip with SPELLBOOK in it, stronger under the mouse, and the arrow.
-- Pressing on it (not on the arrow) starts a drag.
local function title_bar(gui, player, x, y, width, collapsed)
	local hovered = W.hit_area(gui, W.ID.TITLE_HIT, x, y, width, TITLE_H, W.Z_PANEL + 19)
	if hovered then SB.hover_ui = true end
	local strong = hovered or SB.ui.panel_drag
	W.rect(gui, W.ID.TITLE_BAR, x, y, width, TITLE_H, strong and 0.4 or 0.22, W.Z_PANEL + 25, W.TITLE_TINT)
	W.rect(gui, W.ID.TITLE_LINE, x, y + TITLE_H, width, 1, 0.6, W.Z_PANEL + 25, W.TITLE_TINT)
	W.text(gui, x + PANEL_PAD_X, y + 2, "SPELLBOOK", W.LABEL)   -- like the inventory's own WANDS, ITEMS and SPELLS
	if collapse_arrow(gui, x + width, y, collapsed) then
		set_panel_collapsed(player, not collapsed)
	elseif hovered and SB.buttons.pressed and not SB.ui.panel_drag and SB.mouse then
		SB.ui.panel_drag = { SB.mouse[1] - x, SB.mouse[2] - y }
	end
end

-- The page list -----------------------------------------------------------------------------------
-- A line's first page opens from its card, its name or the "1" under it; the numbers after it
-- (2, 3, ...) are its other pages. The numbers get the widest gap (NUM_GAPS) that fits every
-- line in the list's width. A line whose numbers don't fit even with the narrowest gap (copies of
-- a spell you have hundreds of, a big search) shows "< 12/63 >" instead: buttons for the previous
-- and next page, and which page of how many.

-- The two boxes at the top: label and tooltip.
local MERGE_BOX = { "Merge categories", "Show all spells together instead of by category" }
local HIDE_BOX = { "Hide unowned", "Hide the placeholders for spells you own no copies of" }
local function box_label(b, on) return (on and "[x] " or "[ ] ") .. b[1] end

-- The width of the page list's text: enough for every line's name (and for the boxes, which start
-- at the cards' left edge), so the panel doesn't change width as lines come and go.
local function list_text_width(gui)
	local w = LIST_W
	for _, t in ipairs(SB.LIST_ORDER) do w = math.max(w, W.text_width(gui, SB.TYPE_NAMES[t])) end
	for _, b in ipairs({ MERGE_BOX, HIDE_BOX }) do w = math.max(w, W.text_width(gui, box_label(b, true)) - ICON_COL) end
	return w
end

local function page_rows(gui, L, text_w)
	local rows = {}
	for _, t in ipairs(SB.LIST_ORDER) do
		local list = L.by_type[t] or {}
		if #list > 0 then
			local row = { type = t, label = SB.TYPE_NAMES[t], list = list, width = 0 }
			for k = 1, #list do row.width = row.width + W.text_width(gui, tostring(k)) end
			row.pager = #list > 1 and row.width + NUM_GAPS[#NUM_GAPS] * (#list - 1) > text_w
			rows[#rows + 1] = row
		end
	end
	-- one gap for every line with numbers, so the lists look the same: the widest that fits all
	-- of them
	local gap = NUM_GAPS[1]
	for _, row in ipairs(rows) do
		if #row.list > 1 and not row.pager then
			local fits = NUM_GAPS[#NUM_GAPS]
			for _, g in ipairs(NUM_GAPS) do
				if row.width + g * (#row.list - 1) <= text_w then fits = g break end
			end
			gap = math.min(gap, fits)
		end
	end
	for _, row in ipairs(rows) do row.gap = gap end
	return rows
end

-- A page's button: dark grey, the hover yellow under the mouse or while the mouse is in its area
-- (see number_areas and line_area), gold for the selected page. id and color: for the parts of a
-- line's first page, which share them. No tooltip: on the names and numbers it would cover most
-- of the panel (the cards below, the numbers along) while the mouse moves over them. Returns its
-- width.
local function page_button(gui, player, x, y, page, label, id, color)
	local selected = page.key == SB.resolve(SB.selected)
	local clicked, hovered = W.button(gui, id or (W.ID.PAGE + page.type * 1000 + page.number), x, y, label, color or (selected and W.GOLD or W.DIM))
	if hovered then SB.hover_target = page.key end
	if clicked then SB.switch_page(player, page.key) end
	return W.text_width(gui, label)
end

-- "< 12/63 >" after a line's name, for a line whose numbers don't fit. The arrows are white; the
-- number is the selected page's (gold) if it is one of this line's pages, or 1 (dark grey); the
-- "/63" is dark grey. Returns whether an arrow is under the mouse.
local function pager(gui, player, x, y, row)
	local list, cur, here, over = row.list, 1, false, false
	local selected = SB.resolve(SB.selected)   -- (once: with copies open, working it out walks every group)
	for k, page in ipairs(list) do
		if page.key == selected then cur, here = k, true end
	end
	-- An arrow that would go nowhere (on the first or last page, and page 1 too on a line whose page
	-- isn't selected) is dark grey plain text, not a button, so it doesn't light up under the mouse.
	-- Resting on an arrow doesn't look at the page it leads to (confusing for an arrow): the
	-- selected page is shown (worked out after a click, so it is the newly selected page). No
	-- tooltip either: at the screen's right edge the game moves it over the arrow.
	local function arrow(id, label, k)
		if k == cur then
			W.text(gui, x, y, label, W.DIM)
		else
			local clicked, hovered = W.button(gui, id, x, y, label, W.WHITE)
			if clicked then SB.switch_page(player, list[k].key) end
			if hovered then SB.hover_target, over = SB.resolve(SB.selected), true end
		end
		x = x + W.text_width(gui, label) + NUM_GAPS[1] - (label == "<" and LEFT_ARROW_TRIM or 0)
	end
	arrow(W.ID.PAGE_PREV + row.type, "<", math.max(cur - 1, 1))
	local num, total = tostring(cur), "/" .. #list
	W.text(gui, x, y, num, here and W.GOLD or W.DIM)
	W.text(gui, x + W.text_width(gui, num), y, total, W.DIM)
	x = x + W.text_width(gui, num .. total) + NUM_GAPS[1]
	arrow(W.ID.PAGE_NEXT + row.type, ">", math.min(cur + 1, #list))
	return over
end

-- The card at the start of a line: a spell typical of the line's type on the type's card
-- background (on the Copies line, the spell whose copies are open), or the Search symbol on the
-- empty slot box.
local function row_card(gui, row, x, y)
	local bg, sprite = SPECIAL_BG, SPECIAL_ICONS[row.type]
	if not sprite then
		local id = row.type == SB.COPIES and SB.copies_of or TYPE_ICONS[row.type]
		local info = SB.actions and SB.actions[id or ""]
		if not info then return end
		bg, sprite = W.CARD_BG[info.type] or W.CARD_BG[SB.TYPE_OTHER], info.sprite
	end
	W.image(gui, W.ID.ROW_CARD + row.type, x, y, bg, 1, W.z + 1)
	W.image(gui, W.ID.ROW_ICON + row.type, x + 2, y + 2, sprite, 1, W.z)
end

-- A line's first page is one button made of three parts: the card, the line's name, and the "1"
-- under it (none on a line with "< 12/63 >", and none on a line with only one page, whose name is
-- then centred on the card). Under the mouse (or with the mouse on the line, see line_area), any
-- of them lights up all three (the game's hover yellow); for the selected page they are gold.
-- Only the card shows the page's tooltip, and a click on any selects the page. The name also
-- stands for the whole line: it is gold while any of the line's pages is selected, and lights up
-- while any of its page buttons is under the mouse (another number, or an arrow of
-- "< 12/63 >"). Returns where the line's other page numbers start.
local function first_page_button(gui, player, row, x, y)
	local page = row.list[1]
	local name_id, num_id, card_id = W.ID.PAGE + page.type * 1000 + 1, W.ID.FIRST_NUM + row.type, W.ID.ROW_BUTTON + row.type
	local hot, lit = SB.ui.hot or {}, SB.ui.lit or {}
	local function on(id) return hot[id] or lit[id] end
	local selected = SB.resolve(SB.selected)
	local first_hot = on(name_id) or on(num_id) or on(card_id)
	local line_hot = first_hot or on(W.ID.PAGE_PREV + row.type) or on(W.ID.PAGE_NEXT + row.type)
	for k = 2, #row.list do line_hot = line_hot or on(W.ID.PAGE + page.type * 1000 + k) end
	local color = (page.key == selected and W.GOLD) or (first_hot and W.VIEW) or W.DIM
	local name_color = (SB.key_type(selected) == row.type and W.GOLD) or (line_hot and W.VIEW) or W.DIM
	-- the card: a transparent button over its picture
	local clicked, hovered = W.hitbox_button(gui, card_id, x + 1, y + 1, W.z - 1)
	if hovered then SB.hover_target = page.key end
	GuiTooltip(gui, "View page: " .. page.name, "")
	if clicked then SB.switch_page(player, page.key) end
	local tx = x + ICON_COL
	if #row.list == 1 then
		page_button(gui, player, tx, y + NAME_ALONE_IN_ROW, page, row.label, name_id, name_color)
		return tx
	end
	page_button(gui, player, tx, y + NAME_IN_ROW, page, row.label, name_id, name_color)
	if row.pager then return tx end
	return tx + page_button(gui, player, tx, y + NUMS_IN_ROW, page, "1", num_id, color)
end

-- A line's page numbers' areas (xs, ws: each number's left edge and width): each reaches halfway
-- into the gap on either side, so they touch and a sweep along the numbers never leaves them (the
-- text alone has gaps between). In its area a number lights up, shows its page as when the mouse
-- is on the number (SB.update_display), and takes a click. They reach down to the next line, and
-- the last one to the panel's right edge (right_end), so moving on past it doesn't go back to the
-- first page. Returns whether the area of a number other than 1 is under the mouse.
local function number_areas(player, row, xs, ws, top, right_end)
	local half, h = row.gap / 2, ROW_H - NUMS_IN_ROW
	local over = false
	for k, page in ipairs(row.list) do
		local left = xs[k] - half
		local right = (k < #row.list) and (xs[k + 1] - half) or right_end
		if W.mouse_in(left, top, right - left, h) then
			SB.hover_ui, SB.hover_target = true, page.key
			SB.ui.lit_next[k == 1 and (W.ID.FIRST_NUM + row.type) or (W.ID.PAGE + page.type * 1000 + page.number)] = true
			if SB.buttons.pressed then SB.switch_page(player, page.key) end
			over = over or k > 1
		end
	end
	return over
end

-- The rest of a line stands for its first page: the panel's whole width and the line's whole
-- height (the lines touch, so moving between them never leaves a line), apart from the areas of
-- the numbers other than 1 and the arrows of "< 12/63 >" (over, from them). Under the mouse it
-- lights up the first page's parts, shows that page, and takes a click. Acted on after the line is
-- drawn, once it is known whether one of those is under the mouse.
local function line_area(player, row, px, y, width, over)
	if over or not W.mouse_in(px, y, width, ROW_H) then return end
	local page = row.list[1]
	SB.hover_ui, SB.hover_target = true, page.key
	SB.ui.lit_next[W.ID.PAGE + page.type * 1000 + 1] = true
	if SB.buttons.pressed then SB.switch_page(player, page.key) end
end

-- A box ("[x]" ticked, "[ ]" not), white while
-- ticked. Returns whether it was clicked.
local function box(gui, id, x, y, b, on)
	local clicked = W.button(gui, id, x, y, box_label(b, on), on and W.WHITE or W.DIM)
	GuiTooltip(gui, b[2], "")
	return clicked
end

-- The panel --------------------------------------------------------------------------------------

function SB.draw_panel(gui, player, sw, sh)
	local L = SB.layout()
	local text_w = list_text_width(gui)
	local rows = page_rows(gui, L, text_w)
	-- the title bar, the two boxes, the page list, then the search box
	local width = ICON_COL + text_w + PANEL_PAD_X * 2
	local collapsed = panel_collapsed()
	local height = collapsed and (TITLE_H + 1)
		or (TITLE_H + 1 + PANEL_PAD * 2 + LINE_H + (LINE_H + 2) + W.SEARCH_H + (#rows > 0 and #rows * ROW_H or LINE_H))
	local px, py = place_panel(width, height, sw, sh)
	W.z = W.Z_PANEL

	-- the background: the game's own panel graphic, behind everything else here
	GuiZSetForNextWidget(gui, W.Z_PANEL + 30)
	GuiImageNinePiece(gui, W.ID.PANEL, px, py, width, height)
	-- a transparent area over the whole panel: a press on it isn't a press in the inventory
	SB.ui.list_box = { px, py }
	if W.hit_area(gui, W.ID.LIST_HIT, px, py, width, height, W.Z_PANEL + 20) then SB.hover_ui = true end

	title_bar(gui, player, px, py, width, collapsed)
	if collapsed then
		W.z = W.Z_HUD
		return
	end
	local x, y = px + PANEL_PAD_X, py + TITLE_H + 1 + PANEL_PAD

	local merged = not SB.categorize()
	if box(gui, W.ID.MERGE, x, y, MERGE_BOX, merged) then SB.set_merge_categories(player, not merged) end
	y = y + LINE_H
	local hidden = not SB.show_unowned()
	if box(gui, W.ID.HIDE_UNOWNED, x, y, HIDE_BOX, hidden) then SB.set_hide_unowned(player, not hidden) end
	y = y + LINE_H + 2

	if #rows == 0 then
		W.text(gui, x, y, "No spells yet", W.DIM)
		y = y + LINE_H
	end
	for _, row in ipairs(rows) do
		local over = false
		row_card(gui, row, x, y)
		local nx = first_page_button(gui, player, row, x, y)
		if row.pager then
			over = pager(gui, player, nx, y + NUMS_IN_ROW, row)
		elseif #row.list > 1 then
			local xs, ws = { x + ICON_COL }, { W.text_width(gui, "1") }
			for k = 2, #row.list do
				nx = nx + row.gap
				xs[k] = nx
				ws[k] = page_button(gui, player, nx, y + NUMS_IN_ROW, row.list[k], tostring(k))
				nx = nx + ws[k]
			end
			over = number_areas(player, row, xs, ws, y + NUMS_IN_ROW, px + width)
		end
		line_area(player, row, px, y, width, over)
		y = y + ROW_H
	end
	-- the search box at the bottom, under the Copies and Search lines, as wide as the panel's inside
	SB.draw_search_box(gui, player, x, y + 2, ICON_COL + text_w)
	W.z = W.Z_HUD
end
