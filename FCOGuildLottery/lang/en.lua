if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

FCOGuildLottery.lang["en"] = {
    --1st entry in the search dropdown
    [FCOGL_SEARCHDROP_PREFIX .."1"]             = "Name",
    --The sort headers
    FCOGL_HEADER_RANK                           = "Rank",
    FCOGL_HEADER_NAME                           = "Seller",
    FCOGL_HEADER_DATE                           = "Date",
    FCOGL_HEADER_ITEM                           = "Item",
    FCOGL_HEADER_AMOUNT                         = "Amount",
    FCOGL_HEADER_PRICE                          = "Price",
    FCOGL_HEADER_TAX                            = "Tax",
    FCOGL_HEADER_INFO                           = "Info",
    FCOGL_HEADER_NO                             = "#",
    FCOGL_HEADER_ROLL                           = "Dice (Roll)",
    FCOGL_HEADER_MEMBER_NAME                    = "Member name",

    FCOGL_NO_GUILD                              = "-> No guild <-",

    FCOGL_DICE_SIDES                            = "# of sides of the dice",
    FCOGL_START_NEW_GUILD_SALES_LOTTERY         = "Start new guild sales lottery",
    FCOGL_ROLL_THE_DICE                         = "Roll the dice",
    FCOGL_REFRESH                               = "Refresh",
    FCOGL_SETTINGS                              = "Open settings",
    FCOGL_CLOSE                                 = "Close",
    FCOGL_TOGGLE_DICE_ROLL_HISTORY              = "Toggle dice roll history",
    FCOGL_GUILD_SALES_LOTTERY                   = "Guild sales lottery",

    FCOGL_DICE_PREFIX                           = "D",

    --LAM settings menu
    --Description
    FCOGL_LAM_DESCRIPTION                       = 'Helper addon for a guild lottery. Chat slash commands are:\n/fcogl   Toggle the UI\n/fcogls   Toggle the settings menu\n/dice <number>   Will roll a dice with <number> sides. If left empty this will roll a dice with 500 sides!\n/diceG1 - /diceG5  Will roll a dice for the number of guild members of guild 1 - 5\n/newgsl <guildIndex 1 to 5> will reset the last used lottery data and start a new one\n/gsl will roll the next dice for the active guild sales lottery.\n/gsllast or /dicelast will show the last dice roll results in your local chat (or if you got it enabled: within the \'DebugLogViewer\' UI) again.',
    --Headlines
    FCOGL_LAM_FORMAT_OPTIONS                    = "Output format",
    FCOGL_LAM_DICE_OPTIONS                      = 'Dice settings',
    FCOGL_LAM_GUILD_ROLL_OPTIONS                = 'Guild role settings',
    FCOGL_LAM_GUILD_LOTTERY_OPTIONS             = 'Guild lottery settings',
    FCOGL_LAM_DEBUG_OPTIONS                     = 'Debug',

    FCOGL_LAM_SAVE_TYPE                         = 'Settings save type',
    FCOGL_LAM_SAVE_TYPE_TT                      = 'Use account wide settings for all your characters, or save them separatley for each character?',

    --Options
    FCOGL_LAM_DEFAULT_DICE_SIDES                            = "Default dice sides",
    FCOGL_LAM_DEFAULT_DICE_SIDES_TT                         = "The standard sides of a dice which you roll via the \'/dice\' slash command, or via the keybind \'Roll dice with def. sides\'",
    FCOGL_LAM_GUILD_DICE_ROLL_RESULT_TO_CHAT_EDIT           = "Chat edit box: Dice roll result",
    FCOGL_LAM_GUILD_DICE_ROLL_RESULT_TO_CHAT_EDIT_TT        = "Define the text that should be shown in the chat after a normal guild dice roll was done, and a member index was determined\n\nYou can use the following placeholders:\n<<1>>   Dice roll #\n<<2>>   @AccountName of guild member.",
    FCOGL_LAM_GUILD_LOTTERY_DICE_ROLL_RESULT_TO_CHAT_EDIT_TT= "Define the text that should be shown in the chat after a guild sales lottery dice roll was done, and a member rank was determined\n\nYou can use the following placeholders:\n<<1>>   Dice roll #\n<<2>>   @AccountName of seller.",

    FCOGL_LAM_GUILD_LOTTERY_CUT_OFF_AT_MIDNIGHT     = "Cut-off at 00:00 current day",
    FCOGL_LAM_GUILD_LOTTERY_CUT_OFF_AT_MIDNIGHT_TT  = "Cut-off the guild sales history data at the current day at 00:00.\nNo newer events coming in after 00:00 via LibHistoire will be used for the ranking!\nIf this setting is disabled (default setting) the ranking will be using the same values as Master Merchant e.g. does for the 7 days ranking.",
    FCOGL_LAM_GUILD_LOTTERY_SHOW_UI_ON_DICE_ROLL    = "Show UI after dice roll",
    FCOGL_LAM_GUILD_LOTTERY_SHOW_UI_ON_DICE_ROLL_TT = "Automatically show the UI after a dice roll was done via a slash command. The dice roll history will be shown as well then.",
    FCOGL_LAM_GUILD_LOTTERY_DATE_FROM               = "Date from",
    FCOGL_LAM_GUILD_LOTTERY_DATE_FROM_TT            = "The start date of the guild sales lottery. Default value is today - 7 days (at midnight).",

    FCOGL_LAM_USE_24h_FORMAT                    = "Use 24h time format",
    FCOGL_LAM_USE_24h_FORMAT_TT                 = "Use the 24 hours time format for date & time formats",
    FCOGL_LAM_USE_CUSTOM_DATETIME_FORMAT        = "Custom date & time format",
    FCOGL_LAM_USE_CUSTOM_DATETIME_FORMAT_TT     = "Specify your own date & time format.\nLeve the edit field empty to use the standard date & time format.\nThe usable placeholders are pre-defined within the lua language:\n\n%a	abbreviated weekday name (e.g., Wed)\n%A	full weekday name (e.g., Wednesday)\n%b	abbreviated month name (e.g., Sep)\n%B	full month name (e.g., September)\n%c	date and time (e.g., 09/16/98 23:48:10)\n%d	day of the month (16) [01-31]\n%H	hour, using a 24-hour clock (23) [00-23]\n%I	hour, using a 12-hour clock (11) [01-12]\n%M	minute (48) [00-59]\n%m	month (09) [01-12]\n%p	either \"am\" or \"pm\" (pm)\n%S	second (10) [00-61]\n%w	weekday (3) [0-6 = Sunday-Saturday]\n%x	date (e.g., 09/16/98)\n%X	time (e.g., 23:48:10)\n%Y	full year (1998)\n%y	two-digit year (98) [00-99]\n%%	the character `%´",

    FCOGL_LAM_DEBUG_CHAT_OUTPUT_TOO             = "Chat output too (LibDebugLogger)",
    FCOGL_LAM_DEBUG_CHAT_OUTPUT_TOO_TT          = "If LibDebugLogger is enabled the logging will only be shown in the UI DebugLogViewer, or within the SavedVariables file LibDebugLogger.lua.\nIf you enable the setting there also will be a chat output shown for you, but only if:\n|c5F5F5F\'LibDebugLogger\' is loaded AND \'DebugLogViewer\' is currently not loaded|r.",


    --Keybindings
    SI_BINDING_NAME_FCOGL_TOGGLE                = "Toggle FCO GuildLottery UI",

}
local langEn = FCOGuildLottery.lang["en"]

for stringId, stringValue in pairs(langEn) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end