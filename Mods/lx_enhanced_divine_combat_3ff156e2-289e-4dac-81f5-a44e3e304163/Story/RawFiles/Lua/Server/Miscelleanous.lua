Ext.RegisterOsirisListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    ---- Turn to oil AP refund
    if skill == "Target_Condense" and HasActiveStatus(character, "WET") == 1 then
        CharacterAddActionPoints(character, 1)
    end 
    ---- Sucker Punch cooldown fix
    if skill == "Target_SingleHandedAttack" and CharacterIsInCombat(character) == 1 then
        local statCooldown = Ext.GetStat("Target_SingleHandedAttack").Cooldown - CharacterHasTalent(character, "ExtraSkillPoints")
        PersistentVars.SPunchCooldown[character] = statCooldown
    end
end)

Ext.RegisterOsirisListener("ItemEquipped", 2, "before", function(item, character)
    if CharacterIsInCombat(character) == 1 and CharacterHasSkill(character, "Target_SingleHandedAttack") == 1 and PersistentVars.SPunchCooldown[character] ~= nil then
        NRD_SkillSetCooldown(character, "Target_SingleHandedAttack", 0.0)
        TimerLaunch("LX_SPunch_Cooldown_Fix", 300)
    end
end)

Ext.RegisterOsirisListener("ItemUnequipped", 2, "before", function(item, character)
    if CharacterIsInCombat(character) == 1 and CharacterHasSkill(character, "Target_SingleHandedAttack") == 1 and PersistentVars.SPunchCooldown[character] ~= nil then
        NRD_SkillSetCooldown(character, "Target_SingleHandedAttack", 0.0)
        TimerLaunch("LX_SPunch_Cooldown_Fix", 300)
    end
end)

Ext.RegisterOsirisListener("TimerFinished", 1, "before", function(timer)
    if timer == "LX_SPunch_Cooldown_Fix" then
        for char,cooldown in pairs(PersistentVars.SPunchCooldown) do
            if NRD_SkillGetCooldown(char, "Target_SingleHandedAttack") == 0.0 then
                NRD_SkillSetCooldown(char, "Target_SingleHandedAttack", cooldown*6.0)
            end
        end
    end
end)

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(object)
    if PersistentVars.SPunchCooldown[object] ~= nil then
        if PersistentVars.SPunchCooldown[object] > 0 then
            PersistentVars.SPunchCooldown[object] = PersistentVars.SPunchCooldown[object] - 1
        else
            PersistentVars.SPunchCooldown[object] = nil
        end
    end
end)

Ext.RegisterOsirisListener("ObjectLeftCombat", 2, "before", function(object, combatID)
    if PersistentVars.SPunchCooldown[object] ~= nil then
        PersistentVars.SPunchCooldown[object] = nil
    end
end)



---- Perseverance effect
local incapacitatedTypes = {
    INCAPACITATED = true,
    KNOCKED_DOWN = true
}
local resistances = {
    "FireResistance",
    "WaterResistance",
    "AirResistance",
    "EarthResistance",
    "PoisonResistance",
    "PhysicalResistance",
    "PiercingResistance"
}
--- @param character string GUID
--- @param status string StatusID
--- @param instigator string GUID
Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", function(character, status, causee)
    local sts
    if NRD_StatExists(status) then
        sts = Ext.GetStat(status)
    else
        return
    end
    if incapacitatedTypes[sts.StatusType] then
        local turns = GetStatusTurns(character, status)
        if turns > 10 or turns < 1 then return end
        local character = Ext.GetCharacter(character)
        local perseverance = character.Stats.Perseverance
        if NRD_StatExists("LX_PERSEVERANCE_"..perseverance) then
            ApplyStatus(character.MyGuid, "LX_PERSEVERANCE_"..perseverance, turns*6.0, 1)
        else
            local newPotion = Ext.CreateStat("Stats_LX_Perseverance_"..perseverance, "Potion", "Stats_LX_Perseverance")
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