---Level up a weapon to fit the level of the character or at the max range if the character outlevels the weapon
---@param item EsvItem
---@param character EsvCharacter
local function WeaponLevelUpInRange(item, character)
    if not character.IsPlayer then return end
    local originalLevel = (Helpers.GetVariableTag(item, "VP_WeaponGenerationLevel")) or (item.Generation ~= null and item.Generation.Level or item.CurrentTemplate.LevelOverride)
    originalLevel = tonumber(originalLevel)
    -- _P("Item generation level", originalLevel)
    if originalLevel < character.Stats.Level and originalLevel + Ext.ExtraData.DGM_WeaponDefaultLevelRange >= character.Stats.Level then
        -- _P("LEVEL UP", character.Stats.Level)
        ItemLevelUpTo(item.MyGuid, character.Stats.Level)
    elseif originalLevel + Ext.ExtraData.DGM_WeaponDefaultLevelRange < character.Stats.Level then
        ItemLevelUpTo(item.MyGuid, originalLevel + Ext.ExtraData.DGM_WeaponDefaultLevelRange)
        -- _P("LEVEL UP", originalLevel + Ext.ExtraData.DGM_WeaponDefaultLevelRange)
    end
    Helpers.SetVariableTag(item, "VP_WeaponGenerationLevel", originalLevel)
end

Ext.Osiris.RegisterListener("ItemEquipped", 2, "before", function(item, character)
    local item = Ext.ServerEntity.GetItem(item)
    if Data.EquipmentSlots[item.Slot] == "Weapon" or Data.EquipmentSlots[item.Slot] == "Shield" then
        WeaponLevelUpInRange(item, Ext.ServerEntity.GetCharacter(character))
    end
end)

Ext.Osiris.RegisterListener("CharacterLeveledUp", 1, "before", function(character)
    local character = Ext.ServerEntity.GetCharacter(character)
    if character.Stats.MainWeapon then
        WeaponLevelUpInRange(character.Stats.MainWeapon.GameObject, character)
    end
    if character.Stats.OffHandWeapon then
        WeaponLevelUpInRange(character.Stats.OffHandWeapon.GameObject, character)
    end
    if character.Stats.Shield then
        WeaponLevelUpInRange(character.Stats.OffHandWeapon.GameObject, character)
    end
end)

-- Ext.Osiris.RegisterListener("GameStarted", 2, "after", function (_, _)
--     for i,j in pairs(Osi.DB_IsPlayer:Get(nil)) do
--         local character = Ext.ServerEntity.GetCharacter(j[1])
--         if character.Stats.MainWeapon then
--             WeaponLevelUpInRange(character.Stats.MainWeapon.GameObject, character)
--         end
--         if character.Stats.OffHandWeapon then
--             WeaponLevelUpInRange(character.Stats.OffHandWeapon.GameObject, character)
--         end
--     end
-- end)