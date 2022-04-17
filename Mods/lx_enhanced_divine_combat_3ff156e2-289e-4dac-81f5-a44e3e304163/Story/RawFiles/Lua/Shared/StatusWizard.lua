
---@param name string name of the new status
---@param potionBase string name of the potion entry to use as a template
---@param potionBonuses array[] contains all potion fields to modify
---@param statusBase string name of the status to use as a template
---@param statusFields array[] contains all status fields to modify
---@param keep boolean keep in the save or not
function CreateNewStatus(name, potionBase, potionBonuses, statusBase, statusFields, keep) 
    if NRD_StatExists("DGM_Potion_"..name) then
        return "DGM_"..name
    else
        local newPotion = Ext.CreateStat("DGM_Potion_"..name, "Potion", potionBase)
        for bonus,value in pairs(potionBonuses) do
            newPotion[bonus] = value
        end
        Ext.SyncStat(newPotion.Name, keep)
        local newStatus = Ext.CreateStat("DGM_"..name, "StatusData", statusBase)
        newStatus.StatsId = newPotion.Name
        for bonus,value in pairs(statusFields) do
            newStatus[bonus] = value
        end
        Ext.SyncStat(newStatus.Name, keep)
        --Ext.Print(newStatus.Name)
        return "DGM_"..name
    end
end