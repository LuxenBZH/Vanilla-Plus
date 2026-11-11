Ext.Events.BeforeShootProjectile:Subscribe(function(e)
    if e.Projectile.SkillId == "ProjectileStrike_RainOfArrows_-1" then
        local targets = Helpers.GetCharactersAroundPosition(e.Projectile.EndPosition[1], e.Projectile.EndPosition[2], e.Projectile.EndPosition[3], 3)
        local closest = nil
        local caster = Ext.ServerEntity.GetCharacter(e.Projectile.Caster)
        for i,j in pairs(targets) do
            if not j.Invisible and not j.Dead and Helpers.Alignment.IsEnemy(caster.MyGuid, j.MyGuid) then
                if not closest then
                    closest = j
                end
                if Ext.Math.Distance(j.WorldPos, e.Projectile.EndPosition) < Ext.Math.Distance(closest.WorldPos, e.Projectile.EndPosition) then
                    closest = j
                end
            end
        end
        if closest then
            e.Projectile.EndPosition = closest.WorldPos
        end
    end
end)