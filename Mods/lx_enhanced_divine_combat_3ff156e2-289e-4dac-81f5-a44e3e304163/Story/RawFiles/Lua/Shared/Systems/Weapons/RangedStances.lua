---@param attacker CDivinityStatsCharacter
---@param target CDivinityStatsCharacter
---@param hitChance number
---@return number
Data.Math.HitChance.RegisterListener("ReflexStancePenalty", function(attacker, target, hitChance)
    if attacker.Character:GetStatus("LX_REFLEX_STANCE") ~= null then
        local distance = Helpers.CalculateVectorDistance(attacker.Character.WorldPos, target.Character.WorldPos) - target.Character.AI.AIBoundsRadius
        if distance > 8 then
            hitChance = hitChance/2
        end
    end
    return hitChance
end)

---Hunter mark accuracy bypass
---@param attacker CDivinityStatsCharacter
---@param target CDivinityStatsCharacter
---@param hitChance number
---@return number
Data.Math.HitChance.RegisterListener("HunterMark", function(attacker, target, hitChance)
    local hunterMark = target.Character:GetStatus("LX_HUNTERMARK_APPLIED")
    -- ActionState will be null if it's a skill on server side
    if hunterMark ~= null and hunterMark.StatusSourceHandle == attacker.Character.Handle then
        if Ext.IsServer() and hunterMark ~= null and attacker.Character.CharacterBody.ActionState == null then
            return 999
        elseif Ext.IsClient() and attacker.Character.ActionMachine.Layers[1].State and attacker.Character.ActionMachine.Layers[1].State.Type == "PrepareSkill" then
            return 100
        end
        return hitChance
    else
        return hitChance
    end
end)

if Ext.IsClient() then
    --- @param character EclCharacter
    --- @param skillName string
    --- @param tooltip TooltipData
    local function RapidFirePenaltyTooltip(character, skillName, tooltip)
        local skill = Ext.Stats.Get(skillName)
        if character:GetStatus("LX_RAPIDFIRE") == null or skill.Ability ~= "Ranger" or skill["Damage Multiplier"] == 0 or skill.ActionPoints == 1 then return end
        local desc = tooltip:GetElement("SkillDescription")
        tooltip:AppendElementAfter({
            Label = "<font color=#ff0000>Rapid fire damage penalty: -"..tostring(75/skill.ActionPoints).."%</font>",
            Type = "SkillDescription"
        }, desc)

    end

    --- @param character EclCharacter
    --- @param skillName string
    --- @param tooltip TooltipData
    local function ReloadSkillTooltip(character, skillName, tooltip)
        if skillName == "Shout_LX_Reload" then
            local desc = tooltip:GetElement("SkillDescription")
            local skill = Helpers.UserVars.GetVar(character, "VP_HuntsmanReloadLastSkill")
            if skill then
                local celerity = Data.Math.ComputeCharacterCelerity(character)
                local cdReduction = math.floor(celerity/math.abs(Ext.Stats.Get("Stats_LX_Reload").VP_Celerity))
                tooltip:AppendElementAfter({
                    Label = "<font color=#FFEA8C>Available Celerity: "..tostring(celerity/100).."m<br>Cooldown reduction: "..tostring(cdReduction).."<br>Final cooldown: "..tostring(math.max(math.floor(character.SkillManager.Skills[skill].ActiveCooldown/6) - cdReduction, 0)).."</font>",
                    Type = "SkillDescription"
                }, desc)
                tooltip:AppendElementAfter({
                    Label = "<font color=#FFEA8C>Will apply to: "..Ext.L10N.GetTranslatedStringFromKey(skill.."_DisplayName").."</font>",
                    Type = "SkillDescription"
                }, desc)
            else
                tooltip:AppendElementAfter({
                    Label = "<font color=#FFEA8C>No elligible skill used yet!</font>",
                    Type = "SkillDescription"
                }, desc)
            end
        end
    end
    Ext.Events.SessionLoaded:Subscribe(function(e)
        Game.Tooltip.RegisterListener("Skill", nil, RapidFirePenaltyTooltip)
        Game.Tooltip.RegisterListener("Skill", nil, ReloadSkillTooltip)
    end)
end