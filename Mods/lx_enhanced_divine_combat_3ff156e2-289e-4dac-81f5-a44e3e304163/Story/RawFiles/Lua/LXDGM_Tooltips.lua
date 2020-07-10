---@param item StatItem
---@param tooltip TooltipData
local function WeaponTooltips(item, tooltip)
    
	if item.ItemType ~= "Weapon" then return end
	local equipment = {
		Type = "ItemRequirement",
		Label = "",
		RequirementMet = true
	}
	if item.WeaponType == "Staff" then equipment["Label"] = "Increase Skill damages by 110%" end
	if item.WeaponType == "Wand" then equipment["Label"] = "Increase Skill damages by 102.5% (stackable when dual-wielding)" end
	if item.WeaponType == "Bow" or item.WeaponType == "Crossbow" or item.WeaponType == "Rifle" then equipment["Label"]="Get a 35% Damage penalty if the target is closer than 2 meters."; equipment["RequirementMet"]=false end
	if equipment["Label"] ~= "" then tooltip:AppendElementAfter(equipment, "ExtraProperties") end
	if item.WeaponType == "Wand" then
		local equipment = {
			Type = "ItemRequirement",
			Label = "Get a 35% Damage penalty if the target is closer than 2 meters.",
			RequirementMet = false
		}
		tooltip:AppendElementAfter(equipment, "ExtraProperties")
	end
end

---@param character EsvCharacter
---@param skill any
---@param tooltip TooltipData
local function SkillAttributeTooltipBonus(character, skill, tooltip)
    local stats = character.Stats
    local generalBonus = math.floor((stats.Strength-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthGlobalBonus +
    (stats.Finesse-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_FinesseGlobalBonus +
    (stats.Intelligence-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceGlobalBonus)
    local strengthBonus = math.floor((stats.Strength-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_StrengthWeaponBonus)
    local intelligenceBonus = math.floor((stats.Intelligence-Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceSkillBonus)

    local general = {
        Type = "StatsPercentageBoost",
        Label = "From Attributes : +"..generalBonus.."%"
    }
    local strength = {
        Type = "StatsPercentageBoost",
        Label = "From Strength weapon bonus : +"..strengthBonus.."%"
    }
    local intelligence = {
        Type = "StatsPercentageBoost",
        Label = "Skills gets a bonus of +"..intelligenceBonus.."% from Intelligence."
    }
    tooltip:AppendElementAfter(general, "StatsPercentageBoost")
    tooltip:AppendElementAfter(strength, "StatsPercentageBoost")
    tooltip:AppendElementAfter(intelligence, "StatsPercentageBoost")

    if not stats.MainWeapon.IsTwoHanded then
        if stats.OffHandWeapon ~= nil and stats.OffHandWeapon.WeaponType ~= "Shield" then
            local offhandPenalty = tooltip:GetElements("StatsPercentageMalus")
            for i,j in pairs(offhandPenalty) do
                local translatedKey = Ext.GetTranslatedString("he3980bf8gf554g4dd8g823cgf2ccb71036a6", "Offhand penalty: [1]%")
                local finalPenalty = math.floor(Ext.ExtraData.DualWieldingDamagePenalty*100 - stats.DualWielding*(Ext.ExtraData.DualWieldingDamagePenalty*10))
                if j.Label:find(translatedKey:gsub("%[1]%%", "")) ~= nil then
                    local replacement = finalPenalty.."%% (penalty reduced by "..tostring(math.floor(stats.DualWielding*(Ext.ExtraData.DualWieldingDamagePenalty*10))).."%% from Dual-wielding)"
                    j.Label = translatedKey:gsub("%[1]%%", replacement)
                end
            end
        end
    end
end

local function DGM_Init()
    Game.Tooltip.RegisterListener("Item", nil, WeaponTooltips)
    Game.Tooltip.RegisterListener("Stat", "Damage", SkillAttributeTooltipBonus)
end

Ext.RegisterListener("SessionLoaded", DGM_Init)