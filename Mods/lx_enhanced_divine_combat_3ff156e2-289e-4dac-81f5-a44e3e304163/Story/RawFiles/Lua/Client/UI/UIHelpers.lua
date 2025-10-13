---@class UIHelpers.UI.Environment
---@field UIHelpers.UI.Environment.Current "Player"|"GM"|"Menu"|"Dialog"|"LoadingScreen"
Helpers.UI.Environment = {
    Current = "",
    Listeners = {},
}
Helpers.UI.Environment.Refresh = function()
    local state = Ext.Client.GetGameState()
    local dialog = Ext.ClientUI.GetByType(14) or Ext.ClientUI.GetByType(66)
    local GMPanel = Ext.ClientUI.GetByType(120)
    if GMPanel and GMPanel:GetRoot().visible and (state == "Running" or state == "Paused" or state == "GameMasterPause") then
        Helpers.UI.Environment.Current = "GM"
    elseif (dialog and dialog:GetRoot().visible) and (state == "Running" or state == "Paused" or state == "GameMasterPause") then
        Helpers.UI.Environment.Current = "Dialog"
    elseif state ~= "Running" then
        Helpers.UI.Environment.Current = "LoadingScreen"
    elseif state == "Running" or state == "Paused" or state == "GameMasterPause" then
        Helpers.UI.Environment.Current = "Player"
    else
        Helpers.UI.Environment.Current = "Menu"
    end
end

function Helpers.UI.Environment:Subscribe(callback)
    table.insert(Helpers.UI.Environment.Listeners, callback)
end

Helpers.UI.Environment._TriggerListeners = function()
    local previous = Helpers.UI.Environment.Current
    Helpers.UI.Environment.Refresh()
    if Helpers.UI.Environment.Current ~= previous then
        _VPrint("[UIHelpers] Environment changed from: " .. previous .. " to: " .. Helpers.UI.Environment.Current)
        Helpers.Timer.Start(100, function()
            for i,callback in ipairs(Helpers.UI.Environment.Listeners) do
                callback({
                    Context = Helpers.UI.Environment.Current,
                    Previous = previous,
                    Character = Helpers.Client.GetCurrentCharacter()
                })
            end
        end)
    end
end

Ext.Events.GameStateChanged:Subscribe(function(e)
    Helpers.UI.Environment._TriggerListeners()
end)

-- Ext.Events.UICall:Subscribe(function(e)
--     _DS(e)
--     if e.UIType == 120 then
--         Helpers.UI.Environment._TriggerListeners()
--     end
-- end)

Ext.Events.UIInvoke:Subscribe(function(e)
    if e.UI.AnchorObjectName == "minimap" or e.UI.AnchorObjectName == "textDisplay_1" then
        return
    end
    if e.Function == "setButtonEnable" or e.Function == "selectPlayer" then
        Helpers.UI.Environment._TriggerListeners()
    end
end)

Helpers.UI.Environment.Refresh()


Helpers.Tweening = {}
--- Store UI elements currently tweening
Helpers.Tweening.AlphaActiveElements = {}

---@class AlphaTween
local AlphaTween = {
    StartTime = 0,
    Steps = {
        [1] = {
            StartAlpha = 1,
            EndAlpha = 0,
            Duration = 0
        }
    },
}

Ext.Events.Tick:Subscribe(function(e)
    for id,tweenInfo in pairs(Helpers.Tweening.AlphaActiveElements) do
        local currentTime = Ext.Utils.MonotonicTime()
        -- _P(id, tweenInfo.Steps, tweenInfo.Element, tweenInfo.IsEpipElement)
        if type(tweenInfo.Steps) ~= "table" then return end
        local elapsedTime = currentTime - tweenInfo.Steps[1].StartTime
        local progress = math.min(elapsedTime / tweenInfo.Steps[1].Duration, 1)
        local newAlpha = (tweenInfo.Steps[1].EndAlpha - tweenInfo.Steps[1].StartAlpha) * progress + tweenInfo.Steps[1].StartAlpha
        if progress >= 1 then
            if #tweenInfo.Steps > 1 then
                Helpers.TableShiftLeft(tweenInfo.Steps)
                newAlpha = tweenInfo.Steps[1].StartAlpha
                tweenInfo.Steps[1].StartTime = currentTime
            else
                newAlpha = tweenInfo.Steps[1].EndAlpha
                tweenInfo.Steps = nil
            end
        end
        if tweenInfo.IsEpipElement then
            tweenInfo.Element:SetAlpha(newAlpha, tweenInfo.IncludeChildren)
        else
            tweenInfo.Element:GetRoot().alpha = newAlpha
        end
        if not tweenInfo.Steps then
            Helpers.Tweening.AlphaActiveElements[id] = nil
        end
    end
end)

---@param elementID string
---@param tweenInfo table
---@param isEpipElement boolean
---@param includeChildren boolean
Helpers.Tweening.AlphaTween = function(elementID, tweenInfo, isEpipElement, includeChildren)
    tweenInfo.IsEpipElement = isEpipElement
    tweenInfo.IncludeChildren = includeChildren
    tweenInfo.Steps[1].StartTime = Ext.Utils.MonotonicTime()
    Helpers.Tweening.AlphaActiveElements[elementID] = tweenInfo
end
