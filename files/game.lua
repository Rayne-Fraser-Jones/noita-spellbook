-- Spellbook: what runs each frame (SB.tick, from init.lua): the mouse, the spell refresher, the
-- Unlimited spells perk and the sync, in that order; and taking over the player entity when the
-- game is loaded or the player is replaced (polymorph and back).

-- The spell refresher's script (spell_refresh_append.lua, in another Lua state) sets this global
-- value when a refresher is picked up. The last request done is kept with the run, so one still
-- waiting when the game is saved (picked up during a drag) is done after loading.
SB.REFRESH_KEY = "spellbank_refresh_request"
local REFRESH_DONE_KEY = "spellbank2_refresh_done"

-- The player ------------------------------------------------------------------------------

function SB.prepare(player)
	SB.restore_controls(player)
	SB.load_actions()
	SB.row_snapshot(player)   -- reads the row's size before loading
	SB.load()
	-- ("-": none done yet. Not there at all: a run saved before this was kept, whose request is
	-- taken as done, as it was then.)
	local done = GlobalsGetValue(REFRESH_DONE_KEY, "")
	if done == "" then done = GlobalsGetValue(SB.REFRESH_KEY, "") elseif done == "-" then done = "" end
	SB.last_refresh = done
	GlobalsSetValue(REFRESH_DONE_KEY, done ~= "" and done or "-")
	SB.player = player
	SB.take_over_row(player)
	SB.save()
end

-- The inventory was closed, or the player entity replaced: what was under the mouse and any press
-- in progress are forgotten, and the next time the inventory opens, the row shows the selected
-- page.
function SB.inventory_closed(player)
	SB.hover_card, SB.hover_target, SB.hover_ui = nil, nil, nil
	SB.press, SB.double_click, SB.last_wand_click, SB.wand_press = nil, nil, nil, nil
	SB.dragging, SB.drag_from, SB.drag_started = nil, nil, false
	SB.preview, SB.hover_cand = nil, nil
	SB.shown = nil
	SB.ui_closed()
	SB.restore_controls(player)
end

-- The player entity was replaced (polymorph and back). The spellbook's cards in the old row are
-- gone; the new row holds copies of them, which are already counted.
function SB.player_changed(player)
	SB.log("player entity changed: " .. tostring(SB.player) .. " -> " .. tostring(player))
	SB.player = player
	SB.inventory_closed(player)
	SB.take_over_row(player)
	SB.save()
end

-- The mouse ----------------------------------------------------------------------------------
-- Presses and releases, with the inventory open. What is under the mouse comes from the previous
-- frame's drawing (SB.hover_card: one of the spellbook's cards; SB.hover_ui: the spellbook's
-- buttons and panel; SB.mouse: the mouse in UI pixels).

local DOUBLE_CLICK_FRAMES = 30   -- two clicks on the same wand spell within this many frames
local CLICK_MOVE = 3             -- a press let go further than this (UI pixels) from where it was
                                 -- made is a drag, not a click

local function on_press(player)
	local e = SB.hover_card
	if e and SB.reps[e] then
		-- on one of the spellbook's cards: it may be dragged (the drawing shows the next copy in its
		-- slot once the mouse moves away with the button held)
		SB.card_pressed(e)
		SB.press = "card"
		SB.dragging, SB.drag_from, SB.drag_started = e, SB.mouse and { SB.mouse[1], SB.mouse[2] }, false
		local g = SB.groups[SB.reps[e]]
		SB.log("mouse pressed on " .. SB.info(g and g.id or "?").name)
	elseif not SB.hover_ui then
		-- somewhere else in the inventory: maybe on a wand spell (found from the measured wand
		-- panels). A second click on the same one soon after is a double-click; only clicks count,
		-- not drags, so a click and then a drag of the same spell moves it.
		SB.press = "inventory"
		local card = SB.mouse and SB.wand_card_at(player, SB.mouse[1], SB.mouse[2])
		SB.wand_press = card and { entity = card.entity, frame = SB.frame, x = SB.mouse[1], y = SB.mouse[2] } or nil
		local last = SB.last_wand_click
		if card and last and last.entity == card.entity and SB.frame - last.frame <= DOUBLE_CLICK_FRAMES then
			SB.double_click = { entity = card.entity }
			SB.last_wand_click = nil
			SB.log("double-click on " .. SB.info(card.id).name .. " in a wand (if let go where pressed)")
		else
			SB.log("mouse pressed" .. (card and (" on " .. SB.info(card.id).name .. " in a wand") or ""))
		end
	else
		SB.press = nil
	end
end

local function on_release()
	-- the game also counts letting go of a dragged spell over a button as a click on it (seen in
	-- play); the spellbook's buttons ignore that click
	if SB.press then SB.drag_released = SB.frame end
	SB.dragging, SB.drag_from, SB.drag_started = nil, nil, false
	-- a press on a wand spell let go where it was made is a click
	local p = SB.wand_press
	local m = SB.mouse
	local moved = p ~= nil and (m == nil or math.abs(m[1] - p.x) > CLICK_MOVE or math.abs(m[2] - p.y) > CLICK_MOVE)
	if SB.double_click and not SB.double_click.released then
		if moved then
			SB.log("the second press was a drag: not a double-click")
			SB.double_click = nil
		else
			SB.double_click.released = SB.frame
		end
	elseif p and not moved then
		SB.last_wand_click = { entity = p.entity, frame = p.frame }
	else
		SB.last_wand_click = nil
	end
	SB.wand_press = nil
	SB.log("mouse released (under the mouse " .. tostring(SB.hover_target) .. ")")
	SB.press = nil
end

local function track_mouse(player)
	local b = SB.buttons
	-- (a press in progress with the button up is released, also if the release came on a frame
	-- this didn't run: no player entity for a frame, say; otherwise a double-click stayed waiting)
	local pending = SB.press ~= nil or SB.wand_press ~= nil or SB.dragging ~= nil
	if b.pressed then on_press(player) elseif pending and not b.left then on_release() end
	-- a right press on one of the spellbook's cards: its spell's copies pages
	if b.right_pressed then
		local kind = SB.hover_card and SB.reps[SB.hover_card]
		local g = kind and SB.groups[kind]
		if g then SB.show_copies(player, g.id) end
	end
end

-- The game changing the spells the player carries -----------------------------------------

-- The Unlimited spells perk: the game makes the cards the player has unlimited (the row's too),
-- but the spellbook's other copies are counts, so their groups are made unlimited here, and so
-- are limited copies stored later. With the inventory open the row is emptied and refilled, so
-- this waits while a mouse button is held. Returns true if anything changed.
local function apply_unlimited_spells(player, snap, open, held)
	if held or not SB.unlimited_spells() or #SB.limited_groups() == 0 then return false end
	SB.reset_row_uses(snap)
	local function make_unlimited() SB.log("Unlimited spells: " .. SB.make_unlimited() .. " groups made unlimited") end
	-- (with the inventory closed the row is empty, and stays so: only the groups change)
	if open then SB.relayout(player, make_unlimited) else make_unlimited() end
	return true
end

-- A spell refresher picked up: every limited-uses group is refilled. With the inventory open the
-- row is emptied first (it is refilled by the sync), so this waits while a mouse button is held.
-- Returns true if anything changed.
local function apply_refresher(snap, was_open, held)
	local request = GlobalsGetValue(SB.REFRESH_KEY, "")
	if request == SB.last_refresh or (was_open and held) then return false end
	SB.last_refresh = request
	GlobalsSetValue(REFRESH_DONE_KEY, request)
	if was_open then
		-- the game refills the cards in the row as well
		SB.reset_row_uses(snap)
		SB.empty_row(snap)
	end
	SB.refresh_uses()
	return true
end

-- Each frame -------------------------------------------------------------------------------

function SB.tick(player, open, was_open)
	SB.frame = SB.frame + 1
	local snap = SB.row_snapshot(player)
	if not snap then return end
	local held = SB.button_held()
	if open then track_mouse(player) end

	local changed = apply_unlimited_spells(player, snap, open, held)
	changed = apply_refresher(snap, was_open, held) or changed

	if open then
		if not was_open then changed = SB.store_pickups(snap) or changed end
		changed = SB.reconcile(snap) or changed
		-- a double-clicked wand spell, a moment after the release (the game puts the card back in
		-- its slot when the button is let go)
		local dc = SB.double_click
		if dc and dc.released and not held and SB.frame - dc.released >= 2 then
			SB.double_click = nil
			SB.take_from_wand(player, dc.entity)
		end
		SB.update_display(player)
	else
		if was_open then
			SB.empty_row(snap)
			changed = true
		end
		changed = SB.store_pickups(snap) or changed
	end

	if SB.wands_changed then
		SB.wands_changed = false
		SB.needs_refresh = false
		SB.refresh_wands(player)
	elseif SB.needs_refresh then
		SB.needs_refresh = false
		SB.force_refresh(player)
	end
	if changed then SB.save() end
end
