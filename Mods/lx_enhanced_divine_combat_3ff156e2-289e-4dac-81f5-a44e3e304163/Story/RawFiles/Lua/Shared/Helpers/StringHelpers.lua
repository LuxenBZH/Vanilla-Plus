Helpers.String = {}

---Substitude indexed params in strings (representated with [x])
---@param str string
---@param ... string|number
---@return string
Helpers.String.SubstituteIndexedParams = function(str, ...)
    local args = {...}
    local result = str

    for k, v in pairs(args) do
        if type(v) == "number" then
            v = math.floor(v) -- Formatting integers to not show .0
        end
        result = result:gsub("%["..tostring(k).."%]", v)
    end
    return result
end