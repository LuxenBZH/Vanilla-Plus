

SkillMutations = {}

RegisterSkillListener({"Projectile_Fireball"}, function(skill, char, state, data)
    if state == SKILL_STATE.PREPARE then
        local character = Ext.GetCharacter(char)
        if character.IsPlayer or character.IsPossessed then
            GameHelpers.ClearActionQueue(char, true)
            CharacterAddSkill(char, "Target_Haste", 0)
            local slot = NRD_SkillBarFindSkill(char, "Target_Haste")
            if slot then
                NRD_SkillBarClear(char, slot)
            end
            NRD_SkillBarSetSkill(char, 100, "Target_Haste")
            SkillMutations[char] = skill
            Timer.Start("SkillMutation", 0, char)
        end
    end
end)

Timer.RegisterListener("SkillMutation", function(_, char)
    Ext.Print("Sending mutation to client...")
	Ext.PostMessageToClient(char.MyGuid, "SkillMutationTest", Ext.JsonStringify({char.MyGuid, SkillMutations[char.MyGuid]}))
    SkillMutations[char] = nil
end, true)

Ext.RegisterNetListener("SkillMutationBounce", function(call, message)
    local message = Ext.JsonParse(message)
    NRD_SkillBarClear(message[1], 100)
end)

RegisterSkillListener({"Target_Haste"}, function(skill, char, state, data)
    if state == SKILL_STATE.CAST then
        Timer.Start("SkillMutationRemove", 1000, char)
    elseif state == SKILL_STATE.CANCEL then
        CharacterRemoveSkill(char, "Target_Haste")
    end
end)

Timer.RegisterListener("SkillMutationRemove", function(_, char)
    Ext.Print("HIT")
    CharacterRemoveSkill(char.MyGuid, "Target_Haste")
end, true)
-------- END Power Hit