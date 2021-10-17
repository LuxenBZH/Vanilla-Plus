---------- Corrosive/Shadow damage tagging
local function TagShadowCorrosiveDifference(damageArray)
	if damageArray.Shadow > 0 and damageArray.Corrosive > 0 then
		if damageArray.Shadow > damageArray.Corrosive then
			Ext.BroadcastMessage("DGM_ShadowCorrosiveTag", "S")
		else
			Ext.BroadcastMessage("DGM_ShadowCorrosiveTag", "C")
		end
	elseif damageArray.Shadow > 0 then
		Ext.BroadcastMessage("DGM_ShadowCorrosiveTag", "S")
	elseif damageArray.Corrosive > 0 then
		Ext.BroadcastMessage("DGM_ShadowCorrosiveTag", "C")
	end
end

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
----------

---------- Corrogic Module
--- @param instigator string GUID
--- @param skill string
local function IncreaseCorrosiveMagicFromSkill(instigator, skill, damageList)
	local school = Ext.GetStat(skill).Ability
	local stat = Ext.GetCharacter(instigator).Stats[skillAbilities[school]]
	if stat then
		if damageList["Corrosive"] ~= 0 then
			damageList["Corrosive"] = damageList["Corrosive"] * 1.0+(0.05*stat)
		end
		if damageList["Magic"] ~= 0 then
			damageList["Magic"] = damageList["Magic"] * 1.0+(0.05*stat)
		end
	end
end

local function InflictResistanceDebuff(target, perc)
	local character = Ext.GetCharacter(target)
	local current = FindStatus(character, "LX_CORROGIC_")
	if not current then
		current = perc
	else
		current = string.gsub(current, "LX_CORROGIC_", "")
		Ext.Print(current, perc)
		current = tonumber(current) + perc
	end
	if NRD_StatExists("LX_CORROGIC_"..current) then
		ApplyStatus(character.MyGuid, "LX_CORROGIC_"..current, 12.0, 1)
	else
		local newPotion = Ext.CreateStat("DGM_Potion_Corrogic_"..current, "Potion", "DGM_Potion_Base")
		for i,res in pairs(resistances) do
			newPotion[res] = -current
		end
		Ext.SyncStat(newPotion.Name, false)
		local newStatus = Ext.CreateStat("LX_CORROGIC_"..current, "StatusData", "LX_CORROGIC")
		newStatus.StatsId = newPotion.Name
		Ext.SyncStat(newStatus.Name, false)
		ApplyStatus(character.MyGuid, "LX_CORROGIC_"..current, 12.0, 1)
	end
end

--- @param target string GUID
--- @param dmgList number[] 
local function TriggerCorrogicResistanceStrip(target, dmgList)
	local character = Ext.GetCharacter(target)
	if dmgList.Corrosive > 0 or dmgList.Magic > 0 then
		local perc = 0
		if character.Stats.CurrentArmor == 0 then
			perc = perc + math.floor(dmgList.Corrosive / character.Stats.MaxVitality * 100)
		end
		if character.Stats.CurrentMagicArmor == 0 then
			perc = perc + math.floor(dmgList.Magic / character.Stats.MaxVitality * 100)
		end
		if perc > 0 then
			InflictResistanceDebuff(target, perc)
		end
	end
end
-----------

----------- Damage Scaling functions
------ Intelligence Skill bonus
---@param instigator string GUID
---@param skillID string
---@param intelligence integer
---@param weaponTypes string[]
---@param globalMultiplier float
local function ScaleDamageFromSkill(instigator, skillID, intelligence, weaponTypes)
	local damageBonus = intelligence*Ext.ExtraData.DGM_IntelligenceSkillBonus
	local globalMultiplierBonus = 0
		-- print("Bonus: skill")
		-- Apply bonus from wand and staves
		if weaponTypes[1] == "Wand" then
			if weaponTypes[2] == "Wand" then
				globalMultiplierBonus = globalMultiplierBonus + Ext.ExtraData.DGM_WandSkillMultiplier/100*2
			else
				globalMultiplierBonus = globalMultiplierBonus + Ext.ExtraData.DGM_WandSkillMultiplier/100
			end
		elseif weaponTypes[2] == "Wand" then -- Credits to lololice to spot that edge case
			if weaponTypes[1] == "Wand" then
				globalMultiplierBonus = globalMultiplierBonus + Ext.ExtraData.DGM_WandSkillMultiplier/100*2
			else
				globalMultiplierBonus = globalMultiplierBonus + Ext.ExtraData.DGM_WandSkillMultiplier/100
			end
		elseif weaponTypes[1] == "Staff" then
			globalMultiplierBonus = globalMultiplierBonus + Ext.ExtraData.DGM_StaffSkillMultiplier/100
		end
		-- Apply Slingshot bonus if it's a grenade
		local isGrenade = string.find(skillID, "Grenade")
		local hasSlingshot = CharacterHasTalent(instigator, "WarriorLoreGrenadeRange")
		if isGrenade ~= nil and hasSlingshot == 1 then
			damageBonus = damageBonus + Ext.ExtraData.DGM_SlingshotBonus
		end
	return damageBonus, globalMultiplierBonus
end

---@param instigator string GUID
---@param target string GUID
local function SiphonPoisonBoost(instigator, target)
	if HasActiveStatus(instigator, "SIPHON_POISON") == 1 then
		local seconds = 12.0
		if HasActiveStatus(instigator, "VENOM_COATING") == 1 or HasActiveStatus(instigator, "VENOM_AURA") == 1 then
			seconds = seconds + 12.0
		end
		if CharacterHasTalent(instigator, "Torturer") == 1 then
			seconds = seconds + 6.0
		end
		ApplyStatus(target, "ACID", seconds, 1)
	end
end

---@param weaponTypes string[]
---@param target string GUID
---@param instigator string GUID
local function ApplyCQBPenalty(weaponTypes, target, instigator)
	local globalMultiplierBonus = 0
	if weaponTypes[1] == "Bow" or weaponTypes[1] == "Crossbow" or weaponTypes[1] == "Rifle" or weaponTypes[1] == "Wand" then
		local distance = GetDistanceTo(target, instigator)
		--Ext.Print("[LXDGM_DamageControl.DamageControl] Distance :",distance)
		if distance <= Ext.ExtraData.DGM_RangedCQBPenaltyRange and CharacterHasTalent(instigator, "RangerLoreArrowRecover") == 0 then
			globalMultiplierBonus = (Ext.ExtraData.DGM_RangedCQBPenalty/100)
		end
	end
	return globalMultiplierBonus
end
----------

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
	local totalDamage = 0
	for i,dmgType in pairs(types) do
		damages[dmgType] = NRD_HitStatusGetDamage(target, handle, dmgType)
		totalDamage = totalDamage + damages[dmgType]
		if damages[dmgType] ~= 0 then Ext.Print("Damage "..dmgType..": "..damages[dmgType]) end
	end
	TagShadowCorrosiveDifference(damages)
	
	if isBlocked == 1 then return end
	if sourceType == 1 or sourceType == 2 or sourceType == 3 then InitiatePassingDamage(target, damages); return end
	if skillID == "" and sourceType == 0 and ObjectIsCharacter(target) == 1 then InitiatePassingDamage(target, damages); return end
	if fixedValue ~= 0 and fixedValue ~= 1 and fixedValue ~= 2 then InitiatePassingDamage(target, damages); return end
	
	if ObjectIsCharacter(target) == 1 then
		TraceDamageSpreaders(Ext.GetCharacter(target))
	end

	-- Dodge mechanic override
	if isMissed == 1 or isDodged == 1 then
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
		-- Siphon Poison effect
		SiphonPoisonBoost(instigator, target)
		-- Wands bonus
		if weaponTypes[1] == "Wand" then
			local groundSurface = string.gsub(GetSurfaceGroundAt(instigator), "Surface", "")
			local cloudSurface = string.gsub(GetSurfaceCloudAt(instigator), "Surface", "")
			if surfaceToType[groundSurface] ~= nil then
				damages[surfaceToType[groundSurface]] = damages[surfaceToType[groundSurface]] + (totalDamage * Ext.ExtraData.DGM_WandSurfaceBonus/100)
			end
			if surfaceToType[cloudSurface] ~= nil then
				damages[surfaceToType[cloudSurface]] = damages[surfaceToType[cloudSurface]] + (totalDamage * Ext.ExtraData.DGM_WandSurfaceBonus/100)
			end
		end
		-- Apply CQB Penalty if necessary
		globalMultiplier = globalMultiplier + ApplyCQBPenalty(weaponTypes, target, instigator)
		-- Dual Wielding offhand damage boost
		if sourceType == 7 then
			local dualWielding = CharacterGetAbility(instigator, "DualWielding")
			damageBonus = damageBonus + dualWielding*Ext.ExtraData.DGM_DualWieldingOffhandBonus
		end
	end
	-- DoT Wits bonus
	if isDoT == 1 then
		damageBonus = wits*Ext.ExtraData.DGM_WitsDotBonus
		Ext.Print("Dot bonus",damageBonus)
	end
	-- Intelligence skill bonus
	if skillID ~= "" then 
		local skillBonus, skillGlobalBonus = ScaleDamageFromSkill(instigator, skillID, intelligence, weaponTypes)
		damageBonus = damageBonus + skillBonus
		globalMultiplier = globalMultiplier + skillGlobalBonus
	end
	-- Apply damage changes and side effects
	if skillID == "Projectile_Talent_Unstable" or IsTagged(target, "DGM_GuardianAngelProtector") == 1 or isFromShacklesOfPain then 
		ClearTag(target, "DGM_GuardianAngelProtector")
		damageBonus = 0
		globalMultiplier = 1
	end
	damages = ChangeDamage(damages, (damageBonus/100+1)*globalMultiplier, 0, instigator, target, handle, isDoT)
	ReplaceDamages(damages, handle, target)
	TagShadowCorrosiveDifference(damages)
	if ObjectIsCharacter(target) == 1 then SetWalkItOff(target, handle) end
	
	-- Armor passing damages
	if ObjectIsCharacter(target) == 1 then InitiatePassingDamage(target, damages) end
	if Ext.ExtraData.DGM_Corrogic == 1 then
		TriggerCorrogicResistanceStrip(target, damages)
	end
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
function ChangeDamage(damages, multiplier, value, instigator, target, handle, dot)
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
	if ObjectIsCharacter(target) ~= 1 or dot == 1 then lifesteal = 0 end
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

-- Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "before", ManageDemiPerseverance)

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
		local diff = 0
		if attacker.MainWeapon then
			diff = diff + math.max(0, (attacker.MainWeapon.Level - attacker.Level))
		end
		if attacker.OffHandWeapon then
			diff = diff + math.max(0, (attacker.OffHandWeapon.Level - attacker.Level))
		end
        return 100 - diff * Ext.ExtraData.WeaponAccuracyPenaltyPerLevel
	end
	
    local accuracy = attacker.Accuracy
	local dodge = target.Dodge
	if target.Character:GetStatus("KNOCKED_DOWN") and dodge > 0 then
		dodge = 0
	end

	local chanceToHit1 = accuracy - dodge
	chanceToHit1 = math.max(0, math.min(100, chanceToHit1))
    return chanceToHit1 + attacker.ChanceToHitBoost
end

Game.Math.CalculateHitChance = DGM_CalculateHitChance

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

