Ext.RegisterListener("SessionLoaded", function()
    local json = Ext.LoadFile("LeaderLib_GlobalSettings.json", "user")
    local module = Ext.JsonParse(json).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags.LXDGM_ModuleDivineTalentsDisable
    if Mods.LeaderLib ~= nil and not module.Enabled then
        -- TalentManager = Mods.LeaderLib.TalentManager
        for i,talent in pairs(GB4Talents) do
            TalentManager.EnableTalent(talent, VPlusId)
        end
    end
end)