Data.Math = {}

--[[
    Character stats related formulas
]]

---@param character EclCharacter|EsvCharacter
---@return number
Data.Math.ComputeStatIntegerFromEquipment = function(character, statName)
	local equipmentAttribute = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item
		if getmetatable(character) == "esv::Character" then
			local guid = CharacterGetEquippedItem(character.MyGuid, j)
			if guid then
				item = Ext.ServerEntity.GetItem(CharacterGetEquippedItem(character.MyGuid, j))
			end
		else
			item = character:GetItemObjectBySlot(j)
		end
		if item then
			for i, dynamicStat in pairs(item.Stats.DynamicStats) do
				if dynamicStat.ObjectInstanceName ~= "" then
					equipmentAttribute = equipmentAttribute + Ext.Stats.Get(dynamicStat.ObjectInstanceName)[statName]
				end
			end
			-- equipmentAttribute = equipmentAttribute + tonumber(item[statName])
		end
	end
	return equipmentAttribute
end

Data.Math.ComputeStatIntegerFromStatus = function(character, statName)
	local statusesAttribute = {}
	for i,j in pairs(character:GetStatuses()) do
		local stat = Ext.Stats.Get(j, nil, false)
		local status = character:GetStatus(j)
		if stat then
			local statsId = stat.StatsId
			if statsId ~= "" then
				table.insert(statusesAttribute, {
					Status = stat.StatsId,
					Value = tonumber(Ext.Stats.Get(statsId)[statName]) * status.StatsMultiplier,
					Type = statName
				})
			end
		end
	end
	return statusesAttribute
end

---@param character EclCharacter|EsvCharacter
---@return number
Data.Math.ComputeCharacterWisdomFromEquipment = function(character)
	local equipmentWisdom = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item
		if getmetatable(character) == "esv::Character" then
			item = Ext.ServerEntity.GetItem(CharacterGetEquippedItem(character.MyGuid, j))
		else
			item = character:GetItemObjectBySlot(j)
		end
		if item then
			for i, dynamicStat in pairs(item.Stats.DynamicStats) do
				if dynamicStat.ObjectInstanceName ~= "" then
					equipmentWisdom = equipmentWisdom + Ext.Stats.Get(dynamicStat.ObjectInstanceName).VP_WisdomBoost
				end
			end
			equipmentWisdom = equipmentWisdom + tonumber(item.VP_WisdomBoost)
		end
	end
	return equipmentWisdom
end

Data.Math.ComputeCharacterWisdomFromStatuses = function(character)
	local statusesWisdom = {}
	for i,j in pairs(character:GetStatuses()) do
		local stat = Ext.Stats.Get(j, nil, false)
		if stat then
			local statsId = stat.StatsId
			if statsId ~= "" then
				table.insert(statusesWisdom, {
					Status = stat.StatsId,
					Value = tonumber(Ext.Stats.Get(statsId).VP_WisdomBoost),
					Type = "VP_WisdomBoost"
				})
			end
		end
	end
	return statusesWisdom
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdom = function(character)
	local equipmentWisdom = Data.Math.ComputeCharacterWisdomFromEquipment(character)
	local statusesInfo = Data.Math.ComputeCharacterWisdomFromStatuses(character)
	local statusesWisdom = 0
	for i,statusInfo in pairs(statusesInfo) do
		statusesWisdom = statusesWisdom + statusInfo.Value
	end
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint + equipmentWisdom + statusesWisdom) / 100 + 1
end

Data.Math.ComputeCharacterWisdomArmorFromEquipment = function(character)
	local equipmentWisdom = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item = character.Stats:GetItemBySlot(j)
		if item then
			equipmentWisdom = equipmentWisdom + tonumber(item.VP_ArmorRegenBoost)
		end
	end
	return equipmentWisdom
end

Data.Math.ComputeCharacterWisdomArmorFromStatuses = function(character)
	local statusesWisdom = {}
	for i,j in pairs(character:GetStatuses()) do
		local stat = Ext.Stats.Get(j, nil, false)
		if stat then
			local statsId = stat.StatsId
			if statsId ~= "" then
				table.insert(statusesWisdom, {
					Status = stat.StatsId,
					Value = tonumber(Ext.Stats.Get(statsId).VP_ArmorRegenBoost),
					Type = "VP_ArmorRegenBoost"
				})
			end
		end
	end
	return statusesWisdom
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdomArmor = function(character)
	local equipmentWisdom = Data.Math.ComputeCharacterWisdomArmorFromEquipment(character)
	local statusesInfo = Data.Math.ComputeCharacterWisdomArmorFromStatuses(character)
	local statusesWisdom = 0
	for i,statusInfo in pairs(statusesInfo) do
		statusesWisdom = statusesWisdom + statusInfo.Value
	end
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint + equipmentWisdom + statusesWisdom) / 100 + 1
end

Data.Math.ComputeCharacterWisdomMagicArmorFromEquipment = function(character)
	local equipmentWisdom = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item = character.Stats:GetItemBySlot(j)
		if item then
			equipmentWisdom = equipmentWisdom + tonumber(item.VP_MagicArmorRegenBoost)
		end
	end
	return equipmentWisdom
end

Data.Math.ComputeCharacterWisdomMagicArmorFromStatuses = function(character)
	local statusesWisdom = {}
	for i,j in pairs(character:GetStatuses()) do
		local stat = Ext.Stats.Get(j, nil, false)
		if stat then
			local statsId = stat.StatsId
			if statsId ~= "" then
				table.insert(statusesWisdom, {
					Status = stat.StatsId,
					Value = tonumber(Ext.Stats.Get(statsId).VP_MagicArmorRegenBoost),
					Type = "VP_MagicArmorRegenBoost"
				})
			end
		end
	end
	return statusesWisdom
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdomMagicArmor = function(character)
	local equipmentWisdom = Data.Math.ComputeCharacterWisdomMagicArmorFromEquipment(character)
	local statusesInfo = Data.Math.ComputeCharacterWisdomMagicArmorFromStatuses(character)
	local statusesWisdom = 0
	for i,statusInfo in pairs(statusesInfo) do
		statusesWisdom = statusesWisdom + statusInfo.Value
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

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterCelerity = function(character)
	local equipmentCelerity = Data.Math.ComputeStatIntegerFromEquipment(character, "VP_Celerity")
	local statusesInfo = Data.Math.ComputeStatIntegerFromStatus(character, "VP_Celerity")
	local statusesCelerity = 0
	for i,statusInfo in pairs(statusesInfo) do
		statusesCelerity = statusesCelerity + statusInfo.Value
	end
    return math.min(equipmentCelerity + statusesCelerity)
end

--[[
    Heal related formulas
]]

---@alias PotionHealQualifier "Vitality"|"Armor"|"MagicArmor"

--- @param stat StatEntryType|string
--- @param healer EsvCharacter|EclCharacter
--- @param field PotionHealQualifier|nil
Data.Math.GetHealScaledValue = function(stat, healer, field)
	if type(stat) == "string" then
		stat = Ext.Stats.Get(stat)
	end
    local HealTypeSkillData = healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint
	local entryType = Helpers.Stats.GetEntryType(stat)
	-- When the status type is HEALING, the initial value is copied over to the next HEAL ticks and automatically apply the Hydro/Geo bonus
	if entryType == "StatusData" and stat.StatusType == "HEALING" then
		HealTypeSkillData = 0
	elseif (entryType == "StatusData" and stat.HealStat == "PhysicalArmor") or (entryType == "Potion" and field == "Armor") then
		HealTypeSkillData = healer.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint
	elseif (entryType == "StatusData" and stat.HealStat == "MagicArmor") or (entryType == "Potion" and field == "MagicArmor") then
		HealTypeSkillData = healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint
	end
	return Ext.Utils.Round((entryType == "StatusData" and stat.HealValue or stat[field]) * Game.Math.GetAverageLevelDamage(healer.Stats.Level) * Ext.ExtraData.HealToDamageRatio / 100 * (1 + HealTypeSkillData/100))
end

--- @param stat StatEntryType
--- @param healer EsvCharacter|EclCharacter
Data.Math.GetHealValue = function(stat, healer)
	return Ext.Utils.Round(stat.HealValue * Game.Math.GetAverageLevelDamage(healer.Stats.Level) * Ext.ExtraData.HealToDamageRatio / 100)
end

--- @param stat StatEntryType
--- @param healer EsvCharacter|EclCharacter
Data.Math.GetHealScaledWisdomValue = function(stat, healer)
	local bonus = Data.Stats.HealType[stat.HealStat](healer)
	local hydrosophistBonus = math.max(1, 1 + (healer.Stats.WaterSpecialist*Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint/100))
    return Ext.Utils.Round(Ext.Utils.Round(Data.Math.GetHealValue(stat, healer) * bonus / hydrosophistBonus)*hydrosophistBonus)
end

--[[
	Armor
]]

---@param level number
Data.Math.GetArmorScaledValue = function(level)
	return Game.Math.GetVitalityBoostByLevel(level) * ((level * Ext.ExtraData.ExpectedConGrowthForArmorCalculation) * Ext.ExtraData.VitalityBoostFromAttribute + 1.0) * Ext.ExtraData.ArmorToVitalityRatio
end

---@param level number
---@param healer EsvCharacter|EclCharacter
---@param armorType PotionHealQualifier
---@param potion StatEntryPotion
Data.Math.GetArmorRegenScaledValue = function(level, healer, armorType, potion)
	local multiplier = 1
	if armorType == "Armor" then
		multiplier = 1 + (healer.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint)/100
	else
		multiplier = 1 + (healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint)/100
	end
	return Ext.Utils.Round(Data.Math.GetArmorScaledValue(level) * potion[armorType] / 100) * multiplier
end

--[[
    Damage related formulas
]]

---@param target EsvCharacter|EclCharacter
---@param instigator EsvCharacter|EclCharacter
Data.Math.ApplyCQBPenalty = function(target, instigator)
	if not target or not instigator then return 0 end
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
	if not character or getmetatable(character) ~= "esv::Character" and getmetatable(character) ~= "ecl::Character" then return {
		Strength = 0,
		Finesse = 0,
		Intelligence = 0,
		Wits = 0,
		DamageBonus = 0,
		GlobalMultiplier = 1.0
	} end
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
	if flags.IsWeaponAttack or (skill and (skill.Name == "Target_TentacleLash" or skill.UseWeaponDamage == "Yes")) then
		if (flags.DamageSourceType == "Offhand" and character.Stats.OffHandWeapon.WeaponType == "Wand") or character.Stats.MainWeapon.WeaponType == "Wand" then
			attributes.DamageBonus = attributes.DamageBonus + attributes.Intelligence * Ext.ExtraData.DGM_IntelligenceSkillBonus
		else
			attributes.DamageBonus = attributes.DamageBonus + attributes.Strength * Ext.ExtraData.DGM_StrengthWeaponBonus
		end
		-- Weapon ability boost (no DW)
		if flags.DamageSourceType ~= "Offhand" and character.Stats.MainWeapon ~= null then
			local weaponAbility = Game.Math.GetWeaponAbility(character.Stats, character.Stats.MainWeapon)
			attributes.DamageBonus = attributes.DamageBonus * (1 + character.Stats[weaponAbility] * Data.Stats.WeaponAbilitiesBonuses[weaponAbility] / 100)
		end
		attributes.GlobalMultiplier = attributes.GlobalMultiplier + Data.Math.ApplyCQBPenalty(target, character)
	-- DoT Boost
	elseif flags.IsStatusDamage then
		attributes.DamageBonus = attributes.Wits * Ext.ExtraData.DGM_WitsDotBonus
	end
	-- Intelligence Boost
	if skill and skill.Name ~= "Target_LX_NormalAttack" then 
		attributes.DamageBonus = attributes.DamageBonus + attributes.Intelligence * Ext.ExtraData.DGM_IntelligenceSkillBonus
		if string.find(skill.Name, "Grenade") and character.Stats.TALENT_WarriorLoreGrenadeRange then
			attributes.DamageBonus = attributes.DamageBonus + Ext.ExtraData.DGM_SlingshotBonus
		end
	end
    return attributes
end

---Get the amount of damage that will be absorbed by physical armor
---@param character EsvCharacter | EclCharacter
Data.Math.CharacterGetEffectivePhysicalArmor = function(character)
	return character.Stats.CurrentArmor * (Ext.ExtraData.DGM_DamageThroughArmor + (character.Stats.CurrentMagicArmor > 0 and Ext.ExtraData.DGM_DamageThroughArmorDepleted or 0) /100)
end

---Get the amount of damage that will be absorbed by magic armor
---@param character EsvCharacter | EclCharacter
Data.Math.CharacterGetEffectiveMagicArmor = function(character)
	return character.Stats.CurrentMagicArmor * (Ext.ExtraData.DGM_DamageThroughArmor + (character.Stats.CurrentArmor > 0 and Ext.ExtraData.DGM_DamageThroughArmorDepleted or 0) /100)
end

---@param character EsvCharacter | EclCharacter
Data.Math.GetCharacterWeaponAbilityPoints = function(character)
	local ability = Game.Math.GetWeaponAbility(character.Stats, character.Stats.MainWeapon)
	if ability then
		return character.Stats[ability]
	else
		return 0
	end
end

---@param character EsvCharacter | EclCharacter
Data.Math.GetCharacterWeaponAbilityBonus = function(character)
	local ability = Game.Math.GetWeaponAbility(character.Stats, character.Stats.MainWeapon)
	if ability then
		return character.Stats[ability] * Data.Stats.WeaponAbilitiesBonuses[ability]
	else
		return 0
	end
end

--- @param character EsvCharacter
Data.Math.GetCharacterMovement = function(character)
    local stats = character.Stats.DynamicStats
	local movementFromEquipment = Data.Math.ComputeStatIntegerFromEquipment(character, "Movement")
	local movementFromStatuses = Data.Math.ComputeStatIntegerFromStatus(character, "Movement")
	local movement = stats[1].Movement + movementFromEquipment + character.Stats.RogueLore * Ext.ExtraData.SkillAbilityMovementSpeedPerPoint
	for i,statusInfo in pairs(movementFromStatuses) do
		movement = movement + statusInfo.Value
	end
    return {
        Movement = movement,
        BaseMovement = stats[1].Movement
    }
end

---@param distance integer Distance in centimeters
---@param character EsvCharacter|EclCharacter
---@return unknown
Data.Math.ComputeCelerityValue = function(distance, character)
	local movement = Data.Math.GetCharacterMovement(character)
	if movement.Movement > 0 then
		return distance/movement.Movement
	else
		return 0
	end
end
