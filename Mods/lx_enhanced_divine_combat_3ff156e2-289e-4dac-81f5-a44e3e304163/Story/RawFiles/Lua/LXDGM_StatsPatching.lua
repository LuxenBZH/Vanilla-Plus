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
		Shout_FlamingTongues = "Skill:Projectile_Status_FlamingTongue:Damage",
		Shout_IceBreaker = "Weapon:DamageSurface_FrostExplosion:DamageFromBase"
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
				Ext.Print(bonusWeapon, Ext.StatGetAttribute(bonusWeapon, "DamageFromBase"))
			end
		end
	end
end

local function AddAdditionalDescription()
	local descriptions = {
		Target_EvasiveManeuver = "Prevent Dodge Fatigue when active.",
		Target_Fortify = "Reduce damage going through Physical armor by 50%",
		Shout_MendMetal = "Reduce damage going through Physical armor by 25%",
		Shout_SteelSkin = "Reduce damage going through Physical armor by 33%",
		Target_FrostyShell = "Reduce damage going through Magic armor by 50%",
		Shout_FrostAura = "Reduce damage going through Magic armor by 25%"
	}
	for skill,desc in pairs(descriptions) do
		Ext.StatAddCustomDescription(skill, "SkillProperties", desc)
	end
end

Ext.RegisterListener("StatsLoaded", AddDamageToDescription)
Ext.RegisterListener("StatsLoaded", AdaptWeaponEnhancingSkills)
Ext.RegisterListener("StatsLoaded", AddAdditionalDescription)