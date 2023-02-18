---@param target EsvCharacter
local function TraceDamageSpreaders(target)
	local statuses = target:GetStatuses()
	for i,status in pairs(statuses) do
		if target:GetStatus(status).StatusType == "GUARDIAN_ANGEL" then
			local source = target:GetStatus(status).StatusSourceHandle
			if source then
				SetTag(Ext.ServerEntity.GetCharacter(source).MyGuid, "DGM_GuardianAngelProtector")
			end
		end
	end
end

--- @param target EsvCharacter | EsvItem
--- @param damage StatsDamagePairList
local function AbsorbDamageFromShieldStatus(target, damage)
	for dmgType, amount in pairs(damage:ToTable()) do
		local absorbStatus = target:GetStatus("LX_SHIELD_"..string.upper(dmgType))
		if absorbStatus then
			local absorbAmount = absorbStatus.StatsMultiplier
			if absorbAmount > 0 then
				damage:Clear(dmgType) 
                damage:Add(dmgType, math.max(amount-absorbAmount, 0))
				local newAbsorbAmount = math.max(absorbAmount-amount, 0)
				if newAbsorbAmount > 0 then
					absorbStatus.StatsMultiplier = newAbsorbAmount
				else
					RemoveStatus(target.MyGuid, absorbStatus.StatusId)
				end
			end
		end
	end
end

---@param target EsvCharacter | EsvItem
---@param damages StatsDamagePairList
local function InitiatePassingDamage(target, damages)
    if Helpers.IsItem(target) then return end
	for dmgType,amount  in pairs(damages) do
		if amount ~= 0 then
			local piercing = ArmorSystem.CalculatePassingDamage(target.MyGuid, amount, dmgType)
			ArmorSystem.ApplyPassingDamage(target.MyGuid, piercing)
		end
	end
end

---@param target EsvCharacter
---@param instigator EsvCharacter
local function ApplyCQBPenalty(target, instigator)
	local globalMultiplierBonus = 0
	local weaponTypes = {instigator.Stats.MainWeapon.WeaponType, instigator.Stats.OffHandWeapon.WeaponType}
	if weaponTypes[1] == "Bow" or weaponTypes[1] == "Crossbow" or weaponTypes[1] == "Rifle" or weaponTypes[1] == "Wand" then
		local distance = Ext.Math.Distance(target.WorldPos, instigator.WorldPos)
		--Ext.Print("[LXDGM_DamageControl.DamageControl] Distance :",distance)
		if distance <= Ext.ExtraData.DGM_RangedCQBPenaltyRange and instigator.Stats.TALENT_RangerLoreArrowRecover then
			globalMultiplierBonus = (Ext.ExtraData.DGM_RangedCQBPenalty/100)
		end
	end
	return globalMultiplierBonus
end

---@param character EsvCharacter
---@param step number|nil
local function ApplyWarmup(character, step)
	local warmup = FindStatus(character, "DGM_WARMUP")
	local stage
	if step then
		stage = step
	elseif warmup then
		stage = math.min(tonumber(string.sub(warmup, 11, 11))+1, 4)
		ObjectSetFlag(character.MyGuid, "DGM_WarmupReapply", 0)
	else
		stage = 1
	end
	CustomStatusManager:CharacterApplyMultipliedStatus(char, "DGM_WARMUP"..tostring(stage), 6.0, 1.0 + 0.1 * char.Stats.WarriorLore)
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

---@param character EsvCharacter
---@param target EsvCharacter
---@param flags HitFlags
---@param hit StatEntrySkillData | nil
local function GetCharacterComputedDamageBonus(character, target, flags, skill)
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
		attributes.GlobalMultiplier = attributes.GlobalMultiplier + ApplyCQBPenalty(target, character)
		-- TODO: Dual Wielding offhand status chance increase
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

---@param target EsvCharacter
---@param damages table
local function InitiatePassingDamage(target, damages)
	if getmetatable(target) ~= "esv::Character" then
		return
	end
	for i, element  in pairs(damages) do
		if element.Amount ~= 0 then
			local piercing = ArmorSystem.CalculatePassingDamage(target.MyGuid, element.Amount, element.DamageType)
			ArmorSystem.ApplyPassingDamage(target.MyGuid, piercing)
		end
	end
end

---@param target Guid
---@param instigator Guid
---@param hitDamage number
---@param handle number
local function DamageControl(target, instigator, hitDamage, handle)
	local target = Ext.ServerEntity.GetGameObject(target) --- @type EsvItem | EsvCharacter
	local instigator = Ext.ServerEntity.GetGameObject(instigator) --- @type EsvCharacter
	if getmetatable(instigator) ~= "esv::Character" then
		return
	end
	local hit = Ext.ServerEntity.GetStatus(target.MyGuid, handle) --- @type EsvStatusHit
	local skill = hit.SkillId ~= "" and Ext.Stats.Get(string.sub(hit.SkillId, 1, string.len(hit.SkillId)-3)) or nil --- @type StatEntrySkillData | nil
	local flags = HitFlags:Create()
    flags.Dodged = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "Dodged") == 1
    flags.Missed = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "Missed") == 1
    flags.Critical = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "CriticalHit") == 1
    flags.Backstab = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "Backstab") == 1
    flags.DamageSourceType = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "DamageSourceType")
    flags.Blocked = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "Blocked") == 1
    flags.IsDirectAttack = hit.DamageSourceType == "Attack" or hit.SkillId ~= ""
	flags.FromReflection = NRD_StatusGetInt(target.MyGuid, handle, "Reflection") == 1
    flags.IsWeaponAttack = hit.Hit.HitWithWeapon
	flags.IsStatusDamage = NRD_StatusGetInt(target.MyGuid, handle, "DoT")

	if (hit.SkillId == "Projectile_Talent_Unstable" and IsTagged(instigator.MyGuid, "LX_UNSTABLE_COOLDOWN") == 1) 
	 or flags.Blocked then
		return 
	end
	if hit.HitReason == 1 and hit.SkillId == ""
	 and target:GetStatus("SHACKLES_OF_PAIN")
	 and Ext.ServerEntity.GetGameObject(target:GetStatus("SHACKLES_OF_PAIN").StatusSourceHandle).MyGuid == instigator.MyGuid then
		flags.IsFromShackles = true
	end
	-- Don't scale damage from surfaces, GM, scriting , reflection, or if the damage type doesn't fit scaling
	if flags.FromReflection
	 or (flags.DamageSourceType > 0 and flags.DamageSourceType < 4) 
	 or (flags.DamageSourceType == 0 and hit.SkillId == "" and Helpers.IsCharacter(target))
	 or skill and (skill.Damage ~= "AverageLevelDamge" and skill.Damage ~= "BaseLevelDamage")  then
		AbsorbDamageFromShieldStatus(target, hit.Hit.DamageList)
		InitiatePassingDamage(target, hit.Hit.DamageList)
        return
	end
    -- Trace Guardian Angel statuses
    if Helpers.IsCharacter(target) then TraceDamageSpreaders(target) end
    -- Aimed shot
    if flags.IsWeaponAttack and instigator.Stats.MainWeapon.WeaponType == "Crossbow" then
        local aimedShot = FindStatus(instigator, "DMG_AimedShot")
        if aimedShot then RemoveStatus(instigator.MyGuid, aimedShot) end
    end
    -- Dodge Mechanics
    if (flags.Missed or flags.Dodged) and not target:GetStatus("EVADING") and Helpers.IsCharacter(instigator) then
        ApplyWarmup(instigator)
    end
    -- Bonuses
	local attacker = GetCharacterComputedDamageBonus(instigator, target, flags, skill)
	--TODO: move specifics in a listener
    if flags.IsWeaponAttack or (skill and skill.Name == "Target_TentacleLash") then
		SiphonPoisonBoost(character.MyGuid, target.MyGuid)
	end
    if (skill and skill.Name == "Projectile_Talent_Unstable") or IsTagged(target.MyGuid, "DGM_GuardianAngelProtector") == 1 or flags.IsFromShackles then
		ClearTag(target.MyGuid, "DGM_GuardianAngelProtector")
		attacker.DamageBonus = 0
		attacker.GlobalMultiplier = 1
	end
	local lifesteal = instigator.Stats.LifeSteal
	-- hit.Hit.DamageList:Multiply((attacker.DamageBonus/100+1)*attacker.GlobalMultiplier)
	local damageTable = hit.Hit.DamageList:ToTable()
	-- hit.Hit.DamageList:Clear()
	NRD_HitStatusClearAllDamage(target.MyGuid, handle)
	-- _D(damageTable)

	for i,element in pairs(damageTable) do
		local multiplier = attacker.DamageBonus/100
		if element.DamageType == "Water" and instigator.Stats.TALENT_IceKing then
			multiplier = multiplier + 1/Ext.ExtraData.DGM_IceKingDamageBonus
		elseif element.DamageType == "Corrosive" or element.DamageType == "Magic" then
			element.Amount = element.Amount * Ext.ExtraData.DGM_ArmourReductionMultiplier / 100
		end
		element.Amount = (element.Amount * multiplier) * attacker.GlobalMultiplier + math.random(0,1) -- Range somewhat of a fix
		-- hit.Hit.DamageList:Add(element.DamageType, math.ceil(element.Amount))
		NRD_HitStatusAddDamage(target.MyGuid, handle, element.DamageType, element.Amount)
	end
	-- _D(hit.Hit.DamageList:ToTable())
	HitHelpers.HitRecalculateAbsorb(hit.Hit, target)
	HitHelpers.HitRecalculateLifesteal(hit.Hit, instigator)
	InitiatePassingDamage(target, damageTable)
end

-- Ext.RegisterOsirisListener("NRD_OnStatusAttempt", 4, "before", HitCatch)
-- Ext.RegisterOsirisListener("NRD_OnHit", 4, "before", DamageControl)

--- Trigger lua ComputeCharacterHit for the Sadist fix to work if LLib isn't active
if not Mods.LeaderLib then
	--- Fix the original DoHit that is
	local function DoHit(hit, damageList, statusBonusDmgTypes, hitType, target, attacker, ctx)
		hit.Hit = true;
		damageList:AggregateSameTypeDamages()
		damageList:Multiply(ctx.DamageMultiplier)

		local totalDamage = 0
		for i,damage in pairs(damageList:ToTable()) do
			totalDamage = totalDamage + damage.Amount
		end
	
		if totalDamage < 0 then
			damageList:Clear()
		end
	
		Game.Math.ApplyDamageCharacterBonuses(target, attacker, damageList)
		damageList:AggregateSameTypeDamages()
		hit.DamageList:Clear()
	
		for i,damageType in pairs(statusBonusDmgTypes) do
			damageList:Add(damageType, math.ceil(totalDamage * 0.1))
		end
	
		Game.Math.ApplyDamagesToHitInfo(damageList, hit)
		hit.ArmorAbsorption = hit.ArmorAbsorption + Game.Math.ComputeArmorDamage(damageList, target.CurrentArmor)
		hit.ArmorAbsorption = hit.ArmorAbsorption + Game.Math.ComputeMagicArmorDamage(damageList, target.CurrentMagicArmor)
	
		if hit.TotalDamageDone > 0 then
			Game.Math.ApplyLifeSteal(hit, target, attacker, hitType)
		else
			hit.DontCreateBloodSurface = true
		end
	
		if hitType == "Surface" then
			hit.Surface = true
		end
	
		if hitType == "DoT" then
			hit.DoT = true
		end
	end

	Game.Math.DoHit = DoHit

	--- Fix Sadist when LeaderLib is not active
	---@param e EsvLuaComputeCharacterHitEvent
	local function ApplySadist(e)
		local totalDamage = 0
		for i,damage in pairs(e.DamageList:ToTable()) do
			totalDamage = totalDamage + damage.Amount
		end
		local statusBonusDmgTypes = {}
		if e.Hit.Poisoned then
			table.insert(statusBonusDmgTypes, "Poison")
		end
		if e.Hit.Burning or e.Target.Character:GetStatus("NECROFIRE") then
			table.insert(statusBonusDmgTypes, "Fire")
		end
		if e.Hit.Bleeding then
			table.insert(statusBonusDmgTypes, "Physical")
		end
		local damageList = e.Hit.DamageList
		local damageBonus = math.ceil(totalDamage * 0.1)
		for i,damageType in pairs(statusBonusDmgTypes) do
			damageList:Add(damageType, damageBonus)
		end
		e.DamageList:Merge(damageList)
		e.Hit.ArmorAbsorption = Game.Math.ComputeArmorDamage(damageList, e.Target.CurrentArmor)
			e.Hit.ArmorAbsorption = e.Hit.ArmorAbsorption + Game.Math.ComputeMagicArmorDamage(damageList, e.Target.CurrentMagicArmor)
		return e
	end

	---@param e EsvLuaComputeCharacterHitEvent
	Ext.Events.ComputeCharacterHit:Subscribe(function(e)
		if e.Attacker and e.Attacker.TALENT_Sadist then
			-- Fix Sadist for melee skills that doesn't have UseCharacterStats = Yes
			if e.HitType == "WeaponDamage" and not Game.Math.IsRangedWeapon(e.Attacker.MainWeapon) and e.Hit.HitWithWeapon then
				ApplySadist(e)
			-- Fix Sadist for Necrofire
			elseif e.HitType == "Melee" and e.Target.Character:GetStatus("NECROFIRE") then
				ApplySadist(e)
			end
			if not e.Handled then
				e.Handled = true
			end
			Game.Math.ComputeCharacterHit(e.Target, e.Attacker, e.Weapon, e.DamageList, e.HitType, e.NoHitRoll, e.ForceReduceDurability, e.Hit, e.AlwaysBackstab, e.HighGround, e.CriticalRoll)
		end
	end)
end

---- Elemental Ranger fix
local surfaceDamageMapping = {
	SurfaceFire = "Fire",
	SurfaceWater = "Water",
	SurfaceWaterFrozen = "Water",
	SurfaceWaterElectrified = "Air",
	SurfaceBlood = "Physical",
	SurfaceBloodElectrified = "Air",
	SurfaceBloodFrozen = "Water",
	SurfacePoison = "Poison",
	SurfaceOil = "Earth",
	SurfaceLava = "Fire"
}

---@param e EsvLuaComputeCharacterHitEvent
Ext.Events.ComputeCharacterHit:Subscribe(function(e)
	if e.Attacker and e.Attacker.TALENT_ElementalRanger and e.HitType == "WeaponDamage" and Game.Math.IsRangedWeapon(e.Attacker.MainWeapon) then
		local surface = GetSurfaceGroundAt(e.Target.Character.MyGuid)
		local dmgType = surfaceDamageMapping[surface]
		if dmgType then
			local totalDamage = 0
			for i,damage in pairs(e.DamageList:ToTable()) do
				totalDamage = totalDamage + damage.Amount
			end
			
			local damageList = Ext.Stats.NewDamageList()
			damageList:CopyFrom(e.DamageList)
			damageList:Add(dmgType, math.ceil(tonumber(totalDamage)*0.2))
			e.DamageList:CopyFrom(damageList)
			e.Hit.ArmorAbsorption = Game.Math.ComputeArmorDamage(damageList, e.Target.CurrentArmor)
			e.Hit.ArmorAbsorption = e.Hit.ArmorAbsorption + Game.Math.ComputeMagicArmorDamage(damageList, e.Target.CurrentMagicArmor)
		end
		if not e.Handled then
			e.Handled = true
		end
		Game.Math.ComputeCharacterHit(e.Target, e.Attacker, e.Weapon, e.DamageList, e.HitType, e.NoHitRoll, e.ForceReduceDurability, e.Hit, e.AlwaysBackstab, e.HighGround, e.CriticalRoll)
	end
end)