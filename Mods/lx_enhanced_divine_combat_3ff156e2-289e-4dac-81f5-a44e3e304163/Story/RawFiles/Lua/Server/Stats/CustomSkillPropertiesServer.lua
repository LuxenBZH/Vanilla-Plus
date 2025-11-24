CustomSBValues = {}
done = 0

-- Ext.RegisterOsirisListener("CharacterUsedSkillOnTarget", 5, "before", function(character, target, skill, skillType, skillElement)
--     local stat = Ext.GetStat(skill)
--     local isCSB = false
--     for i, properties in pairs(stat.SkillProperties) do
--         if properties.Action == "CUSTOMSURFACEBOOST" then isCSB = true end
--     end
--     if isCSB then
--         local surfaces = {}
--         for i, properties in pairs(stat.SkillProperties) do
--             if properties.SurfaceBoosts ~= nil then
--                 for i,surface in pairs(properties.SurfaceBoosts) do
--                     table.insert(surfaces, surface)
--                 end
--             end
--         end
--         local char = Ext.GetCharacter(target)
--         local x = char.WorldPos[1]
-- 		local y = char.WorldPos[3]
-- 		local radius = Ext.GetStat(skill).AreaRadius
-- 		local grid = Ext.GetAiGrid()
-- 		local tiles = 0
-- 		local scale = 0.5
-- 		for i = x-radius,x+radius, scale do
-- 			for j = y-radius,y+radius, scale do
-- 				local info = grid:GetCellInfo(i,j)
-- 				if ((i-x)*(i-x) + (j-y)*(j-y)) <= radius*radius then
-- 					for surfaceType, t in pairs(SiphonPoisonSurfaces) do
-- 						if info ~= nil and (info.Flags & surfaceFlags[surfaceType]) == surfaceFlags[surfaceType] then
-- 							tiles = tiles + 1
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end
-- 		Ext.Print("tiles:",tiles)
--         if CustomSBValues[skill] == nil then CustomSBValues = {} end
-- 		CustomSBValues[skill][char.MyGuid] = tiles
--     end
-- end)

Ext.RegisterOsirisListener("CharacterUsedSkill", 4, "before", function(character, skill, skillType, skillElement)
    local stat = Ext.GetStat(skill)
    local isCSB = false
    if stat.SkillProperties ~= nil then
        for i, properties in pairs(stat.SkillProperties) do
            if properties.Action == "CUSTOMSURFACEBOOST" then isCSB = true end
        end
    end
    if isCSB then
        local surfaces = {}
        for i, properties in pairs(stat.SkillProperties) do
            if properties.SurfaceBoosts ~= nil then
                for i,surface in pairs(properties.SurfaceBoosts) do
                    table.insert(surfaces, tostring(surface))
                end
            end
        end
        local char = Ext.GetCharacter(character)
        local x = char.WorldPos[1]
		local y = char.WorldPos[3]
		local radius = Ext.GetStat(skill).AreaRadius
		local grid = Ext.GetAiGrid()
		local tiles = 0
		local scale = 0.5
		for i = x-radius,x+radius, scale do
			for j = y-radius,y+radius, scale do
				local info = grid:GetCellInfo(i,j)
				if ((i-x)*(i-x) + (j-y)*(j-y)) <= radius*radius then
					for i, surfaceType in pairs(surfaces) do
						if info ~= nil then
                            local rawType = string.gsub(surfaceType, "Blessed", "")
                            rawType = string.gsub(rawType, "Cursed", "")
                            if (info.Flags & surfaceFlags[rawType]) == surfaceFlags[rawType] then
                                if string.match(surfaceType, "Blessed") then
                                    if (info.Flags & surfaceFlags["Blessed"]) == surfaceFlags["Blessed"] then
                                        tiles = tiles + 1
                                    end
                                elseif string.match(surfaceType, "Cursed") then
                                    if (info.Flags & surfaceFlags["Cursed"]) == surfaceFlags["Cursed"] then
                                        tiles = tiles + 1
                                    end
                                else
                                    tiles = tiles + 1
                                end
                            end
						end
					end
				end
			end
		end
        if CustomSBValues[skill] == nil then CustomSBValues[skill] = {} end
		CustomSBValues[skill][char.MyGuid] = tiles
    end
end)

Ext.RegisterSkillProperty("LX_SHIELD", {
	GetDescription = function() end,
	ExecuteOnTarget = function(property, attacker, target, position, isFromItem, skill, hit)
		local statProperties = {} -- Usage: StatEntry, Field, Base, Growth, CellAggregate
		local index = 1
		for value in string.gmatch(property.Arg3, "(.-)/") do
			statProperties[index] = value
			index = index + 1
		end
		-- 1: Type, 2: Damage scaling, 3: Amount, 4: Duration, 5: Can reinforce existing shield
		local scaledAmount = Ext.Utils.Round(DamageScalingFormulas[statProperties[2]](attacker.Stats.Level))
		_P("Scaled bonus:",scaledAmount)
		-- SetTag(target.MyGuid, "LX_SHIELD_"..statProperties[1].."_")
		-- SetVarInteger(target.MyGuid, "LX_SHIELD_"..statProperties[1], (GetVarInteger(target, "LX_SHIELD_"..statProperties[1]) or 0) + scaledAmount)
		local statusName = "LX_SHIELD_"..string.upper(statProperties[1])
		local status = target:GetStatus(statusName)
		_D(statProperties)
		if statProperties[5] == "1" and status then
			status.StatsMultiplier = status.StatsMultiplier + scaledAmount
		else
			status = Ext.PrepareStatus(target.MyGuid, "LX_SHIELD_"..string.upper(statProperties[1]), statProperties[4]*6.0)
			-- The StatsMultiplier of the shield status is used to store the absorbed amount information
			status.StatsMultiplier = scaledAmount
			Ext.ApplyStatus(status)
		end
	end,
	ExecuteOnPosition = function(property, attacker, position, areaRadius, isFromItem, skill, hit)
	end
})


Ext.RegisterSkillProperty("CUSTOMSURFACEBOOST", {
	GetDescription = function() end,
	ExecuteOnTarget = function(property, attacker, target, position, isFromItem, skill, hit)
		-- Ext.Print("SKILLPROPERTY on target")
		-- Ext.Dump(property)
		-- Ext.Print(property, attacker.DisplayName, target.DisplayName, position, isFromItem, skill, hit)
		if done < 1 then
			local args = {}
			local index = 1
			for value in string.gmatch(property.Arg3, "(.-)/") do
				args[index] = value
				-- Ext.Print(index, value)
				index = index + 1
			end
			local status = Ext.GetStat(args[1])
			local duration = args[2]
			local statProperties = {} -- Usage: StatEntry, Field, Base, Growth, CellAggregate
			index = 1
			for value in string.gmatch(args[3], "(.-)|") do
				statProperties[index] = value
				index = index + 1
			end
			index = 1
			local start = 1
			for i=1,GetTableSize(statProperties),7 do
				local baseStat = statProperties[i] -- The name of the status to take as a base
				if baseStat == nil then break end
				local statEntry = statProperties[i+1] -- Potion or Weapon entry
				local field = statProperties[i+2]
				local base = statProperties[i+3]
				local growth = statProperties[i+4]
				local cellAggregate = tonumber(statProperties[i+5])
				local maxBonus = tonumber(statProperties[i+6])
				-- Ext.Print(baseStat, statEntry, field, base, growth, cellAggregate)
				-- Ext.Dump(CustomSBValues[skill])
				local nbBoosts = CustomSBValues[skill.Name][attacker.MyGuid] / cellAggregate
				local boostValue
				if nbBoosts < maxBonus then
					boostValue = Ext.Round(math.floor(nbBoosts * growth))
				else
					boostValue = Ext.Round(math.floor(maxBonus * growth))
				end
				-- Ext.Print("boost:", boostValue, "total:", base+boostValue)
				local hiddenBoost = status.Name.."_"..string.gsub(field, " ", "").."_"..boostValue
				-- Ext.Print(hiddenBoost)

				if NRD_StatExists(hiddenBoost) then
					if GetStatusTurns(attacker.MyGuid, "LXC_Proxy_"..hiddenBoost) == tonumber(duration) then
						return
					end
					-- if HasActiveStatus(attacker.MyGuid, hiddenBoost) == 0 then
					ApplyStatus(attacker.MyGuid, "LXC_Proxy_"..hiddenBoost, duration*6.0, 1)
					-- end
				else
					local newStat = {Name = hiddenBoost}
					if not NRD_StatExists(newStat.Name) then
						newStat = Ext.CreateStat(newStat.Name, statEntry, baseStat)
						newStat[field] = base + boostValue
						Ext.SyncStat(newStat.Name, false)
					end
					if statEntry == "Weapon" then
						if not NRD_StatExists("LXC_PotionProxy"..hiddenBoost) then
							local newPotion = Ext.CreateStat("LXC_PotionProxy"..hiddenBoost, "Potion", "DGM_Potion_Base")
							newPotion.BonusWeapon = newStat.Name
							Ext.SyncStat(newPotion.Name, false)
						end
					end
					local newStatus = Ext.CreateStat("LXC_Proxy".."_"..hiddenBoost, "StatusData", "DGM_BASE")
					if statEntry == "Potion" then
						newStatus["StatsId"] = hiddenBoost
					elseif statEntry == "Weapon" then
						newStatus["StatsId"] = "LXC_PotionProxy"..hiddenBoost
					end
					newStatus["StackId"] = "DGM_Stack_"..status.Name
					Ext.SyncStat(newStatus.Name, false)
					ApplyStatus(attacker.MyGuid, newStatus.Name, duration*6.0, 1)
				end
			end
			ApplyStatus(attacker.MyGuid, status.Name, duration*6.0)
		end
		if done == 0 then
			done = 2
		else
			done = done - 1
		end
	end,
	ExecuteOnPosition = function(property, attacker, position, areaRadius, isFromItem, skill, hit)
		-- Ext.Print("SKILLPROPERTY on position")
		-- Ext.Dump(property)
		-- Ext.Print(property, attacker, position, areaRadius, isFromItem, skill, hit)
	end
})

Ext.RegisterSkillProperty("VP_TryKill", {
	GetDescription = function() end,
	---@param property StatsPropertyExtender
	---@param attacker EsvCharacter|EsvItem
	---@param target EsvCharacter|EsvItem
	---@param position number[]
	---@param isFromItem boolean
	---@param skill StatEntrySkillData|StatsSkillPrototype|nil
	---@param hit StatsHitDamageInfo|nil
	ExecuteOnTarget = function(property, attacker, target, position, isFromItem, skill, hit)
		if getmetatable(target) == "esv::Item" or not hit then return end
		local args = {}
		local index = 1
		for value in string.gmatch(property.Arg3, "(.-)/") do
			args[index] = value
			-- Ext.Print(index, value)
			index = index + 1
		end
		local value = args[1]
		local scaling = args[2]
		local chance = args[3]
		local bonusStatuses = args[4]
		local statusesArray = {}
		for status in string.gmatch(bonusStatuses, "([^|]+)") do
			table.insert(statusesArray, status)
		end
		local statusBonusValue = tonumber(args[5])
		local SPDamageBonus = tonumber(args[6])
		local SPConsumptionCap = tonumber(args[7])
		local computedStatusBonus = 0
		for i,status in pairs(statusesArray) do
			if target:GetStatus(status) then
				computedStatusBonus = computedStatusBonus + statusBonusValue
			end
		end
		local computedSPBonusValue = 0
		local source = Osi.CharacterGetSourcePoints(attacker.MyGuid)
		if source > SPConsumptionCap then
			computedSPBonusValue = SPConsumptionCap * SPDamageBonus
			Osi.CharacterAddSourcePoints(attacker.MyGuid, -SPConsumptionCap)
		else
			computedSPBonusValue = source * SPDamageBonus
			Osi.CharacterAddSourcePoints(attacker.MyGuid, -source)
		end
		local computedThreshold = math.floor(Helpers.GetScaledValue(scaling, target, attacker) * (value + computedStatusBonus + computedSPBonusValue) / 100)
		if target.Stats.CurrentVitality < computedThreshold then
			CharacterDie(target.MyGuid, 1, hit.DeathType, attacker.MyGuid)
		end
	end,
	ExecuteOnPosition = function(property, attacker, position, areaRadius, isFromItem, skill, hit)
	end
})

Ext.RegisterSkillProperty("LX_CustomVaporize", {
	GetDescription = function()
		return "Splash oil puddles around when targeting an oil surface and explode ice on spot, dealing damage in the area." ---TODO: translation string
	end,
	---@param property StatsPropertyExtender
	---@param attacker EsvCharacter|EsvItem
	---@param target EsvCharacter|EsvItem
	---@param position number[]
	---@param isFromItem boolean
	---@param skill StatEntrySkillData|StatsSkillPrototype|nil
	---@param hit StatsHitDamageInfo|nil
	ExecuteOnTarget = function(property, attacker, target, position, isFromItem, skill, hit)
	end,
	ExecuteOnPosition = function(property, attacker, position, areaRadius, isFromItem, skill, hit)
		local surface = Helpers.GetSurfaceTypeAtPosition(position[1], position[3])
		if string.sub(surface, 1, 3) == "Oil" then
            local modifier = string.gsub(surface, "Oil", "")
			local quarters = {
				{1, 1},
				{1, -1},
				{-1, 1},
				{-1, -1}
			}
            for i=1,2,1 do
				for j,quarter in pairs(quarters) do
					Helpers.LaunchProjectile(position, {position[1] + math.random(3,8)*quarter[1], position[2], position[3] + math.random(3,8)*quarter[2]}, "LX_Projectile_OilGeyserSpit"..modifier)
				end
			end
		elseif string.find(surface, "Frozen") ~= nil then
            Ext.PropertyList.ExecuteSkillPropertiesOnPosition("Shout_IceBreaker", attacker.MyGuid, position, skill.AreaRadius, {"Target", "AoE"}, false)
        end
	end
})