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
	if item.WeaponType == "Staff" then equipment["Label"] = "Increase Skill damages by 110%" end
	if item.WeaponType == "Wand" then equipment["Label"] = "Increase Skill damages by 102.5% (stackable when dual-wielding)" end
	if item.WeaponType == "Bow" or item.WeaponType == "Crossbow" or item.WeaponType == "Rifle" then equipment["Label"]="Get a 35% Damage penalty if the target is closer than 2 meters."; equipment["RequirementMet"]=false end
	if equipment["Label"] ~= "" then tooltip:AppendElementAfter(equipment, "ExtraProperties") end
	if item.WeaponType == "Wand" then
		local equipment = {
			Type = "ItemRequirement",
			Label = "Get a 35% Damage penalty if the target is closer than 2 meters.",
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
        Label = "From Attributes : +"..generalBonus.."%"
    }
    local strength = {
        Type = "StatsPercentageBoost",
        Label = "From Strength weapon bonus : +"..strengthBonus.."%"
    }
    local intelligence = {
        Type = "StatsPercentageBoost",
        Label = "Skills gets a bonus of +"..intelligenceBonus.."% from Intelligence."
    }
    tooltip:AppendElementAfter(general, "StatsPercentageBoost")
    tooltip:AppendElementAfter(strength, "StatsPercentageBoost")
    tooltip:AppendElementAfter(intelligence, "StatsPercentageBoost")

    if not stats.MainWeapon.IsTwoHanded then
        if stats.OffHandWeapon ~= nil and stats.OffHandWeapon.WeaponType ~= "Shield" then
            local offhandPenalty = tooltip:GetElements("StatsPercentageMalus")
            for i,j in pairs(offhandPenalty) do
                local translatedKey = Ext.GetTranslatedString("he3980bf8gf554g4dd8g823cgf2ccb71036a6", "Offhand penalty: [1]%")
                local finalPenalty = math.floor(Ext.ExtraData.DualWieldingDamagePenalty*100 - stats.DualWielding*(Ext.ExtraData.DualWieldingDamagePenalty*10))
                if j.Label:find(translatedKey:gsub("%[1]%%", "")) ~= nil then
                    local replacement = finalPenalty.."%% (penalty reduced by "..tostring(math.floor(stats.DualWielding*(Ext.ExtraData.DualWieldingDamagePenalty*10))).."%% from Dual-wielding)"
                    j.Label = translatedKey:gsub("%[1]%%", replacement)
                end
            end
        end
    end
end

local dynamicTooltips = {
    ["Strength"] = "he1708d1eg243dg4b72g8f48gddb9bc8d62ff",
    ["Finesse"] = "h2e87e6cfg0183g4968g8ec1g325614c7d9fa",
    ["Intelligence"] = "h58e777ddgd569g4c0dg8f58gece56cce053d",
    ["Wits"] = "ha422c4f4ge2bbg4cbcgbbf3g505c7ce673d1",
    ["Damage"] = "h7fec5db8g58d3g4abbgab7ag03e19b542bef",
    ["Dual-Wielding"] = {current = "hc5d5552bg6b33g44c1gbb0cg8d55a101f081", new = "h2baa6ed9gdca0g4731gb999g098d9c2d90b0"},
    ["Ranged"] = {current = "he86bfd28ge123g42a4g8c0cg2f9bcd7d9e05", new = "hffc37ae5g6651g4a60ga1c1g49d233cb1ca2"},
    ["Single-Handed"] = {current = "h70707bb2g5a48g4571g9a68ged2fe5a030ea", new = "h2afdc1f0g4650g4ea9gafb7gb0c042367766"},
    ["Two-Handed"] = {current = "h6e9ec88dgcbb7g426bgb1d9g69df0240825a", new = "hda7ee9a4g5bbeg4c62g96b7ge31b21e094f3"},
    ["Perseverance"] = {current = "h5d0c3ad0g3d9dg4cf1g92b7g20d6d7d26344", new = "h443a51dcgbd6fg46c2g8988gbfe93a3123a5"}
}

---@param str string
local function SubstituteString(str, ...)
    local args = {...}
    local result = str
    for k, v in pairs(args) do
        result = result:gsub("%["..tostring(k).."%]", v)
    end
    return result
end

---@param character EsvCharacter
---@param skill string
---@param tooltip TooltipData
local function OnStatTooltip(character, stat, tooltip)

    -- Ext.Print(Ext.JsonStringify(tooltip))
    
    local stat = tooltip:GetElement("StatName").Label
    local statsPointValue = tooltip:GetElement("StatsPointValue")

    local attrBonus = CharGetDGMAttributeBonus(character, 0)

    local str = nil
    if dynamicTooltips[stat] then
        str = Ext.GetTranslatedString(dynamicTooltips[stat], "Handle Error!")
    end

    if stat == "Strength" then
        str = SubstituteString(str, attrBonus["str"], attrBonus["strGlobal"], attrBonus["strWeapon"], attrBonus["strRes"])
        statsPointValue.Label = str
    elseif stat == "Finesse" then
        str = SubstituteString(str, attrBonus["fin"], attrBonus["finGlobal"], attrBonus["finDodge"], attrBonus["finMovement"], attrBonus["finCrit"])
        statsPointValue.Label = str
    elseif stat == "Intelligence" then
        str = SubstituteString(str, attrBonus["int"], attrBonus["intGlobal"], attrBonus["intSkill"], attrBonus["intAcc"])
        statsPointValue.Label = str
    elseif stat == "Wits" then
        str = SubstituteString(str, attrBonus["wits"], attrBonus["witsCrit"], attrBonus["witsIni"], attrBonus["witsDot"])
        statsPointValue.Label = str
    elseif stat == "Damage" then
        local damageText = tooltip:GetElement("StatsTotalDamage")
        local minDamage = damageText.Label:gsub("^.* ", ""):gsub("-[1-9]*", "")
        local maxDamage = damageText.Label:gsub("^.*-", "")
        
        minDamage = math.floor(tonumber(minDamage) * (100+attrBonus["strGlobal"]+attrBonus["strWeapon"]+attrBonus["finGlobal"]+attrBonus["intGlobal"])/100)
        maxDamage = math.floor(tonumber(maxDamage) * (100+attrBonus["strGlobal"]+attrBonus["strWeapon"]+attrBonus["finGlobal"]+attrBonus["intGlobal"])/100)
        
        str = SubstituteString(str, minDamage, maxDamage)
        damageText.Label = str
    end

    -- Ext.Print(Ext.JsonStringify(tooltip))
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

    local str = ""

    if stat == "Dual-Wielding" then

        if stats.DualWielding > 0 then
            str = Ext.GetTranslatedString(dynamicTooltips[stat].current, "Handle Error!")
            str = SubstituteString(str, stats.DualWielding, attrBonus["dual"], attrBonus["dualDodge"], attrBonus["dualOff"])
            abilityDescription.CurrentLevelEffect = str
        end
        
        str = Ext.GetTranslatedString(dynamicTooltips[stat].new, "Handle Error!")
        str = SubstituteString(str, stats.DualWielding+1, attrBonusNew["dual"], attrBonusNew["dualDodge"], attrBonusNew["dualOff"])
        abilityDescription.NextLevelEffect = str
        
    elseif stat == "Ranged" then
        if stats.Ranged > 0 then
            str = Ext.GetTranslatedString(dynamicTooltips[stat].current, "Handle Error!")
            str = SubstituteString(str, stats.Ranged, attrBonus["ranged"], attrBonus["rangedCrit"], attrBonus["rangedRange"])
            abilityDescription.CurrentLevelEffect = str
        end
        
        str = Ext.GetTranslatedString(dynamicTooltips[stat].new, "Handle Error!")
        str = SubstituteString(str, stats.Ranged+1, attrBonusNew["ranged"], attrBonusNew["rangedCrit"], attrBonusNew["rangedRange"])
        abilityDescription.NextLevelEffect = str

    elseif stat == "Single-Handed" then
        if stats.SingleHanded > 0 then
            str = Ext.GetTranslatedString(dynamicTooltips[stat].current, "Handle Error!")
            str = SubstituteString(str, stats.SingleHanded, attrBonus["single"], attrBonus["singleAcc"], attrBonus["singleArm"], attrBonus["singleEle"])
            abilityDescription.CurrentLevelEffect = str
        end
        
        str = Ext.GetTranslatedString(dynamicTooltips[stat].new, "Handle Error!")
        str = SubstituteString(str, stats.SingleHanded+1, attrBonusNew["single"], attrBonusNew["singleAcc"], attrBonusNew["singleArm"], attrBonusNew["singleEle"])
        abilityDescription.NextLevelEffect = str
        
    elseif stat == "Two-Handed" then
        if stats.TwoHanded > 0 then
            str = Ext.GetTranslatedString(dynamicTooltips[stat].current, "Handle Error!")
            str = SubstituteString(str, stats.TwoHanded, attrBonus["two"], attrBonus["twoCrit"], attrBonus["twoAcc"])
            abilityDescription.CurrentLevelEffect = str
        end
        
        str = Ext.GetTranslatedString(dynamicTooltips[stat].new, "Handle Error!")
        str = SubstituteString(str, stats.TwoHanded+1, attrBonusNew["two"], attrBonusNew["twoCrit"], attrBonusNew["twoAcc"])
        abilityDescription.NextLevelEffect = str

    elseif stat == "Perseverance" then
        if stats.Perseverance > 0 then
            str = Ext.GetTranslatedString(dynamicTooltips[stat].current, "Handle Error!")
            str = SubstituteString(str, stats.Perseverance, attrBonus["persArm"], attrBonus["persVit"])
            abilityDescription.CurrentLevelEffect = str
        end
        
        str = Ext.GetTranslatedString(dynamicTooltips[stat].new, "Handle Error!")
        str = SubstituteString(str, stats.Perseverance+1, attrBonusNew["persArm"], attrBonusNew["persVit"])
        abilityDescription.NextLevelEffect = str

    end

    -- Ext.Print(Ext.JsonStringify(tooltip))
end

local tooltipFix = {
    Finesse = "h3b3ad9d6g754fg44a0g953dg4f87d4ac96fe",
    Intelligence = "h33d41553g12cag401eg8c71g640d3d654054",
    SingleHanded = "ha74334b1gd56bg49c2g8738g44da4decd00a",
    TwoHanded = "h3fb5cd5ag9ec8g4746g8f9cg03100b26bd3a"
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