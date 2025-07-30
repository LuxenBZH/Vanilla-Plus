local function PreventClientVertcasting()
  local EclCustomSkillState = {}
  local skillProperties
  ---There is a bug where skills with a SurfaceChange property will trigger ValidateTarget way more and kill client FPS
  ---A workaround is to remove the SurfaceChange property temporarily from client side while casting the skill
  ---@param ev CustomSkillEventParams
  ---@param skillState EclSkillState
  function EclCustomSkillState:Enter(ev, skillState)
    local skill = Helpers.GetFormattedSkillID(skillState.SkillId)
    local statEntry = Ext.Stats.Get(skill)
    skillProperties = statEntry.SkillProperties
    local cleanProperties = {}
    for i, property in pairs(statEntry.SkillProperties) do
      if property.Type ~= "SurfaceChange" then
        table.insert(cleanProperties, property)
      end
    end
    statEntry.SkillProperties = cleanProperties
    return false
  end

  ---@param ev CustomSkillEventParams
  ---@param skillState EclSkillState
  ---@param targetHandle ComponentHandle
  ---@param targetPos vec3
  ---@param snapToGrid boolean
  ---@param fillInHeight boolean
  ---@return number
  function EclCustomSkillState:ValidateTarget(ev, skillState, targetHandle, targetPos, snapToGrid, fillInHeight)
    if math.abs(Ext.ClientEntity.GetAiGrid():GetHeight(targetPos[1], targetPos[3]) - targetPos[2]) > 2 then
      ev.PreventDefault = true
      ev.StopEvent = true
      return 8
    end
    return 0
  end

  ---Make sure to restore the original skill properties before hit since it's client-driven
  ---@param ev CustomSkillEventParams
  ---@param skillState EclSkillState
  function EclCustomSkillState:EnterAction(ev, skillState)
    if #skillProperties > 0 then
      local skill = Helpers.GetFormattedSkillID(skillState.SkillId)
      local statEntry = Ext.Stats.Get(skill)
      statEntry.SkillProperties = skillProperties
    end
    return false
  end

  ---@param ev CustomSkillEventParams
  ---@param skillState EclSkillState
  function EclCustomSkillState:Finish(ev, skillState)
    if #skillProperties > 0 then
      local skill = Helpers.GetFormattedSkillID(skillState.SkillId)
      local statEntry = Ext.Stats.Get(skill)
      statEntry.SkillProperties = skillProperties
    end
    return false
  end
  return EclCustomSkillState
end

local function PreventLadderCasting()
  local EclCustomSkillState = PreventClientVertcasting()
  
  ---@param ev CustomSkillEventParams
  ---@param skillState EclSkillState
  ---@param targetHandle ComponentHandle
  ---@param targetPos vec3
  ---@param snapToGrid boolean
  ---@param fillInHeight boolean
  ---@return number
  function EclCustomSkillState:ValidateTarget(ev, skillState, targetHandle, targetPos, snapToGrid, fillInHeight)
    if Ext.Utils.IsValidHandle(targetHandle) then
      local target = Ext.ClientEntity.GetGameObject(targetHandle)
      -- Ladder should still be targetable if they are meant to be destroyed (if they have an HP bar)
      if Helpers.IsItem(target) and target.IsLadder and target.StatsFromName.StatsEntry.Vitality == -1 then
        ev.PreventDefault = true
        ev.StopEvent = true
        return 4
      end
    end
    return 0
  end

  return EclCustomSkillState
end

Ext.ClientBehavior.Skill.AddByType("Target", PreventClientVertcasting)
Ext.ClientBehavior.Skill.AddByType("ProjectileStrike", PreventClientVertcasting)
Ext.ClientBehavior.Skill.AddByType("Projectile", PreventLadderCasting)