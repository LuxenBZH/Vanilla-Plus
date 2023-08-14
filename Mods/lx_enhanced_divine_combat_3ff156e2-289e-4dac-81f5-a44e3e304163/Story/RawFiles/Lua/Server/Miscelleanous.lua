Ext.RegisterOsirisListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    ---- Turn to oil AP refund
    if skill == "Target_Condense" and HasActiveStatus(character, "WET") == 1 then
        CharacterAddActionPoints(character, 1)
    end 
    ---- Sucker Punch cooldown fix
    if skill == "Target_SingleHandedAttack" and CharacterIsInCombat(character) == 1 then
        local statCooldown = Ext.GetStat("Target_SingleHandedAttack").Cooldown - CharacterHasTalent(character, "ExtraSkillPoints")
        PersistentVars.SPunchCooldown[character] = statCooldown
    end
end)

Ext.RegisterOsirisListener("ItemEquipped", 2, "before", function(item, character)
    if CharacterIsInCombat(character) == 1 and CharacterHasSkill(character, "Target_SingleHandedAttack") == 1 and PersistentVars.SPunchCooldown[character] ~= nil then
        NRD_SkillSetCooldown(character, "Target_SingleHandedAttack", 0.0)
        TimerLaunch("LX_SPunch_Cooldown_Fix", 300)
    end
end)

Ext.RegisterOsirisListener("ItemUnequipped", 2, "before", function(item, character)
    if CharacterIsInCombat(character) == 1 and CharacterHasSkill(character, "Target_SingleHandedAttack") == 1 and PersistentVars.SPunchCooldown[character] ~= nil then
        NRD_SkillSetCooldown(character, "Target_SingleHandedAttack", 0.0)
        TimerLaunch("LX_SPunch_Cooldown_Fix", 300)
    end
end)

Ext.RegisterOsirisListener("TimerFinished", 1, "before", function(timer)
    if timer == "LX_SPunch_Cooldown_Fix" then
        for char,cooldown in pairs(PersistentVars.SPunchCooldown) do
            if NRD_SkillGetCooldown(char, "Target_SingleHandedAttack") == 0.0 then
                NRD_SkillSetCooldown(char, "Target_SingleHandedAttack", cooldown*6.0)
            end
        end
    end
end)

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(object)
    if PersistentVars.SPunchCooldown[object] ~= nil then
        if PersistentVars.SPunchCooldown[object] > 0 then
            PersistentVars.SPunchCooldown[object] = PersistentVars.SPunchCooldown[object] - 1
        else
            PersistentVars.SPunchCooldown[object] = nil
        end
    end
end)

Ext.RegisterOsirisListener("ObjectLeftCombat", 2, "before", function(object, combatID)
    if PersistentVars.SPunchCooldown[object] ~= nil then
        PersistentVars.SPunchCooldown[object] = nil
    end
end)

---------- Perseverance effect
local incapacitatedTypes = {
    INCAPACITATED = true,
    KNOCKED_DOWN = true
}
--- @param character string GUID
--- @param status string StatusID
--- @param instigator string GUID
Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", function(character, status, causee)
    local sts
    if NRD_StatExists(status) and status ~= "SHOCKWAVE" then
        sts = Ext.GetStat(status)
    else
        return
    end
    local turns = GetStatusTurns(character, status)
    if incapacitatedTypes[sts.StatusType] and CharacterIsInCombat(character) == 1 then
        if turns > 10 or turns < 1 then return end
        local character = Ext.GetCharacter(character)
        local perseverance = character.Stats.Perseverance
        if perseverance == 0 then return end
        if NRD_StatExists("LX_PERSEVERANCE_"..perseverance) then
            ApplyStatus(character.MyGuid, "LX_PERSEVERANCE_"..perseverance, turns*6.0, 1)
        else
            local newPotion = Ext.CreateStat("DGM_Potion_Perseverance_"..perseverance, "Potion", "Stats_LX_Perseverance")
            for i,res in pairs(resistances) do
                newPotion[res] = math.floor(perseverance * Ext.ExtraData.DGM_PerseveranceResistance)
            end
            Ext.SyncStat(newPotion.Name, false)
            local newStatus = Ext.CreateStat("LX_PERSEVERANCE_"..perseverance, "StatusData", "LX_PERSEVERANCE")
            newStatus.StatsId = newPotion.Name
            Ext.SyncStat(newStatus.Name, false)
            ApplyStatus(character.MyGuid, "LX_PERSEVERANCE_"..perseverance, turns*6.0, 1)
        end
    end
end)

--- Remove Perseverance effect if the character gets a playable turn (the CC has been cleared before its expiration)
--- @param object string UUID
Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(object)
    if ObjectIsCharacter(object) == 0 then return end
    local char = Ext.GetCharacter(object)
    local perseverance = char.Stats.Perseverance
    if char:GetStatus("LX_PERSEVERANCE_"..perseverance) and char.Stats.CurrentAP > 0 then
        RemoveStatus(object, "LX_PERSEVERANCE_"..perseverance)
    end
end)
----------
---------- Last Rites workaround
Ext.RegisterOsirisListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    if skill == "Teleportation_LastRites" then
        ---@type EsvCharacter
        local char = Ext.GetCharacter(character)
        char.Stats.CurrentVitality = 1
    end
end)

----------
---------- Unstable cooldown
Ext.RegisterOsirisListener("CharacterResurrected", 1, "before", function(character)
    if CharacterHasTalent(character, "Unstable") == 1 then
        ApplyStatus(character, "LX_UNSTABLE_COOLDOWN", 12.0, 1, character)
    end
end)

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", function(character, status, causee)
    if status == "LX_UNSTABLE_COOLDOWN" then
        SetTag(character, "LX_UNSTABLE_COOLDOWN")
    end
end)

Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "before", function(character, status, causee)
    if status == "LX_UNSTABLE_COOLDOWN" and CharacterIsDead(character) == 0 then
        ClearTag(character, "LX_UNSTABLE_COOLDOWN")
    end
end)

Ext.RegisterOsirisListener("CharacterDied", 1, "before", function(character)
    if CharacterHasTalent(character, "Unstable") == 1 and IsTagged(character, "LX_UNSTABLE_COOLDOWN") == 0 then
        local pos = Ext.GetCharacter(character).WorldPos
		PlayEffectAtPosition("RS3_FX_GP_Combat_CorpseExplosion_Blood_01_Medium", pos[1], pos[2], pos[3])
    end
end)

----------
---------- Free Movement per turn
--- @param character EsvCharacter
function GetCharacterMovement(character)
    local stats = character.Stats.DynamicStats
    local movement = 0
    for i,ds in pairs(stats) do
        movement = movement + ds.Movement
    end
    return {
        Movement = movement,
        BaseMovement = stats[1].Movement
    }
end


RegisterTurnTrueStartListener(function(character)
    local char = Ext.GetCharacter(character)
    local movement = GetCharacterMovement(char)
    if movement.Movement >= movement.BaseMovement then
        char.PartialAP = char.PartialAP + 100/movement.Movement
    else
        char.PartialAP = char.PartialAP + movement.Movement/movement.BaseMovement * 100/movement.Movement
    end
end)

----------
---------- Wits increase healings
--- @param target string GUID
--- @param instigator string GUID
--- @param amount integer
--- @param handle double StatusHandle
-- Ext.RegisterOsirisListener("NRD_OnHeal", 4, "before", function(target, instigator, amount, handle)
--     -- Ext.Print(instigator, handle)
--     local heal = Ext.GetStatus(target, handle) ---@type EsvStatusHeal
--     local healer = Ext.GetCharacter(instigator)
--     local bonus = math.floor((healer.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * (healer.Stats.Wits - Ext.ExtraData.AttributeBaseValue)*Game.Math.GetLevelScaledDamage(healer.Stats.Level)*0.07)
--     local amount = heal.HealAmount
--     Ext.Print("Healing bonus",bonus)
--     if not heal.IsFromItem then
--         heal.HealAmount = -9999
--         Ext.Print(amount, bonus)
--         amount = amount + bonus
--         heal.HealAmount = amount
--     end
--     -- Ext.Dump(heal)
-- end)

Ext.Osiris.RegisterListener("NRD_OnStatusAttempt", 4, "before", function(target, status, handle, instigator)
    if instigator == "NULL_00000000-0000-0000-0000-000000000000" then return end -- Spams the console in few cases otherwise
    local s = Ext.ServerEntity.GetStatus(target, handle) --- @type EsvStatus|EsvStatusHeal|EsvStatusHealing
    local healer = Ext.ServerEntity.GetCharacter(instigator)
    -- Fix the double bonus from shared healings
    if status == "HEAL" and s.HealEffect == "HealSharing" then
        if s.HealType == "PhysicalArmor" then
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint / 100))
        elseif s.HealType == "MagicArmor" then
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint / 100))
        else
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint / 100))
        end
    end
    -- Wisdom bonus to any other heal that isn't LIFESTEAL
    -- HEAL is the proxy status used for the healing value, the original status will have a healing value equal to 0
    -- You need to recalculate the healing value manually, and the following HEAL proxies will duplicate that value
    -- Note : you cannot track the origin of HEAL proxies. In case where a custom value would be needed for each tick, applying a new status each tick could be a workaround.
    if (s.StatusType == "HEAL" or s.StatusType == "HEALING") and status ~= "HEAL" and status ~= "LIFESTEAL" then
        local stat = Ext.Stats.Get(s.StatusId)
        if stat.HealType ~= "Qualifier" then return end
        -- local bonus = Data.Stats.HealType[stat.HealStat](healer)
        -- _P("HealAmount", Data.Math.GetHealValue(stat, healer), bonus)
        s.HealAmount = math.floor(Data.Math.GetHealScaledWisdomValue(stat, healer) / math.max(1, 1 + (healer.Stats.WaterSpecialist*Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint/100)))
        -- s.HealAmount = Data.Math.GetHealScaledWisdomValue(stat, healer)
        _P(s.HealAmount)
        -- _P("ScaledAmount", s.HealAmount)
    elseif status == "LIFESTEAL" then
        s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint / 100))
    end
end)