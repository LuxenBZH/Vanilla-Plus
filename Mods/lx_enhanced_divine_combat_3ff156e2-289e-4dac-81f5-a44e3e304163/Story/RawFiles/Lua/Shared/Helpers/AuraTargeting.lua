Helpers.AuraTargeting = {
    Client = {
        Tracker = nil,
        TrackCursorListener = false,
        Aura = nil
    },
    Server = {},
    ArrowStatuses = {
        Enemy = "LX_TARGET_ARROW_RED",
        Ally = "LX_TARGET_ARROW_GREEN",
        Neutral = "LX_TARGET_ARROW_YELLOW"
    }
}

--------------
--- CLIENT ---
--------------
if Ext.IsClient() then
    --- When session loads, each client creates a custom version of each arrow status
    Ext.RegisterNetListener("LX_RetrieveClientInfo", function(channel, payload, ...)
        _VPrint("Creating AuraTargeting effects for client", "AuraTargeting", payload)
        local userID = tonumber(payload)
        for i,original in pairs(Helpers.AuraTargeting.ArrowStatuses) do
            local statName = original.."_"..tostring(userID)
            if not Helpers.Stats.Exists("StatusData", statName) then
                local stat = Ext.Stats.Create(statName, "StatusData", original)
                --- Make sure other clients don't see the effect when syncing it to them, then reactivate it just for this client
                local effect = stat.StatusEffect
                stat.StatusEffect = ""
                Ext.Stats.Sync(statName, false)
                Ext.Net.PostMessageToServer("LX_AuraTarget_CreateStat", Ext.Json.Stringify({
                    StatName = statName,
                    Base = original,
                    Mods = {
                        StatusEffect = ""
                    }
                }))
                Helpers.Timer.Start(300, function(stat, effect)
                    Ext.Stats.Get(stat).StatusEffect = effect
                end, 0, statName, effect)
                -- stat.StatusEffect = effect
                Helpers.AuraTargeting.ArrowStatuses[i] = statName
            end
        end
    end)


    ---@param position number[]
    ---@param radius number
    ---@param includeAllies boolean
    ---@param includeNeutrals boolean
    ---@param includeEnemies boolean
    ---@param trackCursor boolean
    ---@param source EclCharacter
    function Helpers.AuraTargeting.Client.ApplyTargeting(position, radius, includeAllies, includeNeutrals, includeEnemies, trackCursor, source)
        local userID = Data.UserID
        local suffix = (tostring(radius).."_")..(includeAllies and "A" or "")..(includeNeutrals and "N" or "")..(includeEnemies and "E" or "")..tostring(userID)
        Helpers.AuraTargeting.Client.Aura = "LX_AURATARGET_"..suffix
        local auraExists = Helpers.Stats.Exists("StatusData", Helpers.AuraTargeting.Client.Aura)
        if not auraExists then
            local aura = Ext.Stats.Create(Helpers.AuraTargeting.Client.Aura, "StatusData", "DGM_BASE")
            local mods = {
                AuraRadius = radius,
                AuraAllies = includeAllies and Helpers.AuraTargeting.ArrowStatuses["Ally"] or "",
                AuraNeutrals = includeNeutrals and Helpers.AuraTargeting.ArrowStatuses["Neutral"] or "",
                AuraEnemies = includeEnemies and Helpers.AuraTargeting.ArrowStatuses["Enemy"] or ""
            }
            Ext.Net.PostMessageToServer("LX_AuraTarget_CreateStat", Ext.Json.Stringify({
                StatName = Helpers.AuraTargeting.Client.Aura,
                Base = "DGM_BASE",
                Mods = mods
            }))
            for field, value in pairs(mods) do
                aura[field] = value
            end
            Ext.Stats.Sync(Helpers.AuraTargeting.Client.Aura, false)
            Data.Stats.BannedStatusesFromChecks[Helpers.AuraTargeting.Client.Aura] = true
        end
        Ext.Net.PostMessageToServer("LX_AuraTarget_Apply", Ext.Json.Stringify({
            Aura = Helpers.AuraTargeting.Client.Aura,
            Position = position,
            Source = source.NetID,
            TrackCursor = trackCursor
        }))
    end

    function Helpers.AuraTargeting.Client.SetTracker(channel, payload, ...)
        local info = Ext.Json.Parse(payload)
        Helpers.AuraTargeting.Client.Tracker = tonumber(info.Tracker)
        if info.Cursor then
            Helpers.AuraTargeting.Client.TrackCursorPosition()
        end
    end

    Ext.RegisterNetListener("LX_AuraTarget_Applied", Helpers.AuraTargeting.Client.SetTracker)

    ---Update the center position of the aura target
    ---@param position number[]
    function Helpers.AuraTargeting.Client.UpdateTracker(position)
        -- local tracker = Ext.ClientEntity.GetItem(Helpers.AuraTargeting.Client.Tracker)
        local tracker = Ext.ClientEntity.GetCharacter(Helpers.AuraTargeting.Client.Tracker)
        tracker.Translate = position
    end

    function Helpers.AuraTargeting.Client.TrackCursorPosition()
        if Helpers.AuraTargeting.Client.Tracker then
            if not Helpers.AuraTargeting.Client.TrackCursorListener then
                Helpers.AuraTargeting.Client.TrackCursorListener = Ext.Events.Tick:Subscribe(function(e)
                    if Helpers.AuraTargeting.Client.Tracker then
                        -- Ext.ClientEntity.GetItem(Helpers.AuraTargeting.Client.Tracker).Translate = Ext.ClientUI.GetPickingState().WorldPosition
                        -- Ext.ClientEntity.GetCharacter(Helpers.AuraTargeting.Client.Tracker).Translate = Ext.ClientUI.GetPickingState().WalkablePosition
                        Ext.ClientEntity.GetCharacter(Helpers.AuraTargeting.Client.Tracker).Invisible = true
                        Ext.Net.PostMessageToServer("LX_AuraTarget_Update", Ext.Json.Stringify({
                            Tracker = Helpers.AuraTargeting.Client.Tracker,
                            Position = Ext.ClientUI.GetPickingState().WalkablePosition
                        }))

                    else
                        Ext.Events.Tick:Unsubscribe(Helpers.AuraTargeting.Client.TrackCursorListener)
                        Helpers.AuraTargeting.Client.TrackCursorListener = nil
                    end
                end, {Priority=912})
            else
                _VWarning("The tracker is already following the cursor!", "AuraTargeting")
            end
        else
            _VError("No tracker to use!", "AuraTargeting")
        end
    end

    function Helpers.AuraTargeting.Client.Stop()
        if Helpers.AuraTargeting.Client.Tracker then
            Ext.Net.PostMessageToServer("LX_AuraTarget_Stop", Ext.Json.Stringify({
                Tracker = Helpers.AuraTargeting.Client.Tracker,
                Aura = Helpers.AuraTargeting.Client.Aura
            }))
            Helpers.AuraTargeting.Client.Tracker = nil
            Helpers.AuraTargeting.Client.Aura = nil
            if Helpers.AuraTargeting.Client.TrackCursorListener then
                Ext.Events.Tick:Unsubscribe(Helpers.AuraTargeting.Client.TrackCursorListener)
                Helpers.AuraTargeting.Client.TrackCursorListener = nil
            end
        end
    end
end

--------------
--- SERVER ---
--------------
if Ext.IsServer() then
    function Helpers.AuraTargeting.Server.ApplyTargeting(channel, payload, ...)
        local info = Ext.Json.Parse(payload)
        local position = info.Position
        local source = Ext.ServerEntity.GetCharacter(tonumber(info.Source))
        -- local tracker = Ext.ServerEntity.GetItem(CreateItemTemplateAtPosition("9a0c0892-64ff-4e2c-9137-322efe4946c2", position[1], position[2], position[3]))
        local tracker = Ext.ServerEntity.GetCharacter(TemporaryCharacterCreateAtPosition(position[1], position[2], position[3], "ff8e0ca2-9f9b-4a09-944f-b775850b4449", 0))
        -- local tracker = Ext.ServerAction.CreateGameAction("StatusDomeAction", info.Skill, source)
        SetFaction(tracker.MyGuid, GetFaction(source.MyGuid))
        CharacterFreeze(tracker.MyGuid)
        ApplyStatus(tracker.MyGuid, info.Aura, -1, 1, source.MyGuid)
        tracker.OffStage = true
        tracker.Invulnerable = true
        Data.Stats.BannedStatusesFromChecks[info.Aura] = true
        Ext.Net.PostMessageToClient(source.MyGuid, "LX_AuraTarget_Applied", Ext.Json.Stringify({
            Tracker = tracker.NetID,
            Cursor = info.TrackCursor
        }))
    end

    Ext.RegisterNetListener("LX_AuraTarget_Apply", Helpers.AuraTargeting.Server.ApplyTargeting)

    function Helpers.AuraTargeting.Server.RemoveTargeting(channel, payload, ...)
        local info = Ext.Json.Parse(payload)
        -- local item = Ext.ServerEntity.GetItem(tonumber(info.Tracker))
        local tracker = Ext.ServerEntity.GetCharacter(tonumber(info.Tracker))
        RemoveStatus(tracker.MyGuid, info.Aura)
        -- ItemRemove(item.MyGuid)
        RemoveTemporaryCharacter(tracker.MyGuid)
    end

    Ext.RegisterNetListener("LX_AuraTarget_Stop", Helpers.AuraTargeting.Server.RemoveTargeting)

    Ext.RegisterNetListener("LX_AuraTarget_Update", function(channel, payload, ...)
        local info = Ext.Json.Parse(payload)
        Ext.ServerEntity.GetCharacter(tonumber(info.Tracker)).Translate = info.Position
    end)

    Ext.RegisterNetListener("LX_AuraTarget_CreateStat", function(channel, payload, ...)
        local info = Ext.Json.Parse(payload)
        if not Helpers.Stats.Exists("StatusData", info.StatName) then
            local stat = Ext.Stats.Create(info.StatName, "StatusData", info.Base)
            for field,value in pairs(info.Mods) do
                stat[field] = value
            end
            Ext.Stats.Sync(info.StatName)
        end
    end)
end
