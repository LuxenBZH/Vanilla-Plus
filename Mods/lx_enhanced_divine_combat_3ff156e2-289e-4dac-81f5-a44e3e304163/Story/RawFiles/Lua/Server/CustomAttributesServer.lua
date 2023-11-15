---------- Wisdom healing increase
--- @param target string GUID
--- @param instigator string GUID
--- @param amount integer
--- @param handle double StatusHandle
Ext.Osiris.RegisterListener("NRD_OnStatusAttempt", 4, "before", function(target, status, handle, instigator)
    if instigator == "NULL_00000000-0000-0000-0000-000000000000" then return end -- Spams the console in few cases otherwise
    local s = Ext.ServerEntity.GetStatus(target, handle) --- @type EsvStatus|EsvStatusHeal|EsvStatusHealing
    if ObjectIsCharacter(instigator) == 0 then return end
    local healer = Ext.ServerEntity.GetCharacter(instigator)
    -- Fix the double bonus from shared healings
    if status == "HEAL" and s.HealEffect == "HealSharing" then
        if s.HealType == "PhysicalArmor" then
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint / 100))
        elseif s.HealType == "MagicArmor" then
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint / 100))
        else
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint / 100))
        end
    end
    -- Wisdom bonus to any other heal that isn't LIFESTEAL
    -- HEAL is the proxy status used for the healing value, the original status will have a healing value equal to 0
    -- You need to recalculate the healing value manually, and the following HEAL proxies will duplicate that value
    -- Note : you cannot track the origin of HEAL proxies. In case where a custom value would be needed for each tick, applying a new status each tick could be a workaround.
    if (s.StatusType == "HEAL" or s.StatusType == "HEALING") and status ~= "HEAL" and status ~= "LIFESTEAL" then
        local stat = Ext.Stats.Get(s.StatusId)
        if stat.HealType ~= "Qualifier" then return end
        s.HealAmount = math.floor(Data.Math.GetHealScaledWisdomValue(stat, healer) / math.max(1, 1 + (healer.Stats.WaterSpecialist*Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint/100)))
        -- _P("ScaledAmount", s.HealAmount)
    elseif status == "LIFESTEAL" then
        s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint / 100))
    end
end)

---------- Celerity free movement attribution
---@param character GUID
---@param status string
---@param instigator GUID
Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "before", function(character, status, instigator)
    if not Data.Stats.BannedStatusesFromChecks[status] and status ~= "" and NRD_StatExists(status) == 1 then
        local character = Ext.ServerEntity.GetCharacter(character)
        local status = character:GetStatus(status)
        local statEntry = Ext.Stats.Get(status.StatsId)
        if statEntry.VP_Celerity ~= 0 then
            character.PartialAP = character.PartialAP + Data.Math.ComputeCelerityValue(statEntry.VP_Celerity, character)
        end
    end
end)

----------
---------- Free Movement per turn
Helpers.RegisterTurnTrueStartListener(function(character)
    local char = Ext.ServerEntity.GetCharacter(character)
    local movement = Data.Math.GetCharacterMovement(char)
    local celerity = Data.Math.ComputeCelerityValue(Data.Math.ComputeCharacterCelerity(char), char)
    if movement.Movement >= movement.BaseMovement then
        char.PartialAP = char.PartialAP + 100/movement.Movement + celerity
    else
        char.PartialAP = char.PartialAP + movement.Movement/movement.BaseMovement * 100/movement.Movement + celerity
    end
end)