HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "LX_WeaponArtsHit", function(hit, instigator, target, flags, skillId)
    if instigator == nil then return end 
    if instigator:GetStatus("LX_WA_TRUESTRIKE") then    
        HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, 0.9)
        ---Check if the character is back to idle state and remove True Strike
        ---Also reduce damage by 30%
        ---@param character EsvCharacter
        Helpers.Timer.StartNamed("LX_TrueStrike_"..instigator.MyGuid, 30, function(guid)
            local character = Ext.ServerEntity.GetCharacter(guid)
            if character.ActionMachine.Layers[1].State == null then
                RemoveStatus(character.MyGuid, "LX_WA_TRUESTRIKE")
                Helpers.Timer.Delete("LX_TrueStrike_"..guid)
            end
        end, 150, instigator.MyGuid)
    end
end)

---@param e EsvLuaBeforeStatusApplyEvent
Ext.Events.BeforeStatusApply:Subscribe(function(e)
    if e.Status.StatusId == "LX_WA_RECKLESSDASH" then
        e.PreventStatusApply = true
        e.Owner.PartialAP = e.Owner.PartialAP + Data.Math.ComputeCelerityValue(Data.Math.GetCharacterMovement(e.Owner).Movement, e.Owner)
    end
end)

Ext.Osiris.RegisterListener("ItemEquipped", 2, "after", function(_, character)
    Helpers.Timer.Start(10, function(character)
        local hasWA = CharacterHasSkill(character, "Target_DualWieldingAttack") == 1
        local character = Ext.ServerEntity.GetCharacter(character)
        if not hasWA and character.Stats.MainWeapon.WeaponType ~= "Wand" then
            CharacterAddSkill(character.MyGuid, "Target_DualWieldingAttack", 0)
        end
    end, nil, character)
end)