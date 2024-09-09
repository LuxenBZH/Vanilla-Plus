Data.Text = {}

Data.Text.TranslatedKeys = {}

Data.Text.TranslatedKeys.DamageTypes = {
    Air = "h1cea7e28gc8f1g4915ga268g31f90767522c",
    Fire = "h9d241c17g79ccg42b2g80d8gd6baba6ad9f6",
    Water = "ha9528d8ag0e84g41a8g9603g8a5ed23c7587",
    Earth = "hd1fb2660g2e2cg4a2egb80dg7fe9ab55c090",
    Poison = "haa64cdb8g22d6g40d6g9918g61961514f70f",
    Physical = "ha6c38456g4c6ag47b2gae87g60a26cf4bf7b",
    Piercing = "h22f6b7bcgc548g49cbgbc04g9532e893fb55",
    Corrosive = "h727b2365g5cd3g4557g8627ge9612ab59420",
    Magic = "h02e0fcacg670eg4d35g9f20gcf5cddab7fd1",
    Shadow = "hf4632a8fg42a7g4d53gbe26gd203f28e3d5e",
    None = "hc0932370gbe42g4780gb939g69928bc5ec15",
    Sentinel = "h4e0ec4ffg0bedg459dga960g88333d857845",
    Sulfur = ""
}

Data.Text.DamageTypeColors = {
    Physical ="'#A8A8A8'",
	Corrosive ="'#cccc00'",
	Magic ="'#7F00FF'",
	Fire ="'#FE6E27'",
	Water ="'#4197E2'",
	Earth ="'#7F3D00'",
	Poison ="'#65C900'",
	Air ="'#7D71D9'",
	Shadow ="'#6600ff'",
    Piercing ="'#C80030'",
    None ="'#C80030'",
}

Data.Text.GetDamageColor = Helpers.GetDamageColor

Data.Text.TranslatedKeys.Common = {
    Damage = "h9531fd22g6366g4e93g9b08g11763cac0d86"
}

---@param damageType string
---@param value integer|number
---@return string
Data.Text.GetFormattedDamageText = function(damageType, value)
    return "<font color="..Data.Text.GetDamageColor(damageType)..">"..tostring(Ext.Utils.Round(value)).." "..damageType.." "..string.lower(Ext.L10N.GetTranslatedString(Data.Text.TranslatedKeys.Common.Damage)).."</font>"
end

Data.Text.GetFormattedDamageRangeText = function(damageType, value1, value2)
    return "<font color="..Data.Text.GetDamageColor(damageType)..">"..tostring(Ext.Utils.Round(value1)).."-"..tostring(Ext.Utils.Round(value2)).." "..damageType.." "..string.lower(Ext.L10N.GetTranslatedString(Data.Text.TranslatedKeys.Common.Damage)).."</font>"
end

---@param skill string
Data.Text.GetSkillDisplayName = function(skill)
    local statEntry = Ext.Stats.Get(skill) ---@type StatEntrySkillData
    if statEntry.DisplayName ~= "" then
        return Ext.L10N.GetTranslatedStringFromKey(statEntry.DisplayName)
    elseif statEntry.Using ~= "" then
        Data.Text.GetSkillDisplayName(statEntry.Using)
    end
    return skill
end

---comment
---@param number number|string
---@return string
Data.Text.FormatNumberDigitsNoZero = function(number)
    local str = string.format("%.2f", number)
    local pruned = str:gsub("%.?0+$", "")
    return pruned
end