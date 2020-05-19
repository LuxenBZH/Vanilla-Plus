-- Helpers
function DamageTypeEnum()
	local enum = {
		"Physical",
		"Piercing",
		"Corrosive",
		"Magic",
		"Chaos",
		"Fire",
		"Air",
		"Water",
		"Earth",
		"Poison",
		"Shadow"
	}
	return enum
end

function CharGetDGMAttributeBonus(char)
	if char == nil then return end
	local stats = char.Stats
	local strength = stats.Strength - Ext.ExtraData.AttributeBaseValue
	local finesse = stats.Finesse - Ext.ExtraData.AttributeBaseValue
	local intelligence = stats.Intelligence - Ext.ExtraData.AttributeBaseValue
	local bonus = {
		str = math.floor(strength),
		strGlobal = math.floor(strength * Ext.ExtraData.DGM_StrengthGlobalBonus),
		strWeapon = math.floor(strength * Ext.ExtraData.DGM_StrengthWeaponBonus),
		strDot = math.floor(strength * Ext.ExtraData.DGM_StrengthDoTBonus),
		fin = math.floor(finesse),
		finGlobal = math.floor(finesse * Ext.ExtraData.DGM_FinesseGlobalBonus),
		int = math.floor(intelligence),
		intGlobal = math.floor(intelligence * Ext.ExtraData.DGM_IntelligenceGlobalBonus),
		intSkill = math.floor(intelligence * Ext.ExtraData.DGM_IntelligenceSkillBonus),
		intAcc = math.floor(intelligence * Ext.ExtraData.DGM_IntelligenceAccuracyBonus)
	}
	return bonus
end