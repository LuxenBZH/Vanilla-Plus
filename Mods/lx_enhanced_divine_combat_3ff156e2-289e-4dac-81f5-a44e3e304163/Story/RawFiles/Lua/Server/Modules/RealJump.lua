------ Real Jumps module -------
function ReplaceAllJumps(toggle)
    if toggle == "on" then
        print("RealJump module activated")
        PersistentVars["DGM_RealJump"] = true
        CharacterLaunchOsirisOnlyIterator("DGM_CharacterReplaceJumpSkills")
    else
        print("RealJump module deactivated")
        PersistentVars["DGM_RealJump"] = false
        CharacterLaunchOsirisOnlyIterator("DGM_CharacterReplaceJumpSkillsRevert")
    end
end

local function GameStartJumpModule(arg1, arg2)
    if PersistentVars["DGM_RealJump"] == true then
        ReplaceAllJumps("on")
    elseif PersistentVars["DGM_RealJump"] == false then
        ReplaceAllJumps("off")
    end
end

Ext.RegisterOsirisListener("GameStarted", 2, "after", GameStartJumpModule)

local elligibleSkills = {
    "Jump_PhoenixDive",
    "Jump_EnemyPhoenixDive",
    "Jump_TacticalRetreat",
    "Jump_EnemyTacticalRetreat",
    "Jump_EnemyTacticalRetreat_Frog",
    "Jump_IncarnateJump",
    "Jump_CloakAndDagger",
    "Jump_EnemyCloakAndDagger"
}

local function IsElligibleJump(skill)
    for i,jump in pairs(elligibleSkills) do
        if skill == jump then
            return true
        end
    end
    return false
end

local function CharacterReplaceJumpSkills(character, eventName)
    if not PersistentVars.DGM_RealJump then return end
    if eventName == "DGM_CharacterReplaceJumpSkills" then
        local character = Ext.GetCharacter(character)
        if character == nil then return end
        --print(character)
        local skills = character.GetSkills(character)
        for i,skill in pairs(skills) do
            for j,jump in pairs(elligibleSkills) do
                if skill == jump then
                    CharacterRemoveSkill(character.MyGuid, skill)
                    local newJump = string.gsub(skill, "Jump_", "Projectile_")
                    CharacterAddSkill(character.MyGuid, newJump)
                end
            end
        end
    end

    if eventName == "DGM_CharacterReplaceJumpSkillsRevert" then
        local character = Ext.GetCharacter(character)
        if character == nil then return end
        local skills = character.GetSkills(character)
        for i,skill in pairs(skills) do
            for j,jump in pairs(elligibleSkills) do
                local projectileJump = string.gsub(jump, "Jump_", "Projectile_")
                if skill == projectileJump then
                    CharacterRemoveSkill(character.MyGuid, skill)
                    local newJump = string.gsub(skill, "Projectile_", "Jump_")
                    CharacterAddSkill(character.MyGuid, newJump)
                end
            end
        end
    end
end

Ext.RegisterOsirisListener("StoryEvent", 2, "before", CharacterReplaceJumpSkills)

local function CharacterUnlearnJumpSkill(character, skill)
    if not PersistentVars.DGM_RealJump then return end
    for i,jump in pairs(elligibleSkills) do
        if skill == jump then
            --print("Jump learned")
            local character = Ext.GetCharacter(character)
            if character == nil then return end
            CharacterRemoveSkill(character.MyGuid, skill)
            local newJump = string.gsub(skill, "Jump_", "Projectile_")
            --print(newJump)
            CharacterAddSkill(character.MyGuid, newJump)
        end
    end
end

Ext.RegisterOsirisListener("CharacterLearnedSkill", 2, "before", CharacterUnlearnJumpSkill)

local function CharacterHotReplaceJumps(character, x, y, z, skill, skillType, skillElement)
    if not PersistentVars.DGM_RealJump then return end
    if skillType ~= "jump" then return end
    -- Cancel cast for NPCs
    if not Ext.GetCharacter(character).IsPlayer and IsElligibleJump(skill) then
        CharacterAddActionPoints(character, Ext.GetStat(skill).ActionPoints)
        CharacterUseSkill(character, "Shout_LX_CancelCast", character, 0, 1, 1)
        CharacterUnlearnJumpSkill(character, skill)
    end
end

Ext.RegisterOsirisListener("CharacterUsedSkillAtPosition", 7, "before", CharacterHotReplaceJumps)

local function ReplaceJumpsOnTurn(char)
    if not PersistentVars.DGM_RealJump then return end
    if ObjectIsCharacter(char) ~= 1 then return end
    char = Ext.GetCharacter(char)
    for i,skill in pairs(char.GetSkills(char)) do
        CharacterUnlearnJumpSkill(char.MyGuid, skill)
    end
end

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "after", ReplaceJumpsOnTurn)