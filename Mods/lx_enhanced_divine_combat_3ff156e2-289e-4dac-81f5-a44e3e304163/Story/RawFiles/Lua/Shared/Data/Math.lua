Data.Math = {}

--- @param character EsvCharacter|EclCharacter
Data.Math.GetCharacterWisdom = function(character)
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint) / 100 + 1
end

--- @param character EsvCharacter|EclCharacter
Data.Math.GetCharacterWisdomArmor = function(character)
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint) / 100 + 1
end

--- @param character EsvCharacter|EclCharacter
Data.Math.GetCharacterWisdomMagicArmor = function(character)
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint) / 100 + 1
end

Data.Stats.HealType = {
    Vitality = Data.Math.GetCharacterWisdom,
    PhysicalArmor = Data.Math.GetCharacterWisdomArmor,
    MagicArmor = Data.Math.GetCharacterWisdomMagicArmor
}

--- @param stat StatEntryType
--- @param healer EsvCharacter|EclCharacter
Data.Math.GetHealScaledValue = function(stat, healer)
    local HealTypeSkillData = healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint
	-- When the status type is HEALING, the initial value is copied over to the next HEAL ticks and automatically apply the Hydro/Geo bonus
	if stat.StatusType == "HEALING" then
		HealTypeSkillData = 0
	elseif stat.HealStat == "PhysicalArmor" then
		HealTypeSkillData = healer.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint
	elseif stat.HealStat == "MagicArmor" then
		HealTypeSkillData = healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint
	end
	return Ext.Utils.Round(stat.HealValue * Game.Math.GetAverageLevelDamage(healer.Stats.Level) * Ext.ExtraData.HealToDamageRatio / 100 * (1 + HealTypeSkillData/100))
end

--- @param stat StatEntryType
--- @param healer EsvCharacter|EclCharacter
Data.Math.GetHealValue = function(stat, healer)
	return Ext.Utils.Round(stat.HealValue * Game.Math.GetAverageLevelDamage(healer.Stats.Level) * Ext.ExtraData.HealToDamageRatio / 100)
end

--- @param character EsvCharacter | EclCharacter
Data.Math.ComputeCharacterIngress = function(character)
    local ingressFromAttributes = math.min((character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceIngressBonus, (character.Stats.Strength - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthIngressCap)
    local ingressFromHuntsman = character.Stats.RangerLore * Ext.ExtraData.DGM_RangerLoreIngressBonus
    local ingressFromEquipment = 0 --TODO: Equipment Ingress stat and deltamods
    return ingressFromAttributes + ingressFromHuntsman + ingressFromEquipment
end