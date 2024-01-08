Data = {}
Data.IsServer = Ext.IsServer() -- Can be useful to know the variable context

Ext.Require("Shared/Helpers.lua")
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

tooltipStatusDmgHelper = {}

VPlusId = "3ff156e2-289e-4dac-81f5-a44e3e304163"

---The new function to scale down damage attributes
---@param value integer PenaltyQualifier
---@param level integer
local function NewMainAttributeScaling(value, level)
    value = Data.PenaltyQualifier[value]
    return (value >= 0 and 1 or -1) * math.ceil(value/10*level * Ext.ExtraData.AttributeBoostGrowth * 0.6)
end

local AttributesCorrection = {
    "StrengthBoost",
    "FinesseBoost",
    "IntelligenceBoost"
}

local StatTypeCorrection = {
    "Armor",
    "Weapon",
    "Shield"
}

Ext.Events.ModuleLoading:Subscribe(function(e)
    for i,statType in pairs(StatTypeCorrection) do
        for j,attribute in pairs(AttributesCorrection) do
            Ext.Stats.SetLevelScaling(statType, attribute, NewMainAttributeScaling)
        end
    end
end)
