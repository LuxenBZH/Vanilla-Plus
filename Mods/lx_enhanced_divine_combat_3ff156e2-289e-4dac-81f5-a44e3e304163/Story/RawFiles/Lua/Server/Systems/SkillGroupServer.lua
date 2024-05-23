if not PersistentVars.SkillGroupSavedBars then
    PersistentVars.SkillGroupSavedBars = {}
end

Ext.RegisterNetListener("LX_SkillGroupsTrigger", function(channel, payload)
    local info = Ext.Json.Parse(payload)
    local character = Ext.ServerEntity.GetCharacter(tonumber(info.Character))
    PersistentVars.SkillGroupSavedBars[character.MyGuid] = {}
    for i,j in pairs(character.PlayerData.SkillBar) do
        PersistentVars.SkillGroupSavedBars[character.MyGuid][i] = {ItemHandle = j.ItemHandle, SkillOrStatId = j.SkillOrStatId, Type = j.Type}
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
    if PersistentVars.SkillGroupSavedBars[character.MyGuid] then
        local slot = 0
        while slot < 29 do
            NRD_SkillBarClear(character.MyGuid, slot)
            if PersistentVars.SkillGroupSavedBars[character.MyGuid][slot] then
                if PersistentVars.SkillGroupSavedBars[character.MyGuid][slot].Type == "Skill" then
                    NRD_SkillBarSetSkill(character.MyGuid, slot-1, PersistentVars.SkillGroupSavedBars[character.MyGuid][slot].SkillOrStatId)
                else
                    NRD_SkillBarSetItem(character.MyGuid, slot-1, PersistentVars.SkillGroupSavedBars[character.MyGuid][slot].SkillOrStatId)
                end
            end
            slot = slot + 1
        end
    end
end)