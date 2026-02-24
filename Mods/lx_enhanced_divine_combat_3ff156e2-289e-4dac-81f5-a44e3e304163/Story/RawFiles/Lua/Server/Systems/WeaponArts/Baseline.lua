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

---@param characterGUID string|GUID
local function ToggleWeaponArtsMenu(characterGUID)
    Helpers.Timer.Start(33, function(character)
        if ObjectExists(character) == 1 then
            local hasWA = CharacterHasSkill(character, "Target_LX_WeaponArtMenu") == 1
            local character = Ext.ServerEntity.GetCharacter(character)
            if not hasWA and character.Stats.MainWeapon.WeaponType ~= "Wand" then
                CharacterAddSkill(character.MyGuid, "Target_LX_WeaponArtMenu", 0)
            elseif hasWA and character.Stats.MainWeapon.WeaponType == "Wand" then
                CharacterRemoveSkill(character.MyGuid, "Target_LX_WeaponArtMenu")
            end
        end
    end, nil, characterGUID)
end

Ext.Osiris.RegisterListener("ItemEquipped", 2, "after", function(_, character)
    ToggleWeaponArtsMenu(character)
end)

Ext.Osiris.RegisterListener("ItemUnEquipped", 2, "after", function(_, character)
    ToggleWeaponArtsMenu(character)
end)

Ext.Osiris.RegisterListener("ObjectEnteredCombat", 2, "after", function(object, _)
    if ObjectIsCharacter(object) == 1 then
        ToggleWeaponArtsMenu(object)
    end
end)