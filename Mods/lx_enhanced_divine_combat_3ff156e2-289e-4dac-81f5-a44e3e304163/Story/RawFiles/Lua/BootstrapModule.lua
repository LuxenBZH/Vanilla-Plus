Data = {}
-- Ext.Require("Shared/Helpers.lua")
-- Ext.Require("Shared/Data/Stats.lua")
-- Helpers.VPPrint("Loaded", "BootstrapModule")
BootstrapModule = {
    Potion = {
        VP_IngressBoost = "ConstantInt",
        VP_IngressBoostType = "FixedString",
        VP_WisdomBoost = "ConstantInt",
        VP_ArmorRegenBoost = "ConstantInt",
        VP_MagicArmorRegenBoost = "ConstantInt",
        VP_CustomImmunity = "FixedString",
        VP_AbsorbShieldValue = "ConstantInt",
        VP_AbsorbShieldType = "FixedString",
        VP_AbsorbShieldScaling = "FixedString",
        VP_AbsorbHealValue = "ConstantInt",
        VP_AbsorbHealScaling = "FixedString",
        VP_TemporaryVitalityValue = "ConstantInt",
        VP_TemporaryVitalityScaling = "FixedString",
        VP_ArmorBypassValue = "ConstantInt",
        VP_ArmorBypassType = "FixedString",
        VP_MagicArmorBypassValue = "ConstantInt",
        VP_MagicArmorBypassType = "FixedString",
        VP_VitalityMinimum = "ConstantInt",
        VP_Celerity = "ConstantInt",
        VP_CelerityFromMovement = "ConstantInt",
        VP_CriticalMultiplier = "ConstantInt"
    },
    Weapon = {
        VP_IngressBoost = "ConstantInt",
        VP_IngressBoostType = "FixedString",
        VP_WisdomBoost = "ConstantInt",
        VP_ArmorRegenBoost = "ConstantInt",
        VP_MagicArmorRegenBoost = "ConstantInt",
        VP_CustomImmunity = "FixedString",
        VP_Celerity = "ConstantInt",
        VP_CelerityFromMovement = "ConstantInt",
        VP_CriticalMultiplier = "ConstantInt"
    },
    Shield = {
        VP_IngressBoost = "ConstantInt",
        VP_IngressBoostType = "FixedString",
        VP_WisdomBoost = "ConstantInt",
        VP_ArmorRegenBoost = "ConstantInt",
        VP_MagicArmorRegenBoost = "ConstantInt",
        VP_CustomImmunity = "FixedString",
        VP_Celerity = "ConstantInt",
        VP_CelerityFromMovement = "ConstantInt"
    },
    Armor = {
        VP_IngressBoost = "ConstantInt",
        VP_IngressBoostType = "FixedString",
        VP_WisdomBoost = "ConstantInt",
        VP_ArmorRegenBoost = "ConstantInt",
        VP_MagicArmorRegenBoost = "ConstantInt",
        VP_CustomImmunity = "FixedString",
        VP_Celerity = "ConstantInt",
        VP_CelerityFromMovement = "ConstantInt"
    },
    SkillData = {
        VP_DamageCapValue = "ConstantInt",
        VP_DamageCapScaling = "FixedString",
        VP_ConsecutiveDamageReductionPercent = "ConstantInt",
        VP_ConsecutiveDamageReductionHitAmount = "ConstantInt"
    },
    StatusData = {
        VP_ChallengeVitalityStep = "ConstantInt",
        VP_ChallengeVitalityScaling = "FixedString",
        VP_ChallengeMultiplierCap = "ConstantInt",
        VP_WA_DamagePerAP = "ConstantInt",
        VP_ExecuteMultiplier = "ConstantInt",
        VP_ExecuteScaling = "FixedString",
        VP_ExecuteCondition = "FixedString"
    },
    Object = {}
}

Ext.Events.StatsStructureLoaded:Subscribe(function(e)
    Ext.Utils.Print("[V++:BootstrapModule] Loaded stats structure", "StatsProperties")
    for statType, attArray in pairs(BootstrapModule) do
        for customAttribute, dataType in pairs(attArray) do
            Ext.Stats.AddAttribute(statType, customAttribute, dataType)
        end
    end
end)