Ext.RegisterListener("SessionLoaded", function()
    if PersistentVars.Soulcatcher == nil then
        PersistentVars.Soulcatcher = {}
    end
end)
-------- Magic Cycles START
-- --- @param object string UUID
-- --- @param combatId integer
-- Ext.RegisterOsirisListener("ObjectEnteredCombat", 2, "before", function(object, combatId)
--     if ObjectIsCharacter(object) ~= 1 then return end
--     local character = Ext.GetCharacter(object)
--     if character.Stats.TALENT_MagicCycles then
--         local roll = math.random(1, 2)
--         if roll == 1 then
--             ApplyStatus(object, "LX_GB4_MC_EA", 6.0, 1)
--         else
--             ApplyStatus(object, "LX_GB4_MC_WF", 6.0, 1)
--         end
--     end
-- end)

-- --- @param object string UUID
-- Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(object)
--     if ObjectIsCharacter(object) ~= 1 then return end
--     local character = Ext.GetCharacter(object)
--     if character.Stats.TALENT_MagicCycles then
--         if character:GetStatus("LX_GB4_MC_EA") then
--             ApplyStatus(object, "LX_GB4_MC_WF", 6.0, 1)
--         else
--             ApplyStatus(object, "LX_GB4_MC_EA", 6.0, 1)
--         end
--     end
-- end)

local function TriggerMagicCycleEarth(instigator, pos)
    local cloud = Ext.ServerEntity.GetAiGrid():GetCellInfo(pos[1], pos[3]).CloudSurface
    if cloud then
        local characters = Helpers.GetCharactersInSurface(cloud)
        for i,character in pairs(characters) do
            local suffocating = character:GetStatus("SUFFOCATING")
            if CharacterIsEnemy(instigator.MyGuid, character.MyGuid) == 1 then
                if suffocating then
                    if suffocating.CurrentLifeTime >= 12.0 then
                        Helpers.Status.Multiply(suffocating, suffocating.StatsMultiplier + 0.2)
                    else
                        suffocating.CurrentLifeTime = suffocating.CurrentLifeTime + 6.0
                        suffocating.RequestClientSync = true
                    end
                else
                    ApplyStatus(character.MyGuid, "SUFFOCATING", 6.0, 0, instigator.MyGuid)
                end
            end
        end
    end
end

-- ---@param e EsvLuaProjectileHitEvent
Ext.Events.ProjectileHit:Subscribe(function(e)
    if e.HitObject and Ext.Utils.IsValidHandle(e.Projectile.SourceHandle) and e.Projectile.SkillId ~= "" then
        local skill = Ext.Stats.Get(string.gsub(e.Projectile.SkillId, "%_%-1", ""), nil, false)
        local instigator = Ext.ServerEntity.GetGameObject(e.Projectile.SourceHandle)
        if Helpers.IsCharacter(instigator) and instigator.Stats.TALENT_MagicCycles then
            if skill.Ability == "Air" then
                Ext.PropertyList.ExecuteSkillPropertiesOnPosition("Target_Vaporize", instigator.MyGuid, e.Position, skill.AreaRadius, {"Target", "AoE"}, false)
            elseif skill.Ability == "Earth" then
                TriggerMagicCycleEarth(instigator, e.Position)
            end
        end
    end
end)

Ext.Osiris.RegisterListener("CharacterUsedSkillAtPosition", 7, "after", function(character, x, y, z, skillName, skillType, ability)
    if CharacterHasTalent(character, "MagicCycles") == 1 and (ability == "Air" or ability == "Earth") and skillType ~= "Projectile" then
        local character = Ext.ServerEntity.GetCharacter(character)
        character.UserVars.VP_MagicCycles = {[1] =  {x,y,z}}
    end
end)

Ext.Osiris.RegisterListener("CharacterUsedSkillOnTarget", 5, "after", function(character, target, skillName, skillType, ability)
    if CharacterHasTalent(character, "MagicCycles") == 1 and (ability == "Air" or ability == "Earth") and skillType ~= "Projectile" then
        local character = Ext.ServerEntity.GetCharacter(character)
        local target = Ext.ServerEntity.GetCharacter(target)
        if not character.UserVars.VP_MagicCycles then
            character.UserVars.VP_MagicCycles = {
                [1] =  target.WorldPos
            }
        else
            character.UserVars.VP_MagicCycles[#character.UserVars.VP_MagicCycles+1] = target.WorldPos
        end
    end
end)

---@param e EsvLuaBeforeStatusApplyEvent
Ext.Events.BeforeStatusApply:Subscribe(function(e)
    local instigator = Ext.Utils.IsValidHandle(e.Status.StatusSourceHandle) and Ext.ServerEntity.GetCharacter(e.Status.StatusSourceHandle) or nil
    if instigator and instigator.Stats.TALENT_MagicCycles then
        local target = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle)
        local thermalShock = target:GetStatus("LX_THERMAL_SHOCK")
        if ((e.Status.StatusId == "BURNING" or e.Status.StatusId == "NECROFIRE") and (target:GetStatus("WET") or target:GetStatus("CHILLED") or target:GetStatus("FROZEN"))) then
            if thermalShock then
                thermalShock.CurrentLifeTime = thermalShock.CurrentLifeTime + 6.0
                thermalShock.RequestClientSync = true
            else
                ApplyStatus(target.MyGuid, "LX_THERMAL_SHOCK", 12, 0, instigator.MyGuid)
            end
        elseif ((e.Status.StatusId == "WET" or e.Status.StatusId == "CHILLED") and (target:GetStatus("BURNING")) or target:GetStatus("NECROFIRE") or target:GetStatus("WARM")) then
            if thermalShock then
                thermalShock.CurrentLifeTime = thermalShock.CurrentLifeTime + 6.0
                thermalShock.RequestClientSync = true
            else
                ApplyStatus(target.MyGuid, "LX_THERMAL_SHOCK", 12, 0, instigator.MyGuid)
            end
        end
    end
end)

Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "before", function(target, status, instigator)
    if HasActiveStatus(target, "LX_THERMAL_SHOCK") == 1 and status == "INSURFACE" then
        local cloud = GetSurfaceCloudAt(target)
        if cloud == "SurfaceWaterCloud" then
            local thermalShockInstigator = Ext.ServerEntity.GetCharacter(Ext.ServerEntity.GetGameObject(target):GetStatus("LX_THERMAL_SHOCK").OwnerHandle)
            ApplyDamage(target, Ext.Utils.Round(Game.Math.GetLevelScaledWeaponDamage(CharacterGetLevel(instigator))*0.4), "Water", thermalShockInstigator.MyGuid)
        end
    end
end)

Data.Math.Resistance:RegisterCalculationListener("LX_ThermalShock", function(target, attacker, damage, resistance, bypassValue)
    if target.Character:GetStatus("LX_THERMAL_SHOCK") and ((damage.DamageType == "Fire" and damage.Amount > 0) or (damage.DamageType == "Water" and damage.Amount > 0)) then
        local fireResistance = Game.Math.GetResistance(target, "Fire")
        local waterResistance = Game.Math.GetResistance(target, "Water")
        return math.min(fireResistance, waterResistance), bypassValue+15
    end
    return resistance, bypassValue
end)

-- Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "after", function(character, status, instigator)
--     _DS(Ext.ServerEntity.GetCharacter(character):GetStatus(status))
-- end)

Ext.Osiris.RegisterListener("SkillCast", 4, "after", function(character, skillName, _, ability)
    if CharacterHasTalent(character, "MagicCycles") == 1 then
        local character = Ext.ServerEntity.GetCharacter(character)
        local skill = Ext.Stats.Get(skillName, nil, true)
        if ability == "Air" then    
            local condense = false
            if not condense then
                for i,targetPos in pairs(character.UserVars.VP_MagicCycles or {}) do
                    for i,property in pairs(skill.SkillProperties or {}) do
                        if property.Action == "Condense" then
                            condense = true
                        end
                    end
                    Ext.PropertyList.ExecuteSkillPropertiesOnPosition("Target_Vaporize", character.MyGuid, {targetPos[1], targetPos[2], targetPos[3]}, skill.AreaRadius, {"Target", "AoE"}, false)
                end
                character.UserVars.VP_MagicCycles = nil
            end
        elseif ability == "Earth" then
            for i,targetPos in pairs(character.UserVars.VP_MagicCycles or {}) do
                TriggerMagicCycleEarth(character, targetPos)
            end
        end
    end
end)

-- ---@param e LuaGetSkillDamageEvent
-- Ext.Events.GetSkillDamage:Subscribe(function(e)
--     if e.Skill ~= "" and e.Attacker and getmetatable(e.Attacker) == "CDivinityStats_Character" and e.Attacker.TALENT_MagicCycles then
--         if e.Skill.Ability == "Air" then
--             Ext.PropertyList.ExecuteSkillPropertiesOnPosition("Target_Vaporize", attacker.Character.MyGuid, e.Position, e.Skill.AreaRadius, {"Target", "AoE"}, false)
--         end
--     end
-- end)

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
    if ObjectExists(character) == 0 then return end
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