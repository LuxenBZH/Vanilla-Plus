PersistentVars = {}

------ Real Jumps module -------
function JumpProjectile(projectile, hitObject, position)
    local skill = projectile.SkillId:gsub("%_%-1", "")
    --Ext.Print(skill)
    if skill == "Projectile_TacticalRetreat" or skill == "Projectile_CloakAndDagger" or skill == "Projectile_PhoenixDive" then
        local char = Ext.GetCharacter(projectile.CasterHandle)
        PlayAnimation(char.MyGuid, "skill_jump_flight_land")
    end
end

--Ext.RegisterListener("ProjectileHit", JumpProjectile)

local function ReplaceAllJumps(toggle)
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
    elseif PersistentVars["DGM_RealJump"] == true then
        ReplaceAllJumps("off")
    end
end


local function CharacterReplaceJumpSkills(character, eventName)
    if eventName == "DGM_CharacterReplaceJumpSkills" then
        local character = Ext.GetCharacter(character)
        if character == nil then return end
        --print(character)
        local skills = character.GetSkills(character)
        for i,skill in pairs(skills) do
            if skill == "Jump_TacticalRetreat" or skill == "Jump_CloakAndDagger" or skill == "Jump_PhoenixDive" then
                --print(skill)
                CharacterRemoveSkill(character.MyGuid, skill)
                local newJump = string.gsub(skill, "Jump", "Projectile")
                --print(newJump)
                CharacterAddSkill(character.MyGuid, newJump)
            end
        end
    end

    if eventName == "DGM_CharacterReplaceJumpSkillsRevert" then
        local character = Ext.GetCharacter(character)
        --print(character)
        local skills = character.GetSkills(character)
        for i,skill in pairs(skills) do
            if skill == "Projectile_TacticalRetreat" or skill == "Projectile_CloakAndDagger" or skill == "Projectile_PhoenixDive" then
                --print(skill)
                CharacterRemoveSkill(character.MyGuid, skill)
                local newJump = string.gsub(skill, "Projectile", "Jump")
                --print(newJump)
                CharacterAddSkill(character.MyGuid, newJump)
            end
        end
    end
end

local function CharacterUnlearnJumpSkill(character, skill)
    if skill == "Jump_TacticalRetreat" or skill == "Jump_CloakAndDagger" or skill == "Jump_PhoenixDive" then
        --print("Jump learned")
        local character = Ext.GetCharacter(character)
        if character == nil then return end
        CharacterRemoveSkill(character.MyGuid, skill)
        local newJump = string.gsub(skill, "Jump", "Projectile")
        --print(newJump)
        CharacterAddSkill(character.MyGuid, newJump)
    end
end

local function EnableFallDamage(cmd)
    if cmd == "on" then
        print("Fall damage module activated")
        PersistentVars["DGM_FallDamage"] = true
    elseif cmd == "off" then
        print("Fall damage module deactivated")
        PersistentVars["DGM_FallDamage"] = false
    end
end

local function EnableJumpDamage(cmd)
    if cmd == "on" then
        print("Jump fall damage module activated")
        PersistentVars["DGM_FallDamage_Jump"] = true
    elseif cmd == "off" then
        print("Jump fall damage module deactivated")
        PersistentVars["DGM_FallDamage_Jump"] = false
    end
end

local function DGM_Modules_consoleCmd(cmd, ...)
	local params = {...}
	for i=1,10,1 do
		local par = params[i]
		if par == nil then break end
		if type(par) == "string" then
			par = par:gsub("&", " ")
			par = par:gsub("\\ ", "&")
			params[i] = par
		end
	end
    if cmd == "DGM_Module_RealJump" then ReplaceAllJumps(params[1]) end
    if cmd == "DGM_Module_FallDamage" then EnableFallDamage(params[1]) end
    if cmd == "DGM_Module_FallDamage_Jump" then EnableJumpDamage(params[1]) end
end

Ext.RegisterConsoleCommand("DGM_Module_RealJump", DGM_Modules_consoleCmd)
Ext.RegisterConsoleCommand("DGM_Module_FallDamage", DGM_Modules_consoleCmd)
Ext.RegisterOsirisListener("StoryEvent", 2, "before", CharacterReplaceJumpSkills)
Ext.RegisterOsirisListener("CharacterLearnedSkill", 2, "before", CharacterUnlearnJumpSkill)
Ext.RegisterOsirisListener("GameStarted", 2, "after", GameStartJumpModule)