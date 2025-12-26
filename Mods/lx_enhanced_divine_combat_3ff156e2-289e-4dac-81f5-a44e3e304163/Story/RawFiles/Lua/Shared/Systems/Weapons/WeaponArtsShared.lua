---@param attacker StatCharacter
---@param target StatCharacter
---@param hitChance number
Data.Math.HitChance.RegisterListener("VP_TrueStrike", function(attacker, target, hitChance)
    if attacker.Character:GetStatus("LX_WA_TRUESTRIKE") ~= null then
        hitChance = hitChance + 30
    end
    return hitChance
end)