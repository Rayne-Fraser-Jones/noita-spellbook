-- Spellbook: what is drawn at the vanilla spell row: beside the SPELLS label, the name of the page
-- shown and "Store all: Held wand / All wands"; over the row, the group counts, the next copy in
-- the slot of a card being dragged, and faded icons for spells you don't have (not with "Hide unowned") or
-- that can't be shown as a card.

local W = SB.widgets

local BUTTON_GAP = 8        -- space before "Store all:"
local DRAG_START = 3        -- how far the mouse moves from a press on a card before it counts as dragged

-- Beside the SPELLS label -------------------------------------------------------------------

-- "Store all: Held wand / All wands": "Store all:" and "/" the grey of SPELLS; the two buttons white while
-- they can be used. Otherwise a button is dark grey plain text (not a button, so the game doesn't
-- light it up under the mouse), and its tooltip says why under what it does.
local STORE_PARTS = {
	"Store all: ",
	{ id = W.ID.FROM_HELD, which = "held", label = "Held wand", tip = "Store every spell in your held wand" },
	" / ",
	{ id = W.ID.FROM_ALL, which = "all", label = "All wands", tip = "Store every spell in all your wands" },
}

local function store_button(gui, player, b, x, y)
	local cards, why = SB.from_wands_cards(player, b.which, true)
	if cards then
		if W.button(gui, b.id, x, y, b.label, W.WHITE) then SB.from_wands(player, b.which) end
		GuiTooltip(gui, b.tip, "")
	else
		W.label(gui, x, y, b.label, W.DIM)
		GuiTooltip(gui, b.tip, why)
	end
end

-- "Page: Projectiles 1", the name gold for the selected page and the hover yellow while looking
-- at another by resting the mouse on its name (the same yellow as that name). Then "Store all:
-- Held wand / All wands", at the right end of the spell row (or after the page name, if it is
-- long).
local function toolbar(gui, player, snap, x, y)
	local shown = SB.page(SB.shown or SB.selected)
	local right
	if shown.key == "none" then
		W.text(gui, x, y, shown.name, W.DIM)
		right = x + W.text_width(gui, shown.name)
	else
		W.text(gui, x, y, "Page:", W.LABEL)   -- the grey of the SPELLS label
		local nx = x + W.text_width(gui, "Page: ")
		W.text(gui, nx, y, shown.name, SB.previewing() and W.VIEW or W.GOLD)
		right = nx + W.text_width(gui, shown.name)
	end
	local function part_text(p) return type(p) == "table" and p.label or p end
	local width = 0
	for _, p in ipairs(STORE_PARTS) do width = width + W.text_width(gui, part_text(p)) end
	local bx = math.max(W.ROW_X + snap.sx * W.PITCH - 2 - width, right + BUTTON_GAP)
	for _, p in ipairs(STORE_PARTS) do
		if type(p) == "table" then store_button(gui, player, p, bx, y) else W.text(gui, bx, y, p, W.LABEL) end
		bx = bx + W.text_width(gui, part_text(p))
	end
end

-- Over the spell row ------------------------------------------------------------------------

-- How many copies a slot stands for: every copy of the spell (all its groups), or one on a copies
-- page.
local function entry_count(en)
	if not en or not en.group then return 0 end
	if en.single then return 1 end
	local n = 0
	for _, g in ipairs(en.groups or { en.group }) do n = n + g.count end
	return n
end

local function slot_pos(snap, slot)
	local i = slot - 1
	return W.ROW_X + (i % snap.sx) * W.PITCH, W.ROW_Y + math.floor(i / snap.sx) * W.PITCH
end

-- The count in a slot's bottom-right corner, drawn like the game's uses count in the top-left
-- (1 in from the corner, measured from a screenshot). Only for more than one copy.
local function count_label(gui, x, y, n)
	if n <= 1 then return end
	local label = tostring(n)
	W.small_number(gui, x + W.SLOT_BOX - W.COUNT_DIGIT_W * #label, y + W.SLOT_BOX - 1 - W.COUNT_DIGIT_H, label, W.Z_HUD)
end

-- While a card is dragged out of the row, the game shows its slot empty, and the row isn't
-- changed until the button is let go. So the slot shows the copy that will take its place: the
-- card's background, the icon, its uses (top-left, as the game draws them) and the count one
-- less; nothing if that was the last copy (or on a copies page, one copy per slot).
local function next_copy(gui, x, y, en, kind)
	if not en or en.single or not en.groups then return end
	local left = entry_count(en) - 1
	if left < 1 then return end
	local g, nextg = SB.groups[kind], nil
	if g and g.count > 1 then
		nextg = g
	else
		for i, gg in ipairs(en.groups) do if gg == g then nextg = en.groups[i + 1] end end
	end
	if not nextg then return end
	local info = SB.info(nextg.id)
	W.image(gui, W.ID.DRAG_BG, x - 1, y - 1, W.CARD_BG[info.type] or W.CARD_BG[SB.TYPE_OTHER], 1, W.Z_HUD + 1)
	W.image(gui, W.ID.DRAG_ICON, x + 1, y + 1, info.sprite, 1, W.Z_HUD)
	if nextg.uses >= 0 then W.small_number(gui, x + 1, y + 1, tostring(nextg.uses), W.Z_HUD - 1) end
	count_label(gui, x, y, left)
end

-- The game lifts a pressed card out of its slot only once the mouse moves (seen in play: a press
-- alone left it there), so the next copy is drawn from when the mouse has moved DRAG_START from
-- where it was pressed, until the button is let go.
local function card_lifted()
	if not (SB.dragging and SB.buttons.left) then return false end
	if not SB.drag_started and SB.drag_from and SB.mouse then
		local dx, dy = SB.mouse[1] - SB.drag_from[1], SB.mouse[2] - SB.drag_from[2]
		if dx * dx + dy * dy >= DRAG_START * DRAG_START then
			SB.drag_started = true
			SB.log("card dragged (the mouse moved " .. math.floor(math.sqrt(dx * dx + dy * dy)) .. " from where it was pressed)")
		end
	end
	return SB.drag_started
end

-- Spells you don't have (not with "Hide unowned"), and groups that can't be shown as a card (usually: the
-- mod that added the spell is disabled), faded, with a tooltip. (Spell names in capitals, like the
-- game's own tooltips for cards.)
local function placeholder(gui, snap, i, en)
	local g = en.group
	local info = SB.info(en.id)
	local x, y = slot_pos(snap, i)
	GuiZSetForNextWidget(gui, W.Z_HUD)
	GuiImage(gui, W.ID.SLOT_FADED + i, x + 1, y + 1, info.sprite, 0.3, 1)
	if g then
		local n = entry_count(en)
		local why = info.unknown and ("Not in the game's spell list (ID " .. en.id .. ")\nThe mod that added it may be disabled")
			or "The game didn't show this spell"
		GuiTooltip(gui, string.upper(info.name), why .. "\nIts " .. n .. (n == 1 and " copy stays" or " copies stay") .. " in the spellbook")
		count_label(gui, x, y, n)
	else
		GuiTooltip(gui, string.upper(info.name), "You own no copies of this spell" .. (SB.is_locked(info) and "\nNot unlocked yet" or ""))
	end
end

-- Draws over the row. Returns the spellbook's card under the mouse, if any.
local function row_overlay(gui, snap)
	local lifted = card_lifted()
	local hovered_card = nil
	local entries = SB.shown and SB.page(SB.shown).entries or {}
	for e, kind in pairs(SB.reps) do
		local c = snap.by_entity[e]
		if c then
			local x, y = slot_pos(snap, c.slot)
			local en = entries[c.slot]
			if lifted and e == SB.dragging then
				next_copy(gui, x, y, en, kind)
			elseif en and en.group and en.group.kind == kind then
				count_label(gui, x, y, entry_count(en))
			end
			-- a transparent area over the card, only to tell where the mouse is
			GuiZSetForNextWidget(gui, W.Z_HUD + 10)
			if W.NO_SOUND then GuiOptionsAddForNextWidget(gui, W.NO_SOUND) end
			GuiImage(gui, W.ID.SLOT_HITBOX + c.slot, x, y, W.HITBOX, 1, 1)
			if W.hovered(gui) then hovered_card = e end
		end
	end
	for i, en in ipairs(entries) do
		if i <= snap.cap and not snap.by_slot[i] and (not en.group or SB.unshown[en.group.kind]) then
			placeholder(gui, snap, i, en)
		end
	end
	return hovered_card
end

-- Draws everything at the spell row; sets SB.hover_card.
function SB.draw_spell_row(gui, player, snap)
	toolbar(gui, player, snap, W.ROW_X + 40, W.ROW_Y - 14)
	SB.hover_card = row_overlay(gui, snap)
end
