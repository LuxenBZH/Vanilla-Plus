Ext.ClientBehavior.Skill.AddGlobal(function()
  local EclCustomSkillState = {}
  ---@param ev CustomSkillEventParams
  ---@param skillState EclSkillState
  ---@param targetHandle ComponentHandle
  ---@param targetPos vec3
  ---@param snapToGrid boolean
  ---@param fillInHeight boolean
  ---@return number
  function EclCustomSkillState:ValidateTarget(ev, skillState, targetHandle, targetPos, snapToGrid, fillInHeight)
    if math.abs(Ext.GetAiGrid():GetCellInfo(targetPos[1], targetPos[3]).Height - targetPos[2]) > 2 then
      ev.PreventDefault = true
			ev.StopEvent = true
      return 8
    elseif Ext.Utils.IsValidHandle(targetHandle) then
      local target = Ext.ClientEntity.GetGameObject(targetHandle)
      if Helpers.IsItem(target) and target.IsLadder then
        ev.PreventDefault = true
			  ev.StopEvent = true
        return 4
      end
    end
    return 0
  end
  return EclCustomSkillState
end)