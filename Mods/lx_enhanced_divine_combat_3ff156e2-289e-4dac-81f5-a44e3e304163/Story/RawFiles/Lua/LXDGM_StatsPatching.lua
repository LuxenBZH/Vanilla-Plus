local function AddDamageToDescription()
	local skillList = {
		Shout_SparkingSwings = "Skill:Projectile_Status_Spark:Damage",
		Target_MasterOfSparks = "Skill:Projectile_Status_GreaterSpark:Damage",
		Target_CorpseExplosion = "Skill:Projectile_CorpseExplosion_Explosion:Damage",
		Shout_MassCorpseExplosion = "Skill:Projectile_CorpseExplosion_Explosion:Damage",
		Target_Sabotage = "Damage",
		Target_MassSabotage = "Damage",
		Projectile_LaunchExplosiveTrap = "Skill:Projectile_TrapLaunched:Damage",
		Projectile_DeployMassTraps = "Skill:Projectile_TrapLaunched:Damage",
		Shout_FlamingTongues = "Skill:Projectile_Status_FlamingTongues:Damage",
		Shout_IceBreaker = "Weapon:DamageSurface_FrostExplosion:DamageFromBase",
	}
	for skill,description in pairs(skillList) do
		local statDesc = Ext.StatGetAttribute(skill, "StatsDescriptionParams")
		if statDesc ~= "" and statDesc ~= nil then
			Ext.StatSetAttribute(skill, "StatsDescriptionParams", statDesc..";"..description)
		else
			Ext.StatSetAttribute(skill, "StatsDescriptionParams", description)
		end
		--Ext.SyncStat(skill, false)
	end
end

local function AdaptWeaponEnhancingSkills()
	for i,name in pairs(Ext.GetStatEntries("Potion")) do
		local bonusWeapon = Ext.StatGetAttribute(name, "BonusWeapon")
		if bonusWeapon ~= '' then
			local weaponDamage = Ext.StatGetAttribute(bonusWeapon, "Damage")
			local weaponMultiplier = Ext.StatGetAttribute(bonusWeapon, "DamageFromBase")
			if weaponDamage == "AverageLevelDamge" or weaponDamage == 1 then
				Ext.StatSetAttribute(bonusWeapon, "Damage", 0)
				Ext.StatSetAttribute(bonusWeapon, "DamageFromBase", Ext.Round(weaponMultiplier*1.5))
				--Ext.SyncStat(bonusWeapon, false)
			end
		end
	end
end

local function AddAdditionalDescription()
	local descriptions = {
		["Target_EvasiveManeuver"] = {},
		["Target_Fortify"]         = {math.floor(Ext.ExtraData.DGM_FortifiedPassingPhysicalReduction*100)},
		["Shout_MendMetal"]        = {math.floor(Ext.ExtraData.DGM_MendMetalPassingPhysicalReduction*100)},
		["Shout_SteelSkin"]        = {math.floor(Ext.ExtraData.DGM_SteelSkinPassingPhysicalReduction*100)},
		["Target_FrostyShell"]     = {math.floor(Ext.ExtraData.DGM_MagicShellPassingMagicReduction*100)},
		["Shout_FrostAura"]        = {math.floor(Ext.ExtraData.DGM_FrostAuraPassingMagicReduction*100)},
		["Shout_RecoverArmour"]    = {math.floor(Ext.ExtraData.DGM_ShieldsUpPassingReduction*100)},
		["Target_TentacleLash"]	   = {}
	}

	for skill, params in pairs(descriptions) do
		local desc = GetDynamicTranslationString(skill, table.unpack(params))
		if desc == nil then desc = params end
		Ext.StatAddCustomDescription(skill, "SkillProperties", desc)
	end
end

local function ReduceEquipmentMovementBonus()
	for i,name in pairs(Ext.GetStatEntries("Armor")) do
		local boostArmor = Ext.StatGetAttribute(name, "Movement")
		if boostArmor ~= '' then
			Ext.StatSetAttribute(name, "Movement", math.floor(boostArmor/2))
		end
	end
end

local function ReplaceDescriptionParams()
	local skills = {
		Target_Bless = "Potion:Stats_Blessed:DodgeBoost;Potion:Stats_Blessed:AccuracyBoost;Potion:Stats_Blessed:FireResistance"
	}
	for skill,description in pairs(skills) do
		Ext.StatSetAttribute(skill, "StatsDescriptionParams", description)
		Ext.Print(bonusWeapon)
		--Ext.SyncStat(skill, false)
	end
end

local function GetParentStat(entry, stat)
	if entry[stat] == "None" and entry.Using ~= nil then
		GetParentStat(entry.Using, stat)
	else
		return entry[stat]
	end
end

--- @param character StatEntryObject
local function GetArchetype(stats)
	local strength = GetParentStat(stats, "Strength")
	local finesse = GetParentStat(stats, "Finesse")
	local intelligence = GetParentStat(stats, "Intelligence")
	--Ext.Print(stats.Name, strength, finesse, intelligence)
	if strength > finesse and strength > intelligence then
		return "Strength"
	elseif finesse > strength and finesse > intelligence then
		return "Finesse"
	elseif intelligence > strength and intelligence > finesse then
		return "Intelligence"
	end
	return "None"
end

local function HasParent(stat, value)
	if stat.Using == value then
		return true
	elseif stat.Using ~= nil or stat.Using == "" then
		HasParent(stat.Using, value)
	else
		return false
	end
end

local function CheckStoryMode()
	local ftj = Ext.GetStat("_FortJoyNPCs")
	local rc = Ext.GetStat("_ReapersCoastNPCs")
	local cos = Ext.GetStat("_CoS")
	local arx = Ext.GetStat("_ARX")
	Ext.Print(ftj.Name,rc.Name,cos.Name,arx.Name)
	if ftj ~= nil and rc ~= nil and cos ~= nil and arx ~= nil then
		return true
	else
		return false
	end
end

local function AdjustNPCStats()
	if CheckStoryMode() then
		Ext.Print("Overriding NPC stats for balance...")
		local attributes = {
			"Strength",
			"Finesse",
			"Intelligence"
		}
		for i,stat in pairs(Ext.GetStatEntries("Character")) do
			stat = Ext.GetStat(stat)
			if not HasParent(stat, "_Hero") and string.find(stat.Name, "Summon_") ~= 1 then
				local archetype = GetArchetype(stat)
				for i,attr in pairs(attributes) do
					if stat[attr] ~= "None" then
						if attr == archetype then
							Ext.StatSetAttribute(stat.Name, attr, string.gsub(tostring(RoundToFirstDecimal(stat[attr]*0.8)), ".0", ""))
						elseif archetype == "None" then
							Ext.StatSetAttribute(stat.Name, attr, string.gsub(tostring(RoundToFirstDecimal(stat[attr]*0.65)), ".0", ""))
						else
							Ext.StatSetAttribute(stat.Name, attr, string.gsub(tostring(RoundToFirstDecimal(stat[attr]*0.5)), ".0", ""))
						end
					end
				end
			end
		end
	end
end

Ext.RegisterListener("StatsLoaded", AddDamageToDescription)
Ext.RegisterListener("StatsLoaded", AdaptWeaponEnhancingSkills)
Ext.RegisterListener("StatsLoaded", AddAdditionalDescription)
Ext.RegisterListener("StatsLoaded", ReduceEquipmentMovementBonus)
Ext.RegisterListener("StatsLoaded", ReplaceDescriptionParams)
Ext.RegisterListener("StatsLoaded", AdjustNPCStats)
