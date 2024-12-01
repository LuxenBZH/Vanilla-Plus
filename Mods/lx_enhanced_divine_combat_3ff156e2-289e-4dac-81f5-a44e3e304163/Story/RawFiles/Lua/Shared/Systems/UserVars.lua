Helpers.UserVars = {
    Registered = {},
    SyncedFromGameStart = false
}


---comment
---@param entity EsvCharacter|EclCharacter|EsvItem|EclItem
---@param name string
function Helpers.UserVars.GetVar(entity, name)
    if not entity then
        _VError("Attempted to get var "..name.." from an unexisting entity!")
        return nil
    end
    local id = Ext.IsServer() and entity.MyGuid or entity.NetID
    local vars = Ext.Vars.GetModVariables(Data.ModGUID)
    if not vars[name] then
        _VError("Variable "..name.." is not registered!", "UserVars")
        return nil
    end
    return vars[name][tostring(id)]
end

function Helpers.UserVars.SetComplexValue(name, index, value)
    local vars = Ext.Vars.GetModVariables(Data.ModGUID)
    if not vars[name] then
        _VWarning("Var "..name.." is not registered !", "UserVars", "IsServer:", Ext.IsServer())
        return
    end
    local varContent = vars[name]
    varContent[index] = value
    vars[name] = varContent
    return true
end

---comment
---@param entity EsvCharacter|EclCharacter|EsvItem|EclItem
---@param name string
---@param value any
---@param noSync boolean|nil
function Helpers.UserVars.SetVar(entity, name, value, noSync)
    local id = Ext.IsServer() and entity.MyGuid or entity.NetID
    local valid = Helpers.UserVars.SetComplexValue(name, id, value)
    if not noSync and valid then
        if Ext.IsServer() then
            if Helpers.UserVars.Registered[name].SyncToClient and Helpers.UserVars.Registered[name].SyncOnWrite then
                Ext.Net.BroadcastMessage("VP_UserVarsSyncSingle", Ext.Json.Stringify({
                    Entity = entity.NetID,
                    IsItem = Helpers.IsItem(entity),
                    Var = name,
                    Value = value
                }))
            end
        else
            Ext.Net.PostMessageToServer("VP_UserVarsSyncFromClient", Ext.Json.Stringify({
                Entity = entity.NetID,
                IsItem = Helpers.IsItem(entity),
                Var = name,
                Value = value
            }))
        end
    end
end

local function PackVariableForClientSide(varName)
    local contentTable = {}
    local vars = Ext.Vars.GetModVariables(Data.ModGUID)
    local varContent = vars[varName]
    if varContent then
        for guid, content in pairs(varContent) do
            ---TODO: GUID integrity checks. Maybe a map-based table for GM mode ?
            if ObjectExists(guid) == 1 then
                local entity = Ext.ServerEntity.GetGameObject(guid)
                if entity.CurrentLevel == Ext.ServerEntity.GetCurrentLevel().LevelDesc.LevelName then
                    contentTable[entity.NetID] = content
                end
            -- else
            --     Helpers.UserVars.SetComplexValue(varName, guid, nil)
            end
        end
        return contentTable
    else
        return {}
    end
end

local function SyncVariableToClients(varName)
    local contentTable = PackVariableForClientSide(varName)
    Ext.Net.BroadcastMessage("VP_UserVarsSyncVar", Ext.Json.Stringify({
        Var = varName,
        Content = contentTable
    }))
end

if Ext.IsServer() then
    ---If a client wrote a variable, spread it to the server
    ---@param _ string
    ---@param payload string
    ---@param _ integer|nil
    Ext.RegisterNetListener("VP_UserVarsSyncFromClient", function(_, payload, _)
        local info = Ext.Json.Parse(payload)
        local entity = Ext.ServerEntity.GetGameObject(info.Entity)
        Helpers.UserVars.SetVar(entity, info.Var, info.Value)
    end)

    ---Resync all UserVars content upon game start
    ---@param _ string|number
    ---@param _ any
    Ext.Osiris.RegisterListener("GameStarted", 2, "after", function(_, _)
        for varName,info in pairs(Helpers.UserVars.Registered) do
            if Helpers.UserVars.Registered[varName].Persistent then
                SyncVariableToClients(varName)
            end
        end
    end)

    ---Resync all UserVars content upon user connection
    ---@param _ string|number
    ---@param _ any
    Ext.Osiris.RegisterListener("UserConnected", 3, "after", function(userId, userName, _)
        _VPrint(userName.." connected.")
        for i,var in pairs(Helpers.UserVars.Registered) do
            local contentTable = PackVariableForClientSide(var)
            Ext.Net.PostMessageToUser(userId, "VP_UserVarsSyncVar", Ext.Json.Stringify({
                Var = var,
                Content = contentTable
            }))
        end
    end)
else
    ---Sync a var from the server
    ---@param _ string
    ---@param payload string
    ---@param _ integer|nil
    Ext.RegisterNetListener("VP_UserVarsSyncSingle", function(_, payload, _)
        local info = Ext.Json.Parse(payload)
        local entity
        if info.IsItem then
            entity = Ext.ClientEntity.GetItem(info.Entity)
        else
            entity = Ext.ClientEntity.GetCharacter(info.Entity)
        end
        Helpers.UserVars.SetComplexValue(info.Var, tostring(entity.NetID), info.Value)
        -- Ext.Net.BroadcastMessage("VP_UserVarsSync", payload)
    end)

    ---Sync all values of a var from server
    ---@param _ string
    ---@param payload string
    ---@param _ integer|nil
    Ext.RegisterNetListener("VP_UserVarsSyncVar", function(_, payload, _)
        local info = Ext.Json.Parse(payload)
        _VPrint("Syncing var "..info.Var.." from server", "UserVars:Client")
        for entity,value in pairs(info.Content) do
            Helpers.UserVars.SetComplexValue(info.Var, entity, value)
        end
    end)
end

---Better be used on SessionLoading
---@param name string
---@param persistent boolean|nil
---@param syncToClient boolean|nil
---@param syncOnWrite boolean|nil
---@param syncOnTick boolean|nil
function Helpers.UserVars.RegisterUserVar(name, persistent, syncToClient, syncOnWrite, syncOnTick)
    _VPrint("Registered user var "..name, "UserVars")
    Helpers.UserVars.Registered[name] = {
        Persistent = persistent,
        SyncToClient = syncToClient,
        SyncOnWrite = syncOnWrite,
        SyncOnTick = syncOnTick
    }
    Ext.Vars.RegisterModVariable(Data.ModGUID, name, {
        Persistent = persistent or false,
        Server = true,
        Client = true,
        WriteableOnServer = true,
        WriteableOnClient = true,
        DontCache = false,
        SyncOnTick = false,
        SyncOnWrite = false,
        SyncToClient = false,
        SyncToServer = false
    })
    local vars = Ext.Vars.GetModVariables(Data.ModGUID)
    if Ext.IsServer() then
        if not vars[name] then
            vars[name] = {}
            return
        end
        if persistent then
            Helpers.Timer.Start(300, SyncVariableToClients, nil, name)
        end
    else
        vars[name] = {}
    end
end

