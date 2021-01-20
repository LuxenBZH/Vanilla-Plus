local defaultDataValues = {
    DGM_StrengthGlobalBonus = 2,
    DGM_StrengthWeaponBonus = 3,
    DGM_StrengthResIgnoreBaseMult = 0.15,
    DGM_FinesseGlobalBonus = 3,
    DGM_FinesseMovementBonus = 20,
    DGM_FinesseCritChance = 1,
    DGM_IntelligenceGlobalBonus = 2,
    DGM_IntelligenceSkillBonus = 3,
    DGM_IntelligenceAccuracyBonus = 1,
    DGM_WitsDotBonus = 10,
    DGM_DamageThroughArmor = 50,
    DGM_DamageThroughArmorDepleted = 25,
    DGM_RangedCQBPenalty = 35,
    DGM_RangedCQBPenaltyRange = 2,
    DGM_StaffSkillMultiplier = 10,
    DGM_WandSkillMultiplier = 2.5,
    DGM_CrossbowBasePenalty = -98,
    DGM_CrossbowLevelGrowthPenalty = -8,
    DGM_PerseveranceVitalityRecovery = 2,
    DGM_NpcScalingMainAttributeCorrection = 50,
    DGM_NpcScalingSecondaryAttributeCorrection = 70,
    DGM_NpcScalingNoArchetypeCorrection = 60,
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
    CrossbowPenaltyBase = "DGM_CrossbowBasePenalty",
    CrossbowPenaltyGrowth = "DGM_CrossbowLevelGrowthPenalty",
    PerseveranceVitality = "DGM_PerseveranceVitalityRecovery",
    NPCStatsMainCorrection = "DGM_NpcScalingMainAttributeCorrection",
    NPCStatsSecondaryCorrection = "DGM_NpcScalingSecondaryAttributeCorrection",
    NPCStatsNoArchetypeCorrection = "DGM_NpcScalingNoArchetypeCorrection",
}

local requireRestart = {
    StrengthGloBonus = false,
    StrengthWeaponBonus = false,
    FinesseGloBonus = false,
    FinesseMovement = true,
    FinesseCriticalChance = true,
    IntelligenceGloBonus = false,
    IntelligenceSkillBonus = false,
    IntelligenceAccuracyBonus = true,
    WitsDotBonus = false,
    ArmourDamagePass = false,
    ArmourDamagePassDepleted = false,
    CQBPenalty = false,
    CQBPenaltyRange = false,
    StaffSkillMult = false,
    WandSkillMult = false,
    CrossbowPenaltyBase = true,
    CrossbowPenaltyGrowth = true,
    PerseveranceVitality = false,
    NPCStatsMainCorrection = true,
    NPCStatsSecondaryCorrection = true,
    NPCStatsNoArchetypeCorrection = true
}

local flags = {
    "LXDGM_ModuleRealJump",
    "LXDGM_ModuleFallDamageClassic", 
    "LXDGM_ModuleFallDamageAlternate",
    "LXDGM_NPCStatsCorrectionCampaign",
    "LXDGM_NPCStatsCorrectionGM",
}

local BootStat = {}

Ext.RegisterListener("StatsLoaded", function()
	Ext.Print("Loading stored vars...")
    local json = Ext.LoadFile("LeaderLib_GlobalSettings.json", "user")
    if json == nil or json == "" then return end
    for var,value in pairs(Ext.JsonParse(json).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Variables) do
        Ext.Print("Set Data var",var,value.Value)
        if requireRestart[var] then
            Ext.ExtraData[idToVariable[var]] = value.Value
        end
	end
end)


Ext.RegisterListener("SessionLoaded", function()
    if Mods.LeaderLib == nil then return end
    ---@type ModSettings
    local settings = Mods.LeaderLib.CreateModSettings("3ff156e2-289e-4dac-81f5-a44e3e304163")
    settings.TitleColor = "#ffff99"
    
    settings.Global:AddLocalizedFlag("LXDGM_ModuleRealJump", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleFallDamageClassic", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_ModuleFallDamageAlternate", "Global", false, nil, nil, false)
    -- settings.Global:AddLocalizedFlag("LXDGM_ModuleDualCC", "Global", false, nil, nil, false)

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

    settings.Global:AddLocalizedVariable("ArmourDamagePass", "LXDGM_ArmourDamagePass", Ext.ExtraData.DGM_DamageThroughArmor, 0, 100, 1, "LXDGM_ArmourDamagePass_Description")
    settings.Global:AddLocalizedVariable("ArmourDamagePassDepleted", "LXDGM_ArmourDamagePassDepleted", Ext.ExtraData.DGM_DamageThroughArmorDepleted, 0, 100, 1, "LXDGM_ArmourDamagePassDepleted_Description")

    settings.Global:AddLocalizedVariable("CQBPenalty", "LXDGM_CQBPenalty", Ext.ExtraData.DGM_RangedCQBPenalty, 0, 100, 1, "LXDGM_CQBPenalty_Description")
    settings.Global:AddLocalizedVariable("CQBPenaltyRange", "LXDGM_CQBPenaltyRange", Ext.ExtraData.DGM_RangedCQBPenaltyRange, 0, 10, 1, "LXDGM_CQBPenaltyRange_Description")
    settings.Global:AddLocalizedVariable("StaffSkillMult", "LXDGM_StaffSkillMult", Ext.ExtraData.DGM_StaffSkillMultiplier, 0, 100, 0.5, "LXDGM_StaffSkillMult_Description")
    settings.Global:AddLocalizedVariable("WandSkillMult", "LXDGM_WandSkillMult", Ext.ExtraData.DGM_WandSkillMultiplier, 0, 100, 0.5, "LXDGM_WandSkillMult_Description")
    settings.Global:AddLocalizedVariable("CrossbowPenaltyBase", "LXDGM_CrossbowPenaltyBase", Ext.ExtraData.DGM_CrossbowBasePenalty, -300, 0, 1, "LXDGM_CrossbowPenaltyBase_Description")
    settings.Global:AddLocalizedVariable("CrossbowPenaltyGrowth", "LXDGM_CrossbowPenaltyGrowth", Ext.ExtraData.DGM_CrossbowLevelGrowthPenalty, -100, 0, 1, "LXDGM_CrossbowPenaltyGrowth_Description")
    settings.Global:AddLocalizedVariable("PerseveranceVitality", "LXDGM_PerseveranceVitality", Ext.ExtraData.DGM_PerseveranceVitalityRecovery, 0, 20, 0.5, "LXDGM_PerseveranceVitality_Description")

    settings.Global:AddLocalizedFlag("LXDGM_NPCStatsCorrectionCampaignDisable", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedFlag("LXDGM_NPCStatsCorrectionGM", "Global", false, nil, nil, false)
    settings.Global:AddLocalizedVariable("NPCStatsMainCorrection", "LXDGM_NPCStatsMainCorrection", Ext.ExtraData.DGM_NpcScalingMainAttributeCorrection, 0, 100, 1, "LXDGM_NPCStatsMainCorrection_Description")
    settings.Global:AddLocalizedVariable("NPCStatsSecondaryCorrection", "LXDGM_NPCStatsSecondaryCorrection", Ext.ExtraData.DGM_NpcScalingSecondaryAttributeCorrection, 0, 100, 1, "LXDGM_NPCStatsSecondaryCorrection_Description")
    settings.Global:AddLocalizedVariable("NPCStatsNoArchetypeCorrection", "LXDGM_NPCStatsNoArchetypeCorrection", Ext.ExtraData.DGM_NpcScalingNoArchetypeCorrection, 0, 100, 1, "LXDGM_NPCStatsNoArchetypeCorrection_Description")

    settings.GetMenuOrder = function()
        return {{
                DisplayName = "Modules",
                Entries = {
                    "LXDGM_ModuleRealJump",
                    "LXDGM_ModuleFallDamageClassic",
                    "LXDGM_ModuleFallDamageAlternate",
                    -- "LXDGM_ModuleDualCC"
                }},
                {DisplayName = "Attributes",
                Entries = {
                    -- "LXDGM_SettingsUseDefaultAttributeValues",
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
                }},
                {DisplayName = "Armour System",
                Entries = {
                    "ArmourDamagePass",
                    "ArmourDamagePassDepleted",
                }},
                {DisplayName = "Miscellaneous",
                Entries = {
                    "CQBPenalty",
                    "CQBPenaltyRange",
                    "StaffSkillMult",
                    "WandSkillMult",
                    "CrossbowPenaltyBase",
                    "CrossbowPenaltyGrowth",
                    "PerseveranceVitality",
                }},
                {DisplayName = "NPC Stats Scaling",
                Entries = {
                    "LXDGM_NPCStatsCorrectionCampaignDisable",
                    "LXDGM_NPCStatsCorrectionGM",
                    "NPCStatsMainCorrection",
                    "NPCStatsSecondaryCorrection",
                    "NPCStatsNoArchetypeCorrection",
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
