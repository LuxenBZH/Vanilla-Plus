---@param attacker CDivinityStatsCharacter
---@param target CDivinityStatsCharacter
---@param hitChance number
---@return number
Data.Math.HitChance.RegisterListener("ReflexStancePenalty", function(attacker, target, hitChance)
    if attacker.Character:GetStatus("LX_REFLEX_STANCE") ~= null then
        local distance = Helpers.CalculateVectorDistance(attacker.Character.WorldPos, target.Character.WorldPos) - target.Character.AI.AIBoundsRadius
        if distance > 8 then
            hitChance = hitChance/2
        end
    end
    return hitChance
end)

---Hunter mark accuracy bypass
---@param attacker CDivinityStatsCharacter
---@param target CDivinityStatsCharacter
---@param hitChance number
---@return number
Data.Math.HitChance.RegisterListener("HunterMark", function(attacker, target, hitChance)
    local hunterMark = target.Character:GetStatus("LX_HUNTERMARK_APPLIED")
    -- ActionState will be null if it's a skill on server side
    if hunterMark ~= null and hunterMark.StatusSourceHandle == attacker.Character.Handle then
        if Ext.IsServer() and hunterMark ~= null and attacker.Character.CharacterBody.ActionState == null then
            return 999
        elseif Ext.IsClient() and attacker.Character.ActionMachine.Layers[1].State and attacker.Character.ActionMachine.Layers[1].State.Type == "PrepareSkill" then
            return 100
        end
        return hitChance
    else
        return hitChance
    end
end)