Ext.RegisterNetListener("VP_ResetWeaponCriticalMultiplier", function(channel, payload, user)
    local item = Ext.ClientEntity.GetItem(tonumber(payload))
    item.Stats.DynamicStats[1].CriticalDamage = item.Stats.StatsEntry.CriticalDamage
end)

Ext.RegisterNetListener("VP_UpdateWeaponLevelRange", function(channel, payload, user)
    local info = Ext.Json.Parse(payload)
    local item = Ext.ClientEntity.GetItem(info.NetID)
    item.Stats.Level = info.Level
    item.Stats.DynamicStats[1].MinDamage = info.MinDamage
    item.Stats.DynamicStats[1].MaxDamage = info.MaxDamage
end)