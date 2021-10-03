local colours = {
    Shadow = '#4d0066', --Shadow
    Corrosive = '#cccc00',
}

local sc = ""

Ext.RegisterListener("SessionLoaded", function() 
    local OverheadUI = Ext.GetUIByType(5) 
    local root = OverheadUI:GetRoot() 

    local function DamageOverheadColor()
        local i = 2
        local scArray = {}
        while i < #root.addOH_array do
            -- Ext.Print("addOH_array["..i.."]: ", root.addOH_array[i])
            if type(root.addOH_array[i]) == "string" then
                -- Ext.Print(root.addOH_array[i])
                if string.find(root.addOH_array[i], "#797980") ~= nil then
                    table.insert(scArray, {i, root.addOH_array[i]})
                end
            end  
            i = i + 4
        end
        if #scArray == 1 then
            if sc == "S" then
                root.addOH_array[scArray[1][1]] = scArray[1][2]:gsub("#797980", colours.Shadow)
            elseif sc == "C" then
                root.addOH_array[scArray[1][1]] = scArray[1][2]:gsub("#797980", colours.Corrosive)
            end
        elseif #scArray == 2 then
            local highest = 0
            local lowest = 0
            local firstNumber = string.match(scArray[1][2], ">(.*)<")
            local secondNumber = string.match(scArray[2][2], ">(.*)<")
            if tonumber(firstNumber) == nil or tonumber(secondNumber) == nil then return end
            if tonumber(firstNumber) > tonumber(secondNumber) then
                highest = 1
                lowest = 2
            else
                highest = 2
                lowest = 1
            end
            if sc == "S" then
                root.addOH_array[scArray[highest][1]] = scArray[highest][2]:gsub("#797980", colours.Shadow)
                root.addOH_array[scArray[lowest][1]] = scArray[lowest][2]:gsub("#797980", colours.Corrosive)
            else
                root.addOH_array[scArray[highest][1]] = scArray[highest][2]:gsub("#797980", colours.Corrosive)
                root.addOH_array[scArray[lowest][1]] = scArray[lowest][2]:gsub("#797980", colours.Shadow)
            end
            -- Ext.Print(root.addOH_array[scArray[1][1]], root.addOH_array[scArray[2][1]])
        end
    end
    Ext.RegisterUIInvokeListener(OverheadUI, "updateOHs", DamageOverheadColor, "Before")
end)

Ext.RegisterNetListener("DGM_ShadowCorrosiveTag", function (_, state)
    sc = state
end)