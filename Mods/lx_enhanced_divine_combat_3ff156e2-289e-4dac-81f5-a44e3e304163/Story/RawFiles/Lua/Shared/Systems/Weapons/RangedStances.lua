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