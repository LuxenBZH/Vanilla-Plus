
local conduitAllowedSchools = {
    Fire = "Fire",
    Water = "Water",
    Necromancy = "Physical",
    Earth = "Earth",
    Air = "Air",
    Summoning = "Chaos"
}

Ext.Osiris.RegisterListener("CharacterUsedSkill", 4, "after", function(character, skill, skillType, school)
    local character = Ext.ServerEntity.GetCharacter(character)
    local mainHand, offHand = Helpers.Character.GetWeaponTypes(character)
    local conduitSize = 3 * ((mainHand == "Wand" and 1 or 0) + (offHand == "Wand" and 1 or 0))
    -- _P(school, conduitSize)
    if conduitSize == 0 then return end
    local conduit = character.UserVars.LX_SpellConduit or {}
    if not conduitAllowedSchools[school] then
        school = "Chaos"
    else
        school = conduitAllowedSchools[school]
    end
    if skill ~= "Projectile_LX_SpellConduit" then
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
    Fire = true,
    Water = true,
    Air = true,
    Earth = true,
    Physical = true,
    Chaos = true,
}

---@param e EsvLuaShootProjectileEvent
Ext.Events.BeforeShootProjectile:Subscribe(function(e)
    if e.Projectile.SkillId == "Projectile_LX_SpellConduit_-1" then
        local character = Ext.ServerEntity.GetCharacter(e.Projectile.Caster)
        local conduits = character.UserVars.LX_SpellConduit or {}
        local element = conduits[1]
        if element then
            e.Projectile.SkillId = "Projectile_LX_SpellConduit_"..element
            e.Projectile.DamageList:ConvertDamageType(Ext.Stats.Get(e.Projectile.SkillId).DamageType)
            Helpers.TableShiftLeft(conduits)
            if SPELL_CONDUIT_ELEMENT[element] then
                local stackLimit = 1
                local stackBonusDamage = Ext.Utils.Round(e.Projectile.DamageList:GetByType(element) / 1.625)  -- 65% base, 40% bonus per stack. Avoids recalculating the entire bonus at the downside of not having a true range
                while conduits[1] == element and stackLimit < 3 do
                    Helpers.TableShiftLeft(conduits)
                    e.Projectile.DamageList:Add(element, stackBonusDamage)
                    stackLimit = stackLimit + 1
                end
            end
        end
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
