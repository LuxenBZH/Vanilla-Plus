
---comment
---@param target EsvCharacter
---@param healStatus EsvStatusHeal
---@param amount integer
local function HealToDamage(target, healStatus, amount, instigator)
    if healStatus.StatusId ~= "HEAL" then
        healStatus.HealAmount = 1
    else
        healStatus.HealAmount = -1
    end
    local hit = Ext.PrepareStatus(target.MyGuid, "HIT", 0) ---@type EsvStatusHit
    hit.HitReason = 6
    hit.Hit.DeathType = "DoT"
    hit.Hit.EffectFlags = 1
    HitHelpers.HitAddDamage(hit.Hit, target, healer, "Physical", Ext.Utils.Round(amount*(1+Game.Math.GetDamageBoostByType(instigator.Stats, "Physical"))))
    Ext.ApplyStatus(hit)
end

---------- Wisdom healing increase
--- @param target string GUID
--- @param instigator string GUID
--- @param amount integer
--- @param handle double StatusHandle
Ext.Osiris.RegisterListener("NRD_OnStatusAttempt", 4, "before", function(target, status, handle, instigator)
    if instigator == "NULL_00000000-0000-0000-0000-000000000000" then return end -- Spams the console in few cases otherwise
    local s = Ext.ServerEntity.GetStatus(target, handle) --- @type EsvStatus|EsvStatusHeal|EsvStatusHealing
    if ObjectIsCharacter(instigator) == 0 then return end
    local healer
    -- Fix the double bonus from shared healings
    if status == "HEAL" and s.HealEffect == "HealSharing" then
        healer = Ext.ServerEntity.GetCharacter(instigator)
        if s.HealType == "PhysicalArmor" then
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint / 100))
        elseif s.HealType == "MagicArmor" then
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint / 100))
        else
            s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint / 100))
        end
    end
    local target = Ext.ServerEntity.GetGameObject(target)
    healer = Ext.ServerEntity.GetCharacter(instigator)
    -- Wisdom bonus to any other heal that isn't LIFESTEAL
    -- HEAL is the proxy status used for the healing value, the original status will have a healing value equal to 0
    -- You need to recalculate the healing value manually, and the following HEAL proxies will duplicate that value
    -- Note : you cannot track the origin of HEAL proxies. In case where a custom value would be needed for each tick, applying a new status each tick could be a workaround
    if (s.StatusType == "HEAL" or s.StatusType == "HEALING") and status ~= "HEAL" and status ~= "LIFESTEAL" then
        local stat = Ext.Stats.Get(s.StatusId)
        if stat.HealType ~= "Qualifier" then return end
        local amount = Data.Math.GetHealScaledWisdomValue(stat, healer)
        --- HEAL statuses with a s.HealAmount modified manually will heal undeads for some reason unless it is set to 0
        --- HEALING statuses don't need this hack because they apply HEAL independently
        if s.StatusType == "HEAL" and stat.HealStat == "Vitality" and Helpers.IsCharacter(target) and (target.Stats.TALENT_Zombie or target:GetStatus("DECAYING_TOUCH")) then
            HealToDamage(target, s, amount, healer)
        else
            --- HEALING statuses apply HEAL which needs to prune the ability bonus again because it's reapplied a second time
            amount = s.StatusType == "HEALING" and math.floor(amount / Data.Stats.HealAbilityBonus[stat.HealStat](Ext.ServerEntity.GetCharacter(instigator))) or amount
            s.HealAmount = amount
        end
    elseif status == "LIFESTEAL" then
        s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint / 100))
    elseif status == "HEAL" and Helpers.IsCharacter(target) and (target.Stats.TALENT_Zombie or target:GetStatus("DECAYING_TOUCH")) then
        s.HealAmount = Ext.Utils.Round(s.HealAmount * (1+Game.Math.GetDamageBoostByType(healer.Stats, "Physical")))
    end
end)

---------- Celerity PartialAP recalculation every time a status influencing Movement stat or Celerity is added or removed
---@param character GUID
---@param status string
---@param removed boolean
local function CelerityRecalcStatusEvent(character, status, removed)
    character = GetUUID(character)
    if CharacterIsInCombat(character) == 1 and CombatGetActiveEntity(CombatGetIDForCharacter(character)) ~= character and not Data.Stats.BannedStatusesFromChecks[status] and status ~= "" and NRD_StatExists(status) then
        local character = Ext.ServerEntity.GetCharacter(character)
        local status = removed and status or character:GetStatus(status)
        if status then
            if removed and Ext.Stats.Get(status).StatsId == "" then return end
            local statEntry = Ext.Stats.Get(not removed and status.StatsId or Ext.Stats.Get(status).StatsId)
            if statEntry.Movement ~= 0 or statEntry.MovementSpeedBoost ~= 0 or statEntry.VP_Celerity ~= 0 then
                character.PartialAP = Data.Math.CharacterCalculatePartialAP(character)
            end
        end
    end
end

---@param status EsvStatus
Helpers.Status.RegisterMultipliedStatus("All", function(status, _, _)
    if NRD_StatExists(status.StatsId) then
        local character = Ext.ServerEntity.GetCharacter(status.TargetHandle)
        CelerityRecalcStatusEvent(character.MyGuid, status.StatusId)
    end
end)

---@param character GUID
---@param status string
---@param instigator GUID
Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "after", function(character, status, instigator)
    CelerityRecalcStatusEvent(character, status)
end)

Ext.Osiris.RegisterListener("CharacterStatusRemoved", 3, "before", function(character, status, instigator)
    CelerityRecalcStatusEvent(character, status, true)
end)

---@param e EsvLuaStatusDeleteEvent
-- Ext.Events.BeforeStatusDelete:Subscribe(function(e)
--     _P(e.Status.StatusId, e.Status.StatusType, e.Status.StatsId)
--     if e.Status.StatusType == "CONSUME" and NRD_StatExists(e.Status.StatsId) then
--         local object = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle)
--         if Helpers.IsCharacter(object) then
--             _P("CALL")
--             CelerityRecalcStatusEvent(object.MyGuid, e.Status.StatusId)
--         end
--     end
-- end)

Ext.Osiris.RegisterListener("ObjectTurnEnded", 1, "after", function(object)
    if ObjectIsCharacter(object) == 1 then
        local character = Ext.ServerEntity.GetCharacter(object)
        character.PartialAP = Data.Math.CharacterCalculatePartialAP(character)
    end
end)

----------
---------- Critical Multiplier management from statuses
--- The game does not support the usage of CriticalDamage field from Weapon stats to increase the critical multiplier from statuses
--- This workaround uses the extender to set the current weapon critical multiplier as a proxy to the statuses bonuses
Helpers.Status.RegisterCleanStatusAppliedListener("CriticalMultiplierProxy", function(character, status, instigator)
    -- _VPrint("Clean status applied listener (ALL)", "CustomAttributesServer", status)
    local target = Helpers.ServerSafeGetCharacter(character)
    if not target then return end
    local status = target:GetStatus(status)
    local statEntry = status and Ext.Stats.Get(status.StatusId) or nil
    if statEntry and statEntry.StatsId ~= "" then
        local potionEntry = Ext.Stats.Get(statEntry.StatsId) or nil
        if potionEntry and potionEntry.VP_CriticalMultiplier ~= 0 then
            local target = Ext.ServerEntity.GetGameObject(status.TargetHandle)
            if Helpers.IsCharacter(target) then
                local _,critMult = Data.Math.ComputeStatIntegerFromStatus(target, "VP_CriticalMultiplier")
                -- Helpers.VPPrint("Applying new crit multiplier to the weapon (adding)...", "CustomAttributesServer", target.Stats.MainWeapon.StatsEntry.CriticalDamage +critMult)
                target.Stats.MainWeapon.DynamicStats[1].CriticalDamage = target.Stats.MainWeapon.StatsEntry.CriticalDamage + critMult
                Ext.Net.BroadcastMessage("VP_RecalculateStatusCritMultBonus", tostring(target.NetID))
            end
        end
    end
end)

---@param status EsvStatus
---@param multiplier number
Helpers.Status.RegisterMultipliedStatus("All", function(status, multiplier, previousMultiplier)
    -- _VPrint("Multiplied status listener (ALL)", "CustomAttributesServer", status.StatusId)
    local statEntry = Ext.Stats.Get(status.StatusId)
    if statEntry.StatsId ~= "" then
        local potionEntry = Ext.Stats.Get(statEntry.StatsId)
        if potionEntry and potionEntry.VP_CriticalMultiplier ~= 0 then
            local _,critMult = Data.Math.ComputeStatIntegerFromStatus(target, "VP_CriticalMultiplier")
            local character = Ext.ServerEntity.GetCharacter(status.TargetHandle)
            character.Stats.MainWeapon.DynamicStats[1].CriticalDamage = character.Stats.MainWeapon.StatsEntry.CriticalDamage + critMult
            Ext.Net.BroadcastMessage("VP_RecalculateStatusCritMultBonus", tostring(target.NetID))
        end
    end
end)

---@param e ExtenderBeforeStatusDeleteEventParams
Ext.Events.StatusDelete:Subscribe(function(e)
    ---TODO: Deal with CONSUME
    -- _VPrint("Status delete event (ALL)", "CustomAttributesServer", e.Status.StatusId)
    if not Data.Stats.BannedStatusesFromChecks[e.Status.StatusId] or e.Status.StatusId == "DGM_Finesse" then
        local statEntry = Ext.Stats.Get(e.Status.StatusId)
        if statEntry and statEntry.StatsId ~= "" then
            local potionEntry = Ext.Stats.Get(statEntry.StatsId)
            if potionEntry and potionEntry.VP_CriticalMultiplier ~= 0 then
                local target = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle)
                if Helpers.IsCharacter(target) then
                    local _,critMult = Data.Math.ComputeStatIntegerFromStatus(target, "VP_CriticalMultiplier")
                    -- Helpers.VPPrint("Applying new crit multiplier to the weapon (adding)...", "CustomAttributesServer", target.Stats.MainWeapon.StatsEntry.CriticalDamage +critMult)
                    target.Stats.MainWeapon.DynamicStats[1].CriticalDamage = target.Stats.MainWeapon.StatsEntry.CriticalDamage + critMult
                    Ext.Net.BroadcastMessage("VP_RecalculateStatusCritMultBonus", tostring(target.NetID))
                end
            end
        end
    end
end)

Ext.Osiris.RegisterListener("ItemUnEquipped", 2, "before", function(item, character)
    if ObjectExists(item) == 0 then return end
    local item = Ext.ServerEntity.GetItem(item)
    if item.Stats.ItemSlot == "Weapon" then
        item.Stats.DynamicStats[1].CriticalDamage = item.Stats.StatsEntry.CriticalDamage
        Ext.Net.BroadcastMessage("VP_ResetWeaponCriticalMultiplier", tostring(item.NetID))
    end
end)