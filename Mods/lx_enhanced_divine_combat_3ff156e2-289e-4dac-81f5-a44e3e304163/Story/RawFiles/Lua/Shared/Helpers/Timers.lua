Helpers.Timer = {
    ActiveTimers = {},
    CurrentTime = Ext.Utils.MonotonicTime(),
    IsServer = Ext.IsServer()
}

---@param time number Time in milliseconds
---@param callback function
---@param repeatCount number|nil
function Helpers.Timer.Start(time, callback, repeatCount, ...)
    table.insert(Helpers.Timer.ActiveTimers, {
        Time = time,
        Remaining = time,
        Callback = callback,
        RepeatCount = repeatCount or 0,
        Params = {...}
    })
end

---@param name string
---@param time number Time in milliseconds
---@param callback function
---@param repeatCount number|nil
function Helpers.Timer.StartNamed(name, time, callback, repeatCount, ...)
    table.insert(Helpers.Timer.ActiveTimers, {
        Name = name,
        Time = time,
        Remaining = time,
        Callback = callback,
        RepeatCount = repeatCount or 0,
        Params = {...}
    })
end

---@param timer table|string
function Helpers.Timer.Delete(timer)
    local success = false
    for i, activeTimer in pairs(Helpers.Timer.ActiveTimers) do
        if type(timer) == "table" and timer == activeTimer then
            table.remove(Helpers.Timer.ActiveTimers, i)
            success = true
        elseif type(timer) == "string" and activeTimer.Name == timer then
            table.remove(Helpers.Timer.ActiveTimers, i)
            success = true
        end
    end
    if not success then
        _VError("Unable to delete timer!", "Helpers.Timer")
    end
end

Ext.Events.Tick:Subscribe(function()
    local time = Ext.Utils.MonotonicTime()
    local timeDelta = time - Helpers.Timer.CurrentTime
    for i, timer in pairs(Helpers.Timer.ActiveTimers) do
        if timeDelta >= timer.Remaining then
            timer.Callback(table.unpack(timer.Params))
            if Helpers.Timer.ActiveTimers[i] and timer.RepeatCount > 0 then
                Helpers.Timer.ActiveTimers[i].RepeatCount = timer.RepeatCount - 1
                Helpers.Timer.ActiveTimers[i].Remaining = timer.Time
            else
                if Helpers.Timer.ActiveTimers[i] then
                    Helpers.Timer.Delete(timer)
                end
            end
        else
            Helpers.Timer.ActiveTimers[i].Remaining = Helpers.Timer.ActiveTimers[i].Remaining - timeDelta
        end
    end
    Helpers.Timer.CurrentTime = Ext.Utils.MonotonicTime()
end)