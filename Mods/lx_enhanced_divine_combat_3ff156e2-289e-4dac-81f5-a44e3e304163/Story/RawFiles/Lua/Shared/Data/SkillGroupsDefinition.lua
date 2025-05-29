local VPlusSimpleSkillGroups = {
    Shout_LX_RangedStances = {
        Shout_LX_RangedReflexStance = function(character)
            return character:GetStatus("LX_AIMING_STANCE") == null, true
        end,
        Shout_LX_RangedAimingStance = function(character)
            return character:GetStatus("LX_REFLEX_STANCE") == null, true
        end,
        Shout_LX_Reload = function(character)
            return character:GetStatus("LX_REFLEX_STANCE") ~= null, false
        end,
        Shout_LX_RapidFire = function(character)
            return character:GetStatus("LX_REFLEX_STANCE") ~= null, false
        end,
        Target_LX_SuppressionFire = function(character)
            return character:GetStatus("LX_AIMING_STANCE") ~= null, false
        end,
        Target_LX_HunterMark = function(character)
            return character:GetStatus("LX_AIMING_STANCE") ~= null, false
        end
    },
    Target_HeavyAttack = {
        Target_HeavyAttack = function(character)
            return true, false
        end,
        Shout_LX_WeaponArtTrueStrike = function(character)
            return true, false
        end
    },

    Target_DualWieldingAttack = {
        Target_DualWieldingAttack = function(character)
            return true, false
        end,
        Shout_LX_WeaponArtTrueStrike = function(character)
            return true, false
        end
    }
}

local VPlusSimpleSkillGroupsSharedCooldown = {
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
    SkillGroupManager:AddGroup(SkillGroup:Create(parent, children, false))
end

for parent, children in pairs(VPlusSimpleSkillGroupsSharedCooldown) do
    SkillGroupManager:AddGroup(SkillGroup:Create(parent, children, true))
end