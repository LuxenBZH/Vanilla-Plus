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

---@param hit EsvStatusHit
---@param instigator EsvCharacter
---@param target EsvCharacter
---@param flags HitFlags
HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "VP_AxeAttackBonus", function(hit, instigator, target, flags)
    if hit.SkillId == "Target_LX_AxeAttack_-1" and Helpers.IsCharacter(target) then
        local mainDamage = (instigator.Stats.MainWeapon and instigator.Stats.MainWeapon.WeaponType == "Axe") and instigator.Stats.MainWeapon.StatsEntry['Damage Type'] or 
            instigator.Stats.OffHandWeapon.StatsEntry['Damage Type']
        local correspondingArmor = Data.DamageTypeToArmorType[mainDamage]
        local correspondingDamage = correspondingArmor == "CurrentArmor" and HitHelpers.HitGetPhysicalDamage(hit.Hit) or HitHelpers.HitGetMagicDamage(hit.Hit)
        if target.Stats[correspondingArmor] - correspondingDamage <= 0 then
            local totalDamage = Ext.Utils.Round(math.min(HitHelpers.HitGetTotalDamage(hit.Hit)*0.75, instigator.Stats.MaxVitality*0.08))
            HitHelpers.HitAddDamage(hit.Hit, target, instigator, mainDamage, totalDamage)
            Helpers.Character.AddSkillCooldown(instigator, "Target_LX_AxeAttack", 6.0)
        end
    elseif hit.SkillId == "Target_LX_MaceCrush_-1" and Helpers.IsCharacter(target) then
        local mainDamage = (instigator.Stats.MainWeapon and instigator.Stats.MainWeapon.WeaponType == "Club") and instigator.Stats.MainWeapon.StatsEntry['Damage Type'] or 
            instigator.Stats.OffHandWeapon.StatsEntry['Damage Type']
        local correspondingArmor = Data.DamageTypeToArmorType[mainDamage]
        if target.Stats[correspondingArmor] <= 0 then
            Helpers.Character.AddSkillCooldown(instigator, "Target_LX_MaceCrush", -6.0)
        end
        local totalDamage = Ext.Utils.Round(HitHelpers.HitGetTotalDamage(hit.Hit)*0.8)
        HitHelpers.HitAddDamage(hit.Hit, target, instigator, Data.ArmorTypeDamage[correspondingArmor], totalDamage)
    elseif hit.SkillId == "Zone_LX_SpearAttack_-1" and Helpers.IsCharacter(target) then
        local count = GetVarInteger(instigator.MyGuid, "VP_SpearAttackCount") or 0
        SetVarInteger(instigator.MyGuid, "VP_SpearAttackCount", count+1)
    elseif hit.SkillId == "Target_LX_SwordCleave_-1" and Helpers.IsCharacter(target) then
        local count = GetVarInteger(instigator.MyGuid, "VP_SwordAttackCount") or 0
        SetVarInteger(instigator.MyGuid, "VP_SwordAttackCount", count+1)
    end
end)

Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "after", function(character, skill, _, _)
    if skill == "Zone_LX_SpearAttack" then
        Helpers.Timer.Start(1200, function(character)
            local count = GetVarInteger(character, "VP_SpearAttackCount") or 0
            if count > 2 then
                Helpers.Character.AddSkillCooldown(Ext.ServerEntity.GetCharacter(character), "Zone_LX_SpearAttack", (count-2)*6)
            end
            SetVarInteger(character, "VP_SpearAttackCount", 0)
        end, nil, character)
    elseif skill == "Target_LX_SwordCleave" then
        Helpers.Timer.Start(1200, function(character)
            local count = GetVarInteger(character, "VP_SwordAttackCount") or 0
            if count > 2 then
                Helpers.Character.AddSkillCooldown(Ext.ServerEntity.GetCharacter(character), "Target_LX_SwordCleave", (count-2)*6)
            end
            SetVarInteger(character, "VP_SwordAttackCount", 0)
        end, nil, character)
    end
end)