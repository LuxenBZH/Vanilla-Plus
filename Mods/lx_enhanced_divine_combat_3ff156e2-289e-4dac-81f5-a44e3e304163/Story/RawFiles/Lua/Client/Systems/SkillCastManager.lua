Ext.RegisterNetListener("SkillMutationTest", function(call, message)
    Ext.Print("Received mutation message...")
    local ui = Ext.GetBuiltinUI("Public/Game/GUI/hotBar.swf")
    ui:ExternalInterfaceCall("SlotPressed", 100  , true);
    Ext.PostMessageToServer("SkillMutationBounce", message)
end)

local function slotpress(ui, call, slot, bool)
    Ext.Print("slot pressed", call, slot, bool)
    ui:GetRoot().hotbar_mc.setSlotEnabled(tonumber(slot), false)
    if slot == 0.0 then
        Ext.Print("test")
        ui:ExternalInterfaceCall("SlotPressed", 2, true);
        slot = 2
    end
end

local function SetupHotbar()
    local charSheet = Ext.GetBuiltinUI("Public/Game/GUI/hotBar.swf")
    -- Ext.RegisterUIInvokeListener(charSheet, "updateArraySystem", changeDamageValue)
    -- Overhaul bonus refresh on buttons click
    Ext.RegisterUICall(charSheet, "SlotPressed", slotpress)
    -- Ext.RegisterUIInvokeListener(charSheet, "onClick", slotpress)
    -- Ext.RegisterUIInvokeListener(tooltip, "addFormattedTooltip", test)
    -- Ext.RegisterUINameCall("onChangeParam", itemSheetButtonPressed)
end

Ext.RegisterListener("SessionLoaded", SetupHotbar)