Data.Math = {}

--[[
    Character stats related formulas
]]

---@param character EclCharacter|EsvCharacter
---@return number
Data.Math.ComputeStatIntegerFromEquipment = function(character, statName)
	local equipmentAttribute = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item = character.Stats:GetItemBySlot(j)
		if item then
			for i, dynamicStat in pairs(item.DynamicStats) do
				if dynamicStat.ObjectInstanceName ~= "" then
					equipmentAttribute = equipmentAttribute + Ext.Stats.Get(dynamicStat.ObjectInstanceName)[statName]
				end
			end
			-- equipmentAttribute = equipmentAttribute + tonumber(item[statName])
		end
	end
	return equipmentAttribute
end

---@param character EsvCharacter|EclCharacter
---@param statName string
---@return table
---@return number
Data.Math.ComputeStatIntegerFromStatus = function(character, statName)
	local statusesAttribute = {}
	for i,j in pairs(character:GetStatuses()) do
		local stat = Ext.Stats.Get(j, nil, false)
		--- Note: some particular statuses does seems to create a warning (e.g. LINGERING_WOUNDS)
		local status = character:GetStatus(j)
		if stat then
			local statsId = stat.StatsId
			if statsId ~= "" then
				table.insert(statusesAttribute, {
					Status = stat.StatsId,
					Value = Ext.Utils.Round(tonumber(Ext.Stats.Get(statsId)[statName]) * status.StatsMultiplier),
					Type = statName
				})
			end
		end
	end
	local total = 0
	for i, info in pairs(statusesAttribute) do
		total = total + info.Value
	end
	return statusesAttribute, total
end

---@param character EclCharacter|EsvCharacter
---@return number
Data.Math.ComputeCharacterWisdomFromEquipment = function(character)
	local equipmentWisdom = 0
	for i,j in pairs(Helpers.EquipmentSlots) do
		local item
		if Ext.IsServer() then
			item = CharacterGetEquippedItem(character.MyGuid, j)
			if item then
				item = Ext.ServerEntity.GetItem(CharacterGetEquippedItem(character.MyGuid, j))
			end
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
	return Data.Math.ComputeStatIntegerFromStatus(character, "VP_WisdomBoost")
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdom = function(character)
	local equipmentWisdom = Data.Math.ComputeCharacterWisdomFromEquipment(character)
	local statusesInfo, _ = Data.Math.ComputeStatIntegerFromStatus(character, "VP_WisdomBoost")
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
	return Data.Math.ComputeStatIntegerFromStatus(character, "VP_ArmorRegenBoost")
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdomArmor = function(character)
	local equipmentWisdom = Data.Math.ComputeCharacterWisdomArmorFromEquipment(character)
	local statusesInfo,_ = Data.Math.ComputeStatIntegerFromStatus(character, "VP_ArmorRegenBoost")
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
	return Data.Math.ComputeStatIntegerFromStatus(character, "VP_MagicArmorRegenBoost")
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdomMagicArmor = function(character)
	local equipmentWisdom = Data.Math.ComputeCharacterWisdomMagicArmorFromEquipment(character)
	local statusesInfo,_ = Data.Math.ComputeStatIntegerFromStatus(character, "VP_MagicArmorRegenBoost")
	local statusesWisdom = 0
	for i,statusInfo in pairs(statusesInfo) do
		statusesWisdom = statusesWisdom + statusInfo.Value
	end
    return (math.min(
        (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
        (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus) +
        character.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint + equipmentWisdom + statusesWisdom) / 100 + 1
end

--- @param character EsvCharacter|EclCharacter
Data.Math.ComputeCharacterWisdomHighestArmor = function(character)
	return math.max(Data.Math.ComputeCharacterWisdomArmor(character), Data.Math.ComputeCharacterWisdomMagicArmor(character))
end

Data.Stats.HealType = {
    Vitality = Data.Math.ComputeCharacterWisdom,
    PhysicalArmor = Data.Math.ComputeCharacterWisdomArmor,
    MagicArmor = Data.Math.ComputeCharacterWisdomMagicArmor,
	AllArmor = Data.Math.ComputeCharacterWisdomHighestArmor
}

Data.Stats.HealAbilityBonus = {
	Vitality = function(healer) return math.max(1, 1 + (healer.Stats.WaterSpecialist*Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint/100)) end,
	PhysicalArmor = function(healer) return math.max(1, 1 + (healer.Stats.EarthSpecialist*Ext.ExtraData.SkillAbilityArmorRestoredPerPoint/100)) end,
	MagicArmor = function(healer) return math.max(1, 1 + (healer.Stats.WaterSpecialist*Ext.ExtraData.SkillAbilityArmorRestoredPerPoint/100)) end,
	AllArmor = function(healer) return math.max(math.max(1, 1 + (healer.Stats.EarthSpecialist*Ext.ExtraData.SkillAbilityArmorRestoredPerPoint/100)), math.max(1, 1 + (healer.Stats.WaterSpecialist*Ext.ExtraData.SkillAbilityArmorRestoredPerPoint/100))) end
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
	local wisdomBonus = Data.Stats.HealType[stat.HealStat](healer)
	-- Ability is Hydro if vitality/MA, otherwise Geo
	local abilityBonus = Data.Stats.HealAbilityBonus[stat.HealStat](healer)
    return Ext.Utils.Round(Ext.Utils.Round(Data.Math.GetHealValue(stat, healer) * wisdomBonus / abilityBonus)*abilityBonus)
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
	if skill and not (skill.Damage == "BaseLevelDamage" or skill.Damage == "AverageLevelDamge" or skill.Damage == "MonsterWeaponDamage") then attributes.DamageBonus = 0; return end
	-- Weapon Boost
	if flags.IsWeaponAttack or (skill and (skill.Name == "Target_TentacleLash" or skill.UseWeaponDamage == "Yes")) then
		if (flags.DamageSourceType == "Offhand" and character.Stats.OffHandWeapon.WeaponType == "Wand") or character.Stats.MainWeapon.WeaponType == "Wand" then
			attributes.DamageBonus = attributes.DamageBonus + attributes.Intelligence * Ext.ExtraData.DGM_IntelligenceSkillBonus
		else
			attributes.DamageBonus = attributes.DamageBonus + attributes.Strength * Ext.ExtraData.DGM_StrengthWeaponBonus
		end
		-- Weapon ability boost
		if character.Stats.MainWeapon ~= null then
			local weaponAbility = Game.Math.GetWeaponAbility(character.Stats, character.Stats.MainWeapon)
			attributes.DamageBonus = attributes.DamageBonus + (1 + character.Stats[weaponAbility] * Data.Stats.WeaponAbilitiesBonuses[weaponAbility])
		end
		attributes.GlobalMultiplier = attributes.GlobalMultiplier + Data.Math.ApplyCQBPenalty(target, character)
	-- DoT Boost
	elseif flags.IsStatusDamage then
		attributes.DamageBonus = attributes.Wits * Ext.ExtraData.DGM_WitsDotBonus
	end
	-- Intelligence Boost
	if skill and skill.Name ~= "Target_LX_NormalAttack" then
		if skill.UseWeaponDamage == "No" then
			attributes.DamageBonus = attributes.DamageBonus + attributes.Intelligence * Ext.ExtraData.DGM_IntelligenceSkillBonus
		end
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

---@param character EsvCharacter|EclCharacter
Data.Math.GetCharacterComputedAbilityBonus = function(character, ability)
	local abilityValue = character.Stats[ability]
	return (Data.Stats.AbilityToDataValue[ability] * abilityValue / 100)
end

---@param character StatCharacter
---@param damageType DamageType
Data.Math.GetDamageBoostByType = function(character, damageType)
	local ability = Data.DamageTypeToAbility[damageType]
	if ability then
		return (Data.Stats.AbilityToDataValue[ability] * character[ability] / 100)
	else
		return Ext.Stats.Math.GetDamageBoostByType(character, damageType) / 100.0
	end
end

Game.Math.GetDamageBoostByType = Data.Math.GetDamageBoostByType
Game.Math.GetDamageBoostByTypeVanilla = Data.Math.GetDamageBoostByType

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
		return math.max(distance/movement.Movement, 0)
	else
		return 0
	end
end

Data.Math.HitChance = {
	Listeners = {}
}

---Listen for accuracy calculations and apply potential modifiers
---@param name string
---@param handle function
Data.Math.HitChance.RegisterListener = function(name, handle)
	Data.Math.HitChance.Listeners[name] = handle
end

Data.Math.HitChance.RemoveListener = function(name)
	if not Data.Math.HitChance.Listeners[name] then
		_VWarning('Could not find listener "'..name..'" in HitChance listeners !', "_InitShared")
	end 
	Data.Math.HitChance.Listeners[name] = nil
end

Data.Math.HitChance.CallListeners = function(attacker, target, hitChance)
	for name, listener in pairs(Data.Math.HitChance.Listeners) do
		hitChance = listener(attacker, target, hitChance)
	end
	return hitChance
end

--- @param attacker StatCharacter
--- @param target StatCharacter
local function DGM_CalculateHitChance(attacker, target)
    if attacker.TALENT_Haymaker then
		local diff = 0
		if attacker.MainWeapon then
			diff = diff + math.max(0, (attacker.MainWeapon.Level - attacker.Level))
		end
		if attacker.OffHandWeapon then
			diff = diff + math.max(0, (attacker.OffHandWeapon.Level - attacker.Level))
		end
        return 100 - diff * Ext.ExtraData.WeaponAccuracyPenaltyPerLevel
	end
	
	local _, accuracyFromStatuses = Data.Math.ComputeStatIntegerFromStatus(attacker.Character, "AccuracyBoost")
	local accuracy
	if Ext.IsServer() then
		accuracy = attacker.Accuracy + Data.Math.ComputeStatIntegerFromEquipment(attacker.Character, "AccuracyBoost") + accuracyFromStatuses
	else
		accuracy = attacker.Accuracy
	end
	local dodge = target.Dodge
	if target.Character:GetStatus("KNOCKED_DOWN") and dodge > 0 then
		dodge = 0
	end

	local chanceToHit1 = accuracy - dodge
	chanceToHit1 = Data.Math.HitChance.CallListeners(attacker, target, chanceToHit1)
	-- chanceToHit1 = math.max(0, math.min(100, chanceToHit1))
    return math.max(chanceToHit1 + attacker.ChanceToHitBoost, 0)
end

Game.Math.CalculateHitChance = DGM_CalculateHitChance

--- @param e LuaGetHitChanceEvent
Ext.Events.GetHitChance:Subscribe(function(e)
	e.HitChance = DGM_CalculateHitChance(e.Attacker, e.Target)
end)

---@param character EsvCharacter
Data.Math.CharacterCalculatePartialAP = function(character)
	local movement = Data.Math.GetCharacterMovement(character)
	local celerity = Data.Math.ComputeCelerityValue(Data.Math.ComputeCharacterCelerity(character), character)
	return (character.Stats.TALENT_QuickStep and 1 or 0) + 100/movement.Movement + celerity
end

Data.Math.Character = {}

---comment
---@param character EsvCharacter|EclCharacter
---@param isWeapon boolean
---@param isMagic boolean
Data.Math.Character.GetExecutionRange = function(character, isWeapon, isMagic)
	local executeValue = 0
	for i, statusName in pairs(character:GetStatuses()) do
		local statEntry = Ext.Stats.Get(statusName, nil, false)
		if statEntry and statEntry.VP_ExecuteMultiplier ~= 0 then
			if isWeapon and statEntry.VP_ExecuteCondition == "Weapon" or isMagic and statEntry.VP_ExecuteCondition == "Magic" or statEntry.VP_ExecuteCondition == "" then
				if statEntry.VP_ExecuteScaling ~= "" then
					executeValue = executeValue + Data.DamageScalingFormulas[VP_ExecuteScaling](character.Stats.Level) * statEntry.VP_ExecuteMultiplier/100
				else
					executeValue = executeValue + statEntry.VP_ExecuteMultiplier/100 * character:GetStatus(statusName).StatsMultiplier
				end
			end
		end
	end
	return executeValue
end