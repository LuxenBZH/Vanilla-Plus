Ext.RegisterNetListener("VP_MultiplyStatus", function(channel, payload, user)
    local info = Ext.Json.Parse(payload)
    local character = Ext.ClientEntity.GetCharacter(info.Character)
    local status = Ext.ClientEntity.GetStatus(character, info.Status)
    status.StatsMultiplier = info.Multiplier
    --- Crit Multiplier particularity
    local statEntry = Ext.Stats.Get(status.StatusId)
    if statEntry.StatsId ~= "" then
        local potionEntry = Ext.Stats.Get(statEntry.StatsId)
        if potionEntry.VP_CriticalMultiplier ~= 0 then
            local _,critMult = Data.Math.ComputeStatIntegerFromStatus(character, "VP_CriticalMultiplier")
            character.Stats.MainWeapon.DynamicStats[1].CriticalDamage = character.Stats.MainWeapon.StatsEntry.CriticalDamage + critMult
        end
    end
end)

Ext.RegisterNetListener("VP_RecalculateStatusCritMultBonus", function(channel, payload, user)
    local character = Ext.ClientEntity.GetCharacter(tonumber(payload))
    local _,critMult = Data.Math.ComputeStatIntegerFromStatus(character, "VP_CriticalMultiplier")
    character.Stats.MainWeapon.DynamicStats[1].CriticalDamage = character.Stats.MainWeapon.StatsEntry.CriticalDamage + critMult
end)
