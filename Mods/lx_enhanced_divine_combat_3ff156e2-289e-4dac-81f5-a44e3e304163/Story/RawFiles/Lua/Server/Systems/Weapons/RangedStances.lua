HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "RangedStancesMechanics", function(hit, instigator, target, flags)
    --- Suppression
    local suppression = target:GetStatus("LX_SUPPRESSED")
    if suppression ~= null and (not flags.Dodged and not flags.Missed and not flags.Blocked) and flags.IsDirectAttack then
        if (flags.IsWeaponAttack and ((hit.DamageSourceType == "Offhand" and Game.Math.IsRangedWeapon(instigator.Stats.OffHandWeapon)) or Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon))) then
            CustomStatusManager:CharacterApplyMultipliedStatus(target, "LX_SUPPRESSED", -1, math.min(suppression.StatsMultiplier + 1.0, 5))
        end
    end
    --- Aiming stance break
    if target:GetStatus("LX_AIMING_STANCE") ~= null and (not flags.Dodged and not flags.Missed and not flags.Blocked) and flags.IsDirectAttack and flags.IsWeaponAttack then
        if ((hit.DamageSourceType == "Offhand" and not Game.Math.IsRangedWeapon(instigator.Stats.OffHandWeapon)) or not Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon)) then
            local skill = hit.SkillId ~= "" and Ext.Stats.Get(hit.SkillId:gsub("(.*).+-1$", "%1")) or nil --- @type StatEntrySkillData | nil
            if skill and skill.IsMelee == "Yes" or not skill then
                RemoveStatus(target.MyGuid, "LX_AIMING_STANCE")
                Helpers.Character.SetSkillCooldown(target, "Shout_LX_RangedAimingStance", 18.0)
            end
        end
    end
    --- Hunter mark bonus
    if target:GetStatus("LX_HUNTERMARK_APPLIED") ~= null and flags.IsWeaponAttack and hit.SkillId ~= "" and instigator.UserVars.VP_LastSkillID.Name == hit.SkillId:gsub("(.*).+-1$", "%1") then
        HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, 1.5)
        Osi.ProcObjectTimer(target.MyGuid, "VP_HunterMarkComboTimer", 1000)
    end
end)

Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
    if event == "VP_HunterMarkComboTimer" then
        RemoveStatus(character, "LX_HUNTERMARK_APPLIED")
    end
end)

---@param e ExtenderBeforeStatusDeleteEventParams
Ext.Events.StatusDelete:Subscribe(function(e)
    if e.Status.StatusId == "LX_HUNTERMARK" then
        local instigator = Ext.ServerEntity.GetCharacter(e.Status.StatusSourceHandle)
        if instigator:GetStatus("LX_AIMING_STANCE") ~= null then
            ApplyStatus(Ext.ServerEntity.GetCharacter(e.Status.TargetHandle).MyGuid, "LX_HUNTERMARK_APPLIED", 6.0, 1, instigator.MyGuid)
        end
    end
end)