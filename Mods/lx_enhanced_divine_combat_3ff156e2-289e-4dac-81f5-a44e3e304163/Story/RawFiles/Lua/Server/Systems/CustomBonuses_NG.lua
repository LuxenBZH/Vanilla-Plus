--- @class CustomStatusManager
--- Manage the creation and synchronisation of custom bonus statuses given to characters
CustomStatusManager = {
    Banned = {
        DGM_Finesse = true,
        DGM_Intelligence = true,
        DGM_NoWeapon = true,
        DGM_OneHanded = true,
        DGM_Ranged = true,
        DGM_CrossbowSlow = true,
        GM_SELECTED = true,
        GM_SELECTEDDISCREET = true,
        GM_TARGETED = true,
        HIT = true,
        INSURFACE = true,
        SHOCKWAVE = true,
        UNSHEATHED = true,
        THROWN = true,
        HEAL = true,
        LEADERSHIP = true,
        LEADERLIB_RECALC = true,
        DGM_RECALC = true,
        LX_CROSSBOWCLEAR = true
    },
    ExtendedBanList = {
        Data.Stats.CustomAttributeBonuses,
        Data.Stats.CustomAbilityBonuses,
    },
    SyncListeners = {}
}

for i, banList in pairs(CustomStatusManager.ExtendedBanList) do
    for term, values in pairs(banList) do
        CustomStatusManager.Banned["DGM_"..term] = true
    end
end

---@param name string
---@param func function
---@param priority integer|nil Default: 100
function CustomStatusManager:RegisterCharacterSyncListener(name, func, priority)
    local index = priority or 100
	while self.SyncListeners[index] do
		index = index + 1
	end
    self.SyncListeners[priority or 100] = {
        Name = name,
        Handle = func
    }
end

---@param name string
---@return boolean
function CustomStatusManager:UnregisterCharacterSyncListener(name)
    for i,listener in pairs(self.SyncListeners) do
        if listener.Name == name then
            table.remove(self.SyncListeners, i)
            return true
        end
    end
    return false
end

---@param character EsvCharacter
function CustomStatusManager:TriggerSyncListeners(character)
    for i,listener in pairs(self.SyncListeners) do
        listener.Handle(character)
    end
end

--- @param name string
--- @param stats table
--- @param template string|nil
--- @param sync boolean|nil
function CustomStatusManager:Create(name, stats, template, sync)
    if NRD_StatExists(name) then
        return Ext.Stats.Get(name)
    end
    local newPotion
    if not NRD_StatExists(name.."Potion") then
        newPotion = Ext.Stats.Create(name.."_Potion", "Potion", template)
        for field, value in pairs(stats.Potion) do
            newPotion[field] = value
        end
    else
        newPotion = Ext.Stats.Get(name.."_Potion")
    end
    local newStatus = Ext.Stats.Create(name, "StatusData", template or "DGM_BASE")
    for field, value in pairs(stats.Status) do
        newStatus[field] = value
    end
    newStatus.StatsId = newPotion.Name
    Ext.Stats.Sync(name, sync)
    Ext.Stats.Sync(newPotion.Name, sync)
    return newStatus
end

--- @param character EsvCharacter|GUID
--- @param name string
--- @param duration number
--- @param multiplier number
--- @param cap number|nil
function CustomStatusManager:Apply(character, name, duration, multiplier, cap)
    if not Ext.Stats.Get(name) then
        return
    end
    if type(character) == "string" then
        character = Ext.Entity.GetCharacter(character)
    end
    local exists = character:GetStatus(name)
    if exists and ((cap and multiplier <= cap) or not cap) and exists.StatsMultiplier == multiplier then
        return
    end
    local status = Ext.PrepareStatus(character.MyGuid, name, duration)
    if multiplier ~= 1.0 then
        status.StatsMultiplier = math.min(multiplier, cap or 9999999)
    end
    Ext.ApplyStatus(status)
    ApplyStatus(character.MyGuid, "DGM_RECALC", 0.0, 1)
end

--- @param character EsvCharacter
function CustomStatusManager:SynchronizeDGMBonuses(character)
    self:TriggerSyncListeners(character)
end

--[[
    Synchronisation hooks
]]

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("StoryEvent", 2, "before", function(character, event)
    if event ~= "DGM_GlobalStatCheck" or character == "NULL_00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
    CustomStatusManager:SynchronizeDGMBonuses(Ext.ServerEntity.GetCharacter(character))
end)

--- @param character GUID
--- @param event string
Ext.Osiris.RegisterListener("ProcObjectTimerFinished", 2, "after", function(character, event)
    if event ~= "DGM_GlobalStatCheck" or character == "00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
    CustomStatusManager:SynchronizeDGMBonuses(Ext.ServerEntity.GetCharacter(character))
end)

--- @param character GUID
--- @param status string
--- @param instigator GUID
local function CharacterStatusEventSynchronize(character, status, instigator)
    if not CustomStatusManager.Banned[status] and character ~= "NULL_00000000-0000-0000-0000-000000000000" and ObjectExists(character) == 1 then
        CustomStatusManager:SynchronizeDGMBonuses(Ext.ServerEntity.GetCharacter(character))
    end
end

Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "before", CharacterStatusEventSynchronize)
Ext.Osiris.RegisterListener("CharacterStatusRemoved", 3, "before", CharacterStatusEventSynchronize)

--- @param item GUID
--- @param character GUID
local function CharacterEquipmentEventSynchronize(item, character)
    if character == "NULL_00000000-0000-0000-0000-000000000000" or ObjectExists(character) == 0 then return end
    CustomStatusManager:SynchronizeDGMBonuses(Ext.ServerEntity.GetCharacter(character))
end

Ext.Osiris.RegisterListener("ItemEquipped", 2, "before", CharacterEquipmentEventSynchronize)
Ext.Osiris.RegisterListener("ItemUnequipped", 2, "before", CharacterEquipmentEventSynchronize)

--- @param message string
--- @param netID string
Ext.RegisterNetListener("DGM_UpdateCharacter", function(message, netID)
    local character = Ext.ServerEntity.GetCharacter(tonumber(netID))
    Osi.ProcObjectTimer(character.MyGuid, "DGM_GlobalStatCheck", 330)
end)

Ext.Osiris.RegisterListener("CharacterResurrected", 1, "before", function(character)
    CustomStatusManager:SynchronizeDGMBonuses(Ext.ServerEntity.GetCharacter(character))
end)

--[[
    Custom V++ features
]]

--- @param character EsvCharacter
CustomStatusManager:RegisterCharacterSyncListener("DGM_AttributeSync", function(character)
    for attribute, bonuses in pairs(Data.Stats.CustomAttributeBonuses) do
        local attributeValue = character.Stats[attribute] - Ext.ExtraData.AttributeBaseValue
        local status = CustomStatusManager:Create("DGM_"..attribute, bonuses)
        if attribute == "Intelligence" then
            CustomStatusManager:Apply(character, status.Name, -1.0, attributeValue, math.min(bonuses.Cap, (character.Stats.Finesse - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_FinesseAccuracyFromIntelligenceCap))
        else
            CustomStatusManager:Apply(character, status.Name, -1.0, attributeValue, bonuses.Cap)
        end
    end
end, 1)

--- @param character EsvCharacter
CustomStatusManager:RegisterCharacterSyncListener("DGM_AbilitiesSync", function(character)
    local currentAbility = GetWeaponAbility(character.Stats, character.Stats.MainWeapon)
    if currentAbility and Data.Stats.CustomAbilityBonuses[currentAbility] then
        local abilityValue = character.Stats[currentAbility]
        local status = CustomStatusManager:Create("DGM_"..currentAbility, Data.Stats.CustomAbilityBonuses[currentAbility])
        CustomStatusManager:Apply(character, status.Name, -1.0, abilityValue, Data.Stats.CustomAbilityBonuses[currentAbility].Cap)
    end
end, 2)

--- @param character EsvCharacter
CustomStatusManager:RegisterCharacterSyncListener("DGM_CrossbowPenalty", function(character)
    if character:GetStatus("LX_CROSSBOWINIT") and character.Stats.MainWeapon and character.Stats.MainWeapon.WeaponType == "Crossbow" then
        local weapon = character.Stats.MainWeapon
        local scaledPenalty = weapon.Level * Ext.ExtraData.DGM_CrossbowLevelGrowthPenalty + Ext.ExtraData.DGM_CrossbowBasePenalty
        local status = CustomStatusManager:Create("DGM_CrossbowSlow", {Potion = {Movement = -1}, Status = {StackId = "DGM_CrossbowSlow"}})
        CustomStatusManager:Apply(character, status.Name, -1.0, scaledPenalty)
    elseif character.Stats.MainWeapon and character.Stats.MainWeapon.WeaponType == "Crossbow" then
        ApplyStatus(character.MyGuid, "LX_CROSSBOWCLEAR", 0.0, 1, character.MyGuid)
    end
end, 3)

---@param target GUID|EsvCharacter
---@param statusID string
---@param duration number
---@param multiplier number
---@param fallback StatusFallbackArray|nil
function CustomStatusManager:CharacterApplyMultipliedStatus(target, statusID, duration, multiplier, fallback)
    if type(target) ~= "string" then
        target = target.MyGuid
    end
    if not NRD_StatExists(statusID) then
        self:CreateStatFromTemplate(statusID, "StatusData", fallback.Template, fallback.StatsArray, fallback.Persistance)
    end
    local status = Ext.PrepareStatus(target, statusID, duration)
    status.StatsMultiplier = multiplier
    Ext.ApplyStatus(status)
end

---@param statusID string
---@param template string
---@param statsArray table
---@param persistance boolean|nil
function CustomStatusManager:CreateStatFromTemplate(statID, statType, template, statsArray, persistance)
    local status = Ext.Stats.Create(statID, statType, template)
    for stat, value in pairs(statsArray) do
        status[stat] = value    
    end
    Ext.Stats.Sync(statID, persistance)
end