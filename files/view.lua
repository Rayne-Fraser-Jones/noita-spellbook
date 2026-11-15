-- Spellbook: which page is selected, and which page the spell row shows: storing a spell selects
-- its page; clicking a page in the page list selects it; resting the mouse on one shows it for a
-- while; the search box and right-clicking a card open search and copies pages.

SB.selected    = SB.selected or SB.FIRST_PAGE  -- the selected page's key
SB.home        = SB.home or SB.FIRST_PAGE      -- the last spell type page selected, to go back to
SB.search_text = SB.search_text or ""          -- the search box's text (a search page while not empty)
-- SB.copies_of: the spell whose copies pages are open, or nil. SB.shown: the page the row shows
-- (nil: none yet). SB.preview: the page shown because the mouse rests on its name, or nil.

-- Stores one copy of a spell, and selects the page it is on, so it stays in view.
function SB.store(id, uses, how)
	local g = SB.add(id, uses, 1)
	local L = SB.layout()
	local key = L.page_of[g.kind]
	if key then
		SB.home = key
		-- On a search or copies line that shows this spell, its page there is selected (on the
		-- copies line, the first one with a copy with these uses), so the copy stored is in view.
		-- Otherwise the spell's own page, and the copies pages close, as when another page is
		-- clicked.
		local t = SB.is_special(SB.selected) and SB.key_type(SB.selected)
		local there
		for _, page in ipairs(t and L.by_type[t] or {}) do
			for _, e in ipairs(page.entries) do
				if not there and e.group and e.id == g.id and (t ~= SB.COPIES or e.group.kind == g.kind) then there = page.key end
			end
		end
		if there then
			SB.selected = there
		else
			SB.selected = key
			SB.copies_of = nil
		end
	end
	SB.log(SB.info(id).name .. " (" .. uses .. " uses): " .. how .. "; stored, now " .. g.count .. ", on " .. SB.page(SB.selected).name)
	return g
end

-- What the row shows ---------------------------------------------------------------------
-- The selected page, unless the mouse rests on one of a page's buttons in the page list (its name,
-- number or card) for PREVIEW_FRAMES frames: then that page. Once a page is shown that way,
-- moving onto another page's button shows that one at once, so a sweep along a line's numbers
-- shows each page in turn; off the buttons, the selected page is shown again at once. The drawing
-- sets SB.hover_target (a page key).

local PREVIEW_FRAMES = 8

function SB.previewing() return SB.shown ~= nil and SB.shown ~= SB.resolve(SB.selected) end

function SB.update_display(player)
	if not SB.row_quiet() then return end
	local h = SB.hover_target
	if h ~= SB.hover_cand then SB.hover_cand, SB.hover_since = h, SB.frame end
	if h == nil then
		SB.preview = nil
	elseif SB.preview ~= nil or SB.frame - (SB.hover_since or 0) >= PREVIEW_FRAMES then
		SB.preview = h
	end
	if SB.preview and not SB.layout().by_key[SB.preview] then SB.preview, SB.hover_cand = nil, nil end
	SB.selected = SB.resolve(SB.selected)
	local want = SB.resolve(SB.preview or SB.selected)
	if want == SB.shown and SB.page_sig(SB.page(want)) == SB.row_sig then return end
	SB.log("showing " .. SB.page(want).name .. (want ~= SB.selected and " (mouse over its name)" or ""))
	SB.relayout(player, function() SB.shown = want end)
end

-- Selects a page: it stays shown. Selecting any page but a copies page closes the copies pages
-- (clicking one, or typing a search, which selects the search page).
function SB.switch_page(player, key)
	if not SB.layout().by_key[key] then return end
	SB.selected = key
	if SB.copies_of and SB.key_type(key) ~= SB.COPIES then SB.copies_of = nil end
	if not SB.is_special(key) then SB.home = key end
	SB.preview, SB.hover_cand, SB.hover_since = nil, key, SB.frame
	SB.save()
	SB.update_display(player)
end

-- The two boxes at the top of the panel, the same as the mod settings of those names.
local function set_box(player, id, on)
	SB.set_setting(id, on)
	SB.log(id .. " " .. (on and "on" or "off"))
	SB.update_display(player)
end
function SB.set_merge_categories(player, on) set_box(player, "merge_categories", on) end
function SB.set_hide_unowned(player, on) set_box(player, "hide_unowned", on) end

-- Copies pages: every copy of one spell, one slot each, ordered by uses left. Opened by
-- right-clicking one of its cards (any spell, for consistency, though for a spell with unlimited
-- uses every copy is the same); they close when another page is selected.
function SB.show_copies(player, id)
	SB.copies_of = id
	SB.copies_hint_done()
	SB.log("copies of " .. SB.info(id).name .. " (right-click)")
	SB.switch_page(player, SB.page_key(SB.COPIES, 1))
end

-- The hint at the bottom of the screen about right-clicking, shown while the mod setting "Show
-- right-click hint" is on (as it is to begin with). The first right-click on a card turns the
-- setting off; it can be turned on or off in the mod settings at any time.
function SB.copies_hint_wanted() return SB.setting("show_copies_hint") ~= false end
function SB.copies_hint_done()
	if SB.copies_hint_wanted() then SB.set_setting("show_copies_hint", false) end
end

-- Search: the search page shows the spells whose name holds the text. It is selected as you
-- type; when the text is cleared, the last spell type page is selected again.
function SB.set_search(player, text)
	text = text or ""
	if text == SB.search_text then return end
	SB.search_text = text
	if text ~= "" then
		SB.switch_page(player, SB.page_key(SB.SEARCH, 1))
	elseif SB.key_type(SB.selected) == SB.SEARCH then
		SB.switch_page(player, SB.resolve(SB.home))
	end
end
