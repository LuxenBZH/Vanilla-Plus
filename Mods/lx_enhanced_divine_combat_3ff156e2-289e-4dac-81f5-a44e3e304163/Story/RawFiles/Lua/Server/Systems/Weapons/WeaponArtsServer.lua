HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "LX_WeaponArtsHit", function(status, instigator, target, flags, skillId)
    if instigator == nil then return end
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
    elseif GetVarString(target.MyGuid, "LX_SwordWA_PreparedSkill") ~= nil and GetVarString(target.MyGuid, "LX_SwordWA_PreparedSkill") ~= "" and flags.IsWeaponAttack and GetDistanceTo(target.MyGuid, instigator.MyGuid) <= target.Stats.MainWeapon.WeaponRange then
        CharacterUseSkill(target.MyGuid, GetVarString(target.MyGuid, "LX_SwordWA_PreparedSkill"), instigator.MyGuid, 0, 0, 1)
        RemoveStatus(target.MyGuid, "LX_WA_SWORD")
    end
    if instigator:GetStatus("LX_WA_TRUESTRIKE") then
        ---Check if the character is back to idle state and remove True Strike
        ---@param character EsvCharacter
        Helpers.Timer.StartNamed("LX_TrueStrike_"..instigator.MyGuid, 30, function(guid)
            local character = Ext.ServerEntity.GetCharacter(guid)
            if character.ActionMachine.Layers[1].State == null then
                RemoveStatus(character.MyGuid, "LX_WA_TRUESTRIKE")
                Helpers.Timer.Delete("LX_TrueStrike_"..guid)
            end
        end, 150, instigator.MyGuid)
    end
end)

Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "before", function(character, status, instigator)
    if status == "LX_WA_TRUESTRIKE" then
        local character = Ext.ServerEntity.GetCharacter(character)
        local trueStrike = character:GetStatus(status)
        Helpers.Status.Multiply(trueStrike, math.min(Helpers.Character.GetWarmupStacks(character)*3*(1.0 + 0.1 * character.Stats.WarriorLore)*3, 30))
    end
end)