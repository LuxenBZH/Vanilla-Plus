---@param character EsvCharacter
function InitCharacterAbilities(character)
	local abilitiesStr = {
		"SingleHanded",
		"Ranged",
		"TwoHanded"
	}
	for i,abi in pairs(abilitiesStr) do
		if CharacterGetAbility(character, abi) == nil then return end
		SetVarInteger(character, "LX_Check_"..abi, CharacterGetAbility(character, abi))
		SetVarInteger(character, "LX_Check_Base_"..abi, CharacterGetBaseAbility(character, abi))
		if abi == "SingleHanded" then
			local armorPBonus = NRD_CharacterGetPermanentBoostInt(character, "ArmorBoost")
			local armorMBonus = NRD_CharacterGetPermanentBoostInt(character, "MagicArmorBoost")
			if armorPBonus == 0 and armorMBonus == 0 then SetVarInteger(character, "LX_Changed_SingleHanded", CharacterGetAbility(character, abi)) end
		end
		if abi == "Ranged" then
			local rangeBonus = NRD_CharacterGetPermanentBoostInt(character, "RangeBoost")
			if rangeBonus == 0 then SetVarInteger(character, "LX_Changed_Ranged", CharacterGetAbility(character, abi)) end
		end
		if abi == "TwoHanded" then
			local cthBonus = NRD_CharacterGetPermanentBoostInt(character, "ChanceToHitBoost")
			if cthBonus == 0 then SetVarInteger(character, "LX_Changed_TwoHanded", CharacterGetAbility(character, abi)) end
		end
	end
	local wpnAbility = CheckCurrentWeaponAbility(character)
	SetVarString(character, "LX_Previous_Weapon_Ability", wpnAbility)
end

---@param character EsvCharacter
function InitCharacter(character)
	InitCharacterStatCheck(character)
	InitCharacterAbilities(character)
end

---- Weapon Ability check
---@param character EsvCharacter
function CheckCurrentWeaponAbility(character)
	-- Throw this function at character init and every time that a character change its equipment. Use for see if 
	if CharacterGetAbility(character, "SingleHanded") == nil then return end --Check for characters without stats
	local charStats = Ext.GetCharacter(character).Stats
	local mainWeapon = charStats.MainWeapon
	local mainWeaponType = "None"
	if mainWeapon ~= nil then
		mainWeaponType = mainWeapon.WeaponType
	end
	local mainWeaponHandedness = mainWeapon.IsTwoHanded
	--Ext.Print(mainWeaponHandedness)
	local offHand = charStats.OffHandWeapon
	--Ext.Print("Offhand Weapon: ", Ext.GetCharacter(character).Stats.OffHandWeapon)
	local offHandType = "None"
	if offHand ~= nil then
		offHandType = Ext.GetCharacter(character).Stats.OffHandWeapon.WeaponType
	end
	--print("Offhand type: "..offHandType)
	
	if mainWeaponType == "None" and offHand == nil then return "None" end
	
	if mainWeaponType == "Bow" or mainWeaponType == "Crossbow" or mainWeaponType == "Rifle" then
		return "Ranged"
	elseif mainWeaponHandedness then
		return "TwoHanded"
	elseif mainWeaponType == "Wand" and offHandType == "Wand" then
		return "Ranged" 
	elseif mainWeaponType ~= "None"	and offHandType ~= "None" then
		return "DualWielding"
	end
	
	return "SingleHanded"
end

---@param character EsvCharacter
---@param new string
---@param previous string
function ChangedWeaponAbility(character, new, previous)
	if previous ~= new then
		local newAbility = GetVarInteger(character, "LX_Check_"..new)
		if newAbility == nil then newAbility = 0 end
		SetVarInteger(character, "LX_Changed_"..new, newAbility)
	
	
		if previous == nil then previous = "None" end
		local previousAbility = GetVarInteger(character, "LX_Check_"..previous)
		if previousAbility == nil then previousAbility = 0 end
		if previous ~= "None" then
			SetVarInteger(character, "LX_Changed_"..previous, -previousAbility)
		end
	end
end

---@param character EsvCharacter
function ApplyOverhaulWeaponAbilityBonuses(character)
	if CharacterGetAbility(character, "SingleHanded") == nil then return end --Check for characters without stats
	---- Abilities
	local wpnAbilityBonuses = {}
	wpnAbilityBonuses["SingleHanded"] = {
		ArmorBoost=Ext.ExtraData.DGM_SingleHandedArmorBonus,
		MagicArmorBoost=Ext.ExtraData.DGM_SingleHandedArmorBonus,
		FireResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
		EarthResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
		PoisonResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
		WaterResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
		AirResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus
		}
	wpnAbilityBonuses["TwoHanded"] = {Accuracy=Ext.ExtraData.DGM_TwoHandedCTHBonus}
	wpnAbilityBonuses["Ranged"] = {RangeBoost=Ext.ExtraData.DGM_RangedRangeBonus}
	
	local wpnAbility = CheckCurrentWeaponAbility(character)
	local previousWpnAbility = GetVarString(character, "LX_Previous_Weapon_Ability")
	if previousWpnAbility == nil then previousWpnAbility = "None" end
	local change = GetVarInteger(character, "LX_Changed_"..wpnAbility)
	if change == nil then change = 0 end
	
	local change2 = GetVarInteger(character, "LX_Changed_"..previousWpnAbility)
	if change2 == nil then change2 = 0 end
	
	local bonuses = {}
	local multipliers = {}
	local n=0
	
	if wpnAbility ~= "None" and wpnAbility ~= "DualWielding" then
		for k,v in pairs(wpnAbilityBonuses[wpnAbility]) do
			n=n+1
			--print(k.." "..v)
			bonuses[n]=k
			multipliers[n]=v
		end
	end
	
	-- If gained point while ability is active
	if wpnAbility == previousWpnAbility and change ~= 0 then
		for n,bonus in pairs(bonuses) do
			print("Apply bonus for "..bonus.." with a mutiplier of "..multipliers[n].." Stat being "..change)
			ApplyBonus(character, wpnAbility, bonus, multipliers[n])
		end
		SetVarInteger(character, "LX_Changed_"..wpnAbility, 0)
	end
		
	-- If changed ability
	if wpnAbility ~= previousWpnAbility then
		ChangedWeaponAbility(character, wpnAbility, previousWpnAbility)
		change = GetVarInteger(character, "LX_Changed_"..wpnAbility)
		if change == nil then change = 0 end
	
		change2 = GetVarInteger(character, "LX_Changed_"..previousWpnAbility)
		if change2 == nil then change2 = 0 end
		print("Weapon ability: "..wpnAbility.." change of "..change)
		print("Previous weapon ability: "..previousWpnAbility.." change of "..change2)
		if wpnAbility ~= "None" and wpnAbility ~= "DualWielding" then
			for n,bonus in pairs(bonuses) do
				ApplyBonus(character, wpnAbility, bonus, multipliers[n])
				print("Apply bonus for "..bonus.." with a mutiplier of "..multipliers[n].." Stat being "..change)
			end
			SetVarInteger(character, "LX_Changed_"..wpnAbility, 0)
		end
		if previousWpnAbility ~= "None" and previousWpnAbility ~= "DualWielding" then
			bonuses = {}
			multipliers = {}
			for k,v in pairs(wpnAbilityBonuses[previousWpnAbility]) do
				n=n+1
				bonuses[n]=k
				multipliers[n]=v
			end
			for n,bonus in pairs(bonuses) do
				ApplyBonus(character, previousWpnAbility, bonus, multipliers[n])
				print("Apply bonus for "..bonus.." with a mutiplier of "..multipliers[n])
			end
			SetVarInteger(character, "LX_Changed_"..previousWpnAbility, 0)
		end
	end
	SetVarString(character, "LX_Previous_Weapon_Ability", wpnAbility)
end

---@param character EsvCharacter
function GetWeaponsType(character)
	local charStats = Ext.GetCharacter(character).Stats
	local mainWeapon = charStats.MainWeapon
	local mainWeaponType = "None"
	if mainWeapon ~= nil then mainWeaponType = mainWeapon.WeaponType end
	local offHand = charStats.OffHandWeapon
	local offHandType = "None"
	if offHand ~= nil then offHandType = offHand.WeaponType end
	return {mainWeaponType, offHandType}
end
