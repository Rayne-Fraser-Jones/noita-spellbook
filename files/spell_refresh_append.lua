-- Appended to data/scripts/items/spell_refresh.lua.
-- Signals Spellbook (which runs in a different Lua state) that a refresher was picked up.
local spellbook_original_item_pickup = item_pickup

function item_pickup( entity_item, entity_who_picked, name )
	if spellbook_original_item_pickup ~= nil then
		spellbook_original_item_pickup( entity_item, entity_who_picked, name )
	end
	if EntityHasTag( entity_who_picked, "player_unit" ) then
		GlobalsSetValue( "spellbank_refresh_request", tostring( GameGetFrameNum() ) .. "_" .. tostring( entity_item ) )
	end
end
