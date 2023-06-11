Ext.Osiris.RegisterListener("NRD_OnStatusAttempt", 4, "before", function(target, statusID, statusHandle, instigator)
    local entry, potion
    if statusID == "CONSUME" then
        potion = Ext.Stats.Get(Ext.GetStatus(target, statusHandle).StatsIds[1].StatsId)
    else
        entry = Ext.Stats.Get(statusID, nil, false, nil)
        if entry and entry.StatsId and entry.StatsId ~= "" then
            potion = Ext.Stats.Get(entry.StatsId)
        end
    end 
    local target = Ext.Entity.GetCharacter(target)
    if potion and potion.VP_AbsorbShieldValue ~= 0 then
        local shield = target:GetStatus("LX_SHIELD_"..string.upper(potion.VP_AbsorbShieldType))
        if shield then
            shield.StatsMultiplier = shield.StatsMultiplier + Helpers.ScalingFunctions[potion.VP_AbsorbShieldScaling](Ext.Entity.GetCharacter(target).Stats.Level) * (potion.VP_AbsorbShieldValue / 100)
            shield.LifeTime = shield.LifeTime + potion.Duration * 6.0
        else
            local shield = Ext.PrepareStatus(target, "LX_SHIELD_"..string.upper(potion.VP_AbsorbShieldType), potion.Duration * 6.0)
            shield.StatsMultiplier = Helpers.ScalingFunctions[potion.VP_AbsorbShieldScaling](Ext.Entity.GetCharacter(target).Stats.Level) * (potion.VP_AbsorbShieldValue / 100)
            Helpers.VPPrint(shield.StatsMultiplier, "AbsorbShield")
            Ext.ApplyStatus(shield)
        end
    end
end)

---@param target EsvCharacter
---@param hit EsvStatusHit
---@param handle integer
function AbsorbShieldProcessDamage(target, instigator, hit)
    local damageList = hit.Hit.DamageList:ToTable()
    for index, array in pairs(damageList) do
        local damageType = tostring(array.DamageType)
		local shield = Helpers.CharacterGetAbsorbShield(target, damageType)
		if shield then
			if shield.StatsMultiplier > array.Amount then
                hit.Hit.DamageList:Clear(damageType)
                HitHelpers.HitAddDamage(hit.Hit, target, instigator, damageType, -array.Amount)
                shield.StatsMultiplier = shield.StatsMultiplier - array.Amount
                Helpers.VPPrint("Hit absorbed !", "DamageControl:AbsorbShield")
            else
                HitHelpers.HitAddDamage(hit.Hit, target, instigator, damageType, -math.floor(shield.StatsMultiplier))
                RemoveStatus(target.MyGuid, shield.StatusId)
            end
        end
	end
end