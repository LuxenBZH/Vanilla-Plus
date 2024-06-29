local VPlusSimpleSkillGroups = {
    Projectile_Fireball = {
        Projectile_Fireball = function(character)
            return true, true
        end,
        Projectile_FlamingDaggers = function(character)
            return true, true
        end,
        Zone_LaserRay = function(character)
            return true, true
        end,
        Shout_InspireStart = function(character)
            return false, true
        end
    },
    Shout_LX_TransmuteSkin = {
        ---@param character EclCharacter
        Shout_IceSkin = function(character)
            return Helpers.Character.CheckSkillRequirements(character, "Shout_IceSkin", false), true
        end,
        Shout_PoisonousSkin = function(character)
            return Helpers.Character.CheckSkillRequirements(character, "Shout_PoisonousSkin", false), true
        end,
        Shout_JellyfishSkin = function(character)
            return Helpers.Character.CheckSkillRequirements(character, "Shout_JellyfishSkin", false), true
        end,
        Shout_FlamingSkin = function(character)
            return Helpers.Character.CheckSkillRequirements(character, "Shout_FlamingSkin", false), true
        end,
    }
}

for parent, children in pairs(VPlusSimpleSkillGroups) do
    SkillGroupManager:AddGroup(SkillGroup:Create(parent, children, true))
end