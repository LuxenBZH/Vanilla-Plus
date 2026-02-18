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
HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "VP_WeaponSignatures", function(hit, instigator, target, flags)
    local mainWeapon, offhandWeapon = Helpers.Character.GetWeaponTypes(instigator)
    if hit.SkillId == "Target_LX_AxeAttack_-1" or (hit.SkillId == "Target_LX_DualWieldingAttack_-1" and ((target.UserVars.VP_ConsecutiveHitFromSkill.Amount == 2 and offhandWeapon == "Axe") or (target.UserVars.VP_ConsecutiveHitFromSkill.Amount ~= 2 and mainWeapon == "Axe"))) then
        local mainDamage = mainWeapon == "Axe" and instigator.Stats.MainWeapon.StatsEntry['Damage Type'] or instigator.Stats.OffHandWeapon.StatsEntry['Damage Type']
        local correspondingArmor = Data.DamageTypeToArmorType[mainDamage]
        local correspondingDamage = correspondingArmor == "CurrentArmor" and HitHelpers.HitGetPhysicalDamage(hit.Hit) or HitHelpers.HitGetMagicDamage(hit.Hit)
        if not Helpers.IsCharacter(target) or (target.Stats[correspondingArmor] - correspondingDamage <= 0) then
            local twoHandedMultiplier = instigator.Stats.MainWeapon.IsTwoHanded and 1 or 2
            local totalDamage = Ext.Utils.Round(math.min(HitHelpers.HitGetTotalDamage(hit.Hit)*0.75/twoHandedMultiplier, instigator.Stats.MaxVitality*0.08/twoHandedMultiplier))
            HitHelpers.HitAddDamage(hit.Hit, target, instigator, mainDamage, totalDamage)
            Helpers.Character.AddSkillCooldown(instigator, "Target_LX_AxeAttack", 6.0)
        end
    elseif hit.SkillId == "Target_LX_MaceCrush_-1" or (hit.SkillId == "Target_LX_DualWieldingAttack_-1" and ((target.UserVars.VP_ConsecutiveHitFromSkill.Amount == 2 and offhandWeapon == "Club") or (target.UserVars.VP_ConsecutiveHitFromSkill.Amount ~= 2 and mainWeapon == "Club"))) then
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
    elseif hit.SkillId == "Target_LX_DualWieldingAttack_-1" and ((target.UserVars.VP_ConsecutiveHitFromSkill.Amount == 2 and offhandWeapon == "Sword") or (target.UserVars.VP_ConsecutiveHitFromSkill.Amount ~= 2 and mainWeapon == "Sword")) then
        local cleaveCandidates = Helpers.GetCharactersAroundPosition(target.WorldPos[1], target.WorldPos[2], target.WorldPos[3], 2)
        local cleaveTarget = nil
        local lowestDistance = 3
        for i,character in pairs(cleaveCandidates) do
            if CharacterIsEnemy(instigator.MyGuid, character.MyGuid) == 1 and character ~= target then --- Note: CharacterIsEnemy is always false if Peace Mode is active !
                local newDistance = Ext.Math.Distance(target.WorldPos, character.WorldPos)
                if newDistance < lowestDistance then
                    cleaveTarget = character
                    lowestDistance = newDistance
                end
            end
        end
        if not cleaveTarget then
            return
        end
        local cleaveHit = NRD_HitPrepare(cleaveTarget.MyGuid, instigator.MyGuid)
        for i,element in pairs(hit.Hit.DamageList:ToTable()) do
            NRD_HitAddDamage(cleaveHit, element.DamageType, element.Amount*0.5)
        end
        local dodged = math.random(0, 99) >= Game.Math.CalculateHitChance(instigator.Stats, target.Stats)
        NRD_HitSetInt(cleaveHit, "Dodged", dodged and 1 or 0)
        NRD_HitSetInt(cleaveHit, "Missed", dodged and 1 or 0)
        NRD_HitSetString(cleaveHit, "DeathType", "Physical")
        NRD_HitSetInt(cleaveHit, "HitType", 4)
        NRD_HitSetInt(cleaveHit, "Hit", 1)
        NRD_HitQryExecute(cleaveHit)
        HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, 0.5)
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

---@param hit EsvStatusHit
---@param instigator EsvCharacter
---@param target EsvCharacter
---@param flags HitFlags
HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "VP_DomeOfProtection", function(hit, instigator, target, flags)
    local dome = target:GetStatus("LX_PROTECTION_CIRCLE")
    if dome and flags.IsDirectAttack then
        local domeAction = Helpers.GameAction.GetSkillId(target.WorldPos[1], target.WorldPos[3], Ext.Stats.Get("Dome_CircleOfProtection").AreaRadius, "Dome_CircleOfProtection")[1]
        if domeAction then
            HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, 0.65)
        end
    end
end)