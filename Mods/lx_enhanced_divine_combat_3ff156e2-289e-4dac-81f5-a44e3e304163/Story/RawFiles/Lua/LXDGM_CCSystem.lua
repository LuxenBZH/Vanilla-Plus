---- Hard CCs rework ----
---@param character EsvCharacter
---@param status string
---@param handle number
function BlockPhysicalCCs(character, status, handle)
	local lifetime = NRD_StatusGetInt(character, handle, "LifeTime")
	local source = NRD_StatusGetInt(character, handle, "DamageSourceType") -- If 5 it's from an aura
	local enterChance = NRD_StatusGetInt(character, handle, "CanEnterChance")
	local blockedStatuses = {
		"KNOCKED_DOWN",
		"CHICKEN"
		}
	for i,block in pairs(blockedStatuses) do
		if status == block then
			NRD_StatusPreventApply(character, handle, 1)
			if lifetime ~= -1 and source ~= 5 then -- if it's not from aura then apply the corresponding debuff
				RollStatusApplication(character, "LX_STAGGERED", 6.0, 1, enterChance, handle)
			end
		end
	end
end

---@param character EsvCharacter
---@param status string
---@param handle number
function BlockMagicalCCs(character, status, handle)
	local lifetime = NRD_StatusGetInt(character, handle, "LifeTime")
	local source = NRD_StatusGetInt(character, handle, "DamageSourceType") -- If 5 it's from an aura
	local enterChance = NRD_StatusGetInt(character, handle, "CanEnterChance")
	local blockedStatuses = {
		"STUNNED",
		"FROZEN",
		"PETRIFIED",
		"MADNESS",
		"FEAR",
		"CHARMED",
		"SLEEPING"
	}
	for i,block in pairs(blockedStatuses) do
		if status == block then
			NRD_StatusPreventApply(character, handle, 1)
			if lifetime ~= -1 and source ~= 5 then -- if it's not from aura then apply the corresponding debuff
				RollStatusApplication(character, "LX_CONFUSED", 6.0, 1, enterChance, handle)
			end
		end
	end
end

---@param character EsvCharacter
---@param status string
---@param duration number
---@param force boolean
---@param enterChance number
---@param baseHandle number
function RollStatusApplication(character, status, duration, force, enterChance, baseHandle)
	local roll = math.random(1, 100)
	Ext.Print("[LXDGM_CCSystem.RollStatusApplication] Status",status,"has enter chance",enterChance,"roll:",roll)
	if roll <= enterChance then 
		ApplyStatus(character, status, duration, force)
	else 
		NRD_StatusPreventApply(character, baseHandle, 1) 
	end
end