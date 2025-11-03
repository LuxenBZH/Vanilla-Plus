if Mods.LeaderLib then
    Mods.LeaderLib.Import(Mods.VanillaPlus)
end

if not PersistentVars then
    PersistentVars = {}
end

---@param e EsvLuaGameStateChangedEvent
Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.ToState == "Running" then
        Data.CurrentLevel = Ext.Entity.GetCurrentLevel().LevelDesc
    end
end)

Ext.Vars.RegisterUserVariable("LX_LastTurnDamageTaken", {
    Server = true,
    Client = true, 
    SyncToClient = true,
    Persistent = true,
    SyncOnWrite = true,
    SyncOnTick = false,
})

Ext.Vars.RegisterUserVariable("LX_LastTurnVitalityDamageTaken", {
    Server = true,
    Client = true, 
    SyncToClient = true,
    Persistent = true,
    SyncOnWrite = true,
    SyncOnTick = false,
})

Ext.Vars.RegisterUserVariable("LX_LastTurnArmorDamageTaken", {
    Server = true,
    Client = true, 
    SyncToClient = true,
    Persistent = true,
    SyncOnWrite = true,
    SyncOnTick = false,
})

Ext.Require("Shared/_InitShared.lua")

Ext.Events.SessionLoading:Subscribe(function(e)
    Helpers.UserVars.RegisterUserVar("VP_LastSkillsUsed", true, true, true)
    Helpers.UserVars.RegisterUserVar("VP_HuntsmanReloadLastSkill", true, true, true)
end)
