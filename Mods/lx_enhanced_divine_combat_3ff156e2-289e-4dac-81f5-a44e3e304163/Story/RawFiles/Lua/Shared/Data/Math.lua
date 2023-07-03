Data.Math = {}

--[[
    Character stats related formulas
]]

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdom = function(character)
	local equipmentWisdom = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item = character.Stats:GetItemBySlot(j)
		if item then
			equipmentWisdom = equipmentWisdom + tonumber(item.VP_WisdomBoost)
		end
	end
	local statusesWisdom = 0
	for i,j in pairs(character:GetStatuses()) do
		if NRD_StatExists(j) then
			local statsId = Ext.Stats.Get(j).StatsId
			if statsId ~= "" then
				statusesWisdom = statusesWisdom + tonumber(Ext.Stats.Get(statsId).VP_WisdomBoost)
			end
		end
	end
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint + equipmentWisdom + statusesWisdom) / 100 + 1
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdomArmor = function(character)
	local equipmentWisdom = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item = character.Stats:GetItemBySlot(j)
		if item then
			equipmentWisdom = equipmentWisdom + tonumber(item.VP_ArmorRegenBoost)
		end
	end
	local statusesWisdom = 0
	for i,j in pairs(character:GetStatuses()) do
		if NRD_StatExists(j) then
			local statsId = Ext.Stats.Get(j).StatsId
			if statsId ~= "" then
				statusesWisdom = statusesWisdom + tonumber(Ext.Stats.Get(statsId).VP_ArmorRegenBoost)
			end
		end
	end
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint + equipmentWisdom + statusesWisdom) / 100 + 1
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdomMagicArmor = function(character)
	local equipmentWisdom = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item = character.Stats:GetItemBySlot(j)
		if item then
			equipmentWisdom = equipmentWisdom + tonumber(item.VP_MagicArmorRegenBoost)
		end
	end
	local statusesWisdom = 0
	for i,j in pairs(character:GetStatuses()) do
		if NRD_StatExists(j) then
			local statsId = Ext.Stats.Get(j).StatsId
			if statsId ~= "" then
				statusesWisdom = statusesWisdom + tonumber(Ext.Stats.Get(statsId).VP_MagicArmorRegenBoost)
			end
		end
	end
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint + equipmentWisdom + statusesWisdom) / 100 + 1
end

Data.Stats.HealType = {
    Vitality = Data.Math.ComputeCharacterWisdom,
    PhysicalArmor = Data.Math.ComputeCharacterWisdomArmor,
    MagicArmor = Data.Math.ComputeCharacterWisdomMagicArmor
}

--- @param character EsvCharacter | EclCharacter
Data.Math.ComputeCharacterIngress = function(character)
    local ingressFromAttributes = math.min((character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceIngressBonus, (character.Stats.Strength - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthIngressCap)
    local ingressFromHuntsman = character.Stats.RangerLore * Ext.ExtraData.DGM_RangerLoreIngressBonus
    local ingressFromEquipment = 0 --TODO: Equipment Ingress stat and deltamods
    return ingressFromAttributes + ingressFromHuntsman + ingressFromEquipment
end

--[[
    Heal related formulas
]]

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

--[[
    Damage related formulas
]]

---@param target EsvCharacter|EclCharacter
---@param instigator EsvCharacter|EclCharacter
Data.Math.ApplyCQBPenalty = function(target, instigator)
	local globalMultiplierBonus = 0
	local weaponTypes = {instigator.Stats.MainWeapon.WeaponType, instigator.Stats.OffHandWeapon and instigator.Stats.OffHandWeapon.WeaponType or nil}
	if weaponTypes[1] == "Bow" or weaponTypes[1] == "Crossbow" or weaponTypes[1] == "Rifle" or weaponTypes[1] == "Wand" then
		local distance = Ext.Math.Distance(target.WorldPos, instigator.WorldPos)
		--Ext.Print("[LXDGM_DamageControl.DamageControl] Distance :",distance)
		if distance <= Ext.ExtraData.DGM_RangedCQBPenaltyRange and instigator.Stats.TALENT_RangerLoreArrowRecover then
			globalMultiplierBonus = (Ext.ExtraData.DGM_RangedCQBPenalty/100)
		end
	end
	return globalMultiplierBonus
end

---@param character EsvCharacter|EclCharacter
---@param target EsvCharacter|EclCharacter
---@param flags HitFlags
---@param skill StatEntrySkillData|nil
Data.Math.GetCharacterComputedDamageBonus = function(character, target, flags, skill)
    local strength = character.Stats.Strength - Ext.ExtraData.AttributeBaseValue
    local finesse = character.Stats.Finesse - Ext.ExtraData.AttributeBaseValue
    local intelligence = character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue
	local attributes = {
        Strength = strength,
        Finesse = finesse,
        Intelligence = intelligence,
		Wits = character.Stats.Wits - Ext.ExtraData.AttributeBaseValue,
        DamageBonus = strength*Ext.ExtraData.DGM_StrengthGlobalBonus+finesse*Ext.ExtraData.DGM_FinesseGlobalBonus+intelligence*Ext.ExtraData.DGM_IntelligenceGlobalBonus, -- /!\ Remember that 1=1% in this variable
        GlobalMultiplier = 1.0
    }
	if flags.Backstab then
        attributes.DamageBonus = attributes.DamageBonus + character.Stats.CriticalChance * Ext.ExtraData.DGM_BackstabCritChanceBonus
    end
	-- Weapon Boost
	if flags.IsWeaponAttack or (skill and skill.Name == "Target_TentacleLash") then
		if (flags.DamageSourceType == "Offhand" and character.Stats.OffHandWeapon.WeaponType == "Wand") or character.Stats.MainWeapon.WeaponType == "Wand" then
			attributes.DamageBonus = attributes.DamageBonus + attributes.Intelligence * Ext.ExtraData.DGM_IntelligenceSkillBonus
		else
			attributes.DamageBonus = attributes.DamageBonus + attributes.Strength * Ext.ExtraData.DGM_StrengthWeaponBonus
		end
		attributes.GlobalMultiplier = attributes.GlobalMultiplier + Data.Math.ApplyCQBPenalty(target, character)
	-- DoT Boost
	elseif flags.IsStatusDamage then
		attributes.DamageBonus = attributes.Wits * Ext.ExtraData.DGM_WitsDotBonus
	end
	-- Intelligence Boost
	if skill then 
		attributes.DamageBonus = attributes.DamageBonus + attributes.Intelligence * Ext.ExtraData.DGM_IntelligenceSkillBonus
		if string.find(skill.Name, "Grenade") and character.Stats.TALENT_WarriorLoreGrenadeRange then
			attributes.DamageBonus = attributes.DamageBonus + Ext.ExtraData.DGM_SlingshotBonus
		end
	end
    return attributes
end