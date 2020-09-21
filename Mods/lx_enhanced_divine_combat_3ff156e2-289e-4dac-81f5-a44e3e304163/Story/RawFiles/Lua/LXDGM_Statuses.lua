local function FoodRemoveRegeneration(character, status, causee)
    if status ~= "POISONED" then return end
    if HasActiveStatus(character, "LX_FOOD_REGENERATION") == 1 or HasActiveStatus(character, "LX_FOOD_REGENERATION_2") == 1 then
        RemoveStatus(character, "LX_FOOD_REGENERATION")
        RemoveStatus(character, "LX_FOOD_REGENERATION_2")
    end
end

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", FoodRemoveRegeneration)