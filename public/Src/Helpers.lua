ITaunted = {}

ITaunted.Helpers = {}

function ITaunted.Helpers.parseText(s, tab)
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

function getCharacterinfo(target)
    local genderTable = { "neutral or unknown", "male", "female" };
    local playerClass, englishClass, classIndex = UnitClass(target);
    local name, upName, level = UnitName(target)
    local unitLevel = UnitLevel(target)
    local gender = genderTable[UnitSex(target)]
    local race, raceEn = UnitRace(target);

    return name, gender, playerClass, race, unitLevel
end

function ITaunted.Helpers.tableContainsValue(table, val)
    for index, value in ipairs(table) do
        if value == val then
            return true
        end
    end

    return false
end

function ITaunted.Helpers.GetPlayerInformation()
    return getCharacterinfo("player")
end
