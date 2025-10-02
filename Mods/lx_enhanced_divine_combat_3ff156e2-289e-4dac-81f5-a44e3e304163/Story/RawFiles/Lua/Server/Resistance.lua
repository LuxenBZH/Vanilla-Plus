--- @param character StatCharacter
--- @param type string DamageType enumeration
local function GetResistance(character, damageType)
	local cap = character.MaxResistance
	local resistance = character[tostring(damageType).."Resistance"]
	if damageType == "None" or damageType == "Chaos" then
		damageType = "Custom" 
	end
	local resCap = FindTag(Ext.GetCharacter(character.MyGuid), "DGM_ResCap"..tostring(damageType)) or character.MaxResistance
	local typeCap = tonumber(string.gsub(resCap, ".*_", "")[1])
	if typeCap then
		cap = cap + typeCap
	end
	-- If the base resistance is higher than the cap, let it be
	if character["Base"..tostring(damageType).."Resistance"] > cap then
		return character["Base"..tostring(damageType).."Resistance"]
	elseif resistance > cap then
		return cap
	else
		return resistance
	end
end

Game.Math.GetResistance = GetResistance

--- @param character CDivinityStatsCharacter
local function GetResistanceBypassValue(character)
	if not character then
		return 0
	end
	local bypassValue = Data.Math.ComputeCharacterIngress(character.Character)
	if character.TALENT_Haymaker then
		bypassValue = bypassValue + (character.Wits-Ext.ExtraData.AttributeBaseValue)*Ext.ExtraData.CriticalBonusFromWits
	end
	return bypassValue
end

--- @param character CDivinityStatsCharacter
--- @param damageList DamageList
--- @param attacker StatCharacter
local function CustomApplyHitResistances(character, damageList, attacker)
	for i,damage in pairs(damageList:ToTable()) do
		local originalResistance = Game.Math.GetResistance(character, damage.DamageType)
		local resistance = originalResistance
		local bypassValue = GetResistanceBypassValue(attacker)
		-- Ext.Print("Resistance bypass value:",bypassValue)
		-- Ext.Print(resistance)
		if originalResistance ~= nil and originalResistance > 50 and originalResistance < 100 and bypassValue > 0 then
            -- resistance = GetResistance(character, damage, originalResistance - bypassValue)
			resistance = originalResistance - bypassValue
			if resistance < 50  then
				resistance = 50
			elseif resistance > originalResistance then
				resistance = originalResistance
			end
		end
		_P(tostring(damage.DamageType).." Resistance: "..tostring(resistance))
        damageList:Add(damage.DamageType, math.floor(damage.Amount * -resistance / 100.0))
    end
end

Game.Math.ApplyHitResistances = CustomApplyHitResistances

--- @param character CDivinityStatsCharacter
--- @param attacker CDivinityStatsCharacter
--- @param damageList DamageList
function CustomApplyDamageCharacterBonuses(character, attacker, damageList)
	-- Ext.Print("VANILLA PLUS ApplyDamageCharacterBonuses")
    damageList:AggregateSameTypeDamages()
    CustomApplyHitResistances(character, damageList, attacker)

    Game.Math.ApplyDamageSkillAbilityBonuses(damageList, attacker)
end

Game.Math.ApplyDamageCharacterBonuses = CustomApplyDamageCharacterBonuses