local GB4Talents = {
    "Elementalist",
    "Sadist",
    "Haymaker",
    "Gladiator",
    "Indomitable",
    "Jitterbug",
    "Soulcatcher",
    "MasterThief",
    "GreedyVessel",
    "MagicCycles",
}

if Mods.LeaderLib ~= nil then
    TalentManager = Mods.LeaderLib.TalentManager
    for i,talent in pairs(GB4Talents) do
        TalentManager.EnableTalent(talent, VPlusId)
    end
end

-------- Magic Cycles START
--- @param object string UUID
--- @param combatId integer
Ext.RegisterOsirisListener("ObjectEnteredCombat", 2, "before", function(object, combatId)
    if ObjectIsCharacter(object) ~= 1 then return end
    local character = Ext.GetCharacter(object)
    if character.Stats.TALENT_MagicCycles then
        local roll = math.random(1, 2)
        if roll == 1 then
            ApplyStatus(object, "LX_GB4_MC_EA", 6.0, 1)
        else
            ApplyStatus(object, "LX_GB4_MC_WF", 6.0, 1)
        end
    end
end)

--- @param object string UUID
Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(object)
    if ObjectIsCharacter(object) ~= 1 then return end
    local character = Ext.GetCharacter(object)
    if character.Stats.TALENT_MagicCycles then
        if character:GetStatus("LX_GB4_MC_EA") then
            ApplyStatus(object, "LX_GB4_MC_WF", 6.0, 1)
        else
            ApplyStatus(object, "LX_GB4_MC_EA", 6.0, 1)
        end
    end
end)
--------- Magic Cycles END

--------- Greedy Vessel START
--- @param character string UUID
Ext.RegisterOsirisListener("SkillCast", 4, "before", function(character, skill, skillType, skillElement)
    if ObjectIsCharacter == 0 or CharacterIsInCombat(character) == 0 or Ext.GetStat(skill)["Magic Cost"] == 0 then return end
    local pos = Ext.GetCharacter(character).WorldPos
    local group = Ext.GetCharactersAroundPosition(pos[1], pos[2], pos[3], 20.0)
    for i,char in pairs(group) do
        if HasTalent(char, "GreedyVessel") == 1 then
            local roll = math.random(1,100)
            if roll < 20 then
                CharacterAddSourcePoints(char, 1)
                PlayEffect(char, "RS3_FX_GP_Status_SourceInfused_Hit_01")
            end
        end
    end
end)
--------- Greedy Vessel END

--------- Jitterbug START
Ext.RegisterOsirisListener("CharacterReceivedDamage", 3, "before", function(target, perc, instigator)
    local target = Ext.GetCharacter(target)
    if not target.Stats.TALENT_Jitterbug then return end
    if perc > 0 and target.Stats.CurrentArmor == 0 and target.Stats.CurrentMagicArmor == 0 and not target:GetStatus("LX_GB4_JITTERBUG_CD") then
        ApplyStatus(target.MyGuid, "LX_GB4_JITTERBUG_CD", 12.0);
        PlayEffect(target.MyGuid, "RS3_FX_GP_ScriptedEvent_Teleport_GenericSmoke_01");
        CharacterJitterbugTeleport(target.MyGuid,instigator, 8.0, 9.0);
    end
end)
--------- Jitterbug END