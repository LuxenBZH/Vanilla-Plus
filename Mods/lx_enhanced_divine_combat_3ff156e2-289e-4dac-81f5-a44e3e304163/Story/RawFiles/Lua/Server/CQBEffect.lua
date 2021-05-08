local rangedWeapons = {
    Bow = true,
    Crossbow = true,
    Wand = true,
    Rifle = true,
}

local function ApplyCQBEffect(object)
    if ObjectIsCharacter(object) == 1 then
        local char = Ext.GetCharacter(object)
        local offhand = char.Stats.OffHandWeapon
        if rangedWeapons[char.Stats.MainWeapon.WeaponType] or (offhand ~= nil and rangedWeapons[offhand]) then
            if NRD_StatExists("LX_CLOSEQUARTER_"..Ext.ExtraData.DGM_RangedCQBPenaltyRange) then
                ApplyStatus(object, "LX_CLOSEQUARTER_"..Ext.ExtraData.DGM_RangedCQBPenaltyRange, 1.0, 1.0)
            else
                local newStatus = Ext.CreateStat("LX_CLOSEQUARTER_"..Ext.ExtraData.DGM_RangedCQBPenaltyRange, "StatusData", "LX_CLOSEQUARTER")
                newStatus["AuraRadius"] = math.floor(Ext.ExtraData.DGM_RangedCQBPenaltyRange)
                Ext.SyncStat(newStatus.Name, false)
                ApplyStatus(char.MyGuid, "LX_CLOSEQUARTER_"..Ext.ExtraData.DGM_RangedCQBPenaltyRange, 1.0, 1)
            end
        end
    end
end

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", ApplyCQBEffect)

local function RemoveCQBEffect(object)
    if ObjectIsCharacter(object) == 1 then
        RemoveStatus(object, "LX_CLOSEQUARTER_"..Ext.ExtraData.DGM_RangedCQBPenaltyRange)
    end
end

Ext.RegisterOsirisListener("ObjectTurnEnded", 1, "before", RemoveCQBEffect)

local function RemoveCQBEffectUnequip(item, character)
    if CharacterIsInCombat(character) == 1 then
        local char = Ext.GetCharacter(character)
        local offhand = char.Stats.OffHandWeapon
        if not (rangedWeapons[char.Stats.MainWeapon.WeaponType] or (offhand ~= nil and rangedWeapons[offhand])) then
            RemoveStatus(character, "LX_CLOSEQUARTER_"..Ext.ExtraData.DGM_RangedCQBPenaltyRange)
        end
    end
end

Ext.RegisterOsirisListener("ItemUnequipped", 2, "before", RemoveCQBEffectUnequip)

local function ReapplyCQBEffectEquip(item, character)
    if CharacterIsInCombat(character) == 1 then
        local char = Ext.GetCharacter(character)
        local offhand = char.Stats.OffHandWeapon
        if (rangedWeapons[char.Stats.MainWeapon.WeaponType] or (offhand ~= nil and rangedWeapons[offhand])) then
            ApplyStatus(character, "LX_CLOSEQUARTER_"..Ext.ExtraData.DGM_RangedCQBPenaltyRange, -1.0, 1)
        end
    end
end

Ext.RegisterOsirisListener("ItemEquipped", 2, "before", ReapplyCQBEffectEquip)