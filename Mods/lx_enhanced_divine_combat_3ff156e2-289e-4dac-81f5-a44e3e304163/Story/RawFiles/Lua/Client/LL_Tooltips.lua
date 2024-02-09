local notPotionStat = {}

Ext.RegisterListener("SessionLoaded", function()
    local objects = Ext.Stats.GetStats("Object")
    for i,object in pairs(objects) do
        notPotionStat[object] = true
    end
end)

--- @param item EclItem
local function ItemCanBeExtended(item)
    if item.StatsId then
        local stat = Ext.Stats.Get(item.StatsId)
        local template = item.RootTemplate
        local entryType = Helpers.Stats.GetEntryType(stat)
        if not item.Stats and entryType == "Potion"
          and GetParentStat(stat, "IsConsumable") == "Yes" and GetParentStat(stat, "IsFood") ~= "Yes" then
            return true
        end
        if entryType ~= "Potion" or not stat.ExtraProperties then return false end
        for i,property in pairs(stat.ExtraProperties) do
            if property.Action == "HEALING_ELIXIR" then
                return true
            end
        end
    end
    return false
end

--- @param character EsvCharacter
--- @param item EsvItem
--- @param tooltip TooltipData
local function OnItemTooltip(item, tooltip)
    if item.StatsId ~= nil then
        local element = tooltip:GetElement("ItemDescription")
        local stat = Ext.Stats.Get(item.StatsId)
        if ItemCanBeExtended(item) then
            tooltip:MarkDirty()
        end
        if tooltip:IsExpanded() then
            if item.ItemType ~= "Weapon" and GetParentStat(stat, "IsConsumable") == "Yes" and GetParentStat(stat, "IsFood") ~= "Yes" then      
                element.Label = element.Label.."<br><font color='#0783b7'>Drinking a second potion during your turn will reduce your AP by 1 the next turn, and drinking a third one will immediatly end your turn and reduce your AP by 3 the next turn.</font>"
            end
            if stat.ExtraProperties == nil then return end
            for i,property in pairs(stat.ExtraProperties) do
                if property.Action == "HEALING_ELIXIR" then
                    tooltip:AppendElement({
                        Type = "ConsumableEffect",
                        Label = "Clear Crippled, Atrophy and Diseased."
                    })
                end
            end
        end
    end
end

--- @param skill StatEntrySkillData
local function SkillCanBeExtended(skill)
    local hasStatusApplied = false
    if skill.SkillType == "Dome" then
        if skill.AuraAllies ~= "" or skill.AuraSelf ~= "" or skill.AuraEnemies then
            hasStatusApplied = true
        end
    end
    if skill.SkillProperties ~= nil then
        for i,property in pairs(skill.SkillProperties) do
            if property.Action == "EXPLODE" then
                hasStatusApplied = true
            elseif property.Type == "Status" then
                local status = Ext.Stats.Get(property.Action)
                if status ~= nil then
                    if status.StatusType == "DAMAGE" or status.LeaveAction ~= ""  or status.StatusType == "SPARK" or status.StatusType == "ACTIVE_DEFENSE" then
                        hasStatusApplied = true
                    end
                    if status.StatsId ~= "" then
                        local statsId = Ext.Stats.Get(status.StatsId)
                        if status.StatusType == "CONSUME" and status.StatsId ~= "" and statsId ~= nil and  statsId.BonusWeapon ~= "" then
                            hasStatusApplied = true
                        end
                    end
                end
            end
        end
    end
    if GetParentStat(skill, "Damage Multiplier") ~= 0 or skill.SkillType == "Storm" or hasStatusApplied or skill.SkillType == "Summon" then
        return true
    else
        return false
    end
end

--- @param element string
--- @param skill StatEntrySkillData
--- @param characterStats StatCharacter
--- @param isProjectile string
--- @param prefix string
--- @param radius boolean
local function ExtendDamage(element, skill, characterStats, isProjectile, prefix, radius)
    if prefix == nil then prefix = "" end
    if GetParentStat(skill, "Damage Multiplier") ~= 0 then
        if skill["Damage Range"] > 0 then
            local min = string.gsub(tostring(skill["Damage Multiplier"] - skill["Damage Range"]/2), "%.0", "")
            local max = string.gsub(tostring(skill["Damage Multiplier"] + skill["Damage Range"]/2), "%.0", "")
            element.Label=element.Label .. "<br><font color='#0783b7'>"..prefix.."Damage "..isProjectile..": "..min.."% - "..max.."%</font>"
        else
            element.Label=element.Label .. "<br><font color='#0783b7'>"..prefix.."Damage "..isProjectile..": "..skill["Damage Multiplier"].."%</font>"
        end
        if radius and skill.AreaRadius > 0 then
            element.Label=element.Label .. "<br><font color='#0783b7'>"..prefix.."Radius: "..skill.AreaRadius.."m</font>"
        end
        if skill.Damage == "BaseLevelDamage" or skill.Damage == "AverageLevelDamge" or skill.Damage == "MonsterWeaponDamage" then
            local generalBonus = math.floor((characterStats.Strength-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthGlobalBonus +
                                            (characterStats.Finesse-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_FinesseGlobalBonus +
                                            (characterStats.Intelligence-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceGlobalBonus)
            local strengthBonus = 0
            if GetParentStat(skill, "UseWeaponDamage") == "Yes" or skill.Name == "Target_TentacleLash" then
                strengthBonus = math.floor((characterStats.Strength-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthWeaponBonus)
            end
            local intelligenceBonus = characterStats.Intelligence-Ext.ExtraData.AttributeBaseValue
            local usesIntelligence = false
            if GetParentStat(skill, "UseWeaponDamage") == "No" then
                intelligenceBonus = math.floor(intelligenceBonus * (Ext.ExtraData.DGM_IntelligenceSkillBonus+Ext.ExtraData.DGM_IntelligenceGlobalBonus))
                usesIntelligence = true
            else
                intelligenceBonus = math.floor(intelligenceBonus * Ext.ExtraData.DGM_IntelligenceGlobalBonus)
            end
            element.Label=element.Label .. "<br><font color='#00cc00'>"..prefix.."Bonus from Attributes: "..generalBonus + strengthBonus + intelligenceBonus.."% </font>"
            element.Label=element.Label .. "<br><font color='#008000'>"..prefix.."• Global: "..generalBonus.."%"
            
            if GetParentStat(skill, "UseWeaponDamage") == "Yes" or skill.Name == "Target_TentacleLash" then
                element.Label=element.Label .. "<br>"..prefix.."• Strength: "..strengthBonus.."%"
            end
            if usesIntelligence then
                element.Label=element.Label .. "<br>"..prefix.."• Intelligence: "..intelligenceBonus.."%</font>"
            end
            if GetParentStat(skill, "UseWeaponDamage") == "Yes" then
                local ability = GetWeaponAbility(characterStats, characterStats.MainWeapon)
                if ability ~= nil then
                    local bonus = math.floor(Game.Math.ComputeWeaponCombatAbilityBoost(characterStats, characterStats.MainWeapon))
                    element.Label=element.Label .. "<br><font color='#ff8c1a'>"..prefix.."Bonus from "..weaponAbility[ability]..": "..bonus.."%</font>"
                end
            end
            local damageTypes = Game.Math.GetSkillDamageRange(characterStats, skill, true)
            -- if damageTypes == nil then damageTypes = Game.Math.GetSkillDamageRange(characterStats, {Name = "Target_HeavyAttack"}) end
            for dmgType, dmg in pairs(damageTypes) do
                local school = dmgTypeToSchool[dmgType]
                if school ~= nil then
                    local bonus = math.floor(Game.Math.GetDamageBoostByType(characterStats, dmgType)*100)
                    element.Label=element.Label .. "<br><font color='#ff8c1a'>"..prefix.."Bonus from "..school..": "..bonus.."%</font>"
                end
            end
        end
    end
end

local function ExtendStatusDamage(status, element, stats, statusName, isWeaponBonus)
    if isWeaponBonus then
        element.Label=element.Label .. "<br><font color='#e60000'>Weapon bonus: "..Mods.LeaderLib.GameHelpers.GetStringKeyText(statusName).."</font>"
    else
        element.Label=element.Label .. "<br><font color='#e60000'>Status: "..Mods.LeaderLib.GameHelpers.GetStringKeyText(statusName).."</font>"
    end
    if status ~= nil then
        local min = tostring(status.DamageFromBase - status["Damage Range"]/2):gsub("%.0", "")
        local max = tostring(status.DamageFromBase + status["Damage Range"]/2):gsub("%.0", "")
        element.Label=element.Label .. "<br><font color='#e60000'>• "..status["Damage Type"]..": "..min.."% - "..max.."%</font>"
        local witsBonus = (stats.Wits-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsDotBonus / 100
        if witsBonus > 0 and not isWeaponBonus then
            -- element.Label=element.Label .. "<br><font color='#e60000'>• Wits Multiplier: "..1+witsBonus.."</font>"
            element.Label=element.Label .. "<font color='#e60000'> (x"..1+witsBonus.." from Wits)</font>"
        end
    end
end

--- @param status StatEntryStatusData
--- @param element string
--- @param stats StatCharacter
local function ExtendStatus(status, element, stats)
    -- if (status.StatusType == "HEAL" or status.StatusType == "HEALING") then
    --     element.Label=element.Label .. "<br><font color='#0783b7'>"..status.DisplayNameRef.."</font>"
    --     element.Label=element.Label .. "<br><font color='#0783b7'>• Heal: "..status.HealStat.."</font>"
    --     element.Label=element.Label .. "<br><font color='#0783b7'>• Heal type: "..status.HealType.."</font>"
    --     Ext.Print(status.AbsorbSurfaceRange)
    --     if tonumber(status.AbsorbSurfaceRange) > 0 then
    --         element.Label=element.Label .. "<br><font color='#0783b7'>• Heal up to: "..status.HealValue.."% in a "..math.floor(tonumber(status.AbsorbSurfaceRange)/100).."m radius</font>"
    --     else
    --         element.Label=element.Label .. "<br><font color='#0783b7'>• Heal per tick: "..status.HealValue.."%</font>"
    --     end
    -- end
    if status.StatusType == "DAMAGE" then
        if status.DamageStats ~= "" then
            ExtendStatusDamage(Ext.Stats.Get(status.DamageStats), element, stats, status.DisplayName)
        end
    elseif status.StatusType == "ACTIVE_DEFENSE" then
        if status.Projectile ~= "" then
            element.Label=element.Label .. "<br><font color='#e60000'>On Activation: "..Mods.LeaderLib.GameHelpers.GetStringKeyText(status.DisplayName).."</font>"
            local damageStat = Ext.Stats.Get(status.Projectile)
            ExtendDamage(element, damageStat, stats, "", "    ")
        end
    elseif status.LeaveAction ~= "" then
        element.Label=element.Label .. "<br><font color='#e60000'>On "..Mods.LeaderLib.GameHelpers.GetStringKeyText(status.DisplayName).." expiration:</font>"
        local subStatus = Ext.Stats.Get(status.LeaveAction)
        ExtendDamage(element, subStatus, stats, "", "    ", true)
    elseif status.StatusType == "SPARK" then
        element.Label=element.Label .. "<br><font color='#e60000'>Each hit will throw a projectile to the nearest target in a "..status.Radius.."m radius:</font>"
        local subStatus = Ext.Stats.Get(status.Projectile)
        ExtendDamage(element, subStatus, stats, "", "    ")
    elseif status.StatusType == "CONSUME" then
        if status.StatsId ~= "" then
            local potion = Ext.Stats.Get(status.StatsId)
            if potion.BonusWeapon ~= "" then
                ExtendStatusDamage(Ext.Stats.Get(potion.BonusWeapon), element, stats, status.DisplayName, true)
            end
        end
    end
end

--- @param character EsvCharacter
--- @param skill string
--- @param tooltip TooltipData
local function OnSkillTooltip(character, skill, tooltip)
    --- @type StatEntrySkillData
    local skillStat = Ext.Stats.Get(skill)
    local stats = character.Stats
    if SkillCanBeExtended(skillStat) then
        tooltip:MarkDirty()
        if tooltip:IsExpanded() then
            local element = tooltip:GetElement("SkillDescription")
            local isProjectile = ""
            if skillStat.SkillType == "Storm" then
                skillStat = Ext.Stats.Get(skillStat.ProjectileSkills:gsub(";.*", ""))
            end
            if skillStat.SkillType == "Projectile" or skillStat.SkillType == "ProjectileStrike" then
                isProjectile = "per hit"
            end
            ExtendDamage(element, skillStat, stats, isProjectile)
            local statuses = {}
            if skillStat.SkillProperties == nil then return end
            for i,property in pairs(skillStat.SkillProperties) do
                if property.Action == "EXPLODE" then
                    local status = Ext.Stats.Get(property.StatsId)
                    if status ~= nil then
                        element.Label=element.Label .. "<br><font color='#e60000'>Explode target, causing in a "..skillStat.AreaRadius.."m radius:</font>"
                        ExtendDamage(element, status, stats, "", "    ")
                    end
                elseif property.Type == "Status" then
                    ---@type StatEntryStatusData
                    local status = Ext.Stats.Get(property.Action)
                    if status ~= nil then
                        ExtendStatus(status, element, stats)
                    end
                end
            end
            if skillStat.SkillType == "Dome" then
                if skillStat.AuraSelf ~= "" then
                    ExtendStatus(Ext.Stats.Get(skillStat.AuraSelf), element, stats)
                end
                if skillStat.AuraAllies ~= skillStat.AuraSelf and skillStat.AuraAllies ~= "" then
                    ExtendStatus(Ext.Stats.Get(skillStat.AuraAllies), element, stats)
                end
                if skillStat.AuraEnemies ~= skillStat.AuraAllies and skillStat.AuraEnemies ~= skillStat.AuraSelf and skillStat.AuraEnemies ~= "" then
                    ExtendStatus(Ext.Stats.Get(skillStat.AuraEnemies), element, stats)
                end
            end
        end
    end
end

--- @param character EsvCharacter
--- @param stat string
--- @param tooltip TooltipData
local function OnStatTooltip(character, stat, tooltip)
    if not tooltip or tooltip:GetElement("StatName") == nil then return end
    local stat = tooltip:GetElement("StatName").Label
    if stat == "Damage" then
        tooltip:MarkDirty()
        if tooltip:IsExpanded() then
            local element = tooltip:GetElement("StatsDescription")
            element.Label=element.Label .. "<br><font color='#66ffff'>• Base Level "..character.Stats.Level.." Damage: "..math.floor(Ext.Round(Game.Math.GetLevelScaledDamage(character.Stats.Level))).."</font>"
            element.Label=element.Label .. "<br><font color='#66ffff'>• Base Weapon Level "..character.Stats.Level.." Damage: "..math.floor(Ext.Round(Game.Math.GetLevelScaledWeaponDamage(character.Stats.Level))).."</font>"
            element.Label=element.Label .. "<br><font color='#66ffff'>• Average Level "..character.Stats.Level.." Damage: "..math.floor(Ext.Round(Game.Math.GetAverageLevelDamage(character.Stats.Level))).."</font>"
            element.Label=element.Label .. "<br><font color='#ff9966'>Base level damage is level scaled damage for a 100% damage hit. Average Level damage takes into account the average bonus from attributes and abilities and is a good point of reference to evaluate the damage effectiveness of your character.</font>"
        end
    end
end

local function DGM_Extended_Tooltips_Init()
    if Mods.LeaderLib == nil then return end
    if Mods.SingingScar ~= nil then
        Ext.Print("[Vanilla+] Detected Singing Scar, applying Shadow damage scaling")
        dmgTypeToSchool["Shadow"] = "Tenebrium Infusion"
    end
    Game.Tooltip.RegisterListener("Item", nil, OnItemTooltip)
    Game.Tooltip.RegisterListener("Skill", nil, OnSkillTooltip)
    Game.Tooltip.RegisterListener("Stat", nil, OnStatTooltip)
end

Ext.RegisterListener("SessionLoaded", DGM_Extended_Tooltips_Init)