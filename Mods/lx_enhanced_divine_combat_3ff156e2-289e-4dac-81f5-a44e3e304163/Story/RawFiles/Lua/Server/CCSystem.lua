---- Hard CCs rework ----
blockedStatuses = {
	physical = {
		"KNOCKED_DOWN",
		"CHICKEN"
	},
	magical = {
		"STUNNED",
		"FROZEN",
		"PETRIFIED",
		"MADNESS",
		"FEAR",
		"CHARMED",
		"SLEEPING"
	},
}

concernedTypes = {
	KNOCKED_DOWN = true,
	INCAPACITATED = true,
	CHARMED = true,
	CONSUME = true
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

local function RecoverFromCCs(character, status, ...)
	local status = Ext.GetStat(status)
	if concernedTypes[status.StatusType] then
		if statusType == "CONSUME" and not status.LoseControl then return end
		if status.SavingThrow == "PhysicalArmor" then
			ApplyStatus(character, "LX_MOMENTUM", Ext.ExtraData.DGM_CCParryDuration*6, 1)
			if Ext.ExtraData.DGM_EnableDualCCParry == 1 then
				ApplyStatus(character, "LX_LINGERING", Ext.ExtraData.DGM_CCParryDuration*6, 1)
			end
		elseif status.SavingThrow == "MagicArmor" then
			ApplyStatus(character, "LX_LINGERING", Ext.ExtraData.DGM_CCParryDuration*6, 1)
			if Ext.ExtraData.DGM_EnableDualCCParry == 1 then
				ApplyStatus(character, "LX_MOMENTUM", Ext.ExtraData.DGM_CCParryDuration*6, 1)
			end
		end
	end
end

Ext.RegisterOsirisListener("CharacterStatusRemoved", 3, "after", RecoverFromCCs)

---@param character string
---@param status string
---@param handle number
local function BlockCCs(character, status, handle, instigator)
	local check = false
	local statuses = Ext.GetCharacter(character).GetStatuses(Ext.GetCharacter(character))
	for i,stts in pairs(statuses) do
		if stts == "LX_MOMENTUM" or stts == "LX_LINGERING" then
			check = true
			break
		end
	end
	if not check then return end
	local lifetime = NRD_StatusGetInt(character, handle, "LifeTime")
	local source = NRD_StatusGetInt(character, handle, "DamageSourceType") -- If 5 it's from an aura
	local enterChance = NRD_StatusGetInt(character, handle, "CanEnterChance")
	status = Ext.GetStat(status)
	local correspondingArmor = {
		PhysicalArmor = "CurrentArmor",
		MagicArmor = "CurrentMagicArmor"
	}
	local correspondingStatus = {
		PhysicalArmor = {"LX_MOMENTUM", "LX_STAGGERED"},
		MagicArmor = {"LX_LINGERING","LX_CONFUSED"}
	}
	if concernedTypes[status.StatusType] then
		if status.StatusType == "CONSUME" and not status.LoseControl then return end
		if correspondingArmor[status.SavingThrow] == nil then return end
		if Ext.GetCharacter(character).Stats[correspondingArmor[status.SavingThrow]] ~= 0 and source ~= 3 then return end
		if Ext.GetCharacter(character).Stats[correspondingArmor[status.SavingThrow]] ~= 0 and NRD_StatusGetInt(character, handle, "ForceStatus") == 0 then return end
		if lifetime ~= -1 and source ~= 5 and HasActiveStatus(character, correspondingStatus[status.SavingThrow][1]) == 1 then -- if it's not from aura then apply the corresponding debuff
			NRD_StatusPreventApply(character, handle, 1)
			RollStatusApplication(character, correspondingStatus[status.SavingThrow][2], 6.0, 1, enterChance, handle)
		end
	end
end

Ext.RegisterOsirisListener("NRD_OnStatusAttempt", 4, "after", BlockCCs)
