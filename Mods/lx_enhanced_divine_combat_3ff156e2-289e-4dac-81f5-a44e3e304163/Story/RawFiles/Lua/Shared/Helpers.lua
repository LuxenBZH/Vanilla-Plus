---@diagnostic disable: duplicate-set-field
-- Helpers
--- @class Helpers
Helpers = {}

--- @param object IEoCServerObject | IEoCClientObject
Helpers.IsCharacter = function(object)
	if Ext.IsServer() then
		return getmetatable(object) == "esv::Character"
	else
		return getmetatable(object) == "ecl::Character"
	end
end

--- @param object IEoCServerObject | IEoCClientObject
Helpers.IsItem = function(object)
	if Ext.IsServer() then
		return getmetatable(object) == "esv::Item"
	else
		return getmetatable(object) == "ecl::Item"
	end
end

--- @param character EsvCharacter
Helpers.HasCounterAttacked = function(character)
	local combat = Ext.ServerEntity.GetCombat(CombatGetIDForCharacter(character.MyGuid))
	if combat then
		for i, team in pairs(combat:GetNextTurnOrder()) do
			if team.Character.MyGuid == character.MyGuid then
				return team.EntityWrapper.CombatComponentPtr.CounterAttacked
			end
		end
	end
end

--- @param character EsvCharacter
--- @param flag boolean
Helpers.SetHasCounterAttacked = function(character, flag)
	local combat = Ext.ServerEntity.GetCombat(CombatGetIDForCharacter(character.MyGuid))
	if combat then
		for i, team in pairs(combat:GetNextTurnOrder()) do
			if team and team.Character.MyGuid == character.MyGuid then
				team.EntityWrapper.CombatComponentPtr.CounterAttacked = flag
			end
		end
	end
end

---@param prioritizeSecondPlayer boolean|nil
---@return EclCharacter|nil
--- Credits to LaughingLeader
Helpers.GetPlayerManagerCharacter = function(prioritizeSecondPlayer)
    local playerManager = Ext.Entity.GetPlayerManager()
    if playerManager then
        if prioritizeSecondPlayer then
            local player2Data = playerManager.ClientPlayerData[2]
            if player2Data then
                local client = Ext.Entity.GetCharacter(player2Data.CharacterNetId)
                if client then
                    return client
                end
            end
        end
        for id,data in pairs(playerManager.ClientPlayerData) do
            local client = Ext.Entity.GetCharacter(data.CharacterNetId)
            if client then
                return client
            end
        end
    end
    return nil
end

Helpers.VPPrint = function(text, module, ...)
	if module then
		module = "["..module.."]"
	end
	Ext.Utils.Print("[V++]"..(module or "").." "..tostring(text), table.unpack({...}))
end

_VPrint = Helpers.VPPrint

Helpers.VPPrintWarning = function(text, module, ...)
	if module then
		module = "["..module.."]"
	end
	Ext.Utils.PrintWarning("[V++]"..(module or "").." "..tostring(text), table.unpack({...}))
end

_VWarning = Helpers.VPPrintWarning

Helpers.VPPrintError = function(text, module, ...)
	if module then
		module = "["..module.."]"
	end
	Ext.Utils.PrintError("[V++]"..(module or "").." "..tostring(text), table.unpack({...}))
end

_VError = Helpers.VPPrintError

Helpers.ScalingFunctions = {
	ALD = Game.Math.GetAverageLevelDamage,
	BLD = Game.Math.GetLevelScaledDamage,
	WLD = Game.Math.GetLevelScaledWeaponDamage,
	MLD = Game.Math.GetLevelScaledMonsterWeaponDamage,
}

--- @param scaling string
--- @param character EclCharacter|EsvCharacter|EsvItem|nil
--- @param instigator EclCharacter|EsvCharacter|nil
Helpers.ScalingValues = function(scaling, character, instigator)
	if scaling == "SourceMaximumPhysicalArmor" then
		return instigator.Stats.MaxArmor
	elseif scaling == "SourceMaximumMagicArmor" then
		return instigator.Stats.MaxMagicArmor
	elseif scaling == "SourceCurrentPhysicalArmor" then
		return instigator.Stats.CurrentArmor
	elseif scaling == "SourceCurrentMagicArmor" then
		return instigator.Stats.CurrentMagicArmor
	end
end

---@param scaling string
---@param character EsvCharacter|EclCharacter|EsvItem|nil
---@param instigator EsvCharacter|EclCharacter|nil
Helpers.GetScaledValue = function(scaling, character, instigator)
	if Helpers.ScalingFunctions[scaling] then
		return Helpers.ScalingFunctions[scaling](instigator.Stats.Level)
	else
		return Helpers.ScalingValues(scaling, character, instigator)
	end
end

--- @param character EsvCharacter|EclCharacter
--- @param damageType DamageType
Helpers.CharacterGetAbsorbShield = function(character, damageType)
	return character:GetStatus("LX_SHIELD_"..string.upper(damageType))
end

Helpers.EquipmentSlots = {
	 "Helmet",
	 "Breast",
	 "Leggings",
	 "Weapon",
	 "Shield",
	 "Ring",
	 "Belt",
	 "Boots",
	 "Gloves",
	 "Amulet",
	 "Ring2",
	 "Wings",
	 "Horns",
	 "Overhead",
}

--- @param object EsvCharacter|EclCharacter|EsvItem|EclItem
Helpers.EntityHasTag = function(object, tag)
	for _,j in ipairs(object:GetTags()) do
		if tag == j then
			return true
		end
	end
	return false
end

Helpers.Sign = function(number)
	return number > 0 and "+" or ""
end

Helpers.Stats = {}

---@param entry StatEntryPotion|StatEntryCharacter|StatEntryWeapon|StatEntrySkillData|StatEntryStatusData|StatEntryArmor|StatEntryShield|StatEntryObject
Helpers.Stats.GetEntryType = function(entry)
	local entryTable = {}
	for i,j in pairs(entry) do
		entryTable[i] = j
	end
	if entryTable.StatusType ~= null then
		return "StatusData"
	elseif entryTable.SkillType ~= null then
		return "SkillData"
	elseif entryTable.WeaponType ~= null then
		return "Weapon"
	elseif entryTable.Blocking ~= null then
		return "Shield"
	elseif entryTable["Armor Defense Value"] ~= null then
		return "Armor"
	elseif entryTable.IsFood ~= null then
		return "Potion"
	elseif entryTable.RuneEffectWeapon ~= null then
		return "Object"
	elseif entryTable.FOV ~= null then
		return "Character"
	end
end

Helpers.Status = {}

Helpers.Status.MultipliedStats = {}

---Multiply a status, including damage if there is a damage entry
---@param status EsvStatus
Helpers.Status.Multiply = function(status, multiplier)
	status.StatsMultiplier = multiplier
	if status.StatusType == "CONSUME" then
		local stat = Ext.Stats.Get(Ext.Stats.Get(status.StatusId).StatsId)
		if stat["Damage Multiplier"] > 0 then
			local character = Ext.ServerEntity.GetCharacter(status.TargetHandle)
			character.UserVars.LX_StatusConsumeMultiplier = multiplier
		end
		-- local newStatName = stat.Name.."_x"..Ext.Utils.Round(multiplier)
		-- Ext.Stats.Create(newStatName, "Potion", stat.Name)
		-- local multipliedStat = Ext.Stats.Get(newStatName) ---@type StatEntryPotion
		-- multipliedStat["Damage Multiplier"] = Ext.Utils.Round(multipliedStat.Damage * multiplier)
		-- status.StatsIds[1].StatsId = newStatName
		-- status.StatsId = newStatName
		-- Ext.Stats.Sync(newStatName, true)
		-- Helpers.Status.MultipliedStats[status] = newStatName
	elseif status.StatusType == "DAMAGE" then
		local stat = Ext.Stats.Get(status.DamageStats)
		local newStatName = stat.Name.."_x"..Ext.Utils.Round(multiplier)
		Ext.Stats.Create(newStatName, "Weapon", stat.Name)
		local multipliedStat = Ext.Stats.Get(newStatName) ---@type StatEntryWeapon
		multipliedStat.Damage = Ext.Utils.Round(multipliedStat.DamageFromBase * multiplier)
		Ext.Stats.Sync(newStatName, true)
		stat.DamageStats = newStatName
		Helpers.Status.MultipliedStats[status] = newStatName
	end
end

Helpers.UI = {}

Helpers.UI.GetTooltipNumberSign = function(number)
	return {
		Type = number > 0 and "StatusBonus" or "StatusMalus",
		Sign = number > 0 and "+" or "-"
	}
end

if Ext.IsServer() then
	Ext.Osiris.RegisterListener("CharacterStatusRemoved", 3, "before", function(target, status, instigator)
		if Helpers.Status.MultipliedStats[status] then
			Ext.Stats.Sync(Helpers.Status.MultipliedStats[status], false)
		end
	end)

		-------- Turn listeners (delay check)
	local TurnListeners = {
		Start = {},
		End = {}
	}

	Ext.Osiris.RegisterListener("CharacterGuarded", 1, "before", function(character)
		ObjectSetFlag(character, "HasDelayed")
	end)

	Ext.Osiris.RegisterListener("ObjectTurnEnded", 1, "before", function(character)
		if ObjectGetFlag(character, "HasDelayed") == 0 then
			for i, listener in pairs(TurnListeners.End) do
				listener.Handle(character)
			end
		end
	end)

	Ext.Osiris.RegisterListener("ObjectTurnStarted", 1, "before", function(character)
		if ObjectGetFlag(character, "HasDelayed") == 1 then
			ObjectClearFlag(character, "HasDelayed")
		else
			for i, listener in pairs(TurnListeners.Start) do
				listener.Handle(character)
			end
		end
	end)

	Helpers.RegisterTurnTrueStartListener = function(func)
		table.insert(TurnListeners.Start, {
			Name = "",
			Handle = func
		})
	end

	Helpers.RegisterTurnTrueEndListener = function(func)
		table.insert(TurnListeners.End, {
			Name = "",
			Handle = func
		})
	end
end

---@param str string
Helpers.SubstituteString = function(str, ...)
	local args = {...}
	local result = str

	for k, v in pairs(args) do
		if type(v) == "number" then
			if v == math.floor(v) then v = math.floor(v) end -- Formatting integers to not show .0
		end
			result = result:gsub("%["..tostring(k).."%]", v)
	end
	return result
end
	
---@param handle string
---@return string
Helpers.GetDynamicTranslationStringFromHandle = function(handle, ...)
	local args = {...}
	if handle == nil then return "" end

	local str = Ext.GetTranslatedString(handle, "Handle Error!")
	if str == "Handle Error!" then
		Helpers.VPPrint("Tooltip handle error:", "Tooltips", handle)
	end
	str = Helpers.SubstituteString(str, table.unpack(args))
	return str
end

--- Removes the _-1 at the end
---@param skillID string
---@return string
Helpers.GetFormattedSkillID = function(skillID)
	return string.sub(skillID, 1, string.len(skillID)-3)
end

---@param entity string
---@return boolean
Helpers.CheckEntityExistence = function(entity)
	return ObjectExists(entity) == 1
end

Helpers.GetSurfaceTypeAtPosition = function(x, z)
	local cell = Ext.Entity.GetAiGrid():GetCellInfo(x, z)
	return cell.GroundSurface and tostring(Ext.Entity.GetSurface(cell.GroundSurface).SurfaceType) or "None"
end

--- Helper for projectiles
---@param from table|GUID
---@param to table|GUID
---@param skillId string
---@param additionalProperties table|nil
Helpers.LaunchProjectile = function(from, to, skillId, additionalProperties)
	_P(from, to, skillId, additionalProperties)
	NRD_ProjectilePrepareLaunch()
	NRD_ProjectileSetInt("CasterLevel", 3);
	if type(from) == "table" then
		NRD_ProjectileSetVector3("SourcePosition", from[1], from[2]+1, from[3])
	else
		NRD_ProjectileSetGuidString("SourcePosition", from)
	end
	if type(to) == "table" then
		NRD_ProjectileSetVector3("TargetPosition", to[1], to[2], to[3])
	else
		NRD_ProjectileSetGuidString("TargetPosition", to)
	end
	NRD_ProjectileSetString("SkillId", skillId)
	if additionalProperties then
		for propertyType,data in pairs(additionalProperties) do
			for field,value in pairs(data) do
				Data.OsirisProjectileFunctions[propertyType](field, value)
			end
		end
	end
	NRD_ProjectileLaunch()
end

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

---@param char EsvCharacter|EclCharacter
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
		-- strRes = math.floor(Ext.Utils.Round((strength+next) * Ext.ExtraData.DGM_StrengthResistanceIgnore * 100))/100, -- Old Ingress multiplier behavior
		strIngCap = math.floor((strength+next) * Ext.ExtraData.DGM_StrengthIngressCap),
		fin = math.floor(finesse+next),
		finGlobal = math.floor((finesse+next) * Ext.ExtraData.DGM_FinesseGlobalBonus),
		finDodge = round((finesse+next) * Ext.ExtraData.DodgingBoostFromAttribute * 100, 0),
		finMovement = round((finesse+next) * Ext.ExtraData.DGM_FinesseMovementBonus / 100, 2),
		finCrit = math.floor((finesse+next) * Ext.ExtraData.DGM_FinesseCritChance),
		finAccCap = math.floor((finesse+next) * Ext.ExtraData.DGM_FinesseAccuracyFromIntelligenceCap),
		int = math.floor(intelligence+next),
		intGlobal = math.floor((intelligence+next) * Ext.ExtraData.DGM_IntelligenceGlobalBonus),
		intSkill = math.floor((intelligence+next) * Ext.ExtraData.DGM_IntelligenceSkillBonus),
		intAcc = math.floor((intelligence+next) * Ext.ExtraData.DGM_IntelligenceAccuracyBonus),
		intWisCap = math.floor((intelligence+next) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap),
		wits = math.floor(wits+next),
		witsCrit = math.floor((wits+next) * Ext.ExtraData.CriticalBonusFromWits),
		witsIni = math.floor((wits+next) * Ext.ExtraData.InitiativeBonusFromWits),
		witsDot = math.floor((wits+next) * Ext.ExtraData.DGM_WitsDotBonus),
		dual = math.floor(Ext.ExtraData.DGM_DualWieldingDamageBonus * (stats.DualWielding+next)),
		dualDodge = math.floor(Ext.ExtraData.CombatAbilityDodgingBonus * (stats.DualWielding+next)),
		dualOff = math.floor(Ext.ExtraData.DGM_DualWieldingOffhandBonus * (stats.DualWielding+next)),
		ranged = math.floor(Ext.ExtraData.DGM_RangedDamageBonus * (stats.Ranged+next)),
		rangedCrit = math.floor(Ext.ExtraData.CombatAbilityCritBonus * (stats.Ranged+next)),
		rangedRange = round(Ext.ExtraData.DGM_RangedRangeBonus * (stats.Ranged+next) * 0.01, 2),
		single = math.floor(Ext.ExtraData.DGM_SingleHandedDamageBonus * (stats.SingleHanded+next)),
		singleAcc = math.floor(Ext.ExtraData.CombatAbilityAccuracyBonus * (stats.SingleHanded+next)),
		singleArm = math.floor(Ext.ExtraData.DGM_SingleHandedArmorBonus * (stats.SingleHanded+next)),
		singleEle = math.floor(Ext.ExtraData.DGM_SingleHandedResistanceBonus * (stats.SingleHanded+next)),
		two = math.floor(Ext.ExtraData.DGM_TwoHandedDamageBonus * (stats.TwoHanded+next)),
		twoCrit = math.floor(Ext.ExtraData.CombatAbilityCritMultiplierBonus * (stats.TwoHanded+next)),
		twoAcc = math.floor(Ext.ExtraData.DGM_TwoHandedCTHBonus * (stats.TwoHanded+next)),
		persArm = math.floor(Data.Math.GetHealValue(Ext.Stats.Get("POST_PHYS_CONTROL"), char) * (stats.Perseverance+next)),
		persVit = math.floor(Ext.ExtraData.DGM_PerseveranceResistance * (stats.Perseverance+next)),
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
    local using = stat.Using
    while using ~= nil and using ~= "" and using ~= value do
        using = Ext.GetStat(using).Using
    end

    return using == value
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

skillAbilities = {
	Fire = "FireSpecialist",
	Earth = "EarthSpecialist",
	Water = "WaterSpecialist",
	Air = "AirSpecialist",
	Rogue = "RogueLore",
	Warrior = "WarriorLore",
	Ranger = "RangerLore",
	Summoning = "Summoning",
	Death = "Necromancy",
	Polymorph = "Polymorph"
}

GB4Talents = {
    "Sadist",
    "Haymaker",
    "Gladiator",
    "Indomitable",
    -- "Jitterbug",
    "Soulcatcher",
    -- "MasterThief",
    "GreedyVessel",
    "MagicCycles",
	-- "WildMag",
	-- "Elementalist"
}

resistances = {
    "FireResistance",
    "WaterResistance",
    "AirResistance",
    "EarthResistance",
    "PoisonResistance",
    "PhysicalResistance",
    "PiercingResistance"
}

--- @param character EsvCharacter
--- @param prefix string
function FindStatus(character, prefix)
	for i,status in pairs(character:GetStatuses()) do
		if string.find(status, prefix) then
			return status
		end
	end
	return
end

--- @param character EsvCharacter | EclCharacter
--- @param prefix string
function FindTag(character, prefix)
	for i,tag in pairs(character:GetTags()) do
		if string.find(tag, prefix) then
			return tag
		end
	end
	return
end

engineStatuses = {
	HIT = true,
	DYING = true,
	HEAL = true,
	-- MUTED = true,
	-- CHARMED = true,
	-- KNOCKED_DOWN = true,
	SUMMONING = true,
	HEALING = true,
	THROWN = true,
	TELEPORT_FALLING = true,
	CONSUME = true,
	COMBAT = true,
	AOO = true,
	STORY_FROZEN = true,
	SNEAKING = true,
	UNLOCK = true,
	-- FEAR = true,
	BOOST = true,
	UNSHEATHED = true,
	STANCE = true,
	SITTING = true,
	LYING = true,
	-- BLIND = true,
	-- SMELLY = true,
	CLEAN = true,
	INFECTIOUS_DISEASED = true,
	-- INVISIBLE = true,
	ROTATE = true,
	ENCUMBERED = true,
	IDENTIFY = true,
	REPAIR = true,
	MATERIAL = true,
	LEADERSHIP = true,
	EXPLODE = true,
	ADRENALINE = true,
	-- SHACKLES_OF_PAIN = true,
	SHACKLES_OF_PAIN_CASTER = true,
	WIND_WALKER = true,
	DARK_AVENGER = true,
	REMORSE = true,
	DECAYING_TOUCH = true,
	UNHEALABLE = true,
	FLANKED = true,
	CHANNELING = true,
	DRAIN = true,
	LINGERING_WOUNDS = true,
	INFUSED = true,
	SPIRIT_VISION = true,
	SPIRIT = true,
	DAMAGE = true,
	FORCE_MOVE = true,
	CLIMBING = true,
	-- INCAPACITATED = true,
	INSURFACE = true,
	SOURCE_MUTED = true,
	OVERPOWER = true,
	COMBUSTION = true,
	-- POLYMORPHED = true,
	DAMAGE_ON_MOVE = true,
	DEMONIC_BARGAIN = true,
	GUARDIAN_ANGEL = true,
	-- FLOATING = true,
	-- CHALLENGE = true,
	-- DISARMED = true,
	HEAL_SHARING = true,
	HEAL_SHARING_CASTER = true,
	EXTRA_TURN = true,
	ACTIVE_DEFENSE = true,
	SPARK = true,
	-- PLAY_DEAD = true,
	CONSTRAINED = true,
	EFFECT = true,
	DEACTIVATED = true,
	TUTORIAL_BED = true
}

function GetHealScaledValue(stat, healer)
	local HealTypeSkillData = healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint
	-- When the status type is HEALING, the initial value is copied over to the next HEAL ticks and automatically apply the Hydro/Geo bonus
	if stat.StatusType == "HEALING" then
		HealTypeSkillData = 0
	elseif stat.HealStat == "PhysicalArmor" then
		HealTypeSkillData = healer.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint
	elseif stat.HealStat == "MagicArmor" then
		HealTypeSkillData = healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint
	end
	return Ext.Round(stat.HealValue * Game.Math.GetAverageLevelDamage(healer.Stats.Level) * Ext.ExtraData.HealToDamageRatio / 100 * (1 + HealTypeSkillData/100))
end

DamageScalingFormulas = {
	ALD = Game.Math.GetAverageLevelDamage,
	BLD = Game.Math.GetLevelScaledDamage,
	BWD = Game.Math.GetLevelScaledWeaponDamage,
	BMD = Game.Math.GetLevelScaledMonsterWeaponDamage
}

Helpers.NullGUID = "NULL_00000000-0000-0000-0000-000000000000"

--- @class HitHelpers
HitHelpers = {}

damageTypes = {
    "Physical",
    "Piercing",
    "Fire",
    "Air",
    "Water",
    "Earth",
    "Poison",
    "Shadow",
    "Corrosive",
    "Magic"
}

magicDamageTypes = {
    "Fire",
    "Air",
    "Water",
    "Earth",
    "Poison",
    "Magic"
}

physicalDamageTypes = {
    "Physical",
    "Corrosive"
}

--- @param hit StatsHitDamageInfo
HitHelpers.HitGetMagicDamage = function(hit)
    local total = 0
    for i,dmgType in pairs(magicDamageTypes) do
        total = total + hit.DamageList:GetByType(dmgType)
    end
    return total
end

--- @param hit StatsHitDamageInfo
HitHelpers.HitGetPhysicalDamage = function(hit)
    local total = 0
    for i,dmgType in pairs(physicalDamageTypes) do
        total = total + hit.DamageList:GetByType(dmgType)
    end
    return total
end

--- @param hit StatsHitDamageInfo
HitHelpers.HitGetTotalDamage = function(hit)
    local total = 0
    for i,dmgType in pairs(damageTypes) do
        total = total + hit.DamageList:GetByType(dmgType)
    end
    return total
end

--- @param hit StatsHitDamageInfo
--- @param target EsvCharacter | EsvItem
HitHelpers.HitRecalculateAbsorb = function(hit, target)
    if Helpers.IsCharacter(target) then
        local physDmg = HitHelpers.HitGetPhysicalDamage(hit)
        local magicDmg = HitHelpers.HitGetMagicDamage(hit)
        local pArmourAbsorb = math.min(target.Stats.CurrentArmor, physDmg)
        local mArmourAbsorb = math.min(target.Stats.CurrentMagicArmor, magicDmg)
        hit.ArmorAbsorption = math.min(pArmourAbsorb + mArmourAbsorb, hit.TotalDamageDone)
	else
		hit.ArmorAbsorption = 0
    end
end

--- @param hit StatsHitDamageInfo
--- @param instigator EsvCharacter
HitHelpers.HitRecalculateLifesteal = function(hit, instigator)
    if hit.DoT or hit.Surface or getmetatable(instigator) ~= "esv::Character" then return end
    hit.LifeSteal = math.floor(Ext.Utils.Round((instigator.Stats.LifeSteal / 100) * (hit.TotalDamageDone - hit.ArmorAbsorption)))
end

--- @param hit StatsHitDamageInfo
--- @param target EsvCharacter | EsvItem
--- @param instigator EsvCharacter
--- @param damageType string
--- @param amount integer
HitHelpers.HitAddDamage = function(hit, target, instigator, damageType, amount)
    hit.TotalDamageDone = math.ceil(hit.TotalDamageDone + amount)
    hit.DamageList:Add(damageType, amount)
	if Helpers.IsCharacter(target) then
    	HitHelpers.HitRecalculateAbsorb(hit, target)
	else
		hit.ArmorAbsorption = 0
	end
    if instigator ~= nil then
        HitHelpers.HitRecalculateLifesteal(hit, instigator)
    end
end

--- @param hit StatsHitDamageInfo
--- @param target EsvCharacter | EsvItem
HitHelpers.HitMultiplyDamage = function(hit, target, instigator, multiplier)
    hit.DamageList:Multiply(multiplier)
    hit.TotalDamageDone = HitHelpers.HitGetTotalDamage(hit)
    HitHelpers.HitRecalculateAbsorb(hit, target)
    if instigator ~= nil then
        HitHelpers.HitRecalculateLifesteal(hit, instigator)
    end
end

--- @class HitFlags
--- @field Dodged boolean
--- @field Missed boolean
--- @field Critical boolean
--- @field Backstab boolean
--- @field DamageSourceType CauseType
--- @field Blocked boolean
--- @field IsDirectAttack boolean
--- @field IsWeaponAttack boolean
--- @field IsStatusDamage boolean
--- @field FromReflection boolean
HitFlags = {
    Dodged = false,
    Missed = false,
    Critical = false,
    Backstab = false,
    DamageSourceType = "",
    Blocked = false,
    IsDirectAttack = false,
    IsWeaponAttack = false,
	IsStatusDamage = false,
	FromReflection = false
}

HitFlags.__index = HitFlags

function HitFlags:Create()
    local this = {}
    setmetatable(this, self)
    return this
end