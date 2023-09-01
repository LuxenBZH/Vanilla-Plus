local tauntArray = {}

---- Register an array with who taunted who
---@param char string
---@param status string
---@param instigator string
Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "after", function(char, status, instigator)
    if status ~= "TAUNTED" then return end
    tauntArray[char] = instigator
    -- Ext.Dump(tauntArray)
end)

---- Set the preferred target tag on the taunter
---@param object string
Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "after", function(object)
    if tauntArray[object] ~= nil then
        SetTag(tauntArray[object], "AI_PREFERRED_TARGET")
        Ext.Print("Set taunt tag")
    end
end)

---- Remove the tag at the end of the turn
---@param object string
Ext.RegisterOsirisListener("ObjectTurnEnded", 1, "before", function(object)
    if tauntArray[object] ~= nil then
        ClearTag(tauntArray[object], "AI_PREFERRED_TARGET")
        Ext.Print("Cleared taunt tag")
    end
end)

---- Remove the entity from the taunt array if it's not taunted anymore
---@param char string
---@param status string
---@param instigator string
Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "after", function(char, status, instigator)
    if status == "TAUNTED" and tauntArray[char] ~= nil then
        tauntArray[char] = nil
    end
end)

-- Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(object)
--     if (HasActiveStatus(object, "TAUNTED") == 1 or HasActiveStatus(object, "MADNESS") == 1 or HasActiveStatus(object, "CHARMED") == 1) and ObjectIsCharacter(object) == 1 then
--         if Ext.GetCharacter(object).IsPossessed then
--             Ext.PostMessageToUser(Ext.GetCharacter(object).UserID, "DGM_test", "")
--         end
--     end
-- end)