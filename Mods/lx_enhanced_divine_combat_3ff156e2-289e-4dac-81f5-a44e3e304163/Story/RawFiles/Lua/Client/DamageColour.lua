local colours = {
    Shadow = '#4d0066', --Shadow
    Corrosive = '#cccc00',
    None = '#f2f2f2'
}

local isShadow = false
local isCorrosive = false
local isNone = false

Ext.RegisterListener("SessionLoaded", function() 
    local OverheadUI = Ext.GetUIByType(5) 
    local root = OverheadUI:GetRoot() 

    local function DamageOverheadColor()
        local i = 1 
        while i < #root.addOH_array do
            Ext.Print("addOH_array["..i.."]: ", root.addOH_array[i])
            if type(root.addOH_array[i]) == "string" then
                -- Ext.Print(root.addOH_array[i])
                if isShadow then
                    root.addOH_array[i] = root.addOH_array[i]:gsub("#797980", colours.Shadow)
                elseif isCorrosive then
                    root.addOH_array[i] = root.addOH_array[i]:gsub("#797980", colours.Corrosive)
                elseif isNone then
                    root.addOH_array[i] = root.addOH_array[i]:gsub("#C80030", colours.None)
                end
            end  
            i = i + 1
        end
    end
    Ext.RegisterUIInvokeListener(OverheadUI, "updateOHs", DamageOverheadColor, "Before")
end)

Ext.RegisterNetListener("ShadowDamageOverhead", function (_, state)
    if state == "true" then
        isShadow = true
    else
        isShadow = false
    end
end)