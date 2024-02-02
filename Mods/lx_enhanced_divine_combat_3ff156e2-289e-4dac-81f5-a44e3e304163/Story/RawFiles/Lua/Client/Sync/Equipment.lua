Ext.RegisterNetListener("VP_ResetWeaponCriticalMultiplier", function(channel, payload, user)
    local item = Ext.ClientEntity.GetItem(tonumber(payload))
    item.Stats.DynamicStats[1].CriticalDamage = item.Stats.StatsEntry.CriticalDamage
end)