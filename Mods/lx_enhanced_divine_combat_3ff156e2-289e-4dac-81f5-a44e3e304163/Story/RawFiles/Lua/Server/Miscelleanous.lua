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
