-- init
ITaunted.TauntMessage = {}
ITaunted.TauntMessage.massTauntLastCasted = GetTime();

local function dump(o)
    if type(o) == 'table' then
        local s = '{ ';
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ',';
        end
        return s .. '} ';
    else
        return tostring(o);
    end
end

function ITaunted.TauntMessage.GetIcon(
    destRaidFlags
)
    local icon = {
        [0] = "",
        [1] = "{rt1}",
        [2] = "{rt2}",
        [4] = "{rt3}",
        [8] = "{rt4}",
        [16] = "{rt5}",
        [32] = "{rt6}",
        [64] = "{rt7}",
        [128] = "{skull}"
    }
    local parsedIcon = icon[destRaidFlags]

    if (parsedIcon) then
        return parsedIcon
    end

    return ''
end

function ITaunted.TauntMessage.isMassTaunt(spellId)
    local massTauntSpells = {
        -- Warrior
        386071, --Disrupting Shout
        1161,   --Challenging Shout
        223591, -- Challening Shout #2
        46276,  --Ravager taunt

        -- Paladin
        204079, -- Final Stand
        204077, -- Final Stand #2,
        406984, -- Final Stand #3,
        278804, -- Final Stand #4,
        31790,  --Righteous Defense

        -- Monk
        116189, --Provoke, talented
        196727, -- Provoke #?

        -- Priest
        236003, --Visage of Terror

        -- Warlock pets
        43263, -- Ghoul Taunt

        -- Engineering
        82407, -- Painful Shock - caused when backfired engineering trinket goes off

        -- Unknown
        -- BEES!
        442054, -- Bees!
        176646, -- Nether Attraction
    }

    if ITaunted.Helpers.tableContainsValue(massTauntSpells, spellId) then
        return true
    end
    return false
end

-- Checks if the spell is one of the taunt spells in game
function ITaunted.TauntMessage.isTaunt(spellId)
    local tauntSpells = {
        --Warrior
        355,    --Taunt
        145058, --Taunt #2
        138937, -- Taunt #3
        172907, --Taunt #4
        55981,  -- Mammoth Trumpet
        12765,  -- improved taunt

        --Death Knight
        51399,  --Death Grip for Blood (49576 is now just the pull effect)
        56222,  --Dark Command
        222409, --Dark Command NPC

        --Paladin
        62124,  --Hand of Reckoning
        221710, -- Hand of Reckoning #2

        --Druid
        6795, --Growl

        --Hunter
        20736,  --Distracting Shot
        146771, --Distracting Shot #2
        -- Pets
        2649,   --Growl #1
        214413, --Growl #2
        39270,  --Growl #3

        --Monk
        115546, --Provoke

        --Demon Hunter
        185245, --Torment

        -- Shaman
        204683, --Dark Whisper
        463161, -- Hand of Provocation
        460468, -- Hand of Provocation #2

        -- Warlock
        -- Pets
        17735,  --Suffering
        171014, -- Infernal, Seethe

        -- Engineering
        40224,  --Clintar agro pulse
        468371, -- Mark of the Hunted
    }

    if ITaunted.Helpers.tableContainsValue(tauntSpells, spellId) then
        return true
    end
    return false
end

function ITaunted.TauntMessage.playerHasValidTarget()
    if (UnitName("target") and not UnitPlayerControlled("target")) then
        return true
    end
    return false
end

function ITaunted.TauntMessage.handleCombatLogEvent(...)
    local _, event, _, _, _, _, _, _, destName, _, destRaidFlags =
        select(1, ...)
    local message = nil
    local spellId, _, _ = select(12, ...)
    local start, duration, enabled = GetSpellCooldown(spellId);

    if (start == nil or duration == nil or enabled == nil) then
        return;
    end

    local timeNow = GetTime()
    local canCastAgain = (start + duration - timeNow) < 0;


    if (ITaunted.TauntMessage.massTauntLastCasted + 10 < timeNow and canCastAgain and ITaunted.TauntMessage.isMassTaunt(spellId)) then
        if (event == "SPELL_AURA_APPLIED") then
            message = "Mass taunt"
        elseif (event == "SPELL_CAST_SUCCESS") then
            message = "Mass taunt"
        elseif (event == "SPELL_MISSED") then
            message = "Mass taunt"
        else
            message = nil
        end
        ITaunted.TauntMessage.massTauntLastCasted = timeNow;
    end

    if (canCastAgain and ITaunted.TauntMessage.isTaunt(spellId)) then
        if (event == "SPELL_AURA_APPLIED") then
            message = "Taunted " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " " .. destName
        elseif (event == "SPELL_CAST_SUCCESS") then
            message = "Taunted " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " " .. destName
        elseif (event == "SPELL_MISSED") then
            message = "Taunt failed on " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " " .. destName
        else
            message = nil
        end
    end

    if (message) then
        SendChatMessage(message);
        message = nil
    end
end

function ITaunted.TauntMessage.run()
    ITaunted.TauntMessage.Frame = CreateFrame("Frame")
    ITaunted.TauntMessage.Frame:RegisterEvent("ADDON_LOADED")
    ITaunted.TauntMessage.Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    ITaunted.TauntMessage.Frame:SetScript("OnEvent", function(self, event, arg1, ...)
        local playerGUID = UnitGUID("player")
        local _, instanceType = IsInInstance()

        if (event == "ADDON_LOADED" and arg1 == "iTaunted") then
            local date = C_AddOns.GetAddOnMetadata("ITaunted", "X-ResetVarsDate")

            -- reset out of date addons
            if (ITauntedVars and ITauntedVars.lastResetDate ~= date) then
                print('\124cffffcee2[i-Taunted]: Config had to be reset because of new functionality.')
                ITauntedVars = nil
            end

            if (ITauntedVars == nil) then
                ITauntedVars = {};
                ITauntedVars.isOn = true;
                ITauntedVars.debugMode = false;
                ITauntedVars.lastResetDate = date;
            end
        end

        if (event == "COMBAT_LOG_EVENT_UNFILTERED" and ITaunted.TauntMessage.playerHasValidTarget) then
            local _, _, _, sourceGUID = CombatLogGetCurrentEventInfo()
            if (sourceGUID == playerGUID and instanceType == "raid") then
                ITaunted.TauntMessage.handleCombatLogEvent(CombatLogGetCurrentEventInfo())
            end

            if (ITauntedVars and sourceGUID == playerGUID and ITauntedVars.debugMode == true) then
                ITaunted.TauntMessage.handleCombatLogEvent(CombatLogGetCurrentEventInfo())
            end
        end
    end
    )
end

local function ITaunted_DebugOn()
    print('\124cffffcee2[i-Taunted]: Debug is now: ON.')
    ITauntedVars.debugMode = true
end

local function ITaunted_DebugOff()
    print('\124cffffcee2[i-Taunted]: Debug is now: OFF.')
    ITauntedVars.debugMode = false;
end

local function ITaunted_On()
    print('\124cffffcee2[i-Taunted]: i-Taunted is now: ON.')
    ITauntedVars.isOn = true;
end

local function ITaunted_Off()
    print('\124cffffcee2[i-Taunted]: i-Taunted is now: OFF.')
    ITauntedVars.isOn = false;
end


local function ITaunted_Init(msg)
    -- pattern matching that skips leading whitespace and whitespace between cmd and args
    -- any whitespace at end of args is retained
    local _, _, cmd, _ = string.find(msg, "%s?(%w+)%s?(.*)")

    if cmd == "reset" then
        ITauntedVars = nil;
        if (ITauntedVars == nil) then
            print('\124cffffcee2[i-Taunted]: Settings have been reset. You should now type /reload.')
        end
    elseif cmd == "on" then
        ITaunted_On();
    elseif cmd == "off" then
        ITaunted_Off();
    elseif cmd == "debug" then
        if (ITauntedVars and ITauntedVars.debugMode == true) then
            ITaunted_DebugOff();
        elseif (ITauntedVars and ITauntedVars.debugMode == false) then
            ITaunted_DebugOn();
        end

        dump(ITauntedVars);
    elseif cmd == "dump" then
        dump(ITauntedVars);
    else
        print('\124cffffcee2[i-Taunted]: Available commands are: on, off, reset, debug, dump')
    end
end

SlashCmdList["ITAUNTED"] = ITaunted_Init;
SLASH_ITAUNTED1 = "/itaunted"
ITaunted.TauntMessage.run();
