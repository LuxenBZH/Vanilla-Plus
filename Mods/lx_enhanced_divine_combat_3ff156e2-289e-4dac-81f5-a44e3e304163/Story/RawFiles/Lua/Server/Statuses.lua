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


---Forbearance mechanic
---@param target string|number
---@param status any
---@param handle any
---@param instigator any
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
---END Forbearance

---Perseverance on Staggered or Confused expiration
Ext.Events.StatusDelete:Subscribe(function(e)
    local entity = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle)
    if (e.Status.StatusId == "LX_STAGGERED" or e.Status.StatusId == "LX_STAGGERED2" or e.Status.StatusId == "LX_STAGGERED3") and e.Status.CurrentLifeTime == 0.0 then
        ApplyStatus(entity.MyGuid, "POST_PHYS_CONTROL_HALF", 0, 1)
    elseif e.Status.StatusId == "LX_CONFUSED" or e.Status.StatusId == "LX_CONFUSED2" or e.Status.StatusId == "LX_CONFUSED3" and e.Status.CurrentLifeTime == 0.0 then
        ApplyStatus(entity.MyGuid, "POST_MAGIC_CONTROL_HALF", 0, 1)
    end
end)