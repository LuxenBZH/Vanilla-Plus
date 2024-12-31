--------------
--- CLIENT ---
--------------
if Ext.IsClient() then
    local impactEffect
    local visual
    local targeted = {}
    local validatedPos = nil

    --- REF: Mace WA Effect
    Ext.RegisterNetListener("LX_WA_MaceSendEffect", function(channel, payload)
        impactEffect = tonumber(payload)
        local item = Ext.ClientEntity.GetItem(tonumber(payload))
        visual = Ext.ClientVisual.CreateOnItem(item.WorldPos, item) ---@type EclLuaVisualClientMultiVisual
        visual:ParseFromStats("VP_FX_Target_Circle_3x", "")
        visual = visual.Handle
    end)

    ---Customize the skills targeting
    ---@return table
	Ext.ClientBehavior.Skill.AddGlobal(function()
		local EclCustomSkillState = {}

		---@class ev CustomSkillEventParams
		---@param skillState EclSkillState
		---@param inputEvent InputEvent
		---@return boolean
		function EclCustomSkillState:EnterBehaviour(ev,skillState)
            local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
            local statEntry = Ext.Stats.Get(string.gsub(skillState.SkillId, "%_%-1", ""))
            --- REF: Spear WA
            if character:GetStatus("LX_WA_RANGEPLUS") and statEntry.UseWeaponDamage == "Yes" then
                if skillState.Type == "Target" or skillState.Type == "MultiStrike" then
                    skillState.TargetRadius = skillState.TargetRadius *1.35
                elseif skillState.Type == "Shout" then
                    skillState.AreaRadius = skillState.AreaRadius * 1.35
                end
            --- REF: Mace WA
            elseif character:GetStatus("LX_WA_MACE") and statEntry.UseWeaponDamage == "Yes" and (skillState.Type == "Zone" or skillState.Type == "Rush") then
                Ext.Net.PostMessageToServer("LX_WA_MaceCreateEffect", tostring(character.NetID))
                Ext.Net.PostMessageToServer("LX_CreateCustomTargetEffect", Ext.Json.Stringify({
                    UserID = character.UserID,
                    Radius = 3,

                }))
                local cursorPosition = Ext.ClientUI.GetPickingState().WalkablePosition
                local coneStartPosition = Helpers.CalculatePositionFromDirection(character.WorldPos, cursorPosition, (math.max(character.AI.AIBoundsRadius + 0.6, statEntry.FrontOffset/2000-0.2)))
                Helpers.AuraTargeting.Client.ApplyTargeting(skillState.Type == "Rush" and cursorPosition or coneStartPosition, 3, false, false, true, true, character)
                if skillState.Type == "Zone" then
                    Helpers.Timer.Start(100, function()
                        Helpers.AuraTargeting.Client.SetTrackerTarget(Ext.ClientEntity.GetItem(impactEffect))
                    end)
                end
                -- visual:AddVisual("")
                --- note: create visual by creating an invisible item with the template GUID "9a0c0892-64ff-4e2c-9137-322efe4946c2"
                --- Once created on the server, create a visual with Ext.ClientVisual.Create
                --- Then apply an FX by using visual:ParseFromStats("RS3_FX_UI_Target_Circle_01", "") (it says FromStats but it takes the FX name directly)
                --- Then move the item by change the EclItem.Translate coordinate on tick
                --- Don't forget to delete the item once the skill is decast or casted.
            end
			return false
		end

        ---@param ev CustomSkillEventParams
        ---@param skillState EclSkillState
        ---@param targetHandle ComponentHandle
        ---@param targetPos vec3
        ---@param snapToGrid boolean
        ---@param fillInHeight boolean
        ---@return CustomSkillState.ValidateTargetResult
        function EclCustomSkillState:GetTargetMoveDistance(ev, skillState)
            local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
            local statEntry = Ext.Stats.Get(string.gsub(skillState.SkillId, "%_%-1", ""))
            if character:GetStatus("LX_WA_MACE") and statEntry.UseWeaponDamage == "Yes" then
                if impactEffect and visual then
                    if skillState.Type == "Rush" then
                        Ext.ClientEntity.GetItem(impactEffect).Translate = Ext.ClientUI.GetPickingState().WalkablePosition
                    elseif skillState.Type == "Zone" then
                        Ext.ClientEntity.GetItem(impactEffect).Translate = Helpers.CalculatePositionFromDirection(character.WorldPos, Ext.ClientUI.GetPickingState().WalkablePosition, math.max(character.AI.AIBoundsRadius + 0.6, statEntry.FrontOffset/2000-0.2))
                    end
                end
            end
            return 1
        end

        -----WA Effect trigger
        ---@param ev CustomSkillEventParams
        ---@param skillState EclSkillState
        function EclCustomSkillState:EnterAction(ev, skillState)
            local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
            local statEntry = Ext.Stats.Get(string.gsub(skillState.SkillId, "%_%-1", ""))
            --- REF: Spear WA effect
            if character:GetStatus("LX_WA_RANGEPLUS") and statEntry.UseWeaponDamage == "Yes" then
                if skillState.Type == "Shout" then
                    Ext.Net.PostMessageToServer("LX_WA_RangePlusShout", Ext.Json.Stringify({
                        Character = character.NetID,
                        WeaponRange = character.Stats.MainWeapon.DynamicStats[1].WeaponRange + (skillState.AreaRadius - (skillState.AreaRadius/1.35))
                    }))
                end
            --- REF: Mace WA effect
            elseif character:GetStatus("LX_WA_MACE") and statEntry.UseWeaponDamage == "Yes" then
                if skillState.Type == "Rush" then
                    Helpers.Timer.StartNamed("WA_Mace_Impact_Trigger", 10, function(netID, targetPosition, originalSkill)
                        local character = Ext.ClientEntity.GetCharacter(netID)
                        if Ext.Math.Distance(character.WorldPos, targetPosition) < 0.25 then
                            local statEntry = Ext.Stats.Get(originalSkill)
                            local effectName = "Projectile_LX_WA_Mace_Impact_"..tostring(statEntry["Damage Multiplier"])
                            if not Ext.Stats.Get(effectName, nil, false, false) then
                                local effect = Ext.Stats.Create(effectName, "SkillData", "Projectile_LX_WA_Mace_Impact")
                                effect["Damage Multiplier"] = statEntry.ActionPoints * Ext.Stats.Get("LX_WA_MACE").VP_WA_DamagePerAP
                                Ext.Stats.Sync(effectName, false)
                            end
                            Ext.Net.PostMessageToServer("LX_ExplodeOnPosition", Ext.Json.Stringify({
                                Source = netID,
                                Skill = effectName,
                                TargetPosition = targetPosition
                            }))
                            Helpers.Timer.Delete("WA_Mace_Impact_Trigger")
                        end
                    end, 200, character.NetID, skillState.TargetPosition, statEntry.Name)
                elseif skillState.Type == "Zone" then
                    Helpers.Timer.StartNamed("WA_Mace_Impact_Trigger", 5, function(netID, targetPosition, originalSkill)
                        if Ext.ClientEntity.GetCharacter(netID).SkillManager.CurrentSkill.State == "CastFinished" then
                            local statEntry = Ext.Stats.Get(originalSkill)
                            local effectName = "Projectile_LX_WA_Mace_Impact_"..tostring(statEntry["Damage Multiplier"])
                            if not Ext.Stats.Get(effectName, nil, false, false) then
                                local effect = Ext.Stats.Create(effectName, "SkillData", "Projectile_LX_WA_Mace_Impact")
                                effect["Damage Multiplier"] = statEntry.ActionPoints * Ext.Stats.Get("LX_WA_MACE").VP_WA_DamagePerAP
                                Ext.Stats.Sync(effectName, false)
                            end
                            Ext.Net.PostMessageToServer("LX_ExplodeOnPosition", Ext.Json.Stringify({
                                Source = netID,
                                Skill = effectName,
                                TargetPosition = targetPosition
                            }))
                            Helpers.Timer.Delete("WA_Mace_Impact_Trigger")
                        end
                    end, 400, character.NetID, Ext.ClientEntity.GetItem(impactEffect).Translate, statEntry.Name)
                end
            end
            Helpers.AuraTargeting.Client.Stop()
            if impactEffect then
                if visual then
                    Ext.ClientVisual.Get(visual):Delete()
                    visual = nil
                end
                Ext.Net.PostMessageToServer("LX_DeleteEffectItem", tostring(impactEffect))
                impactEffect = nil
            end
            return false
        end

        ---@param ev CustomSkillEventParams
        ---@param skillState EclSkillState
        function EclCustomSkillState:ExitBehaviour(ev, skillState)
            Helpers.AuraTargeting.Client.Stop()
            if impactEffect then
                if visual then
                    Ext.ClientVisual.Get(visual):Delete()
                    visual = nil
                end
                Ext.Net.PostMessageToServer("LX_DeleteEffectItem", tostring(impactEffect))
                impactEffect = nil
            end
            return false
        end

		return EclCustomSkillState
	end)

    ------ Tooltips
    --- @param character EclCharacter
    --- @param skillName string
    --- @param tooltip TooltipData
    local function WeaponArtSkillTooltip(character, skillName, tooltip)
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

    ---@param character EclCharacter
    ---@param status EclStatus
    ---@param tooltip TooltipData
    local function WeaponArtStatusTooltip(character, status, tooltip)
        if status.StatusId == "LX_WEAPON_EXECUTE" then
            local description = tooltip:GetElement("StatusDescription")
            description.Label = Helpers.String.SubstituteIndexedParams(description.Label, status.StatsMultiplier)
        end
    end
    Ext.Events.SessionLoaded:Subscribe(function(e)
        Game.Tooltip.RegisterListener("Skill", nil, WeaponArtSkillTooltip)
        Game.Tooltip.RegisterListener("Status", nil, WeaponArtStatusTooltip)
    end)
end

--------------
--- SERVER ---
--------------
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

    Ext.RegisterNetListener("LX_WA_MaceCreateEffect", function(channel, payload)
        local character = Ext.ServerEntity.GetCharacter(tonumber(payload))
        local item = Ext.ServerEntity.GetItem(CreateItemTemplateAtPosition("9a0c0892-64ff-4e2c-9137-322efe4946c2", character.WorldPos[1], character.WorldPos[2], character.WorldPos[3]))
        Helpers.Timer.Start(99, function(characterGUID, itemNetID) Ext.Net.PostMessageToClient(characterGUID, "LX_WA_MaceSendEffect", tostring(itemNetID)) end, nil, character.MyGuid, item.NetID)
    end)

    Ext.RegisterNetListener("LX_DeleteEffectItem", function(channel, payload)
        local item = Ext.ServerEntity.GetItem(tonumber(payload))
        ItemRemove(item.MyGuid)
    end)

    Ext.RegisterNetListener("LX_ExplodeOnPosition", function(channel, payload, ...)
        local info = Ext.Json.Parse(payload)
        --- TODO: check if there's a better way to handle it since it cause a small game freeze on explosion
        Helpers.LaunchProjectile(info.TargetPosition, info.TargetPosition, info.Skill, {
            GuidString = {
                Source = Ext.ServerEntity.GetCharacter(info.Source).MyGuid,
                Caster = Ext.ServerEntity.GetCharacter(info.Source).MyGuid,
            }
        })
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