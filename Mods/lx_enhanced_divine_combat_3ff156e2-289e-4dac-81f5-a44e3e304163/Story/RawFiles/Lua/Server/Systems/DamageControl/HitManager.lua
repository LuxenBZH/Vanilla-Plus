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
--- @param dmgList table
local function TriggerCorrogicResistanceStrip(target, dmgListNew)
	local character = Ext.GetCharacter(target)
	local dmgList = {
		Magic = 0,
		Corrosive = 0
	}
	for i,j in pairs(dmgListNew) do
		dmgList[j.DamageType] = (dmgList[j.DamageType] or 0) + j.Amount
	end
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

---@param target Guid
---@param instigator Guid
---@param hitDamage number
---@param handle number
local function DamageControl(target, instigator, hitDamage, handle)
	local target = Ext.ServerEntity.GetGameObject(target) --- @type EsvItem | EsvCharacter
	-- if instigator == 'NULL_00000000-0000-0000-0000-000000000000' then return end
	local instigator = instigator ~= "NULL_00000000-0000-0000-0000-000000000000" and Ext.ServerEntity.GetGameObject(instigator) or {MyGuid = "NULL_00000000-0000-0000-0000-000000000000"} --- @type EsvCharacter|EsvItem
	-- if getmetatable(instigator) ~= "esv::Character" then
	-- 	return
	-- end
	local hit = Ext.ServerEntity.GetStatus(target.MyGuid, handle) --- @type EsvStatusHit
	local skill = hit.SkillId ~= "" and Ext.Stats.Get(hit.SkillId:gsub("(.*).+-1$", "%1")) or nil --- @type StatEntrySkillData | nil
	local skillId = skill and skill.Name or nil
	local flags = HitFlags:Create()
    flags.Dodged = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "Dodged") == 1
    flags.Missed = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "Missed") == 1
    flags.Critical = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "CriticalHit") == 1
    flags.Backstab = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "Backstab") == 1
    flags.DamageSourceType = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "DamageSourceType")
    flags.Blocked = NRD_StatusGetInt(target.MyGuid, hit.StatusHandle, "Blocked") == 1
    flags.IsDirectAttack = hit.DamageSourceType == "Attack" or hit.SkillId ~= ""
	flags.FromReflection = NRD_StatusGetInt(target.MyGuid, handle, "Reflection") == 1
    flags.IsWeaponAttack = hit.Hit.HitWithWeapon or (hit.DamageSourceType == "Attack" and Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon)) --- EsvHit.HitWithWeapon returns False for ranged weapons
	flags.IsStatusDamage = NRD_StatusGetInt(target.MyGuid, handle, "DoT") == 1

	if ((skill and skill.Name == "Projectile_Talent_Unstable") and IsTagged(instigator.MyGuid, "LX_UNSTABLE_COOLDOWN") == 1) 
	 or flags.Blocked then
		return
	end
	if hit.HitReason == 1 and hit.SkillId == ""
	 and target:GetStatus("SHACKLES_OF_PAIN")
	 and Ext.ServerEntity.GetGameObject(target:GetStatus("SHACKLES_OF_PAIN").StatusSourceHandle).MyGuid == instigator.MyGuid then
		flags.IsFromShackles = true
	end

	--- CONSUME status multiplier
	if target.UserVars.LX_StatusConsumeMultiplier and target.UserVars.LX_StatusConsumeMultiplier ~= 0 then
		if instigator.MyGuid == Helpers.NullGUID then
			HitHelpers.HitMultiplyDamage(hit.Hit, target, target, target.UserVars.LX_StatusConsumeMultiplier)
		else
			HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, target.UserVars.LX_StatusConsumeMultiplier)
		end
		target.UserVars.LX_StatusConsumeMultiplier = nil
	end

	-- Don't scale damage from surfaces, GM, scriting , reflection, or if the damage type doesn't fit scaling
	if flags.FromReflection
	 or (flags.DamageSourceType > 0 and flags.DamageSourceType < 4)
	 or (flags.DamageSourceType == 0 and hit.SkillId == "" and Helpers.IsCharacter(target))
	 or (skill and (skill.Damage ~= "AverageLevelDamge" and skill.Damage ~= "BaseLevelDamage"))  then
		HitManager:TriggerHitListeners("DGM_Hit", "AfterDamageScaling", hit, instigator, target, flags, skillId)
		HitManager:InitiatePassingDamage(target, hit.Hit.DamageList:ToTable())
        return
	end

    -- Trace Guardian Angel statuses
    if Helpers.IsCharacter(target) then HitManager:TagCharacterWithSharedDamage(target) end

	if instigator.MyGuid == 'NULL_00000000-0000-0000-0000-000000000000' then return end

    -- Bonuses
	local attacker = Data.Math.GetCharacterComputedDamageBonus(instigator, target, flags, skill, skillId)

    if (skill and skill.Name == "Projectile_Talent_Unstable") or IsTagged(target.MyGuid, "DGM_GuardianAngelProtector") == 1 or flags.IsFromShackles then
		ClearTag(target.MyGuid, "DGM_GuardianAngelProtector")
		attacker.DamageBonus = 0
		attacker.GlobalMultiplier = 1
	end
	-- _VPrint("General multiplier:", "HitManager", attacker.DamageBonus, attacker.GlobalMultiplier)
	HitManager:TriggerHitListeners("DGM_Hit", "BeforeDamageScaling", hit, instigator, target, flags, skillId)
	local damageTable = hit.Hit.DamageList:ToTable()
	-- _DS(damageTable)
	NRD_HitStatusClearAllDamage(target.MyGuid, handle)
	for i,element in pairs(damageTable) do
		local multiplier = 1 + attacker.DamageBonus/100
		if element.DamageType == "Water" and instigator.Stats.TALENT_IceKing then
			multiplier = multiplier + 1/Ext.ExtraData.DGM_IceKingDamageBonus
		elseif element.DamageType == "Corrosive" or element.DamageType == "Magic" then
			element.Amount = element.Amount * Ext.ExtraData.DGM_ArmourReductionMultiplier / 100
		end
		local schoolMultiplier = (instigator and Data.DamageTypeToAbility[element.DamageType]) and Game.Math.GetDamageBoostByType(instigator.Stats, element.DamageType) or 0
		element.Amount = (element.Amount * (multiplier + schoolMultiplier)) * attacker.GlobalMultiplier + math.random(0,1) -- Range somewhat of a fix
		-- _VPrint("Total Multiplier for", "HitManager", element.DamageType, ": ", tostring((multiplier + schoolMultiplier) * attacker.GlobalMultiplier), element.Amount)
		HitHelpers.HitAddDamage(hit.Hit, target, instigator, tostring(element.DamageType), math.floor(element.Amount))
		-- NRD_HitStatusAddDamage(target.MyGuid, handle, element.DamageType, element.Amount)
	end
	HitHelpers.HitRecalculateAbsorb(hit.Hit, target)
	HitHelpers.HitRecalculateLifesteal(hit.Hit, instigator)
	HitManager:TriggerHitListeners("DGM_Hit", "AfterDamageScaling", hit, instigator, target, flags, skillId)
	if Ext.ExtraData.DGM_Corrogic == 1 then
		TriggerCorrogicResistanceStrip(target.MyGuid, hit.Hit.DamageList:ToTable())
	end
	HitManager:InitiatePassingDamage(target, hit.Hit.DamageList:ToTable())
	-- HitManager:ShieldStatusesAbsorbDamage(target, hit.Hit.DamageList)
end

Ext.Osiris.RegisterListener("NRD_OnHit", 4, "before", DamageControl)