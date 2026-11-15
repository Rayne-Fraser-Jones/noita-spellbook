-- Helpers shared by the tests. Load after tests/stubs.lua and init.lua.
HB = HB_SPRITE   -- the transparent image over each card (tests hover it)
INV2 = EntityGetFirstComponentIncludingDisabled(PLAYER, "Inventory2Component")

function step(n) for _ = 1, (n or 1) do frame_num = frame_num + 1; OnWorldPostUpdate(); end_of_frame() end end
function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end print("ok  " .. msg) end
function find(kind, key) for _, w in ipairs(gui_log) do if w[1] == kind and (key == nil or w[2] == key) then return w end end end
function find_tip(title, pattern) for _, w in ipairs(gui_log) do if w[1] == "tooltip" and w[2] == title and w[3]:find(pattern) then return w end end end
-- a group count drawn over the spell row (in the game's small numbers font), matching pattern
function find_count(pattern) for _, w in ipairs(gui_log) do if w[1] == "text" and w.font == "data/fonts/font_small_numbers.xml" and w[2]:find(pattern) then return w end end end
function find_text(pattern) for _, w in ipairs(gui_log) do if (w[1] == "text" or w[1] == "button" or w[1] == "tooltip") and type(w[2]) == "string" and w[2]:find(pattern) then return w end end end

function card_info(e)
  local ia = EntityGetFirstComponentIncludingDisabled(e, "ItemActionComponent")
  local ic = EntityGetFirstComponentIncludingDisabled(e, "ItemComponent")
  return comps[ia].f.action_id, ComponentGetValue2(ic, "uses_remaining"), ComponentGetValue2(ic, "inventory_slot")
end
local function cards_of(parent)
  local t = {}
  for _, c in ipairs(EntityGetAllChildren(parent) or {}) do
    local id, u, x = card_info(c); t[x + 1] = { e = c, id = id, uses = u }
  end
  return t
end
function row() return cards_of(INV_FULL) end           -- row slot (1-based) -> { e, id, uses }
function wand_cards(w) return cards_of(w or WAND) end   -- wand slot (1-based) -> { e, id, uses }
-- (the player, or the game, moving a card: the game's record of where it is moves too)
function set_slot(e, s) comps[EntityGetFirstComponentIncludingDisabled(e, "ItemComponent")].f.inventory_slot = { s - 1, 0 }; game_slots[e] = { s - 1, 0 } end
function set_uses(e, u) comps[EntityGetFirstComponentIncludingDisabled(e, "ItemComponent")].f.uses_remaining = u end
function in_wand(id, uses, x)
  local c = make_card(id, uses); set_parent(c, WAND)
  comps[EntityGetFirstComponentIncludingDisabled(c, "ItemComponent")].f.inventory_slot = { x, 0 }
  return c
end
function clear_wand() for _, c in ipairs(EntityGetAllChildren(WAND) or {}) do EntityKill(c) end end

function hover_slot(slot) hover_label, hover_xy = HB, { 191 + (slot - 1) * 20, 21 } end
function hover_name(label) hover_label, hover_xy = label, nil end
-- the mouse over the page list, but not over any name in it
function hover_list_gap() hover_label, hover_xy = HB, { SB.ui.list_box[1], SB.ui.list_box[2] } end
function hover_none() hover_label, hover_xy = nil, nil end
function press_on(slot) hover_slot(slot); step(); mouse_down = true; step() end

-- Copies of a spell wherever they are: in groups (which include the cards the spellbook shows in
-- the row), in the wand, on the ground, and cards in the row the spellbook hasn't taken in yet.
function where(id)
  local t = { book = 0, wand = 0, ground = 0, loose = 0 }
  for _, st in pairs(SB.groups) do if st.id == id then t.book = t.book + st.count end end
  for _, c in pairs(wand_cards()) do if c.id == id then t.wand = t.wand + 1 end end
  for e, en in pairs(ents) do
    if not en.dead and en.name == "card" and not en.parent and card_info(e) == id then t.ground = t.ground + 1 end
  end
  for _, c in pairs(row()) do if c.id == id and not SB.reps[c.e] then t.loose = t.loose + 1 end end
  t.total = t.book + t.wand + t.ground + t.loose
  return t
end
function groups_of(id)
  local list = {}
  for _, st in pairs(SB.groups) do if st.id == id then list[#list + 1] = st end end
  table.sort(list, function(a, b) return a.uses > b.uses end)
  return list
end
function group(id, uses) return SB.groups[id .. "#" .. uses] end
-- The spells on a page, slot by slot: "LIGHT_BULLET#-1 SPLITTER#-1", "-NUKE" for a faded one.
function page_str(key)
  local o = {}
  for i, e in ipairs(SB.page(key).entries) do o[i] = e.group and e.group.kind or ("-" .. e.id) end
  return table.concat(o, " ")
end
-- What the row shows, slot by slot ("." for an empty slot).
function row_str()
  local r, o = row(), {}
  local last = 0
  for s = 1, 16 do if r[s] then last = s end end
  for s = 1, last do o[s] = r[s] and (r[s].id .. "#" .. r[s].uses) or "." end
  return table.concat(o, " ")
end
