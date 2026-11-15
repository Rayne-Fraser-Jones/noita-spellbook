-- Spellbook: the pages, worked out from the groups.
--
-- Pages are never stored: SB.layout() is the one place they are worked out. Each spell type has
-- its own pages (with "Merge categories" ticked, every spell is on the pages of one line,
-- "All", in the same order), with one slot per spell (all its groups together), in the game's
-- spell order, one spell row (SB.capacity slots) to a page. The card shown is the spell's first
-- group by uses left. A spell you have none of takes a slot too, drawn faded (not with "Hide
-- unowned" ticked). A line with nothing to show has no pages. No entity code.
--
-- Two more kinds of page are listed below the spell types (copies, then search results, just
-- above the search box). They aren't saved, and close when another page is selected:
--   * search results (SB.SEARCH): the spells whose name holds SB.search_text, grouped and ordered
--     as usual, the ones you have none of too (unless "Hide unowned");
--   * copies (SB.COPIES): every copy of the spell SB.copies_of, one slot each (entries marked
--     `single`, so no count is drawn), ordered by uses left as in the settings.

SB.SEARCH, SB.COPIES, SB.ALL = 8, 9, 10   -- page types after the spell types (0 to 7)
SB.LIST_ORDER = { 10, 0, 1, 2, 3, 4, 5, 6, 7, 9, 8 }   -- the order of the lines in the page list
-- Each kind of page's name: its line in the page list, and its pages ("Projectiles 2"). The game's
-- own names for the spell types (inventory_actiontype_* in its translations), written out in
-- full: it shortens some ("Static proj.", "Proj. modifier").
SB.TYPE_NAMES = {
	[0] = "Projectiles", "Static projectiles", "Projectile modifiers", "Multicasts", "Materials",
	"Other", "Utility", "Passives",
	[SB.SEARCH] = "Search", [SB.COPIES] = "Copies", [SB.ALL] = "All",
}
SB.FIRST_PAGE = "0:1"
SB.capacity = SB.capacity or 16   -- slots on a page: the spell row's (read by SB.row_snapshot)

-- Page keys are "type:number".
function SB.page_key(t, n) return t .. ":" .. n end
function SB.key_type(key) return tonumber(string.match(key or "", "^(%d+):")) end
local function is_special_type(t) return t == SB.SEARCH or t == SB.COPIES end
-- Search and copies pages
function SB.is_special(key) return is_special_type(SB.key_type(key)) end

-- SB.layout() returns { pages = { page, ... }, by_key = {}, by_type = { [type] = { page, ... } },
-- page_of = { [kind] = page key } }. A page is { key, type, number, name, entries }, and each
-- entry is { id, group, groups }: groups are all the spell's groups by uses left, group the first
-- (the card shown); both nil for a spell you don't have. On a copies page an entry is one copy
-- ({ id, group, single = true }). Search and copies pages are in by_key and by_type only, not in
-- pages or page_of. With no pages at all, the one page is an empty one, "none".

local EMPTY = { key = "none", number = 1, name = "No spells", entries = {} }

-- Which spells are unlocked, as a string, while it matters to the pages (unowned spells
-- shown, Show locked off): a spell unlocked during the run gets its placeholder. Worked out once a frame.
local function unlock_key()
	if not SB.show_unowned() or SB.show_locked() then return "" end
	if SB.unlock_frame ~= SB.frame then
		local bits = {}
		for i, fl in ipairs(SB.lock_flags or {}) do bits[i] = HasFlagPersistent(fl) and "1" or "0" end
		SB.unlock_frame, SB.unlock_bits = SB.frame, table.concat(bits)
	end
	return SB.unlock_bits
end

-- Everything the layout depends on, as one string: the layout is kept until it changes.
local function layout_key()
	local parts = {
		SB.version, tostring(SB.show_unowned()), tostring(SB.show_locked()), unlock_key(),
		tostring(SB.categorize()), SB.capacity, tostring(SB.fewest_first()), #SB.action_list,
		SB.search_text, tostring(SB.copies_of),
	}
	if SB.copies_of then
		-- copies pages have a slot per copy, so they change with the counts, not only the groups
		local counts = {}
		for _, g in pairs(SB.groups) do
			if g.id == SB.copies_of then counts[#counts + 1] = g.kind .. "=" .. g.count end
		end
		table.sort(counts)
		parts[#parts + 1] = table.concat(counts, ",")
	end
	return table.concat(parts, "|")
end

-- Cuts a list of entries into pages of one spell row each, named "<name> 1", "<name> 2", ...
-- A search with no results still has its page, empty, and so does a copies page whose last copy
-- has gone: it stays until another page is selected.
local function add_pages(L, t, name, entries)
	local special = is_special_type(t)
	L.by_type[t] = {}
	for i = 1, math.max(#entries, special and 1 or 0), SB.capacity do
		local n = #L.by_type[t] + 1
		local page = { key = SB.page_key(t, n), type = t, number = n, entries = {}, name = name .. " " .. n }
		for k = i, math.min(i + SB.capacity - 1, #entries) do
			local e = entries[k]
			page.entries[#page.entries + 1] = e
			if not special then
				for _, g in ipairs(e.groups or {}) do L.page_of[g.kind] = page.key end
			end
		end
		if not special then L.pages[#L.pages + 1] = page end
		L.by_type[t][n] = page
		L.by_key[page.key] = page
	end
end

function SB.layout()
	local key = layout_key()
	if SB.cached_layout and SB.cached_key == key then return SB.cached_layout end
	local unowned, locked_too = SB.show_unowned(), SB.show_locked()
	-- each spell's groups, by uses left
	local by_id = {}
	for _, g in pairs(SB.groups) do
		by_id[g.id] = by_id[g.id] or {}
		table.insert(by_id[g.id], g)
	end
	for _, list in pairs(by_id) do table.sort(list, SB.uses_order) end
	-- spells not in the game's list (the mod that added them is probably disabled) go at the
	-- end of their type, by id
	local extra = {}
	for id in pairs(by_id) do
		if not (SB.actions and SB.actions[id]) then extra[#extra + 1] = id end
	end
	table.sort(extra)

	-- Adds a type's entries to a list, in page order: its spells in the game's order (then the
	-- extra ones). keep(id) can leave spells out.
	local function add_type(list, t, keep)
		local function add_spell(id)
			if keep and not keep(id) then return end
			local groups = by_id[id]
			if groups then
				-- one slot per spell: the card shown is its first group by uses left; the count
				-- drawn is every copy, of all its groups
				list[#list + 1] = { id = id, group = groups[1], groups = groups }
			elseif unowned and (locked_too or not SB.is_locked(SB.info(id))) then
				-- (a spell not unlocked yet only with the setting for it; one you own is always shown)
				list[#list + 1] = { id = id }
			end
		end
		for _, id in ipairs(SB.action_list) do
			if SB.actions[id].type == t then add_spell(id) end
		end
		for _, id in ipairs(extra) do
			if SB.info(id).type == t then add_spell(id) end
		end
		return list
	end
	local function every_type(keep)
		local list = {}
		for t = 0, SB.SPELL_TYPES - 1 do add_type(list, t, keep) end
		return list
	end

	local L = { pages = {}, by_key = {}, by_type = {}, page_of = {} }
	if SB.categorize() then
		for t = 0, SB.SPELL_TYPES - 1 do add_pages(L, t, SB.TYPE_NAMES[t], add_type({}, t)) end
	else
		add_pages(L, SB.ALL, SB.TYPE_NAMES[SB.ALL], every_type())
	end
	if SB.search_text ~= "" then
		local needle = string.lower(SB.search_text)
		add_pages(L, SB.SEARCH, "Search '" .. SB.search_text .. "'", every_type(function(id)
			return string.find(string.lower(SB.info(id).name), needle, 1, true) ~= nil
		end))
	end
	if SB.copies_of then
		local copies = {}
		for _, g in ipairs(by_id[SB.copies_of] or {}) do
			for _ = 1, g.count do copies[#copies + 1] = { id = g.id, group = g, single = true } end
		end
		add_pages(L, SB.COPIES, "Copies of " .. SB.info(SB.copies_of).name, copies)
	end

	if #L.pages == 0 then L.by_key[EMPTY.key] = EMPTY end
	SB.cached_layout, SB.cached_key = L, key
	return L
end

-- The page a key stands for, or the nearest one that exists: the last page of the same type;
-- for a search or copies page that has gone, the last spell type page selected; then the first
-- page there is.
function SB.resolve(key)
	local L = SB.layout()
	if key and L.by_key[key] then return key end
	local t = SB.key_type(key)
	local list = t and L.by_type[t]
	if list and #list > 0 then return list[#list].key end
	if is_special_type(t) and SB.home and not SB.is_special(SB.home) then return SB.resolve(SB.home) end
	if L.pages[1] then return L.pages[1].key end
	return EMPTY.key
end

function SB.page(key) return SB.layout().by_key[SB.resolve(key)] end

-- What a page holds, slot by slot, as one string: if it changes, the row is refilled.
function SB.page_sig(page)
	local parts = {}
	for i, e in ipairs(page.entries) do parts[i] = e.group and e.group.kind or ("-" .. e.id) end
	return page.key .. "=" .. table.concat(parts, ",")
end
