local jumpers = {}
local fallers = {}
local jumpSkillUsers = {}
local nullifyStatuses = {
    "WINGS",
    "PURE"
}

local function CalculateFallDamage(character)
    Ext.Print("Calculating fall damage")
    local height = jumpers[character][1] - jumpers[character][2]
    if height > 5 then
        for i,status in pairs(nullifyStatuses) do
            if HasActiveStatus(character, status) == 1 then return end
        end
        local char = Ext.GetCharacter(character)
        local damageHeight = height-5-char.Stats.RogueLore*0.5
        if damageHeight < 1 then damageHeight = 1 end
        local totalDamage = char.Stats.MaxVitality*(0.01*(damageHeight*damageHeight))
        ApplyDamage(character, char.Stats.MaxVitality*(0.01*(damageHeight*damageHeight)), "Piercing")
        if damageHeight*damageHeight > 50 then
            ApplyStatus(character, "KNOCKED_DOWN", 6.0, 1.0)
        end
    end
    jumpers[character] = nil
end

local function TimerJumpSkill(timer)
    if timer == "DGM_FallDamageJumpSkill" then
        CalculateFallDamage(jumpSkillUsers[1])
        jumpSkillUsers[1] = nil
        FlushArray(jumpSkillUsers)
    end
end

Ext.RegisterOsirisListener("TimerFinished", 1, "before", TimerJumpSkill)

local function GetJumpHeight(character, x, y, z, skill, skillType, skillElement)
    if not PersistentVars["DGM_FallDamage"] then return end
    if skillType == "jump" or (skillType == "projectile" and Ext.GetStat(skill).MovingObject == "Caster") then
        local bX, bY, bZ = GetPosition(character)
        jumpers[character] = {bY, y}
    end
    if skillType == "jump" then
        jumpSkillUsers[#jumpSkillUsers+1] = character
        TimerLaunch("DGM_FallDamageJumpSkill", 1000)
    end
    if skillType == "projectile" then
        local x,y,z = GetPosition(character)
        fallers[character] = {x,y,z}
        TimerLaunch("DGM_ShockwaveCheckPosition", 200)
    end

end

Ext.RegisterOsirisListener("CharacterUsedSkillAtPosition", 7, "before", GetJumpHeight)

-- local function GetProjectileFallOwner(item, event)
--     if event ~= "DGM_FallDamageInit" then return end
--     if not PersistentVars["DGM_FallDamage"] then ItemRemove(item) return end
--     local closest
--     local closestChar
--     for char, pos in pairs(jumpers) do
--         local dist = GetDistanceTo(item, char)
--         if closest == nil or dist < closest then
--             closest = dist
--             closestChar = char
--         end
--     end
--     ItemRemove(item)
--     CalculateFallDamage(closestChar)
-- end

-- Ext.RegisterOsirisListener("StoryEvent", 2, "before", GetProjectileFallOwner)

local function CheckShockwavePos(timer)
    if timer ~= "DGM_ShockwaveCheckPosition" then return end
    local check = false
    for character, pos in pairs(fallers) do
        local nX, nY, nZ = GetPosition(character)
        if nX == pos[1] and nY == pos[2] and nZ == pos[3] then
            jumpers[character][2] = nY
            fallers[character] = nil
            CalculateFallDamage(character)
        else
            fallers[character] = {nX, nY, nZ}
            check = true
        end
    end
    if check then TimerLaunch("DGM_ShockwaveCheckPosition", 50) end
end

Ext.RegisterOsirisListener("TimerFinished", 1, "before", CheckShockwavePos)

local function ShockwaveCheck(character, status, causee)
    if not PersistentVars["DGM_FallDamage"] then return end
    if status ~= "SHOCKWAVE" then return end
    local x,y,z = GetPosition(character)
    jumpers[character] = {y, y}
    fallers[character] = {x, y, z}
    TimerLaunch("DGM_ShockwaveCheckPosition", 50)
end

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", ShockwaveCheck)

local function ForceHitGround(character, status, causee)
    if status ~= "PHYS_POST_CONTROL" then return end
    local x,y,z = GetPosition(character)
    jumpers[character][2] = y
    CalculateFallDamage(character)
end

Ext.RegisterOsirisListener("CharacterStatusApplied", 3, "before", ForceHitGround)