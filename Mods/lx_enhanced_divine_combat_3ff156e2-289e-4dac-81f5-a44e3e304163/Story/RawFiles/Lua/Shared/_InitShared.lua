Data = {}
Helpers = {}

Helpers.VPPrint = function(text, module, ...)
	if module then
		module = "["..module.."]"
	end
	Ext.Utils.Print("[V++]"..(module or "").." "..tostring(text), table.unpack({...}))
end

_VPrint = Helpers.VPPrint

Helpers.VPPrintWarning = function(text, module, ...)
	if module then
		module = "["..module.."]"
	end
	Ext.Utils.PrintWarning("[V++]"..(module or "").." "..tostring(text), table.unpack({...}))
end

_VWarning = Helpers.VPPrintWarning

Helpers.VPPrintError = function(text, module, ...)
	if module then
		module = "["..module.."]"
	end
	Ext.Utils.PrintError("[V++]"..(module or "").." "..tostring(text), table.unpack({...}))
end

_VError = Helpers.VPPrintError

Ext.Require("Shared/Systems/UserVars.lua")
Ext.Require("Shared/Helpers.lua")
Ext.Require("Shared/Helpers/Timers.lua")
Ext.Require("Shared/Helpers/GeneralHelpers.lua")
Ext.Require("Shared/Helpers/CharacterHelpers.lua")
Ext.Require("Shared/Helpers/StatsHelpers.lua")
Ext.Require("Shared/Helpers/StatusHelpers.lua")
Ext.Require("Shared/Helpers/HitHelpers.lua")
Ext.Require("Shared/Helpers/UIHelpers.lua")
Ext.Require("Shared/Helpers/AuraTargeting.lua")
Ext.Require("Shared/Systems/Requirements.lua")
Ext.Require("Shared/Settings.lua")
Ext.Require("Shared/StatsPatching.lua")
Ext.Require("Shared/StatusWizard.lua")
Ext.Require("Shared/Systems/StatusManager.lua")
Ext.Require("Shared/Systems/StatsProperties.lua")
Ext.Require("Shared/Data/Data.lua")
Ext.Require("Shared/Data/Text.lua")
Ext.Require("Shared/Data/Stats.lua")
Ext.Require("Shared/Data/Math.lua")
Ext.Require("Shared/Data/APCostManagement.lua")
Ext.Require("Shared/Systems/Weapons/RangedStances.lua")
Ext.Require("Shared/Systems/Weapons/WeaponArts.lua")

-- Skill Groups
Ext.Require("Shared/Systems/SkillGroups.lua")
Ext.Require("Shared/Data/SkillGroupsDefinition.lua")

tooltipStatusDmgHelper = {}

VPlusId = "3ff156e2-289e-4dac-81f5-a44e3e304163"

---The new function to scale down damage attributes
---@param value integer PenaltyQualifier
---@param level integer
-- local function NewMainAttributeScaling(value, level)
--     value = Data.PenaltyQualifier[value]
--     return (value >= 0 and 1 or -1) * math.ceil(value/10*level * Ext.ExtraData.AttributeBoostGrowth * 0.6)
-- end

-- local AttributesCorrection = {
--     "StrengthBoost",
--     "FinesseBoost",
--     "IntelligenceBoost"
-- }

-- local StatTypeCorrection = {
--     "Armor",
--     "Weapon",
--     "Shield"
-- }

-- Ext.Events.ModuleLoading:Subscribe(function(e)
--     for i,statType in pairs(StatTypeCorrection) do
--         for j,attribute in pairs(AttributesCorrection) do
--             Ext.Stats.SetLevelScaling(statType, attribute, NewMainAttributeScaling)
--         end
--     end
-- end)
