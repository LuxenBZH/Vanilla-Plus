Data.Stats = {}

Data.Stats.CustomAttributeBonuses = {
    Finesse = {Potion = {Movement = Ext.ExtraData.DGM_FinesseMovementBonus}, Status = {StackId = "DGM_Finesse"}, Cap = Ext.ExtraData.DGM_FinesseMovementCap},
    Intelligence = {Potion = {AccuracyBoost = Ext.ExtraData.DGM_IntelligenceAccuracyBonus}, Status = {StackId = "DGM_Intelligence"}, Cap = Ext.ExtraData.DGM_IntelligenceAccuracyCap}
}

Data.Stats.CustomAbilityBonuses = {
    SingleHanded = { Potion = {
            ArmorBoost=Ext.ExtraData.DGM_SingleHandedArmorBonus,
            MagicArmorBoost=Ext.ExtraData.DGM_SingleHandedArmorBonus,
            FireResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
            EarthResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
            PoisonResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
            WaterResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
            AirResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus
        }, Status = {StackId = "DGM_SingleHanded"}
    },
    TwoHanded = {},
    Ranged = {Potion = {RangeBoost=Ext.ExtraData.DGM_RangedRangeBonus}, Status = {StackId = "DGM_Ranged"}, Cap = 10},
    DualWielding = {},
    None = {}
}

Data.Stats.CrossbowMovementPenalty = {
    Base = Ext.ExtraData.DGM_CrossbowBasePenalty,
    Level = Ext.ExtraData.DGM_CrossbowLevelGrowthPenalty
}
