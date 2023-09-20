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