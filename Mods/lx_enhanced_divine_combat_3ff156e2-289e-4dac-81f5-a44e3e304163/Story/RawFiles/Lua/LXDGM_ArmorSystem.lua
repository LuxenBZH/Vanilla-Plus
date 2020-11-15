---- Armor system modification ---
---@param character EsvCharacter
---@param amount number
---@param dmgType string
function CalculatePassingDamage(character, amount, dmgType)
	if ObjectIsCharacter(character) == 0 then return end
	if amount == nil then amount = 0 end
	local dmgThrough = 0
	local passingMod = Ext.ExtraData.DGM_DamageThroughArmor/100
	local passingModMult = 1
	local pArmor = NRD_CharacterGetStatInt(character, "CurrentArmor")
	local mArmor = NRD_CharacterGetStatInt(character, "CurrentMagicArmor")
	if pArmor == nil then pArmor = 0 end
	if mArmor == nil then mArmor = 0 end
	
	-- Calculate passing modifier
	if pArmor == 0 or mArmor == 0 then
		passingMod = passingMod + Ext.ExtraData.DGM_DamageThroughArmorDepleted/100
	end
	
	if dmgType == "Physical" then
		if HasActiveStatus(character, "FORTIFIED") == 1 then passingModMult = passingModMult - Ext.ExtraData.DGM_FortifiedPassingPhysicalReduction end
		if HasActiveStatus(character, "MEND_MENTAL") == 1 then passingModMult = passingModMult - Ext.ExtraData.DGM_MendMetalPassingPhysicalReduction end
		if HasActiveStatus(character, "STEEL_SKIN") == 1 then passingModMult = passingModMult - Ext.ExtraData.DGM_SteelSkinPassingPhysicalReduction end
		if HasActiveStatus(character, "LX_SHIELDSUP") == 1 then passingModMult = passingModMult - Ext.ExtraData.DGM_ShieldsUpPassingReduction end
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
		"Water"
	}
	for i, mDmg in pairs(magicTypes) do
		if dmgType == mDmg then
			if HasActiveStatus(character, "MAGIC_SHELL") == 1 then passingModMult = passingModMult - Ext.ExtraData.DGM_MagicShellPassingMagicReduction end
			if HasActiveStatus(character, "FROST_AURA") == 1 then passingModMult = passingModMult - Ext.ExtraData.DGM_FrostAuraPassingMagicReduction end
			if HasActiveStatus(character, "LX_SHIELDSUP") == 1 then passingModMult = passingModMult - Ext.ExtraData.DGM_ShieldsUpPassingReduction end
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

---@param character EsvCharacter
---@param amount number
function ApplyPassingDamage(character, amount)
	if ObjectIsCharacter(character) == 0 then return end
	local currentVitality = NRD_CharacterGetStatInt(character, "CurrentVitality")
	if currentVitality == nil then return end
	NRD_CharacterSetStatInt(character, "CurrentVitality", currentVitality - amount)
end