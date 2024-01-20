
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
        if s.StatusType == "HEAL" and stat.HealStat == "Vitality" and Helpers.IsCharacter(target) and target.Stats.TALENT_Zombie then
            HealToDamage(target, s, amount, healer)
        else
            --- HEALING statuses apply HEAL which needs to prune the ability bonus again because it's reapplied a second time
            amount = s.StatusType == "HEALING" and math.floor(amount / Data.Stats.HealAbilityBonus[stat.HealStat](Ext.ServerEntity.GetCharacter(instigator))) or amount
            s.HealAmount = amount
        end
    elseif status == "LIFESTEAL" then
        s.HealAmount = Ext.Utils.Round(s.HealAmount / (1 + healer.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint / 100))
    elseif status == "HEAL" and Helpers.IsCharacter(target) and target.Stats.TALENT_Zombie then
        s.HealAmount = s.HealAmount * (1+Game.Math.GetDamageBoostByType(healer.Stats, "Physical"))
    end
end)

---------- Celerity free movement attribution
---@param character GUID
---@param status string
---@param instigator GUID
Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "before", function(character, status, instigator)
    if not Data.Stats.BannedStatusesFromChecks[status] and status ~= "" and NRD_StatExists(status) == 1 then
        local character = Ext.ServerEntity.GetCharacter(character)
        local status = character:GetStatus(status)
        local statEntry = Ext.Stats.Get(status.StatsId)
        if statEntry.VP_Celerity ~= 0 then
            character.PartialAP = character.PartialAP + Data.Math.ComputeCelerityValue(statEntry.VP_Celerity, character)
        end
    end
end)

----------
---------- Free Movement per turn
Helpers.RegisterTurnTrueStartListener(function(character)
    local char = Ext.ServerEntity.GetCharacter(character)
    local movement = Data.Math.GetCharacterMovement(char)
    local celerity = Data.Math.ComputeCelerityValue(Data.Math.ComputeCharacterCelerity(char), char)
    if movement.Movement >= movement.BaseMovement then
        char.PartialAP = char.PartialAP + 100/movement.Movement + celerity
    else
        char.PartialAP = char.PartialAP + movement.Movement/movement.BaseMovement * 100/movement.Movement + celerity
    end
end)