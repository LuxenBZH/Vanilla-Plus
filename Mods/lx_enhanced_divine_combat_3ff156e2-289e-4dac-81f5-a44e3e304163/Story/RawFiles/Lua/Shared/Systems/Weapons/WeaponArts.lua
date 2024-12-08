--------------
--- CLIENT ---
--------------
if Ext.IsClient() then
    local impactEffect
    local visual
    local targeted = {}

    Ext.RegisterNetListener("LX_WA_MaceSendEffect", function(channel, payload)
        impactEffect = tonumber(payload)
        local item = Ext.ClientEntity.GetItem(tonumber(payload))
        visual = Ext.ClientVisual.CreateOnItem(item.WorldPos, item) ---@type EclLuaVisualClientMultiVisual
        visual:ParseFromStats("VP_FX_Target_Circle_3x", "")
        visual = visual.Handle
    end)
	Ext.ClientBehavior.Skill.AddGlobal(function()
		local EclCustomSkillState = {}

		---@class ev CustomSkillEventParams
		---@param skillState EclSkillState
		---@param inputEvent InputEvent
		---@return boolean
		function EclCustomSkillState:EnterBehaviour(ev,skillState)
            local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
            local statEntry = Ext.Stats.Get(string.gsub(skillState.SkillId, "%_%-1", ""))
            if character:GetStatus("LX_WA_RANGEPLUS") and statEntry.UseWeaponDamage == "Yes" then
                if skillState.Type == "Target" or skillState.Type == "MultiStrike" then
                    skillState.TargetRadius = skillState.TargetRadius *1.35
                elseif skillState.Type == "Shout" then
                    skillState.AreaRadius = skillState.AreaRadius * 1.35
                end
            elseif character:GetStatus("LX_WA_MACE") and statEntry.UseWeaponDamage == "Yes" and (skillState.Type == "Zone" or skillState.Type == "Rush") then
                Ext.Net.PostMessageToServer("LX_WA_MaceCreateEffect", tostring(character.NetID))
                Ext.Net.PostMessageToServer("LX_CreateCustomTargetEffect", Ext.Json.Stringify({
                    UserID = character.UserID,
                    Radius = 3,

                }))
                Helpers.AuraTargeting.Client.ApplyTargeting(skillState.Type == "Rush" and Ext.ClientUI.GetPickingState().WalkablePosition or character.WorldPos, 3, false, false, true, true, character)
                -- visual:AddVisual("")
                --- note: create visual by creating an invisible item with the template GUID "9a0c0892-64ff-4e2c-9137-322efe4946c2"
                --- Once created on the server, create a visual with Ext.ClientVisual.Create
                --- Then apply an FX by using visual:ParseFromStats("RS3_FX_UI_Target_Circle_01", "") (it says FromStats but it takes the FX name directly)
                --- Then move the item by change the EclItem.Translate coordinate on tick
                --- Don't forget to delete the item once the skill is decast or casted.
            end
			return false
		end

        local once = false
        
        ---@param ev CustomSkillEventParams
        ---@param skillState EclSkillState
        ---@param targetHandle ComponentHandle
        ---@param targetPos vec3
        ---@param snapToGrid boolean
        ---@param fillInHeight boolean
        ---@return CustomSkillState.ValidateTargetResult
        function EclCustomSkillState:ValidateTargetSight(ev, skillState, targetPos)
            local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
            local statEntry = Ext.Stats.Get(string.gsub(skillState.SkillId, "%_%-1", "")) 
            -- if not once and skillState.State ~= "Init" then
            --     _DS(skillState)
            --     _DS(targetPos)
            --     once = true
            -- end
            if character:GetStatus("LX_WA_MACE") and statEntry.UseWeaponDamage == "Yes" and (skillState.Type == "Zone" or skillState.Type == "Rush") then
                if impactEffect and visual then
                    Ext.ClientEntity.GetItem(impactEffect).Translate = Ext.ClientUI.GetPickingState().WalkablePosition
                end
                
                -- local pos = skillState.Type == "Rush" and Ext.ClientUI.GetPickingState().WalkablePosition or character.WorldPos
                -- local inRange = Helpers.GetCharactersAroundPosition(pos[1], pos[2], pos[3], 3)
                -- for netID,effect in pairs(targeted) do

                --     if Ext.Math.Distance(pos, Ext.ClientEntity.GetCharacter(netID).WorldPos) > 3 then
                --         Ext.ClientVisual.Get(effect):Delete()
                --         targeted[netID] = nil
                --     end
                -- end
                -- for i,char in pairs(inRange) do
                --     if not targeted[char.NetID] then
                --         local arrowBillboard = Ext.ClientVisual.CreateOnCharacter({char.WorldPos[1], char.WorldPos[2], char.WorldPos[3]}, char) ---@type EclLuaVisualClientMultiVisual
                --         -- local arrowBillboard = Ext.ClientVisual.Create({char.WorldPos[1], char.WorldPos[2]+char.AI.AIBoundsHeight*1.15, char.WorldPos[3]}) ---@type EclLuaVisualClientMultiVisual
                --         arrowBillboard:ParseFromStats("RS3_FX_UI_Icon_TriangleDown_01_Yellow_Active", "")
                --         targeted[char.NetID] = arrowBillboard.Handle
                --     end
                -- end
            end
            return 1
        end

        -- ---@param ev CustomSkillEventParams
        -- ---@param skillState EclSkillState
        -- function EclCustomSkillState:TickAction(ev, skillState)
        --     local character = Ext.ClientEntity.GetCharacter(skillState.CharacterHandle)
        --     local statEntry = Ext.Stats.Get(string.gsub(skillState.SkillId, "%_%-1", "")) ---@type StatEntrySkillData
        --     if character:GetStatus("LX_WA_MACE") and statEntry.SkillType == "Rush" and statEntry.UseWeaponDamage == "Yes" then
        --         if impactEffect and visual then
        --             impactEffect.Translate = skillState.TargetPosition
        --         end
        --     end
        -- end

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