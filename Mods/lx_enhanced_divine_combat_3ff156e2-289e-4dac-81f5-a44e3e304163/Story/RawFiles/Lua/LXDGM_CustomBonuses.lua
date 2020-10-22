---- Crossbow Management
local crossbowSlowdown = {
    Base = Ext.ExtraData.DGM_CrossbowBasePenalty,
    Level = Ext.ExtraData.DGM_CrossbowLevelGrowthPenalty
}

--- @param character EsvCharacter
local function CreateCrossbowSlowdownStat(char)
    if ObjectExists(char) == 0 then return end
    char = Ext.GetCharacter(char)
    if char == nil then return end
    local weapon = char.Stats.MainWeapon
    if weapon.WeaponType ~= "Crossbow" then return end
    local leveledSlow = weapon.Level * crossbowSlowdown.Level
    local statusName = "DGM_CrossbowSlow_"..weapon.Level
    if NRD_StatExists(statusName) then
        ApplyStatus(char.MyGuid, statusName, -1, 1)
    else
        local newPotion = {Name = "DGM_Potion_CrossbowSlow_"..weapon.Level}
        if not NRD_StatExists(newPotion.Name) then
            newPotion = Ext.CreateStat("DGM_Potion_CrossbowSlow_"..weapon.Level, "Potion", "DGM_Potion_Base")
            newPotion.Movement = crossbowSlowdown.Base + leveledSlow
            Ext.SyncStat(newPotion.Name, false)
        end
        local newStatus = Ext.CreateStat("DGM_CrossbowSlow_"..weapon.Level, "StatusData", "DGM_BASE")
        newStatus["StatsId"] = newPotion.Name
        newStatus["StackId"] = "DGM_CrossbowSlow"
        Ext.SyncStat(newStatus.Name, false)
        ApplyStatus(char.MyGuid, statusName, -1, 1)
    end
end

local function ManageCrossbowMovement(char, status, causee)
    if status ~= "LX_CROSSBOWINIT" then return end
    RemoveStatus(char, "LX_CROSSBOWCLEAR")
    CreateCrossbowSlowdownStat(char)
end

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", ManageCrossbowMovement)

local function RemoveCrossbowSlow(char, status, causee)
    if status ~= "LX_CROSSBOWINIT" then return end
    ApplyStatus(char, "LX_CROSSBOWCLEAR", 6.0, 1)
end

Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "before", RemoveCrossbowSlow)

local function CheckCrossbowLevelUp(char)
    if HasActiveStatus(char, "LX_CROSSBOWINIT") == 1 then CreateCrossbowSlowdownStat(char) end
end

Ext.RegisterOsirisListener("CharacterLeveledUp", 1, "before", CheckCrossbowLevelUp)

---- Attributes and abilities management

local customBonuses = {
    Finesse = {Movement = Ext.ExtraData.DGM_FinesseMovementBonus, CriticalChance = Ext.ExtraData.DGM_FinesseCritChance},
    Intelligence = {AccuracyBoost = Ext.ExtraData.DGM_IntelligenceAccuracyBonus}
}

--- @param character EsvCharacter
function SyncAttributeBonuses(char)
    if ObjectExists(char) == 0 then return end
    char = Ext.GetCharacter(char)
    if char == nil then return end
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
            --Ext.Print(newStatus.Name)
            ApplyStatus(char.MyGuid, statusName, -1)
        end
    end
    local weapon = char.Stats.MainWeapon
    if weapon.WeaponType == "Crossbow" then 
        CreateCrossbowSlowdownStat(char.MyGuid) 
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
    DualWielding = {},
    None = {}
}

--- @param character StatCharacter
--- @param weapon StatItem
function GetWeaponAbility(character, weapon)
    if weapon == nil or weapon.WeaponType == "None" then
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
    if ObjectExists(char) == 0 then return end
    char = Ext.GetCharacter(char)
    if char == nil then return end
    local ability = GetWeaponAbility(char.Stats, char.Stats.MainWeapon)
    if ability == nil then
        if NRD_StatExists("DGM_NoWeapon") then
            ApplyStatus(char.MyGuid, "DGM_NoWeapon", -1, 1)
        else
            local newStatus = Ext.CreateStat("DGM_NoWeapon", "StatusData", "DGM_BASE")
            newStatus["StackId"] = "DGM_WeaponAbility"
            newStatus["StackPriority"] = 1
            Ext.SyncStat(newStatus.Name, false)
        end
        return
    end
    local charAbi = math.floor(char.Stats[ability])
    local statusName = "DGM_"..ability.."_"..charAbi
    if NRD_StatExists(statusName) then
        ApplyStatus(char.MyGuid, statusName, -1, 1)
    else
        local bonuses = customAbilityBonuses[ability]
        local newPotion = Ext.CreateStat("DGM_Potion_"..ability.."_"..charAbi, "Potion", "DGM_Potion_Base")
        for bonus,value in pairs(bonuses) do
            newPotion[bonus] = charAbi * value
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

local function CheckAllCustomBonuses(level, isEditor)
    CharacterLaunchOsirisOnlyIterator("DGM_GlobalStatCheck")
end

Ext.RegisterOsirisListener("GameStarted", 2, "before", CheckAllCustomBonuses)

local function CharacterGlobalCheck(character, event)
    if event ~= "DGM_GlobalStatCheck" then return end
    SyncAttributeBonuses(character)
    SyncAbilitiesBonuses(character)
    if HasActiveStatus(character, "LX_CROSSBOWINIT") then
        CreateCrossbowSlowdownStat(character)
    end
end

Ext.RegisterOsirisListener("StoryEvent", 2, "before", CharacterGlobalCheck)

