_P("Loaded CharacterHelpers.lua")

Helpers.NullGUID = "NULL_00000000-0000-0000-0000-000000000000"

Helpers.Character = {}

--- @param object IEoCServerObject | IEoCClientObject
Helpers.IsCharacter = function(object)
	if Ext.IsServer() then
		return getmetatable(object) == "esv::Character"
	else
		return getmetatable(object) == "ecl::Character"
	end
end

--- @param object IEoCServerObject | IEoCClientObject
Helpers.IsItem = function(object)
	if Ext.IsServer() then
		return getmetatable(object) == "esv::Item"
	else
		return getmetatable(object) == "ecl::Item"
	end
end

--- @param character EsvCharacter
Helpers.HasCounterAttacked = function(character)
	local combat = Ext.ServerEntity.GetCombat(CombatGetIDForCharacter(character.MyGuid))
	if combat then
		for i, team in pairs(combat:GetNextTurnOrder()) do
			if team.Character.MyGuid == character.MyGuid then
				return team.EntityWrapper.CombatComponentPtr.CounterAttacked
			end
		end
	end
end

--- @param character EsvCharacter
--- @param flag boolean
Helpers.SetHasCounterAttacked = function(character, flag)
	local combat = Ext.ServerEntity.GetCombat(CombatGetIDForCharacter(character.MyGuid))
	if combat then
		for i, team in pairs(combat:GetNextTurnOrder()) do
			if team and team.Character.MyGuid == character.MyGuid then
				team.EntityWrapper.CombatComponentPtr.CounterAttacked = flag
			end
		end
	end
end

---@param prioritizeSecondPlayer boolean|nil
---@return EclCharacter|nil
--- Credits to LaughingLeader
Helpers.GetPlayerManagerCharacter = function(prioritizeSecondPlayer)
    local playerManager = Ext.Entity.GetPlayerManager()
    if playerManager then
        if prioritizeSecondPlayer then
            local player2Data = playerManager.ClientPlayerData[2]
            if player2Data then
                local client = Ext.Entity.GetCharacter(player2Data.CharacterNetId)
                if client then
                    return client
                end
            end
        end
        for id,data in pairs(playerManager.ClientPlayerData) do
            local client = Ext.Entity.GetCharacter(data.CharacterNetId)
            if client then
                return client
            end
        end
    end
    return nil
end

Helpers.GetCharactersAroundPosition = function(x,y,z,radius)
	local grid = Ext.Entity.GetAiGrid()
	local characters = {}
	for posx = x-radius,x+radius,1 do
		for posz = z-radius,z+radius,1 do
			local cell = grid:GetCellInfo(posx, posz)
			for i,object in pairs(cell.Objects) do
				local entity = Ext.Entity.GetGameObject(object)
				if Ext.Types.GetObjectType(entity) == "ecl::Character" and entity.WorldPos[2] < y+radius and entity.WorldPos[2] > y-radius then
					table.insert(characters, entity)
				end
			end
		end
	end
	return characters
end

---@param character EsvCharacter
Helpers.Character.GetComputedCriticalMultiplier = function(character)
	local result = 100
	if character.Stats.MainWeapon then
		result = character.Stats.MainWeapon.DynamicStats[1].CriticalDamage
		if character.Stats.MainWeapon.IsTwoHanded then
			result = result + character.Stats.TwoHanded * Ext.ExtraData.CombatAbilityCritMultiplierBonus
		end
	end
	result = result + Ext.ExtraData.SkillAbilityCritMultiplierPerPoint * character.Stats.RogueLore
	return result
end

Helpers.Client = {}

Helpers.Client.GetCurrentCharacter = function()
	return Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.hotBar):GetRoot().hotbar_mc.characterHandle))
end

if Ext.IsServer() then
	--- A safe version of Ext.ServerEntity.GetCharacter to avoid errors spamming the console when the handle does not exists
	---@param handle any
	---@return EsvCharacter
	Helpers.ServerSafeGetCharacter = function(handle)
		if type(handle) == "number" then
			return Ext.ServerEntity.GetCharacter(handle)
		else
			if ObjectExists(handle) == 1 then
				return Ext.ServerEntity.GetCharacter(handle)
			else
				if Ext.Debug.IsDeveloperMode() then
					_VWarning("Handle", "CharacterHelpers:ServerSafeGetCharacter", handle, "does not exists!")
					return
				end
			end
		end
		_VError("Could not fetch character", "CharacterHelpers:ServerSafeGetCharacter", handle)
	end
end