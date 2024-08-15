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

Ext.Require("Shared/_InitShared.lua")

Helpers.UserVars.RegisterUserVar("VP_LastSkillsUsed", true, true, true)
Helpers.UserVars.RegisterUserVar("VP_HuntsmanReloadLastSkill", true, true, true)
