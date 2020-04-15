---- Potions ----
function CharacterUsePoisonedPotion(character, potion)
	local potionTemplate = GetTemplate(potion)
	local potionDmg = 0
	if potionTemplate == "CON_Potion_Poison_A_8122de3c-a331-44a4-b51a-6767a778776f" then potionDmg = 0.35
	elseif potionTemplate == "CON_Potion_Poison_Medium_A_3b5c5a91-00ab-4a86-bc30-b59e14951163" then potionDmg = 0.55
	elseif potionTemplate == "CON_Potion_Poison_Large_A_6d9420d8-cbf6-444f-ac42-c535a7df99f7" then potionDmg = 0.75
	elseif potionTemplate == "CON_Potion_Poison_Giant_A_f7d43db4-96b4-4db1-b83c-b21987b63a65" then potionDmg = 1
	elseif potionTemplate == "CON_Potion_Poison_Huge_A_5b31c4c8-88cd-4d86-9c23-f762126ee7f0" then potionDmg = 1
	elseif potionTemplate == "CON_Potion_Poison_Elixir_6a49fb10-6f0b-4caf-9caf-9e74901dbc72" then potionDmg = 0.2
	else return
	end
	SetStoryEvent(character, "LX_Get_Max_HP")
	local charMaxHP = GetVarFloat(character, "LX_Max_HP")
	potionDmg = charMaxHP * potionDmg
	hitHandle = NRD_HitPrepare(character, character)
	NRD_HitAddDamage(hitHandle, "Poison", potionDmg)
	NRD_HitSetInt(hitHandle, "DamagedVitality", 1)
	NRD_HitSetString(hitHandle, "DeathType", "Acid")
	--NRD_HitSetInt(hitHandle, "Hit", 1)
	NRD_HitQryExecute(hitHandle)
end