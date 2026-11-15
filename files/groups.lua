-- Spellbook: what the spellbook holds, as groups, and saving it with the run.
--
-- A group is every copy of one spell with one exact number of uses left: "Bomb, 3 uses" and
-- "Bomb, 0 uses" are two groups. There is only ever one group of each kind ("ID#uses"). Groups
-- are made and removed only by SB.add and SB.change_count, which raise SB.version when they do,
-- so the pages (pages.lua) are worked out again. No entity code.

SB.groups  = SB.groups or {}    -- kind -> { kind, id, uses, count }; uses -1: unlimited
SB.version = SB.version or 0    -- goes up whenever a group is made or removed

function SB.kind(id, uses) return id .. "#" .. uses end

-- Adds n copies of a spell: to its group, or as a new group. Returns the group.
function SB.add(id, uses, n)
	local k = SB.kind(id, uses)
	local g = SB.groups[k]
	if g then
		g.count = g.count + n
	else
		g = { kind = k, id = id, uses = uses, count = n }
		SB.groups[k] = g
		SB.version = SB.version + 1
	end
	return g
end

-- Changes a group's count. A group with no copies left is removed.
function SB.change_count(g, d)
	g.count = g.count + d
	if g.count <= 0 and SB.groups[g.kind] == g then
		SB.groups[g.kind] = nil
		SB.version = SB.version + 1
	end
end

-- Moves every copy of a group to the spell's group with other uses (combining with it, if there
-- is one).
local function move_group(g, uses)
	local n = g.count
	SB.change_count(g, -n)
	SB.add(g.id, uses, n)
end

-- Within one spell: the group with the most uses left first (or the fewest, if chosen in the
-- mod settings). Unlimited uses (-1) count as the most.
function SB.uses_order(a, b)
	local ua = a.uses < 0 and math.huge or a.uses
	local ub = b.uses < 0 and math.huge or b.uses
	if SB.fewest_first() then return ua < ub end
	return ua > ub
end

-- All groups, in a fixed order (Lua's table order varies between runs).
local function sorted_groups(keep)
	local list = {}
	for _, g in pairs(SB.groups) do
		if keep(g) then list[#list + 1] = g end
	end
	table.sort(list, function(a, b) return a.kind < b.kind end)
	return list
end

-- Spell refresher: every group of a spell with limited uses goes back to full uses. Groups with
-- unlimited uses (-1, for example from the Unlimited spells perk) are left alone.
function SB.refresh_uses()
	for _, g in ipairs(sorted_groups(function(g)
		local info = SB.limited_info(g.id)
		return info ~= nil and g.uses >= 0 and g.uses ~= info.max_uses
	end)) do
		move_group(g, SB.limited_info(g.id).max_uses)
	end
end

-- The Unlimited spells perk: the groups with uses left of spells it makes unlimited (every spell
-- with limited uses, except the ones the game marks never_unlimited; spells not in the game's
-- list, from a disabled mod, are left alone).
function SB.limited_groups()
	return sorted_groups(function(g)
		local info = SB.limited_info(g.id)
		return info ~= nil and g.uses >= 0 and not info.never_unlimited
	end)
end

-- Makes those groups unlimited, each joining the spell's unlimited group. Returns how many
-- groups changed.
function SB.make_unlimited()
	local list = SB.limited_groups()
	for _, g in ipairs(list) do move_group(g, -1) end
	return #list
end

-- Saving ---------------------------------------------------------------------------------
-- In the run's global values: the groups, "ID#uses=count;...", and the selected page,
-- "type:number". The keys keep the mod's old name, Spell Bank, so existing runs still load
-- ("stacks" is an old name for groups).

local K_GROUPS, K_SELECTED = "spellbank2_stacks", "spellbank2_selected"

function SB.save()
	local parts = {}
	for _, g in pairs(SB.groups) do
		parts[#parts + 1] = string.format("%s#%d=%d", g.id, g.uses, g.count)
	end
	table.sort(parts)
	GlobalsSetValue(K_GROUPS, table.concat(parts, ";"))
	-- search and copies pages aren't kept: the last spell type page is saved instead
	GlobalsSetValue(K_SELECTED, (SB.is_special(SB.selected) and SB.home or SB.selected) or "")
end

function SB.load()
	SB.groups = {}
	SB.version = SB.version + 1
	for entry in string.gmatch(GlobalsGetValue(K_GROUPS, ""), "[^;]+") do
		local id, u, c = string.match(entry, "^(.-)#(%-?%d+)=(%d+)")
		if id and id ~= "" and tonumber(c) > 0 then SB.add(id, tonumber(u), tonumber(c)) end
	end
	SB.selected = GlobalsGetValue(K_SELECTED, "")
	if SB.selected == "" or SB.is_special(SB.selected) then SB.selected = SB.FIRST_PAGE end
	SB.home = SB.selected
end
