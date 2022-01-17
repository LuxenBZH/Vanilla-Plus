SkillMutator = {
    Skills = {
            -- OriginalSkill = {
            --     Mutator = {
            --         BaseRequirements = true,
            --         Replacement = false,
            --         AbilityRequirements = "",
            --         TagRequirements = "",
            --         LevelRequirement = ""
            --     }
            -- }
        },
    Reverse = {
        -- MutatedSkill = OriginalSkill
    }
}

SkillMutator.__index = SkillMutator

local function LoadModSkillMutators(uuid, file, db)
    local mutators = Ext.JsonParse(file)
    local skip = false
    local previousSkill = ""
    for skill, mutator in pairs(mutators) do
        if previousSkill ~= skill then
            previousSkill = skill
            skip = false
        end
        if not db.Skills[skill] then
            db.Skills[skill] = mutators[skill]
            db.Reverse[mutator] = skill
            skip = true
        elseif not skip then
            if not db.Skills[skill][mutator] then
                table.insert(db.Skills[skill], mutator)
            else
                db.Skills[skill][mutator] = mutators[skill][mutator]
            end
        end
    end
end

--- Original code from LaughingLeader
local function TryFindMutators(info)
	local filePath = string.format("Mods/%s/SkillMutation.json", info.Directory)
	local file = Ext.LoadFile(filePath, "data")
	return file
end

function SkillMutator:Create()
    local this = {
        Skills = {},
        Reverse = {}
    }
    setmetatable(this, self)
    for i,uuid in pairs(Ext.GetModLoadOrder()) do
        local info = Ext.GetModInfo(uuid)
        if info ~= nil then
            local b,result = xpcall(TryFindMutators, debug.traceback, info)
            if not b then
                Ext.PrintError(result)
            elseif result ~= nil and result ~= "" then
                LoadModSkillMutators(uuid, result, this)
            end
        end
    end
    return this
end

Classes.SkillMutator = SkillMutator