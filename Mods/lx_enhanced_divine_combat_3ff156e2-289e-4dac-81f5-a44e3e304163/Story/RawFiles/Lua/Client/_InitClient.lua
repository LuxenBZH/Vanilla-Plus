Ext.Require("Client/Systems/ClientTimer.lua")
Ext.Require("Client/SkillStatusTooltips.lua")
Ext.Require("Client/Tooltips.lua")
Ext.Require("Client/CharacterSheet/CSMisc.lua")
Ext.Require("Client/CharacterSheet/AbilitiesCap.lua")
Ext.Require("Client/CharacterSheet/CustomStats.lua")
Ext.Require("Client/DamageColour.lua")
Ext.Require("Client/CustomSkillPropertiesClient.lua")
Ext.Require("Client/LL_Tooltips.lua")

Ext.Require("Client/Talents/TalentManager.lua")
Ext.Require("Client/Talents/GamepadSupport.lua")
Ext.Require("Client/Talents/TalentMechanics.lua")
Ext.Require("Client/Modules/DivineTalentsClient.lua")

Ext.Require("Client/Fixes/ClientCasting.lua")
Ext.Require("Client/Systems/CustomStatusAttributes.lua")
Ext.Require("Client/Tooltips/CustomAttributes.lua")
Ext.Require("Client/Tooltips/CursorText.lua")
Ext.Require("Client/Tooltips/Items.lua")
Ext.Require("Client/Tooltips/CharacterSheet.lua")

Ext.Require("Client/Sync/Statuses.lua")
Ext.Require("Client/Sync/Equipment.lua")
Ext.Require("Client/Systems/SkillGroupClient.lua")

-- Ext.Require("Client/Systems/SkillCastManager.lua")

tooltipStatusDmgHelper = {}

Ext.RegisterListener("SessionLoaded", function()
    -- Register weapon entries that are used as DoTs in an array for skill tooltips in case there's a status damage description
	local statusDoTs = Ext.GetStatEntries("StatusData")
	tooltipStatusDmgHelper = {}
	for i,status in pairs(statusDoTs) do
		local entry = Ext.GetStat(status)
		if entry.StatusType == "DAMAGE" then
			-- Ext.Print(entry.StatusType, entry.Name, entry.DamageStats)
			if entry.DamageStats ~= "" then
				tooltipStatusDmgHelper[entry.DamageStats] = true
			end
		end
	end
end)
-- Ext.RegisterNetListener("DGM_test", function(...)
--     local statusConsole = Ext.GetBuiltinUI("Public/Game/GUI/statusConsole.swf")
--     statusConsole:ExternalInterfaceCall("BackToGMPressed")
-- end)

Ext.RegisterNetListener("DGM_RefreshWarmup", function(channel, payload)
	local info = Ext.JsonParse(payload)
	local character = Ext.ClientEntity.GetCharacter(info.Character)
	if character and character:GetStatus(info.Status) then
		character:GetStatus(info.Status).CurrentLifeTime = 6.0
	end
end)

-- Helpers.UI = {}
