if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

local addonVars = FCOGuildLottery.addonVars
local addonNamePre = FCOGuildLottery.addonNamePre

--Debug messages
local df    = FCOGuildLottery.df
local dfa   = FCOGuildLottery.dfa
local dfe   = FCOGuildLottery.dfe
local dfv   = FCOGuildLottery.dfv
local dfw   = FCOGuildLottery.dfw

local logger = FCOGuildLottery.logger

local em = EVENT_MANAGER

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--EVENTS

local function checkForHistyIsInitialized(isInitialCall)
    local loopsDone = 0
    local uniqueName = addonVars.addonName .. "_IsHistyReady"
    local function updateCheck()
        loopsDone = loopsDone + 1
        if loopsDone >= 100 then
            em:UnregisterForUpdate(uniqueName)
            dfe(addonNamePre .. "!!!!! \'LibHistoire\' was never initialized properly !!!!!")
        end
        if FCOGuildLottery.libHistoireIsReady == true then
            em:UnregisterForUpdate(uniqueName)
            df( ">>>>>>>>>> \'LibHistoire\' was initialized properly >>>>>>>>>>")
            --Get the default sales history time range of all guilds which own a guild store
            FCOGuildLottery.GetDefaultSalesHistoryData()
        end
    end
    em:UnregisterForUpdate(uniqueName)
    em:RegisterForUpdate(uniqueName, 50, updateCheck)
end

--Player activated function
local function playerActivated(eventId, isInitialCall)
    df( "EVENT_PLAYER_ACTIVATED - initial: %s", tostring(isInitialCall))

    checkForHistyIsInitialized(isInitialCall)

    FCOGuildLottery.playerActivatedDone = true
end

local function addonLoaded(eventName, addon)
    if addon ~= addonVars.addonName then return end
    em:UnregisterForEvent(eventName)

    --[[LIBRARIES]]
    --LibAddonMenu-2.0
    FCOGuildLottery.LAM = LibAddonMenu2

    --Get the SavedVariables
    FCOGuildLottery.getSettings()

    --Add the slash commands
    FCOGuildLottery.slashCommands()

    --Build the LAM settings panel
    FCOGuildLottery.buildAddonMenu()

    --Dialogs
    FCOGuildLottery.AskBeforeResetDialogInitialize(FCOGLAskBeforeResetDialogXML, "resetGuildSalesLottery")

    --EVENTS
    --Register for the zone change/player ready event
    em:RegisterForEvent(addonVars.addonName .. "EVENT_PLAYER_ACTIVATED", EVENT_PLAYER_ACTIVATED, playerActivated)
end

function FCOGuildLottery.initialize()
    em:RegisterForEvent(addonVars.addonName .. "EVENT_ADD_ON_LOADED", EVENT_ADD_ON_LOADED, addonLoaded)
end

--Load the addon
FCOGuildLottery.initialize()
