Ext.Osiris.RegisterListener("CharacterUsedSkillAtPosition", 7, "before", function(character, x, y, z, skill, skillType, skillElement)
    --- Vaporize custom effects
    if skill == "Target_Vaporize" then
        --- Refund
        local surface = Helpers.GetSurfaceTypeAtPosition(x, z)
        local stat = Ext.Stats.Get("Target_Vaporize")
        if Data.VaporizeRefundSurfaces["Surface"..surface] then
            CharacterAddActionPoints(character, stat.ActionPoints)
        end
    end
end)

Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    --- Turn to oil AP refund
    if skill == "Target_Condense" and HasActiveStatus(character, "WET") == 1 then
        CharacterAddActionPoints(character, 1)
    end 
    --- Sucker Punch cooldown fix
    if skill == "Target_SingleHandedAttack" and CharacterIsInCombat(character) == 1 then
        local statCooldown = Ext.GetStat("Target_SingleHandedAttack").Cooldown - CharacterHasTalent(character, "ExtraSkillPoints")
        PersistentVars.SPunchCooldown[character] = statCooldown
    end
end)

Ext.Osiris.RegisterListener("ItemEquipped", 2, "before", function(item, character)
    if CharacterIsInCombat(character) == 1 and CharacterHasSkill(character, "Target_SingleHandedAttack") == 1 and PersistentVars.SPunchCooldown[character] ~= nil then
        NRD_SkillSetCooldown(character, "Target_SingleHandedAttack", 0.0)
        TimerLaunch("LX_SPunch_Cooldown_Fix", 300)
    end
end)

Ext.Osiris.RegisterListener("ItemUnequipped", 2, "before", function(item, character)
    if CharacterIsInCombat(character) == 1 and CharacterHasSkill(character, "Target_SingleHandedAttack") == 1 and PersistentVars.SPunchCooldown[character] ~= nil then
        NRD_SkillSetCooldown(character, "Target_SingleHandedAttack", 0.0)
        TimerLaunch("LX_SPunch_Cooldown_Fix", 300)
    end
end)

Ext.Osiris.RegisterListener("TimerFinished", 1, "before", function(timer)
    if timer == "LX_SPunch_Cooldown_Fix" then
        for char,cooldown in pairs(PersistentVars.SPunchCooldown) do
            if NRD_SkillGetCooldown(char, "Target_SingleHandedAttack") == 0.0 then
                NRD_SkillSetCooldown(char, "Target_SingleHandedAttack", cooldown*6.0)
            end
        end
    end
end)

if not PersistentVars.SPunchCooldown then
    PersistentVars.SPunchCooldown = {}
end

Ext.Osiris.RegisterListener("ObjectTurnStarted", 1, "before", function(object)
    if PersistentVars.SPunchCooldown and PersistentVars.SPunchCooldown[object] ~= nil then
        if PersistentVars.SPunchCooldown[object] > 0 then
            PersistentVars.SPunchCooldown[object] = PersistentVars.SPunchCooldown[object] - 1
        else
            PersistentVars.SPunchCooldown[object] = nil
        end
    end
end)

Ext.Osiris.RegisterListener("ObjectLeftCombat", 2, "before", function(object, combatID)
    if PersistentVars.SPunchCooldown[object] ~= nil then
        PersistentVars.SPunchCooldown[object] = nil
    end
end)