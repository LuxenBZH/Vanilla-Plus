SkillGroupManager.IsInAGroup = false
SkillGroupManager.CurrentCharacter = nil
SkillGroupManager.SavedBarIndex = 1

--- Store the player shortcuts while they are using a group
if not PersistentVars.SkillGroupSlotsBuffer then
    PersistentVars.SkillGroupSlotsBuffer = {}
end

function SkillGroupManager:GetHotbarSlotLength()
    local hotbar_ui = Ext.UI.GetByType(40)
    local root = hotbar_ui:GetRoot()
    local resolution = hotbar_ui.FlashSize
    local design_resolution = {x = root.designResolution.x, y = root.designResolution.y}
    local available_length = math.floor(resolution[1] / resolution[2] * (design_resolution.y / root.uiScaling))
    local number_of_slots = 0
    if available_length < design_resolution.x then
        if available_length > root.baseBarWidth then
            number_of_slots = math.floor((available_length - root.baseBarWidth) / root.visualSlotWidth)
        end
    else
        number_of_slots = root.maxSlots
    end
    return number_of_slots
end

function SkillGroupManager:GetSlotNumber(barSlotNumber)
    local slots_per_bar = self:GetHotbarSlotLength()
    return (Ext.UI.GetByType(40):GetRoot().hotbar_mc.cycleHotBar_mc.currentHotBarIndex-1) * slots_per_bar + barSlotNumber
end


Ext.Events.UICall:Subscribe(function(ev)
    if ev.UI:GetTypeId() == Ext.UI.TypeID.hotBar and (ev.Function == "SlotPressed" or ev.Function == "slotPressed") and ev.When == "Before" then
        local root = ev.UI:GetRoot()
        local hotbarSlot = Helpers.Client.GetCurrentCharacter().PlayerData.SkillBarItems[SkillGroupManager:GetSlotNumber(ev.Args[1]+1)]
        local skillGroup = SkillGroupManager:SearchGroups(hotbarSlot.SkillOrStatId)
        local cancel = hotbarSlot.SkillOrStatId == "Target_LX_CancelGroupSkill"
        if cancel then
            Ext.Net.PostMessageToServer("LX_SkillGroupsRecover", Ext.Json.Stringify({
                Character = tostring(Helpers.Client.GetCurrentCharacter().NetID),
            }))
            SkillGroupManager.IsInAGroup = false
            SkillGroupManager.CurrentCharacter = nil
            return
        end

        if not SkillGroupManager.IsInAGroup and skillGroup then
            ev:PreventAction()
            ev:StopPropagation()
            local currentHotbar = root.hotbar_mc.cycleHotBar_mc.currentHotBarIndex
            SkillGroupManager.SavedBarIndex = currentHotbar
            while currentHotbar > 1 do
                Ext.UI.GetByType(40):ExternalInterfaceCall("prevHotbar")
                currentHotbar = currentHotbar - 1
            end
            Ext.UI.GetByType(40):GetRoot().hotbar_mc.cycleHotBar_mc.text_txt.htmlText = "+"
            local skills = {}
            for i, child in ipairs(skillGroup.Children) do
                --- A skill can show in the toolbar even if conditions are not met.
                isMemorized, isVisible = child.Condition(Helpers.Client.GetCurrentCharacter())
                skills[child.SkillName] = {Memorized = isMemorized, Visible = isVisible}
            end
            Ext.Net.PostMessageToServer("LX_SkillGroupsTrigger", Ext.Json.Stringify({
                Character = tostring(Helpers.Client.GetCurrentCharacter().NetID),
                Parent = hotbarSlot.SkillOrStatId,
                Skills = skills
            }))
            SkillGroupManager.IsInAGroup = skillGroup
            SkillGroupManager.CurrentCharacter = Helpers.Client.GetCurrentCharacter().NetID
        end
        -- Get the skill directly from the EclCharacter skillbar from the id passed in parameter of this call
        -- Switch to the first hotbar tab
        -- Store the 29 first skills from the hotbar and use NRD_SkillBarSetSkill on server side to replace the hotbar skills
        -- Stealth memorize skills that aren't memorized
        -- When cast or if canceled, use again NRD_SkillBarSetSkill on server side to restore the previous icons
        -- Remove skills that were not memorized
        -- How to change the hotbar from lua: Ext.GetUIByType(40):ExternalInterfaceCall("nextHotbar")
        -- Cancel events: character change, unpossess, cancel prompt, successful skill cast
    elseif SkillGroupManager.IsInAGroup and (ev.Function == "prevHotbar" or ev.Function == "nextHotbar") and ev.When == "Before" then
        ev:PreventAction()
        ev:StopPropagation()
        ev.UI:GetRoot().hotbar_mc.cycleHotBar_mc.currentHotBarIndex = 1
        ev.UI:GetRoot().hotbar_mc.cycleHotBar_mc.text_txt.htmlText = "+"
    elseif (ev.Function == "showNewSkill" or ev.Function == "ShowNewSkill") and ev.When == "Before" then
    elseif ev.Function == "BackToGMPressed" and SkillGroupManager.IsInAGroup then
        Ext.Net.PostMessageToServer("LX_SkillGroupsRecover", Ext.Json.Stringify({
            Character = tostring(SkillGroupManager.CurrentCharacter),
        }))
        SkillGroupManager.IsInAGroup = false
        SkillGroupManager.CurrentCharacter = nil
    end
end, {Priority = 9500})

Ext.Events.UIInvoke:Subscribe(function(ev)
    if SkillGroupManager.IsInAGroup and ev.UI == Ext.UI.GetByType(36) and ev.Function == "showNewSkill" then
        Helpers.Timer.Start(500, function()
            Ext.UI.GetByType(36):ExternalInterfaceCall("notificationDone")
        end)
        ev:PreventAction()
        ev:StopPropagation()
    end
end)

Ext.RegisterNetListener("LX_HotbarIndexSetText", function(channel, payload)
    Ext.UI.GetByType(40):GetRoot().hotbar_mc.cycleHotBar_mc.text_txt.htmlText = "+"
end)

Ext.RegisterNetListener("LX_CharacterUsedSkill", function(_, payload)
    local info = Ext.Json.Parse(payload)
    if SkillGroupManager.IsInAGroup and SkillGroupManager.IsInAGroup.Children[info.Skill] then
        SkillGroupManager.IsInAGroup = false
        SkillGroupManager.CurrentCharacter = nil
        Ext.Net.PostMessageToServer("LX_SkillGroupsRecover", payload)
    end
end)

---@param e EsvLuaGameStateChangedEvent
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.ToState == "SwapLevel" then
        SkillGroupManager.IsInAGroup = false
        SkillGroupManager.CurrentCharacter = nil
    end
end)