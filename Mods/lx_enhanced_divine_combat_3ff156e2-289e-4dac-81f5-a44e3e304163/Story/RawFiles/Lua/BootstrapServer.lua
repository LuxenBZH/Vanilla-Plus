Ext.Require("Shared/Data/Data.lua")
Ext.Require("Shared/Helpers.lua")
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



Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    Ext.Entity.GetCharacter(character).UserVars.VP_LastSkillID = {Name = skill, ID = math.random(0, 2147483647)}
end)

Ext.Require("BootstrapShared.lua")
Ext.Require("Server/_InitServer.lua")
