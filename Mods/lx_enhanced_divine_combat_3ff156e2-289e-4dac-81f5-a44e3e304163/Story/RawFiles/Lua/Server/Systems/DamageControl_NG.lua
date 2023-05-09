--- @alias HookEvent string | "StatusHitEnter" | "ComputeCharacterHit" | "BeforeCharacterApplyDamage" | "NRD_OnHit" | "DGM_Hit"
--- @alias HitEvent string | "OnMelee" | "OnRanged" | "OnWeaponHit" | "OnHit" | "BeforeDamageScaling" | "AfterDamageScaling"
--- @alias HitConditionCallback fun(status:EsvStatusHit, instigator:EsvCharacter, target:EsvCharacter, flags:HitFlags, instigatorDGMStats:table):void

---@class HitManager
---@field HitHooks table
HitManager = {
	HitHooks = {
		StatusHitEnter = {
			OnMelee = {},
			OnRanged = {},
			OnWeaponHit = {},
			OnHit = {},
		},
		ComputeCharacterHit = {},
		DGM_Hit = {
			OnMelee = {},
			OnRanged = {},
			OnWeaponHit = {},
			OnHit = {},
			BeforeDamageScaling = {},
			AfterDamageScaling = {},
		},
	}
}

--- @param hook HookEvent
--- @param event HitEvent
--- @param func HitConditionCallback
--- @param priority integer|nil Default: 100
function HitManager:RegisterHitListener(hook, event, name, func, priority)
    table.insert(HitHooks[hook][event], priority or 100, {
        Name = name,
        Handle = func
    })
end

--- @param hook HookEvent
--- @param event HitEvent
function HitManager:TriggerHitListeners(hook, event, ...)
    local params = {...}
    if HitHooks[hook] then
        for i,j in pairs(HitHooks[hook][event]) do
            j.Handle(table.unpack(params))
        end
    end
end

--- Important function to track if the target is currently protected by a shared damage status to avoid double scaling
---@param target EsvCharacter
function HitManager:TagCharacterWithSharedDamage(target)
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

--- Calculate and reduce the potential damage shielding statuses a character can have
--- @param target EsvCharacter | EsvItem
--- @param damage StatsDamagePairList
function HitManager:ShieldStatusesAbsorbDamage(target, damage)
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

--- Calculate and apply the damage going through armors and hit Vitality
---@param target EsvCharacter
---@param damages table
function HitManager:InitiatePassingDamage(target, damages)
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
		HitManager:ShieldStatusesAbsorbDamage(target, hit.Hit.DamageList)
		HitManager:InitiatePassingDamage(target, hit.Hit.DamageList)
        return
	end

    -- Trace Guardian Angel statuses
    if Helpers.IsCharacter(target) then HitManager:TagCharacterWithSharedDamage(target) end

    -- Bonuses
	local attacker = Data.Math.GetCharacterComputedDamageBonus(instigator, target, flags, skill)

    if (skill and skill.Name == "Projectile_Talent_Unstable") or IsTagged(target.MyGuid, "DGM_GuardianAngelProtector") == 1 or flags.IsFromShackles then
		ClearTag(target.MyGuid, "DGM_GuardianAngelProtector")
		attacker.DamageBonus = 0
		attacker.GlobalMultiplier = 1
	end
	local lifesteal = instigator.Stats.LifeSteal
	local damageTable = hit.Hit.DamageList:ToTable()
	
	NRD_HitStatusClearAllDamage(target.MyGuid, handle)
	HitManager:TriggerHitListeners("DGM_Hit", "BeforeDamageScaling", hit, instigator, target, flags, attacker)
	for i,element in pairs(damageTable) do
		local multiplier = 1 + attacker.DamageBonus/100
		if element.DamageType == "Water" and instigator.Stats.TALENT_IceKing then
			multiplier = multiplier + 1/Ext.ExtraData.DGM_IceKingDamageBonus
		elseif element.DamageType == "Corrosive" or element.DamageType == "Magic" then
			element.Amount = element.Amount * Ext.ExtraData.DGM_ArmourReductionMultiplier / 100
		end
		element.Amount = (element.Amount * multiplier) * attacker.GlobalMultiplier + math.random(0,1) -- Range somewhat of a fix
		NRD_HitStatusAddDamage(target.MyGuid, handle, element.DamageType, element.Amount)
	end
	HitHelpers.HitRecalculateAbsorb(hit.Hit, target)
	HitHelpers.HitRecalculateLifesteal(hit.Hit, instigator)
	HitManager:TriggerHitListeners("DGM_Hit", "AfterDamageScaling", hit, instigator, target, flags, attacker)
	HitManager:InitiatePassingDamage(target, damageTable)
	HitManager:ShieldStatusesAbsorbDamage(target, hit.Hit.DamageList)
end

-- Ext.RegisterOsirisListener("NRD_OnStatusAttempt", 4, "before", HitCatch)
Ext.RegisterOsirisListener("NRD_OnHit", 4, "before", DamageControl)

--- Fix the original DoHit that is
local function DoHit(hit, damageList, statusBonusDmgTypes, hitType, target, attacker, ctx)
	hit.Hit = true;
	damageList:AggregateSameTypeDamages()
	if type(ctx) == "number" then
		damageList:Multiply(ctx)
	else
		damageList:Multiply(ctx.DamageMultiplier)
	end

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

--- Trigger lua ComputeCharacterHit for the Sadist fix to work if LLib isn't active
if not Mods.LeaderLib then
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
else
	Mods.LeaderLib.HitOverrides.DoHit = DoHit
end


---- Elemental Ranger and Gladiator fix
local surfaceDamageMapping = {
	SurfaceFire = "Fire",
    SurfaceWater = "Water",
    SurfaceWaterFrozen = "Water",
    SurfaceWaterElectrified = "Air",
    SurfaceBlood = "Physical",
    SurfaceBloodElectrified = "Air",
    SurfaceBloodFrozen = "Physical",
    SurfacePoison = "Poison",
    SurfaceOil = "Earth",
    SurfaceLava = "Fire",
	SurfaceFireCursed = "Fire",
	SurfacePoisonCursed = "Poison",
	SurfaceWaterCursed = "Water",
	SurfacePoisonBlessed = "Poison",
	SurfaceWaterBlessed = "Water",
	SurfaceFireBlessed = "Fire",
	SurfaceOilBlessed = "Earth",
	SurfaceWaterFrozenCursed = "Water",
	SurfaceWaterElectrifiedCursed = "Air",
	SurfaceWaterElectrifiedBlessed = "Air",
	SurfaceWaterFrozenBlessed = "Water",
	SurfaceBloodCursed = "Physical",
	SurfaceBloodElectrifiedBlessed = "Air",
    SurfaceBloodFrozenCursed = "Physical",
	SurfaceBloodElectrifiedCursed = "Air",
	SurfaceOilCursed = "Earth",
	SurfaceBloodFrozenBlessed = "Physical"
}

---@param e EsvLuaComputeCharacterHitEvent
Ext.Events.ComputeCharacterHit:Subscribe(function(e)
	--- Elemental Ranger
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
		e.Hit.Missed = true
		Game.Math.ComputeCharacterHit(e.Target, e.Attacker, e.Weapon, e.DamageList, e.HitType, e.NoHitRoll, e.ForceReduceDurability, e.Hit, e.AlwaysBackstab, e.HighGround, e.CriticalRoll)
	--- Gladiator
	elseif e.Target.TALENT_Gladiator and (e.HitType == "WeaponDamage"and e.Hit.HitWithWeapon) and not Game.Math.IsRangedWeapon(e.Attacker.MainWeapon) and e.Target:GetItemBySlot("Shield") then
		local counterAttacked = Helpers.HasCounterAttacked(e.Target.Character)
		if not counterAttacked and GetDistanceTo(e.Target.Character.MyGuid, e.Attacker.Character.MyGuid) <= 5.0 then
			CharacterUseSkill(e.Target.Character.MyGuid, "Target_LX_GladiatorHit", e.Attacker.Character.MyGuid, 1, 1, 1)
			Helpers.SetHasCounterAttacked(e.Target.Character, true)
		end
	elseif e.Attacker and e.Attacker.TALENT_Gladiator and e.NoHitRoll and e.HitType == "Melee" and not e.Hit.HitWithWeapon then
		e.NoHitRoll = false
		local hit = Game.Math.ComputeCharacterHit(e.Target, e.Attacker, e.Weapon, e.DamageList, e.HitType, e.NoHitRoll, e.ForceReduceDurability, e.Hit, e.AlwaysBackstab, e.HighGround, e.CriticalRoll) ---@type EsvStatusHit
		if hit.Missed then
			e.Hit.Hit = false
			e.Hit.DontCreateBloodSurface = true
		end
		e.Hit.CounterAttack = true
		if not e.Handled and hit then
			e.Handled = true
		end
	end
end)
-- Mods.LeaderLib.Testing

--[[
	Listeners part:
	All features that can potentially influence damage output individually or not.
--]]

---@param character EsvCharacter
---@param step number|nil
function ApplyWarmup(character, step)
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
	CustomStatusManager:CharacterApplyMultipliedStatus(character, "DGM_WARMUP"..tostring(stage), 6.0, 1.0 + 0.1 * character.Stats.WarriorLore)
end

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
--- @param instigatorDGMStats table
HitManager:RegisterHitListener("DGM_Hit", "BeforeDamageScaling", function(hit, instigator, target, flags, instigatorDGMStats)
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

	--- WARMUP application
	if (flags.Missed or flags.Dodged) and not target:GetStatus("EVADING") and Helpers.IsCharacter(instigator) then
		ApplyWarmup(instigator)
	end

	--- Aimed Shot
	if flags.IsWeaponAttack and instigator.Stats.MainWeapon.WeaponType == "Crossbow" then
        local aimedShot = FindStatus(instigator, "DMG_AimedShot")
        if aimedShot then RemoveStatus(instigator.MyGuid, aimedShot) end
    end
end)