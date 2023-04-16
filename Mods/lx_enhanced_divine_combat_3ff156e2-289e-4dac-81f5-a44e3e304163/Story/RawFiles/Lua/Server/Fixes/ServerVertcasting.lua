Ext.RegisterNetListener("LX_VertcastingDecast", function(callback, payload, ...)
    local netID = tonumber(payload)
    PlayAnimation(Ext.Entity.GetCharacter(netID).MyGuid, "", "")
end)