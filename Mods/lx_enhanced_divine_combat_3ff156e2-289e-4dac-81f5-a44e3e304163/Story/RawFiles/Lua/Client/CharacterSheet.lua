-- Ext.AddPathOverride("Public/Game/GUI/characterSheet.swf", "Public/lx_enhanced_divine_combat_3ff156e2-289e-4dac-81f5-a44e3e304163/Game/GUI/characterSheet.swf")

------ UI Values
---@param ui UIObject
---@param call string
---@param state any
local function changeDamageValue(ui, call, state)
    if ui:GetValue("secStat_array", "string", 2) == nil then return end
    local character = Ext.GetCharacter(Ext.DoubleToHandle(ui:GetRoot().charHandle))

    local strength = character.Stats.Strength - Ext.ExtraData.AttributeBaseValue
    local finesse = character.Stats.Finesse - Ext.ExtraData.AttributeBaseValue
    local intelligence = character.Stats.Intelligence - Ext.ExtraData.AttributeBaseValue

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

Ext.Events.UIInvoke:Subscribe(function(e)
    -- if e.UI:GetTypeId() == 63 then
    --     _P(e.Function)
    -- end
    if e.Function == "updateArraySystem" and e.When == "After" then
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