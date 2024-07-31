---@class APCostManager
Data.APCostManager = {
	Skills = {},
	Globals = {}
}

Data.APCostManager.__index = Data.APCostManager

Ext.Events.GetSkillAPCost:Subscribe(function(e)
	for i, info in pairs(Data.APCostManager.Globals) do
		info.Callback(e)
	end
	local skill = e.Skill.StatsObject.StatsEntry.Name
	if Data.APCostManager.Skills[skill] then
		Data.APCostManager.Skills[skill].Callback(e)
	end
end)

---Setter for skills with conditional AP costs
---@param skill string
---@param callback function
Data.APCostManager.RegisterSkillAPFormula = function(skill, callback)
	Data.APCostManager.Skills[skill] = {
		Callback = callback
	}
    Helpers.VPPrint("Registered Skill AP formula for", "APCostManager:"..(Ext.IsServer() and "Server" or "Client"), skill)
end

---Setter for global conditional AP costs
---@param callback function
---@param name string
---@param priority number|nil
Data.APCostManager.RegisterGlobalSkillAPFormula = function(name, callback, priority)
	local index = priority or 100
	while Data.APCostManager.Globals[index] do
		index = index + 1
	end
	Data.APCostManager.Globals[index] = {
		Callback = callback,
		Name = name
	}
    Helpers.VPPrint("Registered global AP formula", "APCostManager:"..(Ext.IsServer() and "Server" or "Client"), name)
end

--- Forbids player to validate casts if the AP cost has been modified through Lua and is above their current AP
--- TODO: fetch the gamepad input value
if Ext.IsClient() then
	Ext.ClientBehavior.Skill.AddGlobal(function()
		local EclCustomSkillState = {}
		---@class ev CustomSkillEventParams
		---@param skillState EclSkillState
		---@param inputEvent InputEvent
		---@return boolean
		function EclCustomSkillState:OnInputEvent(ev,skillState, inputEvent)
			local cc = Ext.UI.GetCursorControl()
			local td = Ext.UI.GetByHandle(cc.TextDisplayUIHandle)
			local tooMuchAP = string.match(td.Text, Ext.L10N.GetTranslatedString("h478017a5gdbc6g44ffgb28dga893e733370b", "Not enough AP"))
			if tooMuchAP and inputEvent.EventId == 1 then
				ev.PreventDefault = true
				ev.StopEvent = true
			else
				ev.StopEvent = false
			end
			return false
		end
		return EclCustomSkillState
	end)
end

Ext.Events.SessionLoading:Subscribe(function (_)
    if Mods.EpipEncounters then
        local epip = Mods.EpipEncounters.Epip ---@type Epip
        if epip.VERSION >= 1069 then -- GetSkillAPCost hook is only available in v1069+
            local CharacterLib = Mods.EpipEncounters.Character ---@type CharacterLib

            CharacterLib.Hooks.GetSkillAPCost:Subscribe(function (e)
                -- Replicate your GetSkillAPCost listener here
                for i, info in pairs(Data.APCostManager.Globals) do
					info.Callback(e)
				end
				local skill = e.Name
				if Data.APCostManager.Skills[skill] then
					Data.APCostManager.Skills[skill].Callback(e)
				end
            end)
        end
    end
end)

------- Skills specific AP costs
---Swap Surfaces anti-cheese
---@param e LuaGetSkillAPCostEvent
Data.APCostManager.RegisterSkillAPFormula("Teleportation_SwapGround", function(e)
	local skill = e.Skill.StatsObject.StatsEntry
	local character = e.Character.Character ---@type EclCharacter|EsvCharacter
	local radius = skill.HitRadius-0.5
	e.AP = 0
	e.ElementalAffinity = e.ElementalAffinity or false

	if Ext.IsClient() and character.SkillManager.CurrentSkill and character.SkillManager.CurrentSkill.SkillId == "Teleportation_SwapGround_-1" and character.SkillManager.CurrentSkill.State == "PickTargets" then
		local position = Ext.UI.GetPickingState().WalkablePosition
		local surface1 = Helpers.GetSurfaceLayersInArea(position[1], position[3], radius)
		local disappear = character.SkillManager.CurrentSkill.DisappearPosition
		local surface2 = character.SkillManager.CurrentSkill.TargetingState == 2 and Helpers.GetSurfaceLayersInArea(disappear[1], disappear[3], radius) or nil
		if surface1.Ground.Lava or surface1.Cloud.Deathfog or (surface2 and (surface2.Ground.Lava or surface2.Cloud.Deathfog)) then
			e.AP = 6
		else
			local characters1 = Helpers.GetCharactersAroundPosition(position[1], position[2], position[3], radius)
			local characters2 = character.SkillManager.CurrentSkill.TargetingState == 2 and Helpers.GetCharactersAroundPosition(disappear[1], disappear[2], disappear[3], radius) or {}
			for i,target in pairs(characters1) do
				if target.NetID == character.NetID then
					e.AP = 1
				end
			end
			for i,target in pairs(characters2) do
				if target.NetID == character.NetID then
					e.AP = 1
				end
			end
		end
	elseif Ext.IsServer() then
		local state = character.ActionMachine.Layers[1].State.OriginalSkill
		local surface1 = Helpers.GetSurfaceLayersInArea(state.SourcePosition[1], state.SourcePosition[3], radius)
		local surface2 = Helpers.GetSurfaceLayersInArea(state.TargetPosition[1], state.TargetPosition[3], radius)
		if surface1.Ground.Lava or surface1.Cloud.Deathfog or surface2.Ground.Lava or surface2.Cloud.Deathfog then
			e.AP = 6
		else
			local characters1 = Ext.ServerEntity.GetCharacterGuidsAroundPosition(state.SourcePosition[1], state.SourcePosition[2], state.SourcePosition[3], radius)
			local characters2 = Ext.ServerEntity.GetCharacterGuidsAroundPosition(state.TargetPosition[1], state.TargetPosition[2], state.TargetPosition[3], radius)
			for i,target in pairs(characters1) do
				if target == character.MyGuid then
					e.AP = 1
				end
			end
			for i,target in pairs(characters2) do
				if target == character.MyGuid then
					e.AP = 1
				end
			end
		end
	end
end)


---@param e LuaGetSkillAPCostEvent
Data.APCostManager.RegisterSkillAPFormula("Target_TerrifyingCruelty", function(e)
	local skill = e.Skill.StatsObject.StatsEntry
	local character = e.Character.Character ---@type EclCharacter|EsvCharacter
	local radius = skill.HitRadius-0.5
	e.AP = skill.ActionPoints
	e.ElementalAffinity = e.ElementalAffinity or false

	if Ext.IsClient() and character.SkillManager.CurrentSkill and character.SkillManager.CurrentSkill.State == "PickTargets" then
		local target = Ext.UI.GetPickingState().HoverCharacter
		if target then
			target = Ext.ClientEntity.GetCharacter(target)
			if target.Stats.CurrentArmor > 0 then
				e.AP = e.AP - 1
			end
			if target.Stats.CurrentMagicArmor > 0 then
				e.AP = e.AP - 1
			end
		end
	elseif Ext.IsServer() and character.ActionMachine.Layers[1].State then
		local state = character.ActionMachine.Layers[1].State.OriginalSkill --TODO: OriginalSkill does not exists in all contexts. Make a check for that.
		local target = Ext.ServerEntity.GetGameObject(state.TargetHandle)
		if target and Helpers.IsCharacter(target) then
			if target.Stats.CurrentArmor > 0 then
				e.AP = e.AP - 1
			end
			if target.Stats.CurrentMagicArmor > 0 then
				e.AP = e.AP - 1
			end
		end
	end
end)

---Ranger stance: rapid fire
---@param e LuaGetSkillAPCostEvent
Data.APCostManager.RegisterGlobalSkillAPFormula("RapidFire", function(e)
	local skill = e.Skill.StatsObject.StatsEntry
	local character = e.Character.Character ---@type EclCharacter|EsvCharacter
	if skill.Ability ~= "Ranger" or character:GetStatus("LX_RAPIDFIRE") == null or skill["Damage Multiplier"] == 0 then return end
	e.AP = math.max(skill.ActionPoints - 1, 1)
end)