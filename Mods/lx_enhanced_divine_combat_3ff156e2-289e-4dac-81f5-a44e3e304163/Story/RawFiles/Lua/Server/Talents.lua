---- Talents ----
---@param character EsvCharacter
---@param talent string
---@param unlocked boolean
function CheckBoostTalents(character, talent, unlocked)
	--Ext.Print("Talent ",talent," changed :",unlocked)
	if unlocked == 1 then
		unlocked = true
	else
		unlocked = false
	end
	
	if talent == "Resurrection" then
		--Ext.Print("[LXGDM_Talents.CheckBoostTalents] Check Talents after resurrection...")
		CheckAllTalents(character)
	end
	
	if talent == "Demon" then
		BoostFromTalentInt(character, "LX_DEMON", unlocked)
	elseif talent == "IceKing" then
		BoostFromTalentInt(character, "LX_ICEKING", unlocked)
	elseif talent == "Leech" then
		BoostFromTalentInt(character, "LX_LEECH", unlocked)
	elseif talent == "Stench" then
		BoostFromTalentInt(character, "LX_STENCH", unlocked)
	elseif talent == "AnimalEmpathy" then
		BoostFromTalentInt(character, "LX_PETPALSUMMONER", unlocked)
	elseif talent == "NoAttackOfOpportunity" then
		BoostFromTalentInt(character, "LX_DDGOOSE", unlocked)
	elseif talent == "Memory" then
		ManageMemory(character, unlocked)
	elseif talent == "Perfectionist" then
		CheckHothead(character)
	elseif talent == "ViolentMagic" then
		BoostFromTalentInt(character, "LX_SAVAGESORTILEGE", unlocked)
	elseif talent == "Raistlin" then -- Glass Cannon
		BoostFromTalentInt(character, "LX_GLASSCANNON", unlocked)
	end
end

---@param character string UUID
---@param unlocked boolean
function ManageMemory(character, unlocked)
	if unlocked then
		-- if CharacterGetHostCharacter() == character then Ext.Print("MEMORY UNLOCKED") end
		local currentBoost = NRD_CharacterGetPermanentBoostInt(character, "Memory")
		local mem = math.floor(Ext.GetCharacter(character).Stats.BaseMemory - currentBoost - Ext.ExtraData.AttributeBaseValue)
		local previousMem = GetVarInteger(character, "DGM_MemoryBoost")
		-- if previousMem == nil or previousMem == 0 then
		-- 	previousMem = mem
		-- end
		if previousMem == nil then
			previousMem = 0
		end
		local diff = mem - previousMem
		-- Ext.Print("memory", diff, previousMem, currentBoost, mem)
		if diff ~= 0 and previousMem ~= 0 then
			NRD_CharacterSetPermanentBoostInt(character, "Memory", currentBoost + diff)
		elseif previousMem == 0 and currentBoost == mem then -- compatibility with previous saves
			NRD_CharacterSetPermanentBoostInt(character, "Memory", mem)
		elseif previousMem == 0 then
			NRD_CharacterSetPermanentBoostInt(character, "Memory", currentBoost + mem)
		end
		CharacterAddAttribute(character, "Dummy", 0)
		SetVarInteger(character, "DGM_MemoryBoost", mem)
	-- else
		-- local memBonus = NRD_CharacterGetPermanentBoostInt(character, "Memory")
		-- local mem = math.floor(CharacterGetBaseAttribute(character, "Memory") - Ext.ExtraData.AttributeBaseValue)
		-- if memBonus-mem < 0 then
		-- 	NRD_CharacterSetPermanentBoostInt(character, "Memory", 0)
		-- else
		-- 	NRD_CharacterSetPermanentBoostInt(character, "Memory", memBonus - mem)
		-- end
		-- CharacterAddAttribute(character, "Dummy", 0)
	end
end

local function MnemonicLocked(character, talent)
	if talent ~= "Memory" then return end
	local memBonus = NRD_CharacterGetPermanentBoostInt(character, "Memory")
	local mem = math.floor(Ext.GetCharacter(character).Stats.BaseMemory - memBonus - Ext.ExtraData.AttributeBaseValue)
	if not Ext.GetCharacter(character).CharacterCreationFinished and Ext.GetGameMode() == "Campaign" then
		SetTag(character, "DGM_MemoryManagement")
		return
	end
	SetVarInteger(character, "DGM_MemoryBoost", 0)
	NRD_CharacterSetPermanentBoostInt(character, "Memory", memBonus-mem)
	CharacterAddAttribute(character, "Dummy", 0)
end

Ext.RegisterOsirisListener("CharacterLockedTalent", 2, "before", MnemonicLocked)

Ext.RegisterOsirisListener("CharacterCreationFinished", 1, "after", function(character)
	if Ext.GetCharacter(character) == nil then return end
	if Ext.GetCharacter(character).Stats.TALENT_Memory then
		ManageMemory(character, true)
	elseif IsTagged(character, "DGM_MemoryManagement") then
		TimerLaunch("MEMORY_"..character, 1000)
	end
	ClearTag(character, "DGM_MemoryManagement")
end)

Ext.RegisterOsirisListener("TimerFinished", 1, "after", function(timer)
	if string.starts(timer, "MEMORY_") then
		local character = string.gsub(timer, "MEMORY_", "")
		NRD_CharacterSetPermanentBoostInt(character, "Memory", 0)
		SetVarInteger(character, "DGM_MemoryBoost", 0)
		CharacterAddAttribute(character, "Dummy", 0)
	end
end)

---@param character EsvCharacter
function CheckAllTalents(character)
	local boostedTalents = {
		"Demon",
		"IceKing",
		"Leech",
		"Stench",
		"AnimalEmpathy",
		"NoAttackOfOpportunity",
		"Perfectionist",
		"ViolentMagic",
		"Raistlin"
	}
	for i,talent in pairs(boostedTalents) do
		local hasTalent = CharacterHasTalent(character, talent)
		--print("[LXDGM_Talents.CheckAllTalents] Character has talent:",talent,hasTalent)
		if hasTalent == 1 then CheckBoostTalents(character, talent, 1) end
	end
	if CharacterHasTalent(character, "ExtraStatPoints") == 1 then CheckDuelist(character) end
end

---@param character EsvCharacter
function CheckDuelist(character)
	local mainHand = Ext.GetCharacter(character).Stats.MainWeapon
	--Ext.Print("[LXDGM_Talents.CheckDuelist] Main hand :",mainHand)
	local offhand = Ext.GetCharacter(character).Stats.OffHandWeapon
	local shield = CharacterGetEquippedShield(character)
	if offhand ~= nil or (mainHand ~= nil and mainHand.IsTwoHanded) or mainHand.WeaponType == "None" or shield ~= nil then
		RemoveStatus(character, "LX_DUELIST")
	else
		ApplyStatus(character, "LX_DUELIST", -1.0, 1)
	end
end

---@param character EsvCharacter
---@param status string
---@param unlocked boolean
function BoostFromTalentInt(character, status, unlocked)
	if unlocked then
		ApplyStatus(character, status, -1.0, 1)
	else
		RemoveStatus(character, status)
	end
end

---@param target EsvCharacter
---@param handle string
function SetWalkItOff(target, handle)
	-- Call this function during damage control to potentially apply Walk It Off bonus
	local hasTalent = CharacterHasTalent(target, "WalkItOff")
	-- Ext.Print("Target has WalkItOff: ",hasTalent)
	if hasTalent == 1 then
		local surfaceHit = NRD_StatusGetInt(target, handle, "Surface")
		local dot = NRD_StatusGetInt(target, handle, "DoT")
		local reflection = NRD_StatusGetInt(target, handle, "Reflection")
		if surfaceHit == 0 and dot == 0 and reflection == 0 then
			WalkItOffReplacement(target)
		end
	end
end

---@param character EsvCharacter
function WalkItOffReplacement(character)
	local hasStatus = 0
	local wioStates = {"LX_WALKITOFF", "LX_WALKITOFF_2", "LX_WALKITOFF_3"}
	local reapply = false
	for i=1,3,1 do
		if reapply == true then
			ApplyStatus(character, wioStates[i], 6.0)
			return 
		end
		hasStatus = HasActiveStatus(character, wioStates[i])
		--Ext.Print("Has ",stage, ": ", hasStatus)
		if hasStatus == 1 then reapply = true end
		if hasStatus == 1 and wioStates[i] == "LX_WALKITOFF_3" then return end
	end
	ApplyStatus(character, "LX_WALKITOFF", 6.0)
end

---@param character EsvCharacter
function CheckHothead(character)
	local HPperc = Ext.Round(NRD_CharacterGetStatInt(character, "CurrentVitality") / NRD_CharacterGetStatInt(character, "MaxVitality") * 100)
	--Ext.Print(HPperc)
	if HPperc > Ext.ExtraData.DGM_HotheadApplicationThreshold then 
		ApplyStatus(character, "LX_HOTHEAD", -1.0, 1) 
	else
		RemoveStatus(character, "LX_HOTHEAD")
	end
end

---@param character EsvCharacter
---@param skill string
---@param cooldown number
function ManageAllSkilledUp(character, skill, cooldown)
	local hasUsedSkill = GetVarInteger(character, "LX_AllSkilledUp_Counter")
	if hasUsedSkill == 0 and cooldown > 6.0 then
		NRD_SkillSetCooldown(character, skill, (cooldown-6.0))
		SetVarInteger(character, "LX_AllSkilledUp_Counter", 1)
	end
end

---@param character EsvCharacter
---@param summon any
function ManagePetPal(character, summon)
	local summons = Osi.DB_DGM_Available_Summons:Get(character, nil);
	if summons[1] ~= nil and summons[2] ~= nil then
		for i,summon in pairs(summons) do
			if ObjectExists(summon[2]) == 0 then 
				Osi.DB_DGM_Available_Summons:Delete(character, summon[2])
				RestorePetPalPower(character, nil)
				return
			end
			ApplyStatus(summon[2], "LX_PETPAL", -1.0, 1)
		end
	end
end

---@param character EsvCharacter
---@param summon any
function RestorePetPalPower(character, summon)
	-- Call this function on DB remove of the second summon
	local summons = Osi.DB_DGM_Available_Summons:Get(character, nil)
	if summons[1] == nil then return end
	if GetTableSize(summons) < 2 then
		RemoveStatus(summons[1][2], "LX_PETPAL")
	end
end

local function ExecutionerHaste(defender, attackerOwner, attacker)
	if ObjectIsCharacter(attacker) == 0 then return end
	local attacker = Ext.GetCharacter(attacker)
	if attacker.Stats.TALENT_Executioner and CharacterIsInCombat(attacker.MyGuid) == 1 then
		ApplyStatus(attacker.MyGuid, "LX_EXECUTIONER", 6.0)
	end
end

Ext.RegisterOsirisListener("CharacterKilledBy", 3, "before", ExecutionerHaste)

---- Ambidextrous refund
---@param item EsvItem
---@param char EsvCharacter
Ext.RegisterOsirisListener("ItemEquipped", 2, "before", function(item, char)
	local character = Ext.GetCharacter(char) ---@type EsvCharacter
	if character.Stats.TALENT_Ambidextrous and CharacterIsInCombat(char) == 1 then
		item = Ext.GetItem(item) ---@type EsvItem
		if item.Stats.WeaponType and item.Stats.WeaponType ~= "Crossbow" then
			CharacterAddActionPoints(char, 1)
		end
	end
end)

---- Ambidextrous counter reset
---@param char EsvCharacter
Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", function(char)
	if Ext.GetCharacter(char).Stats.TALENT_Ambidextrous then
		SetVarInteger(char, "DGM_AmbidextrousCount", 2)
	end
end)

---- Elemental Ranger

local typeMap = {
	Fire = "FIRE",
	Water = "WATER",
	Poison = "POISON",
	Air = "ELECTRIC",
	Physical = "BLOOD",
	Earth = "OIL",
	Shadow = "BLOOD",
	None = ""
}

local surfaceTypeMap = {
	Fire = "FIRE",
	FireBlessed = "FIRE",
	FireCursed = "FIRE",
	FireCloud = "FIRE",
	FireCloudBlessed = "FIRE",
	FireCloudCursed = "FIRE",
	Water = "WATER",
	WaterFrozen = "WATER",
	WaterFrozenBlessed = "WATER",
	WaterFrozenCursed = "WATER",
	WaterBlessed = "WATER",
	WaterCursed = "WATER",
	WaterCloud = "WATER",
	WaterCloudBlessed = "WATER",
	WaterCloudCursed = "WATER",
	WaterElectrified = "ELECTRIC",
	WaterElectrifiedCursed = "ELECTRIC",
	WaterElectrifiedBlessed = "ELECTRIC",
	WaterCloudElectrified = "ELECTRIC",
	WaterCloudElectrifiedCursed = "ELECTRIC",
	WaterCloudElectrifiedBlessed = "ELECTRIC",
	BloodCloudElectrified = "ELECTRIC",
	BloodCloudElectrifiedCursed = "ELECTRIC",
	BloodCloudElectrifiedBlessed = "ELECTRIC",
	PoisonBlessed = "POISON",
	PoisonCursed = "POISON",
	PoisonCloud = "POISON",
	PoisonCloudBlessed = "POISON",
	PoisonCloudCursed = "POISON",
	Oil = "OIL",
	OilBlessed = "OIL",
	OilCursed = "OIL",
	Blood = "BLOOD",
	BloodCursed = "BLOOD",
	BloodBlessed = "BLOOD",
	BloodCloud = "BLOOD",
	BloodCloudBlessed = "BLOOD",
	BloodCloudCursed = "BLOOD",
}

--- @param character string GUID
--- @param skill string Name
--- @param skillType string Type
--- @param skillElement string Elements enum
Ext.RegisterOsirisListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
	if not Ext.GetCharacter(character).Stats.TALENT_ElementalRanger then return end
	local skill = Ext.GetStat(skill)
	if (skill.ProjectileType == "Grenade" and skill.Requirement == "None") or (skill.ProjectileType == "Arrow" and skill.Requirement == "RangedWeapon") and skill.IsEnemySkill == "Yes" and skill["Memory Cost"] == 0 then
		if skill.DamageType == "Chaos" then
			local random = math.random(1, 8)
			local i = 1
			for k,v in pairs(typeMap) do
				if random == i then
					if HasActiveStatus(character, "ARROWHEAD_"..v) == 0 then
						ApplyStatus(character, "ARROWHEAD_"..v, 6.0, 1)
					end
					break
				end
				i = i + 1
			end
		elseif skill.DamageType == "None" then
			local surfaces = {}
			for i, properties in pairs(skill.SkillProperties) do
				if properties.Action == "CreateSurface" then
					table.insert(surfaces, properties.Arg3)
				end
				if HasActiveStatus(character, "ARROWHEAD_"..surfaceTypeMap[properties.Arg3]) == 0 then
					ApplyStatus(character, "ARROWHEAD_"..surfaceTypeMap[properties.Arg3], 6.0, 1)
				end
			end
		else
			if HasActiveStatus(character, "ARROWHEAD_"..typeMap[skill.DamageType]) == 0 then
				ApplyStatus(character, "ARROWHEAD_"..typeMap[skill.DamageType], 6.0, 1)
			end
		end
	end
end)

---- Morning Person AP recovery
--- @param object GUID
Ext.Osiris.RegisterListener("ObjectTurnStarted", 1, "before", function(object)
	if ObjectIsCharacter(object) == 0 then return end
	local char = Ext.ServerEntity.GetCharacter(object)
	if char.Stats.TALENT_ResurrectToFullHealth then
		if char.Stats.CurrentAP == 0 then
			SetTag(object, "MorningPersonRecovery")
		elseif IsTagged(object, "MorningPersonRecovery") == 1 then
			ClearTag(object, "MorningPersonRecovery")
			CharacterAddActionPoints(object, 2)
		end
	end
end)

Ext.Osiris.RegisterListener("ObjectEnteredCombat", 2, "before", function(object, combatID)
	if ObjectIsCharacter(object) == 0 then return end
	if Ext.ServerEntity.GetCharacter(object).Stats.TALENT_ResurrectToFullHealth then
		ApplyWarmup(Ext.ServerEntity.GetCharacter(object), 2)
	end
end)

---- Guerilla invisibility effect
RegisterTurnTrueEndListener(function(character)
	if CharacterHasTalent(character, "Guerilla") == 1 and HasActiveStatus(character, "SNEAKING") == 1 and HasActiveStatus(character, "LX_GUERILLA_COOLDOWN") == 0 then
		ApplyStatus(character, "INVISIBLE", 6.0, 1, character)
		ApplyStatus(character, "LX_GUERILLA_COOLDOWN", 18.0, 1, character)
	end
end)

local ElementalAffinityAiFlags = {
    Fire = { "Lava", "Fire", "FireCloud" },
    Water = { "Water", "WaterCloud" },
    Air = { "Electrified" },
    Earth = { "Oil", "Poison", "PoisonCloud" },
    Death = { "Blood", "BloodCloud" },
    Sulfurology = { "Sulfurium" }
}

---- Elemental Affinity rework
--- @param e LuaGetSkillAPCostEvent
Ext.Events.GetSkillAPCost:Subscribe(function(e)
	local skill = e.Skill
	local character = e.Character
	local grid = e.AiGrid
	local position = e.Position
	local radius = e.Radius
    local baseAP = skill.ActionPoints
    if character == nil or baseAP <= 0 then
        return baseAP, false
    end
    
    local ability = skill.StatsObject.StatsEntry.Ability
    local elementalAffinity = false
    if ability ~= "None" and baseAP > 1 and character.TALENT_ElementalAffinity and grid ~= nil and position ~= nil and radius ~= nil then
        local aiFlags = ElementalAffinityAiFlags[ability]
        if aiFlags ~= nil then
            elementalAffinity = grid:SearchForCell(position[1], position[3], radius, aiFlags, -1.0)
            if elementalAffinity then
                baseAP = baseAP - 1
            end
        end
    end

    local characterAP = 1
    if skill.Requirement ~= "None" and skill.OverrideMinAP == "No" then
        characterAP = Game.Math.GetCharacterWeaponAPCost(character)
    end

	if character.Character:GetStatus("COMBAT") and not character.Character:HasTag("VP_UsedElementalAffinity") then
        e.ElementalAffinity = elementalAffinity
	    e.AP = math.max(characterAP, baseAP)
    else
        e.ElementalAffinity = false
    end
end)

---@param object GUID
Ext.Osiris.RegisterListener("ObjectTurnStarted", 1, "before", function(object)
    ClearTag(object, "VP_UsedElementalAffinity")
end)

---@param character GUID
---@param skill string
---@param skillType SkillType
---@param skillElement SkillAbility
Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
	if ObjectExists(character) == 0 then return end
	local char = Ext.ServerEntity.GetCharacter(character)
	local grid = Ext.ServerEntity.GetAiGrid()
	local aiFlags = ElementalAffinityAiFlags[skillElement]
	if aiFlags and char.Stats.TALENT_ElementalAffinity and not char:HasTag("VP_UsedElementalAffinity") and grid:SearchForCell(char.WorldPos[1], char.WorldPos[3], char.RootTemplate.AIBoundsRadius, aiFlags, -1.0) then
		SetTag(character, "VP_UsedElementalAffinity")
	end
end)