_P("Loaded StatsHelpers.lua")

Helpers.Stats = {}

---@param entry StatEntryPotion|StatEntryCharacter|StatEntryWeapon|StatEntrySkillData|StatEntryStatusData|StatEntryArmor|StatEntryShield|StatEntryObject
Helpers.Stats.GetEntryType = function(entry)
	local entryTable = {}
	for i,j in pairs(entry) do
		entryTable[i] = j
	end
	if entryTable.StatusType ~= null then
		return "StatusData"
	elseif entryTable.SkillType ~= null then
		return "SkillData"
	elseif entryTable.WeaponType ~= null then
		return "Weapon"
	elseif entryTable.Blocking ~= null then
		return "Shield"
	elseif entryTable["Armor Defense Value"] ~= null then
		return "Armor"
	elseif entryTable.IsFood ~= null then
		return "Potion"
	elseif entryTable.RuneEffectWeapon ~= null then
		return "Object"
	elseif entryTable.FOV ~= null then
		return "Character"
	end
end

---Check if the designated stat exists
---@param statType StatType
---@param name string
---@return boolean
Helpers.Stats.Exists = function(statType, name)
	if Ext.IsServer() then
		return NRD_StatExists(name) and true or false
	else
		local stats = Ext.Stats.GetStats(statType)
		for i,stat in pairs(stats) do
			if stat == name then
				return true
			end
		end
		return false
	end
end