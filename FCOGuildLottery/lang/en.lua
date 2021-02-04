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
}
local langEn = FCOGuildLottery.lang["en"]

for stringId, stringValue in pairs(langEn) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end