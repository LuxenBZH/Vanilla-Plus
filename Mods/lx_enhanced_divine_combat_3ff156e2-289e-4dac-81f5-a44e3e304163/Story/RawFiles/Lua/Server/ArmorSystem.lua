---- Armor system modification ---
local physicalArmorReduction = {
	FORTIFIED = Ext.ExtraData.DGM_FortifiedPassingPhysicalReduction,
	MEND_METAL = Ext.ExtraData.DGM_MendMetalPassingPhysicalReduction,
	STEEL_SKIN = Ext.ExtraData.DGM_SteelSkinPassingPhysicalReduction,
	LX_SHIELDSUP = Ext.ExtraData.DGM_ShieldsUpPassingReduction,
	LX_OILYCARAPACE = Ext.ExtraData.DGM_OilyCarapacePassingReduction,
}

local magicArmorReduction = {
	MAGIC_SHELL = Ext.ExtraData.DGM_MagicShellPassingMagicReduction,
	FROST_AURA = Ext.ExtraData.DGM_FrostAuraPassingMagicReduction,
	LX_CRYOTHERAPY = Ext.ExtraData.DGM_CryotherapyPassingMagicReduction,
}

---@param character EsvCharacter
---@param amount number
---@param dmgType string
function CalculatePassingDamage(character, amount, dmgType)
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
		for status,reduction in pairs(physicalArmorReduction) do
			if HasActiveStatus(status) == 1 then passingModMult = passingModMult - reduction end
		end
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
			for status,reduction in pairs(magicArmorReduction) do
				if HasActiveStatus(status) == 1 then passingModMult = passingModMult - reduction end
			end
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
	local currentVitality = NRD_CharacterGetStatInt(character, "CurrentVitality")
	if currentVitality == nil then return end
	NRD_CharacterSetStatInt(character, "CurrentVitality", currentVitality - amount)
end