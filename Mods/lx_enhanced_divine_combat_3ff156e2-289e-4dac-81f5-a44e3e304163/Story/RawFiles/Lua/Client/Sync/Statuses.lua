Ext.RegisterNetListener("VP_MultiplyStatus", function(channel, payload, user)
    local info = Ext.Json.Parse(payload)
    local character = Ext.ClientEntity.GetCharacter(info.Character)
    if not character then return end
    local status = Ext.ClientEntity.GetStatus(info.Character, info.Status) --- @type EclStatus
    if not status then
        _VWarning("Status", "Client/Sync/Statuses", info.Status, "could not be found for character", character.DisplayName, character.MyGuid, "on client side!")
        return
    end
end)
