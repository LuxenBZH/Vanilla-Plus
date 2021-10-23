local defaultDataValues = {
    DGM_StrengthGlobalBonus = 2,
    DGM_StrengthWeaponBonus = 3,
    DGM_StrengthResIgnoreBaseMult = 0.15,
    DGM_FinesseGlobalBonus = 3,
    DGM_FinesseMovementBonus = 20,
    DGM_FinesseCritChance = 1,
    DGM_IntelligenceGlobalBonus = 2,
    DGM_IntelligenceSkillBonus = 3,
    DGM_IntelligenceAccuracyBonus = 2,
    DGM_WitsDotBonus = 10,
    DGM_DamageThroughArmor = 50,
    DGM_DamageThroughArmorDepleted = 25,
    DGM_RangedCQBPenalty = 35,
    DGM_RangedCQBPenaltyRange = 2,
    DGM_StaffSkillMultiplier = 10,
    DGM_WandSkillMultiplier = 5,
    DGM_CrossbowBasePenalty = -88,
    DGM_CrossbowLevelGrowthPenalty = -12,
    DGM_PerseveranceVitalityRecovery = 2,
    DGM_NpcScalingMainAttributeCorrection = 50,
    DGM_NpcScalingSecondaryAttributeCorrection = 70,
    DGM_NpcScalingNoArchetypeCorrection = 60,
    DGM_BackstabCritChanceBonus = 0.5,
    DGM_CCParryDuration = 2,
    DGM_ArmourReductionMultiplier = 100,
    DGM_PlayerVitalityMultiplier = 100,
    DGM_NpcVitalityMultiplier = 100,
    DGM_WandSurfaceBonus = 15,
    DGM_PerseveranceResistance = 5,
}

local idToVariable = {
    StrengthGloBonus = "DGM_StrengthGlobalBonus",
    StrengthWeaponBonus = "DGM_StrengthWeaponBonus",
    FinesseGloBonus = "DGM_FinesseGlobalBonus",
    FinesseMovement = "DGM_FinesseMovementBonus",
    FinesseCriticalChance = "DGM_FinesseCritChance",
    IntelligenceGloBonus = "DGM_IntelligenceGlobalBonus", 
    IntelligenceSkillBonus = "DGM_IntelligenceSkillBonus",
    IntelligenceAccuracyBonus = "DGM_IntelligenceAccuracyBonus",
    WitsDotBonus = "DGM_WitsDotBonus",
    ArmourDamagePass = "DGM_DamageThroughArmor",
    ArmourDamagePassDepleted = "DGM_DamageThroughArmorDepleted",
    CQBPenalty = "DGM_RangedCQBPenalty",
    CQBPenaltyRange = "DGM_RangedCQBPenaltyRange",
    StaffSkillMult = "DGM_StaffSkillMultiplier",
    WandSkillMult = "DGM_WandSkillMultiplier",
    WandSurfaceMult = "DGM_WandSurfaceBonus",
    CrossbowPenaltyBase = "DGM_CrossbowBasePenalty",
    CrossbowPenaltyGrowth = "DGM_CrossbowLevelGrowthPenalty",
    PerseveranceVitality = "DGM_PerseveranceVitalityRecovery",
    NPCStatsMainCorrection = "DGM_NpcScalingMainAttributeCorrection",
    NPCStatsSecondaryCorrection = "DGM_NpcScalingSecondaryAttributeCorrection",
    NPCStatsNoArchetypeCorrection = "DGM_NpcScalingNoArchetypeCorrection",
    CritChanceBackstabBonus = "DGM_BackstabCritChanceBonus",
    CCParryDuration = "DGM_CCParryDuration",
    ArmourReductionMultiplier = "DGM_ArmourReductionMultiplier",
    PlayerVitalityMultiplier = "DGM_PlayerVitalityMultiplier",
    NpcVitalityMultiplier = "DGM_NpcVitalityMultiplier",
    SummonsVitalityMultiplier = "DGM_SummonsVitalityMultiplier",
    SummonsDamageBoost = "DGM_SummonsDamageBoost",
    -- LXDGM_ModuleDivineTalents = "DGM_GB4Talents"
}

local requireRestart = {
    FinesseMovement = true,
    FinesseCriticalChance = true,
    IntelligenceAccuracyBonus = true,
    CrossbowPenaltyBase = true,
    CrossbowPenaltyGrowth = true,
    NPCStatsMainCorrection = true,
    NPCStatsSecondaryCorrection = true,
    NPCStatsNoArchetypeCorrection = true,
    PlayerVitalityMultiplier = true,
    NpcVitalityMultiplier = true,
    SummonsVitalityMultiplier = true,
    SummonsDamageBoost = true,
    -- LXDGM_ModuleDivineTalents = true
}

local flags = {
    "LXDGM_ModuleRealJump",
    "LXDGM_ModuleFallDamageClassic", 
    "LXDGM_ModuleFallDamageAlternate",
    "LXDGM_ModuleDualCC",
    "LXDGM_ModuleOriginalChameleonCloak",
    "LXDGM_NPCStatsCorrectionCampaign",
    "LXDGM_NPCStatsCorrectionGM",
    "LXDGM_ModuleDivineTalentsDisable",
    "LXDGM_ModuleCorrogicDisable"
}

Ext.RegisterListener("StatsLoaded", function()
    if Mods.LeaderLib == nil then return end
    Ext.Print("Loading stored vars...")
    local json = Ext.LoadFile("LeaderLib_GlobalSettings.json", "user")
    if json == nil or json == "" then return end
    for var,value in pairs(Ext.JsonParse(json).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Variables) do
        Ext.Print("Set Data var",var,value.Value)
        if requireRestart[var] then
            Ext.ExtraData[idToVariable[var]] = value.Value
        end
	end
    -- for var,value in pairs(Ext.JsonParse(json).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags) do
    --     Ext.Print("Set Data flag",var,value.Enabled)
    --     if requireRestart[var] then
    --         if value.Enabled then
    --             Ext.ExtraData[idToVariable[var]] = 1
    --         else
    --             Ext.ExtraData[idToVariable[var]] = 0
    --         end
    --     end
	-- end
end)


Ext.RegisterListener("SessionLoaded", function()
    if Mods.LeaderLib == nil then return end
    ---@type ModSettings
    local settings = Mods.LeaderLib.CreateModSettings("3ff156e2-289e-4dac-81f5-a44e3e304163")
    settings.TitleColor = "#ffff99"
    
    settings.Global:AddLocalizedFlag("LXDGM_ModuleRealJump", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleFallDamageClassic", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleFallDamageAlternate", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleDualCC", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleOriginalChameleonCloak", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleDivineTalentsDisable", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleCorrogicDisable", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleOriginalTeleport", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleLegacyDodge", "Global", false, nil, nil, false)

    -- settings.Global:AddLocalizedFlag("LXDGM_SettingsUseDefaultAttributeValues", "Global", true, nil, nil, false)
    settings.Global:AddLocalizedVariable("StrengthGloBonus", "LXDGM_StrengthGlobalDamageBonus", Ext.ExtraData.DGM_StrengthGlobalBonus, 0, 10, 0.5, "LXDGM_StrengthGlobalDamageBonus_Description")
    settings.Global:AddLocalizedVariable("StrengthWeaponBonus", "LXDGM_StrengthSpecialDamageBonus", Ext.ExtraData.DGM_StrengthWeaponBonus, 0, 10, 0.5, "LXDGM_StrengthSpecialDamageBonus_Description")
    settings.Global:AddLocalizedVariable("StrengthResBypass", "LXDGM_StrengthResistanceIgnore", Ext.ExtraData.DGM_StrengthResistanceIgnore, 0, 5, 0.05, "LXDGM_StrengthResistanceIgnore_Description")
    settings.Global:AddLocalizedVariable("FinesseGloBonus", "LXDGM_FinesseGlobalDamageBonus", Ext.ExtraData.DGM_FinesseGlobalBonus, 0, 10, 0.5, "LXDGM_FinesseGlobalDamageBonus_Description")
    settings.Global:AddLocalizedVariable("FinesseMovement", "LXDGM_FinesseMovementBonus", Ext.ExtraData.DGM_FinesseMovementBonus, 0, 100, 1, "LXDGM_FinesseMovementBonus_Description")
    settings.Global:AddLocalizedVariable("FinesseCriticalChance", "LXDGM_FinesseCriticalChanceBonus", Ext.ExtraData.DGM_FinesseCritChance, 0, 10, 1, "LXDGM_FinesseCriticalChanceBonus_Description")
    settings.Global:AddLocalizedVariable("IntelligenceGloBonus", "LXDGM_IntelligenceGlobalDamageBonus", Ext.ExtraData.DGM_IntelligenceGlobalBonus, 0, 10, 0.5, "LXDGM_IntelligenceGlobalDamageBonus_Description")
    settings.Global:AddLocalizedVariable("IntelligenceSkillBonus", "LXDGM_IntelligenceSpecialDamageBonus", Ext.ExtraData.DGM_IntelligenceSkillBonus, 0, 10, 0.5, "LXDGM_IntelligenceSpecialDamageBonus_Description")
    settings.Global:AddLocalizedVariable("IntelligenceAccuracyBonus", "LXDGM_IntelligenceAccuracyBonus", Ext.ExtraData.DGM_IntelligenceAccuracyBonus, 0, 10, 1, "LXDGM_IntelligenceAccuracyBonus_Description")
    settings.Global:AddLocalizedVariable("WitsDotBonus", "LXDGM_WitsDotBonus", Ext.ExtraData.DGM_WitsDotBonus, 0, 50, 1, "LXDGM_WitsDotBonus_Description")
    settings.Global:AddLocalizedVariable("CritChanceBackstabBonus", "LXDGM_BackstabCritChanceBonus", Ext.ExtraData.DGM_BackstabCritChanceBonus, 0, 3, 0.25, "LXDGM_BackstabCritChanceBonus_Description")
    settings.Global:AddLocalizedVariable("AttributeCap", "LXDGM_AttributeCap", Ext.ExtraData.AttributeSoftCap, Ext.ExtraData.AttributeBaseValue, 80, 1, "LXDGM_AttributeCap_Description")

    settings.Global:AddLocalizedVariable("ArmourDamagePass", "LXDGM_ArmourDamagePass", Ext.ExtraData.DGM_DamageThroughArmor, 0, 100, 1, "LXDGM_ArmourDamagePass_Description")
    settings.Global:AddLocalizedVariable("ArmourDamagePassDepleted", "LXDGM_ArmourDamagePassDepleted", Ext.ExtraData.DGM_DamageThroughArmorDepleted, 0, 100, 1, "LXDGM_ArmourDamagePassDepleted_Description")

    settings.Global:AddLocalizedVariable("PotionFatigue", "LXDGM_PotionFatigue", Ext.ExtraData.DGM_PotionFatigue, -1, 6, 1, "LXDGM_PotionFatigue_Description")
    settings.Global:AddLocalizedVariable("CQBPenalty", "LXDGM_CQBPenalty", Ext.ExtraData.DGM_RangedCQBPenalty, 0, 100, 1, "LXDGM_CQBPenalty_Description")
    settings.Global:AddLocalizedVariable("CQBPenaltyRange", "LXDGM_CQBPenaltyRange", Ext.ExtraData.DGM_RangedCQBPenaltyRange, 0, 10, 1, "LXDGM_CQBPenaltyRange_Description")
    settings.Global:AddLocalizedVariable("StaffSkillMult", "LXDGM_StaffSkillMult", Ext.ExtraData.DGM_StaffSkillMultiplier, 0, 100, 0.5, "LXDGM_StaffSkillMult_Description")
    settings.Global:AddLocalizedVariable("WandSkillMult", "LXDGM_WandSkillMult", Ext.ExtraData.DGM_WandSkillMultiplier, 0, 100, 0.5, "LXDGM_WandSkillMult_Description")
    settings.Global:AddLocalizedVariable("WandSurfaceMult", "LXDGM_WandSurfaceMult", Ext.ExtraData.DGM_WandSurfaceBonus, 0, 100, 0.5, "LXDGM_WandSurfaceMult_Description")
    settings.Global:AddLocalizedVariable("CrossbowPenaltyBase", "LXDGM_CrossbowPenaltyBase", Ext.ExtraData.DGM_CrossbowBasePenalty, -300, 0, 1, "LXDGM_CrossbowPenaltyBase_Description")
    settings.Global:AddLocalizedVariable("CrossbowPenaltyGrowth", "LXDGM_CrossbowPenaltyGrowth", Ext.ExtraData.DGM_CrossbowLevelGrowthPenalty, -100, 0, 1, "LXDGM_CrossbowPenaltyGrowth_Description")
    settings.Global:AddLocalizedVariable("PerseveranceResistance", "LXDGM_PerseveranceResistance", Ext.ExtraData.DGM_PerseveranceResistance, 0, 10, 1, "LXDGM_PerseveranceResistance_Description")
    settings.Global:AddLocalizedVariable("CCParryDuration", "LXDGM_CCParryDuration", Ext.ExtraData.DGM_CCParryDuration, 0, 5, 1, "LXDGM_CCParryDuration_Description")
    settings.Global:AddLocalizedVariable("ArmourReductionMultiplier", "LXDGM_ArmourReductionMultiplier", Ext.ExtraData.DGM_ArmourReductionMultiplier, 50, 300, 5, "LXDGM_ArmourReductionMultiplier_Description")

    settings.Global:AddLocalizedFlag("LXDGM_NPCStatsCorrectionCampaignDisable", "Global", false, nil, nil, false)
    -- settings.Global:AddLocalizedFlag("LXDGM_NPCStatsCorrectionGM", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedVariable("NPCStatsMainCorrection", "LXDGM_NPCStatsMainCorrection", Ext.ExtraData.DGM_NpcScalingMainAttributeCorrection, 0, 100, 1, "LXDGM_NPCStatsMainCorrection_Description")
    settings.Global:AddLocalizedVariable("NPCStatsSecondaryCorrection", "LXDGM_NPCStatsSecondaryCorrection", Ext.ExtraData.DGM_NpcScalingSecondaryAttributeCorrection, 0, 100, 1, "LXDGM_NPCStatsSecondaryCorrection_Description")
    settings.Global:AddLocalizedVariable("NPCStatsNoArchetypeCorrection", "LXDGM_NPCStatsNoArchetypeCorrection", Ext.ExtraData.DGM_NpcScalingNoArchetypeCorrection, 0, 100, 1, "LXDGM_NPCStatsNoArchetypeCorrection_Description")
    settings.Global:AddLocalizedVariable("PlayerVitalityMultiplier", "LXDGM_PlayerVitalityMultiplier", Ext.ExtraData.DGM_PlayerVitalityMultiplier, 5, 300, 5, "LXDGM_PlayerVitalityMultiplier_Description")
    settings.Global:AddLocalizedVariable("SummonsVitalityMultiplier", "LXDGM_SummonsVitalityMultiplier", Ext.ExtraData.DGM_SummonsVitalityMultiplier, 5, 300, 5, "LXDGM_SummonsVitalityMultiplier_Description")
    settings.Global:AddLocalizedVariable("SummonsDamageBoost", "LXDGM_SummonsDamageBoost", Ext.ExtraData.DGM_SummonsDamageBoost, -50, 200, 1, "LXDGM_SummonsDamageBoost_Description")
    -- settings.Global:AddLocalizedVariable("NpcVitalityMultiplier", "LXDGM_NpcVitalityMultiplier", Ext.ExtraData.DGM_NpcVitalityMultiplier, 5, 300, 5, "LXDGM_NpcVitalityMultiplier_Description")
    settings.Global:AddLocalizedButton("FixConstitutionGap", "LXDGM_FixConstitutionGap", function(button, uuid, character)
        Ext.PostMessageToServer("DGM_FixConstitutionGap", "")
    end, nil, true, "LXDGM_FixConstitutionGap_Description")
    settings.Global:AddLocalizedButton("FlatScalingActivate", "LXDGM_FlatScalingActivate", function(button, uuid, character)
        Ext.PostMessageToServer("LXDGM_FlatScalingWarning", "")
    end, nil, true, "LXDGM_FlatScalingActivate_Description")
    settings.Global:AddLocalizedButton("FlatScalingDeactivate", "LXDGM_FlatScalingDeactivate", function(button, uuid, character)
        Ext.PostMessageToServer("LXDGM_FlatScalingWarning2", "")
    end, nil, true, "LXDGM_FlatScalingDeactivate_Description")  

    settings.GetMenuOrder = function()
        return {{
                DisplayName = "Modules",
                Entries = {
                    "LXDGM_ModuleDivineTalentsDisable",
                    "LXDGM_ModuleCorrogicDisable",
                    "LXDGM_ModuleDualCC",
                    "LXDGM_ModuleRealJump",
                    "LXDGM_ModuleFallDamageClassic",
                    "LXDGM_ModuleFallDamageAlternate",
                    "LXDGM_ModuleOriginalChameleonCloak",
                    "LXDGM_ModuleOriginalTeleport",
                    "LXDGM_ModuleLegacyDodge"
                }},
                {DisplayName = "Attributes",
                Entries = {
                    "StrengthGloBonus",
                    "StrengthWeaponBonus",
                    "StrengthResBypass",
                    "FinesseGloBonus",
                    "FinesseMovement",
                    "FinesseCriticalChance",
                    "IntelligenceGloBonus",
                    "IntelligenceSkillBonus",
                    "IntelligenceAccuracyBonus",
                    "WitsDotBonus",
                    "CritChanceBackstabBonus",
                    "AttributeCap"
                }},
                {DisplayName = "Armour System",
                Entries = {
                    "ArmourDamagePass",
                    "ArmourDamagePassDepleted",
                }},
                {DisplayName = "Miscellaneous",
                Entries = {
                    "PotionFatigue",
                    "CQBPenalty",
                    "CQBPenaltyRange",
                    "StaffSkillMult",
                    "WandSkillMult",
                    "WandSurfaceMult",
                    "CrossbowPenaltyBase",
                    "CrossbowPenaltyGrowth",
                    "PerseveranceResistance",
                    "CCParryDuration",
                    "ArmourReductionMultiplier"
                }},
                {DisplayName = "NPC Stats Scaling",
                Entries = {
                    "LXDGM_NPCStatsCorrectionCampaignDisable",
                    -- "LXDGM_NPCStatsCorrectionGM",
                    "NPCStatsMainCorrection",
                    "NPCStatsSecondaryCorrection",
                    "NPCStatsNoArchetypeCorrection",
                    "PlayerVitalityMultiplier",
                    -- "NpcVitalityMultiplier",
                    "SummonsVitalityMultiplier",
                    "SummonsDamageBoost",
                    "FixConstitutionGap",
                    "FlatScalingActivate",
                    "FlatScalingDeactivate"
                }},
        }
    end

    ---@param self SettingsData
    ---@param name string
    ---@param data VariableData
    settings.OnVariableSet = function(self, name, data)
        if data.Value ~= Ext.ExtraData[idToVariable[name]] then
            local variableName = idToVariable[name]
            -- Ext.Print("On Variable set",name,data.Value)
            Ext.ExtraData[variableName] = data.Value
            Ext.BroadcastMessage("DGM_SyncSettings", Ext.JsonStringify({variableName, data.Value}))
            -- if requireRestart[name] then
            --     BootStat[variableName] = data.Value
            -- end
        end
    end

    return settings
end)

-- local function SaveRestartVariables(channel, data)
--     if GetTableSize(BootStat) < 1 then return end
--     Ext.Print("Saving bootstat variables...")
--     Ext.SaveFile("VanillaPlus_SavedVariables.json", Ext.JsonStringify(BootStat))
-- end

-- Ext.RegisterNetListener("LeaderLib_ModMenu_SaveChanges", SaveRestartVariables)

local function SyncSettingsOnClients(channel, data)
    Ext.Print("Sync Data")
    if channel ~= "DGM_SyncSettings" or Ext.IsServer() then return end
    data = Ext.JsonParse(data)
    Ext.Print("Syncing",data[1],data[2])
    Ext.ExtraData[data[1]] = data[2]
end

Ext.RegisterNetListener("DGM_SyncSettings", SyncSettingsOnClients)
