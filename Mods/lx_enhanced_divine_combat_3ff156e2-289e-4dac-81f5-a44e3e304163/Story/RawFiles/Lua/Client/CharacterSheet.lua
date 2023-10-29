-- Ext.AddPathOverride("Public/Game/GUI/characterSheet.swf", "Public/lx_enhanced_divine_combat_3ff156e2-289e-4dac-81f5-a44e3e304163/Game/GUI/characterSheet.swf")

------ UI Values
---@param ui UIObject
---@param call string
---@param state any
local function changeDamageValue(ui, call, state)
    if ui:GetValue("secStat_array", "string", 2) == nil then return end
    local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(ui:GetRoot().charHandle))
    local damage = CustomGetSkillDamageRange(character.Stats, Ext.GetStat("Target_LX_NormalAttack"),  character.Stats.MainWeapon, character.Stats.OffHandWeapon, true)
    local minDamage = 0
    local maxDamage = 0
    for dtype,range in pairs(damage) do
        minDamage = minDamage + range.Min
        maxDamage = maxDamage + range.Max
    end
    ui:SetValue("secStat_array", minDamage.." - "..maxDamage, 24)
end

---@param ui UIObject
---@param call string
---@param state any
local function sheetButtonPressed(ui, call, state)
    local char = Ext.GetCharacter(Ext.DoubleToHandle(ui:GetValue("charHandle", "number")))
    Ext.PostMessageToServer("DGM_UpdateCharacter", tostring(char.NetID))
end

---@param ui UIObject
---@param call string
---@param state any
local function itemSheetButtonPressed(ui, call, state)
    local item = Ext.GetItem(Ext.DoubleToHandle(ui:GetValue("itemHandle", "number")))
    if item ~= nil then
        Ext.PostMessageToServer("DGM_UpdateCharacterFromItem", tostring(item.NetID))
    end
end

local function AddToSecStatArray(array, location, label, value, suffix, statID)
    local length = #array
    if length > 0 then
        array[length + 1] = location
        array[length + 2] = label
        array[length + 3] = tostring(value)..suffix
        array[length + 4] = statID
        array[length + 5] = ""
        array[length + 6] = value
        -- array[length + 7] = ""
    end
end

local function AddToPrimStatArray(array, location, label, value, suffix, statID)
    local length = #array
    if length > 0 then
        array[length] = 0
        array[length + 1] = label
        array[length + 2] = "   "..tostring(value)..suffix
        array[length + 3] = 33
        -- array[length + 3] = statID
    end
end

---@param ui UIObject
---@param call string
---@param state any
local function AddResistances(ui, call, state)
    local sheet = Ext.GetBuiltinUI("Public/Game/GUI/characterSheet.swf")
    local charHandle = sheet:GetValue("charHandle", "number")
    local char = Ext.GetCharacter(Ext.DoubleToHandle(charHandle))
    local root = ui:GetRoot()
    local length = #root.secStat_array
    -- AddToPrimStatArray(root.primStat_array, 0, "Test", tostring(char.Stats.PhysicalResistance), "", 33)
    -- Ext.Dump(root.primStat_array)
    if #root.secStat_array > 0 then
        if char.Stats.PhysicalResistance ~= 0 then
            AddToSecStatArray(root.secStat_array, 2, "Physical", tostring(char.Stats.PhysicalResistance), "%       ", 24)
        end
        if char.Stats.PiercingResistance ~= 0 then
            AddToSecStatArray(root.secStat_array, 2, "Piercing", tostring(char.Stats.PiercingResistance), "%       ", 23)
        end
        if char.Stats.ShadowResistance ~= 0 then
            AddToSecStatArray(root.secStat_array, 3, "Shadow", tostring(char.Stats.PhysicalResistance), "%       ", 27)
        end
    end
end

abilityButtonLock = {}
abilityButtonLock.CS = {}
abilityButtonLock.CC = {}

local perseverance = Ext.L10N.GetTranslatedString("hfc4ae314g920ag4fdagbc50ge73b91cfa7c7", "Perseverance")
local leadership = Ext.L10N.GetTranslatedString("h7c65fe39g1526g427bg8a2dgab7e74c66202", "Leadership")
local retribution = Ext.L10N.GetTranslatedString("h19487a02g5b86g4129ga879g0ec268a9f50b", "Retribution")

local function HidePlusButtonCharacterSheet(e)
    local ui = Ext.UI.GetByPath("Public/Game/GUI/characterSheet.swf")
    local root = ui:GetRoot()
    for ability, infos in pairs(abilityButtonLock.CS) do
        root.stats_mc.combatAbilityHolder_mc.list.content_array[1].list.content_array[infos.ID].texts_mc.plus_mc.visible = false
        root.stats_mc.combatAbilityHolder_mc.list.content_array[1].list.content_array[infos.ID].texts_mc.plus_mc.scaleX = 1
        abilityButtonLock.CS[ability] = nil
    end
end

local function HidePlusButtonCharacterSheetConsole(e)
    local ui = Ext.UI.GetByPath("Public/Game/GUI/statsPanel_c.swf")
    local root = ui:GetRoot()
    for ability, infos in pairs(abilityButtonLock.CS) do
        root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array[infos.ID].plus_mc.visible = false
        root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array[infos.ID].plus_mc.scaleX = 1
        abilityButtonLock.CS[ability] = nil
    end
end

local function HidePlusButtonCC(e)
    local root = Ext.UI.GetByType(abilityButtonLock.CCType):GetRoot()
    local abilityGroupList
    local listName = "abilities"
    if abilityButtonLock.CCType == 3 then
        abilityGroupList = root.CCPanel_mc.abilities_mc.abilityGroupList
    elseif abilityButtonLock.CCType == 4 then -- controller
        abilityGroupList = root.CCPanel_mc.combatAbilities_mc.abilityGroupList
        listName = "abilityList"
    end
    for ability, infos in pairs(abilityButtonLock.CC) do
        if abilityGroupList.content_array[2][listName].content_array[infos.Index].plus_mc.scaleX == 0 then
            abilityGroupList.content_array[2][listName].content_array[infos.Index].plus_mc.visible = false
            abilityGroupList.content_array[2][listName].content_array[infos.Index].plus_mc.scaleX = 1
        end
        abilityButtonLock.CC[ability] = nil
    end
end

local GMCharSheetStatsAdded = false -- Workaround since characterSheet.swf calls are fired twice when in GM view

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
    if e.Function == "updateArraySystem" and e.When == "After" then
        --[[
            REGION : Ability cap
        ]]
        local i = 0
        local root = e.UI:GetRoot()
        if e.UI:GetTypeId() == 119 then -- keyboard
            local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(root.charHandle))
            if root.isGameMasterChar then return end
            while i < #root.stats_mc.combatAbilityHolder_mc.list.content_array[1].list.content_array do
                local stat = root.stats_mc.combatAbilityHolder_mc.list.content_array[1].list.content_array[i].texts_mc.label_txt.htmlText
                if string.find(stat, perseverance) and character.Stats.DynamicStats[1].Perseverance >= 5 then
                    abilityButtonLock.CS.Perseverance = {ID = i}
                    root.stats_mc.combatAbilityHolder_mc.list.content_array[1].list.content_array[i].texts_mc.plus_mc.scaleX = 0
                elseif string.find(stat,leadership) and character.Stats.DynamicStats[1].Leadership >= 5 then
                    abilityButtonLock.CS.Leadership = {ID = i}
                    root.stats_mc.combatAbilityHolder_mc.list.content_array[1].list.content_array[i].texts_mc.plus_mc.scaleX = 0
                elseif string.find(stat,retribution) and character.Stats.DynamicStats[1].PainReflection >= 5 then
                    abilityButtonLock.CS.Retribution = {ID = i}
                    root.stats_mc.combatAbilityHolder_mc.list.content_array[1].list.content_array[i].texts_mc.plus_mc.scaleX = 0
                end
                i = i + 1
            end
            Ext.OnNextTick(HidePlusButtonCharacterSheet)
        elseif e.UI:GetTypeId() == 63 then -- controller
            local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(59):GetRoot().characterHandle))
            local j = 0
            local defenceAbilities = {Leadership = 0, Perseverance = 0, Retribution = 0}
            while j < #root.ability_array do
                if root.ability_array[j+3] == leadership then
                    defenceAbilities.Leadership = root.ability_array[j+4]
                elseif root.ability_array[j+3] == perseverance then
                    defenceAbilities.Perseverance = root.ability_array[j+4]
                elseif root.ability_array[j+3] == retribution then
                    defenceAbilities.Retribution = root.ability_array[j+4]
                end
                j = j + 6
            end
            while i < #root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array do
                local stat = root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array[i].label_txt.htmlText
                if string.find(stat, perseverance) and (defenceAbilities.Perseverance - (character.Stats.Perseverance - character.Stats.DynamicStats[1].Perseverance) >= 5) then
                    abilityButtonLock.CS.Perseverance = {ID = i}
                    root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array[i].plus_mc.scaleX = 0
                elseif string.find(stat,leadership) and (defenceAbilities.Leadership - (character.Stats.Leadership - character.Stats.DynamicStats[1].Leadership) >= 5) then
                    abilityButtonLock.CS.Leadership = {ID = i}
                    root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array[i].plus_mc.scaleX = 0
                elseif string.find(stat,retribution) and (defenceAbilities.Retribution - (character.Stats.PainReflection - character.Stats.DynamicStats[1].PainReflection) >= 5) then
                    abilityButtonLock.CS.Retribution = {ID = i}
                    root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array[i].plus_mc.scaleX = 0
                end
                i = i + 1
            end
            Ext.OnNextTick(HidePlusButtonCharacterSheetConsole)
        end
    end
    if e.Function == "updateAbilities" and e.When == "After" then
        local root = e.UI:GetRoot()
        local i = 0
        local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(root.characterHandle))
        local abilityGroupList
        local listName = "abilities"
        if e.UI:GetTypeId() == 3 then
            abilityGroupList = root.CCPanel_mc.abilities_mc.abilityGroupList
        elseif e.UI:GetTypeId() == 4 then -- controller
            abilityGroupList = root.CCPanel_mc.combatAbilities_mc.abilityGroupList
            listName = "abilityList"
        end
        while i < tonumber(#abilityGroupList.content_array[2][listName].content_array) do
            local ability = abilityGroupList.content_array[2][listName].content_array[i]
            if (ability.label_txt.htmlText == perseverance and character.Stats.DynamicStats[1].Perseverance >= 5) then
                abilityButtonLock.CC.Perseverance = {Index = i, Group = 2, Stat = "Perseverance"}
                ability.plus_mc.scaleX = 0
            elseif (ability.label_txt.htmlText == leadership and character.Stats.DynamicStats[1].Leadership >= 5) then
                abilityButtonLock.CC.Leadership = {Index = i, Group = 2, Stat = "Leadership"}
                ability.plus_mc.scaleX = 0
            elseif (ability.label_txt.htmlText == retribution and character.Stats.DynamicStats[1].PainReflection >= 5) then
                abilityButtonLock.CC.Retribution = {Index = i, Group = 2, Stat = "PainReflection"}
                ability.plus_mc.scaleX = 0
            end
            i = i + 1
        end
        abilityButtonLock.CCType = e.UI:GetTypeId()
        Ext.OnNextTick(HidePlusButtonCC)
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

local function SRP_Tooltips_Init()
    local charSheet = Ext.GetBuiltinUI("Public/Game/GUI/characterSheet.swf")
    Ext.RegisterUICall(charSheet, "showStatTooltip", ShowNewStatsTooltips)
    Game.Tooltip.RegisterListener("Stat", nil, OnStatTooltip)
end

Ext.RegisterListener("SessionLoaded", SRP_Tooltips_Init)


--- Prevent controllers button holding to bypass the tiny frame allowing to invest points
Ext.Events.UICall:Subscribe(function(e)
    if e.UI:GetTypeId() == 63 and e.Function == "addPointsAbil" and e.When == "Before" then
        local root = e.UI:GetRoot()
        local i = 0
        local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(59):GetRoot().characterHandle))
        local abilitiesIDs = {}
        local engineAbilities = {[perseverance] = "Perseverance", [leadership] = "Leadership", [retribution] = "PainReflection"}
        while i < #root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array do
            local stat = root.mainpanel_mc.stats_mc.combatAbilities_mc.statList.content_array[1].list.content_array[i]
            abilitiesIDs[stat.id] = {
                stat.label_txt.htmlText,
                tonumber(stat.val_txt.htmlText)
            }
            i = i +1
        end
        if abilitiesIDs[e.Args[1]][2] - (character.Stats[engineAbilities[abilitiesIDs[e.Args[1]][1]]] - character.Stats.DynamicStats[1][engineAbilities[abilitiesIDs[e.Args[1]][1]]]) >= 5 then
            e:PreventAction()
        end
    elseif e.UI:GetTypeId() == 4 and e.Function == "plusAbility" and e.When == "Before" then
        local root = e.UI:GetRoot()
        local i = 0
        local character = Ext.ClientEntity.GetCharacter(Ext.UI.DoubleToHandle(Ext.UI.GetByType(59):GetRoot().characterHandle))
        local abilitiesIDs = {}
        local engineAbilities = {[perseverance] = "Perseverance", [leadership] = "Leadership", [retribution] = "PainReflection"}
        local abilityGroupList = root.CCPanel_mc.combatAbilities_mc.abilityGroupList
        while i < tonumber(#abilityGroupList.content_array[2]["abilityList"].content_array) do
            local ability = abilityGroupList.content_array[2]["abilityList"].content_array[i]
            abilitiesIDs[ability.abilityID] = {
                ability.label_txt.htmlText,
                tonumber(ability.value_txt.htmlText)
            }
            i = i + 1
        end
        if abilitiesIDs[e.Args[1]][2] - (character.Stats[engineAbilities[abilitiesIDs[e.Args[1]][1]]] - character.Stats.DynamicStats[1][engineAbilities[abilitiesIDs[e.Args[1]][1]]]) >= 5 then
            e:PreventAction()
        end
    end
end)

local function DGM_SetupUI()
    local charSheet = Ext.GetBuiltinUI("Public/Game/GUI/characterSheet.swf")
    local tooltip = Ext.GetBuiltinUI("Public/Game/GUI/tooltip.swf")
    Ext.RegisterUIInvokeListener(charSheet, "updateArraySystem", changeDamageValue)
    -- Overhaul bonus refresh on buttons click
    Ext.RegisterUICall(charSheet, "minusStat", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "plusStat", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "minLevel", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "plusLevel", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "minusTalent", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "plusTalent", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "minusAbility", sheetButtonPressed)
    Ext.RegisterUICall(charSheet, "plusAbility", sheetButtonPressed)
    -- Ext.RegisterUIInvokeListener(charSheet, "updateArraySystem", AddResistances)
    -- Ext.RegisterUIInvokeListener(tooltip, "addFormattedTooltip", test)
    -- Ext.RegisterUINameCall("onChangeParam", itemSheetButtonPressed)
end

Ext.RegisterListener("SessionLoaded", DGM_SetupUI)

---@param attacker EsvCharacter
---@param target EsvCharacter
local function DGM_HitChanceFormula(attacker, target)
    local hitChance = attacker.Accuracy - target.Dodge + attacker.ChanceToHitBoost
    -- Make sure that we return a value in the range (0% .. 100%)
    hitChance = math.max(math.min(hitChance, 100), 0)
    return hitChance
end

Ext.RegisterListener("GetHitChance", DGM_HitChanceFormula)