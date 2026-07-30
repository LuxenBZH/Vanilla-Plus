_ActiveCharacterStartingPos = {}

Ext.Osiris.RegisterListener("ObjectTurnStarted", 1, "after", function(object)
    if ObjectIsCharacter(object) == 1 then
        -- Delay the check in case there is any modded effect
        Helpers.Timer.StartNamed("CharacterTurn", 34, function(GUID)
            local character = Ext.ServerEntity.GetCharacter(GUID)
            _ActiveCharacterStartingPos[object] = character.WorldPos
        end, 0, object)
    end
end)

Ext.Osiris.RegisterListener("ObjectTurnEnded", 1, "after", function(object)
    _ActiveCharacterStartingPos[object] = nil
    ClearTag(object, "LX_MovedDuringTurn")
end)

---@param e LuaTickEvent
Ext.Events.Tick:Subscribe(function(e)
    for GUID, startingTurnPosition in pairs(_ActiveCharacterStartingPos) do
        local character = Ext.ServerEntity.GetCharacter(GUID)
        if character.WorldPos[1] ~= startingTurnPosition[1] or character.WorldPos[2] ~= startingTurnPosition[2] or character.WorldPos[3] ~= startingTurnPosition[3] then
            SetTag(GUID, "LX_MovedDuringTurn")
            _ActiveCharacterStartingPos[GUID] = nil
        end
    end
end)