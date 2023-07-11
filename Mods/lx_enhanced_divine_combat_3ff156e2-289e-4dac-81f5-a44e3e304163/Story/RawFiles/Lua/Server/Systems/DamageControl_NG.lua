--- @alias HookEvent string | "StatusHitEnter" | "ComputeCharacterHit" | "BeforeCharacterApplyDamage" | "NRD_OnHit" | "DGM_Hit"
--- @alias HitEvent string | "OnMelee" | "OnRanged" | "OnWeaponHit" | "OnHit" | "BeforeDamageScaling" | "AfterDamageScaling"
--- @alias HitConditionCallback fun(status:EsvStatusHit, instigator:EsvCharacter, target:EsvCharacter, flags:HitFlags):nil

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
	local index = priority or 100
	while self.HitHooks[hook][event][index] do
		index = index + 1
	end
    self.HitHooks[hook][event][index] = {
        Name = name,
        Handle = func
    }
end

--- @param hook HookEvent
--- @param event HitEvent
function HitManager:TriggerHitListeners(hook, event, ...)
    local params = {...}
    if self.HitHooks[hook] then
        for i,j in pairs(self.HitHooks[hook][event]) do
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

	if ((skill and skill.Name == "Projectile_Talent_Unstable") and IsTagged(instigator.MyGuid, "LX_UNSTABLE_COOLDOWN") == 1) 
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
		HitManager:TriggerHitListeners("DGM_Hit", "AfterDamageScaling", hit, instigator, target, flags)
		HitManager:InitiatePassingDamage(target, hit.Hit.DamageList:ToTable())
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
	HitManager:TriggerHitListeners("DGM_Hit", "BeforeDamageScaling", hit, instigator, target, flags)
	for i,element in pairs(damageTable) do
		local multiplier = 1 + attacker.DamageBonus/100
		if element.DamageType == "Water" and instigator.Stats.TALENT_IceKing then
			multiplier = multiplier + 1/Ext.ExtraData.DGM_IceKingDamageBonus
		elseif element.DamageType == "Corrosive" or element.DamageType == "Magic" then
			element.Amount = element.Amount * Ext.ExtraData.DGM_ArmourReductionMultiplier / 100
		end
		element.Amount = (element.Amount * multiplier) * attacker.GlobalMultiplier + math.random(0,1) -- Range somewhat of a fix
		HitHelpers.HitAddDamage(hit.Hit, target, instigator, tostring(element.DamageType), math.floor(element.Amount))
		-- NRD_HitStatusAddDamage(target.MyGuid, handle, element.DamageType, element.Amount)
	end
	HitHelpers.HitRecalculateAbsorb(hit.Hit, target)
	HitHelpers.HitRecalculateLifesteal(hit.Hit, instigator)
	HitManager:TriggerHitListeners("DGM_Hit", "AfterDamageScaling", hit, instigator, target, flags)
	HitManager:InitiatePassingDamage(target, hit.Hit.DamageList:ToTable())
	-- HitManager:ShieldStatusesAbsorbDamage(target, hit.Hit.DamageList)
end

-- Ext.RegisterOsirisListener("NRD_OnStatusAttempt", 4, "before", HitCatch)
Ext.RegisterOsirisListener("NRD_OnHit", 4, "before", DamageControl)

--- Fix the original DoHit that is
--- @param hit HitRequest
--- @param damageList DamageList
--- @param statusBonusDmgTypes DamageList
--- @param hitType string HitType enumeration
--- @param target StatCharacter
--- @param attacker StatCharacter
--- @param ctx HitCalculationContext
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

---@param attacker CDivinityStatsCharacter
---@param target CDivinityStatsCharacter
local function DGM_HitChanceFormula(attacker, target)
	local hitChance = attacker.Accuracy - target.Dodge + attacker.ChanceToHitBoost
    -- Make sure that we return a value in the range (0% .. 100%)
	hitChance = math.max(math.min(hitChance, 100), 0)
    return hitChance
end

--- @param e LuaGetHitChanceEvent
Ext.Events.GetHitChance:Subscribe(function(e)
	DGM_HitChanceFormula(e.Attacker, e.Target)
end)

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

local GladiatorTargets = {}

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
			if not e.Handled then
				e.Handled = true
			end
			Game.Math.ComputeCharacterHit(e.Target, e.Attacker, e.Weapon, e.DamageList, e.HitType, e.NoHitRoll, e.ForceReduceDurability, e.Hit, e.AlwaysBackstab, e.HighGround, e.CriticalRoll)
		end
	--- Gladiator
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
		Osi.ProcObjectTimer(e.Attacker.Character.MyGuid, "LX_GladiatorFollowFix", 1000)
	--- Source Target hit chance roll fix
	elseif e.Attacker and e.SkillProperties and string.match(e.SkillProperties.Name, "Target_") == "Target_" then
		local skill = string.gsub(e.SkillProperties.Name, "_SkillProperties", "")
		local stat = Ext.Stats.Get(skill)
		if stat['Magic Cost'] > 0 and stat.UseWeaponDamage == "Yes" then
			e.NoHitRoll = false
			local isDodged = Game.Math.CalculateHitChance(e.Attacker, e.Target) < math.random(0, 99)
			local hit = Game.Math.ComputeCharacterHit(e.Target, e.Attacker, e.Weapon, e.DamageList, e.HitType, e.NoHitRoll, e.ForceReduceDurability, e.Hit, e.AlwaysBackstab, e.HighGround, e.CriticalRoll) ---@type EsvStatusHit
			if isDodged then
				e.Hit.Missed = true
				e.Hit.Hit = false
				e.Hit.DontCreateBloodSurface = true
			else
				e.Hit.Hit = true
			end
			if not e.Handled and hit then
				e.Handled = true
			end
		end
	end
	if IsTagged(e.Target.MyGuid, "LX_IsCounterAttacking") == 1 then
		ClearTag(e.Target.MyGuid, "LX_IsCounterAttacking")
	end
end)

---@param e EsvLuaStatusHitEnterEvent
Ext.Events.StatusHitEnter:Subscribe(function(e)
	--- Gladiator
	local target = Ext.Entity.GetCharacter(e.Context.TargetHandle)
	local attacker = Ext.Entity.GetCharacter(e.Context.AttackerHandle)
	if target.Stats.TALENT_Gladiator and (e.Hit.Hit.HitWithWeapon) and not Game.Math.IsRangedWeapon(attacker.Stats.MainWeapon) and target.Stats:GetItemBySlot("Shield") and not e.Hit.Hit.CounterAttack and IsTagged(target.MyGuid, "LX_IsCounterAttacking") == 0 and e.Hit.SkillId ~= "Target_LX_GladiatorHit_-1" and not (e.Hit.Hit.Dodged or e.Hit.Hit.Missed) then
		local counterAttacked = Helpers.HasCounterAttacked(target)
		if not counterAttacked and GetDistanceTo(target.MyGuid, attacker.MyGuid) <= 5.0 then
			GladiatorTargets[target.MyGuid] = attacker.MyGuid
			SetTag(attacker.MyGuid, "LX_IsCounterAttacking")
			Osi.ProcObjectTimer(target.MyGuid, "LX_GladiatorDelay", 30)
		end
	end
end)

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
	if event == "LX_GladiatorDelay" and CharacterIsIncapacitated(character) ~= 1 then
		Helpers.SetHasCounterAttacked(Ext.ServerEntity.GetCharacter(character), true)
		CharacterUseSkill(character, "Target_LX_GladiatorHit", GladiatorTargets[character], 1, 1, 1)
		GladiatorTargets[character] = nil
	end
end)

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
	if event == "LX_GladiatorFollowFix" then
		PlayAnimation(character, "", "")
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

	--- WARMUP application
	if (flags.Missed or flags.Dodged) and not target:GetStatus("EVADING") and Helpers.IsCharacter(instigator) then
		ApplyWarmup(instigator)
	end

	--- Aimed Shot
	if flags.IsWeaponAttack and instigator.Stats.MainWeapon.WeaponType == "Crossbow" then
        local aimedShot = FindStatus(instigator, "DMG_AimedShot")
        if aimedShot then RemoveStatus(instigator.MyGuid, aimedShot) end
    end
end, 50)

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
--- @param instigatorDGMStats table
HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "DGM_AbsorbShields", function(hit, instigator, target, flags)
	--- Absorb shields
	AbsorbShieldProcessDamage(target, instigator, hit)
	--- Skill damage cap
	if hit.SkillId ~= "" then
		local stat = Ext.Stats.Get(string.sub(hit.SkillId, 1, string.len(hit.SkillId)-3))
		if stat.VP_DamageCapValue ~= 0 then
			local cap = stat.VP_DamageCapValue / 100 * Helpers.GetScaledValue(stat.VP_DamageCapScaling, target, instigator)
			local damageTable = hit.Hit.DamageList:ToTable()
			local totalAmount = 0
			for i,element in pairs(damageTable) do
				totalAmount = totalAmount + element.Amount
				if totalAmount > cap then
					HitHelpers.HitAddDamage(hit, target, instigator, tostring(element.DamageType), cap - totalAmount)
					totalAmount = cap
				end
			end
		end
	end
	--- Consecutive hit damage multiplier
	if hit.SkillId ~= "" then
		local stat = Ext.Stats.Get(string.sub(hit.SkillId, 1, string.len(hit.SkillId)-3))
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