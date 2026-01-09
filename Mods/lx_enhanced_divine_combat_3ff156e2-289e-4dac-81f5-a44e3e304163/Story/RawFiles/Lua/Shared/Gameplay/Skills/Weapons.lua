----- Quick Shot effects
---@param attacker StatCharacter
---@param target StatCharacter
---@param cth number
local function QuickShotAccuracy(attacker, target, cth)
    local distance = Ext.Math.Distance(attacker.Character.WorldPos, target.Character.WorldPos)
    local accuracyPenalty = Ext.Utils.Round(math.max(distance - 3, 0) * 5)
    return math.min(cth - accuracyPenalty, 80 - accuracyPenalty)
end

---@param attacker StatCharacter
---@param target StatCharacter
---@param cth number
Data.Math.HitChance:RegisterListener(function(attacker, target, cth)
    if Ext.IsClient() and attacker.Character.SkillManager.CurrentSkill and attacker.Character.SkillManager.CurrentSkill.SkillId == "Projectile_LX_QuickShot_-1" then
        return QuickShotAccuracy(attacker, target, cth)
    elseif Ext.IsServer() and attacker.Character.ActionMachine.Layers[1].State and attacker.Character.ActionMachine.Layers[1].State.Type == "UseSkill" and attacker.Character.ActionMachine.Layers[1].State.Skill.SkillId == "Projectile_LX_QuickShot_-1" then
        return QuickShotAccuracy(attacker, target, cth)
    end
    return cth
end)

if Ext.IsServer() then
    Ext.Osiris.RegisterListener("CharacterUsedSkillOnTarget", 5, "after", function(characterGUID, targetGUID, skillId, _, _)
        if skillId == "Projectile_LX_QuickShot" then
            local distance = GetDistanceTo(characterGUID, targetGUID)
            local character = Ext.ServerEntity.GetCharacter(characterGUID)
            character.PartialAP = character.PartialAP + Data.Math.ComputeCelerityValue(distance*100, character)
        end
    end)
end