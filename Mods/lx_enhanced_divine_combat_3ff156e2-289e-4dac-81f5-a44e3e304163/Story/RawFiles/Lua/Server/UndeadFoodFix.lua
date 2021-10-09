---- Full credit to LaughingLeader

local lastPotion = {}

Ext.RegisterOsirisListener("CanUseItem", 3, "after", function(targetId, itemId, request)
    local item = Ext.GetItem(itemId)
    if item and NRD_StatGetType(item.StatsId) == "Potion" then
        lastPotion[GetUUID(targetId)] = item.StatsId
    end
end)

Ext.RegisterOsirisListener("NRD_OnStatusAttempt", 4, "after", function(targetId, statusId, handle, source)
    if statusId == "CONSUME" then
        local target = Ext.GetGameObject(targetId)
        local statsId = lastPotion[target.MyGuid]
        if statsId then
            local duration = Ext.StatGetAttribute(statsId, "Duration") or 0
            if duration > 0 and (target:HasTag("UNDEAD") or target.Stats.TALENT_Zombie) then
                local status = Ext.GetStatus(target.MyGuid, handle)
                if status.LifeTime == 0 then
                    duration = math.ceil(duration * 6)
                    status.LifeTime = duration
                    status.CurrentLifeTime = duration
                end
            end
            lastPotion[target.MyGuid] = nil
        end
    end
end)