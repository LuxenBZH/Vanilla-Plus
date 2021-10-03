local function FoodRegeneration(object)
    if HasActiveStatus(object, "LX_FOOD_REGENERATION") == 1 then
        ApplyStatus(object, "LX_FOOD_REGEN1", 0.0)
    end
    if HasActiveStatus(object, "LX_FOOD_REGENERATION2") == 1 then
        ApplyStatus(object, "LX_FOOD_REGEN2", 0.0)
    end
end

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", FoodRegeneration)

local function FoodPurge(char, status, causee)
    if status ~= "LX_FOOD_CLEAN" then return end
    RemoveStatus(char, "LX_FOOD_POISONED")
    RemoveStatus(char, "LX_FOOD_CLEAN")
end

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", FoodPurge)