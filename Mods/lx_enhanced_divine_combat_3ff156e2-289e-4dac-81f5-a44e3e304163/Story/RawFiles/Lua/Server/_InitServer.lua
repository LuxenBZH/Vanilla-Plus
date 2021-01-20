Ext.Require("Server/DamageControl.lua")
Ext.Require("Server/ArmorSystem.lua")
Ext.Require("Server/CCSystem.lua")
Ext.Require("Server/Potions.lua")
Ext.Require("Server/Talents.lua")
Ext.Require("Server/Weapons.lua")
Ext.Require("Server/CustomBonuses.lua")
Ext.Require("Server/Modules/Modules.lua")
Ext.Require("Server/Consumables.lua")

if Mods.LeaderLib ~= nil then
	Mods.LeaderLib.Features.BackstabCalculation = false
	Mods.LeaderLib.Features.ResistancePenetration = false
end

-- UI functions
---@param uuid string
---@param id string
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

local function CleanBoosts(char)
	print("Clearing boosts...")
	TimerLaunch("DGM_GriffToAtusaFix", 50)
end

local function DGM_consoleCmd(cmd, ...)
	local params = {...}
	for i=1,10,1 do
		local par = params[i]
		if par == nil then break end
		if type(par) == "string" then
			par = par:gsub("&", " ")
			par = par:gsub("\\ ", "&")
			params[i] = par
		end
	end
	if cmd == "DGM_CleanPermaBoosts" then CleanBoosts() end
end

Ext.RegisterConsoleCommand("DGM_CleanPermaBoosts", DGM_consoleCmd)

-- local function EnableStatsOverride(flag)
--     if flag == "LXDGM_NPCStatsCorrectionCampaign" or "LXDGM_NPCStatsCorrectionGM" then
-- 		local hardSaved = Ext.LoadFile("VanillaPlus_SavedVariables.json")
-- 		local variables = {}
-- 		if hardSaved ~= nil and hardSaved ~= "" then
-- 			variables = Ext.JsonParse(hardSaved)
--             if flag == "LXDGM_NPCStatsCorrectionCampaignDisabled" then
--                 variables.LXDGM_NPCStatsCorrectionCampaignDisabled = true
--             elseif flag == "LXDGM_NPCStatsCorrectionGM" then
--                 variables.LXDGM_NPCStatsCorrectionGM = true
--             end
--         end
--         hardSaved = Ext.JsonStringify(variables)
--         Ext.SaveFile("VanillaPlus_SavedVariables.json", hardSaved)
-- 	end
-- end
-- Ext.RegisterOsirisListener("GlobalFlagSet", 1, "after", EnableStatsOverride)

-- local function DisableStatsOverride(flag)
--     if flag == "LXDGM_NPCStatsCorrectionCampaign" or "LXDGM_NPCStatsCorrectionGM" then
-- 		local hardSaved = Ext.LoadFile("VanillaPlus_SavedVariables.json")
-- 		local variables = {}
-- 		if hardSaved ~= nil and hardSaved ~= "" then
-- 			variables = Ext.JsonParse(hardSaved)
--             if flag == "LXDGM_NPCStatsCorrectionCampaignDisabled" then
--                 variables.LXDGM_NPCStatsCorrectionCampaignDisabled = false
--             elseif flag == "LXDGM_NPCStatsCorrectionGM" then
--                 variables.LXDGM_NPCStatsCorrectionGM = false
--             end
--         end
--         hardSaved = Ext.JsonStringify(variables)
--         Ext.SaveFile("VanillaPlus_SavedVariables.json", hardSaved)
-- 	end
-- end
-- Ext.RegisterOsirisListener("GlobalFlagCleared", 1, "after", DisableStatsOverride)


---- Create calls and queries
Ext.NewCall(CheckBoostTalents, "LX_EXT_CheckBoostTalents", "(CHARACTERGUID)_Character, (STRING)_Talent, (INTEGER)_Unlocked");
Ext.NewCall(CheckDuelist, "LX_EXT_CheckDuelist", "(CHARACTERGUID)_Character");

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