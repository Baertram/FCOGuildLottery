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

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
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


    --The guild sales lottery list
    if listType == FCOGL_LISTTYPE_GUILD_SALES_LOTTERY then
        --Scroll UI
        ZO_ScrollList_AddDataType(self.list, fcoglUI.SCROLLLIST_DATATYPE_GUILDSALESRANKING, "FCOGLRowGuildSales", 30, function(control, data)
            self:SetupItemRow(control, data)
        end)
        ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
        self:SetAlternateRowBackgrounds(true)

        self.masterList = { }

        --Build the sortkeys depending on the settings
        --self:BuildSortKeys() --> Will be called internally in "self.sortHeaderGroup:SelectAndResetSortForKey"
        self.currentSortKey = "name"
        self.currentSortOrder = ZO_SORT_ORDER_UP
        self.sortHeaderGroup:SelectAndResetSortForKey(self.currentSortKey) -- Will call "SortScrollList" internally
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
        fcoglUI.initializeSearchDropdown(self, FCOGL_TAB_GUILDSALESLOTTERY, listType, "name")
        --Guilds
        self.guildsDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("GuildsDrop"))
        fcoglUI.initializeSearchDropdown(self, FCOGL_TAB_GUILDSALESLOTTERY, listType, "guilds")

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
            self:SetupItemRow(control, data, listType)
        end)
        ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
        self:SetAlternateRowBackgrounds(true)

        self.masterList = { }

        --Build the sortkeys depending on the settings
        --self:BuildSortKeys() --> Will be called internally in "self.sortHeaderGroup:SelectAndResetSortForKey"
        self.currentSortKey = "name"
        self.currentSortOrder = ZO_SORT_ORDER_UP
        self.sortHeaderGroup:SelectAndResetSortForKey(self.currentSortKey) -- Will call "SortScrollList" internally
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
        fcoglUI.initializeSearchDropdown(self, FCOGL_TAB_GUILDSALESLOTTERY, listType, "name")

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

        self.headers:SetHidden(true)
        self.list = self.frame:GetNamedChild("List")
        self.list:SetHidden(true)
    end

    self:RefreshData()
end

function fcoglWindowClass:BuildMasterList(calledFromFilterFunction)
    calledFromFilterFunction = calledFromFilterFunction or false
    df("list:BuildMasterList-calledFromFilterFunction: %s", tostring(calledFromFilterFunction))

    if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
        if FCOGuildLottery.currentlyUsedGuildSalesLotteryUniqueIdentifier == nil or
           FCOGuildLottery.currentlyUsedGuildSalesLotteryGuildId == nil then return end
        self.masterList = {}

        local rankingData = FCOGuildLottery.currentlyUsedGuildSalesLotteryMemberSellRank
        if rankingData == nil or #rankingData == 0 then return false end
        for i = 1, #rankingData do
            local item = rankingData[i]
            table.insert(self.masterList, fcoglUI.CreateGuildSalesRankingEntry(item))
        end
        --self:updateSortHeaderAnchorsAndPositions(fcoglUI.CurrentTab, settings.maxNameColumnWidth, 32)
    end
end

--Setup the data of each row which gets added to the ZO_SortFilterList
function fcoglWindowClass:SetupItemRow(control, data, listType)
--df("SetupItemRow")
    if fcoglUI.comingFromSortScrollListSetupFunction then return end

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
            nameColumn:ClearAnchors()
            nameColumn.normalColor = ZO_DEFAULT_TEXT
            if not data.columnWidth then data.columnWidth = 200 end
            nameColumn:SetDimensions(data.columnWidth, 30)
            nameColumn:SetText(data.name)
            nameColumn:SetAnchor(LEFT, rankColumn, RIGHT, 0, 0)
            nameColumn:SetText(data.name)
            nameColumn:SetHidden(false)
            priceColumn:SetHidden(false)
            priceColumn:ClearAnchors()
            priceColumn:SetAnchor(LEFT, nameColumn, RIGHT, 0, 0)
            priceColumn:SetText(data.price)
            taxColumn:SetHidden(false)
            taxColumn:ClearAnchors()
            taxColumn:SetAnchor(LEFT, priceColumn, RIGHT, 0, 0)
            taxColumn:SetText(data.tax)
            amountColumn:SetHidden(false)
            amountColumn:ClearAnchors()
            amountColumn:SetAnchor(LEFT, taxColumn, RIGHT, 0, 0)
            amountColumn:SetText(data.amount)
            infoColumn:SetHidden(false)
            infoColumn:ClearAnchors()
            infoColumn:SetAnchor(LEFT, amountColumn, RIGHT, 0, 0)
            infoColumn:SetAnchor(RIGHT, control, RIGHT, 0, 0)
            infoColumn:SetText(data.info)
        end


    elseif listType == FCOGL_LISTTYPE_ROLLED_DICE_HISTORY then
        --local clientLang = fcoglUI.clientLang or fcoglUI.fallbackSetLang
        control.data = data
        --local updateSortHeaderDimensionsAndAnchors = false
        local noColumn = control:GetNamedChild("No")
        local dateColumn = control:GetNamedChild("DateTime")
        local nameColumn = control:GetNamedChild("Name")
        local rollColumn = control:GetNamedChild("Roll")
        ------------------------------------------------------------------------------------------------------------------------
        noColumn:SetHidden(false)
        noColumn:ClearAnchors()
        noColumn:SetAnchor(LEFT, control, nil, 0, 0)
        noColumn:SetText(data.no)
        local dateTimeStamp = data.timestamp
        local dateTimeStr = FCOGuildLottery.getDateTimeFormatted(dateTimeStamp)
        dateColumn:ClearAnchors()
        dateColumn:SetAnchor(LEFT, noColumn, RIGHT, 0, 0)
        dateColumn:SetText(dateTimeStr)
        dateColumn:SetHidden(false)
        nameColumn:ClearAnchors()
        nameColumn.normalColor = ZO_DEFAULT_TEXT
        if not data.columnWidth then data.columnWidth = 200 end
        nameColumn:SetDimensions(data.columnWidth, 30)
        nameColumn:SetAnchor(LEFT, dateColumn, RIGHT, 0, 0)
        nameColumn:SetText(data.name)
        nameColumn:SetHidden(false)
        rollColumn:SetHidden(false)
        rollColumn:ClearAnchors()
        rollColumn:SetAnchor(LEFT, nameColumn, RIGHT, 0, 0)
        rollColumn:SetAnchor(RIGHT, control, RIGHT, 0, 0)
        rollColumn:SetText(data.roll)
    end

    --Set the row to the list now
    ZO_SortFilterList.SetupRow(self, control, data)
end

function fcoglWindowClass:FilterScrollList()
--d("[fcoglWindow:FilterScrollList]")
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
    checkIfMasterListRebuildNeeded(self)
    if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
        for i = 1, #self.masterList do
            --Get the data of each set item
            local data = self.masterList[i]
            --Search for text/set bonuses
            if searchInput == "" or self:CheckForMatch(data, searchInput) then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(fcoglUI.SCROLLLIST_DATATYPE_GUILDSALESRANKING, data))
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
--d("[fcoglUI.BuildSortKeys]")
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
    --Build the sortkeys depending on the settings
    self:BuildSortKeys()
    --Get the current sort header's key and direction
    self.currentSortKey = self.sortHeaderGroup:GetCurrentSortKey()
    self.currentSortOrder = self.sortHeaderGroup:GetSortDirection()
--d("[fcoglWindow:SortScrollList] sortKey: " .. tostring(self.currentSortKey) .. ", sortOrder: " ..tostring(self.currentSortOrder))
	if (self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
        --If not coming from setup function
        if fcoglUI.comingFromSortScrollListSetupFunction then return end
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
function fcoglUI.initializeSearchDropdown(window, currentTab, currentListType, searchBoxType)
    if window == nil then return false end
    currentTab = currentTab or fcoglUI.CurrentTab or FCOGL_TAB_GUILDSALESLOTTERY
    currentListType = currentListType or fcoglUI.CurrentListType or FCOGL_LISTTYPE_GUILD_SALES_LOTTERY
    searchBoxType = searchBoxType or "name"
    local currentTab2SearchDropValues = {
        [FCOGL_TAB_GUILDSALESLOTTERY]   = {
            [FCOGL_LISTTYPE_GUILD_SALES_LOTTERY] = {
                ["name"] = {dropdown=window.searchDrop,  prefix=FCOGL_SEARCHDROP_PREFIX,  entryCount=FCOGL_SEARCH_TYPE_ITERATION_END,
                            exclude = {
                                [FCOGL_SEARCH_TYPE_NAME]     = false,
                            }, --exclude the search entries from the set search
                },
                ["guilds"] = {dropdown=window.guildsDrop,  prefix=FCOGL_GUILDSDROP_PREFIX,  entryCount=#FCOGuildLottery.guildsData + 1, --5 guilds + 1 non-guild entry
                              exclude = {
                                  [FCOGL_SEARCH_TYPE_NAME]     = false,
                              }, --exclude the search entries from the set search
                },
            },
            [FCOGL_LISTTYPE_ROLLED_DICE_HISTORY] = {
                ["name"] = {dropdown=window.searchDrop,  prefix=FCOGL_SEARCHDROP_PREFIX,  entryCount=FCOGL_SEARCH_TYPE_ITERATION_END,
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
    window:InitializeComboBox(searchDropData.dropdown, searchDropData.prefix, searchDropData.entryCount, searchDropData.exclude, searchBoxType )
end

function fcoglWindowClass:InitializeComboBox(control, prefix, max, exclude, searchBoxType )
    local isGuildsCB = ((prefix == FCOGL_GUILDSDROP_PREFIX) or searchBoxType == "guilds") or false
    local isNameSearchCB = ((prefix == FCOGL_SEARCHDROP_PREFIX) or searchBoxType == "name") or false
--d("[fcoglWindow:InitializeComboBox]isSetSearchCB: " .. tostring(isSetSearchCB) .. ", isCharCB: " .. tostring(isCharCB) .. ", prefix: " .. tostring(prefix) ..", max: " .. tostring(max))
    control:SetSortsItems(false)
    control:ClearItems()

    local callback = function( _, _, entry, _ ) --comboBox, entryText, entry, selectionChanged )
        self:SetSearchBoxLastSelected(fcoglUI.CurrentTab, searchBoxType, entry.selectedIndex)
        self:RefreshFilters()
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
                    entry = ZO_ComboBox:CreateItemEntry(guildsData.name, callback)
                    guildId = guildsData.id
                    if currentGuildId ~= nil and guildId == currentGuildId then
                        itemToSelect = i
                    end
                    entry.index      = guildsData.index
                    entry.id         = guildId
                    entry.name       = guildsData.name
                    entry.gotTrader  = guildsData.gotTrader
                else
                    --Last entry: Non-guild
                    if i == FCOGuildLottery.noGuildIndex then
                        local noGuildName = GetString(FCOGL_NO_GUILD)
                        entry = ZO_ComboBox:CreateItemEntry(noGuildName, callback)
                        --guildId = nil
                        if currentGuildId == nil then
                            itemToSelect = i
                        end
                        entry.index      = i
                        entry.id         = -1
                        entry.name       = noGuildName
                        --entry.gotTrader  = nil
                    end
                end

            --Search type combo box
            elseif isNameSearchCB then
                local entryText = GetString(prefix, i)
                --entryText = entryText .. GetString(setSearchCBEntryStart, i)
                entry = ZO_ComboBox:CreateItemEntry(entryText, callback)
                entry.id = i
            end
            numEntriesAdded = numEntriesAdded + 1
            entry.selectedIndex = numEntriesAdded
            control:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
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
    fcoglUI.searchBoxLastSelected[UITab]                = fcoglUI.searchBoxLastSelected[UITab] or {}
    fcoglUI.searchBoxLastSelected[UITab][searchBoxType] = selectedIndex
end

function fcoglWindowClass:GetSearchBoxLastSelected(UITab, searchBoxType)
    if fcoglUI.searchBoxLastSelected[UITab] and fcoglUI.searchBoxLastSelected[UITab][searchBoxType] then
        return fcoglUI.searchBoxLastSelected[UITab][searchBoxType]
    end
    return 1
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
            if newValue > "999"" then newValue = "999"" end
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

function fcoglUI.CreateGuildSalesRankingEntry(item)
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
        type =      FCOGL_SEARCH_TYPE_NAME, -- for the search method to work -> Find the processor in zo_stringsearch:Process()
        rank =      item.rank,
        name =      item.memberName,
        price =     item.soldSum,
        tax =       item.taxSum,
        amount =    item.amountSum,
        info =      "Information text",
    }
    return guildSalesRankingLine
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

local function resetSortGroupHeader(currentTab)
--d("[WL.resetSortGroupHeader]")
    local UIwindow = fcoglUIwindow
    if UIwindow.sortHeaderGroup then
        local settings = FCOGuildLottery.settingsVars.settings
        local sortHeaderKey = settings.UIwindow.sortKeys[currentTab] or "name"
        local sortOrder = settings.UIwindow.sortOrder[currentTab]

        UIwindow.currentSortKey = sortHeaderKey
        UIwindow.currentSortOrder = sortOrder
        UIwindow.sortHeaderGroup:SelectAndResetSortForKey(sortHeaderKey)
        --Select the sort header again to invert the sort order, if last sort order was inverted
        if sortOrder == ZO_SORT_ORDER_DOWN then
            UIwindow.sortHeaderGroup:SelectHeaderByKey(sortHeaderKey)
        end
    end
end

function fcoglUI.saveSortGroupHeader(currentTab)
--d("[WL.saveSortGroupHeader]")
    if fcoglUIwindow then
        local settings = FCOGuildLottery.settingsVars.settings
        settings.UIwindow.sortKeys[currentTab]  = fcoglUIwindow.currentSortKey
        settings.UIwindow.sortOrder[currentTab] = fcoglUIwindow.currentSortOrder
    end
end


function fcoglWindowClass:updateSortHeaderAnchorsAndPositions(wlTab, nameHeaderWidth, nameHeaderHeight)
--d("[fcoglWindowClass]:updateSortHeaderAnchorsAndPositions")
    if wlTab == FCOGL_TAB_GUILDSALESLOTTERY then
        if fcoglUI.CurrentState == FCOGL_TAB_STATE_LOADED then
            --[[
            self.headerDate:ClearAnchors()
            self.headerName:ClearAnchors()
            self.headerName:SetAnchor(TOPLEFT, self.headers, nil, 0, 0)
            self.headerName:SetDimensions(nameHeaderWidth, nameHeaderHeight)
            self.headerInfo:ClearAnchors()
            self.headerInfo:SetAnchor(TOPLEFT, self.headerName, TOPRIGHT, 0, 0)
            self.headerInfo:SetAnchor(TOPRIGHT, self.headers, TOPRIGHT, -16, 0)
            ]]
        end
    end
end

function fcoglWindowClass:UpdateUI(state)
	fcoglUI.CurrentState = state
--d("[fcoglWindow:UpdateUI] state: " ..tostring(state) .. ", currentTab: " ..tostring(fcoglUI.CurrentTab))

    local frameControl = self.frame
    ------------------------------------------------------------------------------------------------------------------------
    --SEARCH tab
	if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
--......................................................................................................................
        if fcoglUI.CurrentState == FCOGL_TAB_STATE_LOADED then
            --WLW_UpdateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE) ..  " - " .. zo_strformat(GetString(WISHLIST_SETS_LOADED), 0))
            --updateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE) .. " - " .. GetString(WISHLIST_BUTTON_SEARCH_TT):upper())

            --Hide currently unused tabs
            frameControl:GetNamedChild("TabList"):SetEnabled(false)
            frameControl:GetNamedChild("TabList"):SetHidden(true)
            frameControl:GetNamedChild("TabDiceRollHistory"):SetEnabled(true)
            frameControl:GetNamedChild("TabDiceRollHistory"):SetHidden(false)
            --Unhide the current tab

            --Unhide buttons at the tab
            self.frame:GetNamedChild("ReloadGuildSalesLottery"):SetEnabled(true)
            self.frame:GetNamedChild("ReloadGuildSalesLottery"):SetHidden(false)
            self.frame:GetNamedChild("RollTheDice"):SetEnabled(true)
            self.frame:GetNamedChild("RollTheDice"):SetHidden(false)
            self.frame:GetNamedChild("NewGuildSalesLottery"):SetEnabled(true)
            self.frame:GetNamedChild("NewGuildSalesLottery"):SetHidden(false)
            --Unhide the search
            self.searchBox:SetHidden(false)
            self.frame:GetNamedChild("Search"):SetHidden(false)
            --Unhide the dropdown boxes
            self.frame:GetNamedChild("SearchDrop"):SetHidden(false)
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

            self.searchBox:Clear()

            --Hide/Unhide the dice history frame
            fcoglUI:ToggleDiceRollHistory(FCOGuildLottery.settingsVars.settings.UIDiceHistoryWindow.isHidden)

            --Reset the sortGroupHeader
            resetSortGroupHeader(fcoglUI.CurrentTab)

            self:RefreshData()
        end
------------------------------------------------------------------------------------------------------------------------
	end
    self:updateSortHeaderAnchorsAndPositions(fcoglUI.CurrentTab, 200, 32)
end -- fcoglWindow:UpdateUI(state)

--Change the tabs at the WishList menu
function fcoglUI.SetTab(index, override)
df("SetTab - index: %s, override: %s", tostring(index), tostring(override))
    if not fcoglUIwindow then return end
    --Do not activate active tab
    if fcoglUI.CurrentTab and (override == true or fcoglUI.CurrentTab ~= index) then
        --Save the current sort order and key
        fcoglUI.saveSortGroupHeader(fcoglUI.CurrentTab)
        --Change to the new tab
        fcoglUI.CurrentTab = index
        --Clear the master list of the currently shown ZO_SortFilterList
        ZO_ScrollList_Clear(fcoglUIwindow.list)
        ZO_ScrollList_Clear(fcoglUIDiceHistoryWindow.list)
        fcoglUIwindow.masterList = {}
        fcoglUIDiceHistoryWindow.masterList = {}
        --Reset variable
        fcoglUI.comingFromSortScrollListSetupFunction = false
        --Update the UI (hide/show items)
        fcoglUIwindow:UpdateUI(fcoglUI.CurrentState)
    end
end

--Toggle the dice roll history "attached" window part at the right
function fcoglUI:ToggleDiceRollHistory(setHidden)
--d(">ToggleDiceRollHistory - setHidden: " ..tostring(setHidden))
    local frameControl = fcoglUIwindow and fcoglUIwindow.frame
    if frameControl == nil or frameControl:IsControlHidden() then return end
    local frameDiceHistoryControl = fcoglUIDiceHistoryWindow and fcoglUIDiceHistoryWindow.control
    if frameDiceHistoryControl == nil then return end
    local isHidden = frameDiceHistoryControl:IsControlHidden()
    local newState = (setHidden ~= nil and setHidden) or (not isHidden)

    frameDiceHistoryControl:SetHidden(newState)
    --(Un)hide the scroll list
    fcoglUIDiceHistoryWindow.list:SetHidden(newState)

    --Change the sort headers
    local diceRollHistoryHeader = frameDiceHistoryControl:GetNamedChild("Headers")
    --diceRollHistoryHeader:ClearAnchors()
    --diceRollHistoryHeader:SetDimensions(445, 30)
    --diceRollHistoryHeader:SetAnchor(TOPLEFT, frameDiceHistoryControl, TOPLEFT, 30, 51)
    --diceRollHistoryHeader:SetAnchor(TOPRIGHT, frameDiceHistoryControl, TOPRIGHT, 0, 51)
    diceRollHistoryHeader:SetHidden(newState)

    --Update the texture at the toggle button
    local tabDiceRollHistoryButton = frameControl:GetNamedChild("TabDiceRollHistory")
    local newStateVal = buttonNewStateVal[newState]
    tabDiceRollHistoryButton:SetState(newStateVal)
    --Save the current state to the SavedVariables
--d(">Updating to: " ..tostring(newState))
    FCOGuildLottery.settingsVars.settings.UIDiceHistoryWindow.isHidden = newState
end
