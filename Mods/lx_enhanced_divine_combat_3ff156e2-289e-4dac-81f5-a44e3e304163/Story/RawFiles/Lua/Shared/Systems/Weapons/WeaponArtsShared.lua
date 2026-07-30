---@param attacker StatCharacter
---@param target StatCharacter
---@param hitChance number
Data.Math.HitChance.RegisterListener("VP_TrueStrike", function(attacker, target, hitChance)
    if attacker.Character:GetStatus("LX_WA_TRUESTRIKE") ~= null then
        hitChance = hitChance + 25
    end
    return hitChance
end)

Data.Math.HitChance.RegisterListener("LX_CrossbowSignature", function(attacker, target, hitChance)
    if Ext.IsClient() then
        local freeMovement = attacker.Character.RemainingMoveDistance * Data.Math.GetCharacterMovement(attacker.Character).Movement
        if attacker.Character.SkillManager.CurrentSkill ~= null and attacker.Character.SkillManager.CurrentSkill.SkillId == "Projectile_LX_Sniper_-1" then
            return hitChance + math.floor(freeMovement/10)
        end
    else
        local freeMovement = attacker.Character.PartialAP * Data.Math.GetCharacterMovement(attacker.Character).Movement
        if attacker.Character:HasTag("LX_CrossbowSignature") then
            return hitChance + math.floor(freeMovement/10)
        end
    end
    return hitChance
end)