HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "LX_WeaponArtsHit", function(status, instigator, target, flags, skillId)
    if flags.IsWeaponAttack and skillId and not flags.Missed and not flags.Blocked and not flags.Dodged then
        if instigator:GetStatus("LX_WA_AXE") then
            RemoveStatus(instigator.MyGuid, "LX_WA_AXE")
            local execute = instigator:GetStatus("LX_WEAPON_EXECUTE")
            if execute then
                execute.CurrentLifeTime = 30
                Helpers.Status.Multiply(execute, execute.StatsMultiplier + math.floor(status.Hit.TotalDamageDone / 2))
            else
                execute = Ext.PrepareStatus(instigator.MyGuid, "LX_WEAPON_EXECUTE", 18)
                execute.StatsMultiplier = math.floor(status.Hit.TotalDamageDone / 2)
                Ext.ApplyStatus(execute)
            end
        end
        Helpers.Timer.Start(30, function(target, instigator)
            target = Ext.ServerEntity.GetCharacter(target)
            instigator = Ext.ServerEntity.GetCharacter(instigator)
            local executeValue = Data.Math.Character.GetExecutionRange(instigator, true, false)
            if executeValue > target.Stats.CurrentVitality then
                Helpers.Character.Execute(target, instigator, "Physical")
            end
        end, nil, target.MyGuid, instigator.MyGuid)
    end
end)