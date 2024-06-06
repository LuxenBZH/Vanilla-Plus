if not PersistentVars.SkillGroupSavedBars then
    PersistentVars.SkillGroupSavedBars = {}
end

Ext.RegisterNetListener("LX_SkillGroupsTrigger", function(channel, payload)
    local info = Ext.Json.Parse(payload)
    local character = Ext.ServerEntity.GetCharacter(tonumber(info.Character))
    PersistentVars.SkillGroupSavedBars[character.MyGuid] = {}
    for i,j in pairs(character.PlayerData.SkillBar) do
        if j.Type ~= "None" then
            if j.Type == "Item" then
                PersistentVars.SkillGroupSavedBars[character.MyGuid][i] = {ItemHandle = Ext.ServerEntity.GetItem(j.ItemHandle).MyGuid, SkillOrStatId = j.SkillOrStatId, Type = tostring(j.Type)}
            else
                PersistentVars.SkillGroupSavedBars[character.MyGuid][i] = {SkillOrStatId = j.SkillOrStatId, Type = tostring(j.Type)}
            end
        end
    end
    -- PersistentVars.SkillGroupSavedBars[character.MyGuid] = character.PlayerData.SkillBar --Needs manual parsing
    NRD_SkillBarSetSkill(character.MyGuid, 0, "Target_LX_CancelGroupSkill")
    local slot = 1 --Leave the first slot to cancel button
    for skill,isAvailable in pairs(info.Skills) do
        if isAvailable then
            NRD_SkillBarSetSkill(character.MyGuid, slot, skill)
            slot = slot + 1
        end
    end

    while slot < 29 do
        NRD_SkillBarClear(character.MyGuid, slot)
        slot = slot + 1
    end
    local skills = "Target_LX_CancelGroupSkill"
    for skill,valid in pairs(info.Skills) do
        if valid then
            skills = skills..";"..skill
        end
    end
    --- Create a status that teach all skills temporarily instead of managing them manually.
    local skillStatus = CustomStatusManager:Create("LX_SkillGroup_"..Helpers.SimpleHash16(skills), {
        Potion = {},
        Status = {
            Skills = skills
        }
    })
    ApplyStatus(character.MyGuid, skillStatus.Name, -1, 1, character.MyGuid)

    Ext.Net.PostMessageToClient(character.MyGuid, "LX_HotbarIndexSetText", "")
end)

---Used for restoring the hotbar
---@param character string|number
---@param skill string
---@param skillType striub
---@param skillElement any
Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    local character = Ext.ServerEntity.GetCharacter(character)
    if character.IsPlayer then
        Ext.Net.PostMessageToClient(character.MyGuid, "LX_CharacterUsedSkill", Ext.Json.Stringify({
            Character = character.NetID,
            Skill = skill,
            SkillType = skillType,
            skillElement = skillElement
        }))
    end
end)

Ext.RegisterNetListener("LX_SkillGroupsRecover", function(_, payload)
    local info = Ext.Json.Parse(payload)
    local character = Ext.ServerEntity.GetCharacter(tonumber(info.Character))
    local skillStatus = nil
    for i,status in pairs(character:GetStatuses()) do
        if string.starts(status, "LX_SkillGroup") then
            RemoveStatus(character.MyGuid, status)
        end
    end
    if PersistentVars.SkillGroupSavedBars[character.MyGuid] then
        local slot = 0
        while slot < 30 do
            NRD_SkillBarClear(character.MyGuid, slot)
            if PersistentVars.SkillGroupSavedBars[character.MyGuid][slot] then
                if PersistentVars.SkillGroupSavedBars[character.MyGuid][slot].Type == "Skill" then
                    NRD_SkillBarSetSkill(character.MyGuid, slot-1, PersistentVars.SkillGroupSavedBars[character.MyGuid][slot].SkillOrStatId)
                else
                    NRD_SkillBarSetItem(character.MyGuid, slot-1, PersistentVars.SkillGroupSavedBars[character.MyGuid][slot].ItemHandle)
                end
            end
            slot = slot + 1
        end
    end
end)