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
fcoglUI.CurrentState    = FCOGL_TAB_STATE_LOADING
fcoglUI.CurrentTab      = FCOGL_TAB_GUILDSALESLOTTERY
fcoglUI.comingFromSortScrollListSetupFunction = false
fcoglUI.sortType = 1
fcoglUI.selectedGuildDataBeforeUpdate = nil
fcoglUI.searchBoxLastSelected = {}


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--FCOGuildLottery window - The UI

FCOGuildLottery.UI.windowClass = ZO_SortFilterList:Subclass()
local fcoglWindowClass = FCOGuildLottery.UI.windowClass

local function setWindowPosition(windowFrame)
    if not windowFrame or (windowFrame and not windowFrame.SetAnchor) then return end
    local settings = FCOGuildLottery.settingsVars.settings
    local uiWindowSettings = settings.UIwindow

    windowFrame:ClearAnchors()
    windowFrame:SetDimensions(uiWindowSettings.width, uiWindowSettings.height)
    windowFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, uiWindowSettings.left, uiWindowSettings.top)
end

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


function fcoglWindowClass:New(control )
	local list = ZO_SortFilterList.New(self, control)
	list.frame = control
	list:Setup()
	return list
end

function fcoglWindowClass:Setup( )
--d("[fcoglWindow:Setup]")
    fcoglUI.comingFromSortScrollListSetupFunction = true
    fcoglUI.CurrentTab = FCOGL_TAB_GUILDSALESLOTTERY

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
    fcoglUI.initializeSearchDropdown(self, FCOGL_TAB_GUILDSALESLOTTERY, "name")
    --Guilds
    self.guildsDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("GuildsDrop"))
    fcoglUI.initializeSearchDropdown(self, FCOGL_TAB_GUILDSALESLOTTERY, "guilds")

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
    --self.headerDate     = self.headers:GetNamedChild("DateTime")
    self.headerName     = self.headers:GetNamedChild("Name")
    --self.headerItem     = self.headers:GetNamedChild("Item")
	self.headerPrice    = self.headers:GetNamedChild("Price")
	self.headerTax      = self.headers:GetNamedChild("Tax")
    self.headerAmount   = self.headers:GetNamedChild("Amount")
	self.headerInfo     = self.headers:GetNamedChild("Info")

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
    self:RefreshData()
end

function fcoglWindowClass:BuildMasterList(calledFromFilterFunction)
    calledFromFilterFunction = calledFromFilterFunction or false
    self.masterList = {}

    if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
        local rankingData = FCOGuildLottery.guildSellStats[GetGuildId(3)] --Fair Trade Society
        if rankingData == nil or #rankingData == 0 then return false end
        for i = 1, #rankingData do
            local item = rankingData[i]
            table.insert(self.masterList, fcoglUI.CreateRankingEntryForItem(item))
        end
    end
end

--Setup the data of each row which gets added to the ZO_SortFilterList
function fcoglWindowClass:SetupItemRow(control, data )
    if fcoglUI.comingFromSortScrollListSetupFunction then return end
    --local clientLang = fcoglUI.clientLang or fcoglUI.fallbackSetLang
    --d(">>>      [fcoglWindow:SetupItemRow] " ..tostring(data.names[clientLang]))
    control.data = data
    --local updateSortHeaderDimensionsAndAnchors = false
    local setItemCollectionStateColumn = control:GetNamedChild("SetItemCollectionState")
    local markerTexture = setItemCollectionStateColumn:GetNamedChild("Marker")
    local nameColumn = control:GetNamedChild("Name")
    nameColumn.normalColor = ZO_DEFAULT_TEXT
    if not data.columnWidth then data.columnWidth = 200 end
    nameColumn:SetDimensions(data.columnWidth, 30)
    nameColumn:SetText(data.name)
    local armorOrWeaponTypeColumn = control:GetNamedChild("ArmorOrWeaponType")
    local slotColumn = control:GetNamedChild("Slot")
    local traitColumn = control:GetNamedChild("Trait")
    local dateColumn = control:GetNamedChild("DateTime")
    local qualityColumn = control:GetNamedChild("Quality")
    local userNameColumn = control:GetNamedChild("UserName")
    local localityColumn = control:GetNamedChild("Locality")
    localityColumn.localityName = nil
    ------------------------------------------------------------------------------------------------------------------------
    if fcoglUI.CurrentTab == FCOGL_TAB_GUILDSALESLOTTERY then
        local dateTimeStamp = data.timestamp
        local dateTimeStr = fcoglUI.getDateTimeFormatted(dateTimeStamp)
        dateColumn:ClearAnchors()
        dateColumn:SetAnchor(LEFT, control, nil, 0, 0)
        dateColumn:SetText(dateTimeStr)
        dateColumn:SetHidden(false)
        nameColumn:SetHidden(false)
        nameColumn:ClearAnchors()
        nameColumn:SetAnchor(LEFT, dateColumn, RIGHT, 0, 0)
        userNameColumn:SetHidden(true)
        qualityColumn:SetHidden(false)
        localityColumn:SetHidden(true)
        localityColumn:ClearAnchors()
        armorOrWeaponTypeColumn:SetHidden(false)
        slotColumn:SetHidden(false)
        traitColumn:SetHidden(false)
        armorOrWeaponTypeColumn.normalColor = ZO_DEFAULT_TEXT
        local armorOrWeaponTypeColumnText = ""
        armorOrWeaponTypeColumn:SetText(armorOrWeaponTypeColumnText)
        slotColumn.normalColor = ZO_DEFAULT_TEXT
        slotColumn:SetText("")
        traitColumn.normalColor = ZO_DEFAULT_TEXT
        --Add the icon to the trait column
        local traitId = data.trait
        local traitText = ""
        traitColumn:SetText(traitText)
        local qualityText = ""
        qualityColumn:ClearAnchors()
        qualityColumn:SetAnchor(LEFT, traitColumn, RIGHT, 0, 0)
        qualityColumn:SetText(qualityText)
        setItemCollectionStateColumn:SetHidden(false)
        setItemCollectionStateColumn:ClearAnchors()
        setItemCollectionStateColumn:SetAnchor(LEFT, qualityColumn, RIGHT, 0, 0)
        markerTexture:SetTexture("")
        markerTexture:SetHidden(true)
        setItemCollectionStateColumn:SetAnchor(RIGHT, control, RIGHT, -16, 0)
    end
    --Set the row to the list now
    ZO_SortFilterList.SetupRow(self, control, data)
end

function fcoglWindowClass:FilterScrollList()
--d("[fcoglWindow:FilterScrollList]")
	local scrollData = ZO_ScrollList_GetDataList(self.list)
	ZO_ClearNumericallyIndexedTable(scrollData)

    --Get the search method chosen at the search dropdown
    --self.searchType = self.searchDrop:GetSelectedItemData().id
    self.searchType = 1
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
            ["timestamp"]               = { isId64          = true, tiebreaker = "name"  }, --isNumeric = true
            ["knownInSetItemCollectionBook"] = { caseInsensitive = true, isNumeric = true, tiebreaker = "name" },
            ["name"]                    = { caseInsensitive = true },
            ["armorOrWeaponTypeName"]   = { caseInsensitive = true, tiebreaker = "name" },
            ["slotName"]                = { caseInsensitive = true, tiebreaker = "name" },
            ["traitName"]               = { caseInsensitive = true, tiebreaker = "name" },
            ["quality"]                 = { caseInsensitive = true, tiebreaker = "name" },
            ["username"]                = { caseInsensitive = true, tiebreaker = "name" },
            ["locality"]                = { caseInsensitive = true, tiebreaker = "name" },
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

function fcoglWindowClass:SearchByCriteria(data, searchInput)
    if data == nil or searchInput == nil or searchInput == "" then return nil end
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
    data["type"]                    = 1 -- for the search method to work -> Find the processor in zo_stringsearch:Process()
    data["id"]                      = itemId
    data["setId"]                   = histDataOfCharId["setId"]
    data["itemType"]                = histDataOfCharId["itemType"]
    data["itemTypeName"]            = itemTypeName
    data["trait"]                   = histDataOfCharId["trait"]
    data["traitName"]               = traitTypeName
    data["armorOrWeaponType"]       = histDataOfCharId["armorOrWeaponType"]
    data["armorOrWeaponTypeName"]   = armorOrWeaponTypeName
    data["slot"]                    = histDataOfCharId["slot"]
    data["slotName"]                = slotTypeName
    data["quality"]                 = histDataOfCharId["quality"]
    data["qualityName"]             = qualityName
    data["name"]                    = histDataOfCharId["setName"]
    data["itemLink"]                = itemLink
    data["bonuses"]                 = numBonuses -- the number of the bonuses of the set
    data["timestamp"]               = histDataOfCharId["timestamp"]
    data["username"]                = histDataOfCharId["username"]
    data["displayName"]             = histDataOfCharId["displayName"]
    data["locality"]                = histDataOfCharId["locality"]
    data["knownInSetItemCollectionBook"] = histDataOfCharId["knownInSetItemCollectionBook"]
    --LibSets data
    data["setType"]         = mlData.setType
    data["traitsNeeded"]    = mlData.traitsNeeded
    data["dlcId"]           = mlData.dlcId
    data["zoneIds"]         = mlData.zoneIds
    data["wayshrines"]      = mlData.wayshrines
    data["zoneIdNames"]     = mlData.zoneIdNames
    data["wayshrineNames"]  = mlData.wayshrineNames
    data["dlcName"]         = mlData.dlcName
    data["setTypeName"]     = mlData.setTypeName
    data["armorTypes"]      = mlData.armorTypes
    data["dropMechanics"]   = mlData.dropMechanics
]]
    return false
end

function fcoglWindowClass:CheckForMatch(data, searchInput )
    return(self:SearchByCriteria(data, searchInput))
end

function fcoglWindowClass:ProcessItemEntry(stringSearch, data, searchTerm )
--d("[WLW.ProcessItemEntry] stringSearch: " ..tostring(stringSearch) .. ", setName: " .. tostring(data.name:lower()) .. ", searchTerm: " .. tostring(searchTerm))
	if ( zo_plainstrfind(data.name:lower(), searchTerm) ) then
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
function fcoglUI.initializeSearchDropdown(window, currentTab, searchBoxType)
    if window == nil then return false end
    currentTab = currentTab or fcoglUI.CurrentTab or FCOGL_TAB_GUILDSALESLOTTERY
    searchBoxType = searchBoxType or "name"
    local currentTab2SearchDropValues = {
        [FCOGL_TAB_GUILDSALESLOTTERY]   = {
            ["name"] = {dropdown=window.searchDrop,  prefix=FCOGL_SEARCHDROP_PREFIX,  entryCount=FCOGL_SEARCH_TYPE_ITERATION_END,
                        exclude = {
                            [FCOGL_SEARCH_TYPE_NAME]     = false,
                        }, --exclude the search entries from the set search
            },
            ["guilds"] = {dropdown=window.guildsDrop,  prefix=FCOGL_GUILDSDROP_PREFIX,  entryCount=#FCOGuildLottery.guildsData,
                        exclude = {
                            [FCOGL_SEARCH_TYPE_NAME]     = false,
                        }, --exclude the search entries from the set search
            },
        },
    }
    local searchDropAtTab = currentTab2SearchDropValues[currentTab]
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
--- FCOGL Row
------------------------------------------------
function FCOGL_UI_OnMouseEnter( rowControlEnter )
	FCOGuildLottery.UI.window:Row_OnMouseEnter(rowControlEnter)
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
end

function FCOGL_UI_OnMouseExit( rowControlExit )
	FCOGuildLottery.UI.window:Row_OnMouseExit(rowControlExit)
    FCOGuildLottery.HideTooltip()
end

function FCOGL_UI_OnMouseUp( rowControlUp, button, upInside )
    if upInside then
        FCOGuildLottery.HideTooltip()
    end
end



------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--FCOGuildLottery UI functions

function fcoglUI.CreateRankingEntryForItem(item)
    return item
end


function fcoglUI.createWindow(doShow)
    doShow = doShow or false
    if (not FCOGuildLottery.UI.window) then
        FCOGuildLottery.UI.window = fcoglWindowClass:New(FCOGLFrame)
    end
    if doShow then
        FCOGuildLottery.UI.window:UpdateUI(FCOGL_TAB_STATE_LOADED)
    end
end

function fcoglUI.Show(doShow)
    fcoglUI.createWindow(true)
    local windowFrame = FCOGuildLottery.UI.window.frame
    if windowFrame == nil then return end
    if doShow ~= nil then
        if doShow == true then
            setWindowPosition(windowFrame)
        end
        windowFrame:SetHidden(not doShow)
        FCOGuildLottery.UI.windowShown = doShow
    else
        --local sceneName = fcoglUI.SCENE_NAME
        if (windowFrame:IsControlHidden()) then
            --SCENE_MANAGER:Show(sceneName)
            setWindowPosition(windowFrame)
            windowFrame:SetHidden(false)

            FCOGuildLottery.UI.windowShown = true
        else
            windowFrame:SetHidden(true)
            --SCENE_MANAGER:Hide(sceneName)

            FCOGuildLottery.UI.windowShown = false
        end
    end
end
FCOGuildLottery.ToggleUI = fcoglUI.Show
--TODO for debugging only
FCOGLT = fcoglUI.Show

function fcoglUI.OnWindowMoveStop()
    local frameControl = FCOGuildLottery.UI.window.frame
    if not frameControl then return end
    local settings = FCOGuildLottery.settingsVars.settings
    settings.UIwindow.left  = frameControl:GetLeft()
    settings.UIwindow.top   = frameControl:GetTop()
end

local function resetSortGroupHeader(currentTab)
--d("[WL.resetSortGroupHeader]")
    local UIwindow = FCOGuildLottery.UI.window
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
    if FCOGuildLottery.UI.window then
        local UIwindow = FCOGuildLottery.UI.window
        local settings = FCOGuildLottery.settingsVars.settings
        settings.UIwindow.sortKeys[currentTab]  = UIwindow.currentSortKey
        settings.UIwindow.sortOrder[currentTab] = UIwindow.currentSortOrder
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

    local normalSearchTexture = "/esoui/art/menubar/gamepad/gp_playermenu_icon_activityfinder.dds"
    local frameControl = self.frame
    ------------------------------------------------------------------------------------------------------------------------
    --SEARCH tab
	if fcoglUI.CurrentTab == WISHLIST_TAB_SEARCH then
        frameControl:GetNamedChild("TabSearch"):SetNormalTexture(normalSearchTexture)

--......................................................................................................................
        --Sets are not loaded yet -> Show load button
        if fcoglUI.CurrentState == FCOGL_TAB_STATE_LOADED then
            --WLW_UpdateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE) ..  " - " .. zo_strformat(GetString(WISHLIST_SETS_LOADED), 0))
            updateSceneFragmentTitle(WISHLIST_SCENE_NAME, TITLE_FRAGMENT, "Label", GetString(WISHLIST_TITLE) .. " - " .. GetString(WISHLIST_BUTTON_SEARCH_TT):upper())

            frameControl:GetNamedChild("TabList"):SetEnabled(true)

            self.frame:GetNamedChild("Reload"):SetHidden(false)
            self.frame:GetNamedChild("Search"):SetHidden(false)
            self.frame:GetNamedChild("SearchDrop"):SetHidden(false)
            self.frame:GetNamedChild("GuildsDrop"):SetHidden(false)
            self.frame:GetNamedChild("List"):SetHidden(false)
            self.searchBox:SetHidden(false)

            self.frame:GetNamedChild("Headers"):SetHidden(false)

            self.headerRank:SetHidden(false)
            --self.headerDate:SetHidden(false)
            self.headerName:SetHidden(false)
            --self.headerItem:SetHidden(false)
            self.headerPrice:SetHidden(false)
            self.headerTax:SetHidden(false)
            self.headerAmount:SetHidden(false)
            self.headerInfo:SetHidden(false)

            --Reset the sortGroupHeader
            resetSortGroupHeader(fcoglUI.CurrentTab)

            self:RefreshData()
        end
------------------------------------------------------------------------------------------------------------------------
	end
    self:updateSortHeaderAnchorsAndPositions(fcoglUI.CurrentTab, 200, 32)
end -- fcoglWindow:UpdateUI(state)

--Change the tabs at the WishList menu
function fcoglUI.SetTab(index)
    --Save the current sort order and key
    fcoglUI.saveSortGroupHeader(fcoglUI.CurrentTab)
    --Change to the new tab
    fcoglUI.CurrentTab = index
    --Clear the master list of the currently shown ZO_SortFilterList
    ZO_ScrollList_Clear(FCOGuildLottery.UI.window.list)
    FCOGuildLottery.UI.window.masterList = {}
    --Reset variable
    fcoglUI.comingFromSortScrollListSetupFunction = false
    --Update the UI (hide/show items)
    FCOGuildLottery.UI.window:UpdateUI(fcoglUI.CurrentState)
end