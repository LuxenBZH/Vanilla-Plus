Ext.Require("Server/ServerHelpers.lua")
Ext.Require("Server/Fixes/GeneralFixes.lua")
Ext.Require("Server/Fixes/Taunt.lua")
Ext.Require("Server/Fixes/UndeadFoodFix.lua")
Ext.Require("Server/Fixes/ServerCasting.lua")
Ext.Require("Server/Systems/CustomBonuses_NG.lua")
-- Ext.Require("Server/Systems/DamageControl_NG.lua")
Ext.Require("Server/Systems/DamageControl/DamageOverrides.lua")
Ext.Require("Server/Systems/DamageControl/HitManager.lua")
Ext.Require("Server/Systems/DamageControl/MainDamageControl.lua")
Ext.Require("Server/Systems/Warmup.lua")
Ext.Require("Server/Systems/WeaponLevelRange.lua")
Ext.Require("Server/Systems/Weapons/RangedStances.lua")
Ext.Require("Server/CustomAttributesServer.lua")
Ext.Require("Server/Mechanics.lua")
-- Ext.Require("Server/DamageControl.lua")
Ext.Require("Server/Resistance.lua")
Ext.Require("Server/AbsorbShield.lua")
Ext.Require("Server/ArmorSystem.lua")
Ext.Require("Server/CCSystem.lua")
Ext.Require("Server/Potions.lua")
Ext.Require("Server/Talents.lua")
Ext.Require("Server/Weapons.lua")
-- Ext.Require("Server/CustomBonuses.lua")
Ext.Require("Server/Modules/Modules.lua")
Ext.Require("Server/Consumables.lua")
Ext.Require("Server/CQBEffect.lua")
Ext.Require("Server/CustomSkillPropertiesServer.lua")
Ext.Require("Server/Miscelleanous.lua")
Ext.Require("Server/Statuses.lua")
Ext.Require("Server/Skills.lua")
Ext.Require("Server/Systems/SkillGroupServer.lua")
-- Ext.Require("Server/Systems/SkillMutator.lua")
-- Ext.Require("Server/SP_DMR.lua")
-- Ext.Utils.Include("3ff156e2-289e-4dac-81f5-a44e3e304163", "Server/SP_DiminishingReturn.lua")

if PersistentVars.SPunchCooldown == nil then
	PersistentVars.SPunchCooldown = {}
end

gameLevel = ""

Ext.RegisterOsirisListener("GameStarted", "2", "after", function(level, editor)
	gameLevel = level
end)

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

--- @param level integer
--- @param extra string[]
local function GetVitalityBoostByLevel(level, extra)
    local expGrowth = extra.VitalityExponentialGrowth
    local growth = expGrowth ^ (level - 1)

    if level >= extra.FirstVitalityLeapLevel then
        growth = growth * extra.FirstVitalityLeapGrowth / expGrowth
    end

    if level >= extra.SecondVitalityLeapLevel then
        growth = growth * extra.SecondVitalityLeapGrowth / expGrowth
    end

    if level >= extra.ThirdVitalityLeapLevel then
        growth = growth * extra.ThirdVitalityLeapGrowth / expGrowth
    end

    if level >= extra.FourthVitalityLeapLevel then
        growth = growth * extra.FourthVitalityLeapGrowth / expGrowth
    end

    local vit = level * extra.VitalityLinearGrowth + extra.VitalityStartingAmount * growth
    return Ext.Round(vit / 5.0) * 5.0
end

Ext.RegisterNetListener("DGM_FixConstitutionGap", function(...)
	OpenMessageBoxYesNo(CharacterGetHostCharacter(), "LXDGM_FixConstitutionGap_Message")
end)

Ext.RegisterOsirisListener("MessageBoxYesNoClosed", 3, "after", function(char, message, result)
	if message ~= "LXDGM_FixConstitutionGap_Message" then return end
	if result == 0 then return end
	local allCharacters = Ext.GetAllCharacters(gameLevel)
	local vanillaVars = {
		VitalityStartingAmount = 21,
		VitalityLinearGrowth = 9.091,
		FirstVitalityLeapLevel = 4,
		SecondVitalityLeapLevel = 9,
		ThirdVitalityLeapLevel = 12,
		FourthVitalityLeapLevel = 18,
		FirstVitalityLeapGrowth = 1.25,
		SecondVitalityLeapGrowth = 1.25,
		ThirdVitalityLeapGrowth = 1.25,
		FourthVitalityLeapGrowth = 1.35,
		VitalityExponentialGrowth = 1.25
	}
	for i,guid in pairs(allCharacters) do
		local vitalityPerc = CharacterGetHitpointsPercentage(guid)
		if vitalityPerc < 100 and vitalityPerc > 0 then
			local char = Ext.GetCharacter(guid)
			local oldMaxVitality = GetVitalityBoostByLevel(char.Stats.Level, vanillaVars)*(1+0.07*char.Stats.Constitution)
			local newMaxVitality = GetVitalityBoostByLevel(char.Stats.Level, Ext.ExtraData)*(1+Ext.ExtraData.VitalityBoostFromAttribute*char.Stats.Constitution)
			local ratio = newMaxVitality / oldMaxVitality
			
			if newMaxVitality > oldMaxVitality then
				if (char.Stats.CurrentVitality*ratio) / char.Stats.MaxVitality > 0.75 then
					char.Stats.CurrentVitality = char.Stats.MaxVitality
				else
					char.Stats.CurrentVitality = math.floor(char.Stats.CurrentVitality*ratio)
				end
			end
		end
	end
	local allItems = Ext.GetAllItems(gameLevel)
	for i,guid in pairs(allItems) do
		local item = Ext.GetItem(guid)
		if item.Vitality ~= 0 then
			local oldMaxVitality = GetVitalityBoostByLevel(item.LevelOverride, vanillaVars)
			local newMaxVitality = GetVitalityBoostByLevel(item.LevelOverride, Ext.ExtraData)
			local ratio = newMaxVitality / oldMaxVitality + 0.2
			item.Vitality = math.floor(item.Vitality*ratio)
		end
	end
end)

Ext.RegisterNetListener("LXDGM_FlatScalingWarning", function(...)
	OpenMessageBoxYesNo(CharacterGetHostCharacter(), "LXDGM_FlatScaling_Message1")
end)

Ext.RegisterNetListener("LXDGM_FlatScalingWarning2", function(...)
	OpenMessageBoxYesNo(CharacterGetHostCharacter(), "LXDGM_FlatScaling_Message2")
end)

Ext.RegisterOsirisListener("MessageBoxYesNoClosed", 3, "after", function(char, message, result)
	if message == "LXDGM_FlatScaling_Message1" then 
		if result == 0 then return end
		PersistentVars.FlatScaling = true
	elseif message == "LXDGM_FlatScaling_Message2" then
		if result == 0 then return end
		PersistentVars.FlatScaling = false
	end
end)


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
