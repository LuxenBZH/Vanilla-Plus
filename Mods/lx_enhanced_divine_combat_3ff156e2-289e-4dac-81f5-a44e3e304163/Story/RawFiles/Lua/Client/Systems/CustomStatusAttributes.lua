--- @param e table
--- @param tooltip TooltipData
--- @param character EclCharacter
--- @param status EclStatus
local function OnStatusTooltip(e, tooltip, character, status)
    local b,err = xpcall(function() return status.StatsId end, debug.traceback)
    if not b then return end
    if status and type(status) ~= "number" and status.StatsId and status.StatsId ~= "" and Ext.Stats.Get(status.StatsId, nil, false) then
        local potion = Ext.Stats.Get(status.StatsId, nil, false)
        if potion.VP_WisdomBoost ~= 0 then
            local signInfo = Helpers.UI.GetTooltipNumberSign(tonumber(potion.VP_WisdomBoost))
            tooltip:AppendElement(
                {
                    Label = "Wisdom: "..signInfo.Sign..potion.VP_WisdomBoost,
                    Type = signInfo.Type
                }
            )
        end
        if potion.VP_Celerity ~= 0 then
            local signInfo = Helpers.UI.GetTooltipNumberSign(tonumber(potion.VP_Celerity))
            tooltip:AppendElement(
                {
                    Label = "Celerity: "..signInfo.Sign..potion.VP_Celerity,
                    Type = signInfo.Type
                }
            )
        end
        if potion.VP_IngressBoost ~= 0 then
            local signInfo = Helpers.UI.GetTooltipNumberSign(tonumber(potion.VP_IngressBoost))
            tooltip:AppendElement(
                {
                    Label = "Ingress: "..signInfo.Sign..potion.VP_IngressBoost,
                    Type = signInfo.Type
                }
            )
        end
    end
end

Ext.Events.SessionLoaded:Subscribe(function(e)
    Game.Tooltip.RegisterListener(OnStatusTooltip)
end)