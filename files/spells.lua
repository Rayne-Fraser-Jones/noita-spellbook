-- Spellbook: the game's spell list, read once from its gun_actions.lua.

SB.SPELL_TYPES = 8   -- the game's spell types, 0 to 7: projectile, static projectile, modifier,
                     -- multicast, material, other, utility, passive
SB.TYPE_OTHER = 5    -- the type taken for a spell whose type isn't one of those

local FALLBACK_SPRITE = "data/ui_gfx/gun_actions/light_bullet.png"

-- SB.actions: spell id -> { id, name, sprite, type, max_uses, never_unlimited, flag }; nil until
-- SB.load_actions. SB.action_list: the ids in the game's order. SB.lock_flags: each flag that
-- unlocks spells, once.
SB.action_list = SB.action_list or {}

function SB.load_actions()
	if SB.actions then return end
	SB.actions, SB.action_list, SB.lock_flags = {}, {}, {}
	local seen_flags = {}
	local ok, err = pcall(function()
		dofile_once("data/scripts/gun/gun_enums.lua")
		dofile_once("data/scripts/gun/gun_actions.lua")
	end)
	if not ok then print("[spellbook] could not read the spell list: " .. tostring(err)) end
	for _, a in ipairs(actions or {}) do
		if a.id and SB.actions[a.id] == nil then
			local t = a.type
			if type(t) ~= "number" or t < 0 or t >= SB.SPELL_TYPES or t ~= math.floor(t) then t = SB.TYPE_OTHER end
			SB.actions[a.id] = {
				id = a.id,
				name = GameTextGetTranslatedOrNot(a.name or a.id),
				sprite = a.sprite or FALLBACK_SPRITE,
				type = t,
				max_uses = a.max_uses,
				never_unlimited = a.never_unlimited == true,   -- stays limited with the Unlimited spells perk
				flag = a.spawn_requires_flag,
			}
			SB.action_list[#SB.action_list + 1] = a.id
			local fl = a.spawn_requires_flag
			if fl and fl ~= "" and not seen_flags[fl] then
				seen_flags[fl] = true
				SB.lock_flags[#SB.lock_flags + 1] = fl
			end
		end
	end
end

-- A spell's entry in the list. A spell not in it (the mod that added it is probably disabled)
-- gets a stand-in, marked `unknown`: its id as its name, type Other.
local unknown = {}
function SB.info(id)
	local info = SB.actions and SB.actions[id]
	if info then return info end
	if not unknown[id] then
		unknown[id] = { id = id, name = id, sprite = FALLBACK_SPRITE, type = SB.TYPE_OTHER, unknown = true }
	end
	return unknown[id]
end

-- The spell's entry, if the game gives it limited uses.
function SB.limited_info(id)
	local info = SB.actions and SB.actions[id]
	if info and info.max_uses and info.max_uses > 0 then return info end
	return nil
end

function SB.is_locked(info)
	return info.flag ~= nil and info.flag ~= "" and not HasFlagPersistent(info.flag)
end

-- Whether the Unlimited spells perk has been taken this run (the game keeps it in the world
-- state, where the perk's own script sets it).
function SB.unlimited_spells()
	local world = GameGetWorldStateEntity and GameGetWorldStateEntity()
	if not world or world == 0 then return false end
	local ws = EntityGetFirstComponentIncludingDisabled(world, "WorldStateComponent")
	return ws ~= nil and ComponentGetValue2(ws, "perk_infinite_spells") == true
end
