if Ext.IsClient() then
	Ext.ClientBehavior.Skill.AddGlobal(function()
		local EclCustomSkillState = {}
		---@class ev CustomSkillEventParams
		---@param skillState EclSkillState
		---@param inputEvent InputEvent
		---@return boolean
		function EclCustomSkillState:EnterBehaviour(ev,skillState)
            local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
            if character:GetStatus("LX_WA_RANGEPLUS") then
                local statEntry = Ext.Stats.Get(string.gsub(skillState.SkillId, "%_%-1", ""))
                if statEntry.UseWeaponDamage == "No" then return false end
                if skillState.Type == "Target" or skillState.Type == "MultiStrike" then
                    skillState.TargetRadius = skillState.TargetRadius *1.35
                elseif skillState.Type == "Shout" then
                    skillState.AreaRadius = skillState.AreaRadius * 1.35
                end
            end
			return false
		end

        ---@param ev CustomSkillEventParams
        ---@param skillState EclSkillState
        function EclCustomSkillState:EnterAction(ev, skillState)
            local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
            if character:GetStatus("LX_WA_RANGEPLUS") then
                local statEntry = Ext.Stats.Get(string.gsub(skillState.SkillId, "%_%-1", ""))
                if statEntry.UseWeaponDamage == "No" then return false end
                if skillState.Type == "Shout" then
                    Ext.Net.PostMessageToServer("LX_WA_RangePlusShout", Ext.Json.Stringify({
                        Character = character.NetID,
                        WeaponRange = character.Stats.MainWeapon.DynamicStats[1].WeaponRange + (skillState.AreaRadius - (skillState.AreaRadius/1.35))
                    }))
                end
            end
            return false
        end
		return EclCustomSkillState
	end)

    --- @param character EclCharacter
    --- @param skillName string
    --- @param tooltip TooltipData
    local function WeaponArtTooltip(character, skillName, tooltip)
        local statEntry = Ext.Stats.Get(skillName)
        if character:GetStatus("LX_WA_TWOHANDED") and statEntry.UseWeaponDamage and statEntry["Damage Multiplier"] > 0 then
            local desc = tooltip:GetElement("SkillDescription")
            tooltip:AppendElementAfter({
                Label = "<font color=#FFEA8C>Weapon Art:<br>• Damage: +"..tostring((1 + statEntry.ActionPoints) / statEntry.ActionPoints * 100 - 100).."%<br>• Cooldown: "..tostring(-math.ceil(statEntry.Cooldown*0.30)).."</font>",
                Type = "SkillDescription"
            }, desc)
        elseif character:GetStatus("LX_WA_DUALWIELDING") and statEntry.UseWeaponDamage and statEntry["Damage Multiplier"] > 0 then
            local desc = tooltip:GetElement("SkillDescription")
            tooltip:AppendElementAfter({
                Label = "<font color=#FFEA8C>Weapon Art:<br>• Damage: "..Data.Text.FormatNumberDigitsNoZero((statEntry.ActionPoints - 1) / statEntry.ActionPoints * 100 - 100).."%<br>• Cooldown: +"..tostring(math.ceil(statEntry.Cooldown*0.30)).."</font>",
                Type = "SkillDescription"
            }, desc)
        elseif character:GetStatus("LX_WA_RANGEPLUS") and statEntry.UseWeaponDamage and statEntry["Damage Multiplier"] > 0 and (statEntry.SkillType == "Target" or statEntry.SkillType == "Shout" or statEntry.SkillType == "MultiStrike") then
            local desc = tooltip:GetElement("SkillRange")
            if desc then
                _DS(desc)
                local value = desc.Value:gsub("m", "")
                local bonus = Data.Text.FormatNumberDigitsNoZero(value * 0.3)
                desc.Value = value.."m".."<font color=#FFEA8C> +"..bonus.."m</font>"
            else
                desc = {
                    Label = "Range",
                    Type = "SkillRange",
                    Value = statEntry.AreaRadius + character.Stats.MainWeapon.WeaponRange/100 + 0.25
                }
                local bonus = Data.Text.FormatNumberDigitsNoZero(desc.Value * 0.3)
                desc.Value = desc.Value.."m".."<font color=#FFEA8C> +"..bonus.."m</font>"
                tooltip:AppendElementAfterType(desc, "SkillRange")
            end
        end
    end
    Ext.Events.SessionLoaded:Subscribe(function(e)
        Game.Tooltip.RegisterListener("Skill", nil, WeaponArtTooltip)
    end)
end

if Ext.IsServer() then
    Ext.RegisterNetListener("LX_WA_RangePlusShout", function(channel, payload, ...)
        local info = Ext.Json.Parse(payload)
        local character = Ext.ServerEntity.GetCharacter(tonumber(info.Character))
        Helpers.Timer.Start(2000, function(character, weaponRange)
            local character = Ext.ServerEntity.GetCharacter(character)
            character.Stats.MainWeapon.DynamicStats[1].WeaponRange = weaponRange
        end, nil, character.NetID, character.Stats.MainWeapon.DynamicStats[1].WeaponRange)
        character.Stats.MainWeapon.DynamicStats[1].WeaponRange = tonumber(info.WeaponRange)
    end)
    Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "before", function(character, skill, _, _)
        local character = Ext.ServerEntity.GetCharacter(character)
        local statEntry = Ext.Stats.Get(skill)
        if character:GetStatus("LX_WA_TWOHANDED") then
            local status = Ext.PrepareStatus(character.MyGuid, "LX_DAMAGEMODIFIER", 6.0)
            status.StatsMultiplier = (1 + statEntry.ActionPoints) / statEntry.ActionPoints * 100 - 100
            Ext.ApplyStatus(status)
            Helpers.Timer.StartNamed("LX_WA_TwoHandedDamage", 30, function(guid)
                local character = Ext.ServerEntity.GetCharacter(guid)
                if character.ActionMachine.Layers[1].State == null then
                    RemoveStatus(character.MyGuid, "LX_DAMAGEMODIFIER")
                    Helpers.Timer.Delete("LX_WA_TwoHandedDamage")
                end
            end, 210, character.MyGuid)
            Helpers.Character.AddSkillCooldown(character, skill, -math.ceil(statEntry.Cooldown*0.30)*6)
        elseif character:GetStatus("LX_WA_DUALWIELDING") then
            local status = Ext.PrepareStatus(character.MyGuid, "LX_DAMAGEMODIFIER", 6.0)
            status.StatsMultiplier = (statEntry.ActionPoints - 1) / statEntry.ActionPoints * 100 - 100
            Ext.ApplyStatus(status)
            Helpers.Timer.StartNamed("LX_WA_DualWieldingDamage", 30, function(guid)
                local character = Ext.ServerEntity.GetCharacter(guid)
                if character.ActionMachine.Layers[1].State == null then
                    RemoveStatus(character.MyGuid, "LX_DAMAGEMODIFIER")
                    Helpers.Timer.Delete("LX_WA_DualWieldingDamage")
                end
            end, 210, character.MyGuid)
            Helpers.Character.AddSkillCooldown(character, skill, math.ceil(statEntry.Cooldown*0.30)*6)
        end
    end)
end

Data.APCostManager.RegisterGlobalSkillAPFormula("LX_WeaponArts", function(e)
    local skill = e.Skill.StatsObject.StatsEntry ---@type StatEntrySkillData
	local character = e.Character.Character ---@type EclCharacter|EsvCharacter
    e.AP = skill.ActionPoints
	e.ElementalAffinity = e.ElementalAffinity or false
    if character:GetStatus("LX_WA_TWOHANDED") and skill.UseWeaponDamage == "Yes" and skill["Damage Multiplier"] > 0 then
        e.AP = e.AP + 1
    elseif character:GetStatus("LX_WA_DUALWIELDING") and skill.UseWeaponDamage == "Yes" and skill["Damage Multiplier"] > 0 then
        e.AP = e.AP - 1
    end
end)