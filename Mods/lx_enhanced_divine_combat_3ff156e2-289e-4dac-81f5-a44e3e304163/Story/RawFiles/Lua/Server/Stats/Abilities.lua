--- Perseverance passive armor recovery
Helpers.RegisterTurnTrueStartListener(function(guid)
    if ObjectIsCharacter(guid) == 1 and CharacterIsIncapacitated(guid) == 0 then
        local character = Ext.ServerEntity.GetCharacter(guid)
        local recoveryValue = Ext.Utils.Round(Game.Math.GetAverageLevelDamage(character.Stats.Level) * character.Stats.Perseverance * (Ext.ExtraData.DGM_PerseveranceRecovery /100))
        character.Stats.CurrentArmor = math.min(character.Stats.CurrentArmor + recoveryValue, character.Stats.MaxArmor)
        character.Stats.CurrentMagicArmor = math.min(character.Stats.CurrentMagicArmor + recoveryValue, character.Stats.MaxMagicArmor)
    end
end)