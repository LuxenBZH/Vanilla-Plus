--- Trigger the damage calculation then revert it to a dodged/missed state
Ext.Events.ComputeCharacterHit:Subscribe(function(e)
	if e.Attacker and e.Attacker.Character:GetStatus("DGM_WARMUP") and (e.Hit.Dodged or e.Hit.Missed) then
		e.NoHitRoll = true
		local hit = Game.Math.ComputeCharacterHit(e.Target, e.Attacker, e.Weapon, e.DamageList, e.HitType, e.NoHitRoll, e.ForceReduceDurability, e.Hit, e.AlwaysBackstab, e.HighGround, e.CriticalRoll) ---@type EsvStatusHit
		e.NoHitRoll = false
		e.Hit.Missed = e.Hit.Missed
		e.Hit.Dodged = e.Hit.Dodged
		e.Hit.Hit = false
		if not e.Handled and hit then
			e.Handled = true
		end
	end
end)

--- @param hit EsvStatusHit
--- @param instigator EsvCharacter
--- @param target EsvItem|EsvCharacter
--- @param flags HitFlags
HitManager:RegisterHitListener("DGM_Hit", "AfterDamageScaling", "VP_WarmupManagement", function(hit, instigator, target, flags)
	if Helpers.IsCharacter(instigator) and Helpers.IsCharacter(target) and flags.IsWeaponAttack and (flags.Dodged or flags.Missed) and
	not instigator:GetStatus("BLINDED") and instigator.Stats.Accuracy >= instigator.Stats.BaseAccuracy and not target:GetStatus("EVADING") then
		if instigator:GetStatus("DGM_WARMUP") then
			local hitChance = Game.Math.CalculateHitChance(instigator.Stats, target.Stats)/100
			local damageMultiplier = math.max(math.max(hit.SkillId ~= "" and 0.5 or hitChance, 0), hitChance)
			local grazedHit = Ext.PrepareStatus(target.Handle, "HIT", 0) --- @type EsvStatusHit
			grazedHit.Hit.DamageList:CopyFrom(hit.Hit.DamageList)
			HitHelpers.HitMultiplyDamage(grazedHit.Hit, target, instigator, damageMultiplier)
			grazedHit.StatusSourceHandle = instigator.Handle
			grazedHit.Hit.Hit = true
			grazedHit.LifeTime = 1
			grazedHit.SkillId = "Target_LX_GrazedHit"
			Ext.ApplyStatus(grazedHit)
			CharacterStatusText(target.MyGuid, "Grazed!") --TODO: translation key
			instigator:GetStatus("DGM_WARMUP").LifeTime = 6
		else
			ApplyStatus(instigator.MyGuid, "DGM_WARMUP", 6, 1, instigator.MyGuid)
		end
	elseif flags.IsWeaponAttack and not (flags.Dodged or flags.Missed or flags.Blocked) and hit.SkillId ~= "Target_LX_GrazedHit" then
		RemoveStatus(instigator.MyGuid, "DGM_WARMUP")
	end
end, 52)