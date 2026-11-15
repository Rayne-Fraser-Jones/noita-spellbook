-- Spellbook: the player's inventory and spell cards, as entities: finding them, reading a card,
-- the mark on the spellbook's own cards, removing cards, and telling the game to show changes.

function SB.get_player()
	local players = EntityGetWithTag("player_unit")
	return players and players[1] or nil
end

function SB.inventory2(player)
	return player and EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component") or nil
end

-- The player's child entity holding the spell row's cards.
function SB.inventory_full(player)
	for _, child in ipairs(EntityGetAllChildren(player) or {}) do
		if EntityGetName(child) == "inventory_full" then return child end
	end
	return nil
end

-- The spell on a card and its uses left (-1: unlimited), or nil if it isn't a spell card.
function SB.card_spell(e)
	local iac = EntityGetFirstComponentIncludingDisabled(e, "ItemActionComponent")
	if not iac then return nil end
	local ic = EntityGetFirstComponentIncludingDisabled(e, "ItemComponent")
	return ComponentGetValue2(iac, "action_id"), ic and ComponentGetValue2(ic, "uses_remaining") or -1
end

function SB.set_card_uses(e, uses)
	local ic = EntityGetFirstComponentIncludingDisabled(e, "ItemComponent")
	if ic then ComponentSetValue2(ic, "uses_remaining", uses) end
end

-- A card the spellbook placed in the row carries a VariableStorageComponent with this name, so
-- that one still there when the game is saved, or when the player entity is replaced, is known
-- as the spellbook's (its copy is already counted in its group).
local MARKER = "spellbank_rep"

local function find_marker(e)
	for _, c in ipairs(EntityGetComponentIncludingDisabled(e, "VariableStorageComponent") or {}) do
		if ComponentGetValue2(c, "name") == MARKER then return c end
	end
	return nil
end

function SB.is_marked(e) return find_marker(e) ~= nil end

function SB.mark(e)
	if not find_marker(e) then EntityAddComponent2(e, "VariableStorageComponent", { name = MARKER }) end
end

function SB.unmark(e)
	local c = find_marker(e)
	if c then EntityRemoveComponent(e, c) end
end

-- Removes a card from the inventory or a wand. (The game removes a killed entity only at the end
-- of the frame.)
function SB.remove_card(e)
	EntityRemoveFromParent(e)
	EntityKill(e)
end

-- The game's inventory display only shows cards a mod added or removed after a refresh.
function SB.force_refresh(player)
	local inv2 = SB.inventory2(player)
	if inv2 then ComponentSetValue2(inv2, "mForceRefresh", true) end
end

-- After cards are added to or removed from a wand, the game also needs to reload the wand.
function SB.refresh_wands(player)
	local inv2 = SB.inventory2(player)
	if inv2 then
		ComponentSetValue2(inv2, "mForceRefresh", true)
		ComponentSetValue2(inv2, "mActualActiveItem", 0)
	end
end
