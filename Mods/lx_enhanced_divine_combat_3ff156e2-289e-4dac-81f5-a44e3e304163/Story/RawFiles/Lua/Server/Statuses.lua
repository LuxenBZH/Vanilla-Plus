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
---@param e EsvLuaStatusDeleteEvent
Ext.Events.StatusDelete:Subscribe(function(e)
    local entity = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle)
    if (e.Status.StatusId == "LX_STAGGERED" or e.Status.StatusId == "LX_STAGGERED2" or e.Status.StatusId == "LX_STAGGERED3") and e.Status.CurrentLifeTime == 0.0 then
        ApplyStatus(entity.MyGuid, "POST_PHYS_CONTROL_HALF", 0, 1)
    elseif e.Status.StatusId == "LX_CONFUSED" or e.Status.StatusId == "LX_CONFUSED2" or e.Status.StatusId == "LX_CONFUSED3" and e.Status.CurrentLifeTime == 0.0 then
        ApplyStatus(entity.MyGuid, "POST_MAGIC_CONTROL_HALF", 0, 1)
    end
end)

---@param e EsvLuaStatusDeleteEvent
Ext.Events.BeforeStatusDelete:Subscribe(function(e)
    if Data.Stats.Warmup[e.Status.StatusId] then
        local object = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle)
        if Helpers.IsCharacter(object) and object:HasTag("LX_Warmup") then
            e.Status.CurrentLifeTime = 6.0
            e:PreventAction()
            ClearTag(object.MyGuid, "LX_Warmup")
        else
            ApplyStatus(object.MyGuid, Data.Stats.Warmup[Data.Stats.Warmup[e.Status.StatusId]-1], 6.0, 1, object.MyGuid)
        end
    end
end)

Ext.Osiris.RegisterListener("CharacterStartAttackObject", 3, "before", function(defender, owner, attacker)
    if CharacterIsInCombat(attacker) == 1 then
        SetTag(attacker, "LX_Warmup")
    end
end)

Ext.Osiris.RegisterListener("ObjectTurnEnded", 1, "before", function(object)
    ClearTag(object, "LX_Warmup")
end)

Ext.Osiris.RegisterListener("ObjectLeftCombat", 2, "before", function(object, combatID)
    ClearTag(object, "LX_Warmup")
end)