Generic = Epip.Client.UI.Generic

local conduits = {}
local SCHOOL_TO_ICON = {
    Fire = "pyrokinetic",
    Water = "hydrosophist",
    Air = "aerotheurge",
    Earth = "geomancy",
    Necromancy = "necromancer",
    Other = "special"
}

local conduitMain

---@param character EclCharacter
local function UpdateConduitSize(character)
    local mainHand, offHand = Helpers.Character.GetWeaponTypes(character)
    _P(mainHand, offHand)
    local conduitSize = 3 * ((mainHand == "Wand" and 1 or 0) + (offHand == "Wand" and 1 or 0))
    _P("Conduit size:", conduitSize)
    if conduitSize == 0 then
        conduitMain:SetVisible(false)
        return 0
    end
    conduitMain:SetVisible(true)
    for i=1,6,1 do
        conduits[i]:SetVisible(i <= conduitSize)
    end
    conduitMain:SetBackground("Black", 32*conduitSize, 32)
    return conduitSize
end

local function InitializeWandConduitUI()
    ---Wands conduit
    local wandsConduit = Generic.GetInstance("LX_WandsConduit") or Generic.Create("LX_WandsConduit")
    wandsConduit:Show()
    -- wandsConduit:Show()
    wandsConduit:GetUI().Layer = 6 -- same layer as statusConsole
    conduitMain = wandsConduit.Elements["ConduitMain"] or wandsConduit:CreateElement("ConduitMain", "GenericUI_Element_TiledBackground")
    conduitMain:SetBackground("Black", 192, 32)
    conduitMain:SetAlpha(0.2)
    for i=1,6,1 do
        conduits[i] = wandsConduit.Elements["ConduitSlot"..tostring(i)] or conduitMain:AddChild("ConduitSlot"..tostring(i), "GenericUI_Element_IggyIcon")
        conduits[i]:SetIcon("PIP_UI_Icon_AP_Simple_Empty", 30, 30)
        conduits[i]:SetPosition((i-1)*32,0)
        conduitMain:SetChildIndex(conduits[i], 1)
        
        -- RS3_FX_Skills_Air_Overlay_Time_02 <6ff42e87-676c-4e6a-a096-75fc156c4bfb>

        -- flash:SetTexture("bd5f3551-c465-40db-bb37-e6dbeb9164fc", Epip.Vector.Create(32, 64))
        
        -- flash:SetVisible(false)
        local icon = wandsConduit.Elements["ConduitIcon"..tostring(i)] or conduits[i]:AddChild("ConduitIcon"..tostring(i), "GenericUI_Element_IggyIcon")
        icon:SetPosition(1,0)
        icon:SetVisible(false)

        local flash = wandsConduit.Elements["ConduitFlash"..tostring(i)] or conduits[i]:AddChild("ConduitFlash"..tostring(i), "GenericUI_Element_IggyIcon")
        flash:SetPosition(0,-30)
        flash:SetIcon("spellconduit_flash", 30, 60)
        flash:SetAlpha(1)
        flash._MovieClip.alpha = 0
        -- flash:GetUI():GetRoot().alpha = 0
    end
    conduitMain:SetPosition(450, (1026-conduitMain:GetHeight()))
    if Helpers.UI.Environment.Current ~= "Player" then
        conduitMain:SetVisible(false)
    else
        UpdateConduitSize(Helpers.Client.GetCurrentCharacter())
    end
    return conduitMain
end

Ext.Events.SessionLoaded:Subscribe(function(e)
    conduitMain = InitializeWandConduitUI()
end)

local positionOffset = {
    [1] = 0,
    [2] = -55,
    [3] = -112,
    [4] = -169,
    [5] = -226
}
Epip.Client.UI.Hotbar.Events.StateChanged:Subscribe(function(e)
    local barIndex = 0
    for i,bar in pairs(e.State.Bars) do
        if bar.Visible then
            barIndex = barIndex + 1
        else
            break
        end
    end
    conduitMain:SetPosition(450, (996-conduitMain:GetHeight() + positionOffset[barIndex]))
end)



Ext.RegisterNetListener("LX_WandsConduitAdd", function(channel, payload, ...)
    local info = Ext.Json.Parse(payload)
    for i,conduit in pairs(info.WandConduits) do
        if SCHOOL_TO_ICON[conduit] then
            local child = conduits[i]:GetChildren()[1]
            child:SetIcon("icon_"..SCHOOL_TO_ICON[conduit], 29, 29)
            child:SetVisible(true)
        end
    end
end)

local function UpdateConduitIcons(channel, payload, ...)
    local character = Ext.ClientEntity.GetCharacter(tonumber(payload))
    -- local mainHand, offHand = Helpers.Character.GetWeaponTypes(character)
    local totalSlots = UpdateConduitSize(character)
    if totalSlots == 0 then
        return
    end
    local spellConduits = character.UserVars.LX_SpellConduit or {}
    for i=(7-totalSlots),6,1 do
        local children = conduits[i]:GetChildren()
        local child
        local flash
        for j,c in pairs(children) do
            if string.starts(c.ID, "ConduitIcon") then
                child = c
            elseif string.starts(c.ID, "ConduitFlash") then
                flash = c
            end
        end
        if not child then return end
        if spellConduits[i] and SCHOOL_TO_ICON[spellConduits[i]] then
            child:SetIcon("icon_"..SCHOOL_TO_ICON[spellConduits[i]], 29, 29)
            child:SetVisible(true)
            if (i == totalSlots or i == #spellConduits) and channel == "LX_WandsConduitUpdateNew" then
                flash:Tween({
                    EventID = "LX_WandsConduitFlashNew_FadeIn",
                    Duration = 0.3,
                    Type = "To",
                    StartingValues = {
                        alpha = 1,
                        scaleY = 0.75,
                        y = -15
                    },
                    FinalValues = {
                        alpha = 1.3,
                        scaleY = 1.25,
                        y = -45
                    },
                    Function = "Quadratic",
                    Ease = "EaseOut",
                    Delay = 0,
                    OnComplete = function()
                        flash:Tween({
                            EventID = "LX_WandsConduitFlashNew_FadeOut",
                            Duration = 0.5,
                            Type = "To",
                            StartingValues = {
                                alpha = 1.3,
                                scaleY = 1.25,
                                y = -45,
                            },
                            FinalValues = {
                                alpha = 0,
                                scaleY = 0.5,
                                y = 0
                            },
                            Function = "Quadratic",
                            Ease = "EaseIn",
                            Delay = 0
                        })
                    end
                })
                child:Tween({
                    EventID = "LX_WandsConduitIcon_FadeIn",
                    Duration = 0.4,
                    Type = "To",
                    StartingValues = {
                        alpha = 0
                    },
                    FinalValues = {
                        alpha = 1
                    },
                    Function = "Quadratic",
                    Ease = "EaseIn",
                    Delay = 0.5
                })
            end
        else
            -- child:SetIcon("PIP_UI_Icon_AP_Simple_Empty", 30, 30)
            child:SetVisible(false)
        end
    end
end

Ext.RegisterNetListener("LX_WandsConduitUpdateNew", UpdateConduitIcons)
Ext.RegisterNetListener("LX_WandsConduitUpdate", UpdateConduitIcons)

Ext.Events.ResetCompleted:Subscribe(function (e)
    Helpers.Timer.Start(1000, function()
        UpdateConduitIcons(nil, _C().NetID)
    end)
    conduitMain = InitializeWandConduitUI()
end)

Helpers.UI.Environment:Subscribe(function(e)
    if not e.Character then return end
    local mainHand, offHand = Helpers.Character.GetWeaponTypes(e.Character)
    if e.Context == "Player" and (mainHand == "Wand" or offHand == "Wand") then
        conduitMain:SetVisible(true)
        UpdateConduitIcons(nil, e.Character.NetID)
    else
        conduitMain:SetVisible(false)
    end
end)

-- icon1 = conduitMain:AddChild("Memory1", "GenericUI_Element_Texture")
-- icon1:SetTexture("PIP_UI_Icon_AP_Simple_Empty", Epip.Vector.Create(32,32))
