Ext.RegisterListener("SessionLoaded", function()
    local json = Ext.LoadFile("LeaderLib_GlobalSettings.json", "user")
    local module = Ext.JsonParse(json).Mods["3ff156e2-289e-4dac-81f5-a44e3e304163"].Global.Flags.LXDGM_ModuleDivineTalentsDisable
    if Mods.LeaderLib ~= nil and not module.Enabled then
        local VersionInt = Ext.GetModInfo("543d653f-446c-43d8-8916-54670ce24dd9_7e737d2f-31d2-4751-963f-be6ccc59cd0c").Version
        local major = (VersionInt >> 28);
        local minor = (VersionInt >> 24) & 0x0F;
        local revision = (VersionInt >> 16) & 0xFF;
        local build = (VersionInt & 0xFFFF);
        local ts = Mods.LeaderLib.Classes.TranslatedString
        Listeners = Mods.LeaderLib.Listeners
    
        if ((minor == 7 and revision == 16 and build > 9) or (minor == 7 and revision > 16) or (minor > 7)) then
            -- TalentManager = Mods.LeaderLib.TalentManager
            for i,talent in pairs(GB4Talents) do
                TalentManager.EnableTalent(talent, VPlusId)
            end
        end
    end
end)