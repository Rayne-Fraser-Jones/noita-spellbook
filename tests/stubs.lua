-- Stand-ins for the parts of the Noita API that Spellbook uses, so its logic can be run
-- outside the game with LuaJIT (the Lua Noita uses). Run the tests from the mod folder:
--   sh tests/run.sh
--
-- Entities, components, globals and mod settings are plain tables. GUI calls record what
-- would be drawn into `gui_log`, and tests "click" or "hover" widgets by label or sprite
-- (`click`, `hover_label`, `hover_xy`). Mouse buttons: `mouse_down`, `right_down`.
-- What the game itself does (moving a card into a wand, dropping it on the ground, stale
-- positions for a frame) is acted out by each test with `set_parent` and slot changes;
-- see the comments in the tests. These stand-ins are a model of the game, not the game:
-- behaviour confirmed in play is listed in docs/DETAILS.md.
MOD_ROOT = "./"  -- tests are run from the mod folder
globals, settings, printed = {}, {}, {}
-- most tests are about the spells you own: "Hide unowned" ticked (tests/merge_categories.lua
-- tests the defaults: categories, and unowned spells shown)
settings["spellbook.hide_unowned"] = true
function GlobalsSetValue(k, v) globals[k] = v end
function GlobalsGetValue(k, d) local v = globals[k]; if v == nil then return d end; return v end
function ModSettingGet(k) return settings[k] end
function ModLuaFileAppend() end
-- (the two perk names the wand-editing messages use, as the game has them in English)
local PERK_NAMES = { ["$perk_edit_wands_everywhere"] = "Tinker With Wands Everywhere", ["$perk_no_wand_editing"] = "No Wand Tinkering" }
function GameTextGetTranslatedOrNot(s) if PERK_NAMES[s] then return PERK_NAMES[s] end return (s:gsub("^%$action_", ""):gsub("^%$actiondesc_", "desc of ")) end
persistent_flags = {}
function HasFlagPersistent(f) return persistent_flags[f] == true end
function GamePrint(s) printed[#printed+1] = s end
frame_num = 0
function GameGetFrameNum() return frame_num end
inventory_open = false
function GameIsInventoryOpen() return inventory_open end
keys_down = {}
function InputIsKeyDown(k) return keys_down[k] == true end

local loaded = {}
function dofile_once(p)
  if loaded[p] then return end; loaded[p] = true
  if p:match("^mods/spellbook/") then dofile(MOD_ROOT .. p:gsub("^mods/spellbook/", ""))
  elseif p:match("gun_enums") then
    ACTION_TYPE_PROJECTILE, ACTION_TYPE_MODIFIER, ACTION_TYPE_UTILITY = 0, 2, 6
  elseif p:match("gun_actions") then
    actions = {
      { id="LIGHT_BULLET", name="$action_light_bullet", description="$actiondesc_light_bullet", sprite="lb.png", type=0 },
      { id="BOMB", name="$action_bomb", description="$actiondesc_bomb", sprite="bomb.png", type=0, max_uses=3 },
      { id="DAMAGE", name="$action_damage", description="$actiondesc_damage", sprite="dmg.png", type=2 },
      { id="NUKE", name="$action_nuke", description="$actiondesc_nuke", sprite="nuke.png", type=0, max_uses=1, spawn_requires_flag="card_unlocked_nuke" },
      { id="SPLITTER", name="$action_splitter", description="", sprite="split.png", type=0 },
      { id="ACID_TRAIL", name="$action_acid_trail", description="", sprite="acid.png", type=0 },
      { id="TELEPORT_PROJECTILE", name="$action_teleport", description="", sprite="tp.png", type=6 },
    }
    -- a test can add spells of its own (set EXTRA_ACTIONS before loading init.lua)
    for _, a in ipairs(EXTRA_ACTIONS or {}) do actions[#actions + 1] = a end
  end
end

-- Entities
ents, comps, next_ent, next_comp = {}, {}, 1, 1
function new_entity(name, parent)
  local e = next_ent; next_ent = next_ent + 1
  ents[e] = { name = name or "", parent = parent, children = {}, comps = {}, x = 0, y = 0 }
  if parent then table.insert(ents[parent].children, e) end
  return e
end
function add_comp(e, type_, fields)
  local c = next_comp; next_comp = next_comp + 1
  comps[c] = { type = type_, f = fields or {} }
  table.insert(ents[e].comps, c); return c
end
function EntityGetIsAlive(e) return ents[e] ~= nil and not ents[e].dead end
function EntityGetParent(e) return ents[e].parent or 0 end
function EntityAddComponent2(e, t, f) return add_comp(e, t, f) end
function EntityRemoveComponent(e, c) for i, x in ipairs(ents[e].comps) do if x == c then table.remove(ents[e].comps, i) break end end end
function EntityGetComponentIncludingDisabled(e, t) local o = {} for _, c in ipairs(ents[e].comps) do if comps[c].type == t then o[#o+1] = c end end if #o == 0 then return nil end return o end
mouse_down = false
right_down = false
function InputIsMouseButtonDown(b) if b == 1 then return mouse_down end if b == 2 then return right_down end return false end
function set_parent(e, p)
  EntityRemoveFromParent(e)
  if p and p ~= 0 then ents[e].parent = p; table.insert(ents[p].children, e) end
end
function EntityGetAllChildren(e) if not ents[e] or #ents[e].children == 0 then return nil end; local o = {}; for i,c in ipairs(ents[e].children) do o[i]=c end; return o end
function EntityGetName(e) return ents[e].name end
function EntityGetTransform(e) return ents[e].x, ents[e].y end
function EntityGetFirstComponentIncludingDisabled(e, t) for _, c in ipairs(ents[e].comps) do if comps[c].type == t then return c end end end
function ComponentGetValue2(c, k) local v = comps[c].f[k]; if type(v) == "table" then return v[1], v[2] end; return v end
function ComponentSetValue2(c, k, a, b) if b ~= nil then comps[c].f[k] = { a, b } else comps[c].f[k] = a end end
function EntityRemoveFromParent(e) local p = ents[e].parent; if p then for i,c in ipairs(ents[p].children) do if c == e then table.remove(ents[p].children, i) break end end end; ents[e].parent = nil end
-- as in the game, a killed entity is only removed at the end of the frame: until then
-- EntityGetWithTag still lists it (seen in play: the cards killed while loading were found again)
killed_this_frame = {}
function EntityKill(e) ents[e].dead = true; ents[e].listed = true; killed_this_frame[#killed_this_frame + 1] = e; EntityRemoveFromParent(e) end
-- The game keeps its own record of where each card in the spell row is: a script setting the
-- slot of a card already there is undone (seen in play: a card moved within the row and put back
-- by setting its slot went back to where it was dropped, every two frames). A new card takes the
-- slot it has when it first shows up there; the player moving one (set_slot in the tests) moves
-- the record too.
game_slots = {}
function end_of_frame()
  for _, e in ipairs(killed_this_frame) do ents[e].listed = nil end; killed_this_frame = {}
  for _, e in ipairs(ents[INV_FULL] and ents[INV_FULL].children or {}) do
    local ic = EntityGetFirstComponentIncludingDisabled(e, "ItemComponent")
    local s = ic and comps[ic].f.inventory_slot
    if s then
      local r = game_slots[e]
      if not r then game_slots[e] = { s[1], s[2] }
      elseif r[1] ~= s[1] or r[2] ~= s[2] then comps[ic].f.inventory_slot = { r[1], r[2] } end
    end
  end
end
function make_card(id, uses)
  local e = new_entity("card")
  add_comp(e, "ItemActionComponent", { action_id = id })
  add_comp(e, "ItemComponent", { uses_remaining = uses or -1, inventory_slot = {0,0} })
  add_comp(e, "VelocityComponent", { mVelocity = {0,0} })
  return e
end
function CreateItemActionEntity(id, x, y) local c = make_card(id, -1); ents[c].x, ents[c].y = x or 0, y or 0; return c end
function GamePickUpInventoryItem(who, item, fx)
  ents[item].parent = INV_FULL; table.insert(ents[INV_FULL].children, item)
end
-- pick up from the world into the first free slot of the spell row
function world_pickup(id, uses)
  local taken = {}
  for _, e in ipairs(ents[INV_FULL].children) do
    taken[comps[EntityGetFirstComponentIncludingDisabled(e, "ItemComponent")].f.inventory_slot[1]] = true
  end
  local x = 0 while taken[x] do x = x + 1 end
  local c = make_card(id, uses)
  GamePickUpInventoryItem(PLAYER, c)
  comps[EntityGetFirstComponentIncludingDisabled(c, "ItemComponent")].f.inventory_slot = { x, 0 }
  return c
end

PLAYER = new_entity("player")
add_comp(PLAYER, "Inventory2Component", { full_inventory_slots_x = 16, full_inventory_slots_y = 1 })
CONTROLS = add_comp(PLAYER, "ControlsComponent", { enabled = true })
INV_QUICK = new_entity("inventory_quick", PLAYER)
WAND = new_entity("wand", INV_QUICK)
INV_FULL = new_entity("inventory_full", PLAYER)
-- the world state entity; perk_infinite_spells is set when the Unlimited spells perk is taken
WORLD = new_entity("world_state")
WORLD_STATE = add_comp(WORLD, "WorldStateComponent", { perk_infinite_spells = false })
function GameGetWorldStateEntity() return WORLD end

-- GUI: records widgets; scripted clicks target widgets by sprite or label.
gui_log = {}
click = nil -- { match = "bomb.png" or label, right = bool }
function GuiCreate() return 1 end
function GuiStartFrame() gui_log = {} end
function GuiGetScreenDimensions() return 640, 360 end
function GuiGetTextDimensions(g, s) return #s * 5, 9 end
-- a colour set for the next widget is recorded on it as .color = { r, g, b }
local next_color = nil
local next_options = {}
local function take_color() local c = next_color; next_color = nil; return c end
-- and a z set for the next widget as .z
local next_z = nil
local function take_z() local z = next_z; next_z = nil; return z end
function GuiText(g, x, y, s, scale, font) next_options = {}; table.insert(gui_log, { "text", s, x, y, color = take_color(), font = font, z = take_z() }) end
local function clicked(key)
  if click and click.match == key then local c = click; click = nil; return not c.right, c.right == true end
  return false, false
end
function GuiButton(g, id, x, y, label) last_widget = { "button", label, x, y, id, color = take_color(), z = take_z(), options = next_options }; next_options = {}; table.insert(gui_log, last_widget); return clicked(label) end
-- (scale_y 0 means the same as scale, as in the game)
function GuiImage(g, id, x, y, s, a, sx, sy) next_options = {}; local c = take_color(); last_widget = { "image", s, x, y, a, id, color = c, z = take_z(), sx = sx or 1, sy = (sy == nil or sy == 0) and (sx or 1) or sy }; table.insert(gui_log, last_widget) end
function GuiImageButton(g, id, x, y, t, s) next_options = {}; last_widget = { "imagebutton", s, x, y, id, z = take_z() }; table.insert(gui_log, last_widget); return clicked(s) end
function GuiTooltip(g, t, d) table.insert(gui_log, { "tooltip", t, d }) end
function GuiTextInput(g, id, x, y, text, w) last_widget = { "input", id, text, x = x, y = y, w = w, options = next_options, z = take_z() }; next_options = {}; table.insert(gui_log, last_widget); return text end
hover_input = false   -- the mouse over the text input
mouse_point = nil
HB_SPRITE = "mods/spellbook/files/slot_hitbox.png"
input_reported_h = 11   -- the height the game reports for a text input
hover_label = nil
last_widget = nil
function GuiGetPreviousWidgetInfo()
  -- (the game reports a text input about 3.5 wider than it draws it)
  if last_widget and last_widget[1] == "input" then return false, false, hover_input, last_widget.x, last_widget.y, last_widget.w + 3.5, input_reported_h end
  -- mouse_point = { x, y }: the mouse at a point. As in the game, an image counts as under the
  -- mouse within a square as wide as it is drawn: its height scale is ignored (seen in play: a
  -- transparent image drawn 98 x 11 counted as under the mouse 98 down)
  if mouse_point and last_widget and (last_widget[1] == "image" or last_widget[1] == "imagebutton") then
    local size = 18 * (last_widget.sx or 1)
    local px, py = mouse_point[1], mouse_point[2]
    return false, false, (last_widget[2] == HB_SPRITE and px >= last_widget[3] and px < last_widget[3] + size
      and py >= last_widget[4] and py < last_widget[4] + size)
  end
  if hover_xy and last_widget and (last_widget[1] == "image" or last_widget[1] == "imagebutton") then
    return false, false, (last_widget[2] == hover_label and last_widget[3] == hover_xy[1] and last_widget[4] == hover_xy[2])
  end
  return false, false, (hover_label ~= nil and last_widget ~= nil and last_widget[2] == hover_label)
end
function GuiGetImageDimensions(g, s, scale) return 20 * (scale or 1), 20 * (scale or 1) end
function GuiZSetForNextWidget(g, z) next_z = z end
-- options set for the next widget (GUI_OPTION.NonInteractive is 2 here) are recorded on a text
-- input as .options
function GuiOptionsAddForNextWidget(g, o) next_options[#next_options + 1] = o end
function GuiColorSetForNextWidget(g, r, gr, b) next_color = { r, gr, b } end
function GuiImageNinePiece(g, id, x, y, w, h) table.insert(gui_log, { "panel", x, y, w, h, z = take_z() }) end
function ModSettingSet(k, v) settings[k] = v end
-- the mod settings menu's values (applied when it closes)
next_settings = {}
function ModSettingSetNextValue(k, v) next_settings[k] = v end
function ModSettingGetNextValue(k) local v = next_settings[k]; if v == nil then return settings[k] end; return v end
tags = {}
function EntityHasTag(e, t) return tags[e] and tags[e][t] or false end
function add_tag(e, t) tags[e] = tags[e] or {}; tags[e][t] = true end
effects = {}
function GameGetGameEffectCount(e, name) return effects[name] or 0 end
function ComponentObjectGetValue2(c, obj, field) return comps[c].f[obj .. "." .. field] end
function EntityGetWithTag(t)
  local o = {}
  if t == "player_unit" then return { PLAYER } end
  if t == "card_action" then
    for e, en in pairs(ents) do if en.name == "card" and (not en.dead or en.listed) then o[#o+1] = e end end
    return o
  end
  for e, ts in pairs(tags) do if ts[t] and not ents[e].dead then o[#o+1] = e end end
  return o
end


-- The mouse, in world coordinates (camera at 0,0); mouse_at_ui(x, y) places it at UI pixels.
mouse_world = { -10000, -10000 }
function DEBUG_GetMouseWorld() return mouse_world[1], mouse_world[2] end
function GameGetCameraPos() return 0, 0 end
local magic = { VIRTUAL_RESOLUTION_X = 427, VIRTUAL_RESOLUTION_Y = 242 }
function MagicNumbersGetValue(k) return magic[k] end
function mouse_at_ui(x, y) mouse_world = { (x - 320) * 427 / 640, (y - 180) * 242 / 360 } end
