ClientTimer = {
    ActiveTimers = {},
    CurrentTime = Ext.Utils.MonotonicTime()
}

---@param time number Time in milliseconds
---@param callback function
---@param repeatCount number|nil
function ClientTimer.Start(time, callback, repeatCount)
    table.insert(ClientTimer.ActiveTimers, {
        Time = time,
        Remaining = time,
        Callback = callback,
        RepeatCount = repeatCount or 0
    })
end

---@param timer table
function ClientTimer.Delete(timer)
    local success = false
    for i, activeTimer in pairs(ClientTimer.ActiveTimers) do
        if timer == activeTimer then
            table.remove(ClientTimer.ActiveTimers, i)
            success = true
        end
    end
    if not success then
        _VError("Unable to delete timer!", "ClientTimer")
    end
end

Ext.Events.Tick:Subscribe(function()
    local time = Ext.Utils.MonotonicTime()
    local timeDelta = time - ClientTimer.CurrentTime

    for i, timer in pairs(ClientTimer.ActiveTimers) do
        if timeDelta >= timer.Remaining then
            timer.Callback()
            if timer.RepeatCount > 0 then
                ClientTimer.ActiveTimers[i].RepeatCount = timer.RepeatCount - 1
                ClientTimer.ActiveTimers[i].Remaining = timer.Time
            else
                ClientTimer.Delete(timer)
            end
        else
            ClientTimer.ActiveTimers[i].Remaining = ClientTimer.ActiveTimers[i].Remaining - timeDelta
        end
    end

    ClientTimer.CurrentTime = Ext.Utils.MonotonicTime()
end)