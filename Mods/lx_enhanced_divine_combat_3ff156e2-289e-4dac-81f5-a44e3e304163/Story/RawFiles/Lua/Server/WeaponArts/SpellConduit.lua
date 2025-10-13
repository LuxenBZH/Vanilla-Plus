
local conduitAllowedSchools = {
    Fire = true,
    Water = true,
    Necromancy = true,
    Earth = true,
    Air = true
}

Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "after", function(character, skill, skillType, school)
    local character = Ext.ServerEntity.GetCharacter(character)
    local mainHand, offHand = Helpers.Character.GetWeaponTypes(character)
    local conduitSize = 3 * ((mainHand == "Wand" and 1 or 0) + (offHand == "Wand" and 1 or 0))
    _P(school, conduitSize)
    if conduitSize == 0 or not conduitAllowedSchools[school] then return end
    local conduit = character.UserVars.LX_SpellConduit or {}
    
    if skill == "Projectile_LX_SpellConduit" then
        
    else
        conduit[#conduit+1] = school
        if #conduit > conduitSize then
            Helpers.TableShiftLeft(conduit)
        end
        character.UserVars["LX_SpellConduit"] = conduit
        if Ext.Net.PlayerHasExtender(character.MyGuid) then
            Ext.Net.PostMessageToClient(character.MyGuid, "LX_WandsConduitUpdateNew", tostring(character.NetID))
        end
    end
end)

-- Ext.Behavior.Skill.AddById("Projectile_LX_SpellConduit", function()
--     local EsvCustomSkillState = {}

--     ---@class ev CustomSkillEventParams
--     ---@param skillState EsvSkillState
--     ---@return boolean
--     function EsvCustomSkillState:EnterBehaviour(ev,skillState)
--         _DS(skillState)
--         return false
--     end

--     return EsvCustomSkillState
-- end)


local SPELL_CONDUIT_ELEMENT = {
    Fire = "Fire",
    Water = "Water",
    Air = "Air",
    Earth = "Earth",
    Necromancy = "Blood",
    Chaos = "Chaos",
}

---@param e EsvLuaShootProjectileEvent
Ext.Events.BeforeShootProjectile:Subscribe(function(e)
    if e.Projectile.SkillId == "Projectile_LX_SpellConduit_-1" then
        local character = Ext.ServerEntity.GetCharacter(e.Projectile.Caster)
        local conduits = character.UserVars.LX_SpellConduit or {}
        e.Projectile.SkillId = "Projectile_LX_SpellConduit_"..SPELL_CONDUIT_ELEMENT[conduits[1]]
        e.Projectile.DamageList:ConvertDamageType(Ext.Stats.Get(e.Projectile.SkillId).DamageType)
        Helpers.TableShiftLeft(conduits)
        character.UserVars.LX_SpellConduit = conduits
        Helpers.Timer.StartNamed("LX_WandsConduitUpdate_"..character.MyGuid, 60, function(guid, netID)
            Ext.Net.PostMessageToClient(guid, "LX_WandsConduitUpdate", tostring(netID))
        end, 0, character.MyGuid, character.NetID)
    end
end)

Ext.Osiris.RegisterListener("ItemEquipped", 2, "after", function(item, character)
    local character = Ext.ServerEntity.GetCharacter(character)
    if not character then return end
    Helpers.Timer.StartNamed("LX_WandsConduitUpdate_"..character.MyGuid, 60, function(guid, netID)
            Ext.Net.PostMessageToClient(guid, "LX_WandsConduitUpdate", tostring(netID))
        end, 0, character.MyGuid, character.NetID)
end)

Ext.Osiris.RegisterListener("ItemUnEquipped", 2, "after", function(item, character)
    local character = Ext.ServerEntity.GetCharacter(character)
    if not character then return end
    Helpers.Timer.StartNamed("LX_WandsConduitUpdate_"..character.MyGuid, 60, function(guid, netID)
            Ext.Net.PostMessageToClient(guid, "LX_WandsConduitUpdate", tostring(netID))
        end, 0, character.MyGuid, character.NetID)
end)

local _SPELL_CONDUIT_STATUS = {
    SHOCKED = 2.0,
    WET = 5.0,
    BURNING = 2.0,
    POISONED = 2.0,
    SLOWED = 3.0
}

---@param e EsvLuaBeforeStatusApplyEvent
Ext.Events.BeforeStatusApply:Subscribe(function(e)
    local target = Ext.ServerEntity.GetCharacter(e.Status.TargetHandle)
    if _SPELL_CONDUIT_STATUS[e.Status.StatusId] then
        for s,maxEffectiveness in pairs(_SPELL_CONDUIT_STATUS) do
            local status = target:GetStatus(s)
            if status then
                if e.Status.StatusId == status.StatusId then
                    Helpers.Status.Multiply(status, math.min(status.StatsMultiplier + maxEffectiveness/5, maxEffectiveness))
                    status.CurrentLifeTime = math.max(status.CurrentLifeTime + 6.0, status.CurrentLifeTime)
                else
                    Helpers.Status.Multiply(status, math.min(status.StatsMultiplier + maxEffectiveness/10, maxEffectiveness))
                end
                e.PreventStatusApply = true
            end
        end
    end
end)