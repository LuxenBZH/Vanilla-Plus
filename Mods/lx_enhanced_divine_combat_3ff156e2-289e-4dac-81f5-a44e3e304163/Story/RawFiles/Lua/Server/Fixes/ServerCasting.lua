Ext.RegisterNetListener("LX_VertcastingDecast", function(callback, payload, ...)
    local netID = tonumber(payload)
    PlayAnimation(Ext.Entity.GetCharacter(netID).MyGuid, "", "")
end)

--- @param char string GUID
--- @param state ActionStateType
Ext.Osiris.RegisterListener("NRD_OnActionStateEnter", 2, "before", function(char, state)
    if CharacterIsPlayer(char) == 1 and state == "PrepareSkill" then
        local pos = Ext.Entity.GetCharacter(char).WorldPos
        local items = Ext.Entity.GetItemGuidsAroundPosition(pos[1], pos[2], pos[3], Ext.ExtraData.RangeBoostedGlobalCap + 5)
        local ladders = {}
        for i, guid in pairs(items) do
            local item = Ext.Entity.GetItem(guid)
            if item.IsLadder then
                table.insert(ladders, item.NetID)
            end
        end
        Ext.Net.PostMessageToClient(char, "LX_LaddercastFixEnter", Ext.Json.Stringify(ladders))
    end
end)