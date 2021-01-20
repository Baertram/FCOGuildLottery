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

function FCOGuildLottery.slashCommands()
    SLASH_COMMANDS["/diceg1"] = function()
        --Get the members of guild1
        local diceSidesGuild1 = FCOGuildLottery.GetGuildMemberCount(1)
        if not diceSidesGuild1 or diceSidesGuild1 == 0 then return end
        FCOGuildLottery.currentlyUsedDiceRollGuildName, FCOGuildLottery.currentlyUsedDiceRollGuildId = FCOGuildLottery.GetGuildName(1, false, true)
        FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
        FCOGuildLottery.RollTheDice(diceSidesGuild1, false)
    end
    SLASH_COMMANDS["/diceg2"] = function()
        --Get the members of guild2
        local diceSidesGuild2 = FCOGuildLottery.GetGuildMemberCount(2)
        if not diceSidesGuild2 or diceSidesGuild2 == 0 then return end
        FCOGuildLottery.currentlyUsedDiceRollGuildName, FCOGuildLottery.currentlyUsedDiceRollGuildId = FCOGuildLottery.GetGuildName(2, false, true)
        FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
        FCOGuildLottery.RollTheDice(diceSidesGuild2, false)
    end
    SLASH_COMMANDS["/diceg3"] = function()
        --Get the members of guild3
        local diceSidesGuild3 = FCOGuildLottery.GetGuildMemberCount(3)
        if not diceSidesGuild3 or diceSidesGuild3 == 0 then return end
        FCOGuildLottery.currentlyUsedDiceRollGuildName, FCOGuildLottery.currentlyUsedDiceRollGuildId = FCOGuildLottery.GetGuildName(3, false, true)
        FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
        FCOGuildLottery.RollTheDice(diceSidesGuild3, false)
    end
    SLASH_COMMANDS["/diceg4"] = function()
        --Get the members of guild4
        local diceSidesGuild4 = FCOGuildLottery.GetGuildMemberCount(4)
        if not diceSidesGuild4 or diceSidesGuild4 == 0 then return end
        FCOGuildLottery.currentlyUsedDiceRollGuildName, FCOGuildLottery.currentlyUsedDiceRollGuildId = FCOGuildLottery.GetGuildName(4, false, true)
        FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
        FCOGuildLottery.RollTheDice(diceSidesGuild4, false)
    end
    SLASH_COMMANDS["/diceg5"] = function()
        --Get the members of guild5
        local diceSidesGuild5 = FCOGuildLottery.GetGuildMemberCount(5)
        if not diceSidesGuild5 or diceSidesGuild5 == 0 then return end
        FCOGuildLottery.currentlyUsedDiceRollGuildName, FCOGuildLottery.currentlyUsedDiceRollGuildId = FCOGuildLottery.GetGuildName(5, false, true)
        FCOGuildLottery.currentlyUsedDiceRollType = FCOGL_DICE_ROLL_TYPE_GUILD_GENERIC
        FCOGuildLottery.RollTheDice(diceSidesGuild5, false)
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
        if FCOGuildLottery.lastRolledChatOutput == nil then return end
        dfa( FCOGuildLottery.lastRolledChatOutput )
    end

    --Reset slash command for the guild sales lottery
    SLASH_COMMANDS["/newgsl"]               = FCOGuildLottery.NewGuildSalesLotterySlashCommand

    --Start new/Roll dice W<numberOfGuildSales> for guild sales lottery
    SLASH_COMMANDS["/gsl"]                  = FCOGuildLottery.GuildSalesLotterySlashCommand

    SLASH_COMMANDS["/gsllast"]              = FCOGuildLottery.GuildSalesLotteryLastRolledSlashCommand

    SLASH_COMMANDS["/fcogl"]                = function() FCOGuildLottery.ToggleUI() end
end
