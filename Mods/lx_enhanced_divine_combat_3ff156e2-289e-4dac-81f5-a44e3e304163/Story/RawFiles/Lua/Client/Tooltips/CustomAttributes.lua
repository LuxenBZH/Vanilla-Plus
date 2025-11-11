--- Minimum Vitality item tooltip
---@param item EclItem
---@param tooltip TooltipData
Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
    if item.StatsFromName and Helpers.Stats.GetEntryType(item.StatsFromName.StatsEntry) == "Potion" and item.StatsFromName.StatsEntry.VP_VitalityMinimum > 0 and Ext.UI.GetByType(Data.UIType.hotBar):GetRoot().hotbar_mc.characterHandle then
        local level = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.hotBar):GetRoot().hotbar_mc.characterHandle)).Stats.Level
        local vitalityAmount = Ext.Utils.Round(Game.Math.GetAverageLevelDamage(level)*item.StatsFromName.StatsEntry.VP_VitalityMinimum/100)  
        tooltip:AppendElement({
            Type = "ConsumableEffect",
            Label = Helpers.GetDynamicTranslationStringFromKey("Heal_ThresholdMinimum", vitalityAmount)
        })
    end
end)

--- % Vitality calculation item tooltip
---@param item EclItem
---@param tooltip TooltipData
Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
    if item.StatsFromName and Helpers.Stats.GetEntryType(item.StatsFromName.StatsEntry) == "Potion" and item.StatsFromName.StatsEntry.VP_VitalityMinimum > 0 then
        local percentage = item.StatsFromName.StatsEntry.VitalityPercentage
        local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.hotBar):GetRoot().hotbar_mc.characterHandle))
        local element = tooltip:GetElement("ConsumableEffect")
        if element then
            element.Label = element.Label.." ("..Ext.Utils.Round(character.Stats.MaxVitality*percentage/100).." "..Ext.L10N.GetTranslatedString("h90ab20e0g9be8g44d6g9261gfbcdaab16798", "HP")..")"
        end
    end
end)

--- Equipment custom bonuses
---@param item EclItem
---@param tooltip TooltipData
Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
    local stat = Ext.Stats.Get(item.StatsId)
    local statsEntry = Helpers.Stats.GetEntryType(stat)
    if statsEntry == "Armor" or statsEntry == "Weapon" or statsEntry == "Shield" then
        local customAttributes = {}
        local itemStats = {} -- avoid console warnings for undeclared custom stats for this specific stat type
        for statField,value in pairs(item.Stats) do
            itemStats[statField] = value
        end
        for customStatField, displayName in pairs(Data.Text.CustomAttributes) do
            if itemStats[customStatField] then
                customAttributes[customStatField] = (customAttributes[customStatField] or 0) + (item.Stats[customStatField] or 0)
                for i,dynamicStat in pairs(item.Stats.DynamicStats) do
                    if dynamicStat.ObjectInstanceName ~= "" then 
                        customAttributes[customStatField] = (customAttributes[customStatField] or 0) + Ext.Stats.Get(dynamicStat.ObjectInstanceName)[customStatField]
                    end
                end
            end
        end
        for customStatField, value in pairs(customAttributes) do
            if value ~= 0 then
                local element = tooltip:GetElement("AbilityBoost")
                if customStatField == "VP_Celerity" then
                    value = value / 100
                end
                tooltip:AppendElement({
                    Label = Data.Text.CustomAttributes[customStatField],
                    Type = "AbilityBoost",
                    Value = value
                })
            end
        end
    end
end)

--- Status custom bonuses
---@param character EclCharacter
---@param status EclStatus
---@param tooltip TooltipData
Game.Tooltip.RegisterListener("Status", nil, function(character, status, tooltip)
    if status.StatsId and status.StatsId ~= "" then
        local potion = Ext.Stats.Get(status.StatsId, nil, false)
        for customStatField, displayName in pairs(Data.Text.CustomAttributes) do
            if potion[customStatField] and potion[customStatField] ~= 0 and status.StatsMultiplier ~= 0 then
                local signInfo = Helpers.UI.GetTooltipNumberSign(tonumber(potion[customStatField]))
                tooltip:AppendElement(
                {
                    Label = displayName..": "..signInfo.Sign..Ext.Utils.Round(potion[customStatField]*status.StatsMultiplier),
                    Type = signInfo.Type
                }
            )
            end
        end
    end
end)