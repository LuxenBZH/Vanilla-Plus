--- @param object EsvCharacter|EclCharacter|EsvItem|EclItem
Helpers.EntityHasTag = function(object, tag)
	for _,j in ipairs(object:GetTags()) do
		if tag == j then
			return true
		end
	end
	return false
end

Helpers.Sign = function(number)
	return number > 0 and "+" or ""
end

Helpers.SignNumber = function(number)
	return number > 0 and 1 or -1
end

---@param position1 vec3
---@param position2 vec3
---@return number
Helpers.CalculateVectorDistance = function(position1, position2)
	local xDist = (position1[1] - position2[1]) * (position1[1] - position2[1])
	local yDist = (position1[2] - position2[2]) * (position1[2] - position2[2])
	local zDist = (position1[3] - position2[3]) * (position1[3] - position2[3])
	return math.sqrt(xDist + yDist + zDist)
end

if Ext.IsServer() then
	Helpers.Status = {}

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
		elseif status.StatusType == "DAMAGE" then
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
			Ext.Stats.Sync(newStatName, true)
			status.DamageStats = newStatName
			Helpers.Status.MultipliedStats[status] = newStatName
		end
		status.RequestClientSync = true -- Triggers the client refresh
		Ext.Net.BroadcastMessage("VP_MultiplyStatus", Ext.Json.Stringify({
			Character = Ext.ServerEntity.GetCharacter(status.TargetHandle).NetID,
			Status = status.NetID,
			Multiplier = multiplier,
		}))
		Helpers.Status.TriggerMultipliedStatusesListeners(status, multiplier, previousMultiplier)
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

---@param entity EsvCharacter|EsvItem|EclCharacter|EclItem
---@param tag string
Helpers.GetVariableTag = function(entity, tag)
	local tags = entity:GetTags()
	for i,j in ipairs(tags) do
		if string.starts(j, tag) then
			local value = string.gsub(j, tag.."_value_", "")
			return value
		end
	end
end

if Ext.IsServer() then
	Ext.Osiris.RegisterListener("CharacterStatusRemoved", 3, "before", function(target, status, instigator)
		if Helpers.Status.MultipliedStats[status] then
			Ext.Stats.Sync(Helpers.Status.MultipliedStats[status], false)
		end
	end)

		-------- Turn listeners (delay check)
	local TurnListeners = {
		Start = {},
		End = {}
	}

	Ext.Osiris.RegisterListener("CharacterGuarded", 1, "before", function(character)
		ObjectSetFlag(character, "HasDelayed")
	end)

	Ext.Osiris.RegisterListener("ObjectTurnEnded", 1, "before", function(character)
		if ObjectGetFlag(character, "HasDelayed") == 0 then
			for i, listener in pairs(TurnListeners.End) do
				listener.Handle(character)
			end
		end
	end)

	Ext.Osiris.RegisterListener("ObjectTurnStarted", 1, "before", function(character)
		if ObjectGetFlag(character, "HasDelayed") == 1 then
			ObjectClearFlag(character, "HasDelayed")
		else
			for i, listener in pairs(TurnListeners.Start) do
				listener.Handle(character)
			end
		end
	end)

	Helpers.RegisterTurnTrueStartListener = function(func)
		table.insert(TurnListeners.Start, {
			Name = "",
			Handle = func
		})
	end

	Helpers.RegisterTurnTrueEndListener = function(func)
		table.insert(TurnListeners.End, {
			Name = "",
			Handle = func
		})
	end

	---@param entity EsvCharacter|EsvItem
	---@param tag string
	Helpers.ClearVariableTag = function(entity, tag)
		local tags = entity:GetTags()
		for i,j in ipairs(tags) do
			if string.starts(tag, j) then
				ClearTag(entity, tag)
			end
		end
	end

	---comment
	---@param entity EsvCharacter|EsvItem
	---@param tag string
	---@param value string|number
	Helpers.SetVariableTag = function(entity, tag, value)
		Helpers.ClearVariableTag(entity, tag)
		SetTag(entity.MyGuid, tag.."_value_"..tostring(value))
	end
end

---@param str string
Helpers.SubstituteString = function(str, ...)
	local args = {...}
	local result = str

	for k, v in pairs(args) do
		if type(v) == "number" then
			if v == math.floor(v) then v = math.floor(v) end -- Formatting integers to not show .0
		end
			result = result:gsub("%["..tostring(k).."%]", v)
	end
	return result
end
	
---@param handle string
---@return string
Helpers.GetDynamicTranslationStringFromHandle = function(handle, ...)
	local args = {...}
	if handle == nil then return "" end

	local str = Ext.GetTranslatedString(handle, "Handle Error!")
	if str == "Handle Error!" then
		Helpers.VPPrint("Tooltip handle error:", "Tooltips", handle)
	end
	str = Helpers.SubstituteString(str, table.unpack(args))
	return str
end

---@param handle string
---@return string
Helpers.GetDynamicTranslationStringFromKey = function(key, ...)
	local args = {...}
	if key == nil then return "" end

	local str = Ext.L10N.GetTranslatedStringFromKey(key)
	if str == "" then
		_VError("Tooltip key error:", "Tooltips", key)
	end
	str = Helpers.SubstituteString(str, table.unpack(args))
	return str
end

--- Removes the _-1 at the end
---@param skillID string
---@return string
Helpers.GetFormattedSkillID = function(skillID)
	return string.sub(skillID, 1, string.len(skillID)-3)
end

---@param entity string
---@return boolean
Helpers.CheckEntityExistence = function(entity)
	return ObjectExists(entity) == 1
end

Helpers.GetSurfaceTypeAtPosition = function(x, z)
	local cell = Ext.Entity.GetAiGrid():GetCellInfo(x, z)
	if Ext.IsServer() then
		return cell.GroundSurface and tostring(Ext.Entity.GetSurface(cell.GroundSurface).SurfaceType) or "None"
	else
		return cell.GroundSurfaceType
	end
end

Helpers.GetCloudTypeAtPosition = function(x, z)
	local cell = Ext.Entity.GetAiGrid():GetCellInfo(x, z)
	if Ext.IsServer() then
		return cell.CloudSurface and tostring(Ext.Entity.GetSurface(cell.CloudSurface).SurfaceType) or "None"
	else
		return cell.CloudSurfaceType
	end
end

Helpers.GetSurfaceLayersAtPosition = function(x,z)
	local cell = Ext.Entity.GetAiGrid():GetCellInfo(x, z)
	if Ext.IsServer() then
		return {
			Ground = cell.GroundSurface and tostring(Ext.Entity.GetSurface(cell.GroundSurface).SurfaceType) or "None",
			Cloud = cell.CloudSurface and tostring(Ext.Entity.GetSurface(cell.CloudSurface).SurfaceType) or "None"
		}
	else
		return {
			Ground = cell.GroundSurfaceType,
			Cloud = cell.CloudSurfaceType
		}
	end
end

---Get SurfaceTypes in the radius
---@param x float
---@param z float
---@param radius integer
Helpers.GetSurfaceLayersInArea = function(x,z,radius)
	local grid = Ext.Entity.GetAiGrid()
	local layers = {
		Ground = {},
		Cloud = {}
	}
	for posx = x-radius,x+radius,0.5 do
		for posz = z-radius,z+radius,0.5 do
			local cell = grid:GetCellInfo(posx, posz)
			if Ext.IsServer() then
				-- _DS(cell)
				if cell.GroundSurface then
					for i,flag in pairs(cell.AiFlags) do
						layers.Ground[Data.SurfacesGround["Surface"..flag] and flag or "None"] = true
					end
				end
				if cell.CloudSurface then
					for i,flag in pairs(cell.AiFlags) do
						layers.Cloud[Data.SurfacesCloud["Surface"..flag] and flag or "None"] = true
					end
				end
				-- layers.Ground[cell.GroundSurface and tostring(Ext.Entity.GetSurface(cell.GroundSurface).SurfaceType) or "None"] = true
				-- layers.Cloud[cell.CloudSurface and tostring(Ext.Entity.GetSurface(cell.CloudSurface).SurfaceType) or "None"] = true
			else
				-- local ground = cell.GroundSurfaceType or "None"
				-- local cloud = cell.CloudSurfaceType or "None"
				layers.Ground[cell.GroundSurfaceType or "None"] = true
				layers.Cloud[cell.CloudSurfaceType or "None"] = true
			end
		end
	end
	return layers
end

--- Helper for projectiles
---@param from table|GUID
---@param to table|GUID
---@param skillId string
---@param additionalProperties table|nil
Helpers.LaunchProjectile = function(from, to, skillId, additionalProperties)
	NRD_ProjectilePrepareLaunch()
	NRD_ProjectileSetInt("CasterLevel", 3);
	if type(from) == "table" then
		NRD_ProjectileSetVector3("SourcePosition", from[1], from[2]+1, from[3])
	else
		NRD_ProjectileSetGuidString("SourcePosition", from)
	end
	if type(to) == "table" then
		NRD_ProjectileSetVector3("TargetPosition", to[1], to[2], to[3])
	else
		NRD_ProjectileSetGuidString("TargetPosition", to)
	end
	NRD_ProjectileSetString("SkillId", skillId)
	if additionalProperties then
		for propertyType,data in pairs(additionalProperties) do
			for field,value in pairs(data) do
				Data.OsirisProjectileFunctions[propertyType](field, value)
			end
		end
	end
	NRD_ProjectileLaunch()
end

--- @param character EsvCharacter|EclCharacter
--- @param damageType DamageType
Helpers.CharacterGetAbsorbShield = function(character, damageType)
	return character:GetStatus("LX_SHIELD_"..string.upper(damageType))
end

Helpers.StatusGetAbsorbShieldElement = function(status)
	if string.starts(status, "LX_SHIELD_") then
		local dmgType = string.gsub(status, "LX_SHIELD_", "")
		return Ext.L10N.GetTranslatedString(Data.Text.TranslatedKeys.DamageTypes[dmgType:sub(1, 1):upper() .. dmgType:sub(2):lower()], "")
	else
		return nil
	end
end

Helpers.SimpleHash16 = function(input)
    local hash = 0
    for i = 1, #input do
        local char = string.byte(input, i)
        hash = (hash * 31 + char) % 0xFFFFFFFF
    end

    -- Convert hash to hexadecimal string
    local hex = string.format("%08x", hash)

    -- Ensure the result is 16 characters long
    -- by repeating or truncating as necessary
    local digest = (hex .. hex):sub(1, 16)

    return digest
end

---Get the position of a point on the line drawn by 2 points with a specific distance from the first point
---@param pos1 number[]
---@param pos2 number[]
---@param distance number
---@return number[]
Helpers.CalculatePositionFromDirection = function(pos1, pos2, distance)
	 local dx = pos2[1] - pos1[1]
	 local dz = pos2[3] - pos1[3]
 
	 local magnitude = math.sqrt(dx^2 + dz^2)
 
	 local normX = dx / magnitude
	 local normY = dz / magnitude
 
	 local cx = pos1[1] + distance * normX
	 local cz = pos1[3] + distance * normY

	 local cy = Ext.Entity.GetCurrentLevel().AiGrid:GetHeight(cx, cz)
	 return {cx, cy, cz}
end

Helpers.TableShiftLeft = function(t)
	for i = 1, #t - 1 do
        t[i] = t[i + 1]
    end
    t[#t] = nil
end