---- Talents ----
function CheckBoostTalents(character, talent, unlocked)
	Ext.Print("Talent ",talent," changed :",unlocked)
	if unlocked == 1 then
		unlocked = true
	else
		unlocked = false
	end
	
	if talent == "Resurrection" then
		Ext.Print("[LXGDM_Talents.CheckBoostTalents] Check Talents after resurrection...")
		CheckAllTalents(character)
	end
	
	if talent == "Demon" then
		BoostFromTalentInt(character, "LX_DEMON", unlocked)
	elseif talent == "IceKing" then
		BoostFromTalentInt(character, "LX_ICEKING", unlocked)
	elseif talent == "Leech" then
		BoostFromTalentInt(character, "LX_LEECH", unlocked)
	elseif talent == "Stench" then
		BoostFromTalentInt(character, "LX_STENCH", unlocked)
	elseif talent == "AnimalEmpathy" then
		BoostFromTalentInt(character, "LX_PETPALSUMMONER", unlocked)
	elseif talent == "ResurrectToFullHealth" then
		BoostFromTalentInt(character, "LX_MORNINGPERSON", unlocked)
	elseif talent == "NoAttackOfOpportunity" then
		BoostFromTalentInt(character, "LX_DDGOOSE", unlocked)
	elseif talent == "Memory" then
		ManageMemory(character, unlocked)
	elseif talent == "Perfectionist" then
		CheckHothead(character)
	end
end

function ManageMemory(character, unlocked)
	if unlocked then
		InitCharacterStatCheck(character)
	else
		local memBonus = NRD_CharacterGetPermanentBoostInt(character, "Memory")
		local mem = CharacterGetBaseAttribute(character, "Memory") - 10 - memBonus
		if memBonus == mem then
			NRD_CharacterSetPermanentBoostInt(character, "Memory", 0)
		else
			NRD_CharacterSetPermanentBoostInt(character, "Memory", memBonus - mem)
		end
		CharacterAddAttribute(character, "Dummy", 0)
	end
end

function CheckAllTalents(character)
	local boostedTalents = {
		"Demon",
		"IceKing",
		"Leech",
		"Stench",
		"AnimalEmpathy",
		"ResurrectToFullHealth",
		"NoAttackOfOpportunity"
	}
	for i,talent in pairs(boostedTalents) do
		local hasTalent = CharacterHasTalent(character, talent)
		print("[LXDGM_Talents.CheckAllTalents] Character has talent:",talent,hasTalent)
		if hasTalent == 1 then CheckBoostTalents(character, talent, 1) end
	end
	if CharacterHasTalent(character, "ExtraStatPoints") == 1 then CheckDuelist(character) end
end

function CheckDuelist(character)
	local mainHand = Ext.GetCharacter(character).Stats.MainWeapon
	Ext.Print("[LXDGM_Talents.CheckDuelist] Main hand :",mainHand)
	local offhand = Ext.GetCharacter(character).Stats.OffHandWeapon
	local shield = CharacterGetEquippedShield(character)
	if offhand ~= nil or (mainHand ~= nil and mainHand.IsTwoHanded) or mainHand.WeaponType == "None" or shield ~= nil then
		RemoveStatus(character, "LX_DUELIST")
	else
		ApplyStatus(character, "LX_DUELIST", -1.0, 1)
	end
end

function BoostFromTalentInt(character, status, unlocked)
	if unlocked then
		ApplyStatus(character, status, -1.0, 1)
	else
		RemoveStatus(character, status)
	end
end

function SetWalkItOff(target, handle)
	-- Call this function during damage control to potentially apply Walk It Off bonus
	local hasTalent = CharacterHasTalent(target, "WalkItOff")
	-- Ext.Print("Target has WalkItOff: ",hasTalent)
	if hasTalent == 1 then
		local hitType = NRD_StatusGetInt(target, handle, "HitType")
		if hitType ~= 4 then WalkItOffReplacement(target) end
	end
end

function WalkItOffReplacement(character)
	local hasStatus = 0
	local wioStates = {"LX_WALKITOFF", "LX_WALKITOFF_2", "LX_WALKITOFF_3", "LX_WALKITOFF_4", "LX_WALKITOFF_5"}
	local reapply = false
	for i,stage in pairs(wioStates) do
		if reapply == true then
			ApplyStatus(character, stage, 6.0)
			return 
		end
		hasStatus = HasActiveStatus(character, stage)
		Ext.Print("Has ",stage, ": ", hasStatus)
		if hasStatus == 1 then reapply = true end
		if stage == "LX_WALKITOFF_5" then return end
	end
	ApplyStatus(character, "LX_WALKITOFF", 6.0)
end

function CheckHothead(character)
	local HPperc = Ext.Round(NRD_CharacterGetStatInt(character, "CurrentVitality") / NRD_CharacterGetStatInt(character, "MaxVitality") * 100)
	Ext.Print(HPperc)
	if HPperc > 74.0 then ApplyStatus(character, "LX_HOTHEAD", -1.0, 1) end
end

function ManageAllSkilledUp(character, skill, cooldown)
	local hasUsedSkill = GetVarInteger(character, "LX_AllSkilledUp_Counter")
	if hasUsedSkill == 0 then
		NRD_SkillSetCooldown(character, skill, (cooldown-6.0))
		SetVarInteger(character, "LX_AllSkilledUp_Counter", 1)
	end
end