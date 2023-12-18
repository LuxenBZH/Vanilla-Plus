---- Elemental Affinity rework
--- @param e LuaGetSkillAPCostEvent
Ext.Events.GetSkillAPCost:Subscribe(function(e)
	ClientElementalAffinityRework(e, nil)
end)

Ext.Events.SessionLoading:Subscribe(function (_)
    if Mods.EpipEncounters then
        local epip = Mods.EpipEncounters.Epip ---@type Epip
        if epip.VERSION >= 1069 then -- GetSkillAPCost hook is only available in v1069+
            local CharacterLib = Mods.EpipEncounters.Character ---@type CharacterLib

            CharacterLib.Hooks.GetSkillAPCost:Subscribe(function (ev)
                -- Replicate your GetSkillAPCost listener here
                ClientElementalAffinityRework(ev, true)
            end)
        end
    end
end)