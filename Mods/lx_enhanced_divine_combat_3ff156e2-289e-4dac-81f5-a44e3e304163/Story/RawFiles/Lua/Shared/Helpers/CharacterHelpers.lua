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
	local currentLevel = Ext.Entity.GetCurrentLevel()
	local levelCharacters = currentLevel.EntityManager.CharacterConversionHelpers.ActivatedCharacters[currentLevel.LevelDesc.LevelName]
	for i, character in pairs(levelCharacters) do
		if Ext.Math.Distance({x, y, z}, character.WorldPos) <= radius then
			table.insert(characters, character)
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

---Returns a status if the text is part of the status name
---@param character EsvCharacter|EclCharacter
---@param text string
Helpers.Character.GetStatus = function(character, text)
	for i,j in pairs(character:GetStatuses()) do
		if string.match(j, text) then
			return j
		end
	end
	return false
end

---Checks if the character has the necessary requirements to memorize the skill
---@param character EsvCharacter|EclCharacter
---@param skill StatEntrySkillData|string
---@param base boolean|nil
Helpers.Character.CheckSkillRequirements = function(character, skill, base)
	local skill = type(skill) == "string" and Ext.Stats.Get(skill) or skill
	for i,r in pairs(skill.MemorizationRequirements) do
		local abilityScore = character.Stats[(base and "Base" or "")..tostring(r.Requirement)]
		_P(abilityScore, r.Param)
		if abilityScore < r.Param then
			return false
		end
	end
	return true
end

---Get the amount of warmup stacks of a character
---@param character EsvCharacter|EclCharacter
Helpers.Character.GetWarmupStacks = function(character)
	local warmup = Helpers.Character.GetStatus(character, "DGM_WARMUP")
	local stackNumber = warmup and tonumber(string.sub(warmup, -1)) or 0
	return stackNumber
end

Helpers.Client = {}

Helpers.Client.GetCurrentCharacter = function()
	if Ext.UI.GetByType(Data.UIType.hotBar) then
		return Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.hotBar):GetRoot().hotbar_mc.characterHandle))
	else
		return nil
	end
end

if Ext.IsServer() then
	--- A safe version of Ext.ServerEntity.GetCharacter to avoid errors spamming the console when the handle does not exists
	---@param handle any
	---@return EsvCharacter|nil
	Helpers.ServerSafeGetCharacter = function(handle)
		if type(handle) == "number" then
			return Ext.ServerEntity.GetCharacter(handle)
		else
			if ObjectExists(handle) == 1 then
				return Ext.ServerEntity.GetCharacter(handle)
			else
				if Ext.Debug.IsDeveloperMode() then
					_VWarning("Handle", "CharacterHelpers:ServerSafeGetCharacter", handle, "does not exists!")
				end
				
			end
		end
		return
	end

	--- A safe version of Ext.ServerEntity.GetItem to avoid errors spamming the console when the handle does not exists
	---@param handle any
	---@return EsvItem|nil
	Helpers.ServerSafeGetItem = function(handle)
		if type(handle) == "number" then
			return Ext.ServerEntity.GetItem(handle)
		else
			if ObjectExists(handle) == 1 then
				return Ext.ServerEntity.GetItem(handle)
			else
				if Ext.Debug.IsDeveloperMode() then
					_VWarning("Handle", "CharacterHelpers:ServerSafeGetItem", handle, "does not exists!")
				end
			end
		end
		return
	end

	---@param character EsvCharacter
	---@param skill string
	---@param cooldown number in seconds
	---@param warning boolean|nil
	Helpers.Character.SetSkillCooldown = function(character, skill, cooldown, warning)
		warning = warning or true
		if character.SkillManager.Skills[skill] then
			character.SkillManager.Skills[skill].ActiveCooldown = 0 
			Helpers.Timer.Start(100, function(character, cooldown) Ext.ServerEntity.GetCharacter(character).SkillManager.Skills[skill].ActiveCooldown = cooldown end, nil, character.NetID, cooldown)
			-- character.SkillManager.Skills[skill].ActiveCooldown = cooldown
		else
			if warning then
				_VWarning("Character "..character.MyGuid.." does not have the skill "..skill.." so its cooldown could not be changed!", "CharacterHelpers")
			end
		end
	end

	---@param character EsvCharacter
	---@param skill string
	---@param cooldown number in seconds
	---@param warning boolean|nil
	Helpers.Character.AddSkillCooldown = function(character, skill, cooldown, warning)
		warning = warning or true
		if character.SkillManager.Skills[skill] then
			local currentCooldown = character.SkillManager.Skills[skill].ActiveCooldown
			character.SkillManager.Skills[skill].ActiveCooldown = 0 
			Helpers.Timer.Start(100, function(character, cooldown) Ext.ServerEntity.GetCharacter(character).SkillManager.Skills[skill].ActiveCooldown = cooldown end, nil, character.NetID, currentCooldown + cooldown)
			-- character.SkillManager.Skills[skill].ActiveCooldown = cooldown
		else
			if warning then
				_VWarning("Character "..character.MyGuid.." does not have the skill "..skill.." so its cooldown could not be changed!", "CharacterHelpers")
			end
		end
	end

	Ext.RegisterNetListener("LX_RefreshSkillCooldown", function(channel, payload)
		local info = Ext.Json.Parse(payload)
		Helpers.Character.AddSkillCooldown(Ext.ServerEntity.GetCharacter(tonumber(info.Character)), info.Skill, tonumber(info.Cooldown), info.Warning)
	end)

	---comment
	---@param target EsvCharacter
	---@param instigator EsvCharacter
	---@param deathType string
	Helpers.Character.Execute = function(target, instigator, deathType)
		PlayEffect(target.MyGuid, "RS3_FX_Skills_Warrior_BlinkStrike_Impact_01", "Dummy_BodyFX")
		CharacterStatusText(target.MyGuid, "Executed!")
		CharacterDie(target.MyGuid, 1, deathType, instigator.MyGuid)
		for i,status in pairs(instigator:GetStatuses()) do
			local statEntry = Ext.Stats.Get(status, nil, false)
			if statEntry and statEntry.VP_ExecuteMultiplier > 0 then
				RemoveStatus(instigator.MyGuid, status)
			end
		end
	end
else
	---@param character EclCharacter
	---@param skill string
	---@param cooldown number in seconds
	---@param warning boolean|nil
	Helpers.Character.AddSkillCooldown = function(character, skill, cooldown, warning)
		Ext.Net.PostMessageToServer("LX_RefreshSkillCooldown", Ext.Json.Stringify({
			Character = character.NetID,
			Skill = skill,
			Cooldown = cooldown,
			Warning = warning
		}))
	end
end