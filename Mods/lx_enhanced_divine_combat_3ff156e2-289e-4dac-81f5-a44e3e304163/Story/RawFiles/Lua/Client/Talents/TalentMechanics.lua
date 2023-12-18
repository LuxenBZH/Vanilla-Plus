local ElementalAffinityAiFlags = {
    Fire = { "Lava", "Fire", "FireCloud" },
    Water = { "Water", "WaterCloud" },
    Air = { "Electrified" },
    Earth = { "Oil", "Poison", "PoisonCloud" },
    Death = { "Blood", "BloodCloud" },
    Sulfurology = { "Sulfurium" }
}

function ClientElementalAffinityRework(e, epip)
    local skill = e.Skill
	local character = e.Character
	local grid = e.AiGrid
	local position = e.Position
	local radius = e.Radius
    local baseAP = skill.ActionPoints
    if character == nil or baseAP <= 0 then
        return baseAP, false
    end
    local ability
    if epip then
        ability = skill.Ability
    else
        ability = skill.StatsObject.StatsEntry.Ability
    end
    local elementalAffinity = false
    if character.TALENT_ElementalAffinity then
        if ability ~= "None" and baseAP > 1 and  grid ~= nil and position ~= nil and radius ~= nil then
            local aiFlags = ElementalAffinityAiFlags[ability]
            if aiFlags ~= nil then
                elementalAffinity = grid:SearchForCell(position[1], position[3], radius, aiFlags, -1.0)
                if elementalAffinity then
                    baseAP = baseAP - 1
                end
            end
        end

        local characterAP = 1
        if ((epip and skill.Requirement ~= "None") or (not epip and skill.Requirement > 0)) and skill.OverrideMinAP == "No" then
            characterAP = Game.Math.GetCharacterWeaponAPCost(character)
        end

        if not character.Character:HasTag("VP_UsedElementalAffinity") then
            e.ElementalAffinity = elementalAffinity
            e.AP = math.max(characterAP, baseAP)
        elseif elementalAffinity then
            e.AP = baseAP + 1
            e.ElementalAffinity = true
        else
            e.AP = baseAP
            e.ElementalAffinity = false
        end
    end
end