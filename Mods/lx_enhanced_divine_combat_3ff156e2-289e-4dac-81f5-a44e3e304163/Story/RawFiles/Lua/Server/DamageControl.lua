---@param target EsvCharacter
local function TraceDamageSpreaders(target)
	local statuses = target:GetStatuses()
	for i,status in pairs(statuses) do
		if target:GetStatus(status).StatusType == "GUARDIAN_ANGEL" then
			local source = target:GetStatus(status).StatusSourceHandle
			if source ~= nil then
				SetTag(Ext.GetCharacter(source).MyGuid, "DGM_GuardianAngelProtector")
			end
		end
	end
end

---@param target EsvCharacter
---@param handle number
---@param instigator EsvCharacter
---@param status EsvStatusHit
---@param context HitContext
function DamageControl(target, instigator, hitDamage, handle)
-- function DamageControl(status, context)
	--[[
		Main damage control : damages are teared down to the original formula and apply custom
		bonuses from the overhaul
	]]--
	if ObjectIsCharacter(instigator) == 0 then return end
	-- Get hit properties
	local damages = {}
	local types = DamageTypeEnum()
	local isCrit = NRD_StatusGetInt(target, handle, "CriticalHit")
	local isDodged = NRD_StatusGetInt(target, handle, "Dodged")
	local isBlocked = NRD_StatusGetInt(target, handle, "Blocked")
	local isMissed = NRD_StatusGetInt(target, handle, "Missed")
	local fromWeapon = NRD_StatusGetInt(target, handle, "HitWithWeapon")
	local fromReflection = NRD_StatusGetInt(target, handle, "Reflection")
	local isDoT = NRD_StatusGetInt(target, handle, "DoT")
	local sourceType = NRD_StatusGetInt(target, handle, "DamageSourceType")
	local skillID = NRD_StatusGetString(target, handle, "SkillId")
	local backstab = NRD_StatusGetInt(target, handle, "Backstab")
	local fixedValue = 0
	local isFromShacklesOfPain = false

	if fromReflection == 1 then return end
	if NRD_StatusGetInt(target, handle, "HitReason") == 0 then
		fromWeapon = 1
	elseif skillID ~= "" then
		fromWeapon = NRD_StatGetInt(string.gsub(skillID, "%_%-1", ""), "UseWeaponDamage")
		fixedValue = NRD_StatGetInt(string.gsub(skillID, "%_%-1", ""), "Damage")
	elseif NRD_StatusGetInt(target, handle, "HitReason") == 1 and skillID == "" and isDoT == 0 
		and HasActiveStatus(target, "SHACKLES_OF_PAIN") == 1 and HasActiveStatus(instigator, "SHACKLES_OF_PAIN_CASTER") == 1 then
		isFromShacklesOfPain = true
		Ext.Print("Shackles of Pain hit!")
	end
	
	local weaponTypes = GetWeaponsType(instigator)
	-- local hitStatus = Ext.GetStatus(target, handle)
	
	-- Get hit damages
	for i,dmgType in pairs(types) do
		damages[dmgType] = NRD_HitStatusGetDamage(target, handle, dmgType)
		if damages[dmgType] ~= 0 then Ext.Print("Damage "..dmgType..": "..damages[dmgType]) end
	end
	
	if isBlocked == 1 then return end
	if sourceType == 1 or sourceType == 2 or sourceType == 3 then InitiatePassingDamage(target, damages); return end
	if skillID == "" and sourceType == 0 and ObjectIsCharacter(target) == 1 then InitiatePassingDamage(target, damages); return end
	if fixedValue ~= 0 and fixedValue ~= 1 and fixedValue ~= 2 then InitiatePassingDamage(target, damages); return end
	
	if ObjectIsCharacter(target) == 1 then
		TraceDamageSpreaders(Ext.GetCharacter(target))
	end

	-- Dodge mechanic override
	if isMissed == 1 or isDodged == 1 then
		-- local weaponHandle = NRD_StatusGetString(target, handle, "WeaponHandle")
		-- local mainWeapon = CharacterGetEquippedWeapon(instigator)
		-- DodgeControl(target, instigator, weaponHandle)
		-- if mainWeapon ~= weaponHandle then
		-- 	SetVarInteger(instigator, "LX_Miss_Main", 0)
		-- end
		TriggerDodgeFatigue(target, instigator)
		return
	end
	
	-- Get instigator bonuses
	local strength = CharacterGetAttribute(instigator, "Strength") - Ext.ExtraData.AttributeBaseValue
	local finesse = CharacterGetAttribute(instigator, "Finesse") - Ext.ExtraData.AttributeBaseValue
	local intelligence = CharacterGetAttribute(instigator, "Intelligence") - Ext.ExtraData.AttributeBaseValue
	local wits = CharacterGetAttribute(instigator, "Wits") - Ext.ExtraData.AttributeBaseValue
	local damageBonus = strength*Ext.ExtraData.DGM_StrengthGlobalBonus+finesse*Ext.ExtraData.DGM_FinesseGlobalBonus+intelligence*Ext.ExtraData.DGM_IntelligenceGlobalBonus -- /!\ Remember that 1=1% in this variable
	local globalMultiplier = 1.0
	
	if backstab == 1 then
		local criticalHit = NRD_CharacterGetComputedStat(instigator, "CriticalChance", 0)
		damageBonus = damageBonus + criticalHit * Ext.ExtraData.DGM_BackstabCritChanceBonus
	end

	-- Get damage type bonus
	if fromWeapon == 1 or skillID == "Target_TentacleLash_-1" then 
		damageBonus = damageBonus + strength*Ext.ExtraData.DGM_StrengthWeaponBonus
		-- print("Bonus: Weapon")
		-- Check distance penalty if it's a distance weapon
		if weaponTypes[1] == "Bow" or weaponTypes[1] == "Crossbow" or weaponTypes[1] == "Rifle" or weaponTypes[1] == "Wand" then
			local distance = GetDistanceTo(target, instigator)
			--Ext.Print("[LXDGM_DamageControl.DamageControl] Distance :",distance)
			if distance <= Ext.ExtraData.DGM_RangedCQBPenaltyRange and CharacterHasTalent(instigator, "RangerLoreArrowRecover") == 0 then
				globalMultiplier = globalMultiplier - (Ext.ExtraData.DGM_RangedCQBPenalty/100)
			end
		end
		if sourceType == 7 then
			local dualWielding = CharacterGetAbility(instigator, "DualWielding")
			damageBonus = damageBonus + dualWielding*Ext.ExtraData.DGM_DualWieldingOffhandBonus
		end
		
	end
	if isDoT == 1 then
		damageBonus = wits*Ext.ExtraData.DGM_WitsDotBonus
		Ext.Print("Dot bonus",damageBonus)
		-- print("Bonus: DoT") 
		-- Demon bonus for burning/necrofire
		-- local hasDemon = CharacterHasTalent(instigator, "Demon")
		-- if hasDemon == 1 then
		-- 	local statusID = NRD_StatusGetString(target, handle, "StatusId")
		-- 	if statusID == "BURNING" or statusID == "NECROFIRE" then
		-- 		-- print("Bonus: Demon")
		-- 		damageBonus = damageBonus + Ext.ExtraData.DGM_DemonStatusesBonus
		-- 	end
		-- end
	end
	if skillID ~= "" then 
		damageBonus = damageBonus + intelligence*Ext.ExtraData.DGM_IntelligenceSkillBonus
		-- print("Bonus: skill")
		-- Apply bonus from wand and staves
		if weaponTypes[1] == "Wand" then
			if weaponTypes[2] == "Wand" then
				globalMultiplier = globalMultiplier + Ext.ExtraData.DGM_WandSkillMultiplier/100*2
			else
				globalMultiplier = globalMultiplier + Ext.ExtraData.DGM_WandSkillMultiplier/100
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
	if skillID == "Projectile_Talent_Unstable" or IsTagged(target, "DGM_GuardianAngelProtector") == 1 or isFromShacklesOfPain then 
		ClearTag(target, "DGM_GuardianAngelProtector")
		damageBonus = 0
		globalMultiplier = 1
	end
	damages = ChangeDamage(damages, (damageBonus/100+1)*globalMultiplier, 0, instigator, target, handle)
	ReplaceDamages(damages, handle, target)
	if ObjectIsCharacter(target) == 1 then SetWalkItOff(target, handle) end
	
	-- Armor passing damages
	if ObjectIsCharacter(target) == 1 then InitiatePassingDamage(target, damages) end
end

---@param target EsvCharacter
---@param damages table
function InitiatePassingDamage(target, damages)
	if ObjectIsCharacter(target) ~= 1 then return end
	for dmgType,amount  in pairs(damages) do
		if amount ~= 0 then
			local piercing = CalculatePassingDamage(target, amount, dmgType)
			ApplyPassingDamage(target, piercing)
		end
	end
end

---@param damages table
---@param multiplier number
---@param value number
---@param instigator EsvCharacter
function ChangeDamage(damages, multiplier, value, instigator, target, handle)
	local lifesteal = NRD_StatusGetInt(target, handle, "LifeSteal")
	instigator = Ext.GetCharacter(instigator)
	for dmgType,amount in pairs(damages) do
		-- Ice king water damage bonus
		if dmgType == "Water" and CharacterHasTalent(instigator.MyGuid, "IceKing") == 1 then
			multiplier = multiplier + Ext.ExtraData.DGM_IceKingDamageBonus/100
			-- print("Bonus: IceKing")
		end
		if dmgType == "Corrosive" or dmgType == "Magic" then
			multiplier = multiplier*(Ext.ExtraData.DGM_ArmourReductionMultiplier/100)
		end
		local rangeFix = math.random()
		if amount > 0 then amount = amount + rangeFix end
		if dmgType ~= "Corrosive" and dmgType ~= "Magic" then
			lifesteal = lifesteal - amount * (instigator.Stats.LifeSteal/100)
		end
		amount = amount * multiplier
		amount = amount + value
		if dmgType ~= "Corrosive" and dmgType ~= "Magic" then
			if lifesteal ~= 0 then
				lifesteal = lifesteal + Ext.Round(amount * (instigator.Stats.LifeSteal/100)) 
			end
		end
		if amount ~= 0 then Ext.Print("Changed "..dmgType.." to "..amount.." (Multiplier = "..multiplier..")") end
		damages[dmgType] = amount
	end
	if ObjectIsCharacter(target) ~= 1 then lifesteal = 0 end
	NRD_StatusSetInt(target, handle, "LifeSteal", lifesteal)
	return damages
end

---@param newDamages table
---@param handle number
---@param target EsvCharacter
function ReplaceDamages(newDamages, handle, target)
	NRD_HitStatusClearAllDamage(target, handle)
	for dmgType,amount in pairs(newDamages) do
		NRD_HitStatusAddDamage(target, handle, dmgType, amount)
	end
end

---@param character EsvCharacter
function HasHarmfulAccuracyStatus(character)
	NRD_IterateCharacterStatuses(character, "LX_Iterate_Statuses_Accuracy")
	local isHarmed = GetVarInteger(character, "LX_Accuracy_Harmed")
	if isHarmed == 1 then return true end
	return false
end

---@param target EsvCharacter
---@param instigator EsvCharacter
---@param weapon string
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

---@param target EsvCharacter
---@param instigator EsvCharacter
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
	if HasActiveStatus(target, "EVADING") == 0 then
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

---@param character EsvCharacter
---@param perseverance number
---@param type string
function ManagePerseverance(character, type)
	local perseverance = Ext.GetCharacter(character).Stats.Perseverance
	local charHP = NRD_CharacterGetStatInt(character, "MaxVitality")
	if type == "Normal" then
		NRD_CharacterSetStatInt(character, "CurrentVitality", NRD_CharacterGetStatInt(character, "CurrentVitality")+(perseverance*Ext.ExtraData.DGM_PerseveranceVitalityRecovery*0.01*charHP))
	elseif type == "Demi-Physic" then
		local charPA = NRD_CharacterGetStatInt(character, "MaxArmor")
		NRD_CharacterSetStatInt(character, "CurrentArmor", NRD_CharacterGetStatInt(character, "CurrentArmor")+(perseverance*Ext.ExtraData.SkillAbilityArmorRestoredPerPoint*0.005*charPA))
		NRD_CharacterSetStatInt(character, "CurrentVitality", NRD_CharacterGetStatInt(character, "CurrentVitality")+(perseverance*Ext.ExtraData.DGM_PerseveranceVitalityRecovery*0.005*charHP))
	elseif type == "Demi-Magic" then
		local charMA = NRD_CharacterGetStatInt(character, "MaxMagicArmor")
		NRD_CharacterSetStatInt(character, "CurrentMagicArmor", NRD_CharacterGetStatInt(character, "CurrentMagicArmor")+(perseverance*Ext.ExtraData.SkillAbilityArmorRestoredPerPoint*0.005*charMA))
		NRD_CharacterSetStatInt(character, "CurrentVitality", NRD_CharacterGetStatInt(character, "CurrentVitality")+(perseverance*Ext.ExtraData.DGM_PerseveranceVitalityRecovery*0.005*charHP))
	end
end

local ccStatusesPhysical = {
	"LX_STAGGERED",
	"LX_STAGGERED2",
	"LX_STAGGERED3",
	"DUMMY"
}

local ccStatusesMagical = {
	"LX_CONFUSED",
	"LX_CONFUSED2",
	"LX_CONFUSED3",
	"DUMMY"
}

local function ManageDemiPerseverance(character, status, causee)
	if status == "POST_PHYS_CONTROL" or status == "POST_MAGIC_CONTROL" then
		ManagePerseverance(character, "Normal")
	end
	for i,cc in pairs(ccStatusesPhysical) do
		if status == cc and HasActiveStatus(character, ccStatusesPhysical[i+1]) == 0 then
			if i ~= GetTableSize(ccStatusesMagical) and HasActiveStatus(character, ccStatusesPhysical[i+1]) == 0 then
				ManagePerseverance(character, "Demi-Physic")
			end
		end
	end
	for i,cc in pairs(ccStatusesMagical) do
		if status == cc then
			if i ~= GetTableSize(ccStatusesMagical) and HasActiveStatus(character, ccStatusesMagical[i+1]) == 0 then
				ManagePerseverance(character, "Demi-Magic")
			end
		end
	end
end

Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "before", ManageDemiPerseverance)

---@param attacker EsvCharacter
---@param target EsvCharacter
local function DGM_HitChanceFormula(attacker, target)
	local hitChance = attacker.Accuracy - target.Dodge + attacker.ChanceToHitBoost
    -- Make sure that we return a value in the range (0% .. 100%)
	hitChance = math.max(math.min(hitChance, 100), 0)
    return hitChance
end

Ext.RegisterListener("GetHitChance", DGM_HitChanceFormula)

--- @param attacker StatCharacter
--- @param target StatCharacter
function DGM_CalculateHitChance(attacker, target)
    if attacker.TALENT_Haymaker then
        return 100
	end
	
    local accuracy = attacker.Accuracy
	local dodge = target.Dodge

	local chanceToHit1 = accuracy - dodge
	chanceToHit1 = math.max(0, math.min(100, chanceToHit1))
    return chanceToHit1 + attacker.ChanceToHitBoost
end

Game.Math.CalculateHitChance = DGM_CalculateHitChance

--- @param character StatCharacter
--- @param weapon StatItem
function CalculateWeaponDamageRange(character, weapon)
    local damages, damageBoost = ComputeBaseWeaponDamage(weapon)

    local abilityBoosts = character.DamageBoost 
        + ComputeWeaponCombatAbilityBoost(character, weapon)
        + ComputeWeaponRequirementScaledDamage(character, weapon)
    abilityBoosts = math.max(abilityBoosts + 100.0, 0.0) / 100.0

    local boost = 1.0 + damageBoost * 0.01
    if character.IsSneaking then
        boost = boost + Ext.ExtraData['Sneak Damage Multiplier']
    end

    local ranges = {}
    for damageType, damage in pairs(damages) do
        local min = damage.Min * boost * abilityBoosts
        local max = damage.Max * boost * abilityBoosts

        if min > max then
            max = min
        end

        ranges[damageType] = {min, max}
    end

    return ranges
end

local function GetDamageMultipliers(skill, stealthed, attackerPos, targetPos)
    local stealthDamageMultiplier = 1.0
    if stealthed then
        stealthDamageMultiplier = Ext.ExtraData.Stealth
    end

    local targetDistance = math.sqrt((attackerPos[1] - targetPos[1])^2 + (attackerPos[3] - targetPos[3])^2)
    local distanceDamageMultiplier = 1.0
    if targetDistance > 1.0 then
        distanceDamageMultiplier = Ext.Round(targetDistance) * skill['Distance Damage Multiplier'] * 0.01 + 1
    end

    local damageMultiplier = skill['Damage Multiplier'] * 0.01
    return stealthDamageMultiplier * distanceDamageMultiplier * damageMultiplier
end

--- @param damageList DamageList
--- @param armor integer
local function ComputeArmorDamage(damageList, armor)
    local damage = damageList:GetByType("Corrosive") + damageList:GetByType("Physical") + damageList:GetByType("Sulfuric")
    return math.min(armor, damage)
end

--- @param damageList DamageList
--- @param magicArmor integer
local function ComputeMagicArmorDamage(damageList, magicArmor)
    local damage = damageList:GetByType("Magic") 
        + damageList:GetByType("Fire") 
        + damageList:GetByType("Water")
        + damageList:GetByType("Air")
        + damageList:GetByType("Earth")
        + damageList:GetByType("Poison")
    return math.min(magicArmor, damage)
end

--- @param hit HitRequest
--- @param damageList DamageList
--- @param statusBonusDmgTypes DamageList
--- @param isDoT string HitType enumeration
--- @param target StatCharacter
--- @param attacker StatCharacter
function DoHit(hit, damageList, statusBonusDmgTypes, isDoT, target, attacker)
    hit.EffectFlags = hit.EffectFlags | Game.Math.HitFlag.Hit;
    damageList:AggregateSameTypeDamages()
    damageList:Multiply(hit.DamageMultiplier)

    local totalDamage = 0
    for i,damage in pairs(damageList:ToTable()) do
        totalDamage = totalDamage + damage.Amount
    end

    if totalDamage < 0 then
        damageList:Clear()
    end

    Game.Math.ApplyDamageCharacterBonuses(target, attacker, damageList)
    damageList:AggregateSameTypeDamages()
    hit.DamageList = Ext.NewDamageList()

    for i,damageType in pairs(statusBonusDmgTypes) do
        damageList.Add(damageType, math.ceil(totalDamage * 0.1))
    end

    Game.Math.ApplyDamagesToHitInfo(damageList, hit)
    hit.ArmorAbsorption = hit.ArmorAbsorption + ComputeArmorDamage(damageList, target.CurrentArmor)
    hit.ArmorAbsorption = hit.ArmorAbsorption + ComputeMagicArmorDamage(damageList, target.CurrentMagicArmor)

    if hit.TotalDamageDone > 0 then
        Game.Math.ApplyLifeSteal(hit, target, attacker, isDoT)
    else
        hit.EffectFlags = hit.EffectFlags | Game.Math.HitFlag.DontCreateBloodSurface
    end

    if isDoT == "Surface" then
        hit.EffectFlags = hit.EffectFlags | Game.Math.HitFlag.Surface
    end

    if isDoT == "DoT" then
        hit.EffectFlags = hit.EffectFlags | Game.Math.HitFlag.DoT
    end
end

--- @param character StatCharacter
--- @param damageList DamageList
--- @param attacker StatCharacter
function ApplyHitResistances(character, damageList, attacker)
	local strength = Ext.ExtraData.AttributeBaseValue
	local intelligence = Ext.ExtraData.AttributeBaseValue
	if attacker ~= nil then 
		strength = attacker.Strength
		intelligence = attacker.Intelligence
	end
	for i,damage in pairs(damageList:ToTable()) do
		local originalResistance = Game.Math.GetResistance(character, damage.DamageType)
		local resistance = originalResistance
		local bypassValue = (strength - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthResistanceIgnore * (intelligence - Ext.ExtraData.AttributeBaseValue)
		-- Ext.Print("bypass value:",bypassValue)
		if originalResistance > 0 and originalResistance < 100 and bypassValue > 0 then
			resistance = originalResistance - bypassValue
			if resistance < 0 then
				resistance = 0
			elseif resistance > originalResistance then
				resistance = originalResistance
			end
		end
        damageList:Add(damage.DamageType, math.floor(damage.Amount * -resistance / 100.0))
    end
end

--- @param character StatCharacter
--- @param attacker StatCharacter
--- @param damageList DamageList
function ApplyDamageCharacterBonuses(character, attacker, damageList)
	-- Ext.Print("VANILLA PLUS ApplyDamageCharacterBonuses")
    damageList:AggregateSameTypeDamages()
    ApplyHitResistances(character, damageList, attacker)

    Game.Math.ApplyDamageSkillAbilityBonuses(damageList, attacker)
end

Game.Math.ApplyDamageCharacterBonuses = ApplyDamageCharacterBonuses
Game.Math.ApplyHitResistances = ApplyHitResistances
Ext.RegisterListener("ComputeCharacterHit", Game.Math.ComputeCharacterHit)

if Mods.LeaderLib ~= nil then
	-- local info = Ext.GetModInfo("7e737d2f-31d2-4751-963f-be6ccc59cd0c")
	-- if info.Version <= 386465794 then
		Mods.LeaderLib.HitOverrides.DoHitModified = DoHit
		Mods.LeaderLib.HitOverrides.ApplyDamageCharacterBonusesModified = ApplyDamageCharacterBonuses
	-- end
end

---- Total lx_damage script conversion
local function SetDodgeCounter(object)
	SetVarInteger(object, "LX_Dodge_Counter", 0)
end

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", SetDodgeCounter)

local function HitCatch(target, status, handle, instigator)
	if status ~= "HIT" then return end
	DamageControl(target, handle, instigator)
end

-- Ext.RegisterOsirisListener("NRD_OnStatusAttempt", 4, "before", HitCatch)
Ext.RegisterOsirisListener("NRD_OnHit", 4, "before", DamageControl)