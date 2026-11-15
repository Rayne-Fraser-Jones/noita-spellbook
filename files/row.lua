-- Spellbook: keeping the vanilla spell row in line with the spellbook.
--
-- While the inventory is open, the spell row shows one page (pages.lua): a real card for each
-- group on it, in its slot. These cards are "reps" (representatives): cards the spellbook made,
-- marked (cards.lua), each standing for one copy of a group. The player moves them with the
-- game's own controls, and the spellbook shows the group's next copy in its place. The game
-- keeps a dragged card in the row until the mouse is released, so the spellbook only acts when
-- no mouse button is held and the row has settled, and works out what happened from where the
-- cards ended up (SB.reconcile):
--   * a card went into a wand, or was thrown out of the inventory: one copy left the spellbook
--     (if a wand spell was dropped onto the card instead, the game swapped the two; the card is
--     taken back out of the wand);
--   * a card moved to another slot of the row: it is replaced in its slot (pages are always in
--     order);
--   * a card came into the row from outside (from a wand, or picked up): it is stored, and the
--     page it is on is selected, so it stays in view.
-- While the inventory is closed the row is kept empty, so picking up a spell always works;
-- picked-up spells go straight into the spellbook.
--
-- Rules: the row is never changed (cards made, killed or moved, or a refresh asked for) while a
-- mouse button is held; only cards whose slot has read the same for two frames are acted on.

dofile_once("data/scripts/gun/procedural/gun_action_utils.lua")   -- CreateItemActionEntity

SB.reps     = SB.reps or {}       -- card entity -> group kind, for the cards the spellbook placed
SB.rep_slot  = SB.rep_slot or {}   -- card entity -> the slot it was placed in
SB.rep_seen  = SB.rep_seen or {}   -- card entity -> true once it has been seen in the row
SB.pressed   = SB.pressed or {}    -- card entity -> syncs left, after the player pressed on it
SB.unshown   = SB.unshown or {}    -- group kind -> true for groups that can't be shown as a card
SB.last_slot = SB.last_slot or {}  -- card entity -> its slot last frame
-- SB.row_sig: what the row was last filled with (SB.page_sig of that page); SB.ran_full: the last
-- sync got past the wait for held buttons and settled cards; SB.needs_refresh: the game must be
-- told to show the row's changes.

-- A press on one of the spellbook's cards is remembered through this many syncs that ran to the
-- end after the release: the game moves a released card within a few frames.
local PRESS_RUNS = 3

function SB.card_pressed(e) SB.pressed[e] = PRESS_RUNS end

-- What is in the spell row right now: { player, full, sx, sy, cap, cards, by_entity, by_slot },
-- each card { entity, id, uses, slot } (slots from 1). nil without an inventory.
function SB.row_snapshot(player)
	local full = SB.inventory_full(player)
	local inv2 = SB.inventory2(player)
	if not full or not inv2 then return nil end
	local sx = ComponentGetValue2(inv2, "full_inventory_slots_x")
	local sy = ComponentGetValue2(inv2, "full_inventory_slots_y")
	local snap = { player = player, full = full, sx = sx, sy = sy, cap = sx * sy, cards = {}, by_entity = {}, by_slot = {} }
	for _, child in ipairs(EntityGetAllChildren(full) or {}) do
		local id, uses = SB.card_spell(child)
		if id then
			local ic = EntityGetFirstComponentIncludingDisabled(child, "ItemComponent")
			local x, y = 0, 0
			if ic then x, y = ComponentGetValue2(ic, "inventory_slot") end
			local card = { entity = child, id = id, uses = uses, slot = (y or 0) * sx + (x or 0) + 1 }
			snap.cards[#snap.cards + 1] = card
			snap.by_entity[child] = card
			snap.by_slot[card.slot] = card
		end
	end
	SB.capacity = snap.cap
	return snap
end

local function forget_rep(e)
	SB.reps[e], SB.rep_slot[e], SB.rep_seen[e], SB.pressed[e] = nil, nil, nil, nil
end

-- Forgets every card the spellbook placed, and what the row was filled with.
local function forget_row()
	SB.reps, SB.rep_slot, SB.rep_seen, SB.pressed, SB.unshown, SB.last_slot = {}, {}, {}, {}, {}, {}
	SB.row_sig = nil
end

-- Removes a card from the row (and from the snapshot).
local function kill_card(snap, c)
	SB.remove_card(c.entity)
	c.dead = true
	snap.by_entity[c.entity] = nil
	if snap.by_slot[c.slot] == c then snap.by_slot[c.slot] = nil end
	forget_rep(c.entity)
	SB.needs_refresh = true
end

local function slot_xy(snap, slot)
	return (slot - 1) % snap.sx, math.floor((slot - 1) / snap.sx)
end

-- Places a card for a group in a slot. Groups that can't be shown as a card are drawn as a faded
-- placeholder instead (SB.unshown); they are tried again after the row is next emptied (page
-- change, inventory closed).
local function spawn_card(snap, g, slot)
	if SB.unshown[g.kind] then return nil end
	if SB.info(g.id).unknown and next(SB.actions or {}) then
		-- not in the game's spell list: the mod that added it is probably disabled
		SB.unshown[g.kind] = true
		SB.log(g.id .. ": not in the game's spell list; shown as a placeholder")
		return nil
	end
	local x, y = EntityGetTransform(snap.player)
	local card = CreateItemActionEntity(g.id, x, y)
	if card == nil or card == 0 then
		SB.unshown[g.kind] = true
		SB.log(g.id .. ": the game made no card; shown as a placeholder")
		return nil
	end
	SB.set_card_uses(card, g.uses)
	GamePickUpInventoryItem(snap.player, card, false)
	local ic = EntityGetFirstComponentIncludingDisabled(card, "ItemComponent")
	if ic then ComponentSetValue2(ic, "inventory_slot", slot_xy(snap, slot)) end
	local c = { entity = card, id = g.id, uses = g.uses, slot = slot }
	snap.cards[#snap.cards + 1] = c
	snap.by_entity[card] = c
	snap.by_slot[slot] = c
	SB.reps[card], SB.rep_slot[card] = g.kind, slot
	SB.mark(card)
	SB.needs_refresh = true
	SB.log(SB.info(g.id).name .. ": card " .. card .. " placed in slot " .. slot)
	return card
end

-- The sync ------------------------------------------------------------------------------

local function remember_slots(snap)
	local seen = {}
	for _, c in ipairs(snap.cards) do
		if not c.dead then seen[c.entity] = c.slot end
	end
	SB.last_slot = seen
end

-- Brings the spellbook and the row in line. Returns true if anything changed. Sets SB.ran_full
-- when it got past the wait for held buttons and settled cards.
function SB.reconcile(snap)
	local changed = false
	SB.ran_full = false

	for _, c in ipairs(snap.cards) do
		if not c.dead and SB.reps[c.entity] then SB.rep_seen[c.entity] = true end
	end

	-- Nothing in the row is touched while a mouse button is held, so a drag in progress is never
	-- disturbed. A card dropped into the row can report its old position (from a wand) for a
	-- frame, so cards are only acted on once their position is the same two frames running.
	local settled = true
	for _, c in ipairs(snap.cards) do
		if not c.dead and SB.last_slot[c.entity] ~= c.slot then settled = false end
	end
	if SB.button_held() or not settled then
		if not settled then SB.log("waiting for the row to settle") end
		remember_slots(snap)
		return false
	end

	-- Cards in the row the spellbook didn't place: from a wand, or picked up.
	local arrivals = {}
	for _, c in ipairs(snap.cards) do
		if not c.dead and not SB.reps[c.entity] then arrivals[#arrivals + 1] = c end
	end

	-- 1. Cards the spellbook placed that are no longer in the row.
	for e, kind in pairs(SB.reps) do
		if not snap.by_entity[e] then
			local g = SB.groups[kind]
			local alive = EntityGetIsAlive(e)
			local parent = alive and EntityGetParent(e) or -1
			local in_wand = alive and parent ~= 0 and EntityHasTag(parent, "wand")
			local seen, pressed = SB.rep_seen[e], SB.pressed[e]
			-- a wand spell now in its slot: the game swapped the two (one dropped onto it)
			local in_its_slot = SB.rep_slot[e] and snap.by_slot[SB.rep_slot[e]]
			local swapped = in_its_slot ~= nil and not in_its_slot.dead and not SB.reps[in_its_slot.entity]
			local name = g and SB.info(g.id).name or kind
			forget_rep(e)
			changed = true
			if not g then
				-- its group is already gone
			elseif alive and parent == 0 and not seen then
				-- the game never put it in the row; its copy is still counted in the group
				EntityKill(e)
				SB.unshown[kind] = true
				SB.log(name .. ": card " .. e .. " never reached the row; shown as a placeholder")
			elseif in_wand and not pressed and swapped then
				-- a wand spell was dropped onto this card, and the game swapped the two: the card is
				-- taken back out of the wand (the dropped spell is stored, below). Without a wand
				-- spell in its slot, it was moved into the wand, even with no press on it seen (the
				-- mouse reached it in the press's frame, or a gamepad).
				SB.remove_card(e)
				SB.wands_changed = true
				SB.log(name .. ": swapped into a wand by a wand spell dropped onto it; taken back out")
			else
				-- dragged into a wand, thrown out of the inventory, or gone some other way: one copy
				-- has left the spellbook
				if alive then SB.unmark(e) end
				SB.change_count(g, -1)
				SB.log(name .. ": one copy " .. (in_wand and "went into a wand" or (parent == 0 and "was thrown" or "left"))
					.. ", " .. g.count .. " left")
			end
		end
	end

	-- 2. Cards the spellbook placed that are still in the row.
	for _, c in ipairs(snap.cards) do
		local kind = not c.dead and SB.reps[c.entity]
		if kind then
			local g = SB.groups[kind]
			if not g then
				-- its group is gone: its copies were moved to another group (the refresher, the
				-- Unlimited spells perk), which counts this card's copy too, so the card goes
				SB.log(SB.info(c.id).name .. ": card " .. c.entity .. " of a group that has gone; removed")
				kill_card(snap, c)
				changed = true
			elseif SB.kind(c.id, c.uses) ~= kind then
				-- its uses changed: it is stored again as what it is now
				forget_rep(c.entity)
				SB.unmark(c.entity)
				SB.change_count(g, -1)
				arrivals[#arrivals + 1] = c
				changed = true
			elseif SB.rep_slot[c.entity] ~= c.slot then
				-- moved within the row: pages are always in order. Setting its slot back doesn't
				-- stick (the game undoes it, seen in play), so the card is removed (its copy is still
				-- counted in its group) and a new one is placed in its slot, as for a copy taken
				-- (step 4)
				SB.log(SB.info(c.id).name .. ": moved to slot " .. c.slot .. "; replaced in slot " .. SB.rep_slot[c.entity])
				kill_card(snap, c)
				changed = true
			end
		end
	end

	-- 3. Cards that came from outside: stored, and their page selected.
	for _, c in ipairs(arrivals) do
		if not c.dead then
			SB.store(c.id, c.uses, "put in the spell row")
			kill_card(snap, c)
			changed = true
		end
	end

	-- 4. If the page shown still holds what the row was filled with, slots that should show a card
	-- but don't get one (a group's next copy, after one was taken). Otherwise the whole row is
	-- refilled (SB.update_display).
	local page = SB.page(SB.shown)
	if SB.shown and SB.page_sig(page) == SB.row_sig then
		-- (by slot: on a copies page one group fills several slots)
		local filled = {}
		for e in pairs(SB.reps) do filled[SB.rep_slot[e]] = true end
		for i, en in ipairs(page.entries) do
			local g = en.group
			if g and i <= snap.cap and not filled[i] and not snap.by_slot[i] then
				if spawn_card(snap, g, i) then changed = true end
			end
		end
	end
	remember_slots(snap)
	for e, n in pairs(SB.pressed) do SB.pressed[e] = (n > 1) and (n - 1) or nil end
	SB.ran_full = true
	return changed
end

-- Emptying and refilling -----------------------------------------------------------------

-- Works out what happened in the row, then removes the spellbook's cards from it. Their copies
-- are already counted in the spellbook.
function SB.empty_row(snap)
	SB.reconcile(snap)
	for e, kind in pairs(SB.reps) do
		local c = snap.by_entity[e]
		if c then
			kill_card(snap, c)
		else
			local g = SB.groups[kind]
			if g then SB.change_count(g, -1) end
			if EntityGetIsAlive(e) then SB.unmark(e) end
		end
	end
	forget_row()
end

-- Runs a change with the row emptied first, and refills the row with the page to show.
function SB.relayout(player, fn)
	local snap = SB.row_snapshot(player)
	if not snap then return end
	SB.empty_row(snap)
	if fn then fn() end
	SB.selected = SB.resolve(SB.selected)
	SB.shown = SB.resolve(SB.shown or SB.selected)
	SB.row_sig = SB.page_sig(SB.page(SB.shown))
	SB.reconcile(snap)
	SB.save()
	SB.force_refresh(player)
end

-- True while the row can be emptied and refilled: no button held, the last sync ran to the end,
-- and no card the player pressed on is still waiting to be worked out.
function SB.row_quiet()
	return not SB.button_held() and SB.ran_full == true and next(SB.pressed) == nil
end

-- After the game changed the uses of the cards the player carries (the refresher, the Unlimited
-- spells perk), the spellbook's cards in the row get their group's uses back: they stand for the
-- group's copy, so they aren't taken for new cards.
function SB.reset_row_uses(snap)
	for _, c in ipairs(snap.cards) do
		local g = SB.groups[SB.reps[c.entity] or ""]
		if g and c.uses ~= g.uses then
			SB.set_card_uses(c.entity, g.uses)
			c.uses = g.uses
		end
	end
end

-- Cards in the row while the inventory is closed are pickups: each is stored, with a message.
function SB.store_pickups(snap)
	local changed = false
	for _, c in ipairs(snap.cards) do
		if not c.dead and not SB.reps[c.entity] then
			SB.store(c.id, c.uses, "picked up")
			SB.message(SB.info(c.id).name .. " stored (" .. SB.page(SB.selected).name .. ")")
			kill_card(snap, c)
			changed = true
		end
	end
	return changed
end

-- Takes over the spell row of a player entity the spellbook hasn't seen yet: when the game is
-- loaded, or when the player entity is replaced (polymorph and back). Marked cards were placed by
-- the spellbook and are already counted in their groups; anything else in the row is stored.
function SB.take_over_row(player)
	local snap = SB.row_snapshot(player)
	local killed = {}
	if snap then
		for _, c in ipairs(snap.cards) do
			if not SB.is_marked(c.entity) then SB.add(c.id, c.uses, 1) end
			kill_card(snap, c)
			killed[c.entity] = true
		end
	end
	-- A marked card outside the row was on the cursor (or just dropped) at that moment, or is in a
	-- wand (dragged or swapped there, not yet worked out). It was still counted in the spellbook,
	-- so it is taken off its group now: its copy is the cursor's or the wand's. The row's cards
	-- killed just above are skipped: the game removes them only at the end of the frame, so until
	-- then they are still listed here, with no parent (seen in play: every shown spell lost a copy
	-- on each load).
	for _, e in ipairs(EntityGetWithTag("card_action") or {}) do
		local parent = (not killed[e] and EntityGetIsAlive(e)) and EntityGetParent(e) or nil
		local outside = parent == 0 or (parent ~= nil and EntityHasTag(parent, "wand"))
		if outside and SB.is_marked(e) then
			local id, uses = SB.card_spell(e)
			local g = id and SB.groups[SB.kind(id, uses)]
			if g then SB.change_count(g, -1) end
			SB.unmark(e)
		end
	end
	forget_row()
	SB.shown = nil
end
