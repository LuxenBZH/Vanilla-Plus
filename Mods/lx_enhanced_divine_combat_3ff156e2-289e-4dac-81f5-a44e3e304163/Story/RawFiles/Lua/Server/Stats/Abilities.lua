--- Perseverance passive armor recovery
Helpers.RegisterTurnTrueStartListener(function(guid)
    if ObjectIsCharacter(guid) == 1 and CharacterIsIncapacitated(guid) == 0 then
        local character = Ext.ServerEntity.GetCharacter(guid)
        local recoveryValue = Ext.Utils.Round(Game.Math.GetAverageLevelDamage(character.Stats.Level) * character.Stats.Perseverance * (Ext.ExtraData.DGM_PerseveranceRecovery /100))
        character.Stats.CurrentArmor = math.min(character.Stats.CurrentArmor + recoveryValue, character.Stats.MaxArmor)
        character.Stats.CurrentMagicArmor = math.min(character.Stats.CurrentMagicArmor + recoveryValue, character.Stats.MaxMagicArmor)
    end
end)

--- Leadership DR + healing increase
local function ScaleLeadershipRecovery(characterGUID)
    local character = Ext.ServerEntity.GetCharacter(characterGUID)
    local leadership = character:GetStatus("LEADERSHIP")
    if Ext.Utils.IsValidHandle(leadership.StatusSourceHandle) then
        local leadershipLevel = Ext.ServerEntity.GetCharacter(leadership.StatusSourceHandle).Stats.Leadership
        local totalDamage = 0
        for damageType, value in pairs(character.UserVars.LX_LastTurnDamageTaken) do
            totalDamage = totalDamage + value
        end
        local maxThreshold = Game.Math.GetAverageLevelDamage(character.Stats.Level) * Ext.ExtraData.VP_LeadershipMaxRecoveryALDMultiplier
        local statusMultiplier = leadershipLevel * (1 + math.min(1, totalDamage/maxThreshold) * (Ext.ExtraData.VP_LeadershipArmourRecoveryMultiplier - 1))
        Helpers.Status.Multiply(leadership, statusMultiplier)
    end
end


HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "VP_LeadershipFriendlyFireDR", function(hit, instigator, target, flags)
	if CharacterIsAlly(instigator.MyGuid, target.MyGuid) == 1 then
        HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, 1-math.min(1, (target.Stats.Leadership * Ext.ExtraData.VP_LeadershipFriendlyFireReduction * 2 / 100)))
    end
    if target:GetStatus("LEADERSHIP") and target.UserVars.LX_LastTurnDamageTaken then
        Helpers.Timer.StartNamed("VP_LeadershipScaling_"..target.MyGuid, 33, ScaleLeadershipRecovery, 0, target.MyGuid)
    end
end)

Helpers.RegisterTurnTrueEndListener(function(character)
    local character = Ext.ServerEntity.GetCharacter(character)
    local leadership = character:GetStatus("LEADERSHIP")
    if leadership and Ext.Utils.IsValidHandle(leadership.StatusSourceHandle) then
        Helpers.Status.Multiply(leadership, Ext.ServerEntity.GetCharacter(leadership.StatusSourceHandle).Stats.Leadership)
    end
end)

Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "after", function(characterGUID, status, _)
    if status == "LEADERSHIP" then
        local character = Ext.ServerEntity.GetCharacter(characterGUID)
        if character.UserVars.LX_LastTurnDamageTaken then
            ScaleLeadershipRecovery(characterGUID)
        end
    end
end)