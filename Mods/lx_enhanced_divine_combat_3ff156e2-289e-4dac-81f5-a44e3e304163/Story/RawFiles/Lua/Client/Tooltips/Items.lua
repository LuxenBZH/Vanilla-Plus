Ext.Events.SessionLoaded:Subscribe(function(e)
    --- Weapon Tooltips
    ---@param item CDivinityStatsItem
    ---@param tooltip TooltipData
    Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
        if tooltip == nil then return end
        if item.ItemType ~= "Weapon" then return end
        local requirements = tooltip:GetElements("ItemRequirement")
        for i,el in pairs(tooltip.Data) do
            if el.Label and string.match(el.Label, "Scales With") ~= nil then
                tooltip:RemoveElement(el)
            end
        end
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
            equipment["Label"] = GetDynamicTranslationString("WpnWand", Ext.ExtraData.DGM_WandSkillMultiplier, Ext.ExtraData.DGM_WandSurfaceBonus)
            tooltip:AppendElementAfter(equipment, "ExtraProperties")
        end
        if Ext.ExtraData.DGM_RangedCQBPenalty > 0 then
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
    end)

    --- Potion damage absorption shield tooltip
    ---@param item EclItem
    ---@param tooltip TooltipData
    Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
        if item.StatsFromName and Helpers.Stats.GetEntryType(item.StatsFromName.StatsEntry) == "Potion" and item.StatsFromName.StatsEntry.VP_AbsorbShieldValue > 0 then
            local potion = item.StatsFromName.StatsEntry
            local character = Helpers.Client.GetCurrentCharacter()
            local value = Helpers.ScalingFunctions[potion.VP_AbsorbShieldScaling](character.Stats.Level) * (potion.VP_AbsorbShieldValue / 100)
            tooltip:AppendElement({
                Type = "ConsumableEffect",
                Label = "Absorb "..Data.Text.GetFormattedDamageText(potion.VP_AbsorbShieldType, value).." for "..potion.Duration.." turns."
            })
        end
    end)
end)