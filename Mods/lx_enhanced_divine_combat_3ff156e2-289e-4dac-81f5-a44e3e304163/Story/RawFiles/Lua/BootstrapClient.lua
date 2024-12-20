Data = {}
Ext.Require("BootstrapShared.lua")
-- Ext.Require("Shared/Helpers.lua")
Helpers.VPPrint("Loaded", "BootstrapClient")

---Ask the server for the UserID
Ext.Events.GameStateChanged:Subscribe(function(e)
	if e.FromState == "PrepareRunning" and e.ToState == "Running" then
		Ext.Net.PostMessageToServer("LX_AskClientInfo", tostring(Ext.ClientEntity.GetPlayerManager().ClientPlayerData[1].CharacterNetId))
	end
end)

Ext.Events.ResetCompleted:Subscribe(function(e)
	Ext.Net.PostMessageToServer("LX_AskClientInfo", tostring(Ext.ClientEntity.GetPlayerManager().ClientPlayerData[1].CharacterNetId))
end)

Ext.RegisterNetListener("LX_RetrieveClientInfo", function(channel, payload, ...)
	Data.UserID = tonumber(payload)
end)

-- Ext.Require("BootstrapShared.lua")

---@overload fun(string:BuiltinUISWFName):integer
Data.UIType = {
	actionProgression = 0,
	addContent = 57,
	addContent_c = 81,
	areaInteract_c = 68,
	arenaResult = 125,
	book = 2,
	bottomBar_c = 59,
	buttonLayout_c = 95,
	calibrationScreen = 98,
	campaignManager = 124,
	characterAssign = 52,
	characterAssign_c = 92,
	characterCreation = 3,
	characterCreation_c = 4,
	characterSheet = 119,
	chatLog = 6,
	combatLog = 7,
	combatLog_c = 65,
	combatTurn = 8,
	connectionMenu = 33,
	connectivity_c = 34,
	--consoleHints_c = -1,
	--consoleHintsPS_c = -1,
	containerInventory = { Default = 9, Pickpocket = 37},
	--containerInventory_lib = -1,
	containerInventoryGM = 143,
	contextMenu = { Default = 10, Object = 11 },
	contextMenu_c = { Default = 12, Object = 96 },
	craftPanel_c = 84,
	credits = 53,
	dialog = 14,
	dialog_c = 66,
	--diplomacy = -1,
	dummyOverhead = 15,
	encounterPanel = 105,
	enemyHealthBar = 42,
	engrave = 69,
	equipmentPanel_c = 64,
	examine = 104,
	examine_c = 67,
	feedback_c = 97,
	--fonts_en = -1,
	formation = 130,
	formation_c = 135,
	fullScreenHUD = 100,
	gameMenu = 19,
	gameMenu_c = 77,
	giftBagContent = 147,
	giftBagsMenu = 146,
	gmInventory = 126,
	GMItemSheet = 107,
	GMJournal = 139,
	GMMetadataBox = 109,
	GMMinimap = 113,
	GMMoodPanel = 108,
	GMPanelHUD = 120,
	GMRewardPanel = 131,
	GMSkills = 123,
	hotBar = 40,
	installScreen_c = 80,
	inventorySkillPanel_c = 62,
	itemAction = 86,
	itemGenerator = 106,
	itemSplitter = 21,
	itemSplitter_c = 85,
	journal = 22,
	journal_c = 70,
	journal_csp = 140,
	loadingScreen = 23,
	--LSClasses = -1,
	mainMenu = 28,
	mainMenu_c = 87, -- Still mainMenu, but this is used for controllers after clicking "Options" in the gameMenu_c
	menuBG = 56,
	minimap = 30,
	minimap_c = 60,
	mods = 49,
	mods_c = 103,
	monstersSelection = 127,
	mouseIcon = 31,
	msgBox = 29,
	msgBox_c = 75,
	notification = 36,
	--npcInfo = -1,
	optionsInput = 13,
	optionsSettings = { Default = 45, Video = 45, Audio = 1, Game = 17 },
	optionsSettings_c = { Default = 91, Video = 91, Audio = 88, Game = 89 },
	overhead = 5,
	overviewMap = 112,
	panelSelect_c = 83,
	partyInventory = 116,
	partyInventory_c = 142,
	partyManagement_c = 82,
	pause = 121,
	peace = 122,
	playerInfo = 38,
	playerInfo_c = 61, --Still playerInfo.swf, but the ID is different.
	possessionBar = 110,
	pyramid = 129,
	pyramid_c = 134,
	reputationPanel = 138,
	reward = 136,
	reward_c = 137,
	roll = 118,
	saveLoad = 39,
	saveLoad_c = 74,
	saving = 99,
	serverlist = 26,
	serverlist_c = 27,
	skills = 41,
	skillsSelection = 54,
	sortBy_c = 79,
	startTurnRequest = 145,
	startTurnRequest_c = 144,
	statsPanel_c = 63,
	statusConsole = 117,
	statusPanel = 128,
	stickiesPanel = 133,
	sticky = 132,
	storyElement = 71,
	--subtitles = -1,
	surfacePainter = 111,
	textDisplay = 43,
	--texture_lib = -1,
	--texture_lib_c = -1,
	tooltip = 44,
	--tooltipHelper = -1,
	--tooltipHelper_kb = -1,
	trade = 46,
	trade_c = 73,
	tutorialBox = 55,
	tutorialBox_c = 94,
	uiCraft = 102,
	--uiElements = -1,
	--uiElementsGM = -1,
	uiFade = 16,
	userProfile = 51,
	vignette = 114,
	voiceNotification_c = 93,
	watermark = 141,
	waypoints = 47,
	waypoints_c = 78,
	worldTooltip = 48,
}

Ext.Vars.RegisterUserVariable("LX_StatusConsumeMultiplier", {
    Server = true,
    Client = true, 
    SyncToClient = true,
    Persistent = false,
    SyncOnWrite = true,
    SyncOnTick = false,
})

Ext.Vars.RegisterUserVariable("LX_WarmupManager", {
    Server = true,
    Client = true, 
    SyncToClient = false,
    Persistent = false,
    SyncOnWrite = true,
    SyncOnTick = false,
})

Ext.Require("Client/_InitClient.lua")