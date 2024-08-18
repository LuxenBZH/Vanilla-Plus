---@param character EsvCharacter
---@param step number|nil
---@param fromMiss boolean|nil
function ApplyWarmup(character, step, fromMiss)
	local warmup = FindStatus(character, "DGM_WARMUP")
	local isMeleeTwoHanded = character.Stats.MainWeapon.IsTwoHanded and not Game.Math.IsRangedWeapon(character.Stats.MainWeapon)
	local stage
	if step then
		stage = step
	elseif warmup then
		stage = string.sub(warmup, 11, 11)
		stage = math.min(tonumber(stage)+1, 4)
		ObjectSetFlag(character.MyGuid, "DGM_WarmupReapply", 0)
	else
		stage = 1
	end
	if fromMiss and isMeleeTwoHanded then
		stage = math.min(stage + 1, 4)
	end
	CustomStatusManager:CharacterApplyMultipliedStatus(character, "DGM_WARMUP"..tostring(stage), 6.0, 1.0 + 0.1 * character.Stats.WarriorLore)
end

---@param character string
---@param status string
---@param causee string
Ext.Osiris.RegisterListener("NRD_OnStatusAttempt", 4, "before", function(target, statusId, handle, instigator)
	if statusId == "DGM_WARMUP" and ObjectIsCharacter(target) == 1 then
		NRD_StatusPreventApply(target, handle, 1)
		ApplyWarmup(Ext.ServerEntity.GetCharacter(target))
	end
end)

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
--- @param instigatorDGMStats table
HitManager:RegisterHitListener("DGM_Hit", "BeforeDamageScaling", "DGM_Specifics", function(hit, instigator, target, flags)
	--- WARMUP application
	if (flags.Missed or flags.Dodged) and not target:GetStatus("EVADING") and Helpers.IsCharacter(instigator) then
		ApplyWarmup(instigator, nil, true)
	end
end, 51)

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "DGM_AbsorbShields", function(hit, instigator, target, flags)
	--- Warmup after 3 hits
	if getmetatable(instigator) == "esv::Character" and instigator:GetStatus("COMBAT") and flags.IsWeaponAttack and not Game.Math.IsRangedWeapon(instigator.Stats.MainWeapon) then
		if not instigator.UserVars.LX_WarmupManager or type(instigator.UserVars.LX_WarmupManager) == "number" then
			instigator.UserVars.LX_WarmupManager = {
				Counter = 0,
				LastSkillHitID = 0,
				LastTarget = ""
			}
		end
		if not hit.Hit.Dodged and not hit.Hit.Missed then
			if hit.SkillId ~= "" then
				local skill = Ext.Stats.Get(Helpers.GetFormattedSkillID(hit.SkillId))
				---Make sure a character can get a warmup count only once for AoE skills, but can still get as many count as there are hits for a single target skill
				if ((instigator.UserVars.LX_WarmupManager.LastSkillHitID ~= Helpers.UserVars.Get(instigator, "VP_LastSkillsUsed")[1].ID) or
				(instigator.UserVars.LX_WarmupManager.LastSkillHitID == Helpers.UserVars.Get(instigator, "VP_LastSkillsUsed")[1].ID and instigator.UserVars.LX_WarmupManager.LastTarget == target.MyGuid)) or
				(instigator.UserVars.LX_WarmupManager.LastSkillHitID == Helpers.UserVars.Get(instigator, "VP_LastSkillsUsed")[1].ID and instigator.UserVars.LX_WarmupManager.LastTarget ~= target.MyGuid and skill.SkillType == "MultiStrike") and
				skill.UseWeaponDamage == "Yes" then
					instigator.UserVars.LX_WarmupManager.Counter = instigator.UserVars.LX_WarmupManager.Counter + 1
				end
				instigator.UserVars.LX_WarmupManager.LastSkillHitID = Helpers.UserVars.Get(instigator, "VP_LastSkillsUsed")[1].ID
				instigator.UserVars.LX_WarmupManager.LastTarget = target.MyGuid
			else
				instigator.UserVars.LX_WarmupManager.Counter = instigator.UserVars.LX_WarmupManager.Counter + 1
			end
			if instigator.UserVars.LX_WarmupManager.Counter >= 3 then
				instigator.UserVars.LX_WarmupManager.Counter = 0
				ApplyWarmup(instigator)
			end
		else
			instigator.UserVars.LX_WarmupManager.Counter = 0
		end
		-- _P(instigator.MyGuid, "Warmup counter:", instigator.UserVars.LX_WarmupManager.Counter)
	end
	--- Refresh Warmup status if the character attack while it's at 0 turn left
	if getmetatable(instigator) == "esv::Character" then
		local warmup = FindStatus(instigator, "DGM_WARMUP")
		if instigator:GetStatus("COMBAT") and warmup then
			local status = instigator:GetStatus(warmup)
			status.CurrentLifeTime = 6.0
			Ext.Net.BroadcastMessage("DGM_RefreshWarmup", Ext.JsonStringify({
				Character = instigator.NetID,
				Status = warmup
			}))
		end
	end
end, 52)