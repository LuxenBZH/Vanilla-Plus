Ext.Require("NRD_SkillMath.lua")

local function CalculateWeaponDamageRange(character, weapon)
    local damages, damageBoost = Game.Math.ComputeBaseWeaponDamage(weapon)

    local abilityBoosts = character.DamageBoost 
        + Game.Math.ComputeWeaponCombatAbilityBoost(character, weapon)
        + Game.Math.ComputeWeaponRequirementScaledDamage(character, weapon)
    abilityBoosts = math.max(abilityBoosts + 100.0, 0.0) / 100.0

    local boost = 1.0 + damageBoost * 0.01
    -- if character.NotSneaking then
        -- boost = boost + Ext.ExtraData['Sneak Damage Multiplier']
    -- end

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

local function GetSkillDamageRange(character, skill)
    local damageMultiplier = skill['Damage Multiplier'] * 0.01

    if skill.UseWeaponDamage == "Yes" then
        local mainWeapon = character.MainWeapon
        local mainDamageRange = CalculateWeaponDamageRange(character, mainWeapon)
        local offHandWeapon = character.OffHandWeapon

        if offHandWeapon ~= nil and IsRangedWeapon(mainWeapon) == IsRangedWeapon(offHandWeapon) then
            local offHandDamageRange = CalculateWeaponDamageRange(character, offHandWeapon)

            local dualWieldPenalty = Ext.ExtraData.DualWieldingDamagePenalty
            for damageType, range in pairs(offHandDamageRange) do
                local min = range[1] * dualWieldPenalty
                local max = range[2] * dualWieldPenalty
                if mainDamageRange[damageType] ~= nil then
                    mainDamageRange[damageType][1] = mainDamageRange[damageType][1] + min
                    mainDamageRange[damageType][2] = mainDamageRange[damageType][2] + max
                else
                    mainDamageRange[damageType] = {min, max}
                end
            end
        end
		
		local globalMult = 1 + (character.Strength-10) * 0.06 + (character.Finesse-10) * 0.03 + (character.Intelligence-10) * 0.06
        for damageType, range in pairs(mainDamageRange) do
            local min = Ext.Round(range[1] * damageMultiplier * globalMult)
            local max = Ext.Round(range[2] * damageMultiplier * globalMult)
            range[1] = min + math.ceil(min * Game.Math.GetDamageBoostByType(character, damageType))
            range[2] = max + math.ceil(max * Game.Math.GetDamageBoostByType(character, damageType))
        end

        local damageType = skill.DamageType
        if damageType ~= "None" and damageType ~= "Sentinel" then
            local min, max = 0, 0
            for damageType, range in pairs(mainDamageRange) do
                min = min + range[1]
                max = max + range[2]
				
            end

            mainDamageRange = {}
            mainDamageRange[damageType] = {min, max}
        end
		Ext.Print("Use Weapon")
        return mainDamageRange
    else
        local damageType = skill.DamageType
        if damageMultiplier <= 0 then
            return {}
        end

        local level = character.Level
        if (level < 0 or skill.OverrideSkillLevel == "Yes") and skill.Level > 0 then
            level = skill.Level
        end

        local skillDamageType = skill.Damage
        local attrDamageScale
        if skillDamageType == "BaseLevelDamage" or skillDamageType == "AverageLevelDamge" then
            attrDamageScale = Game.Math.GetSkillAttributeDamageScale(skill, character)
        else
            attrDamageScale = 1.0
        end

		local globalMult = 1 + (character.Strength-10) * 0.03 + (character.Finesse-10) * 0.03 + (character.Intelligence-10) * 0.06
        local baseDamage = Game.Math.CalculateBaseDamage(skill.Damage, character, 0, level) * attrDamageScale * damageMultiplier * globalMult
        local damageRange = skill['Damage Range'] * baseDamage * 0.005

        local damageType = skill.DamageType
        local damageTypeBoost = 1.0 + Game.Math.GetDamageBoostByType(character, damageType)
        local damageBoost = 1.0 + (character.DamageBoost / 100.0)
		Ext.Print("Base Damage:",Game.Math.GetAverageLevelDamage(character.Level), damageTypeBoost, Game.Math.GetLevelScaledDamage(character.Level))
        local damageRanges = {}
        damageRanges[damageType] = {
            math.ceil(math.ceil(Ext.Round(baseDamage - damageRange) * damageBoost) * damageTypeBoost),
            math.ceil(math.ceil(Ext.Round(baseDamage + damageRange) * damageBoost) * damageTypeBoost)
        }
		Ext.Print("No weapon damage")
        return damageRanges
    end
end


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

local function truncate1(floatNb)
	local rounded = math.floor(floatNb)
	Ext.Print(floatNb, rounded)
	local multiplied = math.floor((floatNb - rounded) * 10)/10
	Ext.Print(multiplied)
	return rounded+multiplied
end

local function StatusGetDescriptionParam(status, statusSource, character, par)
	if par == "Damage" then
		local dmgStat = Ext.GetStat(status.DamageStats)
		local globalMult = 1 + (statusSource.Strength-10) * 0.05 --From the overhaul
		if dmgStat.Damage == 1 then
			dmg = GetAverageLevelDamage(character.Level)
		elseif dmgStat.Damage == 0 then
			dmg = GetLevelScaledDamage(character.Level)
		end
		Ext.Print("AverageLevelDamage "..GetAverageLevelDamage(character.Level))
		dmg = dmg*(dmgStat.DamageFromBase/100)
		dmgRange = dmg*(dmgStat["Damage Range"])*0.005
		Ext.Print(dmg, dmgRange, globalMult)
		local minDmg = math.floor(Ext.Round(dmg - dmgRange * globalMult))
		local maxDmg = math.floor(Ext.Round(dmg + dmgRange * globalMult))
		if maxDmg <= minDmg then maxDmg = maxDmg+1 end
		local color = getDamageColor(dmgStat["Damage Type"])
		Ext.Print(minDmg, maxDmg)
		return "<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgStat["Damage Type"].." damage".."</font>"
	end
	return nil
end

Ext.RegisterListener("StatusGetDescriptionParam", StatusGetDescriptionParam)

local function SkillGetDescriptionParam(skill, character, par)
	Ext.Print(skill, character.Name, par)
	if par == "Damage" or par == "Weapon" then
		local dmg = GetSkillDamageRange(character, skill)
		local result = ""
		local once = false
		for dmgType, damages in pairs(dmg) do
			--Ext.Print(dmgType, damages[1], damages[2])
			local minDmg = math.floor(damages[1])
			local maxDmg = math.floor(damages[2])
			local color = getDamageColor(dmgType)
			if not once then
				result = result.."<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgType.." damage".."</font>"
				once = true
			else
				result = result.." + ".."<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..dmgType.." damage".."</font>"
			end
			return result
		end
		-- if skill.UseWeaponDamage == "No" then
			-- local globalMult = 1 + (character.Strength-10) * 0.03 + (character.Finesse-10) * 0.03 + (character.Intelligence-10) * 0.06
			-- local dmg = CalculateBaseDamage(skill.Damage, character, nil, character.Level)
			-- local dmg = dmg*(skill["Damage Multiplier"]/100)
			-- local dmgRange = dmg*(skill["Damage Range"])*0.005
			-- local minDmg = math.floor(Ext.Round((dmg - dmgRange)*globalMult))
			-- local maxDmg = math.floor(Ext.Round((dmg + dmgRange)*globalMult))
			-- if maxDmg <= minDmg then maxDmg = maxDmg+1 end
			-- local color = getDamageColor(skill.DamageType)
			-- Ext.Print(minDmg, maxDmg)
		-- else
			-- local globalMult = 1 + (character.Strength-10) * 0.06 + (character.Finesse-10) * 0.03 + (character.Intelligence-10) * 0.06
			-- dmg = ComputeBaseWeaponDamage(character.MainWeapon)
			-- local result = ""
			-- local once = false
			
			-- Ext.Print(result)
	end
	return nil
end

Ext.RegisterListener("SkillGetDescriptionParam", SkillGetDescriptionParam)


