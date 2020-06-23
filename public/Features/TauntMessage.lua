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

-- Checks if the spell is one of the taunt spells in game
function ITaunted.TauntMessage.isTaunt(spellId)
    local tauntSpells = {
            --Warrior
            355, --Taunt

            --Death Knight
            51399, --Death Grip for Blood (49576 is now just the pull effect)
            56222, --Dark Command

            --Paladin
            62124, --Hand of Reckoning

            --Druid
            6795, --Growl

            --Hunter
            20736, --Distracting Shot

            --Monk
            115546, --Provoke

            --Demon Hunter
            185245, --Torment

            --Paladin
            204079, --Final Stand
    }

     if ITaunted.Helpers.tableContainsValue(tauntSpells, spellId) then
        return true
    end
    return false
end

function ITaunted.TauntMessage.playerHasValidTarget()
    if(UnitName("target") and not UnitPlayerControlled("target")) then
        return true
    end
    return false
end



function ITaunted.TauntMessage.handleCombatLogEvent(...)
    local sourceGUID
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destRaidFlags = select(1, ...)
    local spellId, spellName, spellSchool = select(12, ...)
    local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(15, ...)
    local message
    local isSameAslastMessage
    local timeNow = GetTime()
    local isSameTimeCasted = ITaunted.TauntMessage.lastTimeCasted == timeNow


    if (ITaunted.TauntMessage.isTaunt(spellId)) then
        if (event == "SPELL_AURA_APPLIED") then
            message = "Taunted " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " " .. destName
        elseif (event == "SPELL_CAST_SUCCESS") then
            message = "Taunted " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " " .. destName
        elseif (event == "SPELL_MISSED") then
            message = "Taunt failed on " .. ITaunted.TauntMessage.GetIcon(destRaidFlags) .. " "  .. destName
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
    print("ITauntedd loaded")

    ITaunted.TauntMessage.Frame = CreateFrame("Frame")
    ITaunted.TauntMessage.Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    ITaunted.TauntMessage.Frame:SetScript("OnEvent", function (self, event, ...)
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