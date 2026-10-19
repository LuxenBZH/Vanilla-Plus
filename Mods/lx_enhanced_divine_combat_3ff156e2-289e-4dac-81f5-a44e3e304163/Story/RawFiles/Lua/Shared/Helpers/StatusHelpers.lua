Helpers.Status = {}

if Ext.IsServer() then
	Helpers.Status.MultipliedStats = {}

	Helpers.Status.MultipliedStatusesListeners = {
		All = {}
	}

	function Helpers.Status.RegisterMultipliedStatus(statusID, func)
		if statusID == "All" then
			table.insert(Helpers.Status.MultipliedStatusesListeners.All, func)
		elseif not Helpers.Status.MultipliedStatusesListeners[statusID] then
			Helpers.Status.MultipliedStatusesListeners[statusID] = {func}
		else
			table.insert(Helpers.Status.MultipliedStatusesListeners[statusID], func)
		end
	end

	---@param status EsvStatus
	---@param multiplier number
	---@param previousMultiplier number
	function Helpers.Status.TriggerMultipliedStatusesListeners(status, multiplier, previousMultiplier)
		if not Helpers.Status.MultipliedStatusesListeners then
			Helpers.Status.MultipliedStatusesListeners = {}
			return
		end
		local handlers = Helpers.Status.MultipliedStatusesListeners[status.StatusId]
		if handlers then
			for i,func in pairs(handlers) do
				func(status, multiplier, previousMultiplier)
			end
			for i,func in pairs(Helpers.Status.MultipliedStatusesListeners.All) do
				func(status, multiplier, previousMultiplier)
			end
		end
	end

	---Multiply a status, including damage if there is a damage entry
	---@param status EsvStatus
	Helpers.Status.Multiply = function(status, multiplier)
		local previousMultiplier = status.StatsMultiplier
		status.StatsMultiplier = multiplier
		if status.StatusType == "CONSUME" then
			local stat = Ext.Stats.Get(Ext.Stats.Get(status.StatusId).StatsId, nil, false)
			if stat and stat["Damage Multiplier"] > 0 then
				local character = Ext.ServerEntity.GetCharacter(status.TargetHandle)
				character.UserVars.LX_StatusConsumeMultiplier = multiplier
			end
			-- local newStatName = stat.Name.."_x"..Ext.Utils.Round(multiplier)
			-- Ext.Stats.Create(newStatName, "Potion", stat.Name)
			-- local multipliedStat = Ext.Stats.Get(newStatName) ---@type StatEntryPotion
			-- multipliedStat["Damage Multiplier"] = Ext.Utils.Round(multipliedStat.Damage * multiplier)
			-- status.StatsIds[1].StatsId = newStatName
			-- status.StatsId = newStatName
			-- Ext.Stats.Sync(newStatName, true)
			-- Helpers.Status.MultipliedStats[status] = newStatName
		end
		status.RequestClientSync = true -- Triggers the client refresh
		Ext.Net.BroadcastMessage("VP_MultiplyStatus", Ext.Json.Stringify({
			Character = Ext.ServerEntity.GetCharacter(status.TargetHandle).NetID,
			Status = status.NetID,
			Multiplier = multiplier,
		}))
		-- Trigger the dynamic stat recomputation on server side
		if status.StatsId ~= "" then
			Helpers.Timer.Start(10, function(characterHandle, statusHandle, statsId)
				local status = Ext.ServerEntity.GetStatus(characterHandle, statusHandle)
				status.StatsId = "" -- The statsId will be recovered to its previous value automatically (client communication?)
			end, nil, status.TargetHandle, status.StatusHandle, status.StatsId)
		end
		Helpers.Status.TriggerMultipliedStatusesListeners(status, multiplier, previousMultiplier)
	end

	Helpers.Status.MultiplyDoT = function(status, multiplier)
		if status.StatusType == "DAMAGE" then
			if status.DamageStats == "" then
				status.DamageStats = Ext.Stats.Get(status.StatusId).DamageStats
			end
			if status.OriginalWeaponStatsId == "" then
				status.OriginalWeaponStatsId = status.DamageStats
			end
			local stat = Ext.Stats.Get(status.OriginalWeaponStatsId)
			local newStatName = stat.Name.."_x"..tostring(multiplier)
			if not Ext.Stats.Get(newStatName, nil, false) then
				Ext.Stats.Create(newStatName, "Weapon", stat.Name)
			end
			local multipliedStat = Ext.Stats.Get(newStatName) ---@type StatEntryWeapon
			multipliedStat.DamageFromBase = Ext.Utils.Round(stat.DamageFromBase * multiplier)
			Ext.Stats.Sync(newStatName, false)
			status.DamageStats = newStatName
			Helpers.Status.MultipliedStats[status] = newStatName
		end
		status.RequestClientSync = true -- Triggers the client refresh
		if status.StatsId ~= "" then
			Helpers.Timer.Start(10, function(characterHandle, statusHandle, statsId)
				local status = Ext.ServerEntity.GetStatus(characterHandle, statusHandle)
				status.StatsId = "" -- The statsId will be recovered to its previous value automatically (client communication?)
			end, nil, status.TargetHandle, status.StatusHandle, status.StatsId)
		end
	end

	Helpers.Status.StatusAppliedListeners = {}
	---Wrapper to the Osiris function to exclude automatically non-existing or banned statuses
	---@param character any
	---@param status any
	---@param instigator any
	Helpers.Status.RegisterCleanStatusAppliedListener = function(name, func)
		Helpers.Status.StatusAppliedListeners[name] = func
	end

	Ext.Osiris.RegisterListener("CharacterStatusApplied", 3, "before", function(character, status, instigator)
		--- string.starts act reversed ???
		if not Data.Stats.BannedStatusesFromChecks[status] or status == "DGM_Finesse" and status ~= "" and string.starts(status, "LX_AURATARGET") then
			for name, func in pairs(Helpers.Status.StatusAppliedListeners) do
				func(character,status,instigator)
			end
		end
	end)
end