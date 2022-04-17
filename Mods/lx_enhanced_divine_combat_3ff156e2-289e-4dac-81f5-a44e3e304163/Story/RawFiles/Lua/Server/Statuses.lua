-- local function FoodRemoveRegeneration(character, status, causee)
--     if status ~= "POISONED" then return end
--     if HasActiveStatus(character, "LX_FOOD_REGENERATION") == 1 or HasActiveStatus(character, "LX_FOOD_REGENERATION_2") == 1 then
--         RemoveStatus(character, "LX_FOOD_REGENERATION")
--         RemoveStatus(character, "LX_FOOD_REGENERATION_2")
--     end
-- end

-- Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", FoodRemoveRegeneration)

local function ScaleAimedShot(character, status, causee)
    if status == "DGM_AIMEDSHOT" then
        RemoveStatus(character, "DGM_AIMEDSHOT")
        local char = Ext.GetCharacter(character)
        local accuracyBoost = math.floor(20 + (char.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue)*3)
        local status = CreateNewStatus("AimedShot_"..tostring(accuracyBoost), "DGM_Potion_Base", {AccuracyBoost = accuracyBoost, CriticalChance = char.Stats.Strength}, "DGM_AIMEDSHOT", {StackId = "Stack_LX_AimedShot"}, false)
        ApplyStatus(character, status, 6.0, 1)
    end
end

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", ScaleAimedShot)