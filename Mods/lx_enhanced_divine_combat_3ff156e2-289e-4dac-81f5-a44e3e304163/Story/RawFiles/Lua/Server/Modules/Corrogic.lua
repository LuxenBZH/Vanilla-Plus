Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", function(target, status, causee)
    if status == "FORTIFIED" or status == "MAGIC_SHELL" then
        local corrogic = FindStatus(Ext.GetCharacter(target), "LX_CORROGIC")
        if corrogic ~= nil then
            RemoveStatus(target, corrogic)
        end
    end
end)