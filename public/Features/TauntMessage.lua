-- init
ITaunted.TauntMessage = {}
ITaunted.TauntMessage.lastMessage = ""
ITaunted.TauntMessage.lastTimeCasted = GetTime()

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
        46276,  --Ravager taunt

        -- Paladin
        204079, -- Final Stand

        -- Monk
        116189, --Provoke, talented
        196727, -- Provoke #?

        -- Priest
        236003, --Visage of Terror

        -- Warlock
        -- Pets
        43263, -- Ghoul Taunt

        -- Engineering
        82407, -- Painful Shock - caused when backfired engineering trinket goes off

        -- BEES!
        442054, -- Bees!

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

        --Death Knight
        51399,  --Death Grip for Blood (49576 is now just the pull effect)
        56222,  --Dark Command
        222409, --Dark Command NPC

        --Paladin
        62124, --Hand of Reckoning

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

        -- Warlock
        -- Pets
        17735, --Suffering
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
    local sourceGUID
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destRaidFlags =
        select(1, ...)
    local spellId, spellName, spellSchool = select(12, ...)
    local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(15, ...)
    local message
    local isSameAslastMessage
    local timeNow = GetTime()
    local isSameTimeCasted = ITaunted.TauntMessage.lastTimeCasted == timeNow


    if (ITaunted.TauntMessage.isMassTaunt(spellId)) then
        message = "Mass taunting..."
    end

    if (ITaunted.TauntMessage.isTaunt(spellId)) then
        if (event == "SPELL_AURA_APPLIED") then
            message = "Taunted " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " " .. destName
        elseif (event == "SPELL_CAST_SUCCESS") then
            message = "Taunted " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " " .. destName
        elseif (event == "SPELL_MISSED") then
            message = "Taunt failed on " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " " .. destName
        end

        isSameAslastMessage = ITaunted.TauntMessage.lastMessage == message

        -- debounce the message
        if (not isSameAslastMessage or not isSameTimeCasted) then
            SendChatMessage(message, "SAY", nil, 1)
            ITaunted.TauntMessage.lastMessage = message
            ITaunted.TauntMessage.lastTimeCasted = GetTime()
        end
    end
end

function ITaunted.TauntMessage.run()
    ITaunted.TauntMessage.Frame = CreateFrame("Frame")
    ITaunted.TauntMessage.Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    ITaunted.TauntMessage.Frame:SetScript("OnEvent", function(self, event, ...)
        local playerGUID = UnitGUID("player")
        local inInstance, instanceType = IsInInstance()

        if (event == "COMBAT_LOG_EVENT_UNFILTERED" and ITaunted.TauntMessage.playerHasValidTarget) then
            local timestamp, type, hideCaster, sourceGUID = CombatLogGetCurrentEventInfo()
            if (sourceGUID == playerGUID and instanceType == "raid") then
                ITaunted.TauntMessage.handleCombatLogEvent(CombatLogGetCurrentEventInfo())
            end
        end
    end
    )
end

-- Load it...
ITaunted.TauntMessage.run()
