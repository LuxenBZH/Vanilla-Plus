local dynamicTooltips = {
    ["Strength"]                = "he1708d1eg243dg4b72g8f48gddb9bc8d62ff",
    ["StrengthDescription"]     = "h18f97d5bg9a79g4917g809dgb0ac7a5ec302",
    ["Finesse"]                 = "h2e87e6cfg0183g4968g8ec1g325614c7d9fa",
    ["FinesseDescription"]      = "h75391bafg8744g4441g9b1egf52f182f96fc",
    ["Intelligence"]            = "h58e777ddgd569g4c0dg8f58gece56cce053d",
    ["IntelligenceDescription"] = "h6b67efcagf943g43a1g959eg36f9ecc42e7e",
    ["Wits"]                    = "ha422c4f4ge2bbg4cbcgbbf3g505c7ce673d1",
    ["WitsDescription"]         = "h6d2cd8aeg4e09g4003ga57cg3fea3a0f5502",
    ["Damage"]                  = "h7fec5db8g58d3g4abbgab7ag03e19b542bef",
    ["WpnStaff"]                = "h1e5caa33g4d5dg4f42g91edg9f546d42f56b",
    ["WpnWand"]                 = "h314ee256g43cdg4864ga519gd23e909ec63e",
    ["WpnRanged"]               = "h3e8d0f43g5060g48d8g95cag541abe3a7c08",
    ["Dual-Wielding"]           = "hc5d5552bg6b33g44c1gbb0cg8d55a101f081",
    ["Dual-Wielding_Next"]      = "h2baa6ed9gdca0g4731gb999g098d9c2d90b0",
    ["Ranged"]                  = "he86bfd28ge123g42a4g8c0cg2f9bcd7d9e05", 
    ["Ranged_Next"]             = "hffc37ae5g6651g4a60ga1c1g49d233cb1ca2",
    ["Single-Handed"]           = "h70707bb2g5a48g4571g9a68ged2fe5a030ea", 
    ["Single-Handed_Next"]      = "h2afdc1f0g4650g4ea9gafb7gb0c042367766",
    ["Two-Handed"]              = "h6e9ec88dgcbb7g426bgb1d9g69df0240825a", 
    ["Two-Handed_Next"]         = "hda7ee9a4g5bbeg4c62g96b7ge31b21e094f3",
    ["Perseverance"]            = "h5d0c3ad0g3d9dg4cf1g92b7g20d6d7d26344", 
    ["Perseverance_Next"]       = "h443a51dcgbd6fg46c2g8988gbfe93a3123a5",
    ["AttrGenBonus"]            = "hdf2a4bd0g134eg4107g9a8agd93d6d22fd68",
    ["StrWpnBonus"]             = "ha418e064g2d69g4407gadc2gf2f590f0e895",
    ["IntSkillBonus"]           = "hf338b2c0gd158g49b4ga2ceg15a7099a4b7b",
    ["DualWieldingPenalty"]     = "h092684e6gbf69g4372g99f8g4743516b0efe",
    ["Target_EvasiveManeuver"]  = "h456b2bf0gf693g41e8gb01cg42e3548814a2",
    ["Target_Fortify"]          = "hdc60c039gac18g416cgb2a0g3d58fc54afcc",
    ["Shout_MendMetal"]         = "h50e9548eg61f2g4aedg8a3eg570a7ffee6d3",
    ["Shout_SteelSkin"]         = "he47a8a79g2f04g410bgbf00gd6b2a84ba9a5",
    ["Target_FrostyShell"]      = "hf2f2ceb4g7be9g453fgb093ga8d7c563f782",
    ["Shout_FrostAura"]         = "h2ce13614gab6cg4878gb781gcb3186a8ead9",
    ["Shout_RecoverArmour"]     = "hf7a19975gea84g44a3g8fffg5b4f063b88b4",
    ["Target_TentacleLash"]     = "hddb00621g65ddg46acg89d2gfcf3efd8cd78",
    ["WpnCrossbow"]             = "h846daabdg90beg4ac9gb930g02e96dcdbd8d"
}

---@param str string
local function SubstituteString(str, ...)
    local args = {...}
    local result = str

    for k, v in pairs(args) do
        if v == math.floor(v) then v = math.floor(v) end -- Formatting integers to not show .0
        result = result:gsub("%["..tostring(k).."%]", v)
    end
    return result
end

---@param dynamicKey string
function GetDynamicTranslationString(dynamicKey, ...)
    local args = {...}
    
    local handle = dynamicTooltips[dynamicKey]
    if handle == nil then return nil end

    local str = Ext.GetTranslatedString(handle, "Handle Error!")
    str = SubstituteString(str, table.unpack(args))
    return str
end

---@param item StatItem
---@param tooltip TooltipData
local function WeaponTooltips(item, tooltip)
    if tooltip == nil then return end
	if item.ItemType ~= "Weapon" then return end
	local equipment = {
		Type = "ItemRequirement",
		Label = "",
		RequirementMet = true
    }

    if item.WeaponType == "Staff" then
        equipment["Label"] = GetDynamicTranslationString("WpnStaff", Ext.ExtraData.DGM_StaffSkillMultiplier)
        tooltip:AppendElementAfter(equipment, "ExtraProperties")
    end

    if item.WeaponType == "Wand" then
        equipment["Label"] = GetDynamicTranslationString("WpnWand", Ext.ExtraData.DGM_WandSkillMultiplier)
        tooltip:AppendElementAfter(equipment, "ExtraProperties")
    end

    if item.WeaponType == "Bow" or item.WeaponType == "Crossbow" or item.WeaponType == "Rifle" or item.WeaponType == "Wand" then
        local equipment = {
            Type = "ItemRequirement",
            Label = "",
            RequirementMet = true
        }
        equipment["Label"] = GetDynamicTranslationString("WpnRanged", Ext.ExtraData.DGM_RangedCQBPenalty, Ext.ExtraData.DGM_RangedCQBPenaltyRange)
        equipment["RequirementMet"] = false
        tooltip:AppendElementAfter(equipment, "ExtraProperties")
    end

    if item.WeaponType == "Crossbow" then
        local equipment = {
            Type = "ItemRequirement",
            Label = GetDynamicTranslationString("WpnCrossbow", -1*Ext.ExtraData.DGM_CrossbowBasePenalty/100+(-1*Ext.ExtraData.DGM_CrossbowLevelGrowthPenalty/100*item.Level)),
            RequirementMet = false
        }
        tooltip:AppendElementAfter(equipment, "ExtraProperties")
    end
end

---@param character EsvCharacter
---@param skill any
---@param tooltip TooltipData
local function SkillAttributeTooltipBonus(character, skill, tooltip)
    local stats = character.Stats
    local generalBonus = math.floor((stats.Strength-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthGlobalBonus +
    (stats.Finesse-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_FinesseGlobalBonus +
    (stats.Intelligence-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceGlobalBonus)
    local strengthBonus = math.floor((stats.Strength-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthWeaponBonus)
    local intelligenceBonus = math.floor((stats.Intelligence-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceSkillBonus)

    local general = {
        Type = "StatsPercentageBoost",
        Label = GetDynamicTranslationString("AttrGenBonus", generalBonus)
    }
    local strength = {
        Type = "StatsPercentageBoost",
        Label = GetDynamicTranslationString("StrWpnBonus", strengthBonus)
    }
    local intelligence = {
        Type = "StatsPercentageBoost",
        Label = GetDynamicTranslationString("IntSkillBonus", intelligenceBonus)
    }

    tooltip:AppendElementAfter(general, "StatsPercentageBoost")
    tooltip:AppendElementAfter(strength, "StatsPercentageBoost")
    tooltip:AppendElementAfter(intelligence, "StatsPercentageBoost")

    if not stats.MainWeapon.IsTwoHanded then
        if stats.OffHandWeapon ~= nil and stats.OffHandWeapon.WeaponType ~= "Shield" then
            local offhandPenalty = tooltip:GetElements("StatsPercentageMalus")

            local finalPenalty = Ext.ExtraData.DualWieldingDamagePenalty*100 - stats.DualWielding * Ext.ExtraData.DGM_DualWieldingOffhandBonus

            local reducedBy = Ext.ExtraData.DualWieldingDamagePenalty*100 - finalPenalty
            
            for _, offhandPenaltySub in pairs(offhandPenalty) do
                offhandPenaltySub.Label = GetDynamicTranslationString("DualWieldingPenalty", finalPenalty, reducedBy)
            end
        end
    end
end

---@param character EsvCharacter
---@param skill string
---@param tooltip TooltipData
local function OnStatTooltip(character, stat, tooltip)
    local stat = tooltip:GetElement("StatName").Label
    local statsDescription = tooltip:GetElement("StatsDescription")
    local statsPointValue = tooltip:GetElement("StatsPointValue")

    local attrBonus = CharGetDGMAttributeBonus(character, 0)

    if stat == "Strength" then
        statsDescription.Label = GetDynamicTranslationString(stat.."Description", Ext.ExtraData.DGM_StrengthGlobalBonus, Ext.ExtraData.DGM_StrengthWeaponBonus, math.floor(Ext.Round(Ext.ExtraData.DGM_StrengthResistanceIgnore*100))/100)
        statsPointValue.Label = GetDynamicTranslationString(stat, attrBonus["str"], attrBonus["strGlobal"], attrBonus["strWeapon"], attrBonus["strRes"])

    elseif stat == "Finesse" then
        statsDescription.Label = GetDynamicTranslationString(stat.."Description", Ext.ExtraData.DGM_FinesseGlobalBonus, math.floor(Ext.Round(Ext.ExtraData.DodgingBoostFromAttribute*100)), Ext.ExtraData.DGM_FinesseCritChance, Ext.ExtraData.DGM_FinesseMovementBonus/100)
        statsPointValue.Label = GetDynamicTranslationString(stat, attrBonus["fin"], attrBonus["finGlobal"], attrBonus["finDodge"], attrBonus["finMovement"], attrBonus["finCrit"])

    elseif stat == "Intelligence" then
        statsDescription.Label = GetDynamicTranslationString(stat.."Description", Ext.ExtraData.DGM_IntelligenceGlobalBonus, Ext.ExtraData.DGM_IntelligenceSkillBonus, Ext.ExtraData.DGM_IntelligenceAccuracyBonus)
        statsPointValue.Label = GetDynamicTranslationString(stat, attrBonus["int"], attrBonus["intGlobal"], attrBonus["intSkill"], attrBonus["intAcc"], (character.Stats.Intelligence-Ext.ExtraData.AttributeBaseValue)*attrBonus["strRes"])

    elseif stat == "Wits" then
        statsDescription.Label = GetDynamicTranslationString(stat.."Description", Ext.ExtraData.CriticalBonusFromWits, Ext.ExtraData.InitiativeBonusFromWits, Ext.ExtraData.DGM_WitsDotBonus)
        statsPointValue.Label = GetDynamicTranslationString(stat, attrBonus["wits"], attrBonus["witsCrit"], attrBonus["witsIni"], attrBonus["witsDot"])
        
    elseif stat == "Damage" then
        local damageText = tooltip:GetElement("StatsTotalDamage")
        local minDamage = damageText.Label:gsub("^.* ", ""):gsub("-[1-9]*", "")
        local maxDamage = damageText.Label:gsub("^.*-", "")
        
        minDamage = math.floor(tonumber(minDamage) * (100+attrBonus["strGlobal"]+attrBonus["strWeapon"]+attrBonus["finGlobal"]+attrBonus["intGlobal"])/100)
        maxDamage = math.floor(tonumber(maxDamage) * (100+attrBonus["strGlobal"]+attrBonus["strWeapon"]+attrBonus["finGlobal"]+attrBonus["intGlobal"])/100)
        
        damageText.Label = GetDynamicTranslationString(stat, minDamage, maxDamage)
    end

end

---@param character EsvCharacter
---@param stat string
---@param tooltip TooltipData
local function OnAbilityTooltip(character, stat, tooltip)
    
    local stat = tooltip:GetElement("StatName").Label
    local abilityDescription = tooltip:GetElement("AbilityDescription")
    local attrBonus = CharGetDGMAttributeBonus(character, 0)
    local attrBonusNew = CharGetDGMAttributeBonus(character, 1)
    local stats = character.Stats

    if stat == "Dual-Wielding" then

        if stats.DualWielding > 0 then
            abilityDescription.CurrentLevelEffect = GetDynamicTranslationString(stat, stats.DualWielding, attrBonus["dual"], attrBonus["dualDodge"], attrBonus["dualOff"])
        end
        
        abilityDescription.NextLevelEffect = GetDynamicTranslationString(stat.."_Next", stats.DualWielding+1, attrBonusNew["dual"], attrBonusNew["dualDodge"], attrBonusNew["dualOff"])
        
    elseif stat == "Ranged" then
        if stats.Ranged > 0 then
            abilityDescription.CurrentLevelEffect = GetDynamicTranslationString(stat, stats.Ranged, attrBonus["ranged"], attrBonus["rangedCrit"], attrBonus["rangedRange"])
        end
        
        abilityDescription.NextLevelEffect = GetDynamicTranslationString(stat.."_Next", stats.Ranged+1, attrBonusNew["ranged"], attrBonusNew["rangedCrit"], attrBonusNew["rangedRange"])

    elseif stat == "Single-Handed" then
        if stats.SingleHanded > 0 then
            abilityDescription.CurrentLevelEffect = GetDynamicTranslationString(stat, stats.SingleHanded, attrBonus["single"], attrBonus["singleAcc"], attrBonus["singleArm"], attrBonus["singleEle"])
        end

        abilityDescription.NextLevelEffect = GetDynamicTranslationString(stat, stats.SingleHanded+1, attrBonusNew["single"], attrBonusNew["singleAcc"], attrBonusNew["singleArm"], attrBonusNew["singleEle"])
        
    elseif stat == "Two-Handed" then
        if stats.TwoHanded > 0 then
            abilityDescription.CurrentLevelEffect = GetDynamicTranslationString(stat, stats.TwoHanded, attrBonus["two"], attrBonus["twoCrit"])
        end

        abilityDescription.NextLevelEffect =  GetDynamicTranslationString(stat, stats.TwoHanded+1, attrBonusNew["two"], attrBonusNew["twoCrit"], attrBonusNew["twoAcc"])

    elseif stat == "Perseverance" then
        if stats.Perseverance > 0 then
            abilityDescription.CurrentLevelEffect = GetDynamicTranslationString(stat, stats.Perseverance, attrBonus["persArm"], attrBonus["persVit"])
        end
        
        abilityDescription.NextLevelEffect = GetDynamicTranslationString(stat, stats.Perseverance+1, attrBonusNew["persArm"], attrBonusNew["persVit"])

    end
end

local tooltipFix = {
    Finesse = "h3b3ad9d6g754fg44a0g953dg4f87d4ac96fe",
    Intelligence = "h33d41553g12cag401eg8c71g640d3d654054",
    SingleHanded = "ha74334b1gd56bg49c2g8738g44da4decd00a",
    TwoHanded = "h3fb5cd5ag9ec8g4746g8f9cg03100b26bd3a",
    CrossbowSlow = "h52ee27b1g46a7g4a0dg95b3gf519d1072d3b"
}

-- Tooltip here is the fix for not being able to put a translation key on generated statuses for custom bonuses
---@param character EsvCharacter
---@param skill any
---@param tooltip TooltipData
local function FixCustomBonusesTranslationKeyBonus(character, stat, tooltip)
    local boosts = tooltip:GetElements("StatsPercentageBoost")
    if #boosts == 0 then 
        boosts = tooltip:GetElements("StatsTalentsBoost")
        if #boosts == nil then return end
    end
    for i,boost in pairs(boosts) do
        if string.find(boost.Label, "DGM_Potion_.*_[0-9]+:") ~= nil then
            local str = boost.Label:gsub("DGM_Potion_", "")
            str = str:gsub("_[0-9]*", "")
            local stat = str:gsub("^%a* ", "")
            stat = stat:gsub(":.*$", "")
            local final = Ext.GetTranslatedString(tooltipFix[stat], stat)
            str = str:gsub(" .*:", " "..final..":")
            boost.Label = str
        end
    end
end

local function FixCustomBonusesTranslationKeyMalus(character, stat, tooltip)
    local boosts = tooltip:GetElements("StatsPercentageMalus")
    if #boosts == 0 then 
        boosts = tooltip:GetElements("StatsTalentsMalus")
        if #boosts == nil then return end
    end
    for i,boost in pairs(boosts) do
        if string.find(boost.Label, "DGM_Potion_.*_-[0-9]+:") ~= nil then
            local str = boost.Label:gsub("DGM_Potion_", "")
            str = str:gsub("_%-[0-9]+", "")
            str = str:gsub("_[0-9]*", "")
            local stat = str:gsub("^%a* ", "")
            stat = stat:gsub(":.*$", "")
            local final = Ext.GetTranslatedString(tooltipFix[stat], stat)
            str = str:gsub(" .*:", " "..final..":")
            boost.Label = str
        end
    end
end

local function DGM_Init()
    Game.Tooltip.RegisterListener("Item", nil, WeaponTooltips)
    Game.Tooltip.RegisterListener("Stat", "Damage", SkillAttributeTooltipBonus)
    Game.Tooltip.RegisterListener("Stat", nil, OnStatTooltip)
    Game.Tooltip.RegisterListener("Ability", nil, OnAbilityTooltip)
    Game.Tooltip.RegisterListener("Stat", nil, FixCustomBonusesTranslationKeyBonus)
    Game.Tooltip.RegisterListener("Stat", nil, FixCustomBonusesTranslationKeyMalus)
end

Ext.RegisterListener("SessionLoaded", DGM_Init)