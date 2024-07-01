---@param e EsvLuaBeforeStatusApplyEvent
Ext.Events.BeforeStatusApply:Subscribe(function(e)
    if e.Status.StatusId == "HIT" then
        if e.Status.SkillId ~= "" then
            local skill = Ext.Stats.Get(e.Status.SkillId:gsub("(.*).+-1$", "%1"))
            if skill.SkillType == "Target" and skill.AreaRadius > 0 then
                local target = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle)
                local heightDiff = math.abs(target.WorldPos[2] - e.Status.ImpactOrigin[2])
                -- Modders can override the height check by writing a value in the Height field of a Target skill
                -- Important note: the height field is multiplied by 1000 when checking it with the extender.
                -- Modders should set the value in meters and not in millimiters !
                if skill.Height/1000 < heightDiff and heightDiff > 2.5 then
                    e.PreventStatusApply = true
                    e:StopPropagation()
                end
            end
        end
    end
end)