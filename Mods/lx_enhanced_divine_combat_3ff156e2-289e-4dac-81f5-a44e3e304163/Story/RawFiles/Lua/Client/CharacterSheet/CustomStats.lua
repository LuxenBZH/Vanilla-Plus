Ext.Events.UIInvoke:Subscribe(function(e)
    if e.UI:GetTypeId() == 119 and e.Function == "setPlayerInfo" and e.When == "After" then
        --[[
            REGION : Add new stats (Ingress, Wisdom, Lifesteal)
        ]]
        local root = e.UI:GetRoot()
        if not GMCharSheetStatsAdded then
            GMCharSheetStatsAdded = true
            Ext.OnNextTick(function(e)
                local root = Ext.UI.GetByType(119):GetRoot()
                local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(root.charHandle))
                root.stats_mc.secondaryStatList.removeElement(6, true, false, 0.3) -- remove spacing between Magic armor and Movement
                root.stats_mc.expStatList.y = 480 -- Move down Exp Gain in GM mode
                root.addSecondaryStat(1, "Lifesteal", character.Stats.LifeSteal, 151, 0, 0)
                root.addSecondaryStat(1, "Ingress", Data.Math.ComputeCharacterIngress(character), 152, 0, 0)
                root.addSecondaryStat(1, "Wisdom", math.floor(Data.Math.ComputeCharacterWisdom(character)*100-100), 153, 0, 0)
                GMCharSheetStatsAdded = false
                    
            end)
        end
    end
end)

local isLifestealTooltip
local isIngressTooltip
local isWisdomTooltip
--Captures when the characterSheet Light Resistance tooltip is trying to be served to the client and serves the FireResistance tooltip instead.
---@param ui UIObject
---@param call string
---@param statId number
local function ShowNewStatsTooltips(ui, call, statId, arg, x, y, ...)
    if statId == 151.0 then
        isLifestealTooltip = true
        ui:ExternalInterfaceCall("showStatTooltip", 33.0, arg+30, 1500, 500, ...)
    end
    if statId == 152.0 then
         isIngressTooltip= true
        ui:ExternalInterfaceCall("showStatTooltip", 33.0, arg+30, 1500, 500, ...)
    end
    if statId == 153.0 then
        isWisdomTooltip= true
       ui:ExternalInterfaceCall("showStatTooltip", 33.0, arg+30, 1500, 500, ...)
   end
end

local WisdomStatChecks = {
    witsWisdom = {
        Value = function(character)
            return math.floor(math.min(
                    (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
                    (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus))
        end,
        Label = "Wits",
        Suffix = ""
    },
    hydroWisdom = {
        Value = function(character)
            return math.floor(character.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityVitalityRestoredPerPoint)
        end,
        Label = "Hydrosophist",
        Suffix = ""
    },
    equipmentWisdom = {
        Value = Data.Math.ComputeCharacterWisdomFromEquipment,
        Label = "equipment",
        Suffix = ""
    },
    statusesWisdom = {
        Value = Data.Math.ComputeCharacterWisdomFromStatuses,
        Suffix = ""
    }
}

local PAWisdomStatChecks = {table.unpack(WisdomStatChecks),
    witsWisdom = {
        Value = function(character)
            return math.floor(math.min(
                    (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
                    (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus))
        end,
        Label = "Wits",
        Suffix = ""
    },
    geoPAWisdom = {
        Value = function(character)
            return math.floor(character.Stats.EarthSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint)
        end,
        Label = "Geomancy",
        Suffix = ""
    },
}

local MAWisdomStatChecks = {table.unpack(WisdomStatChecks),
    witsWisdom = {
        Value = function(character)
            return math.floor(math.min(
                    (character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_IntelligenceWisdomFromWitsCap,
                    (character.Stats.Wits - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_WitsWisdomBonus))
        end,
        Label = "Wits",
        Suffix = ""
    },
    hydroMAWisdom = {
        Value = function(character)
            return math.floor(character.Stats.WaterSpecialist * Ext.ExtraData.SkillAbilityArmorRestoredPerPoint)
        end,
        Label = "Hydrosophist",
        Suffix = ""
    },
}

WisdomTooltipArray = {}


---@param value number
---@param element table
local function CreateTooltipElement(value, element)
    local sign = value > 0 and "+" or ""
    local startString = value < 0 and "<font color='#FF0000'>" or ""
    local endString = value < 0 and "</font>" or ""
    if value ~= 0 then
        return {
            Type = element.Type or (value > 0 and "StatsPercentageBoost" or "StatsPercentageMalus"),
            Label = startString.."From "..element.Label..": "..sign..value.."% "..element.Suffix..endString
        }
    else
        return {
            Type = element.Type,
            Label = "From "..element.Label..": "..sign..value.."% "..element.Suffix
        }
    end
end

---@param character EclCharacter
---@param skill string
---@param tooltip TooltipData
local function OnStatTooltip(character, stat, tooltip)
    if tooltip == nil then return end
    -- Ext.Dump(tooltip:GetElement("StatName"))
    local stat = tooltip:GetElement("StatName").Label
    local statsDescription = tooltip:GetElement("StatsDescription")

    if stat == "UNKNOWN STAT" and isLifestealTooltip then
        tooltip:GetElement("StatName").Label = "Lifesteal"
        statsDescription.Label = "Damage dealt to Vitality restores yours by this percentage of damage dealt."
        local fromNecromancer = math.floor(character.Stats.Necromancy * Ext.ExtraData.SkillAbilityLifeStealPerPoint)
        if fromNecromancer > 0 then
            tooltip:AppendElement({
                Type = "StatsPercentageBoost",
                Label = "From "..Ext.L10N.GetTranslatedString("hb7ea4cc5g2a18g416bg9b95g51d928a60398", "Necromancer")..": +"..fromNecromancer.."%"
            })
        end
        isLifestealTooltip = false

    elseif stat == "UNKNOWN STAT" and isIngressTooltip then
        tooltip:GetElement("StatName").Label = "Ingress"
        statsDescription.Label = "The amount of resistance percentage that is ignored when attacking."
        isIngressTooltip = false

    elseif stat == "UNKNOWN STAT" and isWisdomTooltip then
        tooltip:GetElement("StatName").Label = "Wisdom"
        statsDescription.Label = "Increase all non-necromantic healings done."
        local elementArray = {}
        local PAelementArray = {}
        local MAelementArray = {}
        WisdomTooltipArray = {}
        local wisdom = math.floor(Data.Math.ComputeCharacterWisdom(character)*100-100)
        local wisdomEl = {
            Type = "StatsBaseValue",
            Label = "Vitality healings: "..Helpers.Sign(wisdom)..wisdom.."%"
        }
        table.insert(WisdomTooltipArray, wisdomEl)
        for i,element in pairs(WisdomStatChecks) do
            local value = element.Value(character)
            _P(element.Label, value)
            if type(value) == "number" and value ~= 0 then
                wisdomEl.Label = wisdomEl.Label.."<br>    <img src=\'Icon_BulletPoint\'>"..CreateTooltipElement(value, element).Label
            elseif type(value) == "table" then
                for k,statusInfo in pairs(value) do
                    if statusInfo.Value ~= 0 then
                        element.Label = Ext.L10N.GetTranslatedStringFromKey(statusInfo.Status)
                        wisdomEl.Label = wisdomEl.Label.."<br>    <img src=\'Icon_BulletPoint\'>"..CreateTooltipElement(statusInfo.Value, element).Label
                    end
                end
            end
        end
        local wisdomPA = math.floor(Data.Math.ComputeCharacterWisdomArmor(character)*100-100)
        local wisdomPAEl = {
            Type = "StatsBaseValue",
            Label = "Physical Armour healings: "..Helpers.Sign(wisdomPA)..wisdomPA.."%"
        }
        table.insert(WisdomTooltipArray, wisdomPAEl)
        for i,element in pairs(PAWisdomStatChecks) do
            local value = element.Value(character)
            if type(value) == "number" and value ~= 0 then
                wisdomPAEl.Label = wisdomPAEl.Label.."<br>    <img src=\'Icon_BulletPoint\'>"..CreateTooltipElement(value, element).Label
            elseif type(value) == "table" then
                for k,statusInfo in pairs(value) do
                    if statusInfo.Value ~= 0 then
                        element.Label = Ext.L10N.GetTranslatedStringFromKey(statusInfo.Status)
                        wisdomPAEl.Label = wisdomPAEl.Label.."<br>    <img src=\'Icon_BulletPoint\'>"..CreateTooltipElement(statusInfo.Value, element).Label
                    end
                end
            end
        end
        local wisdomMA = math.floor(Data.Math.ComputeCharacterWisdomMagicArmor(character)*100-100)
        local wisdomMAEl = {
            Type = "StatsBaseValue",
            Label = "Magic Armour healings: "..Helpers.Sign(wisdomMA)..wisdomMA.."%",
        }
        table.insert(WisdomTooltipArray, wisdomMAEl)
        for i,element in pairs(MAWisdomStatChecks) do
            local value = element.Value(character)
            if type(value) == "number" and value ~= 0 then
                wisdomMAEl.Label = wisdomMAEl.Label.."<br>    <img src=\'Icon_BulletPoint\'>"..CreateTooltipElement(value, element).Label
            elseif type(value) == "table" then
                for k,statusInfo in pairs(value) do
                    if statusInfo.Value ~= 0 then
                        element.Label = Ext.L10N.GetTranslatedStringFromKey(statusInfo.Status)
                        wisdomMAEl.Label = wisdomMAEl.Label.."<br>    <img src=\'Icon_BulletPoint\'>"..CreateTooltipElement(statusInfo.Value, element).Label
                    end
                end
            end
        end
        local previousEl
        for i,element in pairs(WisdomTooltipArray) do
            -- _P(element.Label)
            -- Helpers.VPPrint(i, "CharacterSheet", element.Label)
            -- if previousEl then
            --     -- Helpers.VPPrint(previousEl.Label, "CharacterSheet")
            --     tooltip:AppendElementAfter(element, previousEl)
            -- else
                tooltip:AppendElement(element)
            -- end
            -- previousEl = element
        end
    end
end

local function TooltipInit()
    local charSheet = Ext.GetBuiltinUI("Public/Game/GUI/characterSheet.swf")
    Ext.RegisterUICall(charSheet, "showStatTooltip", ShowNewStatsTooltips)
    Game.Tooltip.RegisterListener("Stat", nil, OnStatTooltip)
end

Ext.RegisterListener("SessionLoaded", TooltipInit)