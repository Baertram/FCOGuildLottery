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

--UI variables
FCOGuildLottery.UI = FCOGuildLottery.UI or {}
local fcoglUI = FCOGuildLottery.UI
local fcoglUIwindow
local fcoglUIDiceHistoryWindow

fcoglUI.CurrentState    = FCOGL_TAB_STATE_LOADING
fcoglUI.CurrentTab      = FCOGL_TAB_GUILDSALESLOTTERY
fcoglUI.comingFromSortScrollListSetupFunction = false
fcoglUI.sortType = 1
fcoglUI.selectedGuildDataBeforeUpdate = nil
fcoglUI.searchBoxLastSelected = {}

local buttonNewStateVal = {
    [true]  = 0,
    [false] = 1,
}

local SCROLLLIST_DATATYPE_GUILDSALESRANKING     = fcoglUI.SCROLLLIST_DATATYPE_GUILDSALESRANKING
local SCROLLLIST_DATATYPE_ROLLED_DICE_HISTORY   = fcoglUI.SCROLLLIST_DATATYPE_ROLLED_DICE_HISTORY

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
local function isGuildSalesLotteryActive()
    return (FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier ~= nil and
            FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId ~= nil) or false
end

local function updateMaxDefaultDiceSides()
    local defaultSidesOfDice = FCOGuildLottery.settingsVars.settings.defaultDiceSides
    fcoglUIwindow.editBoxDiceSides:SetText(tostring(defaultSidesOfDice))
end


--FCOGuildLottery window - The UI
FCOGuildLottery.UI.windowClass = ZO_SortFilterList:Subclass()
local fcoglWindowClass = FCOGuildLottery.UI.windowClass

local function setWindowPosition(windowFrame)
    if not windowFrame or (windowFrame and not windowFrame.SetAnchor) then return end
    local settings = FCOGuildLottery.settingsVars.settings
    local uiWindowSettings = settings.UIwindow
    local width, height = uiWindowSettings.width, uiWindowSettings.height

    local bg = windowFrame:GetNamedChild("BG")
    bg:ClearAnchors()
    windowFrame:ClearAnchors()
    windowFrame:SetDimensions(width, height)
    windowFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, uiWindowSettings.left, uiWindowSettings.top)
    bg:SetAnchorFill(windowFrame)
end


--[[
--Update the title of a scene's fragment with a new text
local function updateSceneFragmentTitle(sceneName, fragment, childName, newTitle)
    childName = childName or "Label"
    if sceneName == nil or fragment == nil or newTitle == nil then return false end
    local sm = SCENE_MANAGER
    if not sm then return false end
    local currentScene = sm.currentScene
    local currentSceneName = currentScene.name
    if not currentScene or not currentSceneName or not currentSceneName == sceneName or not currentScene.fragments then return end
    for _, fragmentInCurrentScene in ipairs(currentScene.fragments) do
        if fragmentInCurrentScene == fragment then
            if fragmentInCurrentScene then
                local fragmentCtrl = fragmentInCurrentScene.control
                if fragmentCtrl then
                    local fragmentCtrlChildLabel = fragmentCtrl:GetNamedChild(childName)
                    if fragmentCtrlChildLabel and fragmentCtrlChildLabel.SetText then
                        fragmentCtrlChildLabel:SetText(newTitle)
                    end
                end
            end
            return true
        end
    end
    return false
end
]]


function fcoglWindowClass:New(control, listType)
	local list = ZO_SortFilterList.New(self, control)
	list.frame = control
    list.listType = listType
	list:Setup(listType)
	return list
end

function fcoglWindowClass:Setup(listType)
    --d("[fcoglWindow:Setup]")
    fcoglUI.comingFromSortScrollListSetupFunction = true
    fcoglUI.CurrentTab = FCOGL_TAB_GUILDSALESLOTTERY

    self.listType = listType

    --The guild sales lottery list
    if listType == FCOGL_LISTTYPE_GUILD_SALES_LOTTERY then
        --Scroll UI
        ZO_ScrollList_AddDataType(self.list, fcoglUI.SCROLLLIST_DATATYPE_GUILDSALESRANKING, "FCOGLRowGuildSales", 30, function(control, data)
            self:SetupItemRow(control, data, self.listType)
        end)
        ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
        self:SetAlternateRowBackgrounds(true)

        self.masterList = { }

        --Build the sortkeys depending on the settings
        --self:BuildSortKeys() --> Will be called internally in "self.sortHeaderGroup:SelectAndResetSortForKey"
        --Default values
        --self.currentSortKey, self.currentSortOrder = fcoglUI.loadSortGroupHeader(fcoglUI.CurrentTab, self.listType)
        --self.sortHeaderGroup:SelectAndResetSortForKey(self.currentSortKey) -- Will call "SortScrollList" internally
        local currentSortKey, currentSortOrder = fcoglUI.loadSortGroupHeader(fcoglUI.CurrentTab, self.listType)
        df(">Setup List 1 BEFORE - self.currentSortKey: %s, self.currentSortOrder: %s, svCurrentSortKey: %s, svCurrentSortOrder: %s", tostring(self.currentSortKey), tostring(self.currentSortOrder), tostring(currentSortKey), tostring(currentSortOrder))
        self:resetSortGroupHeader(fcoglUI.CurrentTab, self.listType)
        df(">>Setup List 1 AFTER self.currentSortOrder: %s", tostring(self.currentSortOrder))
        --The sort function
        self.sortFunction = function( listEntry1, listEntry2 )
            if     self.currentSortKey == nil or self.sortKeys[self.currentSortKey] == nil
                    or listEntry1.data == nil or listEntry1.data[self.currentSortKey] == nil
                    or listEntry2.data == nil or listEntry2.data[self.currentSortKey] == nil then
                return nil
            end
            return(ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, self.sortKeys, self.currentSortOrder))
        end
        --Search
        self.searchDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("SearchDrop"))
        self:initializeSearchDropdown(FCOGL_TAB_GUILDSALESLOTTERY, self.listType, "name")
        --Guilds
        self.guildsDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("GuildsDrop"))
        self:initializeSearchDropdown(FCOGL_TAB_GUILDSALESLOTTERY, self.listType, "guilds")

        --Search box and search functions
        self.searchBox = self.frame:GetNamedChild("SearchBox")
        self.searchBox:SetHandler("OnTextChanged", function() self:RefreshFilters() end)
        self.searchBox:SetHandler("OnMouseUp", function(ctrl, mouseButton, upInside)
            --[[
            if mouseButton == MOUSE_BUTTON_INDEX_RIGHT and upInside then
                self:OnSearchEditBoxContextMenu(self.searchBox)
            end
            ]]
        end)
        self.search = ZO_StringSearch:New()
        self.search:AddProcessor(fcoglUI.sortType, function(stringSearch, data, searchTerm, cache)
            return(self:ProcessItemEntry(stringSearch, data, searchTerm, cache))
        end)

        --Sort headers
        self.headers        = self.frame:GetNamedChild("Headers")
        self.headerRank     = self.headers:GetNamedChild("Rank")
        self.headerName     = self.headers:GetNamedChild("Name")
        --self.headerItem     = self.headers:GetNamedChild("Item")
        self.headerPrice    = self.headers:GetNamedChild("Price")
        self.headerTax      = self.headers:GetNamedChild("Tax")
        self.headerAmount   = self.headers:GetNamedChild("Amount")
        self.headerInfo     = self.headers:GetNamedChild("Info")

        self.editBoxDiceSides = self.frame:GetNamedChild("EditDiceSidesBox")
        self.editBoxDiceSides:SetTextType(TEXT_TYPE_NUMERIC_UNSIGNED_INT)
        FCOGuildLottery.prevVars.doNotRunOnTextChanged = true
        self.editBoxDiceSides:SetText(tostring(FCOGuildLottery.settingsVars.settings.defaultDiceSides))
        FCOGuildLottery.prevVars.doNotRunOnTextChanged = false

        --Add the FCOGL scene
    --fcoglUI.scene = ZO_Scene:New(fcoglUI.SCENE_NAME, SCENE_MANAGER)
    --fcoglUI.scene:AddFragment(ZO_SetTitleFragment:New(FCOGL_TITLE))
    --fcoglUI.scene:AddFragment(ZO_FadeSceneFragment:New(FCOGLFrame))
    --fcoglUI.scene:AddFragment(TITLE_FRAGMENT)
    --fcoglUI.scene:AddFragment(RIGHT_BG_FRAGMENT)
    --fcoglUI.scene:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
    --fcoglUI.scene:AddFragment(CODEX_WINDOW_SOUNDS)
    --fcoglUI.scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
    --fcoglUI.scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)

    --Build initial masterlist via self:BuildMasterList()
    --d("[fcoglUI.Setup] RefreshData > BuildMasterList ???")

    --The rolled dice history list
    elseif listType == FCOGL_LISTTYPE_ROLLED_DICE_HISTORY then

        --Scroll UI
        ZO_ScrollList_AddDataType(self.list, fcoglUI.SCROLLLIST_DATATYPE_ROLLED_DICE_HISTORY, "FCOGLRowDiceHistory", 30, function(control, data)
            self:SetupItemRow(control, data, self.listType)
        end)
        ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
        self:SetAlternateRowBackgrounds(true)

        self.masterList = { }

        --Build the sortkeys depending on the settings
        --self:BuildSortKeys() --> Will be called internally in "self.sortHeaderGroup:SelectAndResetSortForKey"
        --self.currentSortKey, self.currentSortOrder = fcoglUI.loadSortGroupHeader(fcoglUI.CurrentTab, self.listType)
        --self.sortHeaderGroup:SelectAndResetSortForKey(self.currentSortKey) -- Will call "SortScrollList" internally
        self:resetSortGroupHeader(fcoglUI.CurrentTab, self.listType)
        df(">Setup List 2 - self.currentSortOrder: %s", tostring(self.currentSortOrder))
        --The sort function
        self.sortFunction = function( listEntry1, listEntry2 )
            if     self.currentSortKey == nil or self.sortKeys[self.currentSortKey] == nil
                    or listEntry1.data == nil or listEntry1.data[self.currentSortKey] == nil
                    or listEntry2.data == nil or listEntry2.data[self.currentSortKey] == nil then
                return nil
            end
            return(ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, self.sortKeys, self.currentSortOrder))
        end
        --Search
        self.searchDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("SearchDrop"))
        self.initializeSearchDropdown(self, FCOGL_TAB_GUILDSALESLOTTERY, self.listType, "name")

        --Search box and search functions
        self.searchBox = self.frame:GetNamedChild("SearchBox")
        self.searchBox:SetHandler("OnTextChanged", function() self:RefreshFilters() end)
        self.searchBox:SetHandler("OnMouseUp", function(ctrl, mouseButton, upInside)
            --[[
            if mouseButton == MOUSE_BUTTON_INDEX_RIGHT and upInside then
                self:OnSearchEditBoxContextMenu(self.searchBox)
            end
            ]]
        end)
        self.search = ZO_StringSearch:New()
        self.search:AddProcessor(fcoglUI.sortType, function(stringSearch, data, searchTerm, cache)
            return(self:ProcessItemEntry(stringSearch, data, searchTerm, cache))
        end)

        --Sort headers
        --Dice history headers
        self.headers        = self.frame:GetNamedChild("Headers")
        self.headerNo       = self.headers:GetNamedChild("No")
        self.headerName     = self.headers:GetNamedChild("Name")
        self.headerDate     = self.headers:GetNamedChild("DateTime")
        self.headerRoll     = self.headers:GetNamedChild("Roll")

    end

    fcoglUI.enableSaveSortGroupHeaders(self.headers)

    --self.headers:SetHidden(true)
    --self.list = self.frame:GetNamedChild("List")
    --self.list:SetHidden(true)

    --[[
        --self:RefreshData() will run:
        -->self:BuildMasterList()
        -->self:FilterScrollList()
        -->self:SortScrollList()
        -->self:CommitScrollList()
    ]]
    self:RefreshData()
end

function fcoglWindowClass:GetListType()
--d("GetListType - listType: " ..tostring(self.listType))
    return self.listType
end

function fcoglWindowClass:BuildMasterList(calledFromFilterFunction)
    calledFromFilterFunction = calledFromFilterFunction or false
    local listType = self:GetListType()
    local guildSalesLotteryActive = isGuildSalesLotteryActive()

    df("list:BuildMasterList-calledFromFilterFunction: %s, currentTab: %s, listType: %s, guildLotteryActive: %s", tostring(calledFromFilterFunction), tostring(fcoglUI.CurrentTab), tostring(listType), tostring(guildSalesLotteryActive))
    if listType == nil then return end

    if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
        --Guild sales lottery is active?


        if listType == FCOGL_LISTTYPE_GUILD_SALES_LOTTERY then
            if guildSalesLotteryActive == true then
                self.masterList = {}

                local rankingData = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank
                if rankingData == nil or #rankingData == 0 then return false end
                for i = 1, #rankingData do
                    local item = rankingData[i]
                    table.insert(self.masterList, self:CreateGuildSalesRankingEntry(item))
                end
                --self:updateSortHeaderAnchorsAndPositions(fcoglUI.CurrentTab, settings.maxNameColumnWidth, 32)
            end
        end

        --Dice history is shown?
        if listType == FCOGL_LISTTYPE_ROLLED_DICE_HISTORY then
            self.masterList = {}

            local tableWithLastDiceThrows
            if guildSalesLotteryActive == true then
                tableWithLastDiceThrows = FCOGuildLottery.diceRollGuildLotteryHistory[FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId][FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier]
            else
                --No guild sales lottery, just normal dice throws
                tableWithLastDiceThrows = FCOGuildLottery.diceRollHistory
            end
            if tableWithLastDiceThrows == nil or NonContiguousCount(tableWithLastDiceThrows) == 0 then return false end
            local helperList = {}
            for _, diceThrowData in pairs(tableWithLastDiceThrows) do
                table.insert(helperList, diceThrowData)
            end
            table.sort(helperList, function(a, b) return a.timestamp < b.timestamp end)

            for _, diceThrowDataSorted in ipairs(helperList) do
                diceThrowDataSorted.no = #self.masterList + 1
                table.insert(self.masterList, self:CreateDiceThrowHistoryEntry(diceThrowDataSorted))
            end
        end
    end
end

--Setup the data of each row which gets added to the ZO_SortFilterList
function fcoglWindowClass:SetupItemRow(control, data, listType)
--df("SetupItemRow - listType: %s,comingFromSortScrollListSetupFunction: %s", tostring(listType), tostring(fcoglUI.comingFromSortScrollListSetupFunction))
    --if fcoglUI.comingFromSortScrollListSetupFunction then return end

    if listType == FCOGL_LISTTYPE_GUILD_SALES_LOTTERY then
        --local clientLang = fcoglUI.clientLang or fcoglUI.fallbackSetLang
        control.data = data
        --local updateSortHeaderDimensionsAndAnchors = false
        local rankColumn = control:GetNamedChild("Rank")
        local nameColumn = control:GetNamedChild("Name")
        local priceColumn = control:GetNamedChild("Price")
        local taxColumn = control:GetNamedChild("Tax")
        --local dateColumn = control:GetNamedChild("DateTime")
        local amountColumn = control:GetNamedChild("Amount")
        local infoColumn = control:GetNamedChild("Info")
        ------------------------------------------------------------------------------------------------------------------------
        if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
            --local dateTimeStamp = data.timestamp
            --local dateTimeStr = fcoglUI.getDateTimeFormatted(dateTimeStamp)
            --dateColumn:ClearAnchors()
            --dateColumn:SetAnchor(LEFT, control, nil, 0, 0)
            --dateColumn:SetText(dateTimeStr)
            --dateColumn:SetHidden(false)
            rankColumn:SetHidden(false)
            rankColumn:ClearAnchors()
            rankColumn:SetAnchor(LEFT, control, nil, 0, 0)
            rankColumn:SetText(data.rank)
            rankColumn:SetMouseEnabled(true)
            nameColumn:ClearAnchors()
            nameColumn.normalColor = ZO_DEFAULT_TEXT
            if not data.columnWidth then data.columnWidth = 200 end
            nameColumn:SetDimensions(data.columnWidth, 30)
            nameColumn:SetText(data.name)
            nameColumn:SetAnchor(LEFT, rankColumn, RIGHT, 0, 0)
            nameColumn:SetText(data.name)
            nameColumn:SetHidden(false)
            nameColumn:SetMouseEnabled(true)
            priceColumn:SetHidden(false)
            priceColumn:ClearAnchors()
            priceColumn:SetAnchor(LEFT, nameColumn, RIGHT, 0, 0)
            priceColumn:SetText(data.price)
            priceColumn:SetMouseEnabled(true)
            taxColumn:SetHidden(false)
            taxColumn:ClearAnchors()
            taxColumn:SetAnchor(LEFT, priceColumn, RIGHT, 0, 0)
            taxColumn:SetText(data.tax)
            taxColumn:SetMouseEnabled(true)
            amountColumn:SetHidden(false)
            amountColumn:ClearAnchors()
            amountColumn:SetAnchor(LEFT, taxColumn, RIGHT, 0, 0)
            amountColumn:SetText(data.amount)
            amountColumn:SetMouseEnabled(true)
            infoColumn:SetHidden(false)
            infoColumn:ClearAnchors()
            infoColumn:SetAnchor(LEFT, amountColumn, RIGHT, 0, 0)
            infoColumn:SetAnchor(RIGHT, control, RIGHT, 0, 0)
            infoColumn:SetText(data.info)
            infoColumn:SetMouseEnabled(true)
        end


    elseif listType == FCOGL_LISTTYPE_ROLLED_DICE_HISTORY then
        --local clientLang = fcoglUI.clientLang or fcoglUI.fallbackSetLang
        control.data = data

        --local updateSortHeaderDimensionsAndAnchors = false
        local noColumn   = control:GetNamedChild("No")
        local dateColumn = control:GetNamedChild("DateTime")
        local nameColumn = control:GetNamedChild("Name")
        local rollColumn = control:GetNamedChild("Roll")
        ------------------------------------------------------------------------------------------------------------------------
        noColumn:ClearAnchors()
        noColumn:SetAnchor(LEFT, control, nil, 0, 0)
        noColumn:SetText(data.no)
        noColumn:SetHidden(false)
        noColumn:SetMouseEnabled(true)
        local dateTimeStamp = data.timestamp
        local dateTimeStr = FCOGuildLottery.getDateTimeFormatted(dateTimeStamp)
        dateColumn:ClearAnchors()
        dateColumn:SetAnchor(LEFT, noColumn, RIGHT, 0, 0)
        dateColumn:SetText(dateTimeStr)
        dateColumn:SetHidden(false)
        dateColumn:SetMouseEnabled(true)
        nameColumn:ClearAnchors()
        nameColumn.normalColor = ZO_DEFAULT_TEXT
        if not data.columnWidth then data.columnWidth = 200 end
        nameColumn:SetDimensions(data.columnWidth, 30)
        nameColumn:SetAnchor(LEFT, dateColumn, RIGHT, 0, 0)
        nameColumn:SetText(data.name)
        nameColumn:SetHidden(false)
        nameColumn:SetMouseEnabled(true)
        rollColumn:ClearAnchors()
        rollColumn:SetAnchor(LEFT, nameColumn, RIGHT, 0, 0)
        rollColumn:SetAnchor(RIGHT, control, RIGHT, 0, 0)
        rollColumn:SetText(data.roll)
        rollColumn:SetHidden(false)
        rollColumn:SetMouseEnabled(true)
    end

    --Set the row to the list now
    ZO_SortFilterList.SetupRow(self, control, data)
end

function fcoglWindowClass:FilterScrollList()
    local listType = self:GetListType()
    if not listType then return end
    df("list:FilterScrollList-currentTab: %s, listType: %s", tostring(fcoglUI.CurrentTab), tostring(listType))

    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    --Get the search method chosen at the search dropdown
    --self.searchType = 1
    self.searchType = self.searchDrop:GetSelectedItemData().id
    --Check the search text
    local searchInput = self.searchBox:GetText()

    local function checkIfMasterListRebuildNeeded(selfVar)
        --If not coming from setup function
        if not fcoglUI.comingFromSortScrollListSetupFunction then
            --d("--->>>checkIfMasterListRebuildNeeded: true")
            selfVar:BuildMasterList(true)
        end
    end
    ------------------------------------------------------------------------------------------------------------------------
    --Rebuild the masterlist so the total list and counts are correct!
    --checkIfMasterListRebuildNeeded(self)
    if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
        if listType == FCOGL_LISTTYPE_GUILD_SALES_LOTTERY then
            for i = 1, #self.masterList do
                --Get the data of each set item
                local data = self.masterList[i]
                --Search for text/set bonuses
                if searchInput == "" or self:CheckForMatch(data, searchInput) then
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(fcoglUI.SCROLLLIST_DATATYPE_GUILDSALESRANKING, data))
                end
            end

        elseif listType == FCOGL_LISTTYPE_ROLLED_DICE_HISTORY then

            for i = 1, #self.masterList do
                --Get the data of each set item
                local data = self.masterList[i]
                --Search for text/set bonuses
                if searchInput == "" or self:CheckForMatch(data, searchInput) then
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(fcoglUI.SCROLLLIST_DATATYPE_ROLLED_DICE_HISTORY, data))
                end
            end
        end

    end
    ------------------------------------------------------------------------------------------------------------------------
    --Update the counter
    self:UpdateCounter(scrollData)
end

function fcoglWindowClass:UpdateCounter(scrollData)
    --Update the counter (found by search/total) at the bottom right of the scroll list
    local listCountAndTotal = ""
    if self.masterList == nil or (self.masterList ~= nil and #self.masterList == 0) then
        listCountAndTotal = "0 / 0"
    else
        listCountAndTotal = string.format("%d / %d", #scrollData, #self.masterList)
    end
    self.frame:GetNamedChild("Counter"):SetText(listCountAndTotal)
end

function fcoglWindowClass:BuildSortKeys()
    local listType = self:GetListType()
    if not listType then return end
    df("list:BuildSortKeys-currentTab: %s, listType: %s", tostring(fcoglUI.CurrentTab), tostring(listType))

    if fcoglUI.sortKeys ~= nil and type(fcoglUI.sortKeys) == "table" then
        self.sortKeys = fcoglUI.sortKeys
    else
        --Get the tiebraker for the 2nd sort after the selected column
        self.sortKeys = {
           -- ["rank"]               = { isId64          = true, isNumeric = true, tiebreaker = "name"  },
            ["rank"]               = { isNumeric = true,        tiebreaker = "name"  },
            ["name"]               = { caseInsensitive = true                       },
            ["price"]              = { caseInsensitive = true,  tiebreaker = "name"  },
            ["tax"]                = { caseInsensitive = true,  tiebreaker = "name"  },
            ["amount"]             = { caseInsensitive = true,  tiebreaker = "name"  },
            ["info"]               = { caseInsensitive = true,  tiebreaker = "name"  },

            ["no"]                  = { isNumeric = true,       tiebreaker = "name"  },
            ["timestamp"]           = { isNumeric = true,       tiebreaker = "name"  },
            ["roll"]                = { isNumeric = true,       tiebreaker = "name"  },
        }
    end
end

function fcoglWindowClass:SortScrollList( )
    local listType = self:GetListType()
    if not listType then return end
    df("list:SortScrollList-currentTab: %s, listType: %s", tostring(fcoglUI.CurrentTab), tostring(listType))

    --Build the sortkeys depending on the settings
    self:BuildSortKeys()
    --Get the current sort header's key and direction
    self.currentSortKey = self.sortHeaderGroup:GetCurrentSortKey()
    self.currentSortOrder = self.sortHeaderGroup:GetSortDirection()
d("> sortKey: " .. tostring(self.currentSortKey) .. ", sortOrder: " ..tostring(self.currentSortOrder))
	if (self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
        --If not coming from setup function
        --if fcoglUI.comingFromSortScrollListSetupFunction then return end
        --Update the scroll list and re-sort it -> Calls "SetupItemRow" internally!
		local scrollData = ZO_ScrollList_GetDataList(self.list)
        if scrollData and #scrollData > 0 then
            table.sort(scrollData, self.sortFunction)
            self:RefreshVisible()
        end
	end
end

------------------------------------------------
--- Search/Filter Functions
------------------------------------------------
function fcoglWindowClass:OrderedSearch(haystack, needles )
	-- A search for "spell damage" should match "Spell and Weapon Damage" but
	-- not "damage from enemy spells", so search term order must be considered
	haystack = haystack:lower()
	needles = needles:lower()
	local i = 0
	for needle in needles:gmatch("%S+") do
		i = haystack:find(needle, i + 1, true)
		if (not i) then return(false) end
	end
	return(true)
end

function fcoglWindowClass:SearchByCriteria(data, searchInput, searchType)
    if data == nil or searchInput == nil or searchInput == ""  or searchType == nil then return nil end
    local listType = self:GetListType()
    if not listType then return end

    local searchValueType = type(searchInput)
    local searchInputLower
    local searchValueIsString = false
    local searchValueIsNumber = false
    local searchInputNumber = tonumber(searchInput)
    if searchInputNumber ~= nil then
        searchValueType = type(searchInputNumber)
        if searchValueType == "number" then
            searchValueIsNumber = true
        end
    else
        if searchValueType == "string" then
            searchValueIsString = true
            searchInputLower = searchInput:lower()
        end
    end



--[[
    data["name"]
    data["rank"]
    data["amount"]
    data["price"]
    data["tax"]
    data["info"]
]]
    return false
end

function fcoglWindowClass:CheckForMatch(data, searchInput )
    local searchType = self.searchType
    if searchType ~= nil then
        local listType = self:GetListType()
        if not listType then return end

        --Search by name
        if searchType == FCOGL_SEARCH_TYPE_NAME then
            local isMatch = false
            local searchInputNumber = tonumber(searchInput)
            if searchInputNumber ~= nil then
                local searchValueType = type(searchInputNumber)
                if searchValueType == "number" then
                    isMatch = searchInputNumber == data.rank or false
                end
            else
                isMatch = self.search:IsMatch(searchInput, data)
            end
            return isMatch
        else
            return(self:SearchByCriteria(data, searchInput, searchType))
        end
    end
	return(false)
end

function fcoglWindowClass:ProcessItemEntry(stringSearch, data, searchTerm )
--d("[WLW.ProcessItemEntry] stringSearch: " ..tostring(stringSearch) .. ", setName: " .. tostring(data.name:lower()) .. ", searchTerm: " .. tostring(searchTerm))
	if ( data.name and zo_plainstrfind(data.name:lower(), searchTerm) ) then
		return(true)
	end
	return(false)
end

------------------------------------------------
--- FCOGL Search Dropdown
------------------------------------------------
function fcoglWindowClass:SearchNow(searchValue, resetSearchTextBox)
--d("[fcoglWindow:SearchNow]searchValue: " ..tostring(searchValue))
    resetSearchTextBox = resetSearchTextBox or false
    if not searchValue then return end
    local searchBox = self.searchBox
    if not searchBox then return end
    searchBox:Clear()
    if searchValue == "" and resetSearchTextBox then return end
    searchBox:SetText(searchValue) --Will automatically raise self:RefreshFilters() as OnTextChanged event fires
end


------------------------------------------------
--- Combo Box Initializers
------------------------------------------------
function fcoglWindowClass:initializeSearchDropdown(currentTab, currentListType, searchBoxType)
    if self == nil then return false end
    currentTab = currentTab or fcoglUI.CurrentTab or FCOGL_TAB_GUILDSALESLOTTERY
    currentListType = currentListType or self:GetListType()
    searchBoxType = searchBoxType or "name"
    local currentTab2SearchDropValues = {
        [FCOGL_TAB_GUILDSALESLOTTERY]   = {
            [FCOGL_LISTTYPE_GUILD_SALES_LOTTERY] = {
                ["name"] = {dropdown=self.searchDrop,  prefix=FCOGL_SEARCHDROP_PREFIX,  entryCount=FCOGL_SEARCH_TYPE_ITERATION_END,
                            exclude = {
                                [FCOGL_SEARCH_TYPE_NAME]     = false,
                            }, --exclude the search entries from the set search
                },
                ["guilds"] = {dropdown=self.guildsDrop,  prefix=FCOGL_GUILDSDROP_PREFIX,  entryCount=#FCOGuildLottery.guildsData + 1, --5 guilds + 1 non-guild entry
                              exclude = {
                                  [FCOGL_SEARCH_TYPE_NAME]     = false,
                              }, --exclude the search entries from the set search
                },
            },
            [FCOGL_LISTTYPE_ROLLED_DICE_HISTORY] = {
                ["name"] = {dropdown=self.searchDrop,  prefix=FCOGL_SEARCHDROP_PREFIX,  entryCount=FCOGL_SEARCH_TYPE_ITERATION_END,
                            exclude = {
                                [FCOGL_SEARCH_TYPE_NAME]     = false,
                            }, --exclude the search entries from the set search
                },
            },
        },
    }
    local searchDropAtTab = currentTab2SearchDropValues[currentTab] and currentTab2SearchDropValues[currentTab][currentListType]
    local searchDropData = searchDropAtTab[searchBoxType]
    if searchDropData == nil then return false end
    --d(">searchDropData: " .. tostring(searchDropData.dropdown) ..", " ..tostring(searchDropData.prefix) .. ", " .. tostring(searchDropData.entryCount))
    self:InitializeComboBox(searchDropData.dropdown, searchDropData.prefix, searchDropData.entryCount, searchDropData.exclude, searchBoxType )
end

function fcoglUI.SelectLastDropdownEntry(searchBoxType, lastIndex, callCallback)
    callCallback = callCallback or false
    df("SelectLastDropdownEntry - lastIndex: %s, searchBoxType: %s, callCallback: %s", tostring(lastIndex), tostring(searchBoxType), tostring(callCallback))
    if searchBoxType == nil or lastIndex == nil or lastIndex <= 0 then return end
    local comboBox
    if searchBoxType == "guilds" then
        local guildsDrop = fcoglUIwindow.guildsDrop
        if guildsDrop == nil then return end
        comboBox = guildsDrop

    elseif searchBoxType == "name" then
        local searchDrop = fcoglUIwindow.searchDrop
        if searchDrop == nil then return end
        comboBox = searchDrop
    end

    if not comboBox or comboBox and not comboBox.SelectItemByIndex then return end
    local callItemEntryCallback = ZO_COMBOBOX_UPDATE_NOW
    if not callCallback then
        callItemEntryCallback = ZO_COMBOBOX_SUPPRESS_UPDATE
    end
    comboBox:SelectItemByIndex(lastIndex, callItemEntryCallback)
end

local function abortUpdateNow(p_searchBoxType, p_lastIndex)
    df(">abortUpdateNow - lastIndex: %s, searchBoxType: %s", tostring(p_lastIndex), tostring(p_searchBoxType))
    --Select the before selected dropdown entry but without calling the callback
    fcoglUI.SelectLastDropdownEntry(p_searchBoxType, p_lastIndex, false)
end

function fcoglWindowClass:InitializeComboBox(control, prefix, max, exclude, searchBoxType )
    local comboBoxOwner = self
    local isGuildsCB = ((prefix == FCOGL_GUILDSDROP_PREFIX) or searchBoxType == "guilds") or false
    local isNameSearchCB = ((prefix == FCOGL_SEARCHDROP_PREFIX) or searchBoxType == "name") or false
df("[fcoglWindowClass:InitializeComboBox]isGuildsCB: " .. tostring(isGuildsCB) .. ", isNameSearchCB: " .. tostring(isNameSearchCB) .. ", prefix: " .. tostring(prefix) ..", max: " .. tostring(max))
    control:SetSortsItems(false)
    control:ClearItems()

    local entryCallbackNoGuild = function( _, _, entry, _ ) --comboBox, entryText, entry )
        local function updateEntryNowNoGuild(guildIndex, daysBefore)
d(">UpdateEntryNow_NoGuild")
            df(">>UpdateEntryNow_NoGuild - selectedIndex: %s, CurrentTab: %s searchBoxType: %s", tostring(entry.selectedIndex), tostring(fcoglUI.CurrentTab), tostring(searchBoxType))
            comboBoxOwner:SetSearchBoxLastSelected(fcoglUI.CurrentTab, searchBoxType, entry.selectedIndex)
            --Set to normal dice roll
            FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GENERIC

            --Update the maximum number of the dice sides to the maximum possible again
            updateMaxDefaultDiceSides()


            --Set the current tab as active again to force the update of all lists and buttons
            fcoglUI.SetTab(FCOGL_TAB_GUILDSALESLOTTERY, true)
        end
        --No guild selected!
        local lastSelectedIndex = comboBoxOwner:GetSearchBoxLastSelected(fcoglUI.CurrentTab, searchBoxType)
        --Currently guild sales lottery active?
        local isGuildSalesLotteryCurrentlyActive = isGuildSalesLotteryActive()
        if isGuildSalesLotteryCurrentlyActive == true then
            --Show ask dialog and reset the guild sales lottery to none if "yes" is chosen at the dialog
            --or reset to the before chosen dropdown entry
            --Guild was selected
            FCOGuildLottery.ResetCurrentGuildSalesLotteryData(false, false, nil, nil,
                    updateEntryNowNoGuild,
                    function() abortUpdateNow(searchBoxType, lastSelectedIndex) end
            )
        else
            updateEntryNowNoGuild(entry.index)
            --comboBoxOwner:RefreshFilters()
        end

    end

    --Combobox entry selected calback function
    local entryCallbackGuild = function( _, _, entry, _ ) --comboBox, entryText, entry, selectionChanged )
        df(">entryCallbackGuild - selectedIndex: %s, id: %s, searchBoxType: %s", tostring(entry.selectedIndex), tostring(entry.id), tostring(searchBoxType))
        local function updateEntryNow(guildIndex, daysBefore)
            df(">>updateEntryNow - selectedIndex: %s, CurrentTab: %s searchBoxType: %s", tostring(entry.selectedIndex), tostring(fcoglUI.CurrentTab), tostring(searchBoxType))
            comboBoxOwner:SetSearchBoxLastSelected(fcoglUI.CurrentTab, searchBoxType, entry.selectedIndex)

            --Set the current guildId for normal guild member dice rolls
            FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
            --Set the guildId for the normal guild dice rolls
            FCOGuildLottery.currentlyUsedDiceRollGuildId = GetGuildId(guildIndex)

            --Update the maximum number of the dice sides to the current guild's member #
            local diceSidesGuild = FCOGuildLottery.RollTheDiceNormalForGuildMemberCheck(entry.index, true)
            if diceSidesGuild and diceSidesGuild > 0 then
                fcoglUIwindow.editBoxDiceSides:SetText(tostring(diceSidesGuild))
            else
                updateMaxDefaultDiceSides()
            end

            --Set the current tab as active again to force the update of all lists and buttons
            fcoglUI.SetTab(FCOGL_TAB_GUILDSALESLOTTERY, true)
        end

        --Guild selected
        local lastSelectedIndex = comboBoxOwner:GetSearchBoxLastSelected(fcoglUI.CurrentTab, searchBoxType)
        --Is currently a guild sales lottery active? Then ask if it should aborted, If not: Switch back to active guildId
        local isGuildSalesLotteryCurrentlyActive = isGuildSalesLotteryActive()
        if isGuildSalesLotteryCurrentlyActive == true then
            --Show ask dialog and reset the guild sales lottery to the new guildId if "yes" is chosen at the dialog
            --or reset to the before chosen dropdown entry
            --TODO: Get daysBefore from editbox at UI!
            local daysBefore = FCOGL_DEFAULT_GUILD_SELL_HISTORY_DAYS --7 days
            FCOGuildLottery.ResetCurrentGuildSalesLotteryData(false, false, entry.index, daysBefore,
                    updateEntryNow,
                    function() abortUpdateNow(searchBoxType, lastSelectedIndex) end
            )
        else
            --Currently no guild sales lottery active? Then just change the active dropdown entry and set the valuse for
            --the normal guild dice throws
            updateEntryNow(entry.index, nil)
            --comboBoxOwner:RefreshFilters()
        end
    end

    local entryCallbackName = function( _, _, entry, _ ) --comboBox, entryText, entry, selectionChanged )
df(">entryCallbackName - selectedIndex: %s, id: %s, searchBoxType: %s", tostring(entry.selectedIndex), tostring(entry.id), tostring(searchBoxType))
        comboBoxOwner:SetSearchBoxLastSelected(fcoglUI.CurrentTab, searchBoxType, entry.selectedIndex)
        comboBoxOwner:RefreshFilters()
    end

    local selectedGuildDataBeforeUpdate
    --local currentCharName
    local currentGuildId = 0
    local itemToSelect = 1
    --local currentCharName = ""
    --Guild combo box?
    if isGuildsCB then
        --currentCharName = GetUnitName("player")
        --Format the name
        --currentCharName = zo_strformat(SI_UNIT_NAME, currentCharName)
        selectedGuildDataBeforeUpdate = fcoglUI.selectedGuildDataBeforeUpdate
        if selectedGuildDataBeforeUpdate ~= nil and selectedGuildDataBeforeUpdate.guildId ~= nil then
            currentGuildId = selectedGuildDataBeforeUpdate.guildId
        else
            currentGuildId = FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId
        end
    end
    local numEntriesAdded = 0
    for i = 1, max do
        if not exclude or (exclude and not exclude[i]) then
            local entry
            --Guilds combo box?
            if isGuildsCB then
                local guildId = -1
                local guildsData = FCOGuildLottery.guildsData[i]
                if guildsData ~= nil then
                    entry = ZO_ComboBox:CreateItemEntry(guildsData.name, entryCallbackGuild)
                    guildId = guildsData.id
                    if currentGuildId ~= nil and guildId == currentGuildId then
                        itemToSelect = i
                    end
                    entry.index      = guildsData.index
                    entry.id         = guildId
                    entry.name       = guildsData.name
                    entry.gotTrader  = guildsData.gotTrader
                    entry.isGuild    = true
                else
                    --Last entry: Non-guild
                    if i == FCOGuildLottery.noGuildIndex then
                        local noGuildName = GetString(FCOGL_NO_GUILD)
                        entry = ZO_ComboBox:CreateItemEntry(noGuildName, entryCallbackNoGuild)
                        --guildId = nil
                        if currentGuildId == nil then
                            itemToSelect = i
                        end
                        entry.index      = i
                        entry.id         = -1
                        entry.name       = noGuildName
                        --entry.gotTrader  = nil
                        entry.isGuild = true
                    end
                end

            --Search type combo box
            elseif isNameSearchCB then
                local entryText = GetString(prefix, i)
                --entryText = entryText .. GetString(setSearchCBEntryStart, i)
                entry = ZO_ComboBox:CreateItemEntry(entryText, entryCallbackName)
                entry.id = i
            end
            numEntriesAdded = numEntriesAdded + 1
            entry.selectedIndex = numEntriesAdded
            control:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE) --ZO_COMBOBOX_UPDATE_NOW
        end
    end
    if itemToSelect ~= nil then
        if isNameSearchCB then
            itemToSelect = self:GetSearchBoxLastSelected(fcoglUI.CurrentTab, "name")
        end
        control:SelectItemByIndex(itemToSelect, true)
    end
end

function fcoglWindowClass:SetSearchBoxLastSelected(UITab, searchBoxType, selectedIndex)
df("SetSearchBoxLastSelected - UITab: %s, searchBoxType: %s, selectedIndex: %s", tostring(UITab), tostring(searchBoxType), tostring(selectedIndex))
    local listType = self:GetListType()
    fcoglUI.searchBoxLastSelected[UITab]                = fcoglUI.searchBoxLastSelected[UITab] or {}
    fcoglUI.searchBoxLastSelected[UITab][listType]      = fcoglUI.searchBoxLastSelected[UITab][listType] or {}
    fcoglUI.searchBoxLastSelected[UITab][listType][searchBoxType] = selectedIndex
end

function fcoglWindowClass:GetSearchBoxLastSelected(UITab, searchBoxType)
df("GetSearchBoxLastSelected - UITab: %s, searchBoxType: %s", tostring(UITab), tostring(searchBoxType))
    local listType = self:GetListType()
    return fcoglUI.searchBoxLastSelected[UITab] and fcoglUI.searchBoxLastSelected[UITab][listType] and
            fcoglUI.searchBoxLastSelected[UITab][listType][searchBoxType] or 1
end

------------------------------------------------
--- FCOGL window global functions XML
------------------------------------------------
function FCOGL_UI_OnMouseEnter( rowControlEnter )
	fcoglUIwindow:Row_OnMouseEnter(rowControlEnter)
    --[[
    local showAdditionalTextTooltip = false
    if showAdditionalTextTooltip then
        local data = rowControlEnter.data
        if data ~= nil then
            local clientLang = FCOGuildLottery.clientLang
            local tooltipText = ""
            local nameVar = ""
            if data.names then
                nameVar = data.names[clientLang]
            elseif data.name then
                nameVar = data.name
            end
            tooltipText = GetString(WISHLIST_TOOLTIP_COLOR_KEY) .. GetString(WISHLIST_CONST_SET) .. "|r: " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. nameVar .. "|r (" .. GetString(WISHLIST_CONST_BONUS) .. ": " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. data.bonuses .. "|r, " .. GetString(WISHLIST_CONST_ID) .. ": " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. data.setId .. "|r)"
            tooltipText = tooltipText .. "\n" .. GetString(WISHLIST_TOOLTIP_COLOR_KEY) .. GetString(WISHLIST_HEADER_LOCALITY) .. "|r: " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. data.locality .. "|r"
            tooltipText = tooltipText .. "\n" .. GetString(WISHLIST_TOOLTIP_COLOR_KEY) .. GetString(WISHLIST_HEADER_NAME) .. "|r: " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) ..data.username .. "|r"
            if data.displayName ~= nil and data.displayName ~= "" then
                tooltipText = tooltipText .. " [" .. data.displayName .. "]"
            end
            if data.timestamp ~= nil then
                local dateTimeStr = fcoglUI.getDateTimeFormatted(data.timestamp)
                tooltipText = tooltipText .. "\n" .. GetString(WISHLIST_TOOLTIP_COLOR_KEY) .. GetString(WISHLIST_HEADER_DATE) .. "|r: " .. GetString(WISHLIST_TOOLTIP_COLOR_VALUE) .. dateTimeStr .. "|r"
            end
            if tooltipText ~= "" then
                FCOGuildLottery.ShowTooltip(rowControlEnter, TOP, tooltipText)
            end
        end
    end
    ]]
end

function FCOGL_UI_OnMouseExit( rowControlExit )
	fcoglUIwindow:Row_OnMouseExit(rowControlExit)
    FCOGuildLottery.HideTooltip()
end

function FCOGL_UI_OnMouseUp( rowControlUp, button, upInside )
    if upInside then
        FCOGuildLottery.HideTooltip()
    end
end

function FCOGL_UI_OnTextChanged( editBox, isNumeric, isDefaultDiceNumber, checkEmpty )
    if FCOGuildLottery.prevVars.doNotRunOnTextChanged == true then
        FCOGuildLottery.prevVars.doNotRunOnTextChanged = false
        return
    end
    isNumeric = isNumeric or false
    isDefaultDiceNumber = isDefaultDiceNumber or false
    checkEmpty = checkEmpty or false
    local defaultVar
    if isDefaultDiceNumber == true then
        defaultVar = FCOGL_DICE_SIDES_DEFAULT
    end
    local text = editBox:GetText()
    local newValue
    if isNumeric == true then
        local numberText = tonumber(text)
        if text == "" and checkEmpty == true then
            newValue = tostring(defaultVar) or "1"
        elseif text == "0" or numberText ~= nil and numberText == 0 then
            newValue = tostring(defaultVar) or "1"
        end
        if newValue ~= nil then
            editBox:SetText(newValue)
        end
    end
    text = newValue or text
    if text ~= nil then
        if isNumeric == true and text ~= "" then
            if isDefaultDiceNumber == true then
                FCOGuildLottery.settingsVars.settings.defaultDiceSides = tonumber(text)
            end
        --else
            --updateVar = tostring(text)
        end
    end
end

function FCOGL_UI_OnArrowKey( editBox, isNumeric, isDefaultDiceNumber, doIncrease )
    isNumeric = isNumeric or false
    isDefaultDiceNumber = isDefaultDiceNumber or false
    if not isNumeric == true then return end
    local defaultVar
    if isDefaultDiceNumber == true then
        defaultVar = FCOGL_DICE_SIDES_DEFAULT
    end
    local text = editBox:GetText()
    local newValue
    local numberText = tonumber(text)
    if text == "" then
        newValue = tostring(defaultVar)
    elseif text == "0" or numberText ~= nil and numberText == 0 then
        if doIncrease == true then
            newValue = "1"
        else
            newValue = "1"
        end
    else
        if doIncrease == true then
            newValue = tostring(numberText + 1)
            if newValue > "999" then newValue = "999" end
        else
            newValue = tostring(numberText - 1)
            if newValue <= "0" then
                if isDefaultDiceNumber == true then
                    newValue = tostring(defaultVar)
                end
            end
        end
    end
    if newValue ~= nil then
        editBox:SetText(newValue)
    end
    text = newValue or text
    if text ~= nil then
        FCOGuildLottery.prevVars.doNotRunOnTextChanged = true
        if text ~= "" then
            if isDefaultDiceNumber == true then
                FCOGuildLottery.settingsVars.settings.defaultDiceSides = tonumber(text)
            end
        --else
            --updateVar = tostring(text)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--FCOGuildLottery UI functions

function fcoglWindowClass:CreateGuildSalesRankingEntry(item)
    --local uniqueId = FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier
    --local guildId = FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId
    --[[
        --Columns of "item":
        --rank
        --memberName
        --soldSum
        --taxSum
        --amountSum
    ]]
    local guildSalesRankingLine = {
        type =      SCROLLLIST_DATATYPE_GUILDSALESRANKING, -- for the search method to work -> Find the processor in zo_stringsearch:Process()
        rank =      item.rank,
        name =      item.memberName,
        price =     item.soldSum,
        tax =       item.taxSum,
        amount =    item.amountSum,
        info =      "Information text",
    }
    return guildSalesRankingLine
end

function fcoglWindowClass:CreateDiceThrowHistoryEntry(diceRolledData)
    --[[
        --Columns of "diceRolledData":
        --no -> Added in BuildMasterList
        --characterId
        --diceSides
        --displayName
        --roll
        --timestamp
    ]]
    local diceRolledHistoryLine = {
        type =      SCROLLLIST_DATATYPE_ROLLED_DICE_HISTORY, -- for the search method to work -> Find the processor in zo_stringsearch:Process()
        no =        diceRolledData.no,
        character = diceRolledData.characterId,
        name =      diceRolledData.displayName,
        nameText =  string.format("%s (%s)", diceRolledData.displayName, FCOGuildLottery.GetCharacterName(diceRolledData.characterId)),
        roll =      diceRolledData.roll,
        rollText =  string.format("%s%s (%s)", GetString(FCOGL_DICE_PREFIX), tostring(diceRolledData.diceSides), tostring(diceRolledData.roll)),
        timestamp = diceRolledData.timestamp,
    }
    return diceRolledHistoryLine
end

function fcoglUI.createWindow()
    if (not FCOGuildLottery.UI.window) then
        --The UI with the frame
        FCOGuildLottery.UI.window = fcoglWindowClass:New(FCOGLFrame, FCOGL_LISTTYPE_GUILD_SALES_LOTTERY)
        fcoglUIwindow = FCOGuildLottery.UI.window
    end
    if (not FCOGuildLottery.UI.diceHistoryWindow) then
        --The rolled dice history inside the frame
        FCOGuildLottery.UI.diceHistoryWindow = fcoglWindowClass:New(FCOGLFrameDiceHistory, FCOGL_LISTTYPE_ROLLED_DICE_HISTORY)
        fcoglUIDiceHistoryWindow = FCOGuildLottery.UI.diceHistoryWindow
    end
end

local function showUIWindow(doShow)
    local windowFrame = fcoglUIwindow.frame
    if windowFrame == nil then return end
    --Toggle show/hide
    if doShow == nil then
        --Recursively call
        showUIWindow(windowFrame:IsControlHidden())
        return
    else
        --Explicitly show/hide
        windowFrame:SetHidden(not doShow)
        FCOGuildLottery.UI.windowShown = doShow
        if doShow == true then
            setWindowPosition(windowFrame)
            fcoglUIwindow:UpdateUI(FCOGL_TAB_STATE_LOADED)
        else
            local windowDiceRollFrame = fcoglUIDiceHistoryWindow.frame
            if windowDiceRollFrame:IsHidden() then return end
            windowDiceRollFrame:SetHidden(true)
        end
    end
end

function fcoglUI.Show(doShow)
--d(">Show: " ..tostring(doShow))
    fcoglUI.createWindow()
    showUIWindow(doShow)
end
FCOGuildLottery.ToggleUI = fcoglUI.Show

function fcoglUI.OnWindowMoveStop()
    local frameControl = fcoglUIwindow.frame
    if not frameControl then return end
    local settings = FCOGuildLottery.settingsVars.settings
    settings.UIwindow.left  = frameControl:GetLeft()
    settings.UIwindow.top   = frameControl:GetTop()
end

function fcoglUI.loadSortGroupHeader(currentTab, listType)
    local settings = FCOGuildLottery.settingsVars.settings
    local uiWindowSettings = settings.UIwindow
    local sortKey = uiWindowSettings.sortKeys[currentTab] and uiWindowSettings.sortKeys[currentTab][listType]
    if sortKey== nil then sortKey = (listType == FCOGL_LISTTYPE_GUILD_SALES_LOTTERY and "name") or "datetime" end
    local sortOrder = uiWindowSettings.sortOrder[currentTab] and uiWindowSettings.sortOrder[currentTab][listType]
    if sortOrder == nil then sortOrder = (listType == FCOGL_LISTTYPE_GUILD_SALES_LOTTERY and ZO_SORT_ORDER_UP) or ZO_SORT_ORDER_DOWN end
    df("[fcoglUI.loadSortGroupHeader]currentTab: %s, listType: %s, sortKey: %s, sortOrder: %s", tostring(currentTab), tostring(listType), tostring(sortKey), tostring(sortOrder))
    return sortKey, sortOrder
end

function fcoglUI.saveSortGroupHeader(currentTab)
df("[fcoglUI.saveSortGroupHeader]currentTab: %s", tostring(currentTab))
    if fcoglUIwindow ~= nil then
        fcoglUIwindow.currentSortKey = fcoglUIwindow.sortHeaderGroup:GetCurrentSortKey()
        fcoglUIwindow.currentSortOrder = fcoglUIwindow.sortHeaderGroup:GetSortDirection()

        FCOGuildLottery.settingsVars.settings.UIwindow.sortKeys[currentTab][FCOGL_LISTTYPE_GUILD_SALES_LOTTERY]  = fcoglUIwindow.currentSortKey
        FCOGuildLottery.settingsVars.settings.UIwindow.sortOrder[currentTab][FCOGL_LISTTYPE_GUILD_SALES_LOTTERY] = fcoglUIwindow.currentSortOrder
df(">listType: %s, sortKey: %s, sortOrder: %s", tostring(FCOGL_LISTTYPE_GUILD_SALES_LOTTERY), tostring(fcoglUIwindow.currentSortKey), tostring(fcoglUIwindow.currentSortOrder))
    end
    if fcoglUIDiceHistoryWindow ~= nil then
        fcoglUIDiceHistoryWindow.currentSortKey = fcoglUIDiceHistoryWindow.sortHeaderGroup:GetCurrentSortKey()
        fcoglUIDiceHistoryWindow.currentSortOrder = fcoglUIDiceHistoryWindow.sortHeaderGroup:GetSortDirection()

        FCOGuildLottery.settingsVars.settings.UIwindow.sortKeys[currentTab][FCOGL_LISTTYPE_ROLLED_DICE_HISTORY]  = fcoglUIDiceHistoryWindow.currentSortKey
        FCOGuildLottery.settingsVars.settings.UIwindow.sortOrder[currentTab][FCOGL_LISTTYPE_ROLLED_DICE_HISTORY] = fcoglUIDiceHistoryWindow.currentSortOrder
df(">listType: %s, sortKey: %s, sortOrder: %s", tostring(FCOGL_LISTTYPE_ROLLED_DICE_HISTORY), tostring(fcoglUIDiceHistoryWindow.currentSortKey), tostring(fcoglUIDiceHistoryWindow.currentSortOrder))
    end
end

function fcoglUI.enableSaveSortGroupHeaders(headerControlParent)
df("[fcoglUI.enableSaveSortGroupHeaders]currentTab: %s", tostring(fcoglUI.CurrentTab))
    if not headerControlParent then return end
    for i=1, headerControlParent:GetNumChildren(), 1 do
        local headerControl = headerControlParent:GetChild(i)
        if headerControl ~= nil then
            --Add the handler "OnMouseUp
            ZO_PostHookHandler(headerControl, "OnMouseUp", function(headerControlVar, mouseButton, upInside, shift, ctrl, alt, command)
                df("sortGroupHeader clicked]currentTab: %s, headerClicked: %s, mouseButton: %s, upInside: %s", tostring(fcoglUI.CurrentTab), tostring(headerControlVar:GetName()), tostring(mouseButton), tostring(upInside))
                if upInside then
                    fcoglUI.saveSortGroupHeader(fcoglUI.CurrentTab)
                end
            end, addonName)
        end
    end
end

function fcoglWindowClass:resetSortGroupHeader(currentTab, listType)
df("[fcoglWindowClass:resetSortGroupHeader]currentTab: %s, listType: %s", tostring(currentTab), tostring(listType))
    currentTab = currentTab or fcoglUI.CurrentTab
    listType = listType or self:GetListType()
    if not currentTab or not listType then return end
    if self.sortHeaderGroup ~= nil then
        local currentSortKey, currentSortOrder
        currentSortKey, currentSortOrder = fcoglUI.loadSortGroupHeader(fcoglUI.CurrentTab, listType)
d("> sortKey: " .. tostring(self.currentSortKey) .. ", sortOrder: " ..tostring(self.currentSortOrder))
        self.sortHeaderGroup:SelectAndResetSortForKey(currentSortKey)
d("> sortKeyAfterReset: " .. tostring(self.currentSortKey) .. ", sortOrderAfterReset: " ..tostring(self.currentSortOrder))
        --Select the sort header again to invert the sort order, if last sort order was inverted
        if currentSortOrder == ZO_SORT_ORDER_DOWN then
            self.sortHeaderGroup:SelectHeaderByKey(currentSortKey)
d("> sortKeyAfterInvert: " .. tostring(self.currentSortKey) .. ", sortOrderAfterInvert: " ..tostring(self.currentSortOrder))
        end
    end
end

function fcoglWindowClass:updateSortHeaderAnchorsAndPositions(currentTab, nameHeaderWidth, nameHeaderHeight)
--d("[fcoglWindowClass]:updateSortHeaderAnchorsAndPositions")
    if currentTab == FCOGL_TAB_GUILDSALESLOTTERY then
        if fcoglUI.CurrentState == FCOGL_TAB_STATE_LOADED then
            self.headers:SetMouseEnabled(true)
        end
    end
end

function fcoglWindowClass:checkNewGuildSalesLotteryButtonEnabled()
    local isEnabled = true
    --No guildId selected?
    local guildIndex = self.guildsDrop:GetSelectedItemData().index
    if guildIndex == nil or guildIndex == FCOGuildLottery.noGuildIndex or
        not FCOGuildLottery.IsGuildIndexValid(guildIndex) then
        isEnabled = false
    end
    local newGuildSalesLotteryButton = self.frame:GetNamedChild("NewGuildSalesLottery")
    local reloadGuildSalesLotteryButton = self.frame:GetNamedChild("ReloadGuildSalesLottery")
    newGuildSalesLotteryButton:SetEnabled(isEnabled)
    newGuildSalesLotteryButton:SetMouseEnabled(isEnabled)
    reloadGuildSalesLotteryButton:SetEnabled(isEnabled)
    reloadGuildSalesLotteryButton:SetMouseEnabled(isEnabled)
    return isEnabled
end

function fcoglWindowClass:UpdateUI(state)
    fcoglUI.CurrentState = state
    local listType = self:GetListType()
    df("[window:UpdateUI] state: %s, currentTab: %s, listType: %s", tostring(state), tostring(fcoglUI.CurrentTab), tostring(listType))
    if listType == nil then return end

    --fcoglUI.saveSortGroupHeader(fcoglUI.CurrentTab)

    local frameControl = self.frame
    ------------------------------------------------------------------------------------------------------------------------
    --SEARCH tab
    if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
        --......................................................................................................................
        if fcoglUI.CurrentState == FCOGL_TAB_STATE_LOADED then
            --WLW_UpdateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE) ..  " - " .. zo_strformat(GetString(WISHLIST_SETS_LOADED), 0))
            --updateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE) .. " - " .. GetString(WISHLIST_BUTTON_SEARCH_TT):upper())

            if listType == FCOGL_LISTTYPE_GUILD_SALES_LOTTERY then
                --Hide currently unused tabs
                frameControl:GetNamedChild("TabList"):SetEnabled(false)
                frameControl:GetNamedChild("TabList"):SetHidden(true)
                frameControl:GetNamedChild("TabDiceRollHistory"):SetEnabled(true)
                frameControl:GetNamedChild("TabDiceRollHistory"):SetHidden(false)

                --Unhide buttons at the tab
                self.frame:GetNamedChild("RollTheDice"):SetEnabled(true)
                self.frame:GetNamedChild("RollTheDice"):SetHidden(false)
                self:checkNewGuildSalesLotteryButtonEnabled()
                self.frame:GetNamedChild("NewGuildSalesLottery"):SetHidden(false)
                self.frame:GetNamedChild("ReloadGuildSalesLottery"):SetHidden(false)

                self.frame:GetNamedChild("GuildsDrop"):SetHidden(false)

                --Unhide the scroll list
                self.frame:GetNamedChild("List"):SetHidden(false)
                --Unhide the scroll list headers
                self.frame:GetNamedChild("Headers"):SetHidden(false)

                self.headerRank:SetHidden(false)
                --self.headerDate:SetHidden(false)
                self.headerName:SetHidden(false)
                --self.headerItem:SetHidden(false)
                self.headerPrice:SetHidden(false)
                self.headerTax:SetHidden(false)
                self.headerAmount:SetHidden(false)
                self.headerInfo:SetHidden(false)

                --Hide/Unhide the dice history frame -> Will call recursively function UpdateUI(state) for listType
                --FCOGL_LISTTYPE_ROLLED_DICE_HISTORY
                fcoglUI.ToggleDiceRollHistory(FCOGuildLottery.settingsVars.settings.UIDiceHistoryWindow.isHidden)


            elseif listType == FCOGL_LISTTYPE_ROLLED_DICE_HISTORY then
                --Unhide the scroll list
                self.frame:GetNamedChild("List"):SetHidden(false)
                --Unhide the scroll list headers
                self.frame:GetNamedChild("Headers"):SetHidden(false)

                self.headerNo:SetHidden(false)
                self.headerDate:SetHidden(false)
                self.headerName:SetHidden(false)
                self.headerRoll:SetHidden(false)
            end

            --For both list types
            --Unhide the search
            self.searchBox:SetHidden(false)
            self.frame:GetNamedChild("Search"):SetHidden(false)
            --Unhide the dropdown boxes
            self.frame:GetNamedChild("SearchDrop"):SetHidden(false)
            self.searchBox:Clear()

            --Reset the sortGroupHeader
            -->Currently not needed as there is only 1 tab
            --self:resetSortGroupHeader(fcoglUI.CurrentTab, listType)

            self:RefreshData()
        end
        ------------------------------------------------------------------------------------------------------------------------
    end
    self:updateSortHeaderAnchorsAndPositions(fcoglUI.CurrentTab, nil, nil)
end -- fcoglWindow:UpdateUI(state)

--Change the tabs at the WishList menu
function fcoglUI.SetTab(index, override)
df("[SetTab] - index: %s, override: %s", tostring(index), tostring(override))
    if not fcoglUIwindow then return end
    --fcoglUI.saveSortGroupHeader(fcoglUI.CurrentTab)

    --Do not activate active tab
    if override == true or fcoglUI.CurrentTab == nil or (fcoglUI.CurrentTab ~= nil and fcoglUI.CurrentTab ~= index) then
        --Change to the new tab
        fcoglUI.CurrentTab = index

        --Clear the master list of the currently shown ZO_SortFilterLists
        ZO_ScrollList_Clear(fcoglUIwindow.list)
        fcoglUIwindow.masterList = {}
        ZO_ScrollList_Clear(fcoglUIDiceHistoryWindow.list)
        fcoglUIDiceHistoryWindow.masterList = {}

        --Reset variable
        fcoglUI.comingFromSortScrollListSetupFunction = false
        --Update the UI (hide/show items), and also check for the dice roll history to show
        --via function fcoglUI.ToggleDiceRollHistory() -> Calls fcoglUIDiceHistoryWindow:UpdateUI
        fcoglUIwindow:UpdateUI(fcoglUI.CurrentState)
    end
end

--Toggle the dice roll history "attached" window part at the right
function fcoglUI.ToggleDiceRollHistory(setHidden)
df("[ToggleDiceRollHistory] - setHidden: %s", tostring(setHidden))
    local frameControl = fcoglUIwindow and fcoglUIwindow.frame
    if frameControl == nil or frameControl:IsControlHidden() then return end
    local frameDiceHistoryControl = fcoglUIDiceHistoryWindow and fcoglUIDiceHistoryWindow.control
    if frameDiceHistoryControl == nil then return end
    local isHidden = frameDiceHistoryControl:IsControlHidden()
    local newState = (setHidden ~= nil and setHidden) or (not isHidden)
df(">newHiddenState: %s", tostring(newState))

    frameDiceHistoryControl:SetHidden(newState)

    fcoglUIDiceHistoryWindow:UpdateUI(fcoglUI.CurrentState)

    --Update the texture at the toggle button
    local tabDiceRollHistoryButton = frameControl:GetNamedChild("TabDiceRollHistory")
    local newStateVal = buttonNewStateVal[newState]
    tabDiceRollHistoryButton:SetState(newStateVal)
    --Save the current state to the SavedVariables
--d(">Updating to: " ..tostring(newState))
    FCOGuildLottery.settingsVars.settings.UIDiceHistoryWindow.isHidden = newState

    --Dice history is shown? Update the list (masterlist) via the Refresh function from UpdateUI
    -->Will call BuildMasterlist then
    --Clear the list here first!
--[[
    if newState == false then
d(">diceHistoryWindow shown: RefreshData now")
        --Clear the master list of the currently shown ZO_SortFilterList -> DiceRollHistory
        ZO_ScrollList_Clear(fcoglUIDiceHistoryWindow.list)
        fcoglUIDiceHistoryWindow.masterList = {}
        fcoglUIDiceHistoryWindow:RefreshData()
    end
]]
end
