Ext.RegisterListener("SessionLoaded", function()
    if PersistentVars.Soulcatcher == nil then
        PersistentVars.Soulcatcher = {}
    end
end)
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
        if CharacterHasTalent(char, "GreedyVessel") == 1 then
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

--------- Indomitable START
local indomitableStatuses = {
    CHICKEN = true,
    FROZEN = true,
    PETRIFIED = true,
    STUNNED = true,
    KNOCKED_DOWN = true,
    CRIPPLED = true
}

Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "before", function(character, status, causee)
    local character = Ext.GetCharacter(character)
    if character.Stats.TALENT_Indomitable and indomitableStatuses[status] and not character:GetStatus("LX_INDOMITABLE_CD") then
        ApplyStatus(character.MyGuid, "LX_INDOMITABLE", 6.0)
    end
end)

Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "before", function(character, status, causee)
    if status ~= "LX_INDOMITABLE" then return end
    ApplyStatus(character, "LX_INDOMITABLE_CD", 12.0)
end)

--------- Indomitable END

--------- Soulcatcher START
Ext.RegisterOsirisListener("CharacterDied", 1, "before", function(character)
    if CharacterIsSummon(character) == 1 then return end
    local pos = Ext.GetCharacter(character).WorldPos
    local group = Ext.GetCharactersAroundPosition(pos[1], pos[2], pos[3], 12.0)
    for i,member in pairs(group) do
        if CharacterHasTalent(member, "Soulcatcher") == 1 and CharacterIsDead(member) == 0 and CharacterIsAlly(character, member) == 1 and CharacterIsInCombat(member) == 1 and HasActiveStatus(member, "LX_SOULCATCHER_CD") == 0 then
            local summoning = CharacterGetAbility(member, "Summoning")
            local corpse = CharacterSummonAtPosition(character, "e7e89c3f-b491-4771-a2e2-602cc89c3631", pos[1], pos[2], pos[3], 18.0, -1, summoning)
            local level = CharacterGetLevel(character)
            PersistentVars.Soulcatcher[character] = corpse
            if level >= 9 then
                CharacterAddSkill(corpse, "Shout_EnemyPoisonWave", 1)
            end
            if level >= 16 then
                CharacterAddSkill(corpse, "Shout_EnemySiphonPoison", 1);
            end
            ApplyStatus(member, "LX_SOULCATCHER_CD", 6.0)
        end
    end
end)

Ext.RegisterOsirisListener("CharacterResurrected", 1, "before", function(character)
    if PersistentVars.Soulcatcher[character] ~= nil then
        CharacterDie(PersistentVars.Soulcatcher[character], 0, "DoT")
    end
end)

Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "before", function(character, status, causee)
    if status ~= "SUMMONING_ABILITY" then return end
    for corpse,spawn in pairs(PersistentVars.Soulcatcher) do
        if spawn == character then
            PersistentVars.Soulcatcher[character] = nil
        end
    end
end)
--------- Soulcatcher END

--------- Gladiator START
---@param status EsvStatus
---@param context HitContext
-- Ext.RegisterListener("StatusHitEnter", function(status, context)
--     local pass, target = pcall(Ext.GetCharacter, status.TargetHandle) ---@type EsvCharacter
--     if not pass then return end
--     local pass, instigator = pcall(Ext.GetCharacter, status.StatusSourceHandle) ---@type EsvCharacter
--     if not pass then return end
--     if instigator == nil then return end
--     if status.DamageSourceType == "Attack"
--     local multiplier = 1.0
--     -- Ext.Print("FirstBlood:",firstBlood,firstBloodWeakened, status.DamageSourceType)
--     if HasActiveStatus(instigator.MyGuid, "LX_HUNTHUNTED") == 1  and (status.DamageSourceType == "Attack" or status.SkillId ~= "") then
--         SetVarInteger(instigator.MyGuid, "LXS_UsedHuntHunted", 1)
--         ApplyStatus(instigator.MyGuid, "LX_ONTHEHUNT", 6.0, 1)
--     end
--     if CharacterIsInCombat(target.MyGuid) == 1 and (status.DamageSourceType == "Attack" or status.SkillId ~= "") then
--         if HasActiveStatus(instigator.MyGuid, "LX_FIRSTBLOOD") == 1 then
--             ApplyStatus(instigator.MyGuid, "LX_FIRSTBLOOD_WEAKENED", 3.0, 1.0)
--         end
--     end
--     -- context.Hit.DamageList:Multiply(multiplier)
--     -- ReplaceDamages(dmgList, status.StatusHandle, target.MyGuid)
-- end)
--------- Gladiator END