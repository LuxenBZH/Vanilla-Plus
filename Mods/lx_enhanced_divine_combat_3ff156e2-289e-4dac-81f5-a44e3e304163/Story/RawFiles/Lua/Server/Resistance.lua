--- @param character StatCharacter
--- @param type string DamageType enumeration
local function GetResistance(character, damageType)
	local cap = character.MaxResistance
	local pen = Data.Math.ComputeCharacterIngress(character.Character) -- Resistance - penetration value
	if damageType == "None" or damageType == "Chaos" then
		damageType = "Custom" 
	end
	-- New V+ resistance cap behavior
	if pen then
		local resCap = FindTag(Ext.GetCharacter(character.MyGuid), "DGM_ResCap"..tostring(damageType)) or "100"
		local typeCap = tonumber(string.gsub(resCap, ".*_", "")[1])
		if typeCap then
			cap = cap + typeCap
		end
		if character["Base"..tostring(damageType).."Resistance"] > cap then
			return character["Base"..tostring(damageType).."Resistance"]
		elseif pen > cap then
			return cap
		else
			return pen
		end
	-- Old behavior, still available
	else
		return character[tostring(damageType).."Resistance"]
	end
end

Game.Math.GetResistance = GetResistance

--- @param character CDivinityStatsCharacter
local function GetResistanceBypassValue(character)
	if not character then
		return 0
	end
	local strength = character.Strength
	local intelligence = character.Intelligence
	local bypassValue = math.min(intelligence - Ext.ExtraData.AttributeBaseValue, (strength - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthResistanceIgnore)
	if character.MainWeapon then
		if character.MainWeapon.WeaponType == "Staff" then
			bypassValue = bypassValue + 10
		elseif character.MainWeapon.WeaponType == "Wand" then
			bypassValue = bypassValue + 5
		end
	end
	if character.OffHandWeapon and character.OffHandWeapon.WeaponType == "Wand" then
		bypassValue = bypassValue + 5
	end
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