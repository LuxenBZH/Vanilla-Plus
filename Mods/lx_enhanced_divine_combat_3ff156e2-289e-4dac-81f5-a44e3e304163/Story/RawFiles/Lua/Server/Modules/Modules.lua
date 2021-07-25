Ext.Require("Server/Modules/FallDamage.lua")
Ext.Require("Server/Modules/GBTalents.lua")

PersistentVars = {}

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

local function CharacterHotReplaceJumps(character, x, y, z, skill, skillType, skillElement)
    if not PersistentVars.DGM_RealJump then return end
    if skillType ~= "jump" then return end
    CharacterUnlearnJumpSkill(character, skill)
    -- Cancel cast for NPCs
    if not Ext.GetCharacter(character).IsPlayer and IsElligibleJump(skill) then
        CharacterUseSkill(character, "Shout_LX_CancelCast", character, 0, 1, 1)
        CharacterAddActionPoints(character, 1)
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

function EnableFallDamage(cmd)
    if cmd == "on" then
        print("Fall damage module activated")
        PersistentVars["DGM_FallDamage"] = true
    elseif cmd == "off" then
        print("Fall damage module deactivated")
        PersistentVars["DGM_FallDamage"] = false
    end
end

function EnableJumpDamage(cmd)
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

local function ActivateModule(flag)
    if flag == "LXDGM_ModuleRealJump" then 
        ReplaceAllJumps("on")
    elseif flag == "LXDGM_ModuleFallDamageClassic" then 
        EnableFallDamage("on")
    elseif flag == "LXDGM_ModuleFallDamageAlternate" then 
        EnableJumpDamage("on")
    elseif flag == "LXDGM_ModuleDualCC" then
        Ext.ExtraData.DGM_EnableDualCCParry = 1
    elseif flag == "LXDGM_ModuleDivineTalents" then
        Ext.ExtraData.DGM_GB4Talents = 1
    end
end
Ext.RegisterOsirisListener("GlobalFlagSet", 1, "after", ActivateModule)

local function DeactivateModule(flag)
    if flag == "LXDGM_ModuleRealJump" then 
        ReplaceAllJumps("off")
    elseif flag == "LXDGM_ModuleFallDamageClassic" then 
        EnableFallDamage("off")
    elseif flag == "LXDGM_ModuleFallDamageAlternate" then 
        EnableJumpDamage("off")
    elseif flag == "LXDGM_ModuleDualCC" then
        Ext.ExtraData.DGM_EnableDualCCParry = 0
    elseif flag == "LXDGM_ModuleDivineTalents" then
        Ext.ExtraData.DGM_GB4Talents = 0
    end
end
Ext.RegisterOsirisListener("GlobalFlagCleared", 1, "after", DeactivateModule)

Ext.RegisterConsoleCommand("DGM_Module_RealJump", DGM_Modules_consoleCmd)
Ext.RegisterConsoleCommand("DGM_Module_FallDamage", DGM_Modules_consoleCmd)
Ext.RegisterOsirisListener("CharacterLearnedSkill", 2, "before", CharacterUnlearnJumpSkill)
Ext.RegisterOsirisListener("GameStarted", 2, "after", GameStartJumpModule)
