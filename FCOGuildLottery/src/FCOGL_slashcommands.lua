if FCOGL == nil then FCOGL = {} end
local FCOGuildLottery = FCOGL

local addonName = FCOGuildLottery.addonVars.addonName
local addonNamePre = "["..addonName.."]"

--Debug messages
local df    = FCOGuildLottery.df
local dfa   = FCOGuildLottery.dfa
local dfe   = FCOGuildLottery.dfe
local dfv   = FCOGuildLottery.dfv
local dfw   = FCOGuildLottery.dfw

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--SLASH COMMANDS
local function normalGuildMemeberDiceRollSlashCommand(guildIndex)
    local diceSidesGuild = FCOGuildLottery.RollTheDiceNormalForGuildMemberCheck(guildIndex, false)
    if diceSidesGuild ~= nil then
        FCOGuildLottery.RollTheDice(diceSidesGuild, false)
    end
end
FCOGuildLottery.normalGuildMemeberDiceRollSlashCommand = normalGuildMemeberDiceRollSlashCommand

function FCOGuildLottery.slashCommands()
    SLASH_COMMANDS["/diceg1"] = function()
        normalGuildMemeberDiceRollSlashCommand(1)
    end
    SLASH_COMMANDS["/diceg2"] = function()
        normalGuildMemeberDiceRollSlashCommand(2)
    end
    SLASH_COMMANDS["/diceg3"] = function()
        normalGuildMemeberDiceRollSlashCommand(3)
    end
    SLASH_COMMANDS["/diceg4"] = function()
        normalGuildMemeberDiceRollSlashCommand(4)
    end
    SLASH_COMMANDS["/diceg5"] = function()
        normalGuildMemeberDiceRollSlashCommand(5)
    end

    --Generic slash commands
    SLASH_COMMANDS["/dice"] = function(params)
        local diceSides = FCOGuildLottery.parseSlashCommandArguments(params, "/dice")
        if diceSides == nil or diceSides <= 0 then
            diceSides = FCOGL_MAX_DICE_SIDES
        end
        FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GENERIC
        FCOGuildLottery.RollTheDice(diceSides, false)
    end

    SLASH_COMMANDS["/dicelast"]             = function()
        local lastOutputText
        if FCOGuildLottery.currentlyUsedDiceRollGuildId ~= nil then
            lastOutputText = FCOGuildLottery.lastRolledGuildChatOutput
            if lastOutputText == nil then return end
        else
            lastOutputText = FCOGuildLottery.lastRolledChatOutput
            if lastOutputText == nil then return end
        end
        dfa( lastOutputText )
    end

    --Reset slash command for the guild sales lottery
    SLASH_COMMANDS["/newgsl"]               = FCOGuildLottery.NewGuildSalesLotterySlashCommand

    --Start new/Roll dice W<numberOfGuildSales> for guild sales lottery
    SLASH_COMMANDS["/gsl"]                  = FCOGuildLottery.GuildSalesLotterySlashCommand

    SLASH_COMMANDS["/gsllast"]              = FCOGuildLottery.GuildSalesLotteryLastRolledSlashCommand

    SLASH_COMMANDS["/fcogl"]                = function() FCOGuildLottery.ToggleUI() end
end
