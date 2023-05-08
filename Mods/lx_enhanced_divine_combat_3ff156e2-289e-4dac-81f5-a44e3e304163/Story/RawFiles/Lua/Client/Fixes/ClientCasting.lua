Ext.Events.SessionLoaded:Subscribe(function(e)
  Ext.Events.UIInvoke:Subscribe(function(e)
    if e.UI.Type == Ext.UI.TypeID.textDisplay and e.Function == "addText" and e.When == "Before" then
      local character = Helpers.GetPlayerManagerCharacter()
      if character and character.SkillManager.CurrentSkill ~= null then
        --- Vertcasting check
        local position = Ext.ClientUI.GetPickingState().WalkablePosition
        if math.abs(Ext.GetAiGrid():GetCellInfo(position[1], position[3]).Height - position[2]) > 2 then
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
      end
    end
  end)

  ---@param e EclLuaInputEvent
  Ext.Events.InputEvent:Subscribe(function(e)
    local character = Helpers.GetPlayerManagerCharacter()
    local position = Ext.ClientUI.GetPickingState().WalkablePosition
    if e.Event.Release and e.Event.EventId == 4 and character and character.SkillManager.CurrentSkill ~= null and math.abs(Ext.GetAiGrid():GetCellInfo(position[1], position[3]).Height - position[2]) > 2 then
      Ext.Net.PostMessageToServer("LX_VertcastingDecast", tostring(character.NetID))
      if PreviousLadder then
        local ladder = Ext.Entity.GetItem(PreviousLadder)
        ladder.CurrentTemplate.CanClickThrough = false
        ladder.CanUse = true
      end
    end
  end)

  Ladders = {}
  CastWatcher = 0

  ---- Ladder casting fixes
  Ext.RegisterNetListener("LX_LaddercastFixEnter", function(channel, payload)
    local ladders = Ext.Json.Parse(payload)
    for i, netID in pairs(ladders) do
      local ladder = Ext.Entity.GetItem(netID)
      ladder.CurrentTemplate.CanClickThrough = true
      ladder.CanUse = false
      table.insert(Ladders, netID)
    end
    CastWatcher = Ext.Events.Tick:Subscribe(function(e)
      local character = Helpers.GetPlayerManagerCharacter()
      if character and character.SkillManager and character.SkillManager.CurrentSkill == null then
        for i, netID in pairs(Ladders) do
          local ladder = Ext.Entity.GetItem(netID)
          ladder.CurrentTemplate.CanClickThrough = false
          ladder.CanUse = true
        end
        Ext.Events.Tick:Unsubscribe(CastWatcher)
      end
    end)
  end)
end)
