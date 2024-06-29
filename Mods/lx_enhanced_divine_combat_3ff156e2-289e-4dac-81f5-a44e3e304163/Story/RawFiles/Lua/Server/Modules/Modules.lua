Ext.Require("Server/Modules/RealJump.lua")
Ext.Require("Server/Modules/FallDamage.lua")
Ext.Require("Server/Modules/GBTalents.lua")
Ext.Require("Server/Modules/Corrogic.lua")

function EnableFallDamage(cmd)
    if cmd == "on" then
        print("Fall damage module activated")
        PersistentVars["DGM_FallDamage"] = true
    elseif cmd == "off" then
        print("Fall damage module deactivated")
        PersistentVars["DGM_FallDamage"] = false
    end
end

function EnableJumpDamage(cmd)
    if cmd == "on" then
        print("Jump fall damage module activated")
        PersistentVars["DGM_FallDamage_Jump"] = true
    elseif cmd == "off" then
        print("Jump fall damage module deactivated")
        PersistentVars["DGM_FallDamage_Jump"] = false
    end
end

local function DGM_Modules_consoleCmd(cmd, ...)
	local params = {...}
	for i=1,10,1 do
		local par = params[i]
		if par == nil then break end
		if type(par) == "string" then
			par = par:gsub("&", " ")
			par = par:gsub("\\ ", "&")
			params[i] = par
		end
	end
    if cmd == "DGM_Module_RealJump" then ReplaceAllJumps(params[1]) end
    if cmd == "DGM_Module_FallDamage" then EnableFallDamage(params[1]) end
    if cmd == "DGM_Module_FallDamage_Jump" then EnableJumpDamage(params[1]) end
end

local function ActivateModule(flag)
    if flag == "LXDGM_ModuleRealJump" then 
        ReplaceAllJumps("on")
    elseif flag == "LXDGM_ModuleFallDamageClassic" then 
        EnableFallDamage("on")
    elseif flag == "LXDGM_ModuleFallDamageAlternate" then 
        EnableJumpDamage("on")
    elseif flag == "LXDGM_ModuleDualCC" then
        Ext.ExtraData.DGM_EnableDualCCParry = 1
    elseif flag == "LXDGM_ModuleCorrogicDisable" then
        Ext.ExtraData.DGM_Corrogic = 0
    elseif flag == "LXDGM_ModuleLegacyDodge" then
        Ext.ExtraData.DGM_LegacyDodge = 1
    end
end
Ext.RegisterOsirisListener("GlobalFlagSet", 1, "after", ActivateModule)

local function DeactivateModule(flag)
    if flag == "LXDGM_ModuleRealJump" then 
        ReplaceAllJumps("off")
    elseif flag == "LXDGM_ModuleFallDamageClassic" then 
        EnableFallDamage("off")
    elseif flag == "LXDGM_ModuleFallDamageAlternate" then 
        EnableJumpDamage("off")
    elseif flag == "LXDGM_ModuleDualCC" then
        Ext.ExtraData.DGM_EnableDualCCParry = 0
    elseif flag == "LXDGM_ModuleCorrogicDisable" then
        Ext.ExtraData.DGM_Corrogic = 1
    elseif flag == "LXDGM_ModuleLegacyDodge" then
        Ext.ExtraData.DGM_LegacyDodge = 0
    end
end
Ext.RegisterOsirisListener("GlobalFlagCleared", 1, "after", DeactivateModule)

Ext.RegisterConsoleCommand("DGM_Module_RealJump", DGM_Modules_consoleCmd)
Ext.RegisterConsoleCommand("DGM_Module_FallDamage", DGM_Modules_consoleCmd)
