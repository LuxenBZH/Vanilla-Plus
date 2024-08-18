if not PersistentVars then
    PersistentVars = {}
end

Ext.Require("BootstrapShared.lua")
-- Ext.Require("Shared/Helpers.lua")
Helpers.VPPrint("Loaded", "BootstrapServer")


Ext.Vars.RegisterUserVariable("VP_LastSkillID", {
    Server = true,
    Client = false, 
    SyncToClient = false,
    Persistent = false,
    SyncOnWrite = false,
    SyncOnTick = false
})

Ext.Vars.RegisterUserVariable("VP_PotionVitalityMinimum", {
    Server = true,
    Client = false, 
    SyncToClient = false,
    Persistent = false,
    SyncOnWrite = false,
    SyncOnTick = false
})

Ext.Vars.RegisterUserVariable("VP_ConsecutiveHitFromSkill", {
    Server = true,
    Client = false, 
    SyncToClient = false,
    Persistent = false,
    SyncOnWrite = false,
    SyncOnTick = false
})

Ext.Vars.RegisterUserVariable("VP_ChallengeMultiplier", {
    Server = true,
    Client = false, 
    SyncToClient = false,
    Persistent = false,
    SyncOnWrite = false,
    SyncOnTick = false,
})

Ext.Vars.RegisterUserVariable("LX_StatusConsumeMultiplier", {
    Server = true,
    Client = true, 
    SyncToClient = true,
    Persistent = false,
    SyncOnWrite = true,
    SyncOnTick = false,
})

Ext.Vars.RegisterUserVariable("LX_WarmupManager", {
    Server = true,
    Client = true, 
    SyncToClient = false,
    Persistent = true,
    SyncOnWrite = true,
    SyncOnTick = false,
})

Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    -- Ext.Entity.GetCharacter(character).UserVars.VP_LastSkillID = {Name = skill, ID = math.random(0, 2147483647)}
    local character = Ext.ServerEntity.GetCharacter(character)
    local lastSkills = Helpers.UserVars.GetVar(character, "VP_LastSkillsUsed")
    if not lastSkills then
        lastSkills = {[1] = {Name = skill, ID = math.random(0, 2147483647)}}
    else
        lastSkills = table.move(lastSkills, 1, math.min(9, #lastSkills), 2, {[1] = {Name = skill, ID = math.random(0, 2147483647)}})
    end
    Helpers.UserVars.SetVar(character, "VP_LastSkillsUsed", lastSkills)
    local statEntry = Ext.Stats.Get(skill)
    if statEntry.Ability == "Ranger" and statEntry.Requirement == "RangedWeapon" then
        Helpers.UserVars.SetVar(character, "VP_HuntsmanReloadLastSkill", skill)
    end
end)

Ext.Require("Server/_InitServer.lua")
