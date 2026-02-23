Ext.Events.SessionLoaded:Subscribe(function(ev)
    ---@param character StatCharacter
    ---@param skill string
    ---@param tooltip TooltipData
    Game.Tooltip.RegisterListener("Skill", nil, function(character, skill, tooltip)
        local requirements = tooltip:GetElements("SkillRequiredEquipment")
        local reqMet = true
        local skillEntry = Ext.Stats.Get(skill)
        for i,requirementTooltip in pairs(requirements) do
            local words = string.split(requirementTooltip.Label, " ")
            if words[2] == "CustomRequirement" then
                -- Fetch word 3 to get the requirement
                for j,requirement in pairs(skillEntry.Requirements) do
                    if requirement.Requirement == words[3] then
                        if requirementTooltip.RequirementMet then
                            local properties = tooltip:GetElement("SkillProperties")
                            table.insert(properties.Properties, {
                                Label = Helpers.GetDynamicTranslationStringFromKey(words[4], string.gsub(words[#words], "<br>", "")),
                                Warning = ""
                            })
                        else
                            reqMet = false
                            requirementTooltip.Label = Helpers.GetDynamicTranslationStringFromKey(words[4], string.gsub(words[#words], "<br>", ""))
                        end
                    end
                end
            end
        end
        if reqMet then
            for i, skillRequirement in pairs(skillEntry.Requirements) do
                local reqTrsKey = Data.CustomRequirements[skillRequirement.Requirement]
                if reqTrsKey then
                    local properties = tooltip:GetElement("SkillProperties")
                    table.insert(properties.Properties, {
                        Label = Helpers.GetDynamicTranslationStringFromKey(reqTrsKey, skillRequirement.Param),
                        Warning = ""
                    })
                end
            end
        end
    end)
end)