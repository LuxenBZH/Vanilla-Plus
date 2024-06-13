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
    for skill,valid in pairs(info.Skills) do
        if valid.Visible then
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
        if valid.Memorized then
            skills = skills..";"..skill
        end
    end
    --- Create a status that teach all skills temporarily instead of managing them manually.
    local skillStatus = CustomStatusManager:Create("LX_SkillGroup_"..info.Parent.."_"..Helpers.SimpleHash16(skills), {
        Potion = {},
        Status = {
            Skills = skills
        }
    })
    ApplyStatus(character.MyGuid, skillStatus.Name, -1, 1, character.MyGuid)

    Ext.Net.PostMessageToClient(character.MyGuid, "LX_HotbarIndexSetText", "")
end)


---@param character string|number
---@param skill string
---@param skillType striub
---@param skillElement any
Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    local character = Ext.ServerEntity.GetCharacter(character)
    local inSkillGroup = Helpers.Character.GetStatus(character, "LX_SkillGroup_")
    if character.IsPlayer and inSkillGroup then
        local skillGroup = SkillGroupManager:FindGroupFromStatus(inSkillGroup)
        if skillGroup then
            if skillGroup.ShareCooldowns then
                local stat = Ext.Stats.Get(skill) ---@type StatEntrySkillData
                local cooldown = stat.Cooldown * 6.0
                for i,skillGroupChild in pairs(skillGroup.Children) do
                    Helpers.Character.SetSkillCooldown(character, skillGroupChild.SkillName, cooldown, false)
                end
                Helpers.Character.SetSkillCooldown(character, skillGroup.Parent, cooldown)
            end
        end
    end
    Ext.Net.PostMessageToClient(character.MyGuid, "LX_CharacterUsedSkill", Ext.Json.Stringify({
        Character = character.NetID,
        Skill = skill,
        SkillType = skillType,
        skillElement = skillElement
    }))
end)

---Restores the hotbar shortcuts to its original state
---@param _ string
---@param payload string
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
        while slot < 145 do
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
        PersistentVars.SkillGroupSavedBars[character.MyGuid] = nil
    else
        _VWarning("Tried to restore the skillbar of "..character.MyGuid.." but it was not saved !")
    end
end)

---@param e EsvLuaGameStateChangedEvent
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "Sync" and e.ToState == "Running" then
        local characters = Ext.ServerEntity.GetAllCharacterGuids()
        for i,guid in pairs(characters) do
            local character = Ext.ServerEntity.GetCharacter(guid)
            if character.PlayerData then
                local status = Helpers.Character.GetStatus(character, "LX_SkillGroup_")
                if status then
                    Ext.Net.PostMessageToServer("LX_SkillGroupsRecover", Ext.Json.Stringify({
                        Character = character.NetID
                    }))
                end
            end
        end
    end
end)

--- Remove the character data from vars to avoid bloating if it is deleted from the game
---@param character string
---@param event string
Ext.Osiris.RegisterListener("StoryEvent", 2, "before", function(character, event)
    -- Remove stuff only on Running, since shutdowns happening outside of it can be due to map switch or something else
    if event == "CharacterShutdown" and Ext.ServerServer.GetGameState() == "Running" then
        -- _VPrint("CharacterShutdown "..character.." "..tostring(Ext.GetGameState()), "SkillGroupServer")
        local GUID = Helpers.GetCharacterCleanGUID(character)
        if PersistentVars.SkillGroupSavedBars[GUID] then
            PersistentVars.SkillGroupSavedBars[GUID] = nil
        end
    end

end)