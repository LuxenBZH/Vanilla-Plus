local WeaponArts = {
    Target_LX_DualWieldingAttack = function(character)
        return Game.Math.GetWeaponAbility(character.Stats, character.Stats.MainWeapon) == "DualWielding"
    end,
    Shout_LX_WeaponArtTrueStrike = function(character)
        return true, false
    end,
    Shout_LX_WeaponArtDash = function(character)
        return true, false
    end,
    Shout_LX_WeaponArtGuard = function(character)
        local mainHand, offHand = Helpers.Character.GetWeaponTypes(character)
        return Helpers.Character.GetFightType(character) == "Melee" and offHand ~= "Shield", false
    end,
    Shout_LX_WeaponArtGuard_Shield = function(character)
        local mainHand, offHand = Helpers.Character.GetWeaponTypes(character)
        return Helpers.Character.GetFightType(character) == "Melee" and offHand == "Shield", false
    end,
    Order = {
        "Target_LX_DualWieldingAttack",
        "Shout_LX_WeaponArtTrueStrike",
        "Shout_LX_WeaponArtDash",
        "Shout_LX_WeaponArtGuard",
        "Shout_LX_WeaponArtShield"
    }
}

local VPlusSimpleSkillGroups = {
    Target_HeavyAttack = WeaponArts,
    Target_DualWieldingAttack = WeaponArts
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