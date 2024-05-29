---@class SkillGroupManager
---@field SkillGroupList table
SkillGroupManager = {
    SkillGroupList = {},
    SharedSkillGroupList = {},
    IsInAGroup = false,
    CurrentCharacter = nil,
    SavedBarIndex = 1
}

--- Store the player shortcuts while they are using a group
if not PersistentVars.SkillGroupSlotsBuffer then
    PersistentVars.SkillGroupSlotsBuffer = {}
end

function SkillGroupManager:AddGroup(skillGroup)
    self.SkillGroupList[skillGroup.Parent] = skillGroup
end

---comment
---@param skillName string
function SkillGroupManager:RemoveGroups(skillName)
    for i,group in pairs(self.SkillGroupList) do
        if group.Parent == skillName and not shared then
            table.remove(self.SkillGroupList, i)
        end
    end
end

---comment
---@param skillName string
function SkillGroupManager:RemoveSharedGroups(skillName)
    for i,group in pairs(self.SharedSkillGroupList) do
        if group.Children[skillName] then
            table.remove(self.SharedSkillGroupList, i)
        end
    end
end

function SkillGroupManager:SearchGroups(skillName)
    return self.SkillGroupList[skillName]
end

function SkillGroupManager:SearchSharedGroups(skillName)
    local results = {}
    for i,group in pairs(self.SharedSkillGroupList) do
        if group.Children[skillName] then
            table.insert(results)
        end
    end
    return results
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


---@class SkillGroup
---@field Parent string
---@field Shared boolean if true, that means there's no parent and having at least another child from the one selected returning true enables the group
---@field Children table skillName : function. At least one child must return true for the group to activate
SkillGroup = {
    Parent = "",
    Shared = false,
    Children = {}
}

SkillGroup.__index = SkillGroup

function SkillGroup:Create(skillName, children, regroupChildren)
    local this = {
        Parent = skillName,
        RegroupFromChildren = regroupChildren or false,
        Children = children or {}
    }
    return this
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
            local currentHotbar = root.hotbar_mc.cycleHotBar_mc.currentHotBarIndex
            SkillGroupManager.SavedBarIndex = currentHotbar
            while currentHotbar > 1 do
                Ext.UI.GetByType(40):ExternalInterfaceCall("prevHotbar")
                currentHotbar = currentHotbar - 1
            end
            Ext.UI.GetByType(40):GetRoot().hotbar_mc.cycleHotBar_mc.text_txt.htmlText = "+"
            local skills = {}
            for skill, condition in pairs(skillGroup.Children) do
                skills[skill] = condition(Helpers.Client.GetCurrentCharacter())
            end
            Ext.Net.PostMessageToServer("LX_SkillGroupsTrigger", Ext.Json.Stringify({
                Character = tostring(Helpers.Client.GetCurrentCharacter().NetID),
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
        ev.UI:GetRoot().hotbar_mc.cycleHotBar_mc.currentHotBarIndex = 1
        ev.UI:GetRoot().hotbar_mc.cycleHotBar_mc.text_txt.htmlText = "+"
    elseif (ev.Function == "showNewSkill" or ev.Function == "ShowNewSkill") and ev.When == "Before" then
    end
end)

Ext.Events.UIInvoke:Subscribe(function(ev)
    if SkillGroupManager.IsInAGroup and ev.UI == Ext.UI.GetByType(36) and ev.Function == "showNewSkill" then
        ClientTimer.Start(500, function()
            Ext.UI.GetByType(36):ExternalInterfaceCall("notificationDone")
        end)
        ev:PreventAction()
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