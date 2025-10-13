Ext.ClientBehavior.Skill.AddById("Projectile_LX_SpellConduit_-1", function()
    local EclCustomSkillState = {}

    ---@class ev CustomSkillEventParams
    ---@param skillState EsvSkillState
    ---@return boolean
    function EclCustomSkillState:EnterBehaviour(ev,skillState)
        -- _DS(ev)
        -- _DS(skillState)
        local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
        local spellConduit = character.UserVars.LX_SpellConduit
        if spellConduit and #spellConduit > 0 then
            for i = 1,3,1 do
                if spellConduit[i] then
                    skillState.AmountOfTargets = i
                end
            end
        end
        -- _DS(character.SkillManager.CurrentSkill)
        ev.StopEvent = true
        return true
    end

    ---@param ev CustomSkillEventParams
    ---@param skillState EclSkillState
    ---@return boolean -- Purpose unknown. Defaults to `false`.
    -- function EclCustomSkillState:EnterAction(ev, skillState)
    --     local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
    --     local spellConduit = character.UserVars.LX_SpellConduit
    --     if spellConduit and #spellConduit > 0 then
    --         for i = 1,math.min(3, #spellConduit),1 do
    --             Helpers.TableShiftLeft(character.UserVars.LX_SpellConduit)
    --         end
    --     end
    --     return false
    -- end
    return EclCustomSkillState
end)