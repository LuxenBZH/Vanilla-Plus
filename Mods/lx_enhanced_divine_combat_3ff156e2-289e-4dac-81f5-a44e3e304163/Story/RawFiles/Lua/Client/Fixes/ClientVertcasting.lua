IsVertcasting = false

Ext.Events.UIInvoke:Subscribe(function (e)
  if e.UI.Type == Ext.UI.TypeID.textDisplay and e.Function == "addText" and e.When == "Before" then
    local character = Helpers.GetPlayerManagerCharacter()
    if character and character.SkillManager.CurrentSkill ~= null then
      local position = Ext.ClientUI.GetPickingState().WalkablePosition
      if math.abs(Ext.GetAiGrid():GetCellInfo(position[1], position[3]).Height - position[2]) > 2 then
        IsVertcasting = true
        local cc = Ext.UI.GetCursorControl()
        local td = Ext.UI.GetByHandle(cc.TextDisplayUIHandle)
        local ui = e.UI --[[@as EclUICursorInfo]]
        local distance = string.match(td.Text, "[0-9]+.[0-9]m")
        e:PreventAction()
        if distance then
          ui.Text = '<font color=\"#C80030\">'..Ext.L10N.GetTranslatedString("hdfbc0f44g7f3dg4985g9621g25cba41922e0")..'!</font><br>'..distance
          ui:GetRoot().addText('<font color=\"#C80030\">'..Ext.L10N.GetTranslatedString("hdfbc0f44g7f3dg4985g9621g25cba41922e0")..'!</font><br>'..distance, e.Args[2], e.Args[3])
        end 
      end
    elseif character then
      IsVertcasting = false
    end
  end
end)

---@param e EclLuaInputEvent
Ext.Events.InputEvent:Subscribe(function(e)
  if e.Event.Release and e.Event.EventId == 4 and IsVertcasting then
    Ext.Net.PostMessageToServer("LX_VertcastingDecast", tostring(Helpers.GetPlayerManagerCharacter().NetID))
  end
end)