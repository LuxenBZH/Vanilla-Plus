Ext.RegisterNetListener("VP_MultiplyStatus", function(channel, payload, user)
    local info = Ext.Json.Parse(payload)
    local character,err = xpcall(function() return Ext.ClientEntity.GetCharacter(info.Character) end, debug.traceback)
    if not character then return end
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
    if not character then
        _VWarning("Character with NetID", "Client/Sync/Statuses", payload, "is not properly sync on client side ! Forcing sync with CharacterForceSynch...")
        Ext.Net.PostMessageToServer("VP_ForceSyncCharacter", payload)
        return
    end
    local _,critMult = Data.Math.ComputeStatIntegerFromStatus(character, "VP_CriticalMultiplier")
    -- _VPrint("Received CritMult net message", "Client/Sync/Statuses", character, character.Stats.MainWeapon.StatsEntry.CriticalDamage, character.Stats.MainWeapon.DynamicStats[1].CriticalDamage, critMult)
    character.Stats.MainWeapon.DynamicStats[1].CriticalDamage = character.Stats.MainWeapon.StatsEntry.CriticalDamage + critMult
end)
