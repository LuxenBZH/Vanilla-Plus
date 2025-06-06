Ext.RegisterSkillProperty("CUSTOMSURFACEBOOST", {
    GetDescription = function (property)
        return Ext.L10N.GetTranslatedStringFromKey("Stats_Property_SurfaceBoost")
    end
})

Ext.RegisterSkillProperty("LX_SHIELD", {
	GetDescription = function(property)
		local statProperties = {}
		local index = 1
		for value in string.gmatch(property.Arg3, "(.-)/") do
			statProperties[index] = value
			index = index + 1
		end
		-- 1: Type, 2: Damage scaling, 3: Amount, 4: Duration, 5: Can reinforce existing shield
		local scaledAmount = Ext.Utils.Round(DamageScalingFormulas[statProperties[2]](Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.GetUIByType(40):GetRoot().hotbar_mc.characterHandle)).Stats.Level))
		if statProperties[5] == "1" then
			return Helpers.GetDynamicTranslationStringFromKey("Stats_Absorb_DynamicTooltip_B", scaledAmount, statProperties[1])
		else
			return Helpers.GetDynamicTranslationStringFromKey("Stats_Absorb_DynamicTooltip", scaledAmount, statProperties[1])
		end
	end
})

---@param e EclLuaStatusGetDescriptionParamEvent
local function ShieldDescription(e)
    if e.Params[1] == "LX_Absorption" then
		Helpers.VPPrint(Helpers.GetDynamicTranslationStringFromKey("Status_Absorb_Description", Ext.Utils.Round(e.Owner.Character:GetStatus(e.Status.StatusName).StatsMultiplier)), "CustomSkillProperties:ShieldDescription")
		e.Description = Data.Text.GetFormattedDamageText(Helpers.StatusGetAbsorbShieldElement(e.Status.StatusName), Ext.Utils.Round(e.Owner.Character:GetStatus(e.Status.StatusName).StatsMultiplier))
        -- e.Description = tostring(Ext.Utils.Round(e.Owner.Character:GetStatus(e.Status.StatusName).StatsMultiplier)).." "..(Helpers.StatusGetAbsorbShieldElement(e.Status.StatusName) or "").." damage"
	end
end

Ext.Events.StatusGetDescriptionParam:Subscribe(ShieldDescription)

--- @param status EsvStatus
--- @param statusSource EsvGameObject
--- @param character StatCharacter
--- @param par string
local function CSBStatusDescriptionParam(status, statusSource, statCharacter, par)
	if string.match(par, "CSB%-") then
		local field = string.gsub(par, "CSB%-", "")
		local statEntry = status.Name.."_"..field.."_"
		if string.match(par, "WPN%-") then
			field = string.gsub(par, "WPN%-", "")
			statEntry = Ext.GetStat(status.StatsId).BonusWeapon
		end
		local character = statCharacter.Character
		for i, sts in pairs(character:GetStatuses()) do
			-- Ext.Print("status:", sts)
			if string.match(sts, statEntry) then
				statEntry = string.gsub(sts, "LXC_Proxy_", "")
			end
		end
		local damage = {Min=0, Max=0}
		statEntry = Ext.GetStat(statEntry)
		if field == "DamageFromBase" then
			local dmg = 0
			if statEntry.Damage == 1 then
				dmg = Game.Math.GetAverageLevelDamage(statCharacter.Level)
			else
				dmg = Game.Math.GetLevelScaledWeaponDamage(statCharacter.Level)
			end
			local globalMult = 1 + (statCharacter.Strength-10) * (Ext.ExtraData.DGM_StrengthGlobalBonus*0.01 + Ext.ExtraData.DGM_StrengthWeaponBonus*0.01) +
				(statCharacter.Finesse-10) * (Ext.ExtraData.DGM_FinesseGlobalBonus*0.01) +
				(statCharacter.Intelligence-10) * (Ext.ExtraData.DGM_IntelligenceGlobalBonus*0.01)
			local damageTypeBoost = 1.0 + Game.Math.GetDamageBoostByType(statCharacter, statEntry["Damage Type"])
			dmg = dmg*(statEntry.DamageFromBase/100)*damageTypeBoost
			local dmgRange = dmg*(statEntry["Damage Range"])*0.005
			
			local minDmg = math.floor(Ext.Round((dmg - dmgRange)*globalMult))
			local maxDmg = math.ceil((dmg + dmgRange)*globalMult)
			if maxDmg <= minDmg then maxDmg = maxDmg+1 end
			local color = Helpers.GetDamageColor(statEntry["Damage Type"])
			return "<font color="..color..">"..tostring(minDmg).."-"..tostring(maxDmg).." "..statEntry["Damage Type"].." "..Ext.L10N.GetTranslatedString("h9531fd22g6366g4e93g9b08g11763cac0d86", "Damage").."</font>"
		end
	end
end

Ext.RegisterListener("StatusGetDescriptionParam", CSBStatusDescriptionParam)


Ext.RegisterSkillProperty("VP_TryKill", {
	---@param property StatsPropertyExtender
	GetDescription = function(property)
		if getmetatable(target) == "esv::Item" then return end
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
		local attacker = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(40):GetRoot().hotbar_mc.characterHandle))
		local baseDamage = Helpers.GetScaledValue(scaling, nil, attacker)
		local computedThreshold = Ext.Utils.Round(baseDamage * value / 100)
		local additionalSPDamage = ""
		if SPDamageBonus ~= 0 then
			local source = attacker.Stats.MPStart
			local computedSPBonusValue = 0
			if source > SPConsumptionCap then
				computedSPBonusValue = SPConsumptionCap * SPDamageBonus
			else
				computedSPBonusValue = source * SPDamageBonus
			end
			additionalSPDamage = ". "..Helpers.GetDynamicTranslationStringFromKey("Stats_Property_TryKill_Source", SPConsumptionCap, Ext.Utils.Round(baseDamage*SPDamageBonus/100), Ext.Utils.Round(baseDamage * (value + computedSPBonusValue)/ 100))
		end
		local additionalStatusDamage = ""
		if #statusesArray > 0 then
			additionalStatusDamage = ". "..Helpers.GetDynamicTranslationStringFromKey("Stats_Property_TryKill_Influence",Ext.Utils.Round(baseDamage*statusBonusValue/100))
			for i,status in pairs(statusesArray) do
				if i == 1 then
					additionalStatusDamage = additionalStatusDamage..Ext.L10N.GetTranslatedStringFromKey(Ext.Stats.Get(status).DisplayName)
				else
					additionalStatusDamage = additionalStatusDamage..", "..Ext.L10N.GetTranslatedStringFromKey(Ext.Stats.Get(status).DisplayName)
				end
			end
		end
		return "<font size='18'>"..Helpers.GetDynamicTranslationStringFromKey("Stats_Property_TryKill_Tooltip",computedThreshold)..additionalSPDamage..additionalStatusDamage..".</font>"
	end
})