_P("Loaded UIHelpers.lua")

Helpers.UI = {}

Helpers.UI.GetTooltipNumberSign = function(number)
	return {
		Type = number > 0 and "StatusBonus" or "StatusMalus",
		Sign = number > 0 and "+" or ""
	}
end