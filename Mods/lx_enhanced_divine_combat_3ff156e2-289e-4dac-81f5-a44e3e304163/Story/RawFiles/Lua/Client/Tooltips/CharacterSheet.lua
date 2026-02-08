local _PrimaryStatsIDs = {
    [0] = "Strength",
    [1] = "Finesse",
    [2] = "Intelligence",
    [3] = "Constitution",
    [4] = "Memory",
    [5] = "Wits",
}

local _TooltipsTypes = {
    Strength = {Damage = true, Ingress = true},
    Finesse = {Damage = true, Accuracy = true, CritMultiplier = true, Celerity = true},
    Intelligence = {Damage = true, Accuracy = true, Healing = true},
    Constitution = {Vitality = true},
    Memory = {MemorySlots = true},
    Wits = {Damage = true, CriticalChance = true, Healing = true}
}

local _AttributeModifierTooltip = {
    CriticalValues = Ext.L10N.GetTranslatedString("", "Critical hit values"),
    BaseDamage = Ext.L10N.GetTranslatedString("", "Base:                 "),
    MainWeaponDamage = Ext.L10N.GetTranslatedString("", "Main hand:     "),
    OffhandWeaponDamage = Ext.L10N.GetTranslatedString("", "Offhand:          "),
    SpellDamage = Ext.L10N.GetTranslatedString("", "Spell:                "),
    DotDamage = Ext.L10N.GetTranslatedString("", "Status:              "),
    AdditionalInfo = Ext.L10N.GetTranslatedString("", "Press CTRL to show Critical hit values.<br>")
}

local function TextValueColorModifier(value1, value2)
    if tonumber(value1) > tonumber(value2) then
        return "color='#C80030'" -- Red
    elseif tonumber(value1) < tonumber(value2) then
        return "color='#188EDE'" -- Blue
    else
        return ""
    end
end

local function FormatTooltipText(start, value1, value2)
    local result = Data.Text.Concatenate({
        start,
        value1,
        " → <font ",
        TextValueColorModifier(value1, value2),
        ">",
        value2,
        "</font>",
        "<br>"
    })
    return result
end

local function StatTypeToTooltip()
end

---comment
---@param character EclCharacter
---@param criticalHit boolean
---@param contentArray FlashArray
local function ComputeCharacerDamageModifiersTooltip(characterHandle, refresh, criticalHit, uiType, contentArray)
    local character = Ext.ClientEntity.GetCharacter(characterHandle)
    local critMultiplier = criticalHit and Game.Math.GetCriticalHitMultiplier(character.Stats.MainWeapon, character.Stats) or 1
    --Character creation resets attributes points on Ecl/EsvCharacter so add the deltas of the sheet to the character stats
    local deltas = {}
    if uiType == 3 then
        local root = Ext.UI.GetByType(3):GetRoot()
        for i,statId in pairs(_PrimaryStatsIDs) do
            deltas[statId] = (root.CCPanel_mc.attributes_mc.attributes.content_array[i].deltaValue or 0)
        end
    end
    --TODO: make sure BWD is level scaled with the weapon and not the character
    local values = {
        BLD = Game.Math.GetLevelScaledDamage(character.Stats.Level) * critMultiplier,
        BWD = Game.Math.GetLevelScaledWeaponDamage(character.Stats.Level) * critMultiplier,
        BHV = Game.Math.GetAverageLevelDamage(character.Stats.Level) * Ext.ExtraData.HealToDamageRatio,
        GlobalBonus = Data.Math.GetCharacterComputedDamageBonus(character, nil, {}, nil, deltas).DamageBonus / 100 + 1,
        WeaponBonus = Data.Math.GetCharacterComputedDamageBonus(character, nil, {IsWeaponAttack = true}, nil, deltas).DamageBonus / 100 + 1,
        SpellBonus = Data.Math.GetCharacterComputedDamageBonus(character, nil, {}, Ext.Stats.Get("Projectile_Fireball"), deltas).DamageBonus / 100 + 1,
        DotDamage = Data.Math.GetCharacterComputedDamageBonus(character, nil, {IsStatusDamage = true}, nil, deltas).DamageBonus / 100 + 1,
        MaxVitality = Ext.Utils.Round(Data.Math.ComputeCharacterMaxVitality(character, deltas.Constitution or 0)),
        Wisdom = Ext.Utils.Round((Data.Math.ComputeCharacterWisdom(character, deltas) - 1) * 100),
        Ingress = Data.Math.ComputeCharacterIngress(character, deltas),
        Accuracy = character.Stats.Accuracy + math.floor(math.min((character.Stats.Finesse + (deltas.Finesse or 0) - Ext.ExtraData.AttributeBaseValue)*5, (character.Stats.Intelligence + (deltas.Intelligence or 0) - Ext.ExtraData.AttributeBaseValue)*2)),
        Celerity = Ext.Utils.Round(Data.Math.ComputeCharacterCelerity(character) + (character.Stats.Finesse + (deltas.Finesse or 0) - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_FinesseMovementBonus)
    }
    local boostedValues = {}
    local labelText = ""
    local hoveringStat = nil
    for i, statId in pairs(_PrimaryStatsIDs) do
        local plus_mc = contentArray[i].plus_mc
        local minus_mc = contentArray[i].minus_mc or contentArray[i].min_mc
        local hovering = false
        if Helpers.UI.isMouseHoveringMC(plus_mc) then
            hovering = plus_mc
            deltas[statId] = (deltas[statId] or 0) + 1
            hoveringStat = statId
        elseif Helpers.UI.isMouseHoveringMC(minus_mc) then
            hovering = minus_mc
            deltas[statId] = (deltas[statId] or 0) - 1
            hoveringStat = statId
        end
        if hovering and hovering.visible then
            for k,v in pairs(values) do boostedValues[k] = v end
            if statId == "Finesse" and criticalHit then
                boostedValues.BLD = values.BLD * (critMultiplier + (Ext.ExtraData.DGM_FinesseCritMultBonus/100)) / critMultiplier
                boostedValues.BWD = values.BWD * (critMultiplier + (Ext.ExtraData.DGM_FinesseCritMultBonus/100)) / critMultiplier
            end
            if _TooltipsTypes[hoveringStat].Damage then
                boostedValues.GlobalBonus = Data.Math.GetCharacterComputedDamageBonus(character, nil, {}, nil, deltas).DamageBonus / 100 + 1
                boostedValues.WeaponBonus = Data.Math.GetCharacterComputedDamageBonus(character, nil, {IsWeaponAttack = true}, nil, deltas).DamageBonus / 100 + 1
                boostedValues.SpellBonus = Data.Math.GetCharacterComputedDamageBonus(character, nil, {}, Ext.Stats.Get("Projectile_Fireball"), deltas).DamageBonus / 100 + 1
                boostedValues.DotDamage = Data.Math.GetCharacterComputedDamageBonus(character, nil, {IsStatusDamage = true}, nil, deltas).DamageBonus / 100 + 1
                labelText = "Damage values (before damage types bonuses)<br>"
                labelText = labelText..FormatTooltipText(_AttributeModifierTooltip.BaseDamage,
                    string.format("%.2f", tostring(values.BLD * values.GlobalBonus)),
                    string.format("%.2f", tostring(boostedValues.BLD * boostedValues.GlobalBonus)))
                if character.Stats.MainWeapon and character.Stats.MainWeapon.DynamicStats then
                    local mainWeaponTAD = 0
                    for i,stat in ipairs(character.Stats.MainWeapon.DynamicStats) do
                        mainWeaponTAD = mainWeaponTAD + ((stat.StatsType == "Weapon" and stat.DamageType ~= "None") and stat.DamageFromBase or 0)
                    end
                    labelText = labelText..FormatTooltipText(_AttributeModifierTooltip.MainWeaponDamage,
                        string.format("%.2f", tostring(values.BWD * values.WeaponBonus * mainWeaponTAD / 100)),
                        string.format("%.2f", tostring(boostedValues.BWD * boostedValues.WeaponBonus * mainWeaponTAD / 100)))
                end
                if character.Stats.OffHandWeapon and character.Stats.OffHandWeapon.DynamicStats then
                    local offhandWeaponTAD = 0
                    for i,stat in ipairs(character.Stats.OffHandWeapon.DynamicStats) do
                        offhandWeaponTAD = offhandWeaponTAD + ((stat.StatsType == "Weapon" and stat.DamageType ~= "None") and stat.DamageFromBase or 0)
                    end
                    labelText = labelText..FormatTooltipText(_AttributeModifierTooltip.OffhandWeaponDamage,
                        string.format("%.2f", tostring(values.BWD * values.WeaponBonus * offhandWeaponTAD / 100 * Ext.ExtraData.DualWieldingDamagePenalty)),
                        string.format("%.2f", tostring(boostedValues.BWD * boostedValues.WeaponBonus * offhandWeaponTAD / 100 * Ext.ExtraData.DualWieldingDamagePenalty)))
                end
                labelText = labelText..FormatTooltipText(_AttributeModifierTooltip.SpellDamage,
                    string.format("%.2f", tostring(values.BLD * values.SpellBonus)),
                    string.format("%.2f", tostring(boostedValues.BLD * boostedValues.SpellBonus)))
                labelText = labelText..FormatTooltipText(_AttributeModifierTooltip.DotDamage,
                    string.format("%.2f", tostring(values.BLD * values.DotDamage)),
                    string.format("%.2f", tostring(boostedValues.BLD * boostedValues.DotDamage)))
                labelText = labelText..(criticalHit and "Critical Multiplier: "..tostring(math.floor(critMultiplier * 100)).."%<br>" or _AttributeModifierTooltip.AdditionalInfo)  
            end
            if _TooltipsTypes[hoveringStat].Vitality then
                boostedValues.MaxVitality = Ext.Utils.Round(Data.Math.ComputeCharacterMaxVitality(character, deltas.Constitution))
                labelText = labelText..FormatTooltipText(
                    Ext.L10N.GetTranslatedString("", "Max Vitality:     "),
                    values.MaxVitality,
                    boostedValues.MaxVitality)
            end
            if _TooltipsTypes[hoveringStat].Healing then
                boostedValues.Wisdom = Ext.Utils.Round((Data.Math.ComputeCharacterWisdom(character, deltas) - 1) * 100)
                labelText = labelText..FormatTooltipText(
                    Ext.L10N.GetTranslatedString("", "Wisdom:          "),
                    values.Wisdom,
                    boostedValues.Wisdom)
            end
            if _TooltipsTypes[hoveringStat].Ingress then
                boostedValues.Ingress = Data.Math.ComputeCharacterIngress(character, deltas)
                labelText = labelText..FormatTooltipText(
                    Ext.L10N.GetTranslatedString("", "Ingress:            "),
                    values.Ingress,
                    boostedValues.Ingress)
            end
            if _TooltipsTypes[hoveringStat].Accuracy then
                boostedValues.Accuracy = math.floor(character.Stats.Accuracy + math.min((character.Stats.Finesse + (deltas.Finesse or 0) - Ext.ExtraData.AttributeBaseValue)*5, (character.Stats.Intelligence + (deltas.Intelligence or 0) - Ext.ExtraData.AttributeBaseValue)*2))
                labelText = labelText..FormatTooltipText(
                    Ext.L10N.GetTranslatedString("", "Accuracy:          "),
                    values.Accuracy,
                    boostedValues.Accuracy)
            end
            if _TooltipsTypes[hoveringStat].Celerity then
                boostedValues.Celerity = Ext.Utils.Round(Data.Math.ComputeCharacterCelerity(character) + (character.Stats.Finesse + (deltas.Finesse or 0) - Ext.ExtraData.AttributeBaseValue) * Ext.ExtraData.DGM_FinesseMovementBonus)
                labelText = labelText..FormatTooltipText(
                    Ext.L10N.GetTranslatedString("", "Celerity:          "),
                    values.Celerity,
                    boostedValues.Celerity)
            end
            hovering.tooltip = labelText
            if refresh and hovering.visible then
                Ext.UI.GetByType(uiType):ExternalInterfaceCall("hideTooltip")
                Helpers.Timer.Start(20, function(uiType, tooltip)
                    Ext.UI.GetByType(uiType):ExternalInterfaceCall("showTooltip", tooltip)
                end, nil, uiType, hovering.tooltip)
            end
        end
    end
    return labelText
end

Ext.Events.UICall:Subscribe(function(e)
    if e.UI:GetTypeId() == Data.UIType.characterSheet then
        local characterHandle = Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.characterSheet):GetRoot().charHandle)
        if e.Function == "showTooltip" and e.When =="Before" then
            ComputeCharacerDamageModifiersTooltip(characterHandle, false, Ext.ClientInput.GetInputManager().Ctrl, 119, e.UI:GetRoot().stats_mc.primaryStatList.content_array)
        elseif (e.Function == "plusStat" or e.Function == "minusStat") and e.When == "Before" then
            Helpers.Timer.Start(50, ComputeCharacerDamageModifiersTooltip, nil, characterHandle, true, Ext.ClientInput.GetInputManager().Ctrl, 119, e.UI:GetRoot().stats_mc.primaryStatList.content_array)
        end
    elseif e.UI:GetTypeId() == Data.UIType.characterCreation then
        local characterHandle = Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.characterCreation):GetRoot().characterHandle)
        local root = e.UI:GetRoot()
        if root.CCPanel_mc.attributes_mc.visible and (e.Function == "PlaySound" or e.Function == "plusAttribute" or e.Function == "minusAttribute") and e.When == "Before" then
            local attributes = Ext.UI.GetByType(Data.UIType.characterCreation):GetRoot().CCPanel_mc.attributes_mc.attributes.content_array
            -- Needs some time to take the button disappearance into account
            Helpers.Timer.Start(100, ComputeCharacerDamageModifiersTooltip, nil, characterHandle, true, Ext.ClientInput.GetInputManager().Ctrl, 3, attributes)
        end
    end
end)

Ext.Events.RawInput:Subscribe(function(e)
    if e.Input.Input.InputId == "lctrl" then
        local charSheet = Ext.UI.GetByType(119)
        local charCreation = Ext.UI.GetByType(3)
        local tooltip = Ext.UI.GetByType(Data.UIType.tooltip)
        if charSheet and charSheet:GetRoot().hasTooltip then
            local charHandle = Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.characterSheet):GetRoot().charHandle)
            ComputeCharacerDamageModifiersTooltip(charHandle, true, e.Input.Value.State == "Pressed", 119, charSheet:GetRoot().stats_mc.primaryStatList.content_array)
        elseif charCreation and tooltip:GetRoot().tf ~= "null" then
            local characterHandle = Ext.UI.DoubleToHandle(Ext.UI.GetByType(Data.UIType.characterCreation):GetRoot().characterHandle)
            ComputeCharacerDamageModifiersTooltip(characterHandle, true, e.Input.Value.State == "Pressed", 3, charCreation:GetRoot().CCPanel_mc.attributes_mc.attributes.content_array)
        end
    end
end)