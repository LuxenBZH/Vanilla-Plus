UICursorTooltipManager = {
    Tooltips = {}
}

---Add a cursor tooltip
---@param callback fun(e:CursorTooltipEvent) -- A function that returns the text that should be displayed (nil if conditions are not met)
function UICursorTooltipManager:AddConditionalTooltip(callback)
    table.insert(self.Tooltips, {Callback = callback})
end

---@param e EclUICursorInfo
---@param character EclCharacter
---@param pickingState EclPickingState
function UICursorTooltipManager:CheckTooltips(e, character, pickingState)
    local ui = e.UI
    local cc = Ext.UI.GetCursorControl()
    local td = Ext.UI.GetByHandle(cc.TextDisplayUIHandle)
    local cursorText = td.Text
    local first = true
    for i,tooltip in pairs(self.Tooltips) do
        local text = tooltip.Callback(character, pickingState)
        if text then
            if first then
                cursorText = cursorText..'<font size="15">'..text..'</font>'
                first = false
            else
                cursorText = cursorText.."<br>"..'<font size="15">'..text..'</font>'
            end
            e:PreventAction()
        end
    end
    ui:GetRoot().addText(cursorText)
end

Ext.Events.SessionLoaded:Subscribe(function(e)
    Ext.Events.UIInvoke:Subscribe(function(e)
        if e.UI.Type == Ext.UI.TypeID.textDisplay and e.Function == "addText" and e.When == "Before" then
            local character = Helpers.GetPlayerManagerCharacter()
            UICursorTooltipManager:CheckTooltips(e, character, Ext.ClientUI.GetPickingState())
        end
    end)
end)

---@param character EclCharacter
---@param pickingState EclPickingState
UICursorTooltipManager:AddConditionalTooltip(function(character, pickingState)
    if character.SkillManager.CurrentSkill and character.SkillManager.CurrentSkill.SkillId == "Target_Challenge_-1" and pickingState.HoverCharacter then
        local statEntry = Ext.Stats.Get("CHALLENGE")
        local multiplier = math.min(Ext.ClientEntity.GetCharacter(pickingState.HoverCharacter).Stats.CurrentVitality / (Game.Math.CalculateBaseDamage(statEntry.VP_ChallengeVitalityScaling, nil, nil, character.Stats.Level) * (statEntry.VP_ChallengeVitalityStep/100)), statEntry.VP_ChallengeMultiplierCap)
        local potion = Ext.Stats.Get("Stats_Challenge_Win")
        return Helpers.GetDynamicTranslationStringFromHandle("h7650995bg0673g4ccfg82eeg66ad641811e8", 
                Ext.Utils.Round(multiplier), 
                Ext.Utils.Round(multiplier*Data.Math.GetArmorRegenScaledValue(character.Stats.Level, character, "Armor", potion)),
                Ext.Utils.Round(multiplier*Data.Math.GetArmorRegenScaledValue(character.Stats.Level, character, "MagicArmor", potion)),
                Ext.Utils.Round(multiplier*Data.Math.GetHealScaledValue("CHALLENGE_WIN_HEAL", character)), 
                Ext.Utils.Round(multiplier*Ext.Utils.Round(Game.Math.GetAverageLevelDamage(character.Stats.Level)*((Ext.Stats.Get("Stats_Challenge_Loss")["Damage Multiplier"])/100)))
            )
    end
end)