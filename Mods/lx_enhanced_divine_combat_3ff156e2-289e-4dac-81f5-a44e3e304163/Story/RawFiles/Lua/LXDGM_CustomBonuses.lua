local customBonuses = {
    Finesse = {Movement = Ext.ExtraData.DGM_FinesseMovementBonus, CriticalChance = Ext.ExtraData.DGM_FinesseCritChance},
    Intelligence = {AccuracyBoost = Ext.ExtraData.DGM_IntelligenceAccuracyBonus}
}

--- @param character EsvCharacter
function SyncAttributeBonuses(char)
    char = Ext.GetCharacter(char)
    for attribute, bonuses in pairs(customBonuses) do
        local charAttr = math.floor(char.Stats[attribute] - Ext.ExtraData.AttributeBaseValue)
        local statusName = "DGM_"..attribute.."_"..charAttr
        if NRD_StatExists(statusName) then
            ApplyStatus(char.MyGuid, statusName, -1, 1)
        else
            local newPotion = Ext.CreateStat("DGM_Potion_"..attribute.."_"..charAttr, "Potion", "DGM_Potion_Base")
            for bonus,value in pairs(bonuses) do
                newPotion[bonus] = charAttr * value
            end
            Ext.SyncStat(newPotion.Name, false)
            local newStatus = Ext.CreateStat("DGM_"..attribute.."_"..charAttr, "StatusData", "DGM_BASE")
            newStatus["StatsId"] = newPotion.Name
            newStatus["StackId"] = "DGM_"..attribute
            Ext.SyncStat(newStatus.Name, false)
            ApplyStatus(char.MyGuid, statusName, -1)
        end
    end
end

Ext.NewCall(SyncAttributeBonuses, "LX_EXT_SyncAttributeBonuses", "(CHARACTERGUID)_Character")

local customAbilityBonuses = {
    SingleHanded = {
        ArmorBoost=Ext.ExtraData.DGM_SingleHandedArmorBonus,
        MagicArmorBoost=Ext.ExtraData.DGM_SingleHandedArmorBonus,
        FireResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
        EarthResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
        PoisonResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
        WaterResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus,
        AirResistance=Ext.ExtraData.DGM_SingleHandedResistanceBonus
    },
    TwoHanded = {AccuracyBoost=Ext.ExtraData.DGM_TwoHandedCTHBonus},
    Ranged = {RangeBoost=Ext.ExtraData.DGM_RangedRangeBonus},
    DualWielding = {}
}

--- @param character StatCharacter
--- @param weapon StatItem
function GetWeaponAbility(character, weapon)
    if weapon == nil then
        return nil
    end

    local offHandWeapon = character.OffHandWeapon
    if offHandWeapon ~= nil then
        return "DualWielding"
    end

    local weaponType = weapon.WeaponType
    if weaponType == "Bow" or weaponType == "Crossbow" or weaponType == "Rifle" then
        return "Ranged"
    end

    if weapon.IsTwoHanded then
        return "TwoHanded"
    end

    return "SingleHanded"
end

function SyncAbilitiesBonuses(char)
    char = Ext.GetCharacter(char)
    local ability = GetWeaponAbility(char.Stats, char.Stats.MainWeapon)
    local charAbi = math.floor(char.Stats[ability])
    local statusName = "DGM_"..ability.."_"..charAbi
    Ext.Print(ability, charAbi, statusName)
    if NRD_StatExists(statusName) then
        ApplyStatus(char.MyGuid, statusName, -1, 1)
    else
        Ext.Print("Stat doesn't exists")
        local bonuses = customAbilityBonuses[ability]
        local newPotion = Ext.CreateStat("DGM_Potion_"..ability.."_"..charAbi, "Potion", "DGM_Potion_Base")
        for bonus,value in pairs(bonuses) do
            newPotion[bonus] = charAbi * value
            Ext.Print(bonus, value, charAbi)
        end
        Ext.SyncStat(newPotion.Name, false)
        local newStatus = Ext.CreateStat("DGM_"..ability.."_"..charAbi, "StatusData", "DGM_BASE")
        newStatus["StatsId"] = newPotion.Name
        newStatus["StackId"] = "DGM_WeaponAbility"
        newStatus["StackPriority"] = 1
        Ext.SyncStat(newStatus.Name, false)
        ApplyStatus(char.MyGuid, statusName, -1)
    end
end

Ext.NewCall(SyncAbilitiesBonuses, "LX_EXT_SyncAbilityBonuses", "(CHARACTERGUID)_Character")


