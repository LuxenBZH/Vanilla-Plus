Ext.Require("LXDGM_Helpers.lua")
Ext.Require("LXDGM_DamageControl.lua")
Ext.Require("LXDGM_ArmorSystem.lua")
Ext.Require("LXDGM_CCSystem.lua")
Ext.Require("LXDGM_Potions.lua")
Ext.Require("LXDGM_Talents.lua")
Ext.Require("LXDGM_Weapons.lua")
Ext.Require("LXDGM_StatsPatching.lua")

---- General Functions ----
function InitCharacterStatCheck(character)
	local attributesStr = {
		"Finesse",
		"Intelligence",
		"Memory"
	}
	for i,attr in pairs(attributesStr) do
		local attribute = CharacterGetAttribute(character, attr)
		if attribute == nil then return end
		local baseAttribute = CharacterGetBaseAttribute(character, attr) - NRD_CharacterGetPermanentBoostInt(character, attr)
		--Ext.Print(character, "Stat init failed !")
		SetVarInteger(character, "LX_Check_"..attr, attribute)
		SetVarInteger(character, "LX_Check_Base_"..attr, baseAttribute)
		if attr == "Intelligence" then
			SetVarInteger(character, "LX_Changed_Intelligence", CharacterGetAttribute(character, attr)-10)
		end
		if attr == "Finesse" then
			SetVarInteger(character, "LX_Changed_Finesse", CharacterGetAttribute(character, attr)-10)
		end
		if attr == "Memory" and CharacterHasTalent(character, "Memory") == 1 then
			SetVarInteger(character, "LX_Changed_Base_Memory", CharacterGetBaseAttribute(character, attr)-10 - NRD_CharacterGetPermanentBoostInt(character ,"Memory"))
		end
	end
	InitCharacterAbilities(character)
	SetVarInteger(character, "LX_Is_Init", 1)
	CheckAllTalents(character)
	ApplyOverhaulAttributeBonuses(character)
end

function CheckStatChange(character)
	--[[ This function is called periodically, and return true if something has changed.
	Changed stats can be queried using LX_Changed_Base_Stat or LX_Changed_Stat with GetVarInteger.
	--]]
	local changed = false
	local isInit = GetVarInteger(character, "LX_Is_Init")
	if isInit == 0 or isInit == nil then
		InitCharacterStatCheck(character)
		InitCharacterAbilities(character)
		return false
	else
		local attributesStr = {
		"Finesse",
		"Intelligence",
		"Memory"}
		
		for i,attr in pairs(attributesStr) do
			if attr == "Memory" and CharacterHasTalent(character, "Memory") == 0 then goto continue end
			local stat = CharacterGetAttribute(character, attr)
			local baseStat = CharacterGetBaseAttribute(character, attr) - NRD_CharacterGetPermanentBoostInt(character, attr)
			local stored = GetVarInteger(character, "LX_Check_"..attr)
			local storedBase = GetVarInteger(character, "LX_Check_Base_"..attr)
			if stat ~= stored then
				--print(attr.." changed from "..stored.." to "..stat)
				changed = true
				--print("Stat change for "..character)
				SetVarInteger(character, "LX_Check_Base_"..attr, baseStat)
				SetVarInteger(character, "LX_Changed_Base_"..attr, baseStat - storedBase)
				SetVarInteger(character, "LX_Check_"..attr, stat)
				SetVarInteger(character, "LX_Changed_"..attr, stat - stored)
			else
				SetVarInteger(character, "LX_Changed_Base"..attr, 0)
				SetVarInteger(character, "LX_Changed"..attr, 0)
			end
			::continue::
		end
		
		local abilitiesStr = {
		"SingleHanded",
		"Ranged",
		"TwoHanded"
		}
		for i,attr in pairs(abilitiesStr) do
			local stat = CharacterGetAbility(character, attr)
			local stored = GetVarInteger(character, "LX_Check_"..attr)
			if stat ~= stored then
				print(attr.." changed from "..stored.." to "..stat)
				changed = true
				print("Stat change for "..character)
				SetVarInteger(character, "LX_Check_"..attr, stat)
				SetVarInteger(character, "LX_Changed_"..attr, stat - stored)
			else
				SetVarInteger(character, "LX_Changed_Base"..attr, 0)
				SetVarInteger(character, "LX_Changed"..attr, 0)
			end
		end
	end
	return changed
end

function ApplyOverhaulAttributeBonuses(character)
	---- This function should be called after a change check
	--print("Character :"..character)

	---- Attribute Bonus
	-- Movement Bonus
	ApplyBonusOnce(character, "Finesse", "Movement", Ext.ExtraData.DGM_FinesseMovementBonus, false)
	-- Accuracy bonus
	ApplyBonusOnce(character, "Intelligence", "Accuracy", Ext.ExtraData.DGM_IntelligenceAccuracyBonus, false)
	-- Memory Bonus for Mnemonic
	if CharacterHasTalent(character, "Memory") == 1 then 
		ApplyBonusOnce(character, "Memory", "Memory", 1, true) 
	end
end

function ApplyBonus(character, attribute, stat, multiplier, base)
	local currentBonus = NRD_CharacterGetPermanentBoostInt(character, stat)
	local change = "LX_Changed_"
	if base then change = change.."Base_" end
	local attChange = GetVarInteger(character, change..attribute)
	if attChange == nil or attChange == 0 then return end
	NRD_CharacterSetPermanentBoostInt(character, stat, currentBonus+multiplier*attChange)
	CharacterAddAttribute(character, "Dummy", 0)
end

function ApplyBonusOnce(character, attribute, stat, multiplier, base)
	ApplyBonus(character, attribute, stat, multiplier, base)
	local change = "LX_Changed_"
	if base then change = change.."Base_" end
	SetVarInteger(character, change..attribute, 0)
end


function ApplyOverhaulBonuses(character)
	ApplyOverhaulAttributeBonuses(character)
	ApplyOverhaulWeaponAbilityBonuses(character)
end

function ApplyOverhaulBonusesCheck(character)
	local isInit = GetVarInteger(character, "LX_Is_Init")
	if isInit == 0 or isInit == nil then
		InitCharacterStatCheck(character)
		InitCharacterAbilities(character)
	end
	CheckStatChange(character)
	ApplyOverhaulBonuses(character)
end

-- UI functions
function SendClientID(uuid, id)
	Ext.PostMessageToClient(uuid, "PDGM_ClientID", tostring(id))
end

local function RequestClientID(call,id,callbackID)
    local clientID = tonumber(id)
    if clientID ~= nil then
        local character = GetCurrentCharacter(clientID)
        if character ~= nil then
            if CharacterIsPlayer(character) == 1 then
				SendClientID(character, clientID)
                return true
            end
        end
    end
end

Ext.RegisterNetListener("PDGM_RequestClientID", RequestClientID)


---- Create calls and queries
Ext.NewCall(InitCharacterStatCheck, "LX_EXT_InitCharacterStatCheck", "(CHARACTERGUID)_Character");
Ext.NewCall(InitCharacterAbilities, "LX_EXT_InitCharacterAbilities", "(CHARACTERGUID)_Character");
Ext.NewQuery(CheckStatChange, "LX_EXT_CheckStatChange", "(CHARACTERGUID)_Character");
Ext.NewCall(CheckBoostTalents, "LX_EXT_CheckBoostTalents", "(CHARACTERGUID)_Character, (STRING)_Talent, (INTEGER)_Unlocked");
Ext.NewCall(CheckDuelist, "LX_EXT_CheckDuelist", "(CHARACTERGUID)_Character");

Ext.NewCall(ApplyOverhaulAttributeBonuses, "LX_EXT_ApplyAttributeBonuses", "(CHARACTERGUID)_Character");
Ext.NewCall(ApplyOverhaulWeaponAbilityBonuses, "LX_EXT_ApplyWeaponAbilityBonuses", "(CHARACTERGUID)_Character");
Ext.NewCall(ApplyOverhaulBonuses, "LX_EXT_ApplyOverhaulBonuses", "(CHARACTERGUID)_Character");
Ext.NewCall(ApplyOverhaulBonusesCheck, "LX_EXT_ApplyOverhaulBonusesCheck", "(CHARACTERGUID)_Character");

-- DamageControl
Ext.NewCall(DamageControl, "LX_EXT_DamageControl", "(GUIDSTRING)_Target, (INTEGER64)_HitHandle, (GUIDSTRING)_Instigator");
Ext.NewCall(ManagePerseverance, "LX_EXT_ManagePerseverance", "(GUIDSTRING)_Target, (INTEGER)_Perseverance, (STRING)_Type");

-- Status Control
Ext.NewCall(BlockPhysicalCCs, "LX_EXT_CheckPhysicalCC", "(GUIDSTRING)_Character, (STRING)_Status, (INTEGER64)_Handle");
Ext.NewCall(BlockMagicalCCs, "LX_EXT_CheckMagicalCC", "(GUIDSTRING)_Character, (STRING)_Status, (INTEGER64)_Handle");

-- Items Control
Ext.NewCall(CharacterUsePoisonedPotion, "LX_EXT_PoisonedPotionManagement", "(GUIDSTRING)_Character, (ITEMGUID)_Potion");
Ext.NewCall(ManagePotionFatigue, "LX_EXT_ManagePotionFatigue", "(CHARACTERGUID)_Character, (ITEMGUID)_Item");

-- Talents
Ext.NewCall(ManageAllSkilledUp, "LX_EXT_ManageAllSkilledUp", "(CHARACTERGUID)_Character, (STRING)_Skill, (REAL)_Cooldown");
Ext.NewCall(ManagePetPal, "LX_EXT_ManagePetPal", "(CHARACTERGUID)_Character, (CHARACTERGUID)_Summon");
Ext.NewCall(RestorePetPalPower, "LX_EXT_RestorePetPalPower", "(CHARACTERGUID)_Character, (CHARACTERGUID)_Summon");


