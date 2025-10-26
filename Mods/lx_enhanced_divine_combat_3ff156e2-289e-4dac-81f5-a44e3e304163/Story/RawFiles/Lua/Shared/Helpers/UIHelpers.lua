_P("Loaded UIHelpers.lua")

Helpers.UI = {}

Helpers.UI.GetTooltipNumberSign = function(number)
	return {
		Type = number > 0 and "StatusBonus" or "StatusMalus",
		Sign = number > 0 and "+" or ""
	}
end

Helpers.UI.isMouseHoveringMC = function(movieClip)
    return movieClip.mouseX > 0 and movieClip.mouseX < movieClip.width and movieClip.mouseY > 0 and movieClip.mouseY < movieClip.height
end