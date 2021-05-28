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
		"Shadow",
		"None"
	}
	return enum
end

surfaceFlags = {
	MovementBlock = 0x1,
	ProjectileBlock = 0x4,
	HasCharacter = 0x10,
	HasItem = 0x80,
	HasInteractableObject = 0x100,
	GroundSurfaceBlock = 0x200,
	CloudSurfaceBlock = 0x400,
	Occupied = 0x1000,
	SurfaceExclude = 0x10000,
	Fire = 0x1000000,
	Water = 0x2000000,
	Blood = 0x4000000,
	Poison = 0x8000000,
	Oil = 0x10000000,
	Lava = 0x20000000,
	Source = 0x40000000,
	Web = 0x80000000,
	Deepwater = 0x100000000,
	Sulfurium = 0x200000000,
	FireCloud = 0x800000000,
	WaterCloud = 0x1000000000,
	BloodCloud = 0x2000000000,
	PoisonCloud = 0x4000000000,
	SmokeCloud = 0x8000000000,
	ExplosionCloud = 0x10000000000,
	FrostCloud = 0x20000000000,
	Deathfog = 0x40000000000,
	ShockwaveCloud = 0x80000000000,
	Blessed = 0x400000000000,
	Cursed = 0x800000000000,
	Purified = 0x1000000000000,
	CloudBlessed = 0x4000000000000,
	CloudCursed = 0x8000000000000,
	CloudPurified = 0x10000000000000,
	Electrified = 0x40000000000000,
	Frozen = 0x80000000000000,
	CloudElectrified = 0x100000000000000,
	ElectrifiedDecay = 0x200000000000000,
	SomeDecay = 0x400000000000000,
	Irreplaceable = 0x4000000000000000,
	IrreplaceableCloud = 0x800000000000000,
}



---@param number number
---@param precision number
function round(number, precision)
	local fmtStr = string.format('%%0.%sf', precision)
	local result = string.format(fmtStr, number)
	return result
end

function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
 end

---@param char EsvCharacter
---@param next integer
function CharGetDGMAttributeBonus(char, next)
	if char == nil then return end
	local stats = char.Stats
	local strength = stats.Strength - Ext.ExtraData.AttributeBaseValue
	local finesse = stats.Finesse - Ext.ExtraData.AttributeBaseValue
	local intelligence = stats.Intelligence - Ext.ExtraData.AttributeBaseValue
	local wits = stats.Wits - Ext.ExtraData.AttributeBaseValue

	local bonus = {
		str = math.floor(strength+next),
		strGlobal = math.floor((strength+next) * Ext.ExtraData.DGM_StrengthGlobalBonus),
		strWeapon = math.floor((strength+next) * Ext.ExtraData.DGM_StrengthWeaponBonus),
		strRes = math.floor(Ext.Round((strength+next) * Ext.ExtraData.DGM_StrengthResistanceIgnore * 100))/100,
		fin = math.floor(finesse+next),
		finGlobal = math.floor((finesse+next) * Ext.ExtraData.DGM_FinesseGlobalBonus),
		finDodge = round((finesse+next) * Ext.ExtraData.DodgingBoostFromAttribute * 100, 0),
		finMovement = round((finesse+next) * Ext.ExtraData.DGM_FinesseMovementBonus / 100, 2),
		finCrit = math.floor((finesse+next) * Ext.ExtraData.DGM_FinesseCritChance),
		int = math.floor(intelligence+next),
		intGlobal = math.floor((intelligence+next) * Ext.ExtraData.DGM_IntelligenceGlobalBonus),
		intSkill = math.floor((intelligence+next) * Ext.ExtraData.DGM_IntelligenceSkillBonus),
		intAcc = math.floor((intelligence+next) * Ext.ExtraData.DGM_IntelligenceAccuracyBonus),
		wits = math.floor(wits+next),
		witsCrit = math.floor((wits+next) * Ext.ExtraData.CriticalBonusFromWits),
		witsIni = math.floor((wits+next) * Ext.ExtraData.InitiativeBonusFromWits),
		witsDot = math.floor((wits+next) * Ext.ExtraData.DGM_WitsDotBonus),
		dual = math.floor(Ext.ExtraData.CombatAbilityDamageBonus * (stats.DualWielding+next)),
		dualDodge = math.floor(Ext.ExtraData.CombatAbilityDodgingBonus * (stats.DualWielding+next)),
		dualOff = math.floor(Ext.ExtraData.DGM_DualWieldingOffhandBonus * (stats.DualWielding+next)),
		ranged = math.floor(Ext.ExtraData.CombatAbilityDamageBonus * (stats.Ranged+next)),
		rangedCrit = math.floor(Ext.ExtraData.CombatAbilityCritBonus * (stats.Ranged+next)),
		rangedRange = round(Ext.ExtraData.DGM_RangedRangeBonus * (stats.Ranged+next) * 0.01, 2),
		single = math.floor(Ext.ExtraData.CombatAbilityDamageBonus * (stats.SingleHanded+next)),
		singleAcc = math.floor(Ext.ExtraData.CombatAbilityAccuracyBonus * (stats.SingleHanded+next)),
		singleArm = math.floor(Ext.ExtraData.DGM_SingleHandedArmorBonus * (stats.SingleHanded+next)),
		singleEle = math.floor(Ext.ExtraData.DGM_SingleHandedResistanceBonus * (stats.SingleHanded+next)),
		two = math.floor(Ext.ExtraData.CombatAbilityDamageBonus * (stats.TwoHanded+next)),
		twoCrit = math.floor(Ext.ExtraData.CombatAbilityCritMultiplierBonus * (stats.TwoHanded+next)),
		twoAcc = math.floor(Ext.ExtraData.DGM_TwoHandedCTHBonus * (stats.TwoHanded+next)),
		persArm = math.floor(Ext.ExtraData.AbilityPerseveranceArmorPerPoint * (stats.Perseverance+next)),
		persVit = math.floor(Ext.ExtraData.DGM_PerseveranceVitalityRecovery * (stats.Perseverance+next)),
		hydroDmg = math.floor(Ext.ExtraData.SkillAbilityWaterDamageBoostPerPoint * (stats.WaterSpecialist+next)),
		hydroHeal = math.floor(Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint * (stats.WaterSpecialist+next)),
		hydroArmor = math.floor(Ext.ExtraData.SkillAbilityArmorRestoredPerPoint * (stats.WaterSpecialist+next))
	}
	return bonus
end

function FlushArray(array)
	local temp
	for i=#array, 2, -1 do
		temp = array[i-1]
		if i == #array then temp = array[i] end
		array[i-1] = temp
	end
end

function RoundToFirstDecimal(number)
	local multiplied = math.floor(Ext.Round(number*10)) --floor operation to remove any unneeded 0 after the final decimal
	return multiplied/10
end

function RoundToSecondDecimal(number)
	return tonumber(string.format("%.2f", number))
end

function GetTableSize(table)
	local size = 0
	for i,j in pairs(table) do
		size = size + 1
	end
	return size
end

function string.starts(String, Start)
	return string.sub(String, 1, string.len(Start))==Start
end

---@param inputStr string
---@param sep string
function string.split(inputStr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputStr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

---@param dmgType string
function getDamageColor(dmgType)
	local colorCode = ""
	local types = {}
	types["Physical"]="'#A8A8A8'"
	types["Corrosive"]="'#cccc00'"
	types["Magic"]="'#7F00FF'"
	types["Fire"]="'#FE6E27'"
	types["Water"]="'#4197E2'"
	types["Earth"]="'#7F3D00'"
	types["Poison"]="'#65C900'"
	types["Air"]="'#7D71D9'"
	types["Shadow"]="'#6600ff'"
    types["Piercing"]="'#C80030'"
    types["None"]="'#C80030'"
	
	for t,code in pairs(types) do
		if dmgType == t then return code end
	end
	return "'#A8A8A8'"
end

surfaceToType = {
	Fire = "Fire",
	FireBlessed = "Fire",
	FireCursed = "Fire",
	FireCloud = "Fire",
	FireCloudBlessed = "Fire",
	FireCloudCursed = "Fire",
	Water = "Water",
	WaterFrozen = "Water",
	WaterFrozenBlessed = "Water",
	WaterFrozenCursed = "Water",
	WaterBlessed = "Water",
	WaterCursed = "Water",
	WaterCloud = "Water",
	WaterCloudBlessed = "Water",
	WaterCloudCursed = "Water",
	WaterElectrified = "Air",
	WaterElectrifiedCursed = "Air",
	WaterElectrifiedBlessed = "Air",
	WaterCloudElectrified = "Air",
	WaterCloudElectrifiedCursed = "Air",
	WaterCloudElectrifiedBlessed = "Air",
	BloodCloudElectrified = "Air",
	BloodCloudElectrifiedCursed = "Air",
	BloodCloudElectrifiedBlessed = "Air",
	PoisonBlessed = "Poison",
	PoisonCursed = "Poison",
	PoisonCloud = "Poison",
	PoisonCloudBlessed = "Poison",
	PoisonCloudCursed = "Poison",
	Oil = "Earth",
	OilBlessed = "Earth",
	OilCursed = "Earth",
	Blood = "Physical",
	BloodCursed = "Physical",
	BloodBlessed = "Physical",
	BloodCloud = "Physical",
	BloodCloudBlessed = "Physical",
	BloodCloudCursed = "Physical",
}

function GetParentStat(entry, stat)
	if entry[stat] == "None" and entry.Using ~= nil then
		GetParentStat(entry.Using, stat)
	else
		return entry[stat]
	end
end

function HasParent(stat, value)
	if stat.Using == value then
		return true
	elseif stat.Using ~= nil or stat.Using == "" then
		HasParent(stat.Using, value)
	else
		return false
	end
end

dmgTypeToSchool = {
	Fire = "Pyrokinetic",
	Water = "Hydrosophist",
	Earth = "Geomancy",
	Poison = "Geomancy",
	Physical = "Warfare",
	Air = "Aerotheurge",
	None = nil,
	Piercing = nil,
	Shadow = nil,
	Corrosive = nil,
	Magic = nil,
	Chaos = nil
}

--- @param character StatCharacter
--- @param weapon StatItem
function GetWeaponAbility(character, weapon)
    if weapon == nil or weapon.WeaponType == "None" then
        return nil
    end

    local offHandWeapon = character.OffHandWeapon
    if offHandWeapon ~= nil then
        return "DualWielding"
    end

    local weaponType = weapon.WeaponType
    if weaponType == "Bow" or weaponType == "Crossbow" or weaponType == "Rifle" then
        return "Ranged"
    end

    if weapon.IsTwoHanded then
        return "TwoHanded"
    end

    return "SingleHanded"
end

weaponAbility = {
	SingleHanded = "Single-Handed",
	TwoHanded = "Two-Handed",
	Ranged = "Ranged",
	DualWielding = "Dual-Wielding"
}

-- Skill tooltips helpers
lastSkill = ""
skillParams = {}
currentParam = 1
paramsOrder = {}

