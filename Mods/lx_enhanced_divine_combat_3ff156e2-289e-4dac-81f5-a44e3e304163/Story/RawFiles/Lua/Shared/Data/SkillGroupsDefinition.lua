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
    }
}

for parent, children in pairs(VPlusSimpleSkillGroups) do
    SkillGroupManager:AddGroup(SkillGroup:Create(parent, children, true))
end