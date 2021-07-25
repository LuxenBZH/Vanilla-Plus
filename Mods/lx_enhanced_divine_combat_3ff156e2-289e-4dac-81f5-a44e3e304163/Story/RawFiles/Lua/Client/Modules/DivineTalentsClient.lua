Ext.RegisterListener("SessionLoaded", function()
    Ext.Print("Checking divine talents module")
    local json = Ext.LoadFile("LeaderLib_GlobalSettings.json", "user")
    local module = Ext.JsonParse(json).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags.LXDGM_ModuleDivineTalents
    if Mods.LeaderLib ~= nil and module.Enabled then
        TalentManager = Mods.LeaderLib.TalentManager
        for i,talent in pairs(GB4Talents) do
            TalentManager.EnableTalent(talent, VPlusId)
        end
    end
end)