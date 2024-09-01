local axer = Ext.Stats.AddRequirement("AxeWeapon")
axer.Description = "an axe"
---@param req any
---@param ctx any
---@param char CDivinityStatsCharacter
axer.Callbacks.EvaluateCallback = function (req, ctx, char) 
    return true and ((char.MainWeapon and char.MainWeapon.WeaponType == "Axe") or (char.OffHandWeapon and char.OffHandWeapon.WeaponType == "Axe")) or false
end

local swordr = Ext.Stats.AddRequirement("SwordWeapon")
swordr.Description = "a sword"
---@param req any
---@param ctx any
---@param char CDivinityStatsCharacter
swordr.Callbacks.EvaluateCallback = function (req, ctx, char) 
    return true and ((char.MainWeapon and char.MainWeapon.WeaponType == "Sword") or (char.OffHandWeapon and char.OffHandWeapon.WeaponType == "Sword")) or false
end

local clubr = Ext.Stats.AddRequirement("ClubWeapon")
clubr.Description = "a mace"
---@param req any
---@param ctx any
---@param char CDivinityStatsCharacter
clubr.Callbacks.EvaluateCallback = function (req, ctx, char) 
    return true and ((char.MainWeapon and char.MainWeapon.WeaponType == "Club") or (char.OffHandWeapon and char.OffHandWeapon.WeaponType == "Club")) or false
end

local spearr = Ext.Stats.AddRequirement("SpearWeapon")
spearr.Description = "a spear"
---@param req any
---@param ctx any
---@param char CDivinityStatsCharacter
spearr.Callbacks.EvaluateCallback = function (req, ctx, char) 
    return true and ((char.MainWeapon and char.MainWeapon.WeaponType == "Spear") or (char.OffHandWeapon and char.OffHandWeapon.WeaponType == "Spear")) or false
end

local staffr = Ext.Stats.AddRequirement("StaffWeapon")
staffr.Description = "a staff"
---@param req any
---@param ctx any
---@param char CDivinityStatsCharacter
staffr.Callbacks.EvaluateCallback = function (req, ctx, char) 
    return true and ((char.MainWeapon and char.MainWeapon.WeaponType == "Staff") or (char.OffHandWeapon and char.OffHandWeapon.WeaponType == "Staff")) or false
end