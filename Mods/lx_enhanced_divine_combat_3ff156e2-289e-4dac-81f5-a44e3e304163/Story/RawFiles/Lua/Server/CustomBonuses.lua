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
        if HasActiveStatus(char.MyGuid, statusName) == 0 then
            ApplyStatus(char.MyGuid, statusName, -1, 1)
        end
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

Ext.RegisterOsirisListener("ItemUnequipped", 2, "before", function(item, character)
    if ObjectExists(item) == 0 then return end
    local item = Ext.GetItem(item)
    if item.Stats.WeaponType == "Crossbow" then
        ApplyStatus(character, "LX_CROSSBOWCLEAR", 6.0, 1)
    end
end)

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
            if HasActiveStatus(char.MyGuid, statusName) == 0 then
                ApplyStatus(char.MyGuid, statusName, -1, 1)
            end
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
    TwoHanded = {},
    Ranged = {RangeBoost=Ext.ExtraData.DGM_RangedRangeBonus},
    DualWielding = {},
    None = {}
}

--- @param character EsvCharacter
local function CreateEmptyWeaponBonus(character)
    if NRD_StatExists("DGM_NoWeapon") then
        if HasActiveStatus(character.MyGuid, "DGM_NoWeapon") == 0 then
            ApplyStatus(character.MyGuid, "DGM_NoWeapon", -1, 1)
        end
    else
        local newStatus = Ext.CreateStat("DGM_NoWeapon", "StatusData", "DGM_BASE")
        newStatus["StackId"] = "DGM_WeaponAbility"
        newStatus["StackPriority"] = 1
        Ext.SyncStat(newStatus.Name, false)
        ApplyStatus(character.MyGuid, "DGM_NoWeapon", -1, 1)
    end
    return
end

function SyncAbilitiesBonuses(char)
    if ObjectExists(char) == 0 then return end
    -- Ext.Print("Abilities punctual check")
    char = Ext.GetCharacter(char)
    if char == nil then return end
    local ability = GetWeaponAbility(char.Stats, char.Stats.MainWeapon)
    -- Ext.Print(ability)
    if ability == nil then
        CreateEmptyWeaponBonus(char)
        return
    end
    local charAbi = math.floor(char.Stats[ability])
    local statusName = "DGM_"..ability.."_"..charAbi
    if NRD_StatExists(statusName) then
        if HasActiveStatus(char.MyGuid, statusName) == 0 then
            ApplyStatus(char.MyGuid, statusName, -1, 1)
        end
    else
        local bonuses = customAbilityBonuses[ability]
        if GetTableSize(bonuses) == 0 then CreateEmptyWeaponBonus(char) end
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
    if event ~= "DGM_GlobalStatCheck" or character == "NULL_00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
    -- Ext.Print("Global check")
    SyncAttributeBonuses(character)
    SyncAbilitiesBonuses(character)
    if HasActiveStatus(character, "LX_CROSSBOWINIT") then
        CreateCrossbowSlowdownStat(character)
    else
        ApplyStatus(character, "LX_CROSSBOWCLEAR", 6.0, 1)
    end
    CheckAllTalents(character)
    ManageMemory(character, Ext.GetCharacter(character).Stats.TALENT_Memory)
end

Ext.RegisterOsirisListener("StoryEvent", 2, "before", CharacterGlobalCheck)

local function CharacterPunctualCheck(character)
    if character == "NULL_00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
    -- Ext.Print("Punctual check")
    SyncAttributeBonuses(character)
    SyncAbilitiesBonuses(character)
    ManageMemory(character, Ext.GetCharacter(character).Stats.TALENT_Memory)
end

bannedStatusTemplates = {
    "DGM_Finesse",
    "DGM_Intelligence",
    "DGM_NoWeapon",
    "DGM_OneHanded",
    "DGM_Ranged",
    "DGM_CrossbowSlow",
    "GM_SELECTED",
    "GM_SELECTEDDISCREET",
    "GM_TARGETED",
    "HIT",
    "INSURFACE",
    "SHOCKWAVE",
    "UNSHEATHED",
    "THROWN",
    "HEAL",
    "LEADERSHIP"
}

local function StatusCharacterPunctualCheck(char, status, causee)
    -- Ext.Print(char, status, causee)
    for i,ban in pairs(bannedStatusTemplates) do
        if string.find(status, ban) ~= nil then return end
    end
    CharacterPunctualCheck(char)
end

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", StatusCharacterPunctualCheck)
Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "before", StatusCharacterPunctualCheck)

local function EquipmentCharacterPunctualCheck(item, char)
    CharacterPunctualCheck(char)
end

Ext.RegisterOsirisListener("ItemEquipped", 2, "before", EquipmentCharacterPunctualCheck)
Ext.RegisterOsirisListener("ItemUnequipped", 2, "before", EquipmentCharacterPunctualCheck)

local currentChar

local function CheckStatChangeNetID(message, netID)
    local char = Ext.GetCharacter(tonumber(netID))
    currentChar = char.MyGuid
	TimerLaunch("DGM_UIStatCheck", 330) -- Below 10 frames would actually trigger before the stat change
end

Ext.RegisterNetListener("DGM_UpdateCharacter", CheckStatChangeNetID)

-- local function CheckStatChangeNetIDFromItem(message, netID)
--     Ext.Print(netID)
--     local char = Ext.GetItem(tonumber(netID))
--     Ext.Print(char)
--     -- currentChar = Ext.GetCharacter(char.OwnerHandle)
-- 	-- TimerLaunch("DGM_UIStatCheck", 33)
-- end

-- Ext.RegisterNetListener("DGM_UpdateCharacterFromItem", CheckStatChangeNetIDFromItem)

local function CheckStatChangeTimer(timer)
    if timer ~= "DGM_UIStatCheck" then return end
    CharacterPunctualCheck(currentChar)
end

Ext.RegisterOsirisListener("TimerFinished", 1, "before", CheckStatChangeTimer)

local function CombatCharacterPunctualCheck(...)
    local params = {...}
    if ObjectIsCharacter(params[1]) == 0 then return end
    CharacterPunctualCheck(params[1])
end

Ext.RegisterOsirisListener("ObjectTurnStarted", 1, "before", CombatCharacterPunctualCheck)
Ext.RegisterOsirisListener("ObjectEnteredCombat", 2, "before", CombatCharacterPunctualCheck)

local function ResurrectGlobalCheck(character)
    CharacterGlobalCheck(character, "DGM_GlobalStatCheck")
end

Ext.RegisterOsirisListener("CharacterResurrected", 1, "before", ResurrectGlobalCheck)