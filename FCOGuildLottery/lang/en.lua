if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

local addonVars = FCOGuildLottery.addonVars
local addonNameShort = addonVars.addonNameShort

FCOGuildLottery.lang = FCOGuildLottery.lang or {}
FCOGuildLottery.lang["en"] = {
    --1st entry in the search dropdown
    SEARCHDROP_PREFIX1 = "Name"
}
local langEn = FCOGuildLottery.lang["en"]

for stringId, stringValue in pairs(langEn) do
    local unqiueGetStringId = addonNameShort.."_"..tostring(stringId)
    ZO_CreateStringId(_G[unqiueGetStringId], stringValue)
    SafeAddVersion(_G[unqiueGetStringId], 1)
end