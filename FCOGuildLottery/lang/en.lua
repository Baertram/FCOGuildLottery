if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

FCOGuildLottery.lang = FCOGuildLottery.lang or {}
FCOGuildLottery.lang["en"] = {
    --1st entry in the search dropdown
    FCOGL_SEARCHDROP_PREFIX1          = "Name"
}
local langEn = FCOGuildLottery.lang["en"]

for stringId, stringValue in pairs(langEn) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end