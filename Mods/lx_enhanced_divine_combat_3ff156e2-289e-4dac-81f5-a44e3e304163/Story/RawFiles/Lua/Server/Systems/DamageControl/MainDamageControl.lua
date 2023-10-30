--- @param character StatCharacter
--- @param weapon StatItem
local function VP_ComputeWeaponCombatAbilityBoost(character, weapon)
    local abilityType = GetWeaponAbility(character, weapon)

    if abilityType == "SingleHanded" or abilityType == "TwoHanded" or abilityType == "Ranged" or abilityType == "DualWielding" then
        local abilityLevel = character[abilityType]
        return abilityLevel * Ext.ExtraData.CombatAbilityDamageBonus
    else
        return 0
    end
end
-- Mods.LeaderLib.Testing

--[[
	Listeners part:
	All features that can potentially influence damage output individually or not.
--]]

---@param object string
---@param combatID any
Ext.Osiris.RegisterListener("ObjectLeftCombat", 2, "before", function(object, combatID)
	if Helpers.CheckEntityExistence(object) then
		RemoveStatus(object, "VP_DW_ATTACK")
	end
end)

---@param object string
---@param combatID any
Ext.Osiris.RegisterListener("ObjectEnteredCombat", 2, "before", function(object, combatID)
	if Helpers.CheckEntityExistence(object) then
		RemoveStatus(object, "VP_DW_ATTACK")
	end
end)

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
--- @param instigatorDGMStats table
HitManager:RegisterHitListener("DGM_Hit", "BeforeDamageScaling", "DGM_Specifics", function(hit, instigator, target, flags)
	--- SIPHON_POISON feature
	if HasActiveStatus(instigator.MyGuid, "SIPHON_POISON") == 1 then
		local seconds = 12.0
		if HasActiveStatus(instigator.MyGuid, "VENOM_COATING") == 1 or HasActiveStatus(instigator.MyGuid, "VENOM_AURA") == 1 then
			seconds = seconds + 12.0
		end
		if CharacterHasTalent(instigator.MyGuid, "Torturer") == 1 then
			seconds = seconds + 6.0
		end
		ApplyStatus(target.MyGuid, "ACID", seconds, 1, instigator.MyGuid)
	end

	--- Aimed Shot
	if flags.IsWeaponAttack and instigator.Stats.MainWeapon.WeaponType == "Crossbow" then
        local aimedShot = FindStatus(instigator, "DMG_AimedShot")
        if aimedShot then RemoveStatus(instigator.MyGuid, aimedShot) end
    end
end, 50)

DWAttackBonus = {}
local AllowedDWBonusAnim = {
	skill_attack_power_01_cast = true,
	skill_attack_precision_01_cast = true
}

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "DGM_AbsorbShields", function(hit, instigator, target, flags)
	if flags.IsWeaponAttack and (NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "DamageSourceType") == 7 or (hit.SkillId ~= "" and instigator.Stats.OffHandWeapon ~= null)) and instigator.Stats.DualWielding > 0 and instigator:GetStatus("VP_DW_ATTACK") then
		local newHit = NRD_HitPrepare(target.MyGuid, instigator.MyGuid)
		NRD_HitSetInt(newHit, "SimulateHit", 1)
		NRD_HitSetInt(newHit, "HitType", 3)
		NRD_HitSetInt(newHit, "Backstab", flags.Backstab and 1 or 0)
		local offhandWeaponDamage = Game.Math.ComputeBaseWeaponDamage(instigator.Stats.OffHandWeapon)
		local totalDamage = 0
		local damageList = Ext.Stats.NewDamageList()
		for dmgType, amounts in pairs(offhandWeaponDamage) do
			local roll = math.random(Ext.Utils.Round(amounts.Min*100), Ext.Utils.Round(amounts.Max*100))/100
			local damageDone = Ext.Utils.Round(roll * Ext.ExtraData.DualWieldingDamagePenalty * (1 + instigator.Stats.DualWielding * Ext.ExtraData.DGM_DualWieldingOffhandBonus*2 / 100))
			NRD_HitAddDamage(newHit, dmgType, damageDone)
			totalDamage = totalDamage + damageDone
			damageList:Add(dmgType, damageDone)
		end
		local properties = {LifeSteal = 0, TotalDamageDone = totalDamage, ArmorAbsorption = 0, DamageList = damageList}
		HitHelpers.HitRecalculateLifesteal(properties)
		NRD_HitSetInt(newHit, "LifeSteal", properties.LifeSteal)
		if hit.SkillId == "" or AllowedDWBonusAnim[Ext.Stats.Get(hit.SkillId:gsub("(.*).+-1$", "%1")).CastAnimation] and not DWAttackBonus[instigator.MyGuid] then
			DWAttackBonus[instigator.MyGuid] = newHit
			Osi.ProcObjectTimer(instigator.MyGuid, "VP_DualWieldingAttackBonus", 200)
		else
			NRD_HitExecute(newHit)
			Osi.ProcObjectTimer(instigator.MyGuid, "VP_ClearDWBonusAttack", 1500) --- Allow for proc on multiple hits
			-- RemoveStatus(instigator.MyGuid, "VP_DW_ATTACK")
		end
	end
end, 49)

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
    if event ~= "VP_DualWieldingAttackBonus" or character == "00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
	CharacterPurgeQueue(character)
	CharacterSetAnimationOverride(character, "skill_attack_projectile_01_cast")
	local instigator = Ext.ServerEntity.GetCharacter(character)
	RemoveStatus(instigator.MyGuid, "VP_DW_ATTACK")
	NRD_HitExecute(DWAttackBonus[character])
	DWAttackBonus[character] = nil
	Osi.ProcObjectTimer(character, "VP_DualWieldingAttackBonusClearAnim", 800)
end)

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
    if event ~= "VP_DualWieldingAttackBonusClearAnim" or character == "00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
	CharacterSetAnimationOverride(character, "")
end)

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
    if event ~= "VP_AddDWBonusAttack" or character == "00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
	ApplyStatus(character, "VP_DW_ATTACK", 12.0, 1, character)
end)

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
    if event ~= "VP_ClearDWBonusAttack" or character == "00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
	RemoveStatus(character, "VP_DW_ATTACK")
end)

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "DGM_AbsorbShields", function(hit, instigator, target, flags)
	--- Retribution indirect damage reduction
	-- if flags.FromReflection or (hit.DamageSourceType ~= "Attack" and hit.DamageSourceType ~= "Offhand" and hit.DamageSourceType ~= "GM") then
	-- 	HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, 1 - (target.Stats.PainReflection * (Ext.ExtraData.DGM_PainReflectionDamageReduction/100)))
	-- end
	--- Perseverance incapacitated damage reduction
	if CharacterIsIncapacitated(target.MyGuid) == 1 and target.Stats.Perseverance > 0 then
		HitHelpers.HitMultiplyDamage(hit, target, instigator, target.Stats.Perseverance * (1 - 100/Ext.ExtraData.DGM_PerseveranceResistance))
	end
	--- Absorb shields
	AbsorbShieldProcessDamage(target, instigator, hit)
	--- Skill damage cap
	if hit.SkillId ~= "" then
		local stat = hit.SkillId ~= "" and Ext.Stats.Get(hit.SkillId:gsub("(.*).+-1$", "%1")) or nil
		if stat.VP_DamageCapValue ~= 0 then
			local cap = stat.VP_DamageCapValue / 100 * Helpers.GetScaledValue(stat.VP_DamageCapScaling, target, instigator)
			local damageTable = hit.Hit.DamageList:ToTable()
			local totalAmount = 0
			for i,element in pairs(damageTable) do
				totalAmount = totalAmount + element.Amount
				if totalAmount > cap then
					HitHelpers.HitAddDamage(hit.Hit, target, instigator, tostring(element.DamageType), cap - totalAmount)
					totalAmount = cap
				end
			end
		end
	end
	--- Consecutive hit damage multiplier
	if hit.SkillId ~= "" then
		local stat = Ext.Stats.Get(hit.SkillId:gsub("(.*).+-1$", "%1"))
		if stat.VP_ConsecutiveDamageReductionPercent ~= 0 then
			if stat.VP_ConsecutiveDamageReductionHitAmount > 0 then
				if not target.UserVars.VP_ConsecutiveHitFromSkill then
					target.UserVars.VP_ConsecutiveHitFromSkill = {ID = instigator.UserVars.VP_LastSkillID.ID, Amount = 1, OnGoing = true}
				else
					if target.UserVars.VP_ConsecutiveHitFromSkill.ID ~= instigator.UserVars.VP_LastSkillID.ID then
						target.UserVars.VP_ConsecutiveHitFromSkill = {ID = instigator.UserVars.VP_LastSkillID.ID, Amount = 1, OnGoing = true}
					else
						target.UserVars.VP_ConsecutiveHitFromSkill.Amount = target.UserVars.VP_ConsecutiveHitFromSkill.Amount + 1
						target.UserVars.VP_ConsecutiveHitFromSkill.OnGoing = true
					end
				end
				Osi.ProcObjectTimer(target.MyGuid, "VP_ConsecutiveHit_"..tostring(target.UserVars.VP_ConsecutiveHitFromSkill.ID), 500)
			end
			local hits = target.UserVars.VP_ConsecutiveHitFromSkill.Amount
			if hits >= stat.VP_ConsecutiveDamageReductionHitAmount then
				Helpers.VPPrint("Combo detected! Current multiplier:", "DamageControl:ComboDamageMultiplier", math.max(1 - (hits - math.max(stat.VP_ConsecutiveDamageReductionHitAmount, 0))*(stat.VP_ConsecutiveDamageReductionPercent/100), 0))
				HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, math.max(1 - (hits - math.max(stat.VP_ConsecutiveDamageReductionHitAmount, 0))*(stat.VP_ConsecutiveDamageReductionPercent/100), 0))
			end
		end
	end
end, 49)

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
    if string.gmatch(event, "VP_ConsecutiveHit_") ~= "VP_ConsecutiveHit_" or character == "00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
    local character = Ext.Entity.GetCharacter(character)
	if character.UserVars.VP_ConsecutiveHitFromSkill.OnGoing then
		character.UserVars.VP_ConsecutiveHitFromSkill.OnGoing = false
		Osi.ProcObjectTimer(target.MyGuid, "VP_ConsecutiveHit_"..tostring(target.VP_ConsecutiveHitFromSkill.ID), 500)
	else
		character.UserVars.VP_ConsecutiveHitFromSkill = nil
	end
end)

Ext.Osiris.RegisterListener("ObjectLeftCombat", 2, "before", function(object, combatID)
	if ObjectIsCharacter(object) == 1 then
		Ext.ServerEntity.GetCharacter(object).UserVars.LX_WarmupManager = 0
	end
end)