Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "after", function(characterGUID, skillName, _, _)
    if HasActiveStatus(characterGUID, "LX_SNIPER") == 1 then
        local skillEntry = Ext.Stats.Get(skillName) --- @type StatEntrySkillData
        if skillEntry["Damage Multiplier"] == 0 then
            local APCost = skillEntry.ActionPoints
            local sniper = Ext.ServerEntity.GetCharacter(characterGUID):GetStatus("LX_SNIPER")
            Helpers.Status.Multiply(sniper, sniper.StatsMultiplier + APCost)
        end
    end
end)

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
--- @param instigatorDGMStats table
HitManager:RegisterHitListener("DGM_Hit", "BeforeDamageScaling", "DGM_Specifics", function(hit, instigator, target, flags)
    local sniper = instigator:GetStatus("LX_SNIPER")
    if flags.IsWeaponAttack and not (flags.Blocked or flags.Missed or flags.Dodged) then
        if sniper and flags.Critical then
            local deadlyAim = instigator:GetStatus("LX_SNIPER_MULT")
            if not deadlyAim then
                deadlyAim = Ext.PrepareStatus(instigator.MyGuid, "LX_SNIPER_MULT", 12.0)
                deadlyAim.StatsMultiplier = sniper.StatsMultiplier
                deadlyAim.StatusSourceHandle = instigator.Handle
                Ext.ApplyStatus(deadlyAim)
            else
                Helpers.Status.Multiply(deadlyAim, deadlyAim.StatsMultiplier + sniper.StatsMultiplier)
                deadlyAim.CurrentLifeTime = 12.0
            end
            Helpers.Status.Multiply(sniper, 1)
        elseif target:GetStatus("LX_SNIPER") and Helpers.Character.GetFightType(instigator) == "Melee" then
            RemoveStatus(target.MyGuid, "LX_SNIPER")
        end
    end
end)

Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "after", function(characterGUID, status, instigator)
    if CharacterIsIncapacitated(characterGUID) == 1 and HasActiveStatus(characterGUID, "LX_SNIPER") == 1 then
        RemoveStatus(characterGUID, "LX_SNIPER")
    elseif status == "LX_SNIPER" then
        local pos = Ext.ServerEntity.GetCharacter(characterGUID).WorldPos
        Helpers.Timer.StartNamed(characterGUID.."SniperMovementListener", 250, function(guid, worldPos)
            local pos = Ext.ServerEntity.GetCharacter(guid).WorldPos
            if pos[1] ~= worldPos[1] or pos[3] ~= worldPos[3] then
                RemoveStatus(guid, "LX_SNIPER")
            end
        end, -1, characterGUID, pos)
    end
end)

Ext.Osiris.RegisterListener("CharacterStatusRemoved", 3, "after", function(characterGUID, status, instigator)
    if status == "LX_SNIPER" then
        Helpers.Timer.Delete(characterGUID.."SniperMovementListener")
    end
end)

Ext.Osiris.RegisterListener("ItemUnequipped", 2, "after", function(item, character)
    RemoveStatus(character, "LX_SNIPER")
    RemoveStatus(character, "LX_SNIPER_MULT")
end)