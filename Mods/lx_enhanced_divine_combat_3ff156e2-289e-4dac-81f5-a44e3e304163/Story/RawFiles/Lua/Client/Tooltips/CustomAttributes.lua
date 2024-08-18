--- Minimum Vitality item tooltip
---@param item EclItem
---@param tooltip TooltipData
Game.Tooltip.RegisterListener("Item", nil, function(item, tooltip)
    if item.StatsFromName and Helpers.Stats.GetEntryType(item.StatsFromName.StatsEntry) == "Potion" and item.StatsFromName.StatsEntry.VP_VitalityMinimum > 0 and Ext.UI.GetByType(Data.UIType.hotBar):GetRoot().hotbar_mc.characterHandle then
        local level = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.hotBar):GetRoot().hotbar_mc.characterHandle)).Stats.Level
        local vitalityAmount = Ext.Utils.Round(Game.Math.GetAverageLevelDamage(level)*item.StatsFromName.StatsEntry.VP_VitalityMinimum/100)  
        tooltip:AppendElement({
            Type = "ConsumableEffect",
            Label = "Heals for a minimum of "..tostring(vitalityAmount).." Vitality."
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
            element.Label = element.Label.." ("..Ext.Utils.Round(character.Stats.MaxVitality*percentage/100).." HP)"
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
        local wisdom = item.Stats.VP_WisdomBoost
        for i, dynamicStat in pairs(item.Stats.DynamicStats) do
            if dynamicStat.ObjectInstanceName ~= "" then
                wisdom = wisdom + Ext.Stats.Get(dynamicStat.ObjectInstanceName).VP_WisdomBoost
            end
        end
        local celerity = item.Stats.VP_Celerity
        for i, dynamicStat in pairs(item.Stats.DynamicStats) do
            if dynamicStat.ObjectInstanceName ~= "" then
                celerity = celerity + Ext.Stats.Get(dynamicStat.ObjectInstanceName).VP_Celerity
            end
        end
        if wisdom ~= 0 then
            local element = tooltip:GetElement("AbilityBoost")
            tooltip:AppendElement({
                Label = "Wisdom",
                Type = "AbilityBoost",
                Value = wisdom
            })
        end
        if celerity ~= 0 then
            celerity = celerity / 100
            local element = tooltip:GetElement("AbilityBoost")
            tooltip:AppendElement({
                Label = "Celerity",
                Type = "AbilityBoost",
                Value = celerity
            })
        end
    end
end)