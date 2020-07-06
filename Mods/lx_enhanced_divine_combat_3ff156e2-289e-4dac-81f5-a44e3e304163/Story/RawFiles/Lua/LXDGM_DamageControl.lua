function DamageControl(target, handle, instigator)
	--[[
		Main damage control : damages are teared down to the original formula and apply custom
		bonuses from the overhaul
	]]--
	if ObjectIsCharacter(instigator) == 0 then return end
	-- Get hit properties
	local damages = {}
	local types = DamageTypeEnum()
	local isCrit = NRD_StatusGetInt(target, handle, "CriticalHit")
	-- print("Crit: "..isCrit)
	local isDodged = NRD_StatusGetInt(target, handle, "Dodged")
	-- print("Dodged: "..isDodged)
	local isBlocked = NRD_StatusGetInt(target, handle, "Blocked")
	-- print("Blocked: "..isBlocked)
	local isMissed = NRD_StatusGetInt(target, handle, "Missed")
	-- print("Missed: "..isMissed)
	local fromWeapon = NRD_StatusGetInt(target, handle, "HitWithWeapon")
	-- print("Hit with weapon: "..fromWeapon)
	local fromReflection = NRD_StatusGetInt(target, handle, "Reflection")
	-- print("Hit from reflection: "..fromReflection)
	local hitType = NRD_StatusGetInt(target, handle, "DoT")
	--print("HitType: "..hitType)
	local sourceType = NRD_StatusGetInt(target, handle, "DamageSourceType")
	local skillID = NRD_StatusGetString(target, handle, "SkillId")
	local backstab = NRD_StatusGetInt(target, handle, "Backstab")
	local fixedValue = 0
	-- print("SkillID: "..skillID)
	if NRD_StatusGetInt(target, handle, "HitReason") == 0 then
		fromWeapon = 1
	elseif skillID ~= "" then
		fromWeapon = NRD_StatGetInt(string.gsub(skillID, "%_%-1", ""), "UseWeaponDamage")
		fixedValue = NRD_StatGetInt(string.gsub(skillID, "%_%-1", ""), "Damage")
	end
	
	local weaponTypes = GetWeaponsType(instigator)
	
	-- Get hit damages
	for i,dmgType in pairs(types) do
		damages[dmgType] = NRD_HitStatusGetDamage(target, handle, dmgType)
		if damages[dmgType] ~= 0 then print("Damage "..dmgType..": "..damages[dmgType]) end
	end
	
	if isBlocked == 1 then return end
	if sourceType == 1 or sourceType == 2 or sourceType == 3 then InitiatePassingDamage(target, damages); return end
	if skillID == "" and sourceType == 0 then InitiatePassingDamage(target, damages); return end
	if fixedValue ~= 0 and fixedValue ~= 1 and fixedValue ~= 2 then InitiatePassingDamage(target, damages); return end
	
	-- Dodge mechanic override
	if isMissed == 1 or isDodged == 1 then
		local weaponHandle = NRD_StatusGetString(target, handle, "WeaponHandle")
		local mainWeapon = CharacterGetEquippedWeapon(instigator)
		DodgeControl(target, instigator, weaponHandle)
		if mainWeapon ~= weaponHandle then
			SetVarInteger(instigator, "LX_Miss_Main", 0)
		end
		return
	end
		
	-- Get instigator bonuses
	local strength = CharacterGetAttribute(instigator, "Strength") - 10
	local finesse = CharacterGetAttribute(instigator, "Finesse") - 10
	local intelligence = CharacterGetAttribute(instigator, "Intelligence") - 10
	local damageBonus = strength*Ext.ExtraData.DGM_StrengthGlobalBonus+finesse*Ext.ExtraData.DGM_FinesseGlobalBonus+intelligence*Ext.ExtraData.DGM_IntelligenceGlobalBonus -- /!\ Remember that 1=1% in this variable
	local globalMultiplier = 1.0
	
	if backstab == 1 then
		local criticalHit = NRD_CharacterGetComputedStat(instigator, "CriticalChance", 0)
		damageBonus = damageBonus + criticalHit * Ext.ExtraData.DGM_BackstabCritChanceBonus

	end
	
	-- Get damage type bonus
	if fromWeapon == 1 then 
		damageBonus = damageBonus + strength*Ext.ExtraData.DGM_StrengthWeaponBonus
		-- print("Bonus: Weapon")
		-- Check distance penalty if it's a distance weapon
		if weaponTypes[1] == "Bow" or weaponTypes[1] == "Crossbow" or weaponTypes[1] == "Rifle" or weaponTypes[1] == "Wand" then
			local distance = GetDistanceTo(target, instigator)
			--Ext.Print("[LXDGM_DamageControl.DamageControl] Distance :",distance)
			if distance <= 2.0 and CharacterHasTalent(instigator, "RangerLoreArrowRecover") == 0 then
				globalMultiplier = globalMultiplier - (Ext.ExtraData.DGM_RangedCQBPenalty/100)
			end
		end
		if sourceType == 7 then
			local dualWielding = CharacterGetAbility(instigator, "DualWielding")
			damageBonus = damageBonus + dualWielding*Ext.ExtraData.DGM_DualWieldingOffhandBonus
		end
		
	end
	if hitType == 1 then
		damageBonus = strength*Ext.ExtraData.DGM_StrengthDoTBonus
		-- print("Bonus: DoT") 
		-- Demon bonus for burning/necrofire
		local hasDemon = CharacterHasTalent(instigator, "Demon")
		if hasDemon == 1 then
			local statusID = NRD_StatusGetString(target, handle, "StatusId")
			if statusID == "BURNING" or statusID == "NECROFIRE" then
				-- print("Bonus: Demon")
				damageBonus = damageBonus + Ext.ExtraData.DGM_DemonStatusesBonus
			end
		end
	end
	if skillID ~= "" then 
		damageBonus = damageBonus + intelligence*Ext.ExtraData.DGM_IntelligenceSkillBonus
		-- print("Bonus: skill")
		-- Apply bonus from wand and staves
		if weaponTypes[1] == "Wand" then
			if weaponTypes[2] == "Wand" then
				globalMultiplier = globalMultiplier + Ext.ExtraData.DGM_WandSkillMultiplier/100
			else
				globalMultiplier = globalMultiplier + Ext.ExtraData.DGM_WandSkillMultiplier/100*2
			end
		elseif weaponTypes[1] == "Staff" then
			globalMultiplier = globalMultiplier + Ext.ExtraData.DGM_StaffSkillMultiplier/100
		end
		-- Apply Slingshot bonus if it's a grenade
		local isGrenade = string.find(skillID, "Grenade")
		local hasSlingshot = CharacterHasTalent(instigator, "WarriorLoreGrenadeRange")
		if isGrenade ~= nil and hasSlingshot == 1 then
			damageBonus = damageBonus + Ext.ExtraData.DGM_SlingshotBonus
		end
	end
	
	-- Apply damage changes and side effects
	damages = ChangeDamage(damages, (damageBonus/100+1)*globalMultiplier, 0, instigator)
	ReplaceDamages(damages, handle, target)
	SetWalkItOff(target, handle)
	
	-- Armor passing damages
	InitiatePassingDamage(target, damages)
end

function InitiatePassingDamage(target, damages)
	for dmgType,amount  in pairs(damages) do
		if amount ~= 0 then
			local piercing = CalculatePassingDamage(target, amount, dmgType)
			ApplyPassingDamage(target, piercing)
		end
	end
end

function ChangeDamage(damages, multiplier, value, instigator)
	for dmgType,amount in pairs(damages) do
		-- Ice king water damage bonus
		if dmgType == "Water" and CharacterHasTalent(instigator, "IceKing") == 1 then
			multiplier = multiplier + Ext.ExtraData.DGM_IceKingDamageBonus/100
			-- print("Bonus: IceKing")
		end
		amount = amount * multiplier
		amount = amount + value
		if amount ~= 0 then print("Changed "..dmgType.." to "..amount.." (Multiplier = "..multiplier..")") end
		damages[dmgType] = amount
	end
	return damages
end

function ReplaceDamages(newDamages, handle, target)
	NRD_HitStatusClearAllDamage(target, handle)
	for dmgType,amount in pairs(newDamages) do
		NRD_HitStatusAddDamage(target, handle, dmgType, amount)
	end
end

function HasHarmfulAccuracyStatus(character)
	NRD_IterateCharacterStatuses(character, "LX_Iterate_Statuses_Accuracy")
	local isHarmed = GetVarInteger(character, "LX_Accuracy_Harmed")
	if isHarmed == 1 then return true end
	return false
end

function DodgeControl(target, instigator, weapon)
	if weapon == nil then weapon = "" end
	local refunded = GetVarInteger(instigator, "LX_Miss_Refunded")
	if CharacterGetEquippedWeapon(instigator) == weapon then 
		if refunded == 1 then 
			SetVarInteger(instigator, "LX_Miss_Refunded", 0)
		else
			CharacterAddActionPoints(instigator, 1)
			SetVarInteger(instigator, "LX_Miss_Refunded", 1)
		end
		SetVarInteger(instigator, "LX_Miss_Main", 1)
		TriggerDodgeFatigue(target, instigator)	
	else
		local hasMissedMain = GetVarInteger(instigator, "LX_Miss_Main")
		if hasMissedMain ~= 1 then
			TriggerDodgeFatigue(target, instigator)
			if refunded == 1 then 
				SetVarInteger(instigator, "LX_Miss_Refunded", 0)
			else
				CharacterAddActionPoints(instigator, 1)
				SetVarInteger(instigator, "LX_Miss_Refunded", 1)
			end
		end
	end
	return
end

function TriggerDodgeFatigue(target, instigator)
	if CharacterIsInCombat(target) == 0 then return end
	local accuracy = NRD_CharacterGetComputedStat(instigator, "Accuracy", 0)
	local baseAccuracy = NRD_CharacterGetComputedStat(instigator, "Accuracy", 1)
	local dodgeCounter = GetVarInteger(target, "LX_Dodge_Counter")
	local dodge = NRD_CharacterGetComputedStat(target, "Dodge", 0)
	--local isHarmed = HasHarmfulAccuracyStatus(instigator)
	if dodgeCounter == nil then dodgeCounter = 0 end
	-- Ext.Print("[LXDGM_DamageControl.DodgeControl] "..accuracy.." "..baseAccuracy)
	-- Ext.Print("[LXDGM_DamageControl.DodgeControl] Dodge counter : "..dodgeCounter)
	if HasActiveStatus(target, "UNCANNY_EVASION") == 0 then
		dodgeCounter = dodgeCounter + 1
	end
	if accuracy >= 90 and accuracy >= baseAccuracy then
		SetVarInteger(target, "LX_Dodge_Counter", dodgeCounter)
		if CharacterHasTalent(target, "DualWieldingDodging") == 1 then dodgeCounter = dodgeCounter - 1 end
		if dodgeCounter == 1 then ApplyStatus(target, "LX_DODGE_FATIGUE1", 6.0, 1) end
		if dodgeCounter == 2 then ApplyStatus(target, "LX_DODGE_FATIGUE2", 6.0, 1) end
		if dodgeCounter == 3 then ApplyStatus(target, "LX_DODGE_FATIGUE3", 6.0, 1) end
		if dodgeCounter == 4 then ApplyStatus(target, "LX_DODGE_FATIGUE4", 6.0, 1) end
		
		
	end
end

function ManagePerseverance(character, perseverance, type)
	-- Ext.Print(perseverance)
	local charHP = NRD_CharacterGetStatInt(character, "MaxVitality")
	NRD_CharacterSetStatInt(character, "CurrentVitality", NRD_CharacterGetStatInt(character, "CurrentVitality")+(perseverance*Ext.ExtraData.DGM_PerseveranceVitalityRecovery*0.01*charHP))
	if type == "Magic" then
		local charMA = NRD_CharacterGetStatInt(character, "MaxMagicArmor")
		NRD_CharacterSetStatInt(character, "CurrentMagicArmor", NRD_CharacterGetStatInt(character, "CurrentMagicArmor")+(perseverance*Ext.ExtraData.SkillAbilityArmorRestoredPerPoint*0.01*charMA))
	elseif type == "Physical" then
		local charPA = NRD_CharacterGetStatInt(character, "MaxArmor")
		NRD_CharacterSetStatInt(character, "CurrentArmor", NRD_CharacterGetStatInt(character, "CurrentArmor")+(perseverance*Ext.ExtraData.SkillAbilityArmorRestoredPerPoint*0.01*charPA))
	end
end

local function DGM_HitChanceFormula(attacker, target)
    local hitChance = attacker.Accuracy - target.Dodge
    -- Make sure that we return a value in the range (0% .. 100%)
    hitChance = math.max(math.min(hitChance, 100), 0)
    return hitChance
end

Ext.RegisterListener("GetHitChance", DGM_HitChanceFormula)