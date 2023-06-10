Ext.Require("Shared/Data/Data.lua")
Ext.Require("Shared/Helpers.lua")
Ext.Require("Shared/Data/Stats.lua")
Helpers.VPPrint("Loaded", "BootstrapModule")
Data.Stats.StatsCustomAttributes = {
    Potion = {
        VP_IngressBoost = "ConstantInt",
        VP_IngressBoostType = "FixedString",
        VP_WisdomBoost = "ConstantInt",
        VP_ArmorRegenBoost = "ConstantInt",
        VP_MagicArmorRegenBoost = "ConstantInt",
        VP_CriticalMultiplierBoost = "ConstantInt",
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
    },
    Weapon = {
        VP_IngressBoost = "ConstantInt",
        VP_IngressBoostType = "FixedString",
        VP_WisdomBoost = "ConstantInt",
        VP_ArmorRegenBoost = "ConstantInt",
        VP_MagicArmorRegenBoost = "ConstantInt",
        VP_CustomImmunity = "FixedString",
    },
    Shield = {
        VP_IngressBoost = "ConstantInt",
        VP_IngressBoostType = "FixedString",
        VP_WisdomBoost = "ConstantInt",
        VP_ArmorRegenBoost = "ConstantInt",
        VP_MagicArmorRegenBoost = "ConstantInt",
        VP_CriticalMultiplierBoost = "ConstantInt",
        VP_CustomImmunity = "FixedString",
    },
    Armor = {
        VP_IngressBoost = "ConstantInt",
        VP_IngressBoostType = "FixedString",
        VP_WisdomBoost = "ConstantInt",
        VP_ArmorRegenBoost = "ConstantInt",
        VP_MagicArmorRegenBoost = "ConstantInt",
        VP_CriticalMultiplierBoost = "ConstantInt",
        VP_CustomImmunity = "FixedString",
    },
    SkillData = {
        VP_DamageCapValue = "ConstantInt",
        VP_DamageCapScaling = "FixedString",
        VP_ConsecutiveDamageReductionPercent = "ConstantInt",
        VP_ConsecutiveDamageReductionHitAmount = "ConstantInt"
    },
    StatusData = {},
    Object = {}
}

Ext.Events.StatsStructureLoaded:Subscribe(function(e)
    Ext.Utils.Print("[V++:BootstrapModule] Loaded stats structure", "StatsProperties")
    for statType, attArray in pairs(Data.Stats.StatsCustomAttributes) do
        for customAttribute, dataType in pairs(attArray) do
            Ext.Stats.AddAttribute(statType, customAttribute, dataType)
        end
    end
end)