if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

local addonName = FCOGuildLottery.addonVars.addonName
local addonNamePre = "["..addonName.."]"

--LibHistoire
local lh
--LibDateTime
--local ldt = FCOGuildLottery.LDT

--Debug messages
local df    = FCOGuildLottery.df
local dfa   = FCOGuildLottery.dfa
local dfe   = FCOGuildLottery.dfe
local dfv   = FCOGuildLottery.dfv
local dfw   = FCOGuildLottery.dfw

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--FUNCTIONS
--Helper functions
local function diffInDays(startTimestamp, endTimestamp)
    endTimestamp = endTimestamp or GetTimeStamp()
    local daysDiff = os.difftime(endTimestamp, startTimestamp) / (60 * 60 * 24)
    return math.floor(daysDiff)
end


--Guild functions
local function resetCurrentGuildSalesLotteryData(startingNewLottery, guildIndex, daysBefore)
    startingNewLottery = startingNewLottery or false
    if startingNewLottery == false and FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier == nil then
        return
    end
    df( "ResetCurrentGuildSalesLotteryData - startingNewLottery: " ..tostring(startingNewLottery))
    FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryTimestamp     = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryRolls         = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryLastRolledChatOutput = nil

    FCOGuildLottery.currentlyUsedGuildSalesLotteryDaysBefore = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryStartTime  = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryEndTime       = nil

    FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId       = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildIndex    = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildName     = nil

    FCOGuildLottery.currentlyUsedGuildSalesLotteryData          = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank= nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberCount   = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums = nil
    FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellCounts = nil

    FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GENERIC
    if startingNewLottery == false then
        df("<END: guild sales lottery data was deleted <<<<<<<<<<<<<<<<<<<<<")
    else
        df("<OLD guild sales lottery data was deleted - STARTING a new lottery now >>>>>>>>>>>>>>>>>>>>")
        if guildIndex ~= nil and daysBefore ~= nil then
            FCOGuildLottery.NewGuildSalesLottery(guildIndex, daysBefore)
        end
    end
end

local function IsGuildIndexValid(guildIndex)
    return (guildIndex ~= nil and guildIndex >= 1 and guildIndex <= MAX_GUILDS) or false
end
FCOGuildLottery.IsGuildIndexValid = IsGuildIndexValid

local function getGuildIdAndName(guildIndex)
    local guildId = GetGuildId(guildIndex)
    local guildName = ZO_CachedStrFormat(SI_UNIT_NAME, GetGuildName(guildId))
    return guildId, guildName
end
FCOGuildLottery.getGuildIdAndName = getGuildIdAndName


local function chatOutputRolledDice(rolledDiceSide, rolledName, guildIndex)
    --Put info into the chat so one just needs to press the return key
    local settings = FCOGuildLottery.settingsVars.settings
    if settings.autoPreFillChatEditBoxAfterDiceRoll == true then
        local chatText
        if settings.autoPreFillChatEditBoxAfterDiceRollOnlyNumber == true then
            chatText = "#<<1>> <<C:2>>"
        else
            if guildIndex ~= nil then
                --Todo: Random chatText template
                local chatTemplates = settings.preFillChatEditBoxAfterDiceRollTextTemplates.guilds
                chatText = chatTemplates[1]
            else
                local chatTemplates = settings.preFillChatEditBoxAfterDiceRollTextTemplates.normal
                chatText = chatTemplates[1]
            end
        end
        local chatChannel = CHAT_CHANNEL_SAY
        if IsGuildIndexValid(guildIndex) == true then
            chatChannel = _G["CHAT_CHANNEL_GUILD_" .. tostring(guildIndex)]
        end
        --"#<<1>>, congratulations to \'<<C:2>>\'"
        StartChatInput(zo_strformat(chatText, tostring(rolledDiceSide), tostring(rolledName)), chatChannel, nil)
    end
end

local function checkIfPendingSellEventAndResetGuildSalesLottery(guildId)
    if FCOGuildLottery.IsSellEventPendingForGuildId(guildId) == true then
        FCOGuildLottery.ResetCurrentGuildSalesLotteryData(true, false, nil, nil, nil, nil)
        return
    end
end

function FCOGuildLottery.FormatDate(timeStamp)
    if not timeStamp then return end
    return os.date("%c", timeStamp)
end

local function checkIfUIShouldBeShownOrUpdated(diceRollType, hideHistory, guildIndex)
    df("checkIfUIShouldBeShownOrUpdated - diceRollType %s, hideHistory %s, guildIndex %s", tostring(diceRollType), tostring(hideHistory), tostring(guildIndex))
    if not diceRollType then return end
    hideHistory = hideHistory or false
    --Is the UI already sown?
    local showUINow = false
    local fcoglUI = FCOGuildLottery.UI

    local function updateUIGuildsDropNow()
df(">updateUIGuildsDropNow")
        --Set the guilds dropdownbox at the UI, if no active guild sales lottery
        if FCOGuildLottery.IsGuildSalesLotteryActive() then return end
        if diceRollType == FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC and guildIndex ~= nil then
            fcoglUI.ChangeGuildsDropSelectedByGuildIndex(guildIndex, false)
        elseif diceRollType == FCOGL_DICE_ROLL_TYPE_GENERIC then
            fcoglUI.ChangeGuildsDropSelectedByIndex(MAX_GUILDS + 1, false)
        end
    end


    local fcoglUIwindow = fcoglUI and fcoglUI.window
    local isWindowAlreadyShown = false
    if fcoglUIwindow ~= nil then
        if fcoglUIwindow.frame == nil then
            showUINow = true
        else
            isWindowAlreadyShown = not fcoglUIwindow.frame:IsControlHidden()
            if isWindowAlreadyShown == false then
                showUINow = true
            end
        end
    else
        showUINow = true
    end
    if isWindowAlreadyShown == false and showUINow then
        --Show the UI if enabled in the settings
        local settings = FCOGuildLottery.settingsVars.settings
        local showUIForDiceRollTypes = settings.showUIForDiceRollTypes
        local showUIForDiceRollType = showUIForDiceRollTypes[diceRollType] or false
df(">isWindowAlreadyShown: false, showUINow: true, showUIForDiceRollType: %s", tostring(showUIForDiceRollType))
        if not showUIForDiceRollType then return end

        --Create (if not exisitng yet) and show the UI window, and the dice history according to setting
        fcoglUI.Show(true, hideHistory)

        updateUIGuildsDropNow()
    elseif isWindowAlreadyShown == true then
df(">isWindowAlreadyShown: true")
        --Should the dice history be shown?
        local diceHistoryWindow = fcoglUI.diceHistoryWindow
        if diceHistoryWindow ~= nil and diceHistoryWindow.frame ~= nil then
            local isDiceHistoryHidden = diceHistoryWindow.frame:IsControlHidden()
            if isDiceHistoryHidden then
                diceHistoryWindow.frame:SetHidden(false)
                fcoglUI.setDiceRollHistoryButtonState(false)
                FCOGuildLottery.settingsVars.settings.UIDiceHistoryWindow.isHidden = false
            end
        end
        updateUIGuildsDropNow()
    end
end

function FCOGuildLottery.buildGuildsDropEntries()
--d("[FCOGuildLottery]buildGuildsDropEntries")
    local guildsComboBoxEntryBase = {}
    local cnt = 0
    local guildsOfAccount = {}
    for guildIndex=1, GetNumGuilds() do
        local guildId = GetGuildId(guildIndex)
        FCOGuildLottery.diceRollGuildsHistory[guildId] = FCOGuildLottery.diceRollGuildsHistory[guildId] or {}
        local gotTrader = (IsPlayerInGuild(guildId) and DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE)) or false
        local guildName = ZO_CachedStrFormat(SI_UNIT_NAME, GetGuildName(guildId))
        if not gotTrader then
            guildName = "|cFF0000" .. guildName .. "|r"
        end
        guildsOfAccount[guildIndex] = {
            index       = guildIndex,
            id          = guildId,
            name        = string.format("(%s) %s", tostring(guildIndex), guildName),
            nameClean   = guildName,
            gotTrader   = gotTrader
        }
    end
    for guildIndex, guildData in ipairs(guildsOfAccount) do
        cnt = cnt + 1
        local stringId = FCOGL_GUILDSDROP_PREFIX .. tostring(guildIndex)
        ZO_CreateStringId(stringId, guildData.name)
        SafeAddVersion(stringId, 1)
        table.insert(guildsComboBoxEntryBase, {
            index               =   guildIndex,
            id                  =   guildData.id,
            name                =   guildData.name,
            nameClean           =   guildData.nameClean,
            gotTrader           =   guildData.gotTrader,
        })
    end
    --[[
    --Sort the chars table by their name
    if guildsComboBoxEntryBase ~= nil and #guildsComboBoxEntryBase > 0 then
        table.sort(guildsComboBoxEntryBase,
            --Sort function, returns true if item a will be before b
            function(a,b)
                --Move the current char to the top of the list (current char name starts with " -")
                --if string.sub(tostring(a.name), 1, 2) == " -" or string.sub(tostring(b.name), 1, 2) == " -" then
                --    return true
                --else
                    return a.name < b.name
                --end
            end
        )
    end
    ]]
    return guildsComboBoxEntryBase
end

function FCOGuildLottery.UpdateCurrentDiceRollType(uiWindow)
    df("UpdateCurrentDiceRollType")
    local fcoglUI = FCOGuildLottery.UI
    uiWindow = uiWindow or fcoglUI.window
    if uiWindow == nil then return end
    if uiWindow.frame ~= nil then
        --The UI is shown?
        if not uiWindow.frame:IsControlHidden() then
            --Get the guilds dropdown selected data
            local selectedGuildsDropdownData = fcoglUI.getSelectedGuildsDropEntry()
            local selectedIndex = selectedGuildsDropdownData.selectedIndex
            local isGuild = selectedGuildsDropdownData.isGuild
            local guildIndex = selectedGuildsDropdownData.index
            local guildId = selectedGuildsDropdownData.id
            local isGuildSalesLotteryActive = FCOGuildLottery.IsGuildSalesLotteryActive()

            local currentDiceRollType = FCOGuildLottery.currentlyUsedDiceRollType
            df(">frame not hidden - currentDiceRollType: %s, guildsDropSelectedIndex: %s", tostring(currentDiceRollType), tostring(selectedIndex))
            local newDiceRolltype
            if currentDiceRollType == FCOGL_DICE_ROLL_TYPE_GENERIC then
                if IsGuildIndexValid(guildIndex) then
                    if isGuildSalesLotteryActive then
                        newDiceRolltype = FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY
                    else
                        newDiceRolltype = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
                    end
                end

            elseif currentDiceRollType == FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC or
                    currentDiceRollType == FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY then
                if guildId ~= nil and IsGuildIndexValid(guildIndex) then
                    if isGuildSalesLotteryActive then
                        newDiceRolltype = FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY
                    else
                        newDiceRolltype = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
                    end
                else
                    newDiceRolltype = FCOGL_DICE_ROLL_TYPE_GENERIC
                end
            end

            df(">>newDiceRolltype: %s", tostring(newDiceRolltype))
            FCOGuildLottery.currentlyUsedDiceRollType = newDiceRolltype
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--LibDateTime
--[[
local function getTraderWeekFromDate(dateStr)
    --TODO Change dateStr to a valid dateStr. datetime could be 2021013 or 2021-01-13 or 13.01.2021 etc.
    --local timeStampOfDateStr = ldt:CalculateTimeStamp(year, month, day, hour, minute, second)
    local timeStampOfDateStr = GetTimeStamp()
    --local isInTraderWeek = ldt:IsInTraderWeek(timeStampOfDateStr)
    local weekOffset = ldt:CalculateWeekOffset(timeStampOfDateStr)
    local isoWeekAndYear, tradingWeekStart, tradingWeekEnd = ldt:GetTraderWeek(weekOffset)
    if not tradingWeekStart or not tradingWeekEnd then return nil, nil, nil end
    return isoWeekAndYear, tradingWeekStart, tradingWeekEnd
end
]]

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Slash command functions
local function showNewGSLSlashCommandHelp(noGuildSelected)
    noGuildSelected = noGuildSelected or false
    local newGSLChatErrorMessage
    local uiWindow = FCOGuildLottery.UI and FCOGuildLottery.UI.window and FCOGuildLottery.UI.window.control
    if uiWindow ~= nil and uiWindow:IsControlHidden() == false then
        if noGuildSelected == true then
            newGSLChatErrorMessage = "Please select a guild from the guilds dropdown box!\nElse you are only able to use the dice button to throw a random dice throw with the sides you have defined with the editbox next to the button."
        else
            newGSLChatErrorMessage = "The selected guild does not seem be valid. Please select the guild from the guilds dropdown box."
        end
    else
        newGSLChatErrorMessage = "Please use the slash command /newgsl <guildIndex> <daysBeforeCurrent> to start a new guild sales lottery.\nReplace <guildIndex> with the index 81 to 5) of your guilds, and optinally replace <daysBeforeCurrent> with the count of days you want to check the guild sales history for.\nIf this 2nd parameter is left empty " ..tostring(FCOGL_DEFAULT_GUILD_SELL_HISTORY_DAYS) .. " days will be used as default value.\n\nAfter starting a new guild sales lottery via /newgsl you can use /gsl to throw the next dice."
    end
    dfa(newGSLChatErrorMessage)
end


local function checkAndShowNoTraderMessage(guildIndex)
    local guildId, guildName = getGuildIdAndName(guildIndex)
    local gotTrader = (IsPlayerInGuild(guildId) and DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE)) or false
    if not gotTrader then
        local noTraderChatErrorMessage = "Either you are not a member of the guild \'%s\' aymore, or ths guild does not use a trader."
        dfa(noTraderChatErrorMessage, guildName)
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- LibHistoire
local function showGuildEventsStillFetchingMessage(guildId, guildIndex)
    guildIndex = guildIndex or FCOGuildLottery.GetGuildIndexById(guildId)
    local _, guildName = getGuildIdAndName(guildIndex)
    dfe( "The listener for the guild #" ..tostring(guildIndex) .." \'" .. guildName .. "\' (ID: " ..tostring(guildId) ..") is still fetching events...\nPlease wait (could take minutes), or open the guild history of that guild and manually press the \'Get more\' keybind to fetch more events, until all missing ones were added!\nThis is only working if the mising data is a small timeframe like 2-10 days.\nAlso check if LibHistoire is still fetching data or if it is fully linked and updated.")
end

local function showGuildEventsNoTraderWeekDeterminedMessage(dateStr)
    dfe( "The trading week for the given date \'" ..tostring(dateStr) .." \' could not be determined." )
end

local function showGuildEventsNoMemberCountMessage(guildId, guildIndex)
    guildIndex = guildIndex or FCOGuildLottery.GetGuildIndexById(guildId)
    local _, guildName = getGuildIdAndName(guildIndex)
    dfe( "The count of members having sold any items, for the guild #" ..tostring(guildIndex) .." \'" .. guildName .. "\' (ID: " ..tostring(guildId) .."), is 0.\nEither no items were sold in the selected timeframe, or there occured an error!\nPlease try to manually update the guild history via the \'Get more\' keybind at the guild's history. Also check if LibHistoire is still fetching data or if it is fully linked and updated.")
end


function FCOGuildLottery.FetchHistyLibrary()
    df( "FetchHistyLibrary")
    if lh == nil or FCOGuildLottery.LH == nil then
        FCOGuildLottery.LH = LibHistoire
        lh = FCOGuildLottery.LH
        if lh == nil then
            dfe( "!!!!! Mandatory library \'LibHistoire\' could not be loaded !!!!!")
        end
    end
end

function FCOGuildLottery.GetSellEventListenerForGuildId(guildId)
df( "GetSellEventListenerForGuildId - guildId: " ..tostring(guildId) .. " -> " ..tostring(FCOGuildLottery.guildSellListeners[guildId]))
    if lh == nil or not FCOGuildLottery.libHistoireIsReady or guildId == nil then return end
    return FCOGuildLottery.guildSellListeners[guildId]
end


function FCOGuildLottery.IsSellEventPendingForAnyGuildId()
    if lh == nil or not FCOGuildLottery.libHistoireIsReady then return end

    local sellEventsForGuildsActive = FCOGuildLottery.guildSellListenerCompleted
    if not sellEventsForGuildsActive then return false end
    for guildId, _ in pairs(sellEventsForGuildsActive) do
        local isPending, timeLeft = FCOGuildLottery.IsSellEventPendingForGuildId(guildId) == true
        if isPending == true then
            return true, timeLeft
        end
    end
    return false, 0
end

function FCOGuildLottery.IsSellEventPendingForGuildId(guildId)
    if lh == nil or not FCOGuildLottery.libHistoireIsReady then return nil, nil end
    df( "IsSellEventPendingForGuildId - guildId: %s", tostring(guildId))
--d( string.format("IsSellEventPendingForGuildId - guildId: %s", tostring(guildId)))

    --[[
        1. weißt du, dass du alle Daten hast wenn der SetIterationCompletedCallback aufgerufen wird
        2. kannst du mittels der GetPendingEventMetrics Funktion abfragen wie weit die iteration ist
        3. wenn eventCount 0 ist und SetIterationCompleted nicht aufgerufen wurde, kannst du annehmen, dass noch Daten ausstehen
    ]]
    local guildEventSellListener = FCOGuildLottery.GetSellEventListenerForGuildId(guildId)
    if not guildEventSellListener then return nil, nil end
    --All data was received already for the guildId?
    if FCOGuildLottery.guildSellListenerCompleted[guildId] == true then
        df("<guild sell listener was completed!")
--d("<guild sell listener was completed!")
        return false, 0
    end

    --is the listener still running or did it end?
    local isRunning = guildEventSellListener:IsRunning()
    if not isRunning then
        df("<guild sell listener not actively running!")
--d("<guild sell listener not actively running!")
        return false, 0
    end
    --eventCount - the amount of stored or unlinked events that are currently waiting to be processed by the listener
    --processingSpeed - the average processing speed in events per second or -1 if not enough data is yet available
    --timeLeft - the estimated time in seconds it takes to process the remaining events or -1 if no estimate is possible
    local eventCount, processingSpeed, timeLeft = guildEventSellListener:GetPendingEventMetrics()
    df(">eventCount: %s, processingSpeed: %s, timeLeft: %s", tostring(eventCount), tostring(processingSpeed), tostring(timeLeft))
--d(string.format(">eventCount: %s, processingSpeed: %s, timeLeft: %s", tostring(eventCount), tostring(processingSpeed), tostring(timeLeft)))
    local errorMsg = false
    if eventCount > 0 then
        --Workaround as there often happens to be the eventCount = 1, but the listener itsself at the guildHistory says: All data fetched?!
        if eventCount == 1 and processingSpeed == -1 and timeLeft == -1 then
            --TODO: How to check that LibHistoire's data for the sell event at guildId is all done?
            if isRunning == true then
                -->Assume all is okay....
                return false, 0
            end
            errorMsg = true
        end
    elseif eventCount == 0 then
        errorMsg = true
        timeLeft = 0 --unknown timeleft, as currently there are no events
    end
    if errorMsg == true then
        showGuildEventsStillFetchingMessage(guildId)
        return true, timeLeft
    end
    return false, 0
end

function FCOGuildLottery.AddTradeSellEvent(guildId, uniqueIdentifier, eventType, eventId, eventTime, param1, param2, param3, param4, param5, param6)
    if lh == nil or not FCOGuildLottery.libHistoireIsReady or
        not guildId or not uniqueIdentifier or not eventId then return end
--dfv( "AddTradeSellEvent - guildId: %s, uniqueIdentifier: %s, seller: %s, buyer: %s, quantity: %s, itemlink: %s, price: %s, tax: %s ", tostring(guildId), tostring(uniqueIdentifier), tostring(param1), tostring(param2), tostring(param3), tostring(param4), tostring(param5), tostring(param6))
    FCOGuildLottery.guildSellStats[guildId][uniqueIdentifier] = FCOGuildLottery.guildSellStats[guildId][uniqueIdentifier] or {}
    local eventTimeFormated = os.date("%c", eventTime)
    local eventKey = param1 .. "_" .. Id64ToString(eventId) .. "_" .. eventTime .. "_"  .. "_" .. eventTimeFormated
    FCOGuildLottery.guildSellStats[guildId][uniqueIdentifier][eventKey] = {
        eventId     = Id64ToString(eventId),
        eventTime   = eventTime, --today: format the date and time from timestamp!
        eventTimeFormated = eventTimeFormated, --today: format the date and time from timestamp!
        seller      = param1, --seller
        buyer       = param2, --buyer
        quantity    = param3, --quantity
        itemLink    = param4, --itemLink
        price       = param5, --price
        tax         = param6  --tax
    }

    --[[
    --TODO: For debugging and comparison with MM data!
    local guildName = GetGuildName(guildId)
    FCOGuildLottery._FCOGL7DaysData = FCOGuildLottery._FCOGL7DaysData or {}
    FCOGuildLottery._FCOGL7DaysData[guildName] = FCOGuildLottery._FCOGL7DaysData[guildName] or {}
    FCOGuildLottery._FCOGL7DaysData[guildName][eventTime .. "(" ..eventTimeFormated .. ")_" .. Id64ToString(eventId)] = {
      seller = param1,
      amount = param5,
      stack = param3,
      wasKiosk = (param2 ~= nil and true) or false,
    }
    ]]

end
local addTradeSellEvent = FCOGuildLottery.AddTradeSellEvent

--Get guild store sell statistics from LibHistoire stored events
function FCOGuildLottery.CollectGuildSellStats(guildId, startDate, endDate, uniqueIdentifier)
    df( "CollectGuildSellStats - guildId: %s, startDate: %s, endDate: %s, uniqueIdentifier: %s", tostring(guildId),tostring(startDate),tostring(endDate),tostring(uniqueIdentifier) )
    if lh == nil or not FCOGuildLottery.libHistoireIsReady then
        dfe( "CollectGuildSellStats - Mandatory library \LibHistoire\' not found, or not ready yet!")
    elseif guildId == nil or uniqueIdentifier == nil or uniqueIdentifier == "" or startDate == nil or endDate == nil or
           startDate == nil or endDate == nil then
        dfe( "CollectGuildSellStats - Either guildId: %s, startTradingDay: %s, endTradingDay: %s or uniqueIdentifier: %s are not given!", tostring(guildId),tostring(startDate),tostring(endDate),tostring(uniqueIdentifier))
        return
    elseif startDate and endDate and startDate > endDate then
        dfe( "CollectGuildSellStats - startTradingDay: " ..tostring(startDate) .. " is newer than endTradingDay: " ..tostring(endDate))
    end
--d(">>listener 0")

    --Create the listener for the guild history sold items
    local listener
    local existingListener = FCOGuildLottery.GetSellEventListenerForGuildId(guildId)
    if existingListener == nil then
        listener = lh:CreateGuildHistoryListener(guildId, GUILD_HISTORY_STORE)
        df(">New listener created for guildId: %s", tostring(guildId))
    else
        listener = existingListener
        df(">re-using existing listener for guildId: %s", tostring(guildId))
    end
    if listener == nil then
        dfe( "CollectGuildSellStats - Listener coud not be found/created! GuildId: " ..tostring(guildId) .. ", startTradingDay: " ..tostring(startDate).. ", endTradingDay: " ..tostring(endDate).. ", uniqueIdentifier: " ..tostring(uniqueIdentifier))
        return
    end
    FCOGuildLottery.guildSellListeners[guildId] = listener
--d(">>listener 1")
    --Did the timeframe change?
    if FCOGuildLottery.currentlyUsedGuildSalesLotteryStartTime == nil or startDate ~= FCOGuildLottery.currentlyUsedGuildSalesLotteryStartTime or
            FCOGuildLottery.currentlyUsedGuildSalesLotteryEndTime == nil or endDate ~= FCOGuildLottery.currentlyUsedGuildSalesLotteryEndTime or
            FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier == nil or uniqueIdentifier ~= FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier then
        df(">listener's timeFrame changed: %s to %s", os.date("%c", startDate), os.date("%c", endDate))
--d(string.format(">listener's timeFrame changed: %s to %s", os.date("%c", startDate), os.date("%c", endDate)))

        --Stop the listener if we want to set a new timeframe!
        if listener:IsRunning() then
            df(">>listener needed to be stopped")
            listener:Stop()
        end
        --Slightly difference to MM data. maybe because SetTimeFrame includes the start but excludes the end?
        --listener:SetTimeFrame(startTradingDay, endTradingDay)
        listener:SetAfterEventTime(startDate) --Excluding the start
        listener:SetBeforeEventTime(endDate) --Including the end

        --Create / reset the guildSalesStats for the current guildId, and the flag "callback completed"
        FCOGuildLottery.guildSellListenerCompleted[guildId] = false
        FCOGuildLottery.guildSellStats[guildId] = FCOGuildLottery.guildSellStats[guildId] or {}

        --Add the callbacks to the listener
        if existingListener == nil then
            listener:SetNextEventCallback(function(eventType, eventId, eventTime, ...) --param1, param2, param3, param4, param5, param6
                if eventType == GUILD_EVENT_ITEM_SOLD then
                    local guildIdOfListener = listener:GetGuildId()
                    dfv(">listener:SetNextEventCallback - guildId: %s, eventType: %s, eventTime: %s", tostring(guildIdOfListener), tostring(eventType), tostring(eventTime))
                    FCOGuildLottery.guildSellListenerCompleted[guildIdOfListener] = false
                    addTradeSellEvent(guildIdOfListener, uniqueIdentifier, eventType, eventId, eventTime, ...)
                end
            end)
            --Events are still coming in from guild history
            listener:SetMissedEventCallback(function(eventType, eventId, eventTime, param1, param2, param3, param4, param5, param6)
                if eventType == GUILD_EVENT_ITEM_SOLD then
                    local guildIdOfListener = listener:GetGuildId()
                    dfw( "Missed event detected-eventId: %s, guildId: %s, eventTime: %s, seller: %s, buyer: %s, quantity: %s, itemLink: %s, price: %s, tax: %s", tostring(eventId), tostring(guildIdOfListener), tostring(eventTime), tostring(param1), tostring(param2), tostring(param3), tostring(param4), tostring(param5), tostring(param6))
                end
            end)

            listener:SetIterationCompletedCallback(function()
                local guildIdOfListener = listener:GetGuildId()
                df( "<<<~~~~~~~~~~ CollectGuildSellStats - end for guildId: %s ~~~~~~~~~~<<<", tostring(guildIdOfListener) )
                FCOGuildLottery.guildSellListenerCompleted[guildIdOfListener] = true
            end)
        end

        df( ">>>~~~~~~~~~~ CollectGuildSellStats - listener started for guildId: %s ~~~~~~~~~~>>>", tostring(guildId) )
        listener:Start()
    end
end

function FCOGuildLottery.CompareMMAndFCOGLGuildSalesData(guildIndex)
    if not IsGuildIndexValid(guildIndex) then return end
    local guildName = GetGuildName(GetGuildId(guildIndex))
    dfa("CompareMMAndFCOGLGuildSalesData - guildIndex: %s, name: %s", tostring(guildIndex), guildName)
    if FCOGuildLottery._FCOGL7DaysData and FCOGuildLottery._FCOGL7DaysData[guildName] then
        if FCOGuildLottery._mm7DaysData and FCOGuildLottery._mm7DaysData[guildName] then
            local mmSalesData = FCOGuildLottery._mm7DaysData[guildName]
            local fcoglSalesData = FCOGuildLottery._FCOGL7DaysData[guildName]

            local countMM = NonContiguousCount(mmSalesData)
            local countFCOGL = NonContiguousCount(fcoglSalesData)
            dfa("Count MM/FCOGL: %s/%s", tostring(countMM), tostring(countFCOGL))
            local tabToUse, tabToCompare
            tabToUse = (countMM > countFCOGL) and mmSalesData or fcoglSalesData
            tabToCompare = (countMM > countFCOGL) and fcoglSalesData or mmSalesData
            FCOGuildLottery._missing7DaysData = {}
            local missingTabKey
            if countMM > countFCOGL then
                missingTabKey = "FCOGL"
            else
                missingTabKey = "MM"
            end
            local foundMissing = 0
            local foundEqual = 0
            FCOGuildLottery._missing7DaysData[missingTabKey] = {}
            FCOGuildLottery._equal7DaysData = {}
            for key, data in pairs(tabToUse) do
                if tabToCompare[key] == nil then
                    FCOGuildLottery._missing7DaysData[missingTabKey][key] = data
                    foundMissing = foundMissing + 1
                else
                    FCOGuildLottery._equal7DaysData[key] = data
                    foundEqual = foundEqual + 1
                end
            end
            dfa("Found %s equal events. Found %s missing events in %s!", tostring(foundEqual), tostring(foundMissing), missingTabKey)
        else
            dfe("MasterMerchant guild sales data is missing for guild \'%s\'!", guildName)
        end
    else
        dfe("FCOGuildHistory guild sales data is missing for guild \'%s\'!", guildName)
    end

end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
local function buildUniqueId(guildId, daysToGetBefore)
    daysToGetBefore = daysToGetBefore or FCOGL_DEFAULT_GUILD_SELL_HISTORY_DAYS
    local guildName = GetGuildName(guildId)
    --Changed at 20210214, removed GuildName as the uniqueId will be used inside tables where the unique guildId is already given as a top level filter
    --local uniqueId = string.format(FCOGuildLottery.constStr.guildLotteryLastNDays, tostring(daysToGetBefore), guildName)
    local uniqueId = string.format(FCOGuildLottery.constStr.guildLotteryLastNDays, tostring(daysToGetBefore))
    df( "buildUniqueId - guildId: %s, daysToGetBefore: %s, guildName: %s -> uniqueId: %s", tostring(guildId), tostring(daysToGetBefore), guildName, uniqueId)
    return uniqueId
end
FCOGuildLottery.BuildUniqueId = buildUniqueId

local function getDateMinusXDays(daysToGetBefore)
    --[[
    -MasterMerchant_Guild.lua -> Get guild trader change time (Start of the day)
    -- Calc Day Cutoff in Local Time
      local dayCutoff = GetTimeStamp() - GetSecondsSinceMidnight()
      (...)
      o.eightStart    = dayCutoff - 7 * 86400 -- last 7 days

    o.eightStart is the cutoff for sales to that filter, i.e. older sales are rejected. So it's start of current day minus 7 days, which matches my experience. It doesn't reset on Tuesday 15h00.
    ]]
    daysToGetBefore = daysToGetBefore or FCOGL_DEFAULT_GUILD_SELL_HISTORY_DAYS --7
    if daysToGetBefore <= 0 then daysToGetBefore = 1 end
    local currentDayCurrentTime = GetTimeStamp()
    local currentDayMidnight = currentDayCurrentTime - GetSecondsSinceMidnight()
    local timeStart = currentDayMidnight - (daysToGetBefore * (24 * 60 * 60)) --86400 seconds a day * <daysToGetBefore> days
    local timeEnd = currentDayCurrentTime

    local settings = FCOGuildLottery.settingsVars.settings
    if settings.cutOffGuildSalesHistoryCurrentDateMidnight == true then
        timeEnd = currentDayMidnight
    end
--d(">getDateMinusXDays - startDate: " .. tostring(timeStart) .. ", endDate: " ..tostring(timeEnd))

    return timeStart, timeEnd
end


--Guild store sell statistics from now to - daysToGetBefore days
function FCOGuildLottery.PrepareSellStatsOfGuild(guildId, daysToGetBefore)
    if not guildId or not daysToGetBefore then return end
    --Get the actual trading week via LibDateTime
    --Not needed!
    --local isoWeekAndYear, tradingWeekStart, tradingWeekEnd = getTraderWeekFromDate(daysToGetBefore)
    --Manually calculate the last n days
    local startDate, endDate = getDateMinusXDays(daysToGetBefore)
    --d( string.format("PrepareSellStatsOfGuild - guildId: %s, daysToGetBefore: %s, dateStart: %s, dateEnd: %s", tostring(guildId), tostring(daysToGetBefore), os.date("%c", startDate) , os.date("%c", endDate)))
    df( "PrepareSellStatsOfGuild - guildId: %s, daysToGetBefore: %s, dateStart: %s, dateEnd: %s", tostring(guildId), tostring(daysToGetBefore), os.date("%c", startDate) , os.date("%c", endDate))

    --77951 - Fair Trade Society
    --guildId = guildId or 77951
    --UniqueId: "GuildSellsLast%sDays_%s"
    local uniqueIdentifier = buildUniqueId(guildId, daysToGetBefore)
    FCOGuildLottery.CollectGuildSellStats(guildId, startDate, endDate, uniqueIdentifier)
    return uniqueIdentifier, startDate, endDate--, isoWeekAndYear
end

--Get the efault (7 days) sales history data of each guild which got a store enabled
function FCOGuildLottery.GetDefaultSalesHistoryData()
    df( "GetDefaultSalesHistoryData - Getting sales history of the last %s days, for all guilds...", tostring(FCOGL_DEFAULT_GUILD_SELL_HISTORY_DAYS))
    if lh == nil then FCOGuildLottery.FetchHistyLibrary() end
    FCOGuildLottery.defaultGuildSalesLotteryUniqueIdentifiers = {}
    --Prepare the sold history data for the 5 guilds, of the last 7 days
    for guildIndex=1, GetNumGuilds(), 1 do
        --Are you in that guild?
        local guildId = GetGuildId(guildIndex)
        if guildId and guildId > 0 then
            --Am I member of this guild?
            if IsPlayerInGuild(guildId) and DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE) then
                --Does this guild use a shop?
                local unqiueId, _ = FCOGuildLottery.PrepareSellStatsOfGuild(guildId, FCOGL_DEFAULT_GUILD_SELL_HISTORY_DAYS)
                FCOGuildLottery.defaultGuildSalesLotteryUniqueIdentifiers[guildId] = unqiueId
            end
        end
    end
end

--Get the count of members who sold something via the guild store, in a timeframe from a given endTime - daysToGetBefore days
function FCOGuildLottery.GetGuildSalesMemberCount(guildId, daysToGetBefore, startTime, endTime, uniqueIdentifier)
    if not guildId or not daysToGetBefore then return end
    if daysToGetBefore <= 0 then daysToGetBefore = 1 end
    if not endTime or not startTime then return end

    df( "GetGuildSalesMemberCount-guildId: %s, daysToGetBefore: %s, startTime: %s, endTime: %s, uniqueIdentifier: %s", tostring(guildId), tostring(daysToGetBefore), tostring(startTime), tostring(endTime), tostring(uniqueIdentifier))

    local countMembersHavingSold = 0
    local currentlyUsedGuildSalesLotteryMemberCount = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberCount
    if FCOGuildLottery.currentlyUsedGuildSalesLotteryData ~= nil and currentlyUsedGuildSalesLotteryMemberCount ~= nil and currentlyUsedGuildSalesLotteryMemberCount > 0 then
        df(">currentlyUsedGuildSalesLotteryMemberCount: " ..tostring(currentlyUsedGuildSalesLotteryMemberCount))
        --d(">currentlyUsedGuildSalesLotteryMemberCount: " ..tostring(currentlyUsedGuildSalesLotteryMemberCount))
        return currentlyUsedGuildSalesLotteryMemberCount
    else
        --Check the sales data for the guildId
        --[[
            --Each entry looks like this
            --Will only work if the listerner "end" callback has fired, so that the requested data was "all" found!
            FCOGuildLottery.guildSellStats[guildId][uniqueIdentifier][eventTime] = {
                eventId     = Id64ToString(eventId),
                eventTime   = eventTime, --today: format the date and time from timestamp!
                eventTimeFormated = eventTimeFormated, --today: format the date and time from timestamp!
                seller      = param1, --seller
                buyer       = param2, --buyer
                quantity    = param3, --quantity
                itemLink    = param4, --itemLink
                price       = param5, --price
                tax         = param6  --tax
            }
        ]]

        --Is the listener of this guild still working?
        if checkIfPendingSellEventAndResetGuildSalesLottery(guildId) then return end

        --df(">got here 1: Listener okay, data should be there")
        if FCOGuildLottery.guildSellStats ~= nil then
            local sellStatsOfGuildId = FCOGuildLottery.guildSellStats[guildId]
            if sellStatsOfGuildId ~= nil then
                uniqueIdentifier = uniqueIdentifier or buildUniqueId(guildId, daysToGetBefore)
                --d(">uniqueIdentifier: " ..tostring(uniqueIdentifier) .. ", daysToGetBefore: " ..tostring(daysToGetBefore))
                local sellStatsDetailsOfGuildId = sellStatsOfGuildId[uniqueIdentifier]
                if sellStatsDetailsOfGuildId ~= nil then
                    --df(">got here 2 - uniqueId data found")
                    FCOGuildLottery.currentlyUsedGuildSalesLotteryData = sellStatsDetailsOfGuildId
                    local currentlyUsedGuildSalesLotteryMemberSellCounts = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellCounts

                    local settings = FCOGuildLottery.settingsVars.settings
                    local cutOffGuildSalesHistoryCurrentDateMidnight = settings.cutOffGuildSalesHistoryCurrentDateMidnight

                    --Count the sells of each different seller name
                    --    local eventTimeFormated = os.date("%c", eventTime)
                    --local eventKey = param1 .. "_" .. eventId .. "_" .. eventTime .. "_"  .. "_" .. eventTimeFormated
                    for eventKey, guildSellData in pairs(sellStatsDetailsOfGuildId) do
                        local eventTime = guildSellData.eventTime
                        --Difference to MM data: MM always includes events after 00:00 of the current day (for the 7,10,30 days ranking)
                        local addEvent = false
                        if cutOffGuildSalesHistoryCurrentDateMidnight == true then
                            if eventTime >= startTime and eventTime <= endTime then
                                addEvent = true
                            end
                        else
                            if eventTime >= startTime then
                                addEvent = true
                            end
                        end
                        if addEvent == true then
                            local memberName = guildSellData.seller
                            if memberName ~= nil and memberName ~= "" then
                                local currentCount = currentlyUsedGuildSalesLotteryMemberSellCounts[memberName]
                                currentCount = currentCount or 0
                                --New member detected?
                                if currentCount == 0 then
                                    local currentlyUsedGuildSalesLotteryMemberCountLoc = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberCount
                                    FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberCount = currentlyUsedGuildSalesLotteryMemberCountLoc + 1
                                end
                                --Increase the counter for the sells of this member by 1
                                FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellCounts[memberName] = currentCount + 1
                                --Increase the counter for the sells value (price) of this member by the price of the actual item
                                FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums[memberName] = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums[memberName] or {
                                    sumPrice = 0,
                                    sumTax   = 0,
                                    sumQuantity = 0,
                                }
                                local actualSellSumDataOfMember = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums[memberName]
                                FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums[memberName].sumPrice       = actualSellSumDataOfMember.sumPrice    + guildSellData.price
                                FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums[memberName].sumTax         = actualSellSumDataOfMember.sumTax      + guildSellData.tax
                                FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums[memberName].sumQuantity    = actualSellSumDataOfMember.sumQuantity + guildSellData.quantity
                            end
                        end
                    end
                    for memberName, sumData in pairs(FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums) do
                        table.insert(FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank, {
                            --rank
                            --memberName
                            --soldSum
                            --taxSum
                            --amountSum
                            rank        = -1,
                            memberName  = memberName,
                            soldSum     = sumData.sumPrice,
                            taxSum      = sumData.sumTax,
                            amountSum   = tostring(currentlyUsedGuildSalesLotteryMemberSellCounts[memberName]) .. "/" .. tostring(sumData.sumQuantity),
                        })
                    end
                    table.sort(FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank, function(a,b) return a.soldSum > b.soldSum end)
                    --Update the rank in the table data now
                    for rank, tabData in ipairs(FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank) do
                        tabData.rank = rank
                    end
                    countMembersHavingSold = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberCount
                end
            end
        end
    end
    return countMembersHavingSold
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function FCOGuildLottery.GetGuildIndexById(guildId)
    if not guildId then return end
    for guildIndex = 1, GetNumGuilds(), 1 do
        local guildIdToCompare = GetGuildId(guildIndex)
        if guildId == guildIdToCompare then return guildIndex end
    end
    return
end
local GetGuildIndexById = FCOGuildLottery.GetGuildIndexById

function FCOGuildLottery.GetGuildId(guildIndex)
    if not IsGuildIndexValid(guildIndex) then return end
    return getGuildIdAndName(guildIndex)
end

function FCOGuildLottery.GetGuildMemberCount(guildIndex)
    if not IsGuildIndexValid(guildIndex) then return end
    local numMembers = GetGuildInfo(GetGuildId(guildIndex))
    return numMembers
end

function FCOGuildLottery.GetGuildName(guildIndex, noChatOutput, shortChatOutput)
    noChatOutput = noChatOutput or false
    shortChatOutput = shortChatOutput or false
    if not IsGuildIndexValid(guildIndex) then return end
    local guildId, guildName = getGuildIdAndName(guildIndex)
    if not noChatOutput then
        if shortChatOutput == true then
            dfa( "Guild name: %s", tostring(guildName))
        else
            dfa( "Guild name of guild no %s (server-wide unique ID: %s): %s", tostring(guildIndex), tostring(guildId), tostring(guildName))
        end
    end
    return guildName, guildId
end

function FCOGuildLottery.GetGuildInfo(guildIndex, noChatOutput)
    noChatOutput = noChatOutput or false
    if not IsGuildIndexValid(guildIndex) then return end
    local guildId, guildName = getGuildIdAndName(guildIndex)
    local numMembers, numOnline, leaderName, numInvitees = GetGuildInfo(guildId)
    if not noChatOutput then
        dfa(">>==============================>>")
        dfa( "GuildInfo about your guild no. %s (server-wide unique ID: %s), name: %s", tostring(guildIndex), tostring(guildId), tostring(guildName))
        dfa(">Leader name: %s / Open invitations: %s", tostring(leaderName), tostring(numInvitees))
        dfa(">Member count: %s / Currently online: %s", tostring(numMembers), tostring(numOnline))
        dfa("<<==============================<<")
    end
    return numMembers, numOnline, leaderName, numInvitees
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Dice functions
--Roll a dice until a new value was rolled, which wasn't rolled before (isn't in table rolledBefore)
local function rollADiceUntilNewValue(diceSides, rolledBefore)
    if not diceSides or diceSides == 0 then return end
    df("rollADiceUntilNewValue - diceSides: %s, rolledBefore: %s", tostring(diceSides), tostring(rolledBefore ~= nil))
    local validRollFound = false
    local abortCounter = 0
    local diceSide
    while validRollFound == false or abortCounter <= diceSides do
        abortCounter = abortCounter + 1
        --Pop some random numbers to make it really random
        math.random(); math.random(); math.random()
        diceSide = zo_roundToZero(math.random(1, diceSides))
        if rolledBefore == nil or ( rolledBefore ~= nil and not rolledBefore[diceSide]) then
            rolledBefore = rolledBefore or {}
            rolledBefore[diceSide] = true
            --Force end of while loop
            validRollFound = true
            abortCounter = diceSides + 1
        else
            df(">Rolled a duplicate number \'%s\'. Re-rolling directly ...", tostring(diceSide))
        end
    end
    return diceSide
end

function FCOGuildLottery.RollTheDiceAndUpdateUIIfShown(sidesOfDice, noChatOutput, diceRollTypeOverride)
    local diceRollData = FCOGuildLottery.RollTheDice(sidesOfDice, noChatOutput, diceRollTypeOverride)
    if diceRollData ~= nil then
        FCOGuildLottery.UI.RefreshWindowLists()
    end
end
local rollTheDiceAndUpdateUIIfShown = FCOGuildLottery.RollTheDiceAndUpdateUIIfShown

--Roll the dice with pre-defined sides of the dice. Do further checks for a guild sales lottery, or other guild related
--rolls.
--Do not check any further if it's only a dice roll.
--Returns a table:
--[[
    diceRollData = {
        --Info about the dice roller
        displayName = @AccountNameOfTheDiceRoller,
        characterId = CharacterIdOfTheDiceRoller,
        --Info about the throw/roll
        timestamp   = timeStampAsTheRollWasDone,
        diceSides   = sidesOfDiceUsed,
        roll        = theRolledRandomDiceValue,
        --Optional (only if guildId was given):
        guildId                            = guildId
        guildIndex                         = guildIndex
        --GuildMemeber who was met with the roll (dice side = memberIndex)
        rolledGuildMemberName              = rolledGuildMemberDisplayName
        rolledGuildMemberStatus            = playerStatus
        rolledGuildMemberSecsSinceLogoff   = secondsSinceLogoff
        soldSum                            = valueOfSoldItemsAsSum
    }
]]
function FCOGuildLottery.RollTheDice(sidesOfDice, noChatOutput, diceRollTypeOverrite)
    noChatOutput = noChatOutput or false
    sidesOfDice = sidesOfDice or FCOGL_MAX_DICE_SIDES --Number of max guild members, currently 500
    if sidesOfDice <= 0 then sidesOfDice = 1 end
df( "RollTheDice - sidesOfDice: %s, noChatOutput: %s, normalDiceRoll: %s", tostring(sidesOfDice), tostring(noChatOutput), tostring(isNormalDiceRoll))

    local now = GetTimeStamp()
    math.randomseed(os.time()) -- random initialize

    local isNormalDiceRoll
    local diceRollType
    local isNormalGuildRoll
    local isGuildSalesLottery
    if diceRollTypeOverrite ~= nil then
        if diceRollTypeOverrite == FCOGL_DICE_ROLL_TYPE_GENERIC then
            isNormalDiceRoll = true
            isGuildSalesLottery = false
            isNormalGuildRoll = false
            diceRollType      = FCOGL_DICE_ROLL_TYPE_GENERIC

        elseif diceRollTypeOverrite == FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC then
            isNormalDiceRoll = false
            isGuildSalesLottery = false
            isNormalGuildRoll = true
            diceRollType      = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC

        elseif diceRollTypeOverrite == FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY then
            isNormalDiceRoll = false
            isGuildSalesLottery = true
            isNormalGuildRoll = false
            diceRollType      = FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY
        end
    else
        diceRollType        = FCOGuildLottery.currentlyUsedDiceRollType
        --isNormalGuildRoll = (diceRollTypeGuild == FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC) or false
        isGuildSalesLottery = (diceRollType == FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY) or false
    end

    --Create random dice value
    local diceSide

    if isGuildSalesLottery == true then
        if FCOGuildLottery.currentlyUsedGuildSalesLotteryRolls ~= nil then
            diceSide = rollADiceUntilNewValue(sidesOfDice, FCOGuildLottery.currentlyUsedGuildSalesLotteryRolls)
            if sidesOfDice == 1 then
                --Reset the table
                FCOGuildLottery.currentlyUsedGuildSalesLotteryRolls = {}
            end
        else
            dfe("> Guild sales lottery previously rolled dice throws were not found! Aborting now...")
            resetCurrentGuildSalesLotteryData()
        end
    else
        --Pop some random numbers to make it really random
        math.random(); math.random(); math.random()
        diceSide = zo_roundToZero(math.random(1, sidesOfDice))
    end

    local guildId = FCOGuildLottery.currentlyUsedDiceRollGuildId
    local rolledGuildMemberDisplayName, memberNote, rankIndex, playerStatus, secsSinceLogoff, guildIndex, soldSum
    if not isNormalDiceRoll and guildId ~= nil then
        --Get the guildMember with the rolled dice value (or if guild sales lottery: from the sales history data -> via LibHistoire)
        rolledGuildMemberDisplayName, memberNote, rankIndex, playerStatus, secsSinceLogoff, guildIndex, soldSum = FCOGuildLottery.GetRolledGuildMemberInfo(guildId, diceSide, isGuildSalesLottery)
        if rolledGuildMemberDisplayName == nil then
            dfe( "<ABORT: rolledGuildMemberDisplayName is nil - sidesOfDice: %s, guildId: %s", tostring(sidesOfDice), tostring(guildId))
            return
        end
    end
    local diceRollData = {
        --Info about the dice roller
        displayName = GetDisplayName(),
        characterId = GetCurrentCharacterId(),
        --Info about the throw/roll
        timestamp   = now,
        diceSides   = sidesOfDice,
        roll        = diceSide,

    }
    if not isNormalDiceRoll and guildId ~= nil then
        --Optional: Info about the guild it was rolled for (if provided)
        diceRollData.guildId                            = guildId
        diceRollData.guildIndex                         = guildIndex
        --GuildMemeber who was met with the roll (dice side = memberIndex)
        diceRollData.rolledGuildMemberName              = rolledGuildMemberDisplayName
        diceRollData.rolledGuildMemberStatus            = playerStatus
        diceRollData.rolledGuildMemberSecsSinceLogoff   = secsSinceLogoff
        soldSum                                         = soldSum
    end
    if not isGuildSalesLottery then
        if not isNormalDiceRoll and guildId ~= nil then
            FCOGuildLottery.diceRollGuildsHistory[guildId] = FCOGuildLottery.diceRollGuildsHistory[guildId] or {}
            FCOGuildLottery.diceRollGuildsHistory[guildId][now] = diceRollData
        else
            FCOGuildLottery.diceRollHistory[now] = diceRollData
        end
    end
    if not noChatOutput then
        local diceTypeStr
        --local settings = FCOGuildLottery.settingsVars.settings
        if not isNormalDiceRoll and guildId ~= nil then
            local guildName = GetGuildName(guildId)
            if isGuildSalesLottery == true then
                diceTypeStr = string.format(GetString(FCOGL_DICE_TYPE_STRING_GUILDSALESLOTTERY), guildName)
            else
                diceTypeStr = string.format(GetString(FCOGL_DICE_TYPE_STRING_GUILD), guildName)
            end
        else
            diceTypeStr = GetString(FCOGL_DICE_TYPE_STRING_RANDOM)
        end
        local lastDiceRollChatOutput = string.format(GetString(FCOGL_LASTROLLED_DICE_CHAT_OUTPUT), diceTypeStr, tostring(sidesOfDice), tostring(diceSide))
        dfa( lastDiceRollChatOutput )

        --Remember the last chat output of the dice rolle for the slash commands /gsllast and /dicelast
        if not isNormalDiceRoll and guildId ~= nil then
            local memberFoundText
            if isGuildSalesLottery == true then
                memberFoundText = string.format(GetString(FCOGL_LASTROLLED_DICE_FOUND_MEMBER_SOLD_CHAT_OUTPUT), tostring(rolledGuildMemberDisplayName), tostring(diceSide), tostring(soldSum))
                lastDiceRollChatOutput = lastDiceRollChatOutput .. "\n" .. memberFoundText
                FCOGuildLottery.currentlyUsedGuildSalesLotteryLastRolledChatOutput = lastDiceRollChatOutput
            else
                memberFoundText = string.format(GetString(FCOGL_LASTROLLED_DICE_FOUND_MEMBER_CHAT_OUTPUT), tostring(rolledGuildMemberDisplayName))
                lastDiceRollChatOutput = lastDiceRollChatOutput .. "\n" .. memberFoundText
                FCOGuildLottery.lastRolledGuildChatOutput = lastDiceRollChatOutput
            end
            dfa( memberFoundText )
        else
            FCOGuildLottery.lastRolledChatOutput = lastDiceRollChatOutput
        end
    end
    local rolledName = diceRollData.rolledGuildMemberName
    if not isNormalDiceRoll and guildId ~= nil then
        rolledName = diceRollData.rolledGuildMemberName
    else
        rolledName = ""
        guildIndex = nil
    end
    chatOutputRolledDice(diceSide, rolledName, guildIndex)

    --Show the UI now, and expand the dice roll history
    checkIfUIShouldBeShownOrUpdated(diceRollType, false, guildIndex)

    return diceRollData
end

function FCOGuildLottery.RollTheDiceWithDefaultSides(noChatOutput)
    --Is a guildId selected?
    local sidesOfDice = 0
    if FCOGuildLottery.currentlyUsedDiceRollGuildId ~= nil then
        --Get the count of guild members
        sidesOfDice = FCOGuildLottery.GetGuildMemberCount(GetGuildIndexById(FCOGuildLottery.currentlyUsedDiceRollGuildId))
    else
        sidesOfDice = FCOGuildLottery.settingsVars.settings.defaultDiceSides
    end
    df("RollTheDiceWithDefaultSides - sidesOfDice: %s, noChatOutput: %s", tostring(sidesOfDice), tostring(noChatOutput))
    if sidesOfDice <= 0 then sidesOfDice = FCOGL_DICE_SIDES_DEFAULT end

    rollTheDiceAndUpdateUIIfShown(sidesOfDice, noChatOutput, nil)
end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Lottery functions

function FCOGuildLottery.IsGuildSalesLotteryActive()
    return (FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier ~= nil and
           FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildIndex ~= nil and
           FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId ~= nil) or false
end

function FCOGuildLottery.UpdateMaxDiceSidesForGuildLottery(numDiceSides)
    df("UpdateMaxDiceSidesForGuildLottery - numDiceSides: %s", tostring(numDiceSides))
    if FCOGuildLottery.UI == nil or FCOGuildLottery.UI.window == nil then
        FCOGuildLottery.tempEditBoxNumDiceSides = numDiceSides
        return
    end
    FCOGuildLottery.tempEditBoxNumDiceSides = nil
    if numDiceSides == nil then return end
    FCOGuildLottery.prevVars.doNotRunOnTextChanged = true
    FCOGuildLottery.UI.window.editBoxDiceSides:SetText(tostring(numDiceSides))
end

function FCOGuildLottery.ReloadGuildSalesLotteryRanks()
    df("ReloadGuildSalesLotteryRanks")
    if not FCOGuildLottery.IsGuildSalesLotteryActive() then return end
end

--Reset the stored / last used data and enable a new lottery dice throw, where the popups of guild and timeFrame selection
--are showing up again
function FCOGuildLottery.ResetCurrentGuildSalesLotteryData(noSecurityQuestion, startingNewLottery, guildIndex, daysBefore, callbackYes, callbackNo)
    df("FCOGuildLottery.ResetCurrentGuildSalesLotteryData - noSecurityQuestion: %s, startingNewLottery: %s, guildIndex: %s, daysBefore: %s, guildSalesLotteryIdActive: %s", tostring(noSecurityQuestion), tostring(startingNewLottery), tostring(guildIndex), tostring(daysBefore), tostring(FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier))
    noSecurityQuestion = noSecurityQuestion or false
    local resetDataNow = false
    --ONLY resetting the data?
    if noSecurityQuestion == true and startingNewLottery == false and guildIndex == nil and daysBefore == nil then
        resetDataNow = true
    else
        if FCOGuildLottery.IsGuildSalesLotteryActive() then
            if not noSecurityQuestion then
                --Show security question dialog
                --Do you really want to reset... ?
                local resetGuildSalesLotteryDialogName = FCOGuildLottery.getDialogName("resetGuildSalesLottery")
                df("dialogName: %s", tostring(resetGuildSalesLotteryDialogName))
                if resetGuildSalesLotteryDialogName ~= nil and not ZO_Dialogs_IsShowingDialog(resetGuildSalesLotteryDialogName) then
                    local data = {
                        title       = "Reset guild sales lottery",
                        question    = "Do you want to reset the currently\nactive guild sales lottery?",
                        callbackData = {
                            yes = function()
                                resetCurrentGuildSalesLotteryData(startingNewLottery, guildIndex, daysBefore)
                                if callbackYes ~= nil and type(callbackYes) == "function" then
                                    callbackYes(guildIndex, daysBefore)
                                end
                            end,
                            no  = function()
                                if callbackNo ~= nil and type(callbackNo) == "function" then
                                    callbackNo(guildIndex, daysBefore)
                                end
                            end
                        },
                    }
                    ZO_Dialogs_ShowDialog(resetGuildSalesLotteryDialogName, data, nil, nil)
                end
            else
                resetDataNow = true
            end
        else
            if resetDataNow == false and startingNewLottery == true then
                resetDataNow = true
            end
        end
    end
    if resetDataNow == true then
        df(">resetting data now - startingNewLottery: %s, index: %s, daysBefore: %s", tostring(startingNewLottery), tostring(guildIndex), tostring(daysBefore))
        resetCurrentGuildSalesLotteryData(startingNewLottery, guildIndex, daysBefore)
    end
end

--Build the ranks list and get number of members having sold something in the timeframe
function FCOGuildLottery.BuildGuildSalesMemberRank(guildId, daysBefore, startTime, endTime, uniqueIdentifier)
    df( "BuildGuildSalesMemberRank - guildId: %s, endTime: %s, daysBefore: %s, startTime: %s, uniqueId: %s", tostring(guildId), os.date("%c", endTime), tostring(daysBefore), os.date("%c", startTime) , tostring(uniqueIdentifier))
    --d( string.format("BuildGuildSalesMemberRank - guildId: %s, endTime: %s, daysBefore: %s, startTime: %s, uniqueId: %s", tostring(guildId), os.date("%c", endTime), tostring(daysBefore), os.date("%c", startTime) , tostring(uniqueIdentifier)))
    if guildId == nil or guildId == 0 then return end

    if checkIfPendingSellEventAndResetGuildSalesLottery(guildId) then return end

    local guildSalesMemberCount = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberCount
    if guildSalesMemberCount == nil or guildSalesMemberCount == 0 then
        guildSalesMemberCount = FCOGuildLottery.GetGuildSalesMemberCount(
                guildId,
                daysBefore,
                startTime,
                endTime,
                uniqueIdentifier
        )
    end
    df(">guildSalesMemberCount: " ..tostring(guildSalesMemberCount))
    --d(">guildSalesMemberCount: " ..tostring(guildSalesMemberCount))
    return guildSalesMemberCount
end

--Roll the dice for the Guild Saes Lottery. At first roll show a dialog to ask for the guildId and the timeframe to get
--the sales data for. Following throws of the dice won't ask again until you reset it via the slash command
--/
function FCOGuildLottery.RollTheDiceForGuildSalesLottery(noChatOutput)
    noChatOutput = noChatOutput or false
df( "RollTheDiceForGuildSalesLottery - noChatOutput: %s", tostring(noChatOutput) )
    local guildId
    local guildIndex

    --Build the unique identifier and set the other needed variables
    if not FCOGuildLottery.IsGuildSalesLotteryActive() then
        --Which guildIndex and Id should be used? And how many days backwards?
        -->All chosen via the slash command /gsl /guildsaleshistory or /dicegsl
        guildIndex = FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildIndex
        guildId    = FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId
        if (guildIndex == nil and guildId == nil) or FCOGuildLottery.currentlyUsedGuildSalesLotteryDaysBefore == nil then
            resetCurrentGuildSalesLotteryData(nil, nil, nil)
            return
        end
        if guildId == nil and guildIndex ~= nil then
            guildId = FCOGuildLottery.GetGuildId(guildIndex)
        elseif guildId ~= nil and guildIndex == nil then
            guildIndex = FCOGuildLottery.GetGuildIndexById(guildId)
        end
        if guildIndex == nil or guildId == nil  then
            resetCurrentGuildSalesLotteryData(nil, nil, nil)
            return
        end

        FCOGuildLottery.currentlyUsedGuildSalesLotteryTimestamp = GetTimeStamp()
        df(">START: New guild sales lottery initiated at \'%s\' >>>>>>>>>>>>>>>>>>>>", os.date("%c", FCOGuildLottery.currentlyUsedGuildSalesLotteryTimestamp))

        FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildIndex    = guildIndex
        FCOGuildLottery.currentlyUsedDiceRollGuildId                = guildId
        FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId       = guildId
        FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildName     = GetGuildName(guildId)

        --Update the LibHistoire data of the guild's sell history
        local uniqueIdentifier, timeStart, timeEnd = FCOGuildLottery.PrepareSellStatsOfGuild(guildId, FCOGuildLottery.currentlyUsedGuildSalesLotteryDaysBefore)
        FCOGuildLottery.currentlyUsedGuildSalesLotteryEndTime       = timeEnd
        FCOGuildLottery.currentlyUsedGuildSalesLotteryStartTime     = timeStart
        if not timeStart or not timeEnd then
            resetCurrentGuildSalesLotteryData()
            --showGuildEventsNoTraderWeekDeterminedMessage(dateStr)
            return
        end

        FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier = uniqueIdentifier

        FCOGuildLottery.currentlyUsedGuildSalesLotteryData             = {}
        FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank   = {}
        FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellCounts = {}
        FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellSums   = {}
        FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberCount   = 0

        FCOGuildLottery.currentlyUsedGuildSalesLotteryRolls             = {}
    else
        guildId     = FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId
        guildIndex  = FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildIndex
        df(">Use existing guild sales lottery id %s, \'%s\' >>>>>>>>>>>>>>>>>>>>", tostring(guildId), os.date("%c", FCOGuildLottery.currentlyUsedGuildSalesLotteryTimestamp))
    end

    --Set the dice roll type
    FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GUILD_SALES_LOTTERY

    local rolledData, countMembersAtRank
    if guildId ~= nil and guildId ~= 0 then
        countMembersAtRank = FCOGuildLottery.BuildGuildSalesMemberRank(
                guildId,
                FCOGuildLottery.currentlyUsedGuildSalesLotteryDaysBefore,
                FCOGuildLottery.currentlyUsedGuildSalesLotteryStartTime,
                FCOGuildLottery.currentlyUsedGuildSalesLotteryEndTime,
                FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier
        )
    end
    if countMembersAtRank ~= nil and countMembersAtRank > 0 then
        --Roll the dice with the number of guild sales members rank of that guildId
        rolledData = FCOGuildLottery.RollTheDice(countMembersAtRank, noChatOutput)
        if rolledData ~= nil and rolledData.timestamp ~= nil then
            FCOGuildLottery.diceRollGuildLotteryHistory[guildId] = FCOGuildLottery.diceRollGuildLotteryHistory[guildId] or {}
            local currentlyUsedGuildSalesLotteryUniqueIdentifier = FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier
            local currentlyUsedGuildSalesLotteryTimestamp = FCOGuildLottery.currentlyUsedGuildSalesLotteryTimestamp
            FCOGuildLottery.diceRollGuildLotteryHistory[guildId][currentlyUsedGuildSalesLotteryUniqueIdentifier] = FCOGuildLottery.diceRollGuildLotteryHistory[guildId][currentlyUsedGuildSalesLotteryUniqueIdentifier] or {}
            FCOGuildLottery.diceRollGuildLotteryHistory[guildId][currentlyUsedGuildSalesLotteryUniqueIdentifier][currentlyUsedGuildSalesLotteryTimestamp] = FCOGuildLottery.diceRollGuildLotteryHistory[guildId][currentlyUsedGuildSalesLotteryUniqueIdentifier][currentlyUsedGuildSalesLotteryTimestamp] or {}
            FCOGuildLottery.diceRollGuildLotteryHistory[guildId][currentlyUsedGuildSalesLotteryUniqueIdentifier][currentlyUsedGuildSalesLotteryTimestamp][rolledData.timestamp] = rolledData

            FCOGuildLottery.UI.RefreshWindowLists()
            FCOGuildLottery.UpdateMaxDiceSidesForGuildLottery(countMembersAtRank)
        end
    else
        resetCurrentGuildSalesLotteryData()
        showGuildEventsNoMemberCountMessage(guildId, guildIndex)
    end
end

function FCOGuildLottery.GetRolledGuildMemberInfo(guildId, diceSide, useGuildSalesHistory)
df( "GetRolledGuildMemberInfo-guildId: " ..tostring(guildId) .. ", diceSide: " .. tostring(diceSide) .. ", useGuildSalesHistory: " ..tostring(useGuildSalesHistory))
    if not guildId then return end
    local guildIndex = FCOGuildLottery.GetGuildIndexById(guildId)
    if not IsGuildIndexValid(guildIndex) then return end
    useGuildSalesHistory = useGuildSalesHistory or false
    local memberName, memberNote, rankIndex, playerStatus, secsSinceLogoff, soldSum
    if not useGuildSalesHistory then
        local maxGuildMembers = FCOGuildLottery.GetGuildMemberCount(guildIndex)
        if diceSide > maxGuildMembers then return end
        memberName, memberNote, rankIndex, playerStatus, secsSinceLogoff = GetGuildMemberInfo(guildId, diceSide)
    else
        local guildSalesMemberCount = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberCount
        if guildSalesMemberCount == nil or guildSalesMemberCount == 0 then
            guildSalesMemberCount = FCOGuildLottery.BuildGuildSalesMemberRank(
                    guildId,
                    FCOGuildLottery.currentlyUsedGuildSalesLotteryDaysBefore,
                    FCOGuildLottery.currentlyUsedGuildSalesLotteryStartTime,
                    FCOGuildLottery.currentlyUsedGuildSalesLotteryEndTime,
                    FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier
            )
        end
        --Nothing found?
        if guildSalesMemberCount == nil or guildSalesMemberCount == 0 then
            showGuildEventsNoMemberCountMessage(guildId, guildIndex)
            return
        end
        if diceSide ~= FCOGL_DICE_SIDES_NO_CHECK and diceSide > guildSalesMemberCount then return end
        if FCOGuildLottery.currentlyUsedGuildSalesLotteryData ~= nil and FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank ~= nil then
            local rankGuilSellData = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank[diceSide]
            if rankGuilSellData ~= nil then
                local memberRankName  = rankGuilSellData.memberName
                soldSum = rankGuilSellData.soldSum
                local guildMemberIndex = GetGuildMemberIndexFromDisplayName(guildId, memberRankName)
                if guildMemberIndex ~= nil and guildMemberIndex > 0 then
                   memberName, memberNote , rankIndex, playerStatus, secsSinceLogoff = GetGuildMemberInfo(guildId, guildMemberIndex)
                end
            else
                df("<<nothing found :-(")
            end
        else
df("<guild sell rank data missing!")
        end
    end
df("<<memberName: %s", tostring(memberName))
    return memberName, memberNote, rankIndex, playerStatus, secsSinceLogoff, guildIndex, soldSum
end

function FCOGuildLottery.NewGuildSalesLottery(guildIndex, daysBefore)
df("[FCOGuildLottery.NewGuildSalesLottery] - index: %s, daysBefore: %s", tostring(guildIndex), tostring(daysBefore))
    if FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier ~= nil then return end
    --Set the guildIndex and daysBefore to start a new guild sales lottery with function
    FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildIndex = guildIndex
    FCOGuildLottery.currentlyUsedGuildSalesLotteryDaysBefore = daysBefore
    FCOGuildLottery.RollTheDiceForGuildSalesLottery()
end

function FCOGuildLottery.GetGuildSalesLotteryStartDate()
    local daysBefore
    --Check the settings for the startdate timestamp:
    local guildLotteryStartDate = FCOGuildLottery.settingsVars.settings.guildLotteryDateStart
    if guildLotteryStartDate ~= nil then
        --Count the days difference between now and this date, and return the days difference value.
        --If below 1, then use 1
        daysBefore = diffInDays(guildLotteryStartDate, GetTimeStamp())
    else
        daysBefore = FCOGL_DEFAULT_GUILD_SELL_HISTORY_DAYS
    end
    return daysBefore
end

function FCOGuildLottery.StartNewGuildSalesLottery(guildIndex, daysBefore, dataWasResetAlready)
df("[FCOGuildLottery.StartNewGuildSalesLottery] - index: %s, daysBefore: %s, dataWasResetAlready: %s", tostring(guildIndex), tostring(daysBefore), tostring(dataWasResetAlready))
    if not IsGuildIndexValid(guildIndex) or daysBefore == nil then
        showNewGSLSlashCommandHelp((FCOGuildLottery.noGuildIndex ~= nil and guildIndex == FCOGuildLottery.noGuildIndex) or false)
        return
    end
    if checkAndShowNoTraderMessage(guildIndex) == true then
        return
    end

    dataWasResetAlready = dataWasResetAlready or false
    if not dataWasResetAlready then
        --Reset and show dialog asking before, if any guild sales lottery is already active
        FCOGuildLottery.ResetCurrentGuildSalesLotteryData(false, true, guildIndex, daysBefore, nil, nil)
    else
        FCOGuildLottery.NewGuildSalesLottery(guildIndex, daysBefore)
    end
end

function FCOGuildLottery.StopGuildSalesLottery()
    if not FCOGuildLottery.IsGuildSalesLotteryActive() then return end
    local callbackYes
    local guildIndex = FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildIndex
    if IsGuildIndexValid(guildIndex) then
        callbackYes = function() FCOGuildLottery.UI.resetGuildDropDownToGuild(guildIndex) end
    else
        callbackYes = function() FCOGuildLottery.UI.resetGuildDropDownToNone() end
    end
    FCOGuildLottery.ResetCurrentGuildSalesLotteryData(false, false, nil, nil,
        callbackYes, nil
    )
end

function FCOGuildLottery.ResetCurrentGenericGuildDiceThrowData()
    local rememberedDiceRollGuildName = FCOGuildLottery.rememberedCurrentUsedDiceRollGuildName
    FCOGuildLottery.currentlyUsedDiceRollGuildName  = rememberedDiceRollGuildName
    FCOGuildLottery.rememberedCurrentUsedDiceRollGuildName = nil

    local rememberedDiceRollGuildId = FCOGuildLottery.rememberedCurrentUsedDiceRollGuildId
    FCOGuildLottery.currentlyUsedDiceRollGuildId  = rememberedDiceRollGuildId
    FCOGuildLottery.rememberedCurrentUsedDiceRollGuildId = nil

    local rememberedDiceRollType = FCOGuildLottery.rememberedCurrentUsedDiceRollType
    FCOGuildLottery.currentlyUsedDiceRollType       = rememberedDiceRollType
    FCOGuildLottery.rememberedCurrentUsedDiceRollType = nil
df("ResetCurrentGenericGuildDiceThrowData - diceRollType %s, guildId %s", tostring(rememberedDiceRollType), tostring(rememberedDiceRollGuildId))

    --Update the currently used dice roll type as it could have been reset to "generic" via a slash command
    FCOGuildLottery.UpdateCurrentDiceRollType()
end

function FCOGuildLottery.RememberCurrentGenericGuildDiceThrowData()
    FCOGuildLottery.rememberedCurrentUsedDiceRollGuildName  = FCOGuildLottery.currentlyUsedDiceRollGuildName
    FCOGuildLottery.rememberedCurrentUsedDiceRollGuildId    = FCOGuildLottery.currentlyUsedDiceRollGuildId
    FCOGuildLottery.rememberedCurrentUsedDiceRollType       = FCOGuildLottery.currentlyUsedDiceRollType
df("RememberCurrentGenericGuildDiceThrowData - diceRollType %s, guildId %s", tostring(FCOGuildLottery.rememberedCurrentUsedDiceRollType), tostring(FCOGuildLottery.rememberedCurrentUsedDiceRollGuildId))
end


function FCOGuildLottery.RollTheDiceNormalForGuildMemberCheck(guildIndex, noChatOutput)
    noChatOutput = noChatOutput or false
df("[FCOGuildLottery.RollTheDiceNormalForGuildMemberCheck] - index: %s, noChatOutput: %s", tostring(guildIndex), tostring(noChatOutput))
    local function abortFunc()
        FCOGuildLottery.currentlyUsedDiceRollGuildName = nil
        FCOGuildLottery.currentlyUsedDiceRollGuildId = nil
        FCOGuildLottery.currentlyUsedDiceRollType =  FCOGL_DICE_ROLL_TYPE_GENERIC
        return
    end
    --Is currently any guild lottery active? As a normal guild dice roll would interrupt it we need to ask if we want to
    if FCOGuildLottery.IsGuildSalesLotteryActive() then
        --Show dialog and ask if we really want to! If yes is chosen: Try the dice throw again now, after resetting the current guild lottery
        FCOGuildLottery.ResetCurrentGuildSalesLotteryData(false, false, nil, nil, FCOGuildLottery.normalGuildMemeberDiceRollSlashCommand, nil)
        --Abort here now and let the dialog Yes callback function try again, or no do nothing
        return
    end
    if not IsGuildIndexValid(guildIndex) then
        return abortFunc()
    end
    local diceSidesGuild = FCOGuildLottery.GetGuildMemberCount(guildIndex)
    if not diceSidesGuild or diceSidesGuild == 0 then
        return abortFunc()
    end

    FCOGuildLottery.currentlyUsedDiceRollGuildName, FCOGuildLottery.currentlyUsedDiceRollGuildId = FCOGuildLottery.GetGuildName(guildIndex, noChatOutput, true)
    FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
    return diceSidesGuild
end

function FCOGuildLottery.RollTheDiceCheck(noChatOutput)
    noChatOutput = noChatOutput or false
    df( "------------[ RollTheDiceCheck - noChatOutput: %s ]------------ ", tostring(noChatOutput))
    if FCOGuildLottery.IsGuildSalesLotteryActive() then
        FCOGuildLottery.RollTheDiceForGuildSalesLottery(noChatOutput)
    else
        FCOGuildLottery.RollTheDiceWithDefaultSides(noChatOutput)
    end
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Slash Command functions
function FCOGuildLottery.parseSlashCommandArguments(args, firstArg)
    --Parse the arguments string
    local options = {}
    --local searchResult = {} --old: searchResult = { string.match(args, "^(%S*)%s*(.-)$") }
    for param in string.gmatch(args, "([^%s]+)%s*") do
        if (param ~= nil and param ~= "") then
            options[#options+1] = string.lower(param)
        end
    end
    --Should a dice be thrown= Chekc for the 2nd argument ONLY and validate as number
    if firstArg == "/dice" then
        if options[1] ~= nil then
            local intVal = tonumber(options[1])
            if type(intVal) == "number" then
                return intVal
            end
        else
            --Default dice sides = dice sides set in settings
            return FCOGuildLottery.settingsVars.settings.defaultDiceSides
        end

    elseif firstArg == "/newgsl" then
        --guildId
        local guildIndex, daysBefore
        guildIndex = options[1]
        if guildIndex ~= nil then
            local intVal = tonumber(guildIndex)
            if type(intVal) == "number" then
                guildIndex = intVal
                if not IsGuildIndexValid(guildIndex) then
                    guildIndex = nil
                end
            else
                guildIndex = nil
            end
        end
        daysBefore = options[2]
        if guildIndex ~= nil and daysBefore ~= nil then
            local intVal = tonumber(daysBefore)
            if type(intVal) == "number" then
                daysBefore = intVal
            end
        elseif guildIndex ~= nil and daysBefore == nil then
            daysBefore = FCOGuildLottery.GetGuildSalesLotteryStartDate()
        end
        if guildIndex ~= nil and daysBefore ~= nil then
            return guildIndex, daysBefore
        end
        return nil, nil
    end
end

--Start (if not started yet) or roll a dice for the current guild sales lottery, via slash command
function FCOGuildLottery.GuildSalesLotterySlashCommand(args)
    --Are we starting a new guild sales lottery with this "dice roll"?
    if not FCOGuildLottery.IsGuildSalesLotteryActive() then
        showNewGSLSlashCommandHelp()
    else
        --Just roll next dice
        FCOGuildLottery.RollTheDiceForGuildSalesLottery()
    end
end

--Start a new guild sales lottery, via slash command
function FCOGuildLottery.NewGuildSalesLotterySlashCommand(args)
    --FCOGuildLottery.ResetCurrentGuildSalesLotteryData(false, true)
    local guildIndex, daysBefore = FCOGuildLottery.parseSlashCommandArguments(args, "/newgsl")
--d("GuildIndex: " .. guildIndex .. ", daysBefore: " .. daysBefore)
    FCOGuildLottery.StartNewGuildSalesLottery(guildIndex, daysBefore, false)
end

--Show the last rolled chat output again
function FCOGuildLottery.GuildSalesLotteryLastRolledSlashCommand()
    if FCOGuildLottery.currentlyUsedGuildSalesLotteryLastRolledChatOutput == nil then return end
    dfa( FCOGuildLottery.currentlyUsedGuildSalesLotteryLastRolledChatOutput )
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Tooltip functions
function FCOGuildLottery.buildTooltip(tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceText2, zoStrFormatReplaceText3)
    local ttText = ""
    if zoStrFormatReplaceText1 ~= nil then
        if zoStrFormatReplaceText3 ~= nil then
            ttText = zo_strformat(tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceText2, zoStrFormatReplaceText3)
        elseif zoStrFormatReplaceText2 ~= nil then
            ttText = zo_strformat(tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceText2)
        else
            ttText = zo_strformat(tooltipText, zoStrFormatReplaceText1)
        end
    else
        ttText = tooltipText
    end
    return ttText
end

function FCOGuildLottery.ShowTooltip(ctrl, tooltipPosition, tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceTex2, zoStrFormatReplaceText3)
--d("[WL]ShowTooltip - ctrl: " ..tostring(ctrl:GetName()) .. ", text: " .. tostring(tooltipText))
    if ctrl == nil or (ctrl.IsMouseEnabled and not ctrl:IsMouseEnabled()) or tooltipText == nil or tooltipText == "" then return false end
	local tooltipPositions = {
        [TOP]       = true,
        [RIGHT]     = true,
        [BOTTOM]    = true,
        [LEFT]      = true,
    }
    if not tooltipPositions[tooltipPosition] then
        tooltipPosition = LEFT
	end
	local ttText = FCOGuildLottery.buildTooltip(tooltipText, zoStrFormatReplaceText1, zoStrFormatReplaceTex2, zoStrFormatReplaceText3)
    ZO_Tooltips_ShowTextTooltip(ctrl, tooltipPosition, ttText)
end

function FCOGuildLottery.HideTooltip()
    ZO_Tooltips_HideTextTooltip()
end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Date & time functions
function FCOGuildLottery.getDateTimeFormatted(dateTimeStamp)
    local dateTimeStr = ""
    if dateTimeStamp ~= nil then
        --Format the timestamp to the output version again
        if os and os.date then
            local settings = FCOGuildLottery.settingsVars.settings
            if settings.useCustomDateFormat ~= nil and settings.useCustomDateFormat ~= "" then
                dateTimeStr = os.date(settings.useCustomDateFormat, dateTimeStamp)
            else
                if settings.use24hFormat then
                    dateTimeStr = os.date("%d.%m.%y, %H:%M:%S", dateTimeStamp)
                else
                    dateTimeStr = os.date("%y-%m-%d, %I:%M:%S %p", dateTimeStamp)
                end

            end
        end
    end
    return dateTimeStr
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Character & account functions
local function buildCharacterData(keyIsCharName)
    keyIsCharName = keyIsCharName or false
    local charactersOfAccount
    --Check all the characters of the account
    for i = 1, GetNumCharacters() do
        local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
        local charName = ZO_CachedStrFormat(SI_UNIT_NAME, name)
        if characterId ~= nil and charName ~= "" then
            if charactersOfAccount == nil then charactersOfAccount = {} end
            if keyIsCharName == true then
                charactersOfAccount[charName]   = characterId
            else
                charactersOfAccount[characterId] = charName
            end
        end
    end
    return charactersOfAccount
end

function FCOGuildLottery.GetCharacterName(characterId)
    if FCOGuildLottery.characterData == nil then
        FCOGuildLottery.characterData = buildCharacterData(false)
    end
    local characterName = FCOGuildLottery.characterData[characterId]
    return characterName
end