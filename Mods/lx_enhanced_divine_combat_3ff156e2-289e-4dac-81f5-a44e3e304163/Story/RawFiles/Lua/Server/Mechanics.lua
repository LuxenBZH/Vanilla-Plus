-------- Turn listeners (delay check)
local TurnListeners = {
    Start = {},
    End = {}
}

Ext.RegisterOsirisListener("CharacterGuarded", 1, "before", function(character)
    ObjectSetFlag(character, "HasDelayed")
end)

Ext.RegisterOsirisListener("ObjectTurnEnded", 1, "before", function(character)
    if ObjectGetFlag(character, "HasDelayed") == 0 then
        for i, listener in pairs(TurnListeners.End) do
            listener.Handle(character)
        end
    end
end)

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(character)
    if ObjectGetFlag(character, "HasDelayed") == 1 then
        ObjectClearFlag(character, "HasDelayed")
    else
        for i, listener in pairs(TurnListeners.Start) do
            listener.Handle(character)
        end
    end
end)

function RegisterTurnTrueStartListener(func)
    table.insert(TurnListeners.Start, {
        Name = "",
        Handle = func
    })
end

function RegisterTurnTrueEndListener(func)
    table.insert(TurnListeners.End, {
        Name = "",
        Handle = func
    })
end