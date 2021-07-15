local GB4Talents = {
    "Elementalist",
    "Sadist",
    "Haymaker",
    "Gladiator",
    "Indomitable",
    "WildMag",
    "Jitterbug",
    "Soulcatcher",
    "MasterThief",
    "GreedyVessel",
    "MagicCycles",
}

if Mods.LeaderLib ~= nil then
    TalentManager = Mods.LeaderLib.TalentManager
    for i,talent in pairs(GB4Talents) do
        TalentManager.EnableTalent(talent, VPlusId)
    end
end