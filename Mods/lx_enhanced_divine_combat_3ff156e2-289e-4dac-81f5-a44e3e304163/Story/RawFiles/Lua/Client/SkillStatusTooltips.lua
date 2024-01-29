

local DamageSourceCalcTable = {
	BaseLevelWeaponDamage = function(attacker, target, level)
		return Ext.Round(Game.Math.GetLevelScaledWeaponDamage(level))
	end,
    BaseLevelDamage = function (attacker, target, level)
        return Ext.Round(Game.Math.GetLevelScaledDamage(level))
    end,
    AverageLevelDamge = function (attacker, target, level)
        return Ext.Round(Game.Math.GetAverageLevelDamage(level))
    end,
    MonsterWeaponDamage = function (attacker, target, level)
        return Ext.Round(Game.Math.GetLevelScaledMonsterWeaponDamage(level))
    end,
    SourceMaximumVitality = function (attacker, target, level)
        return attacker.MaxVitality
    end,
    SourceMaximumPhysicalArmor = function (attacker, target, level)
        return attacker.MaxArmor
    end,
    SourceMaximumMagicArmor = function (attacker, target, level)
        return attacker.MaxMagicArmor
    end,
    SourceCurrentVitality = function (attacker, target, level)
        return attacker.CurrentVitality
    end,
    SourceCurrentPhysicalArmor = function (attacker, target, level)
        return attacker.CurrentArmor
    end,
    SourceCurrentMagicArmor = function (attacker, target, level)
        return attacker.CurrentMagicArmor
    end,
    SourceShieldPhysicalArmor = function (attacker, target, level)
        return Ext.Round(Game.Math.GetShieldPhysicalArmor(attacker))
    end,
    TargetMaximumVitality = function (attacker, target, level)
        return target.MaxVitality
    end,
    TargetMaximumPhysicalArmor = function (attacker, target, level)
        return target.MaxArmor
    end,
    TargetMaximumMagicArmor = function (attacker, target, level)
        return target.MaxMagicArmor
    end,
    TargetCurrentVitality = function (attacker, target, level)
        return target.CurrentVitality
    end,
    TargetCurrentPhysicalArmor = function (attacker, target, level)
        return target.CurrentArmor
    end,
    TargetCurrentMagicArmor = function (attacker, target, level)
        return target.CurrentMagicArmor
    end
}

---@param skillDamageType string
---@param attacker StatCharacter
---@param target StatCharacter
---@param level integer
function CustomCalculateBaseDamage(skillDamageType, attacker, target, level)
    return DamageSourceCalcTable[skillDamageType](attacker, target, level)
end

---@param character CDivinityStatsCharacter
---@param skill StatEntrySkillData
function CustomGetSkillDamageRange(character, skill, mainWeapon, offHand, fromExpandedTooltip)
    skill = Ext.Stats.Get(skill.Name)
    local damageMultiplier = skill['Damage Multiplier'] * 0.01

    ---@type string
    local isWeaponEntry = false
    if currentParam <= GetTableSize(paramsOrder) and not fromExpandedTooltip then
        if skillParams[paramsOrder[currentParam]]:starts("Skill:") then
            local skillName = skillParams[paramsOrder[currentParam]]:gsub("Skill:", ""):gsub(":.*", "")
            skill = Ext.GetStat(skillName)
            if skill == nil then return end
        elseif skillParams[paramsOrder[currentParam]]:starts("Weapon:") then
            isWeaponEntry = true
        end
        if skillParams[paramsOrder[currentParam]]:gsub(".*:", "") ~= "Damage" then return end
    end

	if skill.UseWeaponDamage == "Yes" then
		local mainWeapon = character.MainWeapon
        local mainDamageRange = Game.Math.CalculateWeaponScaledDamageRanges(character, mainWeapon)
        -- Ext.Dump({Game.Math.ComputeBaseWeaponDamage(mainWeapon)})
		local offHandWeapon = character.OffHandWeapon

        if offHandWeapon ~= nil and Game.Math.IsRangedWeapon(mainWeapon) == Game.Math.IsRangedWeapon(offHandWeapon) then
            local offHandDamageRange = Game.Math.CalculateWeaponScaledDamageRanges(character, offHandWeapon)

            local dualWieldPenalty = Ext.ExtraData.DualWieldingDamagePenalty
            for damageType, range in pairs(offHandDamageRange) do
                local min = math.ceil(range.Min * dualWieldPenalty)
                local max = math.ceil(range.Max * dualWieldPenalty)
                local range = mainDamageRange[damageType]
                if mainDamageRange[damageType] ~= nil then
                    range.Min = range.Min + min
                    range.Max = range.Max + max
                else
                    mainDamageRange[damageType] = {Min = min, Max = max}
                end
            end
        end

        -- local globalMult = 1 + (character.Strength-10) * (Ext.ExtraData.DGM_StrengthGlobalBonus*0.01 + Ext.ExtraData.DGM_StrengthWeaponBonus*0.01) +
        --     (character.Finesse-10) * (Ext.ExtraData.DGM_FinesseGlobalBonus*0.01) +
        --     (character.Intelligence-10) * (Ext.ExtraData.DGM_IntelligenceGlobalBonus*0.01 + Ext.ExtraData.DGM_IntelligenceSkillBonus*0.01)

        local boosts = Data.Math.GetCharacterComputedDamageBonus(character.Character, nil, {}, skill)

        local globalMult = boosts.DamageBonus / 100
        
        for damageType, range in pairs(mainDamageRange) do
            range.Min = Ext.Utils.Round(range.Min * (damageMultiplier) * (globalMult + Game.Math.GetDamageBoostByType(character, damageType)))
            range.Max = Ext.Utils.Round(range.Max * (damageMultiplier) * (globalMult + Game.Math.GetDamageBoostByType(character, damageType)))
        end

        local damageType = skill.DamageType
        if damageType ~= "None" and damageType ~= "Sentinel" then
            local min, max = 0, 0
            for damageType, range in pairs(mainDamageRange) do
                min = min + range.Min
                max = max + range.Max
				
            end

            mainDamageRange = {}
            mainDamageRange[damageType] = {min, max}
        end
		--Ext.Print("Use Weapon")
        return mainDamageRange
	else
		local skillDamageType = skill.Damage
        local damageType = skill.DamageType
        local damageRange = skill["Damage Range"]
		if isWeaponEntry then
			local damageConvert = {
				"BaseLevelWeaponDamage",
				"AverageLevelDamge",
				"MonsterWeaponDamage"
			}
            -- local weaponStat = desc:gsub(".*Weapon:", ""):gsub(":Damage.*", "")
            local weaponStat = skillParams[paramsOrder[currentParam]]:gsub("Weapon:", ""):gsub(":.*", "")
            weaponSkill = true
			local weaponDamage = Ext.StatGetAttribute(weaponStat, "Damage")
			if weaponDamage > 2 then return end
			skillDamageType = damageConvert[tonumber(weaponDamage)+1]
			damageType = Ext.StatGetAttribute(weaponStat, "Damage Type")
			damageMultiplier = Ext.StatGetAttribute(weaponStat, "DamageFromBase")*0.01
			damageRange = Ext.StatGetAttribute(weaponStat, "Damage Range")
        end
        
        if damageMultiplier <= 0 then
            return {}
        end

        local level = character.Level
		
        local flags = {
            Dodged = false,
            Missed = false,
            Critical = false,
            Backstab = false,
            DamageSourceType = false,
            Blocked = false,
            IsDirectAttack = false,
            IsWeaponAttack = false,
            IsStatusDamage = false,
            FromReflection = false,
        } ---@type HitFlags

		
        if skill.StatsDescriptionParams:find("Weapon:") ~= nil and not fromExpandedTooltip then
			local weaponStat = skillParams[paramsOrder[currentParam]]:gsub("Weapon:", ""):gsub(":.*", "")
            if tooltipStatusDmgHelper[weaponStat] then
                flags.IsStatusDamage = true
            end
		end
		--Ext.Print("Global mult", globalMult, skillDamageType)
        local globalMult = (Data.Math.GetCharacterComputedDamageBonus(character.Character, nil, flags, skill).DamageBonus/100)
        local damageTypeBoost = Game.Math.GetDamageBoostByType(character, damageType)
        globalMult = globalMult + damageTypeBoost
        local baseDamage = CustomCalculateBaseDamage(skillDamageType, character, 0, level) * damageMultiplier * globalMult
        -- _P(CustomCalculateBaseDamage(skillDamageType, character, 0, level), damageMultiplier, globalMult)
        damageRange = damageRange * baseDamage * 0.005
        
        local damageBoost = 1.0 + (character.DamageBoost / 100.0)
        local damageRanges = {}
        damageRanges[damageType] = {
            Min = math.ceil(math.ceil(Ext.Round(baseDamage - damageRange) * damageBoost)),
            Max = math.ceil(math.ceil(Ext.Round(baseDamage + damageRange) * damageBoost) + (globalMult))
        }
        return damageRanges
    end
end

-- Odinblade compatibility
Game.Math.GetSkillDamageRange = CustomGetSkillDamageRange

local SkillGetDescriptionParamForbidden = {"Projectile_OdinHUN_HuntersTrap", "Target_ElementalArrowheads", "Projectile_OdinHUN_TheHunt"}

---@param skill StatEntrySkillData
---@param character StatCharacter
---@param isFromItem boolean
---@param par string
local function SkillGetDescriptionParam(skill, character, isFromItem, par, ...)
	-- Ext.Print(skill.Damage, skill.DamageMultiplier)
	-- Ext.Print("BaseLevelDamage:",Game.Math.GetLevelScaledDamage(character.Level))
	-- Ext.Print("AverageLevelDamage:",Game.Math.GetAverageLevelDamage(character.Level))
	-- Ext.Print("LevelScaledMonsterWeaponDamage:", Game.Math.GetLevelScaledMonsterWeaponDamage(character.Level))
    -- Ext.Print("LevelScaledWeaponDamage:", Game.Math.GetLevelScaledWeaponDamage(character.Level))
    for _, name in pairs(SkillGetDescriptionParamForbidden) do
        if name == skill.Name then
            return nil
        end
    end
    local additional = {...}

    if currentParam > GetTableSize(paramsOrder) then 
        currentParam = 1
    end
    if lastSkill ~= skill.Name then
        lastSkill = skill.Name
        currentParam = 1
        skillParams = {}
        for i,param in pairs(skill.StatsDescriptionParams:split(";")) do
            if param:starts("Damage") or (param:starts("Skill") and param:gsub(".*:", "") == "Damage") or (param:starts("Weapon") and param:gsub(".*:", "") == "Damage") then
                skillParams[i] = param
            else
                skillParams[i] = ""
            end
        end
        local index = 1
        paramsOrder = {}
        for nb in Ext.GetTranslatedStringFromKey(skill.Description):gmatch("%[.%]") do
            paramsOrder[index] = tonumber(nb:sub(2, 2))
            index = index + 1
        end
    end
    if skillParams[paramsOrder[currentParam]] == "" or skillParams[paramsOrder[currentParam]] == nil then
        currentParam = currentParam + 1
        return 
    end

	local desc = skill.StatsDescriptionParams
    if par == "Damage" or par == "Skill" or par == "Weapon" then
        if par == "Skill" then skill = Ext.GetStat(additional[1], character.Level)
        else skill = Ext.GetStat(skill.Name, character.Level) end
        -- Ext.Print(par, skill.Name, skill.DamageType)
		if skill.Damage ~= "BaseLevelDamage" and skill.Damage ~= "AverageLevelDamge" then return nil end
		local dmg = CustomGetSkillDamageRange(character, skill, character.MainWeapon, character.OffHandWeapon, true)
		local result = ""
		local once = false
        if dmg == nil then return end
        for dmgType, damages in pairs(dmg) do
            if damages.Min == nil then return end
			local minDmg = math.floor(damages.Min)
			local maxDmg = math.floor(damages.Max)
			local color = Helpers.GetDamageColor(dmgType)
			if not once then
				result = result.."<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgType.." damage".."</font>"
				once = true
			else
				result = result.." + ".."<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgType.." damage".."</font>"
			end
        end
        currentParam = currentParam + 1
        return result
	end
	return nil
end

Ext.RegisterListener("SkillGetDescriptionParam", SkillGetDescriptionParam)

---@param status StatsStatusPrototype
---@param statusSource EsvGameObject
---@param character StatCharacter
---@param par string
local function StatusGetDescriptionParam(status, statusSource, character, par)
    if par == "Damage" then
        local dmgStat = Ext.Stats.Get(status.DamageStats, nil, false)
        if statusSource == nil then return end
        local globalMult = 1 + (statusSource.Wits-Ext.ExtraData.AttributeBaseValue) * (Ext.ExtraData.DGM_WitsDotBonus*0.01) --From the overhaul
        local dmg = 0
		if dmgStat.Damage == 1 then
			dmg = Game.Math.GetAverageLevelDamage(statusSource.Level)
		elseif dmgStat.Damage == 0 and dmgStat.BonusWeapon == nil then
			dmg = Game.Math.GetLevelScaledDamage(statusSource.Level)
		else
			dmg = Game.Math.GetLevelScaledWeaponDamage(statusSource.Level)
		end
        dmg = dmg*(dmgStat.DamageFromBase/100)
		local dmgRange = dmg*(dmgStat["Damage Range"])*0.005
        local schoolBonus = 1
        local pass, characterSource = pcall(Ext.ClientEntity.GetCharacter, statusSource.NetID)
        if pass then
            schoolBonus = schoolBonus + Game.Math.GetDamageBoostByType(characterSource.Stats, dmgStat["Damage Type"])
        end
		local minDmg = math.floor(Ext.Utils.Round(dmg - dmgRange)* globalMult * schoolBonus)
        local maxDmg = math.ceil(Ext.Utils.Round(dmg + dmgRange)* globalMult * schoolBonus)
        if maxDmg <= minDmg then maxDmg = maxDmg+1 end
		local color = Helpers.GetDamageColor(dmgStat["Damage Type"])
		return "<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgStat["Damage Type"].." "..Ext.L10N.GetTranslatedString("h9531fd22g6366g4e93g9b08g11763cac0d86", "damage").."</font>"
    elseif par == "HealAmount" then
        local stat = Ext.Stats.Get(status.StatusName, nil, false)
        if stat.HealType == "Qualifier" then
            local computedValue = Data.Math.GetHealScaledWisdomValue(stat, statusSource.Character)
            return "<font color=\"#97FBFF\">"..computedValue.." "..Ext.L10N.GetTranslatedString("h67a4c781g589ag4872g8c46g870e336074bd", "Vitality").."</font>"
        end
    elseif par == "WPN-DamageFromBase" then
        local statEntry = Ext.Stats.Get(Ext.Stats.Get(status.StatsObject.StatsId).BonusWeapon)
        local bonus = Data.Math.GetCharacterComputedDamageBonus(character.Character, nil, {}, Ext.Stats.Get("Target_LX_NormalAttack"))
        local damage = Data.DamageScalingFormulas[tonumber(statEntry.Damage)](character.Level) * (statEntry.DamageFromBase/100) * (bonus.DamageBonus/100+Game.Math.GetDamageBoostByType(character, statEntry["Damage Type"]))*bonus.GlobalMultiplier 
        return Data.Text.GetFormattedDamageRangeText(statEntry["Damage Type"], Ext.Utils.Round(damage*(1-statEntry['Damage Range']/2/100)), Ext.Utils.Round(damage*(1+statEntry['Damage Range']/2/100)))
	end
	return nil
end

Ext.RegisterListener("StatusGetDescriptionParam", StatusGetDescriptionParam)

local DamageTypes = {
    None = 0,
    Physical = 1,
    Piercing = 2,
    Corrosive = 3,
    Magic = 4,
    Chaos = 5,
    Fire = 6,
    Air = 7,
    Water = 8,
    Earth = 9,
    Poison = 10,
    Shadow = 11,
    Sulfuric = 12,
    Sentinel = 13
}