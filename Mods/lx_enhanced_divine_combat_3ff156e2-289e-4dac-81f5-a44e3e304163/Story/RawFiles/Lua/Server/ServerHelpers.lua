---comment
---@param character string
Helpers.GetCharacterCleanGUID = function(character)
    return character:match("([%x]+%-%x+%-%x+%-%x+%-%x+)$")
end