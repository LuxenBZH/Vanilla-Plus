---@param e EsvLuaBeforeStatusApplyEvent
Ext.Events.BeforeStatusApply:Subscribe(function(e)
	if e.Status.StatusType == "DAMAGE" then
		local instigator = Ext.Utils.IsValidHandle(e.Status.StatusSourceHandle) and Ext.ServerEntity.GetGameObject(e.Status.StatusSourceHandle) or nil
		local target = Ext.ServerEntity.GetGameObject(e.Status.TargetHandle)
		local applied
		local witsMultiplier = 1.0
		if Helpers.IsCharacter(instigator) then
			applied = target:GetStatus(e.Status.StatusId)
			witsMultiplier = 1.0 + (instigator.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsDotBonus / 100
		end
		if applied then
			local currentDamageMultiplier = tonumber(string.gsub(applied.DamageStats, ".*_x", "") or 1.0)
			if currentDamageMultiplier and currentDamageMultiplier > witsMultiplier then
				Helpers.Timer.Start(33, function(targetHandle, statusHandle, multiplier)
					Helpers.Status.MultiplyDoT(Ext.ServerEntity.GetStatus(targetHandle,statusHandle), multiplier)
				end, nil, e.Status.TargetHandle, e.Status.StatusHandle, currentDamageMultiplier)
			end
			return
		elseif witsMultiplier <= 0 then
			e.PreventStatusApply = true
			return
		end
		if witsMultiplier ~= 1.0 then
			Helpers.Timer.Start(33, function(targetHandle, statusHandle, multiplier)
				if Ext.Utils.IsValidHandle(statusHandle) then
					Helpers.Status.MultiplyDoT(Ext.ServerEntity.GetStatus(targetHandle,statusHandle), multiplier)
				end
			end, nil, e.Status.TargetHandle, e.Status.StatusHandle, witsMultiplier)
		end
	end
end, {Priority=1, Once=false})