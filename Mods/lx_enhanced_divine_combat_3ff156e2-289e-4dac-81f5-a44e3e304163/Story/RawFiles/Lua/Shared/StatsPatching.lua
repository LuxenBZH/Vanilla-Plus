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
		["Target_TentacleLash"]	   = {},
		["Target_Condense"]		   = {},
	}

	for skill, params in pairs(descriptions) do
		local desc = GetDynamicTranslationString(skill, table.unpack(params))
		if desc == nil then desc = params end
		Ext.StatAddCustomDescription(skill, "SkillProperties", desc)
	end
end

local function OverrideBonus(name, type, multiplier)
	local boost = Ext.StatGetAttribute(name, type)
	if string.find(name, "Rune") ~= nil then return end
	if boost ~= '' then
		Ext.StatSetAttribute(name, type, math.floor(boost*multiplier))
	end
end

local function ReduceDeltaModBonuses()
	for i,name in pairs(Ext.GetStatEntries("Armor")) do
		if string.starts(name, "_Boost") then
			OverrideBonus(name, "Movement", 0.5)
			OverrideBonus(name, "CriticalChance", 0.5)
			OverrideBonus(name, "DodgeBoost", 0.5)
		end
	end
	for i,name in pairs(Ext.GetStatEntries("Weapon")) do
		if string.starts(name, "_Boost") then
			OverrideBonus(name, "Movement", 0.5)
			OverrideBonus(name, "CriticalChance", 0.5)
			OverrideBonus(name, "DodgeBoost", 0.5)
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


local function AdjustNPCStats()
	if Ext.Version() < 53 then return end
	local hardSaved = Ext.LoadFile("LeaderLib_GlobalSettings.json")
	local campaignScaling = true
	-- local GMscaling = false
	if Mods.LeaderLib ~= nil and hardSaved ~= nil and hardSaved ~= "" then
		local variables = Ext.JsonParse(hardSaved).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags
		if variables.LXDGM_NPCStatsCorrectionCampaignDisable.Enabled then campaignScaling = false end
		-- if variables.LXDGM_NPCStatsCorrectionGM.Enabled then GMscaling = true end
	end
	if campaignScaling then -- Ext.GetGameMode() == "Campaign" and campaignScaling then or Ext.GetGameMode() == "GameMaster" and GMscaling then
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
				local total = 0
				if stat.Strength ~= "None" and stat.Finesse ~= "None" and stat.Intelligence ~= "None" then
					total = tonumber(stat.Strength)+tonumber(stat.Finesse)+tonumber(stat.Intelligence)
				end
				-- Ext.StatSetAttribute(stat.Name, "DamageBoost", Ext.Round(stat.DamageBoost-total))
				for i,attr in pairs(attributes) do
					if stat[attr] ~= "None" then
						if attr == archetype then
							Ext.StatSetAttribute(stat.Name, attr, string.gsub(tostring(RoundToFirstDecimal((stat[attr])*(1-stat[attr]*Ext.ExtraData.DGM_NpcScalingMainAttributeCorrection*0.001))), ".0", ""))
						elseif archetype == "None" then
							Ext.StatSetAttribute(stat.Name, attr, string.gsub(tostring(RoundToFirstDecimal((stat[attr])*(1-stat[attr]*Ext.ExtraData.DGM_NpcScalingSecondaryAttributeCorrection*0.001))), ".0", ""))
						else
							Ext.StatSetAttribute(stat.Name, attr, string.gsub(tostring(RoundToFirstDecimal((stat[attr])*(1-stat[attr]*Ext.ExtraData.DGM_NpcScalingNoArchetypeCorrection*0.001))), ".0", ""))
						end
					end
				end
				-- if Ext.ExtraData.DGM_NpcVitalityMultiplier ~= 100 then
				-- 	Ext.StatSetAttribute(stat.Name, "Vitality", stat.Vitality*(Ext.ExtraData.DGM_NpcVitalityMultiplier/100))
				-- end
			end
		end
	end
end

local function CustomScalings()
	if Ext.ExtraData.DGM_PlayerVitalityMultiplier ~= 100 then
		for i,stat in pairs(Ext.GetStatEntries("Character")) do
			stat = Ext.GetStat(stat)
			if HasParent(stat, "_Hero") then
				Ext.StatSetAttribute(stat.Name, "Vitality", math.floor(Ext.Round(stat.Vitality*(Ext.ExtraData.DGM_PlayerVitalityMultiplier/100))))
			end
		end
	end
	if Ext.ExtraData.SummonsVitalityMultiplier ~= 100 or Ext.ExtraData.SummonsDamageBoost ~= 0 then
		for i,stat in pairs(Ext.GetStatEntries("Character")) do
			stat = Ext.GetStat(stat)
			if string.find(stat.Name, "Summon_") == 1 then
				if Ext.ExtraData.SummonsVitalityMultiplier ~= 100 then
					Ext.StatSetAttribute(stat.Name, "Vitality", math.floor(Ext.Round(stat.Vitality*(Ext.ExtraData.DGM_SummonsVitalityMultiplier/100))))
				end
				if Ext.ExtraData.SummonsDamageBoost ~= 0 then
					Ext.StatSetAttribute(stat.Name, "DamageBoost", math.floor(Ext.Round(stat.DamageBoost+Ext.ExtraData.DGM_SummonsDamageBoost)))
				end
			end
		end
	end
end

local function ChameleonCloakRevert()
	local hardSaved = Ext.LoadFile("LeaderLib_GlobalSettings.json")
	if hardSaved ~= nil then
		local variables = Ext.JsonParse(hardSaved).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags
		if variables.LXDGM_ModuleOriginalChameleonCloak.Enabled then
			Ext.Print("Reverting Chameleon Cloak requirements...")
			local requirements = {}
			for i,requirement in pairs(Ext.GetStat("Shout_ChameleonSkin").MemorizationRequirements) do
				if requirement.Param ~= 2 and requirement ~= "RogueLore" then
					table.insert(requirements, requirement)
				end
			end
			Ext.GetStat("Shout_ChameleonSkin").MemorizationRequirements = requirements
			Ext.GetStat("SKILLBOOK_Polymorph_ChameleonSkin").Requirements = requirements
		end
	end
end

local function FlatScaling(fromState, toState)
	if toState == "LoadLevel" then
		local hardSaved = Ext.LoadFile("LeaderLib_GlobalSettings.json")
		if hardSaved ~= nil then
			local variables = Ext.JsonParse(hardSaved).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags
			if not Ext.IsClient() and PersistentVars.FlatScaling then
				-- Ext.ExtraData.VitalityToDamageRatio = 6
				-- Ext.ExtraData.VitalityToDamageRatioGrowth = 0.2
				Ext.ExtraData.FirstPriceLeapGrowth = 1
				Ext.ExtraData.SecondVitalityLeapGrowth = 1
				Ext.ExtraData.ThirdVitalityLeapGrowth = 1
				Ext.ExtraData.VitalityExponentialGrowth = 1
				Ext.ExtraData.VitalityLinearGrowth = 20
				Ext.ExtraData.VitalityStartingAmount = 200
			end
		end
	end
end

local function AttributeCap()
	local hardSaved = Ext.LoadFile("LeaderLib_GlobalSettings.json")
	if hardSaved ~= nil then
		local variables = Ext.JsonParse(hardSaved).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags
		if variables.LXDGM_AttributeCap then
			Ext.ExtraData.AttributeSoftCap = variables.LXDGM_AttributeCap
		end
	end
end

local function TeleportRevert()
	local hardSaved = Ext.LoadFile("LeaderLib_GlobalSettings.json")
	if hardSaved ~= nil then
		local variables = Ext.JsonParse(hardSaved).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags
		if variables.LXDGM_ModuleOriginalTeleport and variables.LXDGM_ModuleOriginalTeleport.Enabled then
			Ext.Print("Reverting Teleport and Nether Swap targetting conditions...")
			Ext.AddPathOverride("Public/lx_enhanced_divine_combat_3ff156e2-289e-4dac-81f5-a44e3e304163/Stats/Generated/Data/LX_TeleportNS.txt", "Public/lx_enhanced_divine_combat_3ff156e2-289e-4dac-81f5-a44e3e304163/Stats/Generated/Data/LX_Empty.txt")
		end
	end
end

local function FixPhysicalResistance()
	if Ext.Version() <= 55 then
		for i,stat in pairs(Ext.GetStatEntries("Character")) do
			stat = Ext.GetStat(stat)
			local physicalResistance = stat.PhysicalResistance
			if physicalResistance > 0 then
				Ext.StatSetAttribute(stat.Name, "PhysicalResistance", math.floor(physicalResistance/2))
			end
		end
	end
end

Ext.RegisterListener("GameStateChanged", FlatScaling)
Ext.RegisterListener("StatsLoaded", AttributeCap)
Ext.RegisterListener("StatsLoaded", AddDamageToDescription)
Ext.RegisterListener("StatsLoaded", AdaptWeaponEnhancingSkills)
Ext.RegisterListener("StatsLoaded", AddAdditionalDescription)
Ext.RegisterListener("StatsLoaded", ReduceDeltaModBonuses)
Ext.RegisterListener("StatsLoaded", ReplaceDescriptionParams)
Ext.RegisterListener("StatsLoaded", AdjustNPCStats)
Ext.RegisterListener("StatsLoaded", CustomScalings)
Ext.RegisterListener("StatsLoaded", ChameleonCloakRevert)
Ext.RegisterListener("StatsLoaded", FixPhysicalResistance)
Ext.RegisterListener("ModuleLoadStarted", TeleportRevert)
