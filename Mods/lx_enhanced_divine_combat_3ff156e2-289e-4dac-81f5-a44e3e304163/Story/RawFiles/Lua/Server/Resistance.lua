--- @param character StatCharacter
--- @param type string DamageType enumeration
local function GetResistance(character, damageType, ...)
	local cap = character.MaxResistance
	local pen = {...} -- Resistance - penetration value
	pen = pen[1]
	if damageType == "None" or damageType == "Chaos" then
		damageType = "Custom" 
	end
	-- New V+ resistance cap behavior
	if pen then
		local typeCap = tonumber(string.gsub(FindTag(Ext.GetCharacter(character.MyGuid), "DGM_ResCap"..damageType), ".*_", ""))
		if typeCap then
			cap = cap + typeCap
		end
		if character["Base"..damageType.."Resistance"] > cap then
			return character["Base"..damageType.."Resistance"]
		elseif pen > cap then
			return cap
		else
			return pen
		end
	-- Old behavior, still available
	else
		return character[damageType.."Resistance"]
	end
end

Game.Math.GetResistance = GetResistance

--- @param character StatCharacter
local function GetResistanceBypassValue(character)
	if not character then
		return 0
	end
	local strength = character.Strength
	local intelligence = character.Intelligence
	local bypassValue = (strength - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthResistanceIgnore * (intelligence - Ext.ExtraData.AttributeBaseValue)
	if character.TALENT_Haymaker then
		bypassValue = bypassValue + (character.Wits-Ext.ExtraData.AttributeBaseValue)*Ext.ExtraData.CriticalBonusFromWits
	end
	return bypassValue
end

--- @param character StatCharacter
--- @param damageList DamageList
--- @param attacker StatCharacter
local function ApplyHitResistances(character, damageList, attacker)
	for i,damage in pairs(damageList:ToTable()) do
		local originalResistance = Game.Math.GetResistance(character, damage.DamageType)
		local resistance = originalResistance
		local bypassValue = GetResistanceBypassValue(attacker)
		-- Ext.Print("Resistance bypass value:",bypassValue)
		-- Ext.Print(resistance)
		if originalResistance ~= nil and originalResistance > 0 and originalResistance < 100 and bypassValue > 0 then
            -- resistance = GetResistance(character, damage, originalResistance - bypassValue)
			resistance = originalResistance - bypassValue
			if resistance < 0 then
				resistance = 0
			elseif resistance > originalResistance then
				resistance = originalResistance
			end
		-- else
			-- resistance = 1
		end
        damageList:Add(damage.DamageType, math.floor(damage.Amount * -resistance / 100.0))
    end
end

Game.Math.ApplyHitResistances = ApplyHitResistances

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