local weaponAbilitiesTK = {
    ["TwoHanded"] = "h3fb5cd5ag9ec8g4746g8f9cg03100b26bd3a",
    ["SingleHanded"] = "ha74334b1gd56bg49c2g8738g44da4decd00a",
    ["Ranged"] = "hdda30cb9g17adg433ag9071g867e97c09c3a",
    ["DualWielding"] = "h03d68693g35e7g4721ga1b3g9f9882f08b12"
}

---@param character EclCharacter
---@param skill any
---@param tooltip TooltipData
local function SkillAttributeTooltipBonus(character, skill, tooltip)
    local stats = character.Stats
    local generalBonus = math.floor((stats.Strength-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthGlobalBonus +
    (stats.Finesse-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_FinesseGlobalBonus +
    (stats.Intelligence-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceGlobalBonus)
    local strengthBonus = math.floor((stats.Strength-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthWeaponBonus)
    local intelligenceBonus = math.floor((stats.Intelligence-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceSkillBonus)
    local weaponAbility = Game.Math.GetWeaponAbility(character.Stats, character.Stats.MainWeapon)
    local abilityBonus = math.floor(Data.Math.GetCharacterWeaponAbilityBonus(character))

    local general = {
        Type = "StatsPercentageBoost",
        Label = Helpers.GetDynamicTranslationStringFromKey("AttributesGeneralBonusDynamicTooltip", generalBonus)
    }
    local strength = {
        Type = "StatsPercentageBoost",
        Label = Helpers.GetDynamicTranslationStringFromKey("Strength_WeaponDamageTooltip", strengthBonus)
    }
    local intelligence = {
        Type = "StatsPercentageBoost",
        Label = Helpers.GetDynamicTranslationStringFromKey("Intelligence_SkillDamageTooltip", intelligenceBonus)
    }

    local ability = {
        Type = "StatsPercentageBoost",
        Label = string.sub(Helpers.GetDynamicTranslationStringFromHandle("h2b23ff71g3f03g4ec6g83cagcbeeae126da7", Ext.L10N.GetTranslatedString(weaponAbilitiesTK[weaponAbility]), abilityBonus, ""), 5).."%"
    }

    tooltip:AppendElementAfter(general, "StatsPercentageBoost")
    tooltip:AppendElementAfter(strength, "StatsPercentageBoost")
    tooltip:AppendElementAfter(intelligence, "StatsPercentageBoost")
    tooltip:AppendElementAfter(ability, "StatsPercentageBoost")
end

---@param character EclCharacter
---@param stat string
---@param tooltip TooltipData
local function OnStatTooltip(character, stat, tooltip)
    if tooltip == nil or tooltip:GetElement("StatName") == nil then return end
    -- Ext.Dump(tooltip:GetElement("StatName"))
    local stat = tooltip:GetElement("StatName").Label
    local statsDescription = tooltip:GetElement("StatsDescription")
    local statsPointValue = tooltip:GetElement("StatsPointValue")
    local baseValue = Ext.ExtraData.AttributeBaseValue
    -- local tooltip = Ext.UI.GetByType(44):GetRoot()

    local attrBonus = CharGetDGMAttributeBonus(character, 0)

    if stat == "Strength" then
        statsDescription.Label = Helpers.GetDynamicTranslationStringFromKey("Strength_Description", Ext.ExtraData.DGM_StrengthGlobalBonus, Ext.ExtraData.DGM_StrengthWeaponBonus, Ext.ExtraData.DGM_StrengthIngressCap)
        statsPointValue.Label = Helpers.GetDynamicTranslationStringFromKey("Strength_DynamicTooltip", attrBonus["str"], attrBonus["strGlobal"], attrBonus["strWeapon"], attrBonus["strIngCap"])

    elseif stat == "Finesse" then
        statsDescription.Label = Helpers.GetDynamicTranslationStringFromKey("Finesse_Description", Ext.ExtraData.DGM_FinesseGlobalBonus, math.floor(Ext.Utils.Round(Ext.ExtraData.DodgingBoostFromAttribute*100)), Ext.ExtraData.DGM_FinesseMovementBonus/100, Ext.ExtraData.DGM_FinesseAccuracyFromIntelligenceCap)
        statsPointValue.Label = Helpers.GetDynamicTranslationStringFromKey("Finesse_DynamicTooltip", attrBonus["fin"], attrBonus["finGlobal"], attrBonus["finDodge"], attrBonus["finMovement"], attrBonus["finAccCap"])

    elseif stat == "Intelligence" then
        statsDescription.Label = Helpers.GetDynamicTranslationStringFromKey("Intelligence_Description", Ext.ExtraData.DGM_IntelligenceGlobalBonus, Ext.ExtraData.DGM_IntelligenceSkillBonus, Ext.ExtraData.DGM_IntelligenceAccuracyBonus, Ext.ExtraData.DGM_IntelligenceIngressBonus, Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap)
        local ingBonus = math.floor((character.Stats.Intelligence - baseValue) * Ext.ExtraData.DGM_IntelligenceIngressBonus)
        local ingCap = math.floor((character.Stats.Strength - baseValue) * Ext.ExtraData.DGM_StrengthIngressCap)
        local ingCapWarning = ""
        if ingBonus > ingCap then
            ingBonus = "<font color='#FF9600'>"..tostring(ingCap)
            ingCapWarning = " "..Ext.L10N.GetTranslatedStringFromKey("Strength_Cap").."</font>"
        end
        local accBonus = math.floor((character.Stats.Intelligence - baseValue) * Ext.ExtraData.DGM_IntelligenceAccuracyBonus)
        local accCap = math.floor((character.Stats.Finesse - baseValue) * Ext.ExtraData.DGM_FinesseAccuracyFromIntelligenceCap)
        local accCapWarning = ""
        if accBonus > accCap then
            accBonus = "<font color='#FF9600'>"..tostring(accCap)
            accCapWarning = " "..Ext.L10N.GetTranslatedStringFromKey("Finesse_Cap").."</font>"
        end
        statsPointValue.Label = Helpers.GetDynamicTranslationStringFromKey("Intelligence_DynamicTooltip", attrBonus["int"], attrBonus["intGlobal"], attrBonus["intSkill"], accBonus, accCapWarning, ingBonus, ingCapWarning, attrBonus.intWisCap)

    elseif stat == "Wits" then
        statsDescription.Label = Helpers.GetDynamicTranslationStringFromKey("Wits_Description", Ext.ExtraData.CriticalBonusFromWits, Ext.ExtraData.InitiativeBonusFromWits, Ext.ExtraData.DGM_WitsDotBonus, Ext.ExtraData.DGM_WitsWisdomBonus)
        local wisBonus =  math.floor((character.Stats.Wits - baseValue) * Ext.ExtraData.DGM_WitsWisdomBonus)
        local wisCap =  math.floor((character.Stats.Intelligence - baseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap)
        local wisCapWarning = ""
        if wisBonus > wisCap then
            wisBonus = "<font color='#FF9600'>"..tostring(wisCap)
            wisCapWarning = " "..Ext.L10N.GetTranslatedStringFromKey("Intelligence_Cap").."</font>"
        end
        statsPointValue.Label = Helpers.GetDynamicTranslationStringFromKey("Wits_DynamicTooltip", attrBonus["wits"], attrBonus["witsCrit"], attrBonus["witsIni"], attrBonus["witsDot"], wisBonus, wisCapWarning)

    elseif stat == "Critical Chance" then
        statsDescription.Label = Helpers.GetDynamicTranslationStringFromKey("CriticalChance_Description", Ext.ExtraData.DGM_BackstabCritChanceBonus)
        
    elseif stat == "Damage" then
        local damageText = tooltip:GetElement("StatsTotalDamage")
        -- local minDamage = damageText.Label:gsub("^.* ", ""):gsub("-[1-9]*", "")
        -- local maxDamage = damageText.Label:gsub("^.*-", "")
        
        -- minDamage = math.floor(tonumber(minDamage) * (100+attrBonus["strGlobal"]+attrBonus["strWeapon"]+attrBonus["finGlobal"]+attrBonus["intGlobal"])/100)
        -- maxDamage = math.floor(tonumber(maxDamage) * (100+attrBonus["strGlobal"]+attrBonus["strWeapon"]+attrBonus["finGlobal"]+attrBonus["intGlobal"])/100)

        local damage = CustomGetSkillDamageRange(character.Stats, Ext.Stats.Get("Target_LX_NormalAttack"),  character.Stats.MainWeapon, character.Stats.OffHandWeapon, true)
        local minDamage = 0
        local maxDamage = 0
        for dtype,range in pairs(damage) do
            minDamage = minDamage + range.Min
            maxDamage = maxDamage + range.Max
        end
        
        damageText.Label = Helpers.GetDynamicTranslationStringFromKey("Damage_DynamicTooltip", minDamage, maxDamage)
    end
end

--- Bonus values tooltips for attributes remove the font tags, so they have to be overriden directly.
--- TODO: better handling of the process
---@param e EclLuaUICallEvent
Ext.Events.UICall:Subscribe(function(e)
    if e.Function == "setTooltipSize" then
        Ext.OnNextTick(function(e)          
            local tooltip = Ext.UI.GetByType(44):GetRoot()
            if tooltip.tf and tooltip.tf.tooltip_mc and tostring(Ext.UI.GetByType(119):GetRoot().charHandle) ~= "nan" then
                local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(119):GetRoot().charHandle))
                local attrBonus = CharGetDGMAttributeBonus(character, 0)
                local baseValue = Ext.ExtraData.AttributeBaseValue

                if string.lower(tooltip.tf.tooltip_mc.header_mc.title_txt.htmlText) == string.lower(Ext.L10N.GetTranslatedString("h8e8351e9gc40ag4e4cgaebfgc810a27ffff8", "Intelligence")) then
                    local ingBonus = math.floor((character.Stats.Intelligence - baseValue) * Ext.ExtraData.DGM_IntelligenceIngressBonus)
                    local ingCap = math.floor((character.Stats.Strength - baseValue) * Ext.ExtraData.DGM_StrengthIngressCap)
                    local ingCapWarning = ""
                    if ingBonus > ingCap then
                        ingBonus = "<font color='#FF9600'>"..tostring(ingCap)
                        ingCapWarning = " "..Ext.L10N.GetTranslatedStringFromKey("Strength_Cap").."</font>"
                    end
                    local accBonus = math.floor((character.Stats.Intelligence - baseValue) * Ext.ExtraData.DGM_IntelligenceAccuracyBonus)
                    local accCap = math.floor((character.Stats.Finesse - baseValue) * Ext.ExtraData.DGM_FinesseAccuracyFromIntelligenceCap)
                    local accCapWarning = ""
                    if accBonus > accCap then
                        accBonus = "<font color='#FF9600'>"..tostring(accCap)
                        accCapWarning = " "..Ext.L10N.GetTranslatedStringFromKey("Finesse_Cap").."</font>"
                    end
                    tooltip.tf.tooltip_mc.list.content_array[1].list.content_array[0].label_txt.htmlText = Helpers.GetDynamicTranslationStringFromKey("Intelligence_DynamicTooltip", attrBonus["int"], attrBonus["intGlobal"], attrBonus["intSkill"], accBonus, accCapWarning, ingBonus, ingCapWarning, attrBonus.intWisCap)

                elseif string.lower(tooltip.tf.tooltip_mc.header_mc.title_txt.htmlText) == string.lower(Ext.L10N.GetTranslatedString("hb385d2f8gfb21g41a1gad09gefe0cbc67c6a", "Wits")) then
                    local wisBonus =  math.floor((character.Stats.Wits - baseValue) * Ext.ExtraData.DGM_WitsWisdomBonus)
                    local wisCap =  math.floor((character.Stats.Intelligence - baseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap)
                    local wisCapWarning = ""
                    if wisBonus > wisCap then
                        wisBonus = "<font color='#FF9600'>"..tostring(wisCap)
                        wisCapWarning = " "..Ext.L10N.GetTranslatedStringFromKey("Intelligence_Cap").."</font>"
                    end
                    tooltip.tf.tooltip_mc.list.content_array[1].list.content_array[0].label_txt.htmlText = Helpers.GetDynamicTranslationStringFromKey("Wits_DynamicTooltip", attrBonus["wits"], attrBonus["witsCrit"], attrBonus["witsIni"], attrBonus["witsDot"], wisBonus, wisCapWarning)
                end
            end
        end)
    end
end)

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

        -- if stats.DualWielding > 0 then
        --     abilityDescription.CurrentLevelEffect = Helpers.GetDynamicTranslationStringFromKey("DualWielding_Description", stats.DualWielding, attrBonus["dual"], attrBonus["dualDodge"], math.floor(attrBonus["dualOff"]/2))
        -- end
        
        -- abilityDescription.NextLevelEffect = Helpers.GetDynamicTranslationStringFromKey("DualWielding_TooltipNext", stats.DualWielding+1, attrBonusNew["dual"], attrBonusNew["dualDodge"], math.floor(attrBonus["dualOff"]/2))
        
    elseif stat == "Ranged" then
        if stats.Ranged > 0 then
            abilityDescription.CurrentLevelEffect = Helpers.GetDynamicTranslationStringFromKey("Ranged_TooltipCurrent", stats.Ranged, attrBonus["ranged"], attrBonus["rangedCrit"], attrBonus["rangedRange"])
        end
        
        abilityDescription.NextLevelEffect = Helpers.GetDynamicTranslationStringFromKey("Ranged_TooltipNext", stats.Ranged+1, attrBonusNew["ranged"], attrBonusNew["rangedCrit"], attrBonusNew["rangedRange"])

    elseif stat == "Single-Handed" then
        if stats.SingleHanded > 0 then
            abilityDescription.CurrentLevelEffect = Helpers.GetDynamicTranslationStringFromKey("SingleHanded_TooltipCurrent", stats.SingleHanded, attrBonus["single"], attrBonus["singleAcc"], attrBonus["singleArm"], attrBonus["singleEle"])
        end

        abilityDescription.NextLevelEffect = Helpers.GetDynamicTranslationStringFromKey("SingleHanded_TooltipNext", stats.SingleHanded+1, attrBonusNew["single"], attrBonusNew["singleAcc"], attrBonusNew["singleArm"], attrBonusNew["singleEle"])
        
    elseif stat == "Two-Handed" then
        if stats.TwoHanded > 0 then
            abilityDescription.CurrentLevelEffect = Helpers.GetDynamicTranslationStringFromKey("TwoHanded_TooltipCurrent", stats.TwoHanded, attrBonus["two"], attrBonus["twoCrit"])
        end

        abilityDescription.NextLevelEffect =  Helpers.GetDynamicTranslationStringFromKey("TwoHanded_TooltipNext", stats.TwoHanded+1, attrBonusNew["two"], attrBonusNew["twoCrit"], attrBonusNew["twoAcc"])

    elseif stat == "Perseverance" then
        local pointValue = Ext.Utils.Round(Game.Math.GetAverageLevelDamage(stats.Level) * Ext.ExtraData.DGM_PerseveranceRecovery / 100)
        local current = pointValue * stats.Perseverance
        local next = pointValue * (stats.Perseverance + 1)
        if stats.Perseverance > 0 then
            abilityDescription.CurrentLevelEffect = Helpers.GetDynamicTranslationStringFromKey("Perseverance_TooltipCurrent", stats.Perseverance, current)
        end
        
        abilityDescription.NextLevelEffect = Helpers.GetDynamicTranslationStringFromKey("Perseverance_TooltipNext", stats.Perseverance+1, next)
    
    elseif stat == "Hydrosophist" then
        if stats.WaterSpecialist > 0 then
            abilityDescription.CurrentLevelEffect = Helpers.GetDynamicTranslationStringFromKey("Hydrosophist_TooltipCurrent", stats.WaterSpecialist, attrBonus["hydroDmg"], attrBonus["hydroHeal"], attrBonus["hydroArmor"])
        end
        
        abilityDescription.NextLevelEffect = Helpers.GetDynamicTranslationStringFromKey("Hydrosophist_TooltipNext", stats.WaterSpecialist+1, attrBonusNew["hydroDmg"], attrBonusNew["hydroHeal"], attrBonusNew["hydroArmor"])

    end
end

local tooltipFix = {
    Finesse = "h3b3ad9d6g754fg44a0g953dg4f87d4ac96fe",
    Intelligence = "h33d41553g12cag401eg8c71g640d3d654054",
    SingleHanded = "ha74334b1gd56bg49c2g8738g44da4decd00a",
    TwoHanded = "h3fb5cd5ag9ec8g4746g8f9cg03100b26bd3a",
    CrossbowSlow = "h52ee27b1g46a7g4a0dg95b3gf519d1072d3b",
    Perseverance = "h5b61fccfg5d2ag4a81g9cacg068403d61b5c",
    Corrogic = "hb24edf38gd48ag477fgbf75g3bd3de8c6eec",
    Warmup = "h565877e2g71eag43aag928fgfee5ca4f0c4f",
    AimedShot = "he5970b83g4f56g4348g8d23g39bce69f8c3c"
}

-- Tooltip here is the fix for not being able to put a translation key on generated statuses for custom bonuses
---@param character EsvCharacter
---@param skill any
---@param tooltip TooltipData
local function FixCustomBonusesTranslationKeyBonus(character, stat, tooltip)
    if tooltip == nil then return end
    local boosts = tooltip:GetElements("StatsPercentageBoost")
    if #boosts == 0 then 
        boosts = tooltip:GetElements("StatsTalentsBoost")
        if #boosts == nil then return end
    end
    -- Ext.Dump(boosts)
    for i,boost in pairs(boosts) do
        if string.find(boost.Label, "DGM_Potion_.*_.*:") ~= nil then
            -- Ext.Print("STRING REPLACEMENT")
            local str = boost.Label:gsub("DGM_Potion_", "")
            -- Ext.Print(str)
            str = str:gsub("_.*:", ":")
            -- Ext.Print(str)
            local stat = str:gsub("^%a* ", "")
            -- Ext.Print(stat)
            stat = stat:gsub(":.*$", "")
            local final = Ext.GetTranslatedString(tooltipFix[stat], stat)
            str = str:gsub(" .*:", " "..final..":")
            boost.Label = str
        end
    end
end

local function FixCustomBonusesTranslationKeyMalus(character, stat, tooltip)
    if tooltip == nil then return end
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

---- Credits to Focus
---@param character EsvCharacter
---@param talent string
---@param tooltip TooltipData
local function TalentTooltip(character, talent, tooltip)
    local description = tooltip:GetElement("TalentDescription")
    if talent == "IceKing" then
        description.Description = Ext.GetTranslatedStringFromKey("IceKing")
    elseif talent == "Demon" then
        description.Description = Ext.GetTranslatedStringFromKey("Demon")
    end
end

---@param character EsvCharacter
---@param skill string
---@param tooltip TooltipData
local function TeleportTooltip(character, skill, tooltip)
    local description = tooltip:GetElement("SkillDescription")
    description.Label = description.Label.."<br>"..Helpers.GetDynamicTranslationStringFromKey("Condition_OneArmorDown")
end

---@param character EsvCharacter
---@param skill string
---@param tooltip TooltipData
local function AimedShotTooltip(character, skill, tooltip)
    local description = tooltip:GetElement("SkillDescription")
    local accuracy = math.floor(20 + (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * 3)
    description.Label = Helpers.GetDynamicTranslationStringFromKey("Shout_LX_AimedShot_Description", accuracy, math.floor(character.Stats.Strength))
end

---@param character EsvCharacter
---@param skill string
---@param tooltip TooltipData
local function AdrenalineTooltip(character, skill, tooltip)
    local property = tooltip:GetElement("SkillProperties").Properties[1]
    local label = string.gsub(string.reverse(property.Label), "%d+", "3", 1)
    property.Label = string.reverse(label)
end

---@param character EclCharacter
---@param skill string
---@param tooltip TooltipData
local function ComputeTooltipHealings(character, skill, tooltip)
    -- _D(tooltip)
    local stat = Ext.Stats.Get(skill, nil, false)
    if stat.SkillProperties then
        for i,property in pairs(stat.SkillProperties) do
            if property.Type == "Status" then
                local status = Ext.Stats.Get(property.Action, nil, false) --- @type EclStatusHealing|EclStatusHeal
                if status and status.HealValue > 0 and status.HealType == "Qualifier" then
                    local properties = tooltip:GetElement("SkillProperties")
                    for j,tooltipProperty in pairs(properties.Properties) do
                        if string.match(tooltipProperty.Label, '<font color=\"#97FBFF\">') then
                            local computedValue = Data.Math.GetHealScaledWisdomValue(status, character)
                            tooltipProperty.Label = string.gsub(tooltipProperty.Label, ">%d+ ", ">"..tostring(computedValue).." ")
                        end
                    end
                end
            end
        end
    end
end

---@param character EclCharacter
---@param status EclStatus|EclStatusChallenge|EclStatusDamage|EclStatusDamageOnMove|EclStatusConsumeBaseStatsData|EclStatusIncapacitated|EclStatusAoO|EclStatusEffect
---@param tooltip TooltipData
local function DamageStatusTooltipScaleFromPower(character, status, tooltip)
    if getmetatable(status) == "ecl::StatusDamage" and status.StatsMultiplier ~= 1 then
        local description = tooltip:GetElements("StatusDescription")
        local damageRanges = {}
        for minValue, maxValue in string.gmatch(description[1].Label, "(%d+)%-(%d+)") do
            table.insert(damageRanges, {Ext.Utils.Round(math.floor(minValue * status.StatsMultiplier)), Ext.Utils.Round(math.floor(maxValue * status.StatsMultiplier))})
        end
        local updatedStr = description[1].Label:gsub("(%d+)%-(%d+)", function(oldMin, oldMax)
            for i,replacements in pairs(damageRanges) do
                -- Check if a replacement is available
                if replacements[i] then
                    local newMin = replacements[1]
                    local newMax = replacements[2]
                    return newMin .. "-" .. newMax
                else
                    -- If no replacement is provided, return the original range
                    return oldMin .. "-" .. oldMax
                end
            end
        end)
        description[1].Label = updatedStr
    end
end

---comment
---@param e LuaEmptyEvent
local function DGM_Tooltips_Init(e)
    Game.Tooltip.RegisterListener("Stat", "Damage", SkillAttributeTooltipBonus)
    Game.Tooltip.RegisterListener("Stat", nil, OnStatTooltip)
    Game.Tooltip.RegisterListener("Ability", nil, OnAbilityTooltip)
    Game.Tooltip.RegisterListener("Stat", nil, FixCustomBonusesTranslationKeyBonus)
    Game.Tooltip.RegisterListener("Stat", nil, FixCustomBonusesTranslationKeyMalus)
    Game.Tooltip.RegisterListener("Talent", nil, TalentTooltip)
    Game.Tooltip.RegisterListener("Skill", "Teleportation_FreeFall", TeleportTooltip)
    Game.Tooltip.RegisterListener("Skill", "Teleportation_Netherswap", TeleportTooltip)
    Game.Tooltip.RegisterListener("Skill", "Shout_LX_AimedShot", AimedShotTooltip)
    Game.Tooltip.RegisterListener("Skill", "Shout_Adrenaline", AdrenalineTooltip)
    Game.Tooltip.RegisterListener("Skill", nil, ComputeTooltipHealings)
    Game.Tooltip.RegisterListener("Status", nil, DamageStatusTooltipScaleFromPower)
end

Ext.Events.SessionLoaded:Subscribe(DGM_Tooltips_Init)