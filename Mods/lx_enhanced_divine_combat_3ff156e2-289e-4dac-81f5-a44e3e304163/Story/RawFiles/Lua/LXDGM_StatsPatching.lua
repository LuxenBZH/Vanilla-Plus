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
			end
		end
	end
end

local function AddAdditionalDescription()
	local descriptions = {
		["Target_EvasiveManeuver"] = {},
		["Target_Fortify"]         = {Ext.ExtraData.DGM_FortifiedPassingPhysicalReduction*100},
		["Shout_MendMetal"]        = {Ext.ExtraData.DGM_MendMetalPassingPhysicalReduction*100},
		["Shout_SteelSkin"]        = {Ext.ExtraData.DGM_SteelSkinPassingPhysicalReduction*100},
		["Target_FrostyShell"]     = {Ext.ExtraData.DGM_MagicShellPassingMagicReduction*100},
		["Shout_FrostAura"]        = {Ext.ExtraData.DGM_FrostAuraPassingMagicReduction*100},
		["Shout_RecoverArmour"]    = {Ext.ExtraData.DGM_ShieldsUpPassingReduction*100}
	}

	for skill, params in pairs(descriptions) do
		local desc = GetDynamicTranslationString(skill, table.unpack(params))
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


Ext.RegisterListener("StatsLoaded", AddDamageToDescription)

Ext.RegisterListener("StatsLoaded", AdaptWeaponEnhancingSkills)

Ext.RegisterListener("StatsLoaded", AddAdditionalDescription)

Ext.RegisterListener("StatsLoaded", ReduceEquipmentMovementBonus)
