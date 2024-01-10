Data = {}
Data.IsServer = Ext.IsServer() -- Can be useful to know the variable context

---@param attacker CDivinityStatsCharacter
---@param target CDivinityStatsCharacter
local function DGM_HitChanceFormula(attacker, target)
	local hitChance = attacker.Accuracy - target.Dodge + attacker.ChanceToHitBoost
    -- Make sure that we return a value in the range (0% .. 100%)
	hitChance = math.max(math.min(hitChance, 100), 0)
    return hitChance
end

--- @param e LuaGetHitChanceEvent
Ext.Events.GetHitChance:Subscribe(function(e)
	e.HitChance = DGM_HitChanceFormula(e.Attacker, e.Target)
end)

--- @param attacker StatCharacter
--- @param target StatCharacter
function DGM_CalculateHitChance(attacker, target)
    if attacker.TALENT_Haymaker then
		local diff = 0
		if attacker.MainWeapon then
			diff = diff + math.max(0, (attacker.MainWeapon.Level - attacker.Level))
		end
		if attacker.OffHandWeapon then
			diff = diff + math.max(0, (attacker.OffHandWeapon.Level - attacker.Level))
		end
        return 100 - diff * Ext.ExtraData.WeaponAccuracyPenaltyPerLevel
	end
	
    local accuracy = attacker.Accuracy
	local dodge = target.Dodge
	if target.Character:GetStatus("KNOCKED_DOWN") and dodge > 0 then
		dodge = 0
	end

	local chanceToHit1 = accuracy - dodge
	chanceToHit1 = math.max(0, math.min(100, chanceToHit1))
	_P(chanceToHit1 + attacker.ChanceToHitBoost)
    return chanceToHit1 + attacker.ChanceToHitBoost
end

Game.Math.CalculateHitChance = DGM_CalculateHitChance

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
