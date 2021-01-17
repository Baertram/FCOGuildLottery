if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

local addonVars = FCOGuildLottery.addonVars
local addonNamePre = FCOGuildLottery.addonNamePre

local ldl = LibDebugLogger
FCOGuildLottery.LDL = ldl

local logger
local subLoggerVerbose

--DEBUG FUNCTIONS
local function isDebuggingEnabled()
    local settings = FCOGuildLottery.settingsVars.settings
    return settings.debug
end

local function createLogger()
    logger = ldl:Create(addonVars.addonName)
    logger:SetEnabled(true)
    subLoggerVerbose = logger:Create("verbose")
    subLoggerVerbose:SetEnabled(true)
end

local function checkLogger()
    if ldl ~= nil then
        if logger == nil then
            createLogger()
        end
        return true
    end
    return false
end

--Info message
local function dfa(str, ...)
    if checkLogger() then
        logger:Info(string.format(str, ...))
    else
        d(addonNamePre .. " " .. string.format(str, ...))
    end
end
FCOGuildLottery.dfa = dfa

--Error message
local function dfe(str, ...)
    if checkLogger() then
        logger:Error(string.format(str, ...))
    else
        d(addonNamePre .. " ERROR " .. string.format(str, ...))
    end
end
FCOGuildLottery.dfe = dfe

--Warning debug message formatted
local function dfw(str, ...)
    if not isDebuggingEnabled() then return end
    if checkLogger() then
        logger:Warn(string.format(str, ...))
    else
        d(addonNamePre .. " WARNING " .. string.format(str, ...))
    end
end
FCOGuildLottery.dfw = dfw

--Verbose debug message formatted
local function dfv(str, ...)
    if not isDebuggingEnabled() then return end
    if checkLogger() then
        --subLoggerVerbose:Verbose(string.format(str, ...)) Not working? Why not?
        subLoggerVerbose:Verbose(string.format(str, ...)) --:Verbose() not working? Why not?
    else
        d(addonNamePre .. " VERBOSE " .. string.format(str, ...))
    end
end
FCOGuildLottery.dfv = dfv

--Debug message formatted
local function df(str, ...)
    if not isDebuggingEnabled() then return end
    if checkLogger() then
        logger:Debug(string.format(str, ...))
    else
        d(addonNamePre .. " " .. string.format(str, ...))
    end
end
FCOGuildLottery.df = df
