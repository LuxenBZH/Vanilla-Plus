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

local function SetupCharacterSheetUI()
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
end

Ext.RegisterListener("SessionLoaded", SetupCharacterSheetUI)
