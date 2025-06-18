Ext.Events.SessionLoaded:Subscribe(function(e)
    --- Weapon Tooltips
    ---@param item CDivinityStatsItem
    ---@param tooltip TooltipData
    Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
        if tooltip == nil then return end
        if item.ItemSlot ~= "Weapon" then return end
        local requirements = tooltip:GetElements("ItemRequirement")
        for i,el in pairs(tooltip.Data) do
            if el.Label and string.match(el.Label, string.sub(Ext.L10N.GetTranslatedString("h565537edgdec5g4483g938fg296519760088", "Scales With"), 1, -5)) ~= nil then
                tooltip:RemoveElement(el)
            end
        end
        local equipment = {
            Type = "ItemRequirement",
            Label = "",
            RequirementMet = true
        }

        if Ext.ExtraData.DGM_RangedCQBPenalty > 0 then
            if item.WeaponType == "Bow" or item.WeaponType == "Crossbow" or item.WeaponType == "Rifle" or item.WeaponType == "Wand" or item.EquipmentType == "Shield" then
                local equipment = {
                    Type = "ItemRequirement",
                    Label = "",
                    RequirementMet = true
                }
                equipment["Label"] = Helpers.GetDynamicTranslationStringFromKey("RangedWeapons_DynamicTooltip", Ext.ExtraData.DGM_RangedCQBPenalty, Ext.ExtraData.DGM_RangedCQBPenaltyRange)
                equipment["RequirementMet"] = false
                tooltip:AppendElementAfter(equipment, "ExtraProperties")
            end

            if item.WeaponType == "Crossbow" then
                local equipment = {
                    Type = "ItemRequirement",
                    Label = Helpers.GetDynamicTranslationStringFromKey("Weapon_Crossbow_MovementPenalty", -1*Ext.ExtraData.DGM_CrossbowBasePenalty/100+(-1*Ext.ExtraData.DGM_CrossbowLevelGrowthPenalty/100*item.Level)),
                    RequirementMet = false
                }
                tooltip:AppendElementAfter(equipment, "ExtraProperties")
            end
        end        
    end)

    --- Weapon and Shields level range adaptation
    ---@param item CDivinityStatsItem
    ---@param tooltip TooltipData
    Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
        if tooltip == nil then return end
        if item.ItemSlot ~= "Weapon" and item.ItemSlot ~= "Shield" then return end
        -- _P(Helpers.GetVariableTag(item.GameObject, "VP_WeaponGenerationLevel"))
        local originalLevel = Helpers.GetVariableTag(item.GameObject, "VP_WeaponGenerationLevel") or (item.GameObject.Level ~= 0 and item.GameObject.Level or item.Stats.Level)
        local levelElement = tooltip:GetElement("ItemLevel")
        levelElement.Label = levelElement.Label.." ("..tostring(item.Stats.Level)..") "..tostring(Ext.Utils.Round(originalLevel)).." -"
        levelElement.Value = Ext.Utils.Round(originalLevel + Ext.ExtraData.DGM_WeaponDefaultLevelRange)
    end)

    --- Potion damage absorption shield tooltip
    ---@param item EclItem
    ---@param tooltip TooltipData
    Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
        if item.StatsFromName and Helpers.Stats.GetEntryType(item.StatsFromName.StatsEntry) == "Potion" and item.StatsFromName.StatsEntry.VP_AbsorbShieldValue > 0 then
            local potion = item.StatsFromName.StatsEntry
            local character = Helpers.Client.GetCurrentCharacter()
            local value = character and Helpers.ScalingFunctions[potion.VP_AbsorbShieldScaling](character.Stats.Level) * (potion.VP_AbsorbShieldValue / 100) or Helpers.ScalingFunctions[potion.VP_AbsorbShieldScaling](1) * (potion.VP_AbsorbShieldValue / 100)
            tooltip:AppendElement({
                Type = "ConsumableEffect",
                Label = Helpers.GetDynamicTranslationStringFromKey("Stats_AbsorbStatus_Description", Data.Text.GetFormattedDamageText(potion.VP_AbsorbShieldType, value), potion.Duration),
                Value = ""
            })
        end
    end)    
end)

-- Ext.Events.GameStateChanged:Subscribe(function(e)
--     if e.FromState == "PrepareRunning" and e.ToState == "Running" then
--         for i,j in pairs(Ext.Entity.GetPlayerManager().ClientPlayerData) do
--             if object.IsPlayer then
--                 _P(object.IsPlayer, object.DisplayName)
--                 if object.Stats.MainWeapon then
--                     object.Stats.MainWeapon.GameObject.Level = object.Stats.MainWeapon.Level
--                     object.Stats.MainWeapon.DynamicStats[1].MinDamage = Ext.Utils.Round(Ext.Utils.Round(Game.Math.GetLevelScaledWeaponDamage(object.Stats.MainWeapon.Level))*(1-(object.Stats.MainWeapon.StatsEntry['Damage Range']/200)))
--                     object.Stats.MainWeapon.DynamicStats[1].MaxDamage = math.ceil(Ext.Utils.Round(Game.Math.GetLevelScaledWeaponDamage(object.Stats.MainWeapon.Level))*(1-(object.Stats.MainWeapon.StatsEntry['Damage Range']/200)))
--                 end
--                 if object.Stats.OffHandWeapon then
--                     object.Stats.OffHandWeapon.GameObject.Level = object.Stats.OffHandWeapon.Level
--                     object.Stats.OffHandWeapon.DynamicStats[1].MinDamage = Ext.Utils.Round(Ext.Utils.Round(Game.Math.GetLevelScaledWeaponDamage(object.Stats.OffHandWeapon.Level))*(1-(object.Stats.OffHandWeapon.StatsEntry['Damage Range']/200)))
--                     object.Stats.OffHandWeapon.DynamicStats[1].MaxDamage = math.ceil(Ext.Utils.Round(Game.Math.GetLevelScaledWeaponDamage(object.Stats.OffHandWeapon.Level))*(1-(object.Stats.OffHandWeapon.StatsEntry['Damage Range']/200)))
--                 end
--             end
--         end
--     end
-- end)