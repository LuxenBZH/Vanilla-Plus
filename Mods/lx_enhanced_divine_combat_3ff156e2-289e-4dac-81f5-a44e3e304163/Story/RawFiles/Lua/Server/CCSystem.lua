---- Hard CCs rework ----
blockedStatuses = {
	PhysicalArmor = {
		KNOCKED_DOWN = true,
		CHICKEN = true
	},
	MagicArmor = {
		STUNNED = true,
		FROZEN = true,
		PETRIFIED = true,
		MADNESS = true,
		FEAR = true,
		CHARMED = true,
		SLEEPING = true
	},
}

concernedTypes = {
	KNOCKED_DOWN = true,
	INCAPACITATED = true,
	CHARMED = true,
	CONSUME = true,
	FEAR = true,
	POLYMORPHED = true
}

local correspondingArmor = {
		PhysicalArmor = "CurrentArmor",
		MagicArmor = "CurrentMagicArmor"
	}
local correspondingStatus = {
	PhysicalArmor = {"LX_MOMENTUM", "LX_STAGGERED"},
	MagicArmor = {"LX_LINGERING","LX_CONFUSED"}
}

---@param character EsvCharacter
---@param status string
---@param duration number
---@param force boolean
---@param enterChance number
---@param baseHandle number
local function RollStatusApplication(character, status, duration, force, enterChance, baseHandle)
	local roll = math.random(1, 100)
	-- Ext.Print("[LXDGM_CCSystem.RollStatusApplication] Status",status,"has enter chance",enterChance,"roll:",roll)
	if roll <= enterChance then 
		ApplyStatus(character, status, duration, force)
	else 
		NRD_StatusPreventApply(character, baseHandle, 1) 
	end
end

-- local function RecoverFromCCs(character, status, ...)
-- 	for i,ban in pairs(bannedStatusTemplates) do
--         if string.find(status, ban) ~= nil then return end
--     end
-- 	local b,err = xpcall(function() Ext.GetStat(status) end, debug.traceback)
-- 	if not b then return end	
-- 	if status == "CHARMED" then status = "MADNESS" end
-- 	local status = Ext.GetStat(status)
-- 	if concernedTypes[status.StatusType] then
-- 		if statusType == "CONSUME" and not status.LoseControl then return end
-- 		if status.SavingThrow == "PhysicalArmor" then
-- 			ApplyStatus(character, "LX_MOMENTUM", Ext.ExtraData.DGM_CCParryDuration*6, 1)
-- 			if Ext.ExtraData.DGM_EnableDualCCParry == 1 then
-- 				ApplyStatus(character, "LX_LINGERING", Ext.ExtraData.DGM_CCParryDuration*6, 1)
-- 			end
-- 		elseif status.SavingThrow == "MagicArmor" then
-- 			ApplyStatus(character, "LX_LINGERING", Ext.ExtraData.DGM_CCParryDuration*6, 1)
-- 			if Ext.ExtraData.DGM_EnableDualCCParry == 1 then
-- 				ApplyStatus(character, "LX_MOMENTUM", Ext.ExtraData.DGM_CCParryDuration*6, 1)
-- 			end
-- 		end
-- 	end
-- end
local function RecoverFromCCs(character, status, ...)
	for armour,statuses in pairs(blockedStatuses) do
		if statuses[status] then
			if armour == "PhysicalArmor" then
				ApplyStatus(character, "LX_MOMENTUM", Ext.ExtraData.DGM_CCParryDuration*6, 1)
			elseif armour == "MagicArmor" then
				ApplyStatus(character, "LX_LINGERING", Ext.ExtraData.DGM_CCParryDuration*6, 1)
			end
		end
	end
end

Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "after", RecoverFromCCs)

---@param character EsvCharacter
---@param status string
---@param handle number
local function BlockCCs(character, status, handle)
	local lifetime = NRD_StatusGetInt(character, handle, "LifeTime")
	local source = NRD_StatusGetInt(character, handle, "DamageSourceType") -- If 5 it's from an aura
	local enterChance = NRD_StatusGetInt(character, handle, "CanEnterChance")
	for armour,statuses in pairs(blockedStatuses) do
		if statuses[status] then
			local armourValue = Ext.GetCharacter(character).Stats[correspondingArmor[armour]]
			if armourValue ~= 0 and NRD_StatusGetInt(character, handle, "ForceStatus") == 0 then return end
			if lifetime == -1 and source == 5 then return end -- Fuck auras
			if armourValue ~= 0 and source == 3 and HasActiveStatus(character, correspondingStatus[armour][1]) == 1 then
				NRD_StatusPreventApply(character, handle, 1)
				RollStatusApplication(character, correspondingStatus[armour][2], 6.0, 1, enterChance, handle)
				return 
			end
			if HasActiveStatus(character, correspondingStatus[armour][1]) == 1 then -- if it's not from aura then apply the corresponding debuff
				NRD_StatusPreventApply(character, handle, 1)
				RollStatusApplication(character, correspondingStatus[armour][2], 6.0, 1, enterChance, handle)
			end
		end
	end
end

Ext.RegisterOsirisListener("NRD_OnStatusAttempt", 4, "after", BlockCCs)
