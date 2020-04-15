---- Armor system modification ---
function CalculatePassingDamage(character, amount, dmgType)
	if amount == nil then amount = 0 end
	local dmgThrough = 0
	local passingMod = 0.5
	local passingModMult = 1
	local pArmor = NRD_CharacterGetStatInt(character, "CurrentArmor")
	local mArmor = NRD_CharacterGetStatInt(character, "CurrentMagicArmor")
	if pArmor == nil then pArmor = 0 end
	if mArmor == nil then mArmor = 0 end
	
	-- Calculate passing modifier
	if pArmor == 0 or mArmor == 0 then
		passingMod = passingMod + 0.25
	end
	
	if dmgType == "Physical" then
		if HasActiveStatus(character, "FORTIFIED") == 1 then passingModMult = passingModMult - 0.5 end
		if HasActiveStatus(character, "MEND_MENTAL") == 1 then passingModMult = passingModMult - 0.25 end
		if HasActiveStatus(character, "STEEL_SKIN") == 1 then passingModMult = passingModMult - 0.25 end
		passingMod = passingMod * passingModMult
		if pArmor > 0 then
			if pArmor > amount then
				dmgThrough = amount * passingMod
			else
				dmgThrough = pArmor * passingMod
			end
		end
	end
	
	
	local magicTypes = {
		"Fire",
		"Air",
		"Earth",
		"Poison",
		"Water",
		"Shadow"
	}
	for i, mDmg in pairs(magicTypes) do
		if dmgType == mDmg then
			if HasActiveStatus(character, "MAGIC_SHELL") == 1 then passingModMult = passingModMult - 0.5 end
			if HasActiveStatus(character, "FROST_AURA") == 1 then passingModMult = passingModMult - 0.25 end
			passingMod = passingMod * passingModMult
			if mArmor > 0 then
				if mArmor > amount then
					dmgThrough = amount * passingMod
				else
					dmgThrough = mArmor * passingMod
				end
			end
		end
	end
	-- Ext.Print("[LXDGM_ArmorSystem.CalculatePassingDamage] Original: "..amount.." "..dmgType.." result "..dmgThrough)
	return math.ceil(dmgThrough)
end

function ApplyPassingDamage(character, amount)
	local currentVitality = NRD_CharacterGetStatInt(character, "CurrentVitality")
	NRD_CharacterSetStatInt(character, "CurrentVitality", currentVitality - amount)
end