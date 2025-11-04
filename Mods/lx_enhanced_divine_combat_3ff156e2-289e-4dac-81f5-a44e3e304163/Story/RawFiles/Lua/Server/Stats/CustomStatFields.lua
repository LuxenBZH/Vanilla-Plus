--- VP_RecoverLastTurn-X-Damage
local _RecoverTypes = {
    VP_RecoverLastTurnArmorDamage = true,
    VP_RecoverLastTurnMagicArmorDamage = true,
    VP_RecoverLastTurnVitalityDamage = true
} 

local _LastTurnDamageTakenType = {
    VP_RecoverLastTurnArmorDamage = "LX_LastTurnArmorDamageTaken",
    VP_RecoverLastTurnMagicArmorDamage = "LX_LastTurnMagicArmorDamageTaken"
}

local _LastTurnDamageRecoveryType = {
    VP_RecoverLastTurnArmorDamage = "PhysicalArmor",
    VP_RecoverLastTurnMagicArmorDamage = "MagicArmor"
}
---@param character EsvCharacter
---@param healType string
---@param amount number
---@param sourceHandle ObjectHandle|nil
local function ApplyLastTurnDamageRecovery(character, healType, amount, sourceHandle)
    local damageTaken = character.UserVars[_LastTurnDamageTakenType[healType]] or 0
    if damageTaken > 0 and amount > 0 then
        _P("Healing:",math.ceil(damageTaken * amount / 100))
        local heal = Ext.PrepareStatus(character.MyGuid, "HEAL", 0) ---@type EsvStatusHeal
        heal.HealType = _LastTurnDamageRecoveryType[healType]
        heal.HealAmount = math.ceil(damageTaken * amount / 100)
        heal.StatusSourceHandle = sourceHandle
        _DS(heal)
        Ext.ApplyStatus(heal)
    end
end


Helpers.RegisterTurnTrueStartListener(function(object)
    if ObjectIsCharacter(object) == 1 then
        local character = Ext.ServerEntity.GetCharacter(object)
        for i,statusName in pairs(character:GetStatuses()) do
            local statusEntry = Data.EngineStatus[statusName] and nil or Ext.Stats.Get(statusName, character.Stats.Level, false) ---@type EsvStatus
            _P(statusEntry.StatusType)
            if statusEntry and statusEntry.StatusType == "HEALING"then
                if statusEntry.HealingEvent == "OnTurn" or statusEntry.HealingEvent == "OnApplyAndTurn" then
                    for recoverType, j in pairs(_RecoverTypes) do
                        if statusEntry[recoverType] > 0 then
                            ApplyLastTurnDamageRecovery(character, recoverType, statusEntry[recoverType], character:GetStatus(statusName).StatusSourceHandle)
                        end
                    end
                end
            end
        end
    end
end)

Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "after", function(character, status, instigator)
    if not Data.EngineStatus[status] then
        local statEntry = Ext.Stats.Get(status, nil, false)
        if statEntry.StatusType == "HEAL" or (statEntry.StatusType == "HEALING" and (statEntry.HealingEvent == "OnApply" or statEntry.HealingEvent == "OnApplyAndTurn")) then
            local character = Ext.ServerEntity.GetCharacter(character)
            for recoverType, j in pairs(_RecoverTypes) do
                if statEntry[recoverType] > 0 then
                    ApplyLastTurnDamageRecovery(character, recoverType, statEntry[recoverType], character:GetStatus(status).StatusSourceHandle)
                end
            end
        end
    end
end)