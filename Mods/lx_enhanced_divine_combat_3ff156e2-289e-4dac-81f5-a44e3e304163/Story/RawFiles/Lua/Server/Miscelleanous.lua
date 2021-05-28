---- Turn to oil AP refund
Ext.RegisterOsirisListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    if skill == "Target_Condense" and HasActiveStatus(character, "WET") == 1 then
        CharacterAddActionPoints(character, 1)
    end 
end)