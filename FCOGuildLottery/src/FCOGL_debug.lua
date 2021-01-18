if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

local addonVars = FCOGuildLottery.addonVars
local addonNamePre = FCOGuildLottery.addonNamePre

local ldl = LibDebugLogger
local logger
local subLoggerVerbose

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--DEBUG FUNCTIONS

local function isDebuggingEnabled()
    local settings = FCOGuildLottery.settingsVars.settings
    return settings.debug
end

local function isExtraChatOutputEnabled()
   local settings = FCOGuildLottery.settingsVars.settings
--d("isExtraChatOutputEnabled - debug: " ..tostring(settings.debug) .. ", LibDebugLogger: " ..tostring(LibDebugLogger~=nil) .. ", DebugLogViewer: " ..tostring(DebugLogViewer~=nil))
    if not settings.debug or LibDebugLogger == nil or DebugLogViewer ~= nil then return false end
--d(">debugToChatToo: " ..tostring(settings.debugToChatToo))
    return settings.debugToChatToo
end

local function createLogger()
--d("[FCOGL]Create logger")
    logger = ldl:Create(addonVars.addonName)
    logger:SetEnabled(true)


    subLoggerVerbose = logger:Create("verbose")
    subLoggerVerbose:SetEnabled(true)

    FCOGuildLottery.logger = logger
end

local function checkLogger(isFirst)
    isFirst = isFirst or false
--d("[FCOGL]Check logger - isFirstCall: " ..tostring(isFirst))
    if ldl == nil then
        ldl = LibDebugLogger
        FCOGuildLottery.LDL = ldl
    end
    if ldl ~= nil then
        if logger == nil then
            createLogger()
        end
        return true
    end
    return false
end

--Create the logger(s)
checkLogger(true)

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--Info message
local function dfa(str, ...)
    local noLogger = true
    if logger ~= nil then
        logger:Info(string.format(str, ...))
        noLogger = false
    end
    if noLogger == true or isExtraChatOutputEnabled() then
        d(addonNamePre .. " " .. string.format(str, ...))
    end
end
FCOGuildLottery.dfa = dfa

--Error message
local function dfe(str, ...)
    local noLogger = true
    if logger ~= nil then
        logger:Error(string.format(str, ...))
        noLogger = false
    end
    if noLogger == true or isExtraChatOutputEnabled() then
        d(addonNamePre .. " ERROR " .. string.format(str, ...))
    end
end
FCOGuildLottery.dfe = dfe

--Warning debug message formatted
local function dfw(str, ...)
    if not isDebuggingEnabled() then return end
    local noLogger = true
    if logger ~= nil then
        logger:Warn(string.format(str, ...))
        noLogger = false
    end
    if noLogger == true or isExtraChatOutputEnabled() then
        d(addonNamePre .. " WARNING " .. string.format(str, ...))
    end
end
FCOGuildLottery.dfw = dfw

--Verbose debug message formatted
local function dfv(str, ...)
--[[
    if not isDebuggingEnabled() then return end
    local noLogger = true
    if logger ~= nil and subLoggerVerbose ~= nil then
        subLoggerVerbose:Verbose(string.format(str, ...)) Not working as long as Verbose is not explicitly enabled in LibDebugLogger/StartUpConfig.lua!
        noLogger = false
    end
    if noLogger == true or isExtraChatOutputEnabled() then
        d(addonNamePre .. " VERBOSE " .. string.format(str, ...))
    end
]]
end
FCOGuildLottery.dfv = dfv

--Debug message formatted
local function df(str, ...)
    if not isDebuggingEnabled() then return end
    local noLogger = true
    if logger ~= nil then
        logger:Debug(string.format(str, ...))
        noLogger = false
    end
    if noLogger == true or isExtraChatOutputEnabled() then
        d(addonNamePre .. " " .. string.format(str, ...))
    end
end
FCOGuildLottery.df = df
