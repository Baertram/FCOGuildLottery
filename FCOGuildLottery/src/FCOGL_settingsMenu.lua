if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

local addonVars = FCOGuildLottery.addonVars
local addonName = addonVars.addonName
local addonNamePre = "["..addonName.."]"

--Debug messages
local df    = FCOGuildLottery.df
local dfa   = FCOGuildLottery.dfa
local dfe   = FCOGuildLottery.dfe
local dfv   = FCOGuildLottery.dfv
local dfw   = FCOGuildLottery.dfw

------------------------------------------------------------------------------------------------------------------------
--LibAddonMenu-2.0 SETTINGS MENU

function FCOGuildLottery.ShowLAMSettings()
    if FCOGuildLottery.FCOSettingsPanel == nil then return end
    FCOGuildLottery.LAM:OpenToPanel(FCOGuildLottery.FCOSettingsPanel)
end

function FCOGuildLottery.buildAddonMenu()
    local settings = FCOGuildLottery.settingsVars.settings
    if not settings or not FCOGuildLottery.LAM then return false end
    local defaults = FCOGuildLottery.settingsVars.defaults

    local panelData = {
        type 				= 'panel',
        name 				= addonVars.addonNameMenu,
        displayName 		= addonVars.addonNameMenuDisplay,
        author 				= addonVars.addonAuthor,
        version 			= tostring(addonVars.addonVersion),
        registerForRefresh 	= true,
        registerForDefaults = true,
        slashCommand        = "/fcogls",
        website             = addonVars.addonWebsite,
        feedback            = addonVars.addonFeedback,
        donation            = addonVars.addonDonation,
    }
    FCOGuildLottery.FCOSettingsPanel = FCOGuildLottery.LAM:RegisterAddonPanel(addonName .. "_LAM", panelData)

    local savedVariablesOptions = {
        [1] = 'Each character',
        [2] = 'Account wide'
    }
    local savedVariablesOptionsValues = {
        [1] = 1,
        [2] = 2,
    }

    local optionsTable =
    {	-- BEGIN OF OPTIONS TABLE

        {
            type = 'description',
            text = 'Helper addon for a guild lottery. Chat slash commands are:\n/dice <number>   Will roll a dice with <number> sides. If left empty this will roll a dice with 500 sides!\n/diceG1 - /diceG5  Will roll a dice for the number of guild members of guild 1 - 5\n/newgsl <guildIndex 1 to 5> will reset the last used lottery data and start a new one\n/gsl will roll the next dice for the active guild sales lottery.\n/gsllast or /dicelast will show the last dice roll results in your local chat (or if you got it enabled: within the \'DebugLogViewer\' UI) again.',
        },
        {
            type = 'dropdown',
            name = 'Settings save type',
            tooltip = 'Use account wide settings for all your characters, or save them separatley for each character?',
            choices = savedVariablesOptions,
            choicesValues = savedVariablesOptionsValues,
            getFunc = function() return FCOGuildLottery.settingsVars.defaultSettings.saveMode end,
            setFunc = function(value)
                FCOGuildLottery.settingsVars.defaultSettings.saveMode = value
            end,
            requiresReload = true,
        },

        --==============================================================================
        {
            type = 'header',
            name = 'Dice settings',
        },
        {
            type    = "slider",
            name    = "Default dice sides",
            tooltip = "The standard sides of a dice which you roll via the \'/dice\' slash command, or via the keybind \'Roll dice with def. sides\'",
            min     = 1,
            max     = FCOGL_MAX_DICE_SIDES,
            step    = 1,
            decimals = 0,
            autoSelect = true,
            getFunc = function() return settings.defaultDiceSides end,
            setFunc = function(value) settings.defaultDiceSides = value   end,
            default = function() return defaults.defaultDiceSides end,
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Guild role settings',
        },
        {
            type    = "editbox",
            name    = "Chat edit box: Dice roll result",
            tooltip = "Define the text that should be shown in the chat after a normal guild dice roll was done, and a member index was determined\n\nYou can use the following placeholders:\n<<1>>   Dice roll #\n<<2>>   @AccountName of guild member.",
            isMultiline = false,
            isExtraWide = true,
            getFunc = function() return settings.preFillChatEditBoxAfterDiceRollTextTemplates.normal[1] end,
            setFunc = function(value) settings.preFillChatEditBoxAfterDiceRollTextTemplates.normal[1] = value end,
            default = function() return defaults.preFillChatEditBoxAfterDiceRollTextTemplates.normal[1] end,
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Guild lottery settings',
        },
        {
            type    = "checkbox",
            name    = "Cut-off at 00:00 current day",
            tooltip = "Cut-off the guild sales history data at the current day at 00:00.\nNo newer events coming in after 00:00 via LibHistoire will be used for the ranking!\nIf this setting is disabled (default setting) the ranking will be using the same values as Master Merchant e.g. does for the 7 days ranking.",
            getFunc = function() return settings.cutOffGuildSalesHistoryCurrentDateMidnight end,
            setFunc = function(value) settings.cutOffGuildSalesHistoryCurrentDateMidnight = value end,
            default = function() return defaults.cutOffGuildSalesHistoryCurrentDateMidnight end,
        },
        {
            type    = "editbox",
            name    = "Chat edit box: Dice roll result",
            tooltip = "Define the text that should be shown in the chat after a guild sales lottery dice roll was done, and a member rank was determined\n\nYou can use the following placeholders:\n<<1>>   Dice roll #\n<<2>>   @AccountName of seller.",
            isMultiline = false,
            isExtraWide = true,
            getFunc = function() return settings.preFillChatEditBoxAfterDiceRollTextTemplates.guilds[1] end,
            setFunc = function(value) settings.preFillChatEditBoxAfterDiceRollTextTemplates.guilds[1] = value end,
            default = function() return defaults.preFillChatEditBoxAfterDiceRollTextTemplates.guilds[1] end,
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Debugging',
        },
        {
            type    = "checkbox",
            name    = "Debug",
            tooltip = "Enable debugging output",
            getFunc = function() return settings.debug  end,
            setFunc = function(value) settings.debug = value   end,
            default = function() return defaults.debug  end,
        },
        {
            type    = "checkbox",
            name    = "Chat output too (LibDebugLogger)",
            tooltip = "If LibDebugLogger is enabled the logging will only be shown in the UI DebugLogViewer, or within the SavedVariables file LibDebugLogger.lua.\nIf you enable the setting there also will be a chat output shown for you, but only if:\n|c5F5F5F\'LibDebugLogger\' is loaded AND \'DebugLogViewer\' is currently not loaded|r.",
            getFunc = function() return settings.debugToChatToo  end,
            setFunc = function(value) settings.debugToChatToo = value   end,
            default = function() return defaults.debugToChatToo  end,
            disabled = function() return not settings.debug or not LibDebugLogger or DebugLogViewer end
        }

    } -- optionsTable
    -- END OF OPTIONS TABLE
    --[[
    local lamPanelCreationInitDone = false
    local function LAMControlsCreatedCallbackFunc(pPanel)
        if pPanel ~= FCOGuildLottery.FCOSettingsPanel then return end
        if lamPanelCreationInitDone == true then return end
        --Do stiff here
        lamPanelCreationInitDone = true
    end
    ]]
    --CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", LAMControlsCreatedCallbackFunc)

    FCOGuildLottery.LAM:RegisterOptionControls(addonName .. "_LAM", optionsTable)
end
