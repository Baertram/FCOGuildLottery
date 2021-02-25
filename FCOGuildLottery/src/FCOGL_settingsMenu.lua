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
            text = GetString(FCOGL_LAM_DESCRIPTION),
        },
        {
            type = 'dropdown',
            name = GetString(FCOGL_LAM_SAVE_TYPE),
            tooltip = GetString(FCOGL_LAM_SAVE_TYPE_TT),
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
            name = GetString(FCOGL_LAM_FORMAT_OPTIONS),
        },
        {
            type = "checkbox",
            name = GetString(FCOGL_LAM_USE_24h_FORMAT),
            tooltip = GetString(FCOGL_LAM_USE_24h_FORMAT_TT),
            getFunc = function() return settings.use24hFormat end,
            setFunc = function(value)
                settings.use24hFormat = value
            end,
            default = defaults.use24hFormat,
            disabled = function() return settings.useCustomDateFormat ~= "" end
        },
        {
            type = "editbox",
            name = GetString(FCOGL_LAM_USE_CUSTOM_DATETIME_FORMAT),
            tooltip = GetString(FCOGL_LAM_USE_CUSTOM_DATETIME_FORMAT_TT),
            getFunc = function() return settings.useCustomDateFormat end,
            setFunc = function(value)
                settings.useCustomDateFormat = value
            end,
            default = defaults.useCustomDateFormat,
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(FCOGL_LAM_DICE_OPTIONS),
        },
        {
            type    = "slider",
            name    = GetString(FCOGL_LAM_DEFAULT_DICE_SIDES),
            tooltip = GetString(FCOGL_LAM_DEFAULT_DICE_SIDES_TT),
            min     = 1,
            max     = FCOGL_MAX_DICE_SIDES,
            step    = 1,
            decimals = 0,
            autoSelect = true,
            getFunc = function() return settings.defaultDiceSides end,
            setFunc = function(value) settings.defaultDiceSides = value   end,
            default = function() return defaults.defaultDiceSides end,
        },
        {
            type    = "checkbox",
            name    = GetString(FCOGL_LAM_GUILD_LOTTERY_SHOW_UI_ON_DICE_ROLL),
            tooltip = GetString(FCOGL_LAM_GUILD_LOTTERY_SHOW_UI_ON_DICE_ROLL_TT),
            getFunc = function() return settings.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GENERIC] end,
            setFunc = function(value) settings.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GENERIC] = value end,
            default = function() return defaults.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GENERIC] end,
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(FCOGL_LAM_GUILD_ROLL_OPTIONS),
        },
        {
            type    = "editbox",
            name    = GetString(FCOGL_LAM_GUILD_DICE_ROLL_RESULT_TO_CHAT_EDIT),
            tooltip = GetString(FCOGL_LAM_GUILD_DICE_ROLL_RESULT_TO_CHAT_EDIT_TT),
            isMultiline = false,
            isExtraWide = true,
            getFunc = function() return settings.preFillChatEditBoxAfterDiceRollTextTemplates.normal[1] end,
            setFunc = function(value) settings.preFillChatEditBoxAfterDiceRollTextTemplates.normal[1] = value end,
            default = function() return defaults.preFillChatEditBoxAfterDiceRollTextTemplates.normal[1] end,
        },
        {
            type    = "checkbox",
            name    = GetString(FCOGL_LAM_GUILD_LOTTERY_SHOW_UI_ON_DICE_ROLL),
            tooltip = GetString(FCOGL_LAM_GUILD_LOTTERY_SHOW_UI_ON_DICE_ROLL_TT),
            getFunc = function() return settings.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC] end,
            setFunc = function(value) settings.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC] = value end,
            default = function() return defaults.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC] end,
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(FCOGL_LAM_GUILD_LOTTERY_OPTIONS)
        },
        {
            type    = "checkbox",
            name    = GetString(FCOGL_LAM_GUILD_LOTTERY_CUT_OFF_AT_MIDNIGHT),
            tooltip = GetString(FCOGL_LAM_GUILD_LOTTERY_CUT_OFF_AT_MIDNIGHT_TT),
            getFunc = function() return settings.cutOffGuildSalesHistoryCurrentDateMidnight end,
            setFunc = function(value) settings.cutOffGuildSalesHistoryCurrentDateMidnight = value end,
            default = function() return defaults.cutOffGuildSalesHistoryCurrentDateMidnight end,
        },

        {
            type    = "slider",
            name    = GetString(FCOGL_LAM_GUILD_LOTTERY_DAYS_BEFORE),
            tooltip = GetString(FCOGL_LAM_GUILD_LOTTERY_DAYS_BEFORE_TT),
            min = 1,
            max = FCOGL_MAX_DAYS_BEFORE,
            step = 1,
            getFunc = function() return settings.guildLotteryDaysBefore end,
            setFunc = function(value) settings.guildLotteryDaysBefore = value end,
            default = function() return defaults.guildLotteryDaysBefore end,
        },

        {
            type = 'datepicker',
            name = GetString(FCOGL_LAM_GUILD_LOTTERY_DATE_FROM),
            tooltip = GetString(FCOGL_LAM_GUILD_LOTTERY_DATE_FROM_TT),
            getFunc = function() return settings.guildLotteryDateStart end,
            setFunc = function(dateTimeStampPicked)
                settings.guildLotteryDateStart = dateTimeStampPicked
                settings.guildLotteryDateStartSet = true
            end,
            default = function() return defaults.guildLotteryDateStart end,
            width = "full",
            reference = "FCOGL_DatePickerFrom",
            disabled = function() return true  end
        },
        {
            type    = "editbox",
            name    = GetString(FCOGL_LAM_GUILD_DICE_ROLL_RESULT_TO_CHAT_EDIT),
            tooltip = GetString(FCOGL_LAM_GUILD_LOTTERY_DICE_ROLL_RESULT_TO_CHAT_EDIT_TT),
            isMultiline = false,
            isExtraWide = true,
            getFunc = function() return settings.preFillChatEditBoxAfterDiceRollTextTemplates.guilds[1] end,
            setFunc = function(value) settings.preFillChatEditBoxAfterDiceRollTextTemplates.guilds[1] = value end,
            default = function() return defaults.preFillChatEditBoxAfterDiceRollTextTemplates.guilds[1] end,
        },
        {
            type    = "checkbox",
            name    = GetString(FCOGL_LAM_GUILD_LOTTERY_SHOW_UI_ON_DICE_ROLL),
            tooltip = GetString(FCOGL_LAM_GUILD_LOTTERY_SHOW_UI_ON_DICE_ROLL_TT),
            getFunc = function() return settings.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY] end,
            setFunc = function(value) settings.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY] = value end,
            default = function() return defaults.showUIForDiceRollTypes[FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY] end,
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(FCOGL_LAM_DEBUG_OPTIONS),
        },
        {
            type    = "checkbox",
            name    = GetString(FCOGL_LAM_DEBUG_OPTIONS),
            tooltip = "Enable debugging output",
            getFunc = function() return settings.debug  end,
            setFunc = function(value) settings.debug = value   end,
            default = function() return defaults.debug  end,
        },
        {
            type    = "checkbox",
            name    = GetString(FCOGL_LAM_DEBUG_CHAT_OUTPUT_TOO),
            tooltip = GetString(FCOGL_LAM_DEBUG_CHAT_OUTPUT_TOO_TT),
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
