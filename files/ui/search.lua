-- Spellbook: the search box at the bottom of the panel, and switching the player's controls off
-- while it has the keyboard.
--
-- Clicking the box gives it the keyboard; clicking again (anywhere), Enter or Escape gives the
-- keyboard back, and so does closing the inventory. A right-click on it clears it. While it is
-- empty and doesn't have the keyboard, it says "Search...".
-- The game's text box only takes typing while the mouse is over it, and then even without a click
-- (seen in play: running left with the mouse over it typed "aaaa"; with the mouse off it,
-- nothing). So the game's box only shows the text (drawn non-interactive), and while it has the
-- keyboard the spellbook reads the keys itself, wherever the mouse is, and draws the cursor. A
-- transparent area over the box tells when the mouse is on it.

local W = SB.widgets

W.SEARCH_H = W.LINE_H + 3     -- the search box's line in the panel
local SEARCH_MAX = 24          -- the most characters it takes
local BACKSPACE_DELAY, BACKSPACE_EVERY = 18, 3   -- holding Backspace: frames before it repeats, and between repeats

-- Keys, by SDL scancode (as the game's Input functions use). They are read by key position, so
-- other keyboard layouts type what a QWERTY keyboard would. Typed: letters (capitals with Shift),
-- digits (also on the keypad), space and some punctuation.
local KEY_RETURN, KEY_ESCAPE, KEY_KP_ENTER, KEY_BACKSPACE = 40, 41, 88, 42
local KEY_LSHIFT, KEY_RSHIFT = 225, 229
local TYPED_KEYS = { [44] = " ", [45] = "-", [52] = "'", [54] = ",", [55] = "." }
for i = 0, 25 do TYPED_KEYS[4 + i] = string.char(97 + i) end
for i = 1, 9 do TYPED_KEYS[29 + i] = tostring(i); TYPED_KEYS[88 + i] = tostring(i) end
TYPED_KEYS[39], TYPED_KEYS[98] = "0", "0"

-- The player's controls -----------------------------------------------------------------------
-- While the search box has the keyboard, the player's controls are switched off, so typing
-- doesn't also work the game's keys (as Advanced Spell Inventory does). A global value notes it,
-- so a run saved meanwhile gets its controls back when it is loaded.

local CONTROLS_KEY = "spellbank2_controls_off"

function SB.set_controls(player, on)
	local cc = player and EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
	if cc then ComponentSetValue2(cc, "enabled", on) end
	-- Switched back on for a player entity without an inventory (polymorphed): the real player
	-- comes back from its stored copy, which still has them off, so they are still to be switched
	-- on then.
	local still_to_do = on and not SB.inventory2(player)
	local off = (not on) or still_to_do
	GlobalsSetValue(CONTROLS_KEY, off and "1" or "")
	SB.controls_off = off
	SB.log("controls " .. (on and "on" or "off") .. " (search box)" .. (still_to_do and ", again when the player is back" or ""))
end

function SB.restore_controls(player)
	if SB.controls_off or GlobalsGetValue(CONTROLS_KEY, "") == "1" then SB.set_controls(player, true) end
end

-- Typing ---------------------------------------------------------------------------------------

-- The text without its last character (a whole UTF-8 character).
local function drop_last_char(s)
	return (string.gsub(s or "", "[%z\1-\127\194-\244][\128-\191]*$", ""))
end

-- The text after this frame's keys: each key as it goes down (a key held down types once);
-- Backspace deletes one character per press, and held, one more every BACKSPACE_EVERY frames after
-- BACKSPACE_DELAY. Keys are only typed while the box has the keyboard (has_focus).
local function type_keys(text, has_focus)
	local was = SB.ui.keys_was or {}
	local now = {}
	for code in pairs(TYPED_KEYS) do now[code] = InputIsKeyDown(code) or nil end
	SB.ui.keys_was = now
	if not has_focus then return text end
	local shift = InputIsKeyDown(KEY_LSHIFT) or InputIsKeyDown(KEY_RSHIFT)
	for code, ch in pairs(TYPED_KEYS) do
		if now[code] and not was[code] and #text < SEARCH_MAX then
			text = text .. (shift and string.upper(ch) or ch)
		end
	end
	if InputIsKeyDown(KEY_BACKSPACE) then
		if not SB.ui.backspace_since then
			SB.ui.backspace_since, SB.ui.backspace_last = SB.frame, SB.frame
			text = drop_last_char(text)
		elseif SB.frame - SB.ui.backspace_since >= BACKSPACE_DELAY and SB.frame - SB.ui.backspace_last >= BACKSPACE_EVERY then
			text = drop_last_char(text)
			SB.ui.backspace_last = SB.frame
		end
	else
		SB.ui.backspace_since = nil
	end
	return text
end

-- The box ----------------------------------------------------------------------------------------

-- The box's top and height as the game reports them, if they look right; otherwise where it was
-- asked for and the usual height (seen in play: the box counted as under the mouse far below it;
-- a height of 0 would do that, as an image's height scale of 0 means "the same as its width
-- scale"). What is reported is logged when it changes, to check against play.
local function box_top_and_height(gui, y)
	local _, _, _, _, ry, _, rh = GuiGetPreviousWidgetInfo(gui)
	local by = (type(ry) == "number" and math.abs(ry - y) <= W.LINE_H) and ry or y
	local bh = (type(rh) == "number" and rh >= 6 and rh <= W.LINE_H * 2) and rh or W.LINE_H
	-- (its height, and its top against the one asked for, so not logged again as the panel moves)
	local reported = tostring(type(ry) == "number" and ry - y or ry) .. "," .. tostring(rh)
	if reported ~= SB.ui.search_reported then
		SB.ui.search_reported = reported
		SB.log("search box: the game reports its top and height as " .. reported .. " (asked for top " .. y .. "); using " .. by .. "," .. bh)
	end
	return by, bh
end

-- With the keyboard: a blinking cursor after the text, and the border lit up white: a 1-pixel
-- white frame over the game's own border (which can't be recoloured), at the box's edges. The
-- game draws the box as wide as asked, but reports it about 3.5 wider (seen in a screenshot), so
-- the width given is used; its top and height are as reported.
local function draw_focus(gui, x, by, w, bh)
	local z = W.z - 2
	if math.floor(SB.frame / 30) % 2 == 0 then
		W.rect(gui, W.ID.SEARCH_CURSOR, x + 2 + W.text_width(gui, SB.search_text), by + 2, 1, bh - 4, 1, z)
	end
	local lines = { { x, by, w, 1 }, { x, by + bh - 1, w, 1 }, { x, by, 1, bh }, { x + w - 1, by, 1, bh } }
	for i, l in ipairs(lines) do W.rect(gui, W.ID.SEARCH_FRAME + i, l[1], l[2], l[3], l[4], 1, z) end
end

function SB.draw_search_box(gui, player, x, y, w)
	local had_focus = SB.ui.search_focus == true

	GuiZSetForNextWidget(gui, W.z)
	GuiOptionsAddForNextWidget(gui, W.NON_INTERACTIVE)
	GuiTextInput(gui, W.ID.SEARCH, x, y, SB.search_text, w, SEARCH_MAX)
	local by, bh = box_top_and_height(gui, y)
	local hovered = W.hit_area(gui, W.ID.SEARCH_HIT, x, by, w, bh, W.z - 3, { "Search spells by name (case-insensitive)", "Right-click to clear" })
	if hovered then SB.hover_ui = true end

	local typed = type_keys(SB.search_text, had_focus)

	local focus = had_focus
	-- A left click elsewhere gives the keyboard back. While the box has it, any left click does:
	-- with the player's controls off, the game's GUI may not follow the mouse (seen in play: a
	-- click elsewhere wasn't seen as elsewhere), so where the click was can't be trusted.
	if SB.buttons.pressed then
		SB.log("search box: left click, over the box (as the GUI sees it): " .. tostring(hovered)
			.. ", mouse at " .. (SB.mouse and (math.floor(SB.mouse[1]) .. "," .. math.floor(SB.mouse[2])) or "?")
			.. ", had the keyboard: " .. tostring(had_focus))
		if had_focus then focus = false else focus = hovered == true end
	end
	if InputIsKeyDown(KEY_RETURN) or InputIsKeyDown(KEY_KP_ENTER) or InputIsKeyDown(KEY_ESCAPE) then focus = false end
	if focus ~= had_focus then
		SB.ui.search_focus = focus
		SB.ui.backspace_since = nil
		SB.set_controls(player, not focus)
	end
	-- A right-click on the box clears it (it keeps the keyboard, if it has it). While it has the
	-- keyboard, whether the mouse is on the box comes from the mouse's position in the world, for
	-- the same reason (that does follow the mouse with the controls off, seen in the debug log).
	local on_box = hovered
	if had_focus then
		local m = SB.mouse
		on_box = m ~= nil and m[1] >= x and m[1] < x + w and m[2] >= by and m[2] < by + bh
	end
	if SB.buttons.right_pressed and on_box and typed ~= "" then
		typed = ""
		SB.log("search box: cleared (right-click)")
	end
	if typed ~= SB.search_text then SB.set_search(player, typed) end
	if SB.search_text == "" and not focus then W.text(gui, x + 2, y + 1, "Search...", W.DIM, W.z - 1) end
	if focus then draw_focus(gui, x, by, w, bh) end
end
