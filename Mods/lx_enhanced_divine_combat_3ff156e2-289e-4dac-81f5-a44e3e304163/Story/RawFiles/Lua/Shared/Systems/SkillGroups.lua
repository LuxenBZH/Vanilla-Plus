---@class SkillGroup
---@field Parent string
---@field Children SkillGroupChild[] skillName : function. At least one child must return true for the group to activate
---@field ShareCooldowns boolean if using one of the children skill triggers a cooldown on the parent and all other children
---@field Order table|nil order skills if wanted
SkillGroup = {
    Parent = "",
    Children = {},
    ShareCooldowns = false
}

SkillGroup.__index = SkillGroup

function SkillGroup:Create(parent, children, shareCooldowns)
    local childrenList = {}
    if children.Order then
        for i,skillName in ipairs(children.Order) do
            table.insert(childrenList, SkillGroupChild:Create(skillName, children[skillName]))
        end
    else
        for skill,condition in pairs(children) do
            table.insert(childrenList, SkillGroupChild:Create(skill, condition))
        end
    end
    local this = {
        Parent = parent,
        Children = childrenList,
        ShareCooldowns = shareCooldowns or false
    }
    -- Allow search children by their name directly from the table
    setmetatable(this.Children, {__index = function(children, skillName)
        for _,child in pairs(children) do
            if child.SkillName == skillName then
                return child
            end
        end
        return nil
    end})
    
    setmetatable(this, self)
    return this
end

---@class SkillGroupChild
---@field SkillName string
---@field Condition function
SkillGroupChild = {
    SkillName = "",
    ---Function need to handle client side, but can optionally handle server side as well
    ---@param character EclCharacter|EsvCharacter
    ---@return boolean memorized usable by the character
    ---@return boolean visible on the hotbar
    Condition = function(character) return false, false end
}

SkillGroupChild.__index = SkillGroupChild

function SkillGroupChild:Create(skill, condition)
    local this = {
        SkillName = skill,
        Condition = condition
    }
    setmetatable(this, self)
    return this
end


---@class SkillGroupManager
---@field SkillGroupList table
SkillGroupManager = {
    SkillGroupList = {},
    SharedSkillGroupList = {},
}

function SkillGroupManager:AddGroup(skillGroup)
    self.SkillGroupList[skillGroup.Parent] = skillGroup
end

---comment
---@param skillName string
function SkillGroupManager:RemoveGroups(skillName)
    for i,group in pairs(self.SkillGroupList) do
        if group.Parent == skillName and not shared then
            table.remove(self.SkillGroupList, i)
        end
    end
end

---comment
---@param skillName string
function SkillGroupManager:RemoveSharedGroups(skillName)
    for i,group in pairs(self.SharedSkillGroupList) do
        if group.Children[skillName] then
            table.remove(self.SharedSkillGroupList, i)
        end
    end
end

---@param skillName string
---@return SkillGroup
function SkillGroupManager:SearchGroups(skillName)
    return self.SkillGroupList[skillName]
end

function SkillGroupManager:SearchSharedGroups(skillName)
    local results = {}
    for i,group in pairs(self.SharedSkillGroupList) do
        if group.Children[skillName] then
            table.insert(results)
        end
    end
    return results
end

---Retrieve the skill group from a computed status name
---@param statusName string
function SkillGroupManager:FindGroupFromStatus(statusName)
    local parentName = string.sub(statusName, 15, -18)
    return self:SearchGroups(parentName)
end