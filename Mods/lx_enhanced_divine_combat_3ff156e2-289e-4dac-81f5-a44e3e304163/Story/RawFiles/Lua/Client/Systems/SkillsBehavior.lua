Ext.ClientBehavior.Skill.AddById("Projectile_LX_SpellConduit_-1", function()
    local EclCustomSkillState = {}
    
    ---@class ev CustomSkillEventParams
    ---@param skillState EsvSkillState
    ---@return boolean
    function EclCustomSkillState:EnterBehaviour(ev,skillState)
        local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
        local spellConduit = character.UserVars.LX_SpellConduit
        if spellConduit and #spellConduit > 0 then
            for i = 1,3,1 do
                if spellConduit[i] and (i > 1 and spellConduit[i-1] ~= spellConduit[i]) then
                    skillState.AmountOfTargets = skillState.AmountOfTargets + 1
                end
            end
        end
        ev.StopEvent = true
        return true
    end

    -- Prevents targeting an already targeted character
    ---@param ev CustomSkillEventParams
    ---@param skillState EclSkillState
    ---@param targetHandle ComponentHandle
    ---@param targetPos vec3
    ---@param snapToGrid boolean
    ---@param fillInHeight boolean
    ---@return CustomSkillState.ValidateTargetResult
    function EclCustomSkillState:ValidateTarget(ev, skillState, targetHandle, targetPos, snapToGrid, fillInHeight)
        if #skillState.Targets > 1 and skillState.Targets[#skillState.Targets].Results[1] and Ext.Utils.IsValidHandle(skillState.Targets[#skillState.Targets].Results[1].Target) then
            for i=1,#skillState.Targets-1,1 do
                if skillState.Targets[i].Results[1].Target == targetHandle then
                    ev.PreventDefault = true
                    return -1
                end
            end
            ev.PreventDefault = false
            return 0
        end
        ev.PreventDefault = false
        return 0
    end

    -- Prevents projectile targeting through path interruption cheese. Should work on gamepads too but untested.
    ---@param ev CustomSkillEventParams
    ---@param skillState EclSkillState
    ---@param inputEvent InputEvent
    function EclCustomSkillState:OnInputEvent(ev, skillState, inputEvent)
        if #skillState.Targets > 1 and skillState.Targets[#skillState.Targets].Results[1] and Ext.Utils.IsValidHandle(skillState.Targets[#skillState.Targets].Results[1].Target) then
            if inputEvent.EventId == 4 and inputEvent.NewValue.State == "Released" then
                for i=1,#skillState.Targets-1,1 do
                    if skillState.Targets[i].Results[1].Target == skillState.Targets[#skillState.Targets].Targets[1] then
                        ev.PreventDefault = true
                        return
                    end
                end
            end
        end
    end

    return EclCustomSkillState
end)

