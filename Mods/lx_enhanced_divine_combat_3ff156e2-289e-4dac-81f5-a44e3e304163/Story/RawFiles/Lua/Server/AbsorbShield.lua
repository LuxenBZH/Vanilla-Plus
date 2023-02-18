Ext.Osiris.RegisterListener("NRD_OnStatusAttempt", 4, "before", function(target, statusID, statusHandle, instigator)
    local entry = Ext.Stats.Get(statusID, nil, false, nil)
    if entry.StatsId and entry.StatsId ~= "" then
        local potion = Ext.Stats.Get(entry.StatsId)
        
    end
end)