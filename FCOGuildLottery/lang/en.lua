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
    FCOGL_LAM_FORMAT_OPTIONS                    = "Output format",
    FCOGL_LAM_USE_24h_FORMAT                    = "Use 24h time format",
    FCOGL_LAM_USE_24h_FORMAT_TT                 = "Use the 24 hours time format for date & time formats",
    FCOGL_LAM_USE_CUSTOM_DATETIME_FORMAT        = "Custom date & time format",
    FCOGL_LAM_USE_CUSTOM_DATETIME_FORMAT_TT     = "Specify your own date & time format.\nLeve the edit field empty to use the standard date & time format.\nThe usable placeholders are pre-defined within the lua language:\n\n%a	abbreviated weekday name (e.g., Wed)\n%A	full weekday name (e.g., Wednesday)\n%b	abbreviated month name (e.g., Sep)\n%B	full month name (e.g., September)\n%c	date and time (e.g., 09/16/98 23:48:10)\n%d	day of the month (16) [01-31]\n%H	hour, using a 24-hour clock (23) [00-23]\n%I	hour, using a 12-hour clock (11) [01-12]\n%M	minute (48) [00-59]\n%m	month (09) [01-12]\n%p	either \"am\" or \"pm\" (pm)\n%S	second (10) [00-61]\n%w	weekday (3) [0-6 = Sunday-Saturday]\n%x	date (e.g., 09/16/98)\n%X	time (e.g., 23:48:10)\n%Y	full year (1998)\n%y	two-digit year (98) [00-99]\n%%	the character `%´",

    --Keybindings
    SI_BINDING_NAME_FCOGL_TOGGLE                = "Toggle FCO GuildLottery UI",

}
local langEn = FCOGuildLottery.lang["en"]

for stringId, stringValue in pairs(langEn) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end