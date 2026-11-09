Helpers.Alignment = {}

if Ext.IsServer() then
    Helpers.Alignment.Factions = {}

    Helpers.Alignment.Update = function()
        local manager = Ext.ServerEntity.GetAlignmentManager()
        local alignments = manager:GetAll()
        for i,handle in pairs(alignments) do
            local alignment = manager:Get(handle)
            Helpers.Alignment.Factions[alignment.Name] = alignment.Handle
        end
    end

    ---@param source EsvCharacter|GUID
    ---@param target EsvCharacter|GUID
    Helpers.Alignment.IsEnemy = function(source, target)
        if Helpers.IsCharacter(source) then
            source = source.MyGuid
        end
        if Helpers.IsCharacter(target) then
            target = target.MyGuid
        end
        local manager = Ext.ServerEntity.GetAlignmentManager()
        local sourceFaction = Helpers.Alignment.Factions[GetFaction(source)]
        local targetFaction = Helpers.Alignment.Factions[GetFaction(target)]
        -- In case a new faction is created after game start
        if not sourceFaction or not targetFaction then
            Helpers.Alignment.Update()
            sourceFaction = Helpers.Alignment.Factions[GetFaction(source)]
            targetFaction = Helpers.Alignment.Factions[GetFaction(target)]
        end
        if (sourceFaction and targetFaction) and (manager:IsPermanentEnemy(sourceFaction, targetFaction) or manager:IsTemporaryEnemy(sourceFaction, targetFaction)) then
            return true
        else
            return false
        end
    end

    ---@param e EsvLuaGameStateChangedEvent
    Ext.Events.GameStateChanged:Subscribe(function(e)
        if e.ToState == "Running" then
            Helpers.Alignment.Update()
        end
    end)
end