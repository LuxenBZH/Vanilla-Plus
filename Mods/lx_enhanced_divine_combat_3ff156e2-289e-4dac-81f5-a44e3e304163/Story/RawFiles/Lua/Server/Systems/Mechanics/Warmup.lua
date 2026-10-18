--- Let the hit still happen
Ext.Events.ComputeCharacterHit:Subscribe(function(e)
	if e.Attacker and e.Attacker.Character:GetStatus("DGM_WARMUP") and (e.Hit.Dodged or e.Hit.Missed) then
		e.NoHitRoll = true
		local hit = Game.Math.ComputeCharacterHit(e.Target, e.Attacker, e.Weapon, e.DamageList, e.HitType, e.NoHitRoll, e.ForceReduceDurability, e.Hit, e.AlwaysBackstab, e.HighGround, e.CriticalRoll) ---@type EsvStatusHit
		e.Hit.Hit = true
		e.Hit.Missed = e.Hit.Missed
		e.Hit.Dodged = e.Hit.Dodged
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
	if Helpers.IsCharacter(instigator) and Helpers.IsCharacter(target) and flags.IsWeaponAttack and (hit.Hit.Dodged or hit.Hit.Missed) then
		if instigator:GetStatus("DGM_WARMUP") then
			local hitChance = Game.Math.CalculateHitChance(instigator.Stats, target.Stats)
			local damageMultiplier = math.min(math.max(hitChance/200, 0))
			HitHelpers.HitMultiplyDamage(hit.Hit, target, instigator, damageMultiplier)
			CharacterStatusText(target.MyGuid, "Scraped!")
		else
			ApplyStatus(instigator.MyGuid, "DGM_WARMUP", 6, 1, instigator.MyGuid)
		end
	end
end, 52)