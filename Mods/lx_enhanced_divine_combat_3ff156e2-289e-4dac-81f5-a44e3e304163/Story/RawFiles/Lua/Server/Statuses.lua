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

-- Ext.Events.BeforeStatusApply:Subscribe(function (e)
--     local status = e.Status --- @type EsvStatus
--     local target = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle).MyGuid
--     if Ext.Stats.Get(e.Status.StatusId).IsResistingDeath and HasActiveStatus(target, "LX_FORBEARANCE") == 1 then
--         _P("PREVENT RESIST DEATH")
--         Osi.NRD_StatusPreventApply(target, e.Status.StatusHandle, 1)
--     end
-- end)

Ext.Osiris.RegisterListener("NRD_OnStatusAttempt", 4, "before", function(target, status, handle, instigator)
    local stat = Ext.Stats.Get(status, nil, false)
    if stat and stat.IsResistingDeath == "Yes" and HasActiveStatus(target, "LX_FORBEARANCE") == 1 then
        Osi.NRD_StatusPreventApply(target, handle, 1)
        Osi.CharacterStatusText(target, "Forbearance is active!")
    end
end)

Ext.Events.StatusDelete:Subscribe(function(e)
    if e.Status.IsResistingDeath then
        ApplyStatus(Ext.ServerEntity.GetGameObject(e.Status.TargetHandle).MyGuid, "LX_FORBEARANCE", 12.0, 1)
    end
end)