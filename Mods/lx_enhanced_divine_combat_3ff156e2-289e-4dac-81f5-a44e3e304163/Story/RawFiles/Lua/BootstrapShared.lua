--- @class HitFlags
--- @field Dodged boolean
--- @field Missed boolean
--- @field Critical boolean
--- @field Backstab boolean
--- @field DamageSourceType CauseType
--- @field Blocked boolean
--- @field IsDirectAttack boolean
--- @field IsWeaponAttack boolean
HitFlags = {
    Dodged = false,
    Missed = false,
    Critical = false,
    Backstab = false,
    DamageSourceType = "",
    Blocked = false,
    IsDirectAttack = false,
    IsWeaponAttack = false
}

HitFlags.__index = HitFlags

function HitFlags:Create()
    local this = {}
    setmetatable(this, self)
    return this
end

Ext.Require("Shared/_InitShared.lua")

if Mods.LeaderLib then
    Mods.LeaderLib.Import(Mods.VanillaPlus)
end