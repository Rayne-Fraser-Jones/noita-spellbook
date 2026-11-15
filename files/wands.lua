-- Spellbook: wands: their spells, where their spells are drawn in the inventory, whether they can
-- be edited here, and storing spells from them (Store all: Held wand / All wands, and
-- double-clicking a wand spell).

-- A wand's spell cards that can be moved (not always-cast), left to right; how many slots it
-- has for them (slots are numbered from 0); and how many always-cast spells it has.
function SB.wand_layout(wand)
	local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
	local capacity = ability and ComponentObjectGetValue2(ability, "gun_config", "deck_capacity") or 0
	local cards, always = {}, 0
	for _, card in ipairs(EntityGetAllChildren(wand) or {}) do
		local id, uses = SB.card_spell(card)
		local ic = EntityGetFirstComponentIncludingDisabled(card, "ItemComponent")
		if id and ic then
			if ComponentGetValue2(ic, "permanently_attached") then
				always = always + 1
			else
				cards[#cards + 1] = { entity = card, x = ComponentGetValue2(ic, "inventory_slot"), id = id, uses = uses }
			end
		end
	end
	table.sort(cards, function(a, b) return a.x < b.x end)
	-- always-cast spells are counted in the capacity but don't take a slot
	return cards, math.max(0, capacity - always), always
end

-- The wand selected in the quickbar, or nil and why there isn't one.
function SB.selected_wand(player)
	local inv2 = SB.inventory2(player)
	local item = inv2 and ComponentGetValue2(inv2, "mActiveItem")
	if not item or item == 0 or not EntityGetIsAlive(item) or not EntityHasTag(item, "wand") then
		return nil, "Select a wand in the quickbar first"
	end
	return item
end

-- The wands in the quickbar, in quickbar order.
function SB.all_wands(player)
	local wands = {}
	for _, child in ipairs(EntityGetAllChildren(player) or {}) do
		if EntityGetName(child) == "inventory_quick" then
			for _, item in ipairs(EntityGetAllChildren(child) or {}) do
				if EntityHasTag(item, "wand") then
					local ic = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
					wands[#wands + 1] = { entity = item, q = ic and ComponentGetValue2(ic, "inventory_slot") or 0 }
				end
			end
		end
	end
	table.sort(wands, function(a, b) return a.q < b.q or (a.q == b.q and a.entity < b.entity) end)
	local list = {}
	for i, w in ipairs(wands) do list[i] = w.entity end
	return list
end

-- The inventory's wand panels, measured from screenshots (640 x 360 UI): one panel per wand in
-- the quickbar, in quickbar order (an empty wand slot has no panel); every panel is the same
-- height (the full stats are only in the tooltip); a panel's slot row starts at y 81 for the
-- first panel and 61 lower for each next one; slots start at x 26, 20 apart, 18 wide. Panels can
-- sit a few pixels lower than this, so the rows are matched with some margin.
local WAND_SLOTS_X, WAND_SLOTS_Y, WAND_PANEL_PITCH, WAND_SLOT_PITCH, WAND_SLOT_BOX = 26, 81, 61, 20, 18
local WAND_ROW_MARGIN = 4
local WAND_ONE_ROW = 26   -- the most slots seen on one line

-- The wand spell under the mouse (UI pixels) in the wand panels, as { entity, x, id, uses }, or
-- nil. A wand with always-cast spells or more than 26 slots hasn't been seen laid out, so from
-- such a wand's panel on, nothing is guessed.
function SB.wand_card_at(player, mx, my)
	for k, wand in ipairs(SB.all_wands(player)) do
		local cards, usable, always = SB.wand_layout(wand)
		if always > 0 or usable > WAND_ONE_ROW then return nil end
		local top = WAND_SLOTS_Y + (k - 1) * WAND_PANEL_PITCH
		if my >= top - WAND_ROW_MARGIN and my <= top + WAND_SLOT_BOX + WAND_ROW_MARGIN then
			local dx = mx - WAND_SLOTS_X
			local x = math.floor(dx / WAND_SLOT_PITCH)
			if dx < 0 or x >= usable or dx - x * WAND_SLOT_PITCH > WAND_SLOT_BOX then return nil end
			for _, c in ipairs(cards) do
				if c.x == x then return c end
			end
			return nil
		end
	end
	return nil
end

-- Editing wands ---------------------------------------------------------------------------

local function in_workshop(player)
	local px, py = EntityGetTransform(player)
	for _, tag in ipairs({ "workshop_aabb", "workshop" }) do
		for _, e in ipairs(EntityGetWithTag(tag) or {}) do
			local ex, ey = EntityGetTransform(e)
			for _, hb in ipairs(EntityGetComponentIncludingDisabled(e, "HitboxComponent") or {}) do
				local x1 = ex + ComponentGetValue2(hb, "aabb_min_x")
				local x2 = ex + ComponentGetValue2(hb, "aabb_max_x")
				local y1 = ey + ComponentGetValue2(hb, "aabb_min_y")
				local y2 = ey + ComponentGetValue2(hb, "aabb_max_y")
				if px >= x1 and px <= x2 and py >= y1 and py <= y2 then return true end
			end
		end
	end
	return false
end

-- How much the player may edit wands, as a level (the user's understanding of the game; not
-- confirmed): a Holy Mountain's workshop area counts 1, each EDIT_WANDS_EVERYWHERE effect
-- ("Tinker With Wands Everywhere": the perk, the potion effect, the meditation cube) adds 1,
-- and each NO_WAND_EDITING effect ("No Wand Tinkering": the perk, or its potion effect) takes 1
-- away. Wands can be edited while it is above 0, so the two perks cancel out: editing only in a
-- Holy Mountain.
function SB.wand_edit_level(player)
	return (in_workshop(player) and 1 or 0)
		+ GameGetGameEffectCount(player, "EDIT_WANDS_EVERYWHERE")
		- GameGetGameEffectCount(player, "NO_WAND_EDITING")
end

-- Why wands can't be edited here, or nil if they can. short: for a button's tooltip, under what
-- the button does: just that it can't be done here.
function SB.wand_edit_blocked(player, short)
	if SB.wand_edit_level(player) > 0 then return nil end
	if short then return "You cannot tinker with wands here" end
	if GameGetGameEffectCount(player, "NO_WAND_EDITING") > 0 then
		return "Wand editing is blocked by " .. GameTextGetTranslatedOrNot("$perk_no_wand_editing")
	end
	return "Wands can only be edited in a Holy Mountain, or anywhere with " .. GameTextGetTranslatedOrNot("$perk_edit_wands_everywhere")
end

-- Storing from wands ----------------------------------------------------------------------

-- The spells "Store all" would take: from the held wand (which = "held") or from every wand
-- ("all"). Returns the cards, or nil and why the button can't be used now (short: for its
-- tooltip).
function SB.from_wands_cards(player, which, short)
	local wands
	if which == "held" then
		local wand, why = SB.selected_wand(player)
		if not wand then return nil, why end
		wands = { wand }
	else
		wands = SB.all_wands(player)
		if #wands == 0 then return nil, "You have no wands" end
	end
	local why = SB.wand_edit_blocked(player, short)
	if why then return nil, why end
	local cards = {}
	for _, w in ipairs(wands) do
		for _, c in ipairs((SB.wand_layout(w))) do cards[#cards + 1] = c end
	end
	if #cards == 0 then
		return nil, which == "held" and "Your held wand has no spells to store" or "Your wands have no spells to store"
	end
	return cards
end

-- Store all: Held wand / All wands: every spell in the wand(s) is stored (always-cast spells
-- stay).
function SB.from_wands(player, which)
	local cards, why = SB.from_wands_cards(player, which)
	if not cards then SB.message(why) return end
	SB.relayout(player, function()
		for _, c in ipairs(cards) do
			SB.add(c.id, c.uses, 1)
			SB.remove_card(c.entity)
		end
	end)
	SB.refresh_wands(player)
	local where = which == "held" and "your held wand" or "your wands"
	SB.log("from " .. where .. ": " .. #cards .. " spells stored")
	SB.message("stored " .. #cards .. (#cards == 1 and " spell" or " spells") .. " from " .. where)
end

-- A double-clicked wand spell is stored, if the card is still in a wand by then.
function SB.take_from_wand(player, e)
	if not EntityGetIsAlive(e) then return end
	local wand = EntityGetParent(e)
	if wand == 0 or not EntityHasTag(wand, "wand") then return end
	local id, uses = SB.card_spell(e)
	local ic = EntityGetFirstComponentIncludingDisabled(e, "ItemComponent")
	if not id or (ic and ComponentGetValue2(ic, "permanently_attached")) then return end
	local why = SB.wand_edit_blocked(player)
	if why then
		SB.message(why)
		return
	end
	SB.store(id, uses, "double-clicked in a wand")
	SB.remove_card(e)
	SB.wands_changed = true
	SB.save()
end
