---@alias GUID string
---@class StatusFallbackArray
---@field Template string
---@field Persistance boolean
---@field StatsArray table

---@class CustomStatusManager
CustomStatusManager = {}

---@param target GUID|EsvCharacter
---@param statusID string
---@param duration number
---@param multiplier number
---@param fallback StatusFallbackArray|nil
function CustomStatusManager:CharacterApplyMultipliedStatus(target, statusID, duration, multiplier, fallback)
    if type(target) ~= "string" then
        target = target.MyGuid
    end
    if not NRD_StatExists(statusID) then
        self:CreateStatFromTemplate(statusID, "StatusData", fallback.Template, fallback.StatsArray, fallback.Persistance)
    end
    local status = Ext.PrepareStatus(target, statusID, duration)
    status.StatsMultiplier = multiplier
    Ext.ApplyStatus(status)
end

---@param statusID string
---@param template string
---@param statsArray table
---@param persistance boolean|nil
function CustomStatusManager:CreateStatFromTemplate(statID, statType, template, statsArray, persistance)
    local status = Ext.Stats.Create(statID, statType, template)
    for stat, value in pairs(statsArray) do
        status[stat] = value
    end
    Ext.Stats.Sync(statID, persistance)
end