Ext.Require("LXDGM_StatsPatching.lua")
Ext.Require("LXDGM_Helpers.lua")
Ext.Require("LXDGM_Tooltips.lua")

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
local function CalculateBaseDamage(skillDamageType, attacker, target, level)
    return DamageSourceCalcTable[skillDamageType](attacker, target, level)
end

---@param character StatCharacter
---@param weapon StatEntryWeapon
-- local function CalculateWeaponDamageRange(character, weapon)
--     local damages, damageBoost = Game.Math.ComputeBaseWeaponDamage(weapon)

--     local abilityBoosts = character.DamageBoost 
--         + Game.Math.ComputeWeaponCombatAbilityBoost(character, weapon)
--         + Game.Math.ComputeWeaponRequirementScaledDamage(character, weapon)
--     abilityBoosts = math.max(abilityBoosts + 100.0, 0.0) / 100.0

--     local boost = 1.0 + damageBoost * 0.01
--     -- if character.NotSneaking then
--         -- boost = boost + Ext.ExtraData['Sneak Damage Multiplier']
--     -- end

--     local ranges = {}
--     for damageType, damage in pairs(damages) do
--         local min = damage.Min * boost * abilityBoosts
-- 		local max = damage.Max * boost * abilityBoosts
-- 		--Ext.Print(min, max)

--         if min > max then
--             max = min
--         end

--         ranges[damageType] = {min, max}
--     end

--     return ranges
-- end

---@param character StatCharacter
---@param skill StatEntrySkillData
local function GetSkillDamageRange(character, skill)
    local desc = skill.StatsDescriptionParams

	--Ext.Print(skill.DamageMultiplier)
    local damageMultiplier = skill['Damage Multiplier'] * 0.01
    if desc:find("Skill:") ~= nil then
        local skillStat = desc:gsub("^[A-z]*:", ""):gsub(":.*", "")
        local skillDamage = Ext.StatGetAttribute(skillStat, "Damage")
        skill.DamageType = Ext.StatGetAttribute(skillStat, "Damage Type")
        damageMultiplier = Ext.StatGetAttribute(skillStat, "Damage Multiplier")*0.01
        skill["Damage Range"] = Ext.StatGetAttribute(skillStat, "Damage Range")
        skill.UseWeaponDamage = Ext.StatGetAttribute(skillStat, "UseWeaponDamage")
    end

    local amplifierMult = 1.0
    if character.MainWeapon.WeaponType == "Staff" then
        amplifierMult = amplifierMult + 0.1
    elseif character.MainWeapon.WeaponType == "Wand" then
        amplifierMult = amplifierMult + 0.025
    end
    if character.OffHandWeapon ~= nil then
        if character.OffHandWeapon.WeaponType == "Wand" then amplifierMult = amplifierMult + 0.025 end
    end

	if skill.UseWeaponDamage == "Yes" then
		local mainWeapon = character.MainWeapon
        local mainDamageRange = Game.Math.CalculateWeaponScaledDamageRanges(character, mainWeapon)
		local offHandWeapon = offHandWeapon or character.OffHandWeapon

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
                    mainDamageRange[damageType] = {min, max}
                end
            end
        end
		
		local globalMult = 1 + (character.Strength-10) * (Ext.ExtraData.DGM_StrengthGlobalBonus*0.01 + Ext.ExtraData.DGM_StrengthWeaponBonus*0.01) +
		(character.Finesse-10) * (Ext.ExtraData.DGM_FinesseGlobalBonus*0.01) +
		(character.Intelligence-10) * (Ext.ExtraData.DGM_IntelligenceGlobalBonus*0.01 + Ext.ExtraData.DGM_IntelligenceSkillBonus*0.01)
        for damageType, range in pairs(mainDamageRange) do
            local min = Ext.Round(range.Min * damageMultiplier * globalMult * amplifierMult)
            local max = Ext.Round(range.Max * damageMultiplier * globalMult * amplifierMult + (globalMult *amplifierMult))
            range.Min = min + math.ceil(min * Game.Math.GetDamageBoostByType(character, damageType))
            range.Max = max + math.ceil(max * Game.Math.GetDamageBoostByType(character, damageType))
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
		local desc = skill.StatsDescriptionParams
		if desc:find("Weapon:") ~= nil then
			local damageConvert = {
				"BaseLevelWeaponDamage",
				"AverageLevelDamge",
				"MonsterWeaponDamage"
			}
			local weaponStat = desc:gsub("^[A-z]*:", ""):gsub(":.*", "")
			local weaponDamage = Ext.StatGetAttribute(weaponStat, "Damage")
			if weaponDamage > 2 then return end
			skillDamageType = damageConvert[tonumber(weaponDamage)+1]
			skill.DamageType = Ext.StatGetAttribute(weaponStat, "Damage Type")
			damageMultiplier = Ext.StatGetAttribute(weaponStat, "DamageFromBase")*0.01
			skill["Damage Range"] = Ext.StatGetAttribute(weaponStat, "Damage Range")
        end
        local damageType = skill.DamageType
        if damageMultiplier <= 0 then
            return {}
        end

        local level = character.Level
        if (level < 0 or skill.OverrideSkillLevel == "Yes") and skill.Level > 0 then
            level = skill.Level
        end
        
        local attrDamageScale
        if skillDamageType == "BaseLevelDamage" or skillDamageType == "AverageLevelDamge" or skillDamageType == "MonsterWeaponDamage" then
            attrDamageScale = Game.Math.GetSkillAttributeDamageScale(skill, character)
        else
            attrDamageScale = 1.0
        end
		--Ext.Print("Damage:", skillDamageType)
		
		local globalMult = 1.0
		
        if skill.StatsDescriptionParams:find("Weapon:") ~= nil  or skill.Name == "Target_TentacleLash" then
            Ext.Print("Strength scaling")
			local weaponStat = skill.StatsDescriptionParams:gsub("^[A-z]*:", ""):gsub(":.*", "")
			globalMult = 1 + (character.Strength-10) * (Ext.ExtraData.DGM_StrengthGlobalBonus*0.01 + Ext.ExtraData.DGM_StrengthWeaponBonus*0.01) +
		(character.Finesse-10) * (Ext.ExtraData.DGM_FinesseGlobalBonus*0.01) +
		(character.Intelligence-10) * (Ext.ExtraData.DGM_IntelligenceGlobalBonus*0.01)
		else
			globalMult = 1 + (character.Strength-10) * (Ext.ExtraData.DGM_StrengthGlobalBonus*0.01) +
		(character.Finesse-10) * (Ext.ExtraData.DGM_FinesseGlobalBonus*0.01) +
		(character.Intelligence-10) * (Ext.ExtraData.DGM_IntelligenceGlobalBonus*0.01 + Ext.ExtraData.DGM_IntelligenceSkillBonus*0.01)
		end
		--Ext.Print("Global mult", globalMult, skillDamageType)
		
        local baseDamage = CalculateBaseDamage(skillDamageType, character, 0, level) * attrDamageScale * damageMultiplier * globalMult
        local damageRange = skill['Damage Range'] * baseDamage * 0.005

        local damageType = skill.DamageType
        local damageTypeBoost = 1.0 + Game.Math.GetDamageBoostByType(character, damageType)
        local damageBoost = 1.0 + (character.DamageBoost / 100.0)
        local damageRanges = {}
        damageRanges[damageType] = {
            Min = math.ceil(math.ceil(Ext.Round(baseDamage - damageRange) * damageBoost) * damageTypeBoost * amplifierMult),
            Max = math.ceil(math.ceil(Ext.Round(baseDamage + damageRange) * damageBoost) * damageTypeBoost * amplifierMult + (globalMult * amplifierMult))
        }
        return damageRanges
    end
end

---@param dmgType string
local function getDamageColor(dmgType)
	local colorCode = ""
	local types = {}
	types["Physical"]="'#A8A8A8'"
	types["Corrosive"]="'#454545'"
	types["Magic"]="'#7F00FF'"
	types["Fire"]="'#FE6E27'"
	types["Water"]="'#4197E2'"
	types["Earth"]="'#7F3D00'"
	types["Poison"]="'#65C900'"
	types["Air"]="'#7D71D9'"
	types["Shadow"]="'#797980'"
	types["Piercing"]="'#C80030'"
	
	for t,code in pairs(types) do
		if dmgType == t then return code end
	end
	return "'#A8A8A8'"
end

---@param status EsvStatus
---@param statusSource EsvGameObject
---@param character StatCharacter
---@param par string
local function StatusGetDescriptionParam(status, statusSource, character, par)
    if par == "Damage" then
        local dmgStat = Ext.GetStat(status.DamageStats)
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
		local minDmg = math.floor(Ext.Round(dmg - dmgRange)* globalMult)
        local maxDmg = math.ceil(Ext.Round(dmg + dmgRange)* globalMult)
        if maxDmg <= minDmg then maxDmg = maxDmg+1 end
		local color = getDamageColor(dmgStat["Damage Type"])
		return "<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgStat["Damage Type"].." damage".."</font>"
	end
	return nil
end

-- Odinblade compatibility
Game.Math.GetSkillDamageRange = GetSkillDamageRange

local SkillGetDescriptionParamForbidden = {"Projectile_OdinHUN_HuntersTrap", "Target_ElementalArrowheads", "Projectile_OdinHUN_TheHunt"}

---@param skill StatEntrySkillData
---@param character StatCharacter
---@param isFromItem boolean
---@param par string
local function SkillGetDescriptionParam(skill, character, isFromItem, par)
	--Ext.Print(skill.Damage, skill.DamageMultiplier)
	-- Ext.Print("BaseLevelDamage:",Game.Math.GetLevelScaledDamage(character.Level))
	-- Ext.Print("AverageLevelDamage:",Game.Math.GetAverageLevelDamage(character.Level))
	-- Ext.Print("LevelScaledMonsterWeaponDamage:", Game.Math.GetLevelScaledMonsterWeaponDamage(character.Level))
    -- Ext.Print("LevelScaledWeaponDamage:", Game.Math.GetLevelScaledWeaponDamage(character.Level))
    for _, name in pairs(SkillGetDescriptionParamForbidden) do
        if name == skill.Name then
            return nil
        end
    end

	local pass = false
	local desc = skill.StatsDescriptionParams
	if desc:find("Weapon:") ~= nil or desc:find("Skill:") then
		pass = true
	end
    if par == "Damage" or pass then
		if skill.Damage ~= "BaseLevelDamage" and skill.Damage ~= "AverageLevelDamge" then return nil end
		local dmg = GetSkillDamageRange(character, skill)
		local result = ""
		local once = false
		
        for dmgType, damages in pairs(dmg) do
            if damages.Min == nil then return end
			local minDmg = math.floor(damages.Min)
			local maxDmg = math.floor(damages.Max)
			local color = getDamageColor(dmgType)
			if not once then
				result = result.."<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgType.." damage".."</font>"
				once = true
			else
				result = result.." + ".."<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgType.." damage".."</font>"
			end
        end
        return result
	end
	return nil
end

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
    Shadow = 11
}

------ UI Values

---@param ui UIObject
---@param call string
---@param state any
local function changeDamageValue(ui, call, state)

    if ui:GetValue("secStat_array", "string", 2) == nil then return end
    
    local strength = ui:GetValue("primStat_array", "string", 2):gsub('<font color="#00547F">', ""):gsub("</font>", "")
    strength = tonumber(strength) - Ext.ExtraData.AttributeBaseValue
    local finesse = ui:GetValue("primStat_array", "string", 6):gsub('<font color="#00547F">', ""):gsub("</font>", "")
    finesse = tonumber(finesse)  - Ext.ExtraData.AttributeBaseValue
    local intelligence = ui:GetValue("primStat_array", "string", 10):gsub('<font color="#00547F">', ""):gsub("</font>", "")
    intelligence = tonumber(intelligence) - Ext.ExtraData.AttributeBaseValue
    
    local damage = ui:GetValue("secStat_array", "string", 24)
    
    local minDamage = damage:gsub(" - .*", "")
    local maxDamage = damage:gsub(".* - ", "")
    local globalMult = 100 + strength * Ext.ExtraData.DGM_StrengthGlobalBonus + strength * Ext.ExtraData.DGM_StrengthWeaponBonus +
        finesse * Ext.ExtraData.DGM_FinesseGlobalBonus + intelligence * Ext.ExtraData.DGM_IntelligenceGlobalBonus

    minDamage = math.floor(tonumber(minDamage) * globalMult * 0.01)
    maxDamage = math.floor(tonumber(maxDamage) * globalMult * 0.01)

    ui:SetValue("secStat_array", minDamage.." - "..maxDamage, 24)
end

---@param ui UIObject
---@param call string
---@param state any
local function sheetButtonPressed(ui, call, state)
    local char = Ext.GetCharacter(Ext.DoubleToHandle(ui:GetValue("charHandle", "number")))
    Ext.PostMessageToServer("DGM_UpdateCharacter", tostring(char.NetID))
end

local function DGM_SetupUI()
    local charSheet = Ext.GetBuiltinUI("Public/Game/GUI/characterSheet.swf")
    Ext.RegisterUIInvokeListener(charSheet, "updateArraySystem", changeDamageValue)
    -- Overhaul bonus refresh on buttons click
    Ext.RegisterUICall(charSheet, "minusStat", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "plusStat", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "minLevel", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "plusLevel", sheetButtonPressed)
end

Ext.RegisterListener("SessionLoaded", DGM_SetupUI)
Ext.RegisterListener("SkillGetDescriptionParam", SkillGetDescriptionParam)
Ext.RegisterListener("StatusGetDescriptionParam", StatusGetDescriptionParam)

---@param attacker EsvCharacter
---@param target EsvCharacter
local function DGM_HitChanceFormula(attacker, target)
	local hitChance = attacker.Accuracy - target.Dodge + attacker.ChanceToHitBoost
    -- Make sure that we return a value in the range (0% .. 100%)
	hitChance = math.max(math.min(hitChance, 100), 0)
    return hitChance
end

Ext.RegisterListener("GetHitChance", DGM_HitChanceFormula)
