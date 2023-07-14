--- @param e table
--- @param tooltip TooltipData
--- @param character EclCharacter
--- @param status EclStatus
local function OnStatusTooltip(e, tooltip, character, status)
    if status and type(status) ~= "number" and status.StatsId and status.StatsId ~= "" and Ext.Stats.Get(status.StatsId, nil, false) then
        local potion = Ext.Stats.Get(status.StatsId)
        if potion.VP_WisdomBoost ~= 0 then
            local bonusType = potion.VP_WisdomBoost > 0 and "StatusBonus" or "StatusMalus"
            local sign = potion.VP_WisdomBoost > 0 and "+" or ""
            tooltip:AppendElement(
                {
                    Label = "Wisdom: "..sign..potion.VP_WisdomBoost,
                    Type = bonusType
                }
            )
        end     
    end
end

Ext.Events.SessionLoaded:Subscribe(function(e)
    Game.Tooltip.RegisterListener(OnStatusTooltip)
end)