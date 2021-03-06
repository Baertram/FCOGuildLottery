if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

FCOGuildLottery.clientLang = GetCVar("language.2")

------------------------------------------------------------------------------------------------------------------------
FCOGuildLottery.addonVars = {}
local addonVars = FCOGuildLottery.addonVars
addonVars.addonVersion		        = 0.1
addonVars.addonSavedVarsVersion	    = "0.02"
addonVars.addonName				    = "FCOGuildLottery"
addonVars.addonNameShort		    = "FCOGL"
addonVars.addonNameMenu  		    = "FCO GuildLottery"
addonVars.addonNameMenuDisplay	    = "|c00FF00FCO |cFFFF00 GuildLottery|r"
addonVars.addonSavedVariablesName   = "FCOGuildLottery_Settings"
addonVars.settingsName   		    = "FCO GuildLottery"
addonVars.addonAuthor			    = "Baertram"
addonVars.addonWebsite              = "https://www.esoui.com/downloads/info1542-FCOGuildLottery.html"
addonVars.addonFeedback             = "https://www.esoui.com/portal.php?uid=2028"
addonVars.addonDonation             = "https://www.esoui.com/portal.php?id=136&a=faq&faqid=131"

local addonName = FCOGuildLottery.addonVars.addonName
local addonNamePre = "["..addonName.."]"
FCOGuildLottery.addonNamePre = addonNamePre

------------------------------------------------------------------------------------------------------------------------
--Dice roll types for guilds, and generic without guilds
FCOGL_DICE_ROLL_TYPE_GENERIC                = -100
FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC          = 1
FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY    = 2
FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GENERIC

FCOGL_DICE_SIDES_NO_CHECK = -99999 --Do not do any checks against diceSide
FCOGL_DICE_SIDES_DEFAULT = 6  --Standard D6/W6 (dice with 6 sides)
FCOGL_MAX_DICE_SIDES = 999 --999 as of 2021-01-26
FCOGL_DEFAULT_GUILD_SELL_HISTORY_DAYS = 7 -- 1 week
FCOGL_MAX_DAYS_BEFORE = 100

------------------------------------------------------------------------------------------------------------------------
--String constants
FCOGuildLottery.lang = {}

FCOGuildLottery.constStr = {}
--Changed at 20210214, removed GuildName as the uniqueId will be used inside tables where the unique guildId is already given as a top level filter
--FCOGuildLottery.constStr.guildLotteryLastNDays = "GuildSellsLast%sDays_%s" --1st: days, 2nd: guildName
FCOGuildLottery.constStr.guildLotteryLastNDays = "GuildSells_Last%sDays" --1st: days

FCOGuildLottery.noGuildIndex = MAX_GUILDS + 1 -- The index of the first non-guild entry in the guilds dropdown box
------------------------------------------------------------------------------------------------------------------------
--Library variables
--LibHistoire
FCOGuildLottery.libHistoireIsReady = false

--LibHistoire
if LibHistoire ~= nil then
    FCOGuildLottery.LH = LibHistoire

    --Adding a callback to the LibHistoire INITIALIZED event
    FCOGuildLottery.LH:RegisterCallback(FCOGuildLottery.LH.callback.INITIALIZED, function()
        FCOGuildLottery.libHistoireIsReady = true
        --Further sales history read and build for the default 7 days backwards will be done at event_player_activated!
    end)
else
    df(addonNamePre .. "!!!!! ERROR Mandatory library \'LibHistoire\' is not found !!!!!")
end

------------------------------------------------------------------------------------------------------------------------
FCOGuildLottery.settingsVars = {}
FCOGuildLottery.settingsVars.defaultSettings = {}
FCOGuildLottery.settingsVars.settings = {}
FCOGuildLottery.settingsVars.defaults = {}

------------------------------------------------------------------------------------------------------------------------
FCOGuildLottery.playerActivatedDone = false

------------------------------------------------------------------------------------------------------------------------
--FCOGuildLottery.otherAddons = {}

------------------------------------------------------------------------------------------------------------------------
FCOGuildLottery.guildsData = {}

------------------------------------------------------------------------------------------------------------------------
FCOGuildLottery.lastRolledChatOutput = nil
FCOGuildLottery.lastRolledGuildChatOutput = nil

------------------------------------------------------------------------------------------------------------------------
FCOGuildLottery.guildSellListeners          = {}
FCOGuildLottery.guildSellListenerCompleted  = {}
FCOGuildLottery.guildSellStats              = {}
FCOGuildLottery.diceRollHistory             = {}
FCOGuildLottery.diceRollGuildsHistory       = {}
FCOGuildLottery.diceRollGuildLotteryHistory = {}

------------------------------------------------------------------------------------------------------------------------
FCOGuildLottery.defaultGuildSalesLotteryUniqueIdentifiers = {
    [1] = nil,
    [2] = nil,
    [3] = nil,
    [4] = nil,
    [5] = nil,
}

------------------------------------------------------------------------------------------------------------------------
FCOGuildLottery.dialogs = {}
FCOGuildLottery.dialogs.names = {
    ["resetGuildSalesLottery"] = "Dialog_ResetGuildSalesLottery",
}

------------------------------------------------------------------------------------------------------------------------
--UI
FCOGL_TAB_GUILDSALESLOTTERY = 1

FCOGL_TAB_STATE_LOADING = 1
FCOGL_TAB_STATE_LOADED  = 2

FCOGL_LISTTYPE_GUILD_SALES_LOTTERY = 1
FCOGL_LISTTYPE_ROLLED_DICE_HISTORY = 2

FCOGL_SEARCHDROP_PREFIX = "FCOGL_SEARCHDROP"
FCOGL_GUILDSDROP_PREFIX = "FCOGL_GUILDSDROP"
FCOGL_HISTORY_SEARCHDROP_PREFIX = "FCOGL_HISTORY_SEARCHDROP"
FCOGL_GUILDSALESHISTORYDROP_PREFIX = "FCOGL_GUILDSALESHISTORYDROP"

FCOGL_SEARCH_TYPE_NAME = 1
FCOGL_SEARCH_TYPE_HISTORY_NAME = 1

FCOGL_SEARCH_TYPE_ITERATION_END = FCOGL_SEARCH_TYPE_NAME
FCOGL_HISTORY_SEARCH_TYPE_ITERATION_END = FCOGL_SEARCH_TYPE_HISTORY_NAME

FCOGuildLottery.UI = {}
FCOGuildLottery.UI.window = nil
FCOGuildLottery.UI.diceHistoryWindow = nil
FCOGuildLottery.UI.SCENE_NAME = "FCOGuildLottery_UI_Scene"
FCOGuildLottery.UI.SCROLLLIST_DATATYPE_GUILDSALESRANKING    = 1
FCOGuildLottery.UI.SCROLLLIST_DATATYPE_ROLLED_DICE_HISTORY  = 2

--Preventer variables
FCOGuildLottery.prevVars = {
    doNotRunOnTextChanged = false
}
FCOGuildLottery.guildLotteryDaysBeforeSliderWasChanged = false