local isOpened = false
local lastObjectHandle = nil

--- Inspired from LaughingLeader's code
Ext.RegisterUINameCall("openContextMenu", function (ui, call, doubleHandle, x, y)
    if ui.Type == Data.UIType.characterSheet then
	    lastObjectHandle = doubleHandle
    else
        lastObjectHandle = nil
    end
end, "Before")

---@param e EclLuaUICallEvent
Ext.Events.UIInvoke:Subscribe(function(e)
    --TODO: get the entity below the cursor to know what it is
    -- GetPickingState won't return any HoverEntity if it's a character sheet or inventory item
    -- _P(e.Function)
    if (e.UI.Type == Data.UIType.contextMenu.Default or e.UI.Type == Data.UIType.contextMenu.Object) and e.When == "Before" and e.Function == "open" and not isOpened then
        if lastObjectHandle then
            local object = Ext.ClientEntity.GetGameObject(Ext.UI.DoubleToHandle(lastObjectHandle))
            if Helpers.IsItem(object) and object.Stats.WeaponType ~= "Sentinel" then
                local character = Helpers.Client.GetCurrentCharacter()
                if character.Stats.TALENT_Ambidextrous then
                    e.UI:GetRoot().windowsMenu_mc.addEntry(20, 50, true, "Ambidextrous: Save Preset 1", false, true)
                    e.UI:GetRoot().windowsMenu_mc.addEntry(21, 51, true, "Ambidextrous: Save Preset 2", false, true)
                    e.UI:GetRoot().windowsMenu_mc.updateDone()
                end
            end
        end
        isOpened = true
    elseif (e.UI.Type == Data.UIType.contextMenu.Default or e.UI.Type == Data.UIType.contextMenu.Object) and e.When == "After" and e.Function == "close" then
        isOpened = false
    end
    
end)

Ext.Events.UICall:Subscribe(function(e)
    if e.UI.Type == Data.UIType.contextMenu.Object and e.Function == "buttonPressed" then
        if (e.Args[2] == "50" or e.Args[2] == "51") and lastObjectHandle then
            local character = Helpers.Client.GetCurrentCharacter()
            if not character.UserVars.VP_Ambidextrous then
                character.UserVars.VP_Ambidextrous = {
                    {},
                    {}
                }
            end
            local mainHand = character:GetItemBySlot("Weapon")
            local offHand = character:GetItemBySlot("Shield")
            character.UserVars.VP_Ambidextrous[tonumber(e.Args[2])-49] = {mainHand, offHand}
            Ext.Net.PostMessageToServer("VP_SetAmbidextrous", Ext.Json.Stringify({
                Character = character.NetID,
                Sets = character.UserVars.VP_Ambidextrous
            }))
        end
    end
end)

-- Ext.RegisterUITypeInvokeListener(typeId, "updateButtons", function(...) self:OnBuiltinMenuUpdating(...)
    
-- end)
