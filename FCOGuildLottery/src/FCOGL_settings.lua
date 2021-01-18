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
------------------------------------------------------------------------------------------------------------------------
-- SETTINGS

--Read the SavedVariables
function FCOGuildLottery.getSettings()
    local svName, svVersion         = addonVars.addonSavedVariablesName, addonVars.addonSavedVarsVersion
    local svSettingsStr             = "Settings"
    local svSettingsAcrossAllStr    = "SettingsForAll"
    local worldName                 = GetWorldName()

    --The default values for the language and save mode
    local defaultsSettings = {
        language 	 		    = 1, --Standard: English
        saveMode     		    = 2, --Standard: Account wide settings
    }

    --Pre-set the deafult values
    local defaults = {
        --Debug
        debug = false,
        debugToChatToo = false,

        --Server + account wide base setting
        alwaysUseClientLanguage			    = true,
        --Server + account wide settings
        defaultDiceSides = FCOGL_DICE_SIDES_DEFAULT,

        diceRollHistory = {},
        diceRollGuildLotteryHistory = {},

        --false: Like MasterMerchant determines the sales from the history -> Until current time.
        --true: cut-off at midnght of the current day
        cutOffGuildSalesHistoryCurrentDateMidnight = false,

        autoPreFillChatEditBoxAfterDiceRollOnlyNumber = false,
        autoPreFillChatEditBoxAfterDiceRoll = false,
        preFillChatEditBoxAfterDiceRollTextTemplates = {
            normal = {
                [1] = "#<<1>>, congratulations to \'<<C:2>>\'"
            },
            guilds = {
                [1] = "#<<1>>, congratulations to \'<<C:2>>\'"
            },
        },

        --Date & time
        use24hFormat        = false,
        useCustomDateFormat = "",

        --UI
        -->Window
        UIwindow = {
            left    = 300,
            top     = 150,
            sortKeys = {
              [FCOGL_TAB_GUILDSALESLOTTERY] = "name",
            },
            sortOrder = {
              [FCOGL_TAB_GUILDSALESLOTTERY] = ZO_SORT_ORDER_DOWN,
            },
        }

    }
    FCOGuildLottery.settingsVars.defaults = defaults

    --=============================================================================================================
    --	LOAD USER SETTINGS
    --=============================================================================================================
    --Load the user's settings from SavedVariables file -> Account wide of basic version 999 at first
    FCOGuildLottery.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(svName, 999, svSettingsAcrossAllStr, defaultsSettings, worldName, nil)

    --Check, by help of basic version 999 settings, if the settings should be loaded for each character or account wide
    --Use the current addon version to read the settings now
    if (FCOGuildLottery.settingsVars.defaultSettings.saveMode == 1) then
        FCOGuildLottery.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(svName, svVersion , svSettingsStr, defaults, worldName, nil )
    else
        FCOGuildLottery.settingsVars.settings = ZO_SavedVars:NewAccountWide(svName, svVersion, svSettingsStr, defaults, worldName, nil )
    end
    --=============================================================================================================

    --Connect local variables with the SV
    FCOGuildLottery.diceRollHistory = FCOGuildLottery.settingsVars.settings.diceRollHistory
    FCOGuildLottery.diceRollGuildLotteryHistory = FCOGuildLottery.settingsVars.settings.diceRollGuildLotteryHistory

    --[[
    if GetDisplayName() == "@Baertram" then
        FCOGuildLottery.settingsVars.settings.debug = true
    end
    ]]
end