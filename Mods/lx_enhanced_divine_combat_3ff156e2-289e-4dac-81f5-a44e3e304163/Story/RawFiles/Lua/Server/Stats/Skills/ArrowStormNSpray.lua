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

---@param e EsvLuaProjectileHitEvent
Ext.Events.ProjectileHit:Subscribe(function(e)
    if e.Projectile.SkillId == "Projectile_ArrowSpray_-1" and not e.HitObject then
        -- _DS(e.Projectile)
        local angle = math.random()*2 * math.pi
        local xR = e.Projectile.Position[1] + math.sqrt(2*2 + math.random() * (4*4 - 2*2)) * math.cos(angle)
        local yR = e.Projectile.Position[2] + math.random()
        local zR = e.Projectile.Position[3] + math.sqrt(2*2 + math.random() * (4*4 - 2*2)) * math.sin(angle)
        Helpers.LaunchProjectile(e.Projectile.Position, {xR, yR, zR}, "Projectile_ArrowSpray_FirstBounce_-1", {
            GuidString = {Caster = Ext.ServerEntity.GetCharacter(e.Projectile.CasterHandle).MyGuid}
        })
    elseif e.Projectile.SkillId == "Projectile_ArrowSpray_FirstBounce_-1" then
        local angle = math.random()*2 * math.pi
        local xR = e.Projectile.Position[1] + math.sqrt(1 + math.random() * 3) * math.cos(angle)
        local yR = e.Projectile.Position[2] + math.random()
        local zR = e.Projectile.Position[3] + math.sqrt(1 + math.random() * 3) * math.sin(angle)
        Helpers.LaunchProjectile(e.Projectile.Position, {xR, yR, zR}, "Projectile_ArrowSpray_SecondBounce_-1", {
            GuidString = {Caster = Ext.ServerEntity.GetCharacter(e.Projectile.CasterHandle).MyGuid}
        })
    end
end)
