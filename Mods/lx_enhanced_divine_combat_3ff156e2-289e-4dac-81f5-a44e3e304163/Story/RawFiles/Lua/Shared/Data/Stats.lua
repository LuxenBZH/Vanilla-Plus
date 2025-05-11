Data.Stats = {}

Data.Stats.StatsCustomAttributes = BootstrapModule

local function DataLoadStatsInfo(e)
	Helpers.VPPrint("Loading Stats Data...", "Stats:DataLoadStatsInfo", "Server:", Ext.IsServer())
	Data.Stats.CustomAttributeBonuses = {
		Finesse = {Potion = {VP_Celerity = Ext.ExtraData.DGM_FinesseMovementBonus, VP_CriticalMultiplier = Ext.ExtraData.DGM_FinesseCritMultBonus}, Status = {StackId = "DGM_Finesse"}, Cap = Ext.ExtraData.DGM_FinesseMovementCap},
		Intelligence = {Potion = {AccuracyBoost = Ext.ExtraData.DGM_IntelligenceAccuracyBonus}, Status = {StackId = "DGM_Intelligence"}, Cap = Ext.ExtraData.DGM_IntelligenceAccuracyCap}
	}

	Data.Stats.CustomWeaponAbilityBonuses = {
		SingleHanded = { Potion = {
				ArmorBoost=Ext.ExtraData.DGM_SingleHandedArmorBonus,
				MagicArmorBoost=Ext.ExtraData.DGM_SingleHandedArmorBonus,
				FireResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
				EarthResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
				PoisonResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
				WaterResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
				AirResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus
			}, Status = {StackId = "DGM_SingleHanded"}
		},
		-- TwoHanded = {},
		Ranged = {Potion = {RangeBoost=Ext.ExtraData.DGM_RangedRangeBonus}, Status = {StackId = "DGM_Ranged"}, Cap = 10},
		-- DualWielding = {},
		-- None = {}
	}

	Data.Stats.CustomAbilityBonuses = {
		Perseverance = {Potion = {Armor=Ext.ExtraData.DGM_PerseveranceArmorIncrease, MagicArmor=Ext.ExtraData.DGM_PerseveranceArmorIncrease}, Status = {StackId = "DGM_Perseverance"}, Cap = 10}
	}
	
	Data.Stats.CrossbowMovementPenalty = {
		Base = Ext.ExtraData.DGM_CrossbowBasePenalty,
		Level = Ext.ExtraData.DGM_CrossbowLevelGrowthPenalty
	}

	Data.Stats.WeaponAbilitiesBonuses = {
		SingleHanded = Ext.ExtraData.DGM_SingleHandedDamageBonus,
		DualWielding = Ext.ExtraData.DGM_DualWieldingDamageBonus,
		Ranged = Ext.ExtraData.DGM_RangedDamageBonus,
		TwoHanded = Ext.ExtraData.DGM_TwoHandedDamageBonus
	}

	Data.Stats.AbilityToDataValue = {
		-- FireSpecialist = Ext.ExtraData.SkillAbilityFireDamageBoostPerPoint,
		-- AirSpecialist = Ext.ExtraData.SkillAbilityAirDamageBoostPerPoint,
		-- EarthSpecialist = Ext.ExtraData.SkillAbilityPoisonAndEarthDamageBoostPerPoint,
		-- WaterSpecialist = Ext.ExtraData.SkillAbilityWaterDamageBoostPerPoint,
		-- WarriorLore = Ext.ExtraData.SkillAbilityPhysicalDamageBoostPerPoint,
		FireSpecialist = 5,
		AirSpecialist = 5,
		EarthSpecialist = 5,
		WaterSpecialist = 5,
		WarriorLore = 5,
		Necromancy = Ext.ExtraData.SkillAbilityLifeStealPerPoint,
		RangerLore = Ext.ExtraData.SkillAbilityHighGroundBonusPerPoint,
		RogueLore = Ext.ExtraData.SkillAbilityCritMultiplierPerPoint
	}

	
end

--- Stats doesn't load correctly sometimes for some reason. This metatable is a failsafe until the source of the problem is found
local nilTableHandler = {
    __index = function(table, key)
		if table[key] == nil then
			DataLoadStatsInfo(nil)
		end
        return nil
    end
}

Data.Stats.WeaponAbilitiesBonuses = {}
setmetatable(Data.Stats.WeaponAbilitiesBonuses, nilTableHandler)
Data.Stats.CrossbowMovementPenalty = {}
setmetatable(Data.Stats.CrossbowMovementPenalty, nilTableHandler)
Data.Stats.CustomWeaponAbilityBonuses = {}
setmetatable(Data.Stats.CustomWeaponAbilityBonuses, nilTableHandler)
Data.Stats.CustomAttributeBonuses = {}
setmetatable(Data.Stats.CustomAttributeBonuses, nilTableHandler)

if Ext.IsServer() then
	DataLoadStatsInfo(nil)
else
	Ext.Events.SessionLoaded:Subscribe(DataLoadStatsInfo)
	Ext.Events.StatsLoaded:Subscribe(DataLoadStatsInfo)
	Ext.Events.ResetCompleted:Subscribe(DataLoadStatsInfo)
end

---@type Enum
Data.TalentEnum = {
	ItemMovement = 1,
	ItemCreation = 2,
	Flanking = 3,
	AttackOfOpportunity = 4,
	Backstab = 5,
	Trade = 6,
	Lockpick = 7,
	ChanceToHitRanged = 8,
	ChanceToHitMelee = 9,
	Damage = 10,
	ActionPoints = 11,
	ActionPoints2 = 12,
	Criticals = 13,
	IncreasedArmor = 14,
	Sight = 15,
	ResistFear = 16,
	ResistKnockdown = 17,
	ResistStun = 18,
	ResistPoison = 19,
	ResistSilence = 20,
	ResistDead = 21,
	Carry = 22,
	Throwing = 23,
	Repair = 24,
	ExpGain = 25,
	ExtraStatPoints = 26,
	ExtraSkillPoints = 27,
	Durability = 28,
	Awareness = 29,
	Vitality = 30,
	FireSpells = 31,
	WaterSpells = 32,
	AirSpells = 33,
	EarthSpells = 34,
	Charm = 35,
	Intimidate = 36,
	Reason = 37,
	Luck = 38,
	Initiative = 39,
	InventoryAccess = 40,
	AvoidDetection = 41,
	AnimalEmpathy = 42,
	Escapist = 43,
	StandYourGround = 44,
	SurpriseAttack = 45,
	LightStep = 46,
	ResurrectToFullHealth = 47,
	Scientist = 48,
	Raistlin = 49,
	MrKnowItAll = 50,
	WhatARush = 51,
	FaroutDude = 52,
	Leech = 53,
	ElementalAffinity = 54,
	FiveStarRestaurant = 55,
	Bully = 56,
	ElementalRanger = 57,
	LightningRod = 58,
	Politician = 59,
	WeatherProof = 60,
	LoneWolf = 61,
	Zombie = 62,
	Demon = 63,
	IceKing = 64,
	Courageous = 65,
	GoldenMage = 66,
	WalkItOff = 67,
	FolkDancer = 68,
	SpillNoBlood = 69,
	Stench = 70,
	Kickstarter = 71,
	WarriorLoreNaturalArmor = 72,
	WarriorLoreNaturalHealth = 73,
	WarriorLoreNaturalResistance = 74,
	RangerLoreArrowRecover = 75,
	RangerLoreEvasionBonus = 76,
	RangerLoreRangedAPBonus = 77,
	RogueLoreDaggerAPBonus = 78,
	RogueLoreDaggerBackStab = 79,
	RogueLoreMovementBonus = 80,
	RogueLoreHoldResistance = 81,
	NoAttackOfOpportunity = 82,
	WarriorLoreGrenadeRange = 83,
	RogueLoreGrenadePrecision = 84,
	WandCharge = 85,
	DualWieldingDodging = 86,
	Human_Inventive = 87,
	Human_Civil = 88,
	Elf_Lore = 89,
	Elf_CorpseEating = 90,
	Dwarf_Sturdy = 91,
	Dwarf_Sneaking = 92,
	Lizard_Resistance = 93,
	Lizard_Persuasion = 94,
	Perfectionist = 95,
	Executioner = 96,
	ViolentMagic = 97,
	QuickStep = 98,
	Quest_SpidersKiss_Str = 99,
	Quest_SpidersKiss_Int = 100,
	Quest_SpidersKiss_Per = 101,
	Quest_SpidersKiss_Null = 102,
	Memory = 103,
	Quest_TradeSecrets = 104,
	Quest_GhostTree = 105,
	BeastMaster = 106,
	LivingArmor = 107,
	Torturer = 108,
	Ambidextrous = 109,
	Unstable = 110,
	ResurrectExtraHealth = 111,
	NaturalConductor = 112,
	Quest_Rooted = 113,
	PainDrinker = 114,
	DeathfogResistant = 115,
	Sourcerer = 116,
	Rager = 117,
	Elementalist = 118,
	Sadist = 119,
	Haymaker = 120,
	Gladiator = 121,
	Indomitable = 122,
	WildMag = 123,
	Jitterbug = 124,
	Soulcatcher = 125,
	MasterThief = 126,
	GreedyVessel = 127,
	MagicCycles = 128,
}

Data.Stats.WisdomTypes = {
	VP_WisdomBoost = "Vitality healings",
	VP_ArmorRegenBoost = "Physical armour healings",
	VP_MagicArmorRegenBoost = "Magic armour healings"
}

Data.Stats.Warmup = {
	[1] = "DGM_WARMUP1",
	[2] = "DGM_WARMUP2",
	[3] = "DGM_WARMUP3",
	[4] = "DGM_WARMUP4",
	DGM_WARMUP1 = 1,
	DGM_WARMUP2 = 2,
	DGM_WARMUP3 = 3,
	DGM_WARMUP4 = 4,
}

Data.Stats.EngineStatuses = {
	ACTIVE_DEFENSE = true,
	ADRENALINE = true,
	AOO = true,
	BOOST = true,
	CHANNELING = true,
	CHARMED = true,
	CLEAN = true,
	CLIMBING = true,
	COMBAT = true,
	COMBUSTION = true,
	CONSTRAINED = true,
	CONSUME = true,
	DAMAGE = true,
	DARK_AVENGER = true,
	DECAYING_TOUCH = true,
	DRAIN = true,
	DYING = true,
	EFFECT = true,
	ENCUMBERED = true,
	EXPLODE = true,
	FLANKED = true,
	FLOATING = true,
	FORCE_MOVE = true,
	HIT = true,
	IDENTIFY = true,
	INCAPACITATED = true,
	INFECTIOUS_DISEASED = true,
	INFUSED = true,
	INSURFACE = true,
	LEADERSHIP = true,
	LINGERING_WOUNDS = true,
	LYING = true,
	MATERIAL = true,
	OVERPOWER = true,
	POLYMORPHED = true,
	REMORSE = true,
	REPAIR = true,
	ROTATE = true,
	SHACKLES_OF_PAIN = true,
	SHACKLES_OF_PAIN_CASTER = true,
	SITTING = true,
	SMELLY = true,
	SNEAKING = true,
	SOURCE_MUTED = true,
	SPARK = true,
	SPIRIT = true,
	SPIRIT_VISION = true,
	STANCE = true,
	STORY_FROZEN = true,
	SUMMONING = true,
	TELEPORT_FALLING = true,
	THROWN = true,
	TUTORIAL_BED = true,
	UNHEALABLE = true,
	UNLOCK = true,
	UNSHEATHED = true,
	WIND_WALKER = true,
}

Data.Stats.HardcodedStatuses = {
	NONE = true,
	HIT = true,
	DYING = true,
	HEAL = true,
	MUTED = true,
	CHARMED = true,
	KNOCKED_DOWN = true,
	SUMMONING = true,
	HEALING = true,
	THROWN = true,
	SHIELD = true,
	FALLING = true,
	CONSUME = true,
	COMBAT = true,
	ATTACKOFOPP = true,
	STORY_FROZEN = true,
	SNEAKING = true,
	UNLOCK = true,
	FEAR = true,
	BOOST = true,
	UNSHEATHED = true,
	STANCE = true,
	SITTING = true,
	LYING = true,
	IDENTIFY = true,
	REPAIR = true,
	BLIND = true,
	SMELLY = true,
	CLEAN = true,
	INFECTIOUS_DISEASED = true,
	INVISIBLE = true,
	ROTATE = true,
	ENCUMBERED = true,
	MATERIAL = true,
	LEADERSHIP = true,
	EXPLODE = true,
	ADRENALINE = true,
	SHACKLES_OF_PAIN = true,
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
	CLIMBING = true,
	INCAPACITATED = true,
	SOURCE_MUTED = true,
	OVERPOWER = true,
	COMBUSTION = true,
	POLYMORPHED = true,
	DAMAGE_ON_MOVE = true,
	DEMONIC_BARGAIN = true,
	GUARDIAN_ANGEL = true,
	THICK_OF_THE_FIGHT = true,
	WINGS = true,
	CHALLENGE = true,
	DISARMED = true,
	HEAL_SHARING = true,
	HEAL_SHARING_CASTER = true,
	EXTRA_TURN = true,
	ACTIVE_DEFENSE = true,
	SPARK = true,
	PLAY_DEAD = true,
	CONSTRAINED = true,
	EFFECT = true,
	DEACTIVATED = true,
	TUTORIAL_BED = true
}

Data.Stats.BannedStatusesFromChecks = {
	DGM_Finesse = true,
	DGM_Intelligence = true,
	DGM_NoWeapon = true,
	DGM_OneHanded = true,
	DGM_Ranged = true,
	DGM_CrossbowSlow = true,
	GM_SELECTED = true,
	GM_SELECTEDDISCREET = true,
	GM_TARGETED = true,
	HIT = true,
	INSURFACE = true,
	SHOCKWAVE = true,
	UNSHEATHED = true,
	THROWN = true,
	HEAL = true,
	LEADERSHIP = true,
	LEADERLIB_RECALC = true,
	DGM_RECALC = true
}

for status, i in pairs(Data.Stats.HardcodedStatuses) do
    Data.Stats.BannedStatusesFromChecks[status] = i
end

Data.Stats.BannedStatusesFromChecks.CONSUME = nil
Data.Stats.BannedStatusesFromChecks.BLIND = nil

---@param status EsvStatus|EclStatus
-- Data.Stats.GetStatEntryFromStatus = function(status)
-- 	if status.StatusId == "CONSUME" then
-- 		return Ext.Stats.Get(status.)
-- end

Data.Stats.Talents = {}

Data.Stats.Talents.TorturerStatuses = {
	"BLEEDING",
	"BURNING",
	"NECROFIRE",
	"POISONED",
	"ACID",
	"SUFFOCATING",
	"ENTANGLED",
	"RUPTURE",
	"DAMAGE_ON_MOVE"
}

local torturerStatusesMetatable = {
	__index = function(table, key)
		if type(key) == "string" then
			local statEntry = Ext.Stats.Get(key, nil, false)
			for i,j in pairs(table.raw) do
				if key == j or (statEntry and HasParent(statEntry, j)) then
					return true
				end
			end
		elseif type(key) == "number" then
			return table.raw[key]
		end
		return nil
	end
}

-- Statuses that are children from vanilla Torturer statuses are also considered as affected by Torturer
Data.Stats.Talents.TorturerStatuses.raw = Data.Stats.Talents.TorturerStatuses -- Keep the original table as "raw"
setmetatable(Data.Stats.Talents.TorturerStatuses, torturerStatusesMetatable)