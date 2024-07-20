HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "SuppressionFire", function(hit, instigator, target, flags)
    local suppression = target:GetStatus("LX_SUPPRESSED")
    if suppression ~= null and (not flags.Dodged and not flags.Missed and not flags.Blocked) and flags.IsDirectAttack then
        if (flags.IsWeaponAttack and ((hit.DamageSourceType == "Offhand" and Game.Math.IsRangedWeapon(instigator.Stats.OffHandWeapon)) or Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon))) then
            CustomStatusManager:CharacterApplyMultipliedStatus(target, "LX_SUPPRESSED", -1, math.min(suppression.StatsMultiplier + 1.0, 5))
        end
    end
end)