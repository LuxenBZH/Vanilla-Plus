HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "RangedStancesMechanics", function(hit, instigator, target, flags)
    local skill = hit.SkillId ~= "" and Ext.Stats.Get(hit.SkillId:gsub("(.*).+-1$", "%1")) or nil --- @type StatEntrySkillData | nil
    --- Suppression
    local suppression = target:GetStatus("LX_SUPPRESSED")
    if Helpers.IsCharacter(instigator) and suppression and (not flags.Dodged and not flags.Missed and not flags.Blocked) and flags.IsDirectAttack then
        if (flags.IsWeaponAttack and ((hit.DamageSourceType == "Offhand" and Game.Math.IsRangedWeapon(instigator.Stats.OffHandWeapon)) or Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon))) then
            CustomStatusManager:CharacterApplyMultipliedStatus(target, "LX_SUPPRESSED", -1, math.min(suppression.StatsMultiplier + 1.0, 5))
        end
    end
    --- Aiming stance break
    if Helpers.IsCharacter(instigator) and target:GetStatus("LX_AIMING_STANCE") and (not flags.Dodged and not flags.Missed and not flags.Blocked) and flags.IsDirectAttack and flags.IsWeaponAttack then
        if ((hit.DamageSourceType == "Offhand" and not Game.Math.IsRangedWeapon(instigator.Stats.OffHandWeapon)) or not Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon)) then
            if skill and skill.IsMelee == "Yes" or not skill then
                RemoveStatus(target.MyGuid, "LX_AIMING_STANCE")
                Helpers.Character.SetSkillCooldown(target, "Shout_LX_RangedAimingStance", 18.0)
            end
        end
    end
    --- Hunter mark bonus
    local mark = target:GetStatus("LX_HUNTERMARK_APPLIED")
    if Helpers.IsCharacter(instigator) and mark and mark.StatusSourceHandle == instigator.Handle and flags.IsWeaponAttack and hit.SkillId ~= "" and Helpers.UserVars.GetVar(instigator, "VP_LastSkillsUsed")[1].Name == skill.Name then
        HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, 1.5)
        Osi.ProcObjectTimer(target.MyGuid, "VP_HunterMarkComboTimer", 1000)
    end
    --- Rapid fire damage penalty
    if Helpers.IsCharacter(instigator) and instigator:GetStatus("LX_RAPIDFIRE") and flags.IsWeaponAttack and skill and Helpers.UserVars.GetVar(instigator, "VP_LastSkillsUsed")[1].Name == skill.Name and skill.ActionPoints > 1 then
        HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, 1 - (0.75 / skill.ActionPoints))
    end
    --- Reflex stance Celerity bonus
    if Helpers.IsCharacter(instigator) and instigator:GetStatus("LX_REFLEX_STANCE") and flags.IsWeaponAttack and (not flags.Missed and not flags.Blocked and not flags.Dodged) then
        if (flags.IsWeaponAttack and ((hit.DamageSourceType == "Offhand" and Game.Math.IsRangedWeapon(instigator.Stats.OffHandWeapon)) or Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon))) then
            local stance = instigator:GetStatus("LX_REFLEX_BONUS")
            if stance and stance.CurrentLifeTime > 0 then
                Helpers.Status.Multiply(stance, math.min(stance.StatsMultiplier + 1, 4))
            else
                ApplyStatus(instigator.MyGuid, "LX_REFLEX_BONUS", 1.0, 1, instigator.MyGuid)
            end
        end
    end
end)

--- Hunter mark removal
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
    if event == "VP_HunterMarkComboTimer" then
        RemoveStatus(character, "LX_HUNTERMARK_APPLIED")
    end
end)

--- Hunter mark application check
---@param e ExtenderBeforeStatusDeleteEventParams
Ext.Events.StatusDelete:Subscribe(function(e)
    if e.Status.StatusId == "LX_HUNTERMARK" then
        local instigator = Ext.ServerEntity.GetCharacter(e.Status.StatusSourceHandle)
        if instigator:GetStatus("LX_AIMING_STANCE") then
            ApplyStatus(Ext.ServerEntity.GetCharacter(e.Status.TargetHandle).MyGuid, "LX_HUNTERMARK_APPLIED", 6.0, 1, instigator.MyGuid)
        end
    end
end)

--- Rapid fire removal
Helpers.RegisterTurnTrueEndListener(function(character)
    if HasActiveStatus(character, "LX_RAPIDFIRE") == 1 then
        RemoveStatus(character, "LX_RAPIDFIRE")
    end
end)

Ext.Events.BeforeStatusApply:Subscribe(function(e)
    if e.Status.StatusId == "LX_RELOAD" then
        local character = Ext.ServerEntity.GetCharacter(e.Owner.Handle)
        local skill = Helpers.UserVars.GetVar(character, "VP_HuntsmanReloadLastSkill")
        if skill then
            local currentCD = character:GetSkillInfo(skill).ActiveCooldown
            local cdReduction = math.min(math.floor(Data.Math.ComputeCharacterCelerity(character) / math.abs(Ext.Stats.Get(Ext.Stats.Get(e.Status.StatusId).StatsId).VP_Celerity)), currentCD)
            Helpers.Character.SetSkillCooldown(character, skill, math.max(character:GetSkillInfo(skill).ActiveCooldown - (cdReduction * 6.0), 0))
            e.Status.StatsMultiplier = cdReduction
        end
    end
end)

Ext.Osiris.RegisterListener("ItemUnEquipped", 2, "before", function(item, character)
    if ObjectExists(item) == 1 then
        local item = Helpers.ServerSafeGetItem(item)
        if Game.Math.IsRangedWeapon(item.Stats) then
            RemoveStatus(character, "LX_RAPIDFIRE")
            RemoveStatus(character, "LX_AIMING_STANCE")
            RemoveStatus(character, "LX_REFLEX_STANCE")
        end
    end
end)

---comment
---@param object GUID
Helpers.RegisterTurnTrueStartListener(function(object)
    if ObjectIsCharacter(object) and HasActiveStatus(object, "LX_RELOAD") == 1 then
        RemoveStatus(character, "")
    end
end)