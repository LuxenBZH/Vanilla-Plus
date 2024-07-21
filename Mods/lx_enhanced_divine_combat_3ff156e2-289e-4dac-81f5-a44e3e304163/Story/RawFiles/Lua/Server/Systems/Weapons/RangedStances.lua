HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "SuppressionFire", function(hit, instigator, target, flags)
    local suppression = target:GetStatus("LX_SUPPRESSED")
    if suppression ~= null and (not flags.Dodged and not flags.Missed and not flags.Blocked) and flags.IsDirectAttack then
        if (flags.IsWeaponAttack and ((hit.DamageSourceType == "Offhand" and Game.Math.IsRangedWeapon(instigator.Stats.OffHandWeapon)) or Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon))) then
            CustomStatusManager:CharacterApplyMultipliedStatus(target, "LX_SUPPRESSED", -1, math.min(suppression.StatsMultiplier + 1.0, 5))
        end
    end
end)

HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "AimingStanceBreak", function(hit, instigator, target, flags)
    if target:GetStatus("LX_AIMING_STANCE") ~= null and (not flags.Dodged and not flags.Missed and not flags.Blocked) and flags.IsDirectAttack and flags.IsWeaponAttack then
        if ((hit.DamageSourceType == "Offhand" and not Game.Math.IsRangedWeapon(instigator.Stats.OffHandWeapon)) or not Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon)) then
            local skill = hit.SkillId ~= "" and Ext.Stats.Get(hit.SkillId:gsub("(.*).+-1$", "%1")) or nil --- @type StatEntrySkillData | nil
            if skill and skill.IsMelee == "Yes" or not skill then
                RemoveStatus(target.MyGuid, "LX_AIMING_STANCE")
                Helpers.Character.SetSkillCooldown(target, "Shout_LX_RangedAimingStance", 18.0)
            end
        end
    end
end)