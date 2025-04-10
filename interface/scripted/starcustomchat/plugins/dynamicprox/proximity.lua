require("/interface/scripted/starcustomchat/plugin.lua")

-- Need this to copy message tables.
local function copy(obj, seen)
    if type(obj) ~= "table" then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do
        res[copy(k, s)] = copy(v, s)
    end
    return res
end

local function trim(s)
    local l = 1
    while string.sub(s, l, l) == " " do
        l = l + 1
    end
    local r = #s
    while string.sub(s, r, r) == " " do
        r = r - 1
    end
    return string.sub(s, l, r)
end

local function sccrpInstalled()
    if root.assetExists then
        return root.assetExists("/interface/scripted/starcustomchat/plugins/proximitychat/proximity.lua")
    else
        return not not root.assetOrigin("/interface/scripted/starcustomchat/plugins/proximitychat/proximity.lua")
    end
end

dynamicprox = PluginClass:new({
    name = "dynamicprox",
})

local DynamicProxPrefix = "^DynamicProx,reset;"
local AuthorIdPrefix = "^author="
local DefaultLangPrefix = ",defLang="
local TagSuffix = ",reset;"
local AnnouncementPrefix = "^clear;!!^reset;"
local randSource = sb.makeRandomSource()
local DEBUG = false
local DEBUG_PREFIX = "[DynamicProx::Debug] "

-- FezzedOne: From FezzedTech.
local function rollDice(die) -- From https://github.com/brianherbert/dice/, with modifications.
    if type(die) == "string" then
        local rolls, sides, modOperation, modifier
        local numberDie = tonumber(die)
        if numberDie then
            sides = math.floor(numberDie)
            if sides < 1 then return nil end
            rolls = 1
            modOperation = "+"
            modifier = 0
        else
            local i, j = string.find(die, "d")
            if not i then return nil end
            if i == 1 then
                rolls = 1
            else
                rolls = tonumber(string.sub(die, 0, (j - 1)))
            end

            local afterD = string.sub(die, (j + 1), string.len(die))
            local i_1, j_1 = string.find(afterD, "%d+")
            local i_2, _ = string.find(afterD, "^[%+%-%*/]%d+")
            local afterSides
            if j_1 and not i_2 then
                sides = tonumber(string.sub(afterD, i_1, j_1))
                j = j_1
                afterSides = string.sub(afterD, (j + 1), string.len(afterD))
            else
                sides = 6
                afterSides = afterD
            end
            if sides < 1 then return nil end

            if string.len(afterSides) == 0 then
                modOperation = "+"
                modifier = 0
            else
                modOperation = string.sub(afterSides, 1, 1)
                modifier = tonumber(string.sub(afterSides, 2, string.len(afterSides)))
            end

            if not modifier then return nil end
        end

        -- Make sure dice are properly random.
        --changed RNG to sb.makerandomsource to keep other rng features untouched
        randSource:init(math.floor(os.clock() * 100000000000))

        local roll, total = 0, 0
        while roll < rolls do
            total = total + randSource:randInt(1, sides)
            roll = roll + 1
        end

        -- Finished with our rolls, now add/subtract our modifier
        if modOperation == "+" then
            total = math.floor(total + modifier)
        elseif modOperation == "-" then
            total = math.floor(total - modifier)
        elseif modOperation == "*" then
            total = math.floor(total * modifier)
        elseif modOperation == "/" then
            total = math.floor(total / modifier)
        else
            return nil
        end

        return total
    else
        return nil
    end
end

function dynamicprox:init() self:_loadConfig() end

function dynamicprox:addCustomCommandPreview(availableCommands, substr)
    if string.find("/newlangitem", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/newlangitem",
            description = "commands.newlangitem.desc",
            data = "/newlangitem",
            color = nil,
        })
    elseif string.find("/addtypo", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/addtypo",
            description = "commands.addtypo.desc",
            data = "/addtypo",
        })
    elseif string.find("/removetypo", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/removetypo",
            description = "commands.removetypo.desc",
            data = "/removetypo",
        })
    elseif string.find("/toggletypos", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/toggletypos",
            description = "commands.toggletypos.desc",
            data = "/toggletypos",
        })
    elseif string.find("/checktypo", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/checktypo",
            description = "commands.checktypo.desc",
            data = "/checktypo",
        })
        --this one is broken, not sure why
    elseif string.find("/showtypos", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/showtypos",
            description = "commands.showtypos.desc",
            data = "/showtypos",
        })
    elseif string.find("/proxlocal", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/proxlocal",
            description = "commands.proxlocal.desc",
            data = "/proxlocal",
        })
    elseif string.find("/sendlocal", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/sendlocal",
            description = "commands.sendlocal.desc",
            data = "/sendlocal",
        })
    elseif string.find("/dynamicsccrp", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/dynamicsccrp",
            description = "commands.dynamicsccrp.desc",
            data = "/dynamicsccrp",
        })
    elseif string.find("/proxooc", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/proxooc",
            description = "commands.proxooc.desc",
            data = "/proxooc",
        })
    elseif string.find("/timezone", substr, nil, true) then
        table.insert(availableCommands, {
            name = "/timezone",
            description = "commands.timezone.desc",
            data = "/timezone",
        })
    end
end

local function checktypo(toggle)
    local typoTable = player.getProperty("typos", {})
    local typoStatus

    if typoTable["typosActive"] == true then
        if toggle then
            typoTable["typosActive"] = false
            typoStatus = "off"
        else
            typoStatus = "on"
        end
    else
        if toggle then
            typoTable["typosActive"] = true
            typoStatus = "on"
        else
            typoStatus = "off"
        end
    end
    player.setProperty("typos", typoTable)
    return "Typo correction is " .. typoStatus
end

local function splitStr(inputstr, sep) --replaced this with a less efficient linear search in order to be system agnostic
    if sep == nil then sep = "%s" end
    local arg = ""
    local t = {}
    local qFlag = false
    for c in inputstr:gmatch(".") do
        if c:match(sep) and not qFlag and #arg > 0 then
            arg = trim(arg)
            table.insert(t, arg)
            arg = ""
        elseif c == '"' then
            if qFlag then
                table.insert(t, arg)
                qFlag = false
                arg = ""
            else
                qFlag = true
            end
        else
            arg = arg .. c
        end
    end
    table.insert(t, arg)
    return t
end

local function getDefaultLang()
    local langItem = player.getItemWithParameter("defaultLang", true) --checks for an item with the "defaultLang" parameter
    local defaultKey
    if langItem == nil then
        defaultKey = "!!"
    else
        defaultKey = langItem["parameters"]["langKey"] or "!!"
    end
    return defaultKey
end

--this messagehandler function runs if the chat preview exists
function dynamicprox:registerMessageHandlers(shared) --look at this function in irden chat's editchat thing
    starcustomchat.utils.setMessageHandler("/proxdebug", function(_, _, data)
        if string.lower(data) == "on" then
            DEBUG = true
            return "^green;ENABLED^reset; debug mode for Dynamic Proximity Chat"
        elseif string.lower(data) == "off" then
            DEBUG = false
            return "^red;DISABLED^reset; debug mode for Dynamic Proximity Chat"
        else
            return "Debug mode for Dynamic Proximity Chat is "
                .. (DEBUG and "^green;ENABLED" or "^red;DISABLED")
                .. "^reset;. To change this setting, pass ^orange;on^reset; or ^orange;off^reset; to this command."
        end
    end)
    starcustomchat.utils.setMessageHandler("/timezone", function(_, _, data)
        local splitArgs = splitStr(data, " ")
        local daylight = true
        local zoneStr = splitArgs[1] or nil
        if splitArgs[2] ~= "true" then daylight = false end
        local tzTable = {
            ["HST"] = -10,
            ["AKST"] = -9,
            ["PST"] = -8,
            ["MST"] = -7,
            ["CST"] = -6,
            ["EST"] = -5,
            ["AST"] = -4,
            ["UTC"] = 0,
            ["Z"] = 0,
            ["AFT"] = 4.5,
            ["CET"] = 1,
            ["EET"] = 2,
            ["MSK"] = 3,
            ["ACST"] = 9.5,
            ["AEST"] = 10,
        }
        if zoneStr == nil or #zoneStr < 1 then
            local curZone = root.getConfiguration("DynamicProxChat::timeZone") or 0
            zoneStr = string.format("%.0f:%.2d", math.floor(curZone), (curZone % 1 * 60))
            if curZone > 0 then zoneStr = "+" .. zoneStr end
            return "Current time offset is ^#fe7;" .. zoneStr .. "^reset;"
        elseif tzTable[zoneStr:upper()] == nil then
            return 'Timezone "^#fe7;'
                .. zoneStr
                .. "^reset;\" doesn't exist or isn't supported. Try using a timezone abbreviation (UTC, CET, EST, CST, MST, PST, etc)"
        else
            zoneStr = zoneStr:upper()
            local newTime = tzTable[zoneStr] or 0
            local timingStr = ""
            if daylight then
                zoneStr = zoneStr .. "+1 (DST)"
                newTime = newTime + 1
            end
            if newTime > 0 then timingStr = "+" end
            timingStr = timingStr .. string.format("%.0f:%.2d", math.floor(newTime), (newTime % 1 * 60))
            root.setConfiguration("DynamicProxChat::timeZone", newTime)
            return "Timezone set to " .. zoneStr .. " (^#fe7;" .. timingStr .. "^reset;)"
        end
    end)
    starcustomchat.utils.setMessageHandler("/dynamicsccrp", function(_, _, data)
        if string.lower(data) == "on" then
            root.setConfiguration("DynamicProxChat::handleSccrpProx", true)
            return "^green;ENABLED^reset; handling SCCRP Proximity messages as dynamic proximity chat"
        elseif string.lower(data) == "off" then
            root.setConfiguration("DynamicProxChat::handleSccrpProx", false)
            return "^red;DISABLED^reset; handling SCCRP Proximity messages as dynamic proximity chat"
        else
            local enabled = root.getConfiguration("DynamicProxChat::handleSccrpProx") or false
            return "Handling SCCRP Proximity messages as dynamic proximity chat is "
                .. (enabled and "^green;ENABLED" or "^red;DISABLED")
                .. "^reset;. To change this setting, pass ^orange;on^reset; or ^orange;off^reset; to this command."
        end
    end)
    starcustomchat.utils.setMessageHandler("/proxooc", function(_, _, data)
        if string.lower(data) == "on" then
            root.setConfiguration("DynamicProxChat::proximityOoc", true)
            return "^green;ENABLED^reset; handling (( )) as range-limited OOC chat"
        elseif string.lower(data) == "off" then
            root.setConfiguration("DynamicProxChat::proximityOoc", false)
            return "^red;DISABLED^reset; handling (( )) as range-limited OOC chat"
        else
            local enabled = root.getConfiguration("DynamicProxChat::proximityOoc") or false
            return "Handling (( )) as range-limited OOC chat is "
                .. (enabled and "^green;ENABLED" or "^red;DISABLED")
                .. "^reset;. To change this setting, pass ^orange;on^reset; or ^orange;off^reset; to this command."
        end
    end)
    starcustomchat.utils.setMessageHandler("/proxlocal", function(_, _, data)
        if string.lower(data) == "on" then
            root.setConfiguration("DynamicProxChat::localChatIsProx", true)
            return "^green;ENABLED^reset; handling local chat as proximity chat"
        elseif string.lower(data) == "off" then
            root.setConfiguration("DynamicProxChat::localChatIsProx", false)
            return "^red;DISABLED^reset; handling local chat as proximity chat"
        else
            local enabled = root.getConfiguration("DynamicProxChat::localChatIsProx") or false
            return "Handling local chat as proximity chat is "
                .. (enabled and "^green;ENABLED" or "^red;DISABLED")
                .. "^reset;. To change this setting, pass ^orange;on^reset; or ^orange;off^reset; to this command."
        end
    end)
    starcustomchat.utils.setMessageHandler("/sendlocal", function(_, _, data)
        if string.lower(data) == "on" then
            root.setConfiguration("DynamicProxChat::sendProxChatInLocal", true)
            return "^green;ENABLED^reset; sending proximity chat as local chat"
        elseif string.lower(data) == "off" then
            root.setConfiguration("DynamicProxChat::sendProxChatInLocal", false)
            return "^red;DISABLED^reset; sending proximity chat as local chat"
        else
            local enabled = root.getConfiguration("DynamicProxChat::sendProxChatInLocal") or false
            return "Sending proximity chat as local chat is "
                .. (enabled and "^green;ENABLED" or "^red;DISABLED")
                .. "^reset;. To change this setting, pass ^orange;on^reset; or ^orange;off^reset; to this command."
        end
    end)
    starcustomchat.utils.setMessageHandler("/showtypos", function(_, _, data)
        local typoTable = player.getProperty("typos", {})
        if typoTable == nil then return "You have no corrections or typos saved. Use /addtypo to make one." end

        local rtStr = "Typos and corrections:^#2ee;"
        local tyTableLen = 0
        local typosActive = "off"
        for k, v in pairs(typoTable) do
            if k ~= "typosActive" then
                rtStr = rtStr .. " {" .. k .. " -> " .. v .. "}"
                tyTableLen = tyTableLen + 1
            elseif v then
                typosActive = "on"
            end
        end
        rtStr = rtStr .. "^reset;. Typo correction is " .. typosActive .. "."

        if tyTableLen == 0 then rtStr = "You have no corrections or typos saved. Use /addtypo to make one." end
        return rtStr
    end)
    starcustomchat.utils.setMessageHandler("/checktypo", function(_, _, data) return checktypo(false) end)
    starcustomchat.utils.setMessageHandler("/toggletypos", function(_, _, data) return checktypo(true) end)
    starcustomchat.utils.setMessageHandler("/addtypo", function(_, _, data)
        --add a typo correction to the typos table in player data, or replace it if it already exists
        -- local typo, correction = chat.parseArguments(data)
        local splitArgs = splitStr(data, " ")
        local typo, correction = splitArgs[1], splitArgs[2]

        if typo == nil or correction == nil then return "Missing arguments for /addtypo, need {typo, correction}" end
        local typoTable = player.getProperty("typos", {})

        typoTable[typo] = correction
        player.setProperty("typos", typoTable)
        return 'Typo "' .. typo .. '" added as "' .. correction .. '".'
    end)
    starcustomchat.utils.setMessageHandler("/removetypo", function(_, _, data)
        --add a typo correction to the typos table in player data, or replace it if it already exists
        -- local typo = chat.parseArguments(data)
        local typo = splitStr(data, " ")[1]
        local typoTable = player.getProperty("typos", false)

        if typo == nil then return "Missing arguments for /removetypo, need {typo}" end

        if typoTable then
            typoTable[typo] = nil
            player.setProperty("typos", typoTable)
            return 'Typo "' .. typo .. '" removed.'
        else
            return "No typos found."
        end
    end)

    starcustomchat.utils.setMessageHandler("/newlangitem", function(_, _, data)
        -- FezzedOne: Whitespace in language names is now supported (only on xStarbound).
        -- Okay, Captain Salt, fair enough. I'll do it only on xSB because oSB and SE convert argument types implicitly.
        local splitArgs = xsb and chat.parseArguments(data) or splitStr(data, " ")
        local langName, langKey, langLevel, isDefault, color =
            (splitArgs[1] or nil),
            (splitArgs[2] or nil),
            (tonumber(splitArgs[3]) or 10),
            (splitArgs[4] or nil),
            (splitArgs[5] or nil)

        if langKey == nil or langName == nil then
            return "Missing arguments for /newlangitem, need {name, code, count, automatic, [hex color]}"
        end
        if isDefault == nil then isDefault = false end

        if color ~= nil then
            if not color:match("#") then color = "#" .. color end
            if #color > 7 then color = color:sub(1, 7) end
        end
        langKey = langKey:upper()
        langKey = langKey:gsub("[%[%]]", "")

        langLevel = math.max(1, math.min(langLevel, 10))
        local itemName = "inferiorbrain"
        local itemDesc = "Allows the user to understand " .. langName .. " [" .. langKey .. "]"
        local shortDesc = "[" .. langKey .. "] " .. langName .. " Aptitude"
        local itemRarity = "Uncommon"
        local itemImage = "inferiorbrain.png"

        if isDefault ~= nil and (isDefault == "true") then
            isDefault = true
            itemRarity = "Rare"
            itemName = "brain"
            itemDesc = "!Default, will automatically apply! " .. itemDesc
            itemImage = "brain.png"
        else
            isDefault = false
        end

        local itemData = {
            name = itemName,
            count = langLevel,
            parameters = {
                inventoryIcon = itemImage,
                description = itemDesc,
                rarity = itemRarity,
                maxStack = 10,
                shortdescription = shortDesc,
                langKey = langKey,
                defaultLang = isDefault,
                color = color,
            },
        }

        player.giveItem(itemData)
        return "Language " .. langName .. " added, use [" .. langKey .. "] to use it."
    end)
end

function dynamicprox:onSendMessage(data)
    --think about running this in local to allow players without the mod to still see messages

    if data.mode == "Prox" then
        -- data.time = systemTime() this is where i'd add time if i wanted it
        data.proxRadius = self.proxRadius
        local function sendMessageToPlayers()
            local position = player.id() and world.entityPosition(player.id())

            -- FezzedOne: Dice roll handling.
            local rawText = data.text
            local newStr = ""
            local cInd = 1
            while cInd <= #rawText do
                local c = rawText:sub(cInd, cInd)
                if c == "\\" then -- Handle escapes.
                    newStr = newStr .. "\\" .. rawText:sub(cInd + 1, cInd + 1)
                    cInd = cInd + 1
                elseif c == "|" then
                    local fStart = cInd
                    local fEnd = rawText:find("|", cInd + 1)

                    if fStart ~= nil and fEnd ~= nil then
                        -- FezzedOne: Replaced dice roller with the more flexible one from FezzedTech.
                        local diceResults = rawText:sub(fStart + 1, fEnd)
                        diceResults = diceResults:gsub("[ ]*", ""):gsub(
                            "(.-)[,|]",
                            function(die) return tostring(rollDice(die) or "n/a") .. ", " end
                        )
                        newStr = newStr .. "|" .. diceResults:sub(1, -3) .. "|"
                        cInd = fEnd
                    else
                        newStr = newStr .. "|"
                    end
                else
                    newStr = newStr .. c
                end
                cInd = cInd + 1
            end

            data.text = newStr

            -- FezzedOne: Global OOC chat.
            local globalOocStrings = {}
            data.text = data.text:gsub("\\%(%(%(", "(^;(("):gsub("%(%(%((.-)%)%)%)", function(s)
                table.insert(globalOocStrings, s)
                return ""
            end)

            local globalStrings = {}
            -- FezzedOne: Global actions and radio. Supports IC language tags now.
            data.text = data.text:gsub("\\{{", "{^;{"):gsub("{{(.-)}}", function(s)
                table.insert(globalStrings, s)
                return ""
            end)

            if position then
                local estRad = data.proxRadius
                local rawText = data.text
                local sum = 0
                local parenSum = 0
                local iCount = 1
                local globalFlag = false
                local hasNoise = false
                local defaultKey = getDefaultLang()
                data.defaultLang = defaultKey
                local typoTable = player.getProperty("typos", {})
                local typoVar = typoTable["typosActive"]
                if typoVar then
                    local newText = ""
                    local wordBuffer = ""
                    for i in (rawText .. " "):gmatch(".") do
                        if i:match("[%s%p]") and i ~= "[" and i ~= "]" then
                            if typoTable[wordBuffer] ~= nil then
                                newText = newText .. typoTable[wordBuffer] .. i

                                wordBuffer = ""
                            else
                                newText = newText .. wordBuffer .. i
                            end
                            wordBuffer = ""
                        else
                            wordBuffer = wordBuffer .. i
                        end
                    end
                    rawText = newText:sub(1, #newText - 1)
                end
                while iCount <= #rawText and not globalFlag do
                    if parenSum == 3 then globalFlag = true end

                    local i = rawText:sub(iCount, iCount)
                    local langEnd = rawText:find("]", iCount)
                    -- if langEnd then langEnd = langEnd - 1 end
                    if i == "\\" then -- FezzedOne: Ignore escaped characters.
                        iCount = iCount + 1
                    elseif i == "+" then
                        sum = sum + 1
                    elseif i == "(" then
                        parenSum = parenSum + 1
                    elseif i == "{" and rawText:find("}", iCount) ~= nil then
                        globalFlag = true
                    elseif i == "[" and langEnd ~= nil then --use this flag to check for default languages. A string without any noise won't have any language support
                        if rawText:sub(iCount + 1, iCount + 1) ~= "[" then -- FezzedOne: If `[[` is detected, don't parse it as a language key.
                            local langKey
                            if rawText:sub(iCount, langEnd) == "[]" then --checking for []
                                langKey = defaultKey
                                rawText = rawText:gsub("%[%]", "[" .. defaultKey .. "]")
                            else
                                -- FezzedOne: Fixed issue where special characters weren't escaped before being passed as a Lua pattern.
                                langKey = rawText:sub(iCount + 1, langEnd - 1)
                                langKey = langKey:gsub("[%(%)%.%%%+%-%*%?%[%^%$]", function(s) return "%" .. s end)
                            end
                            local upperKey = langKey:upper()

                            local langItem = player.getItemWithParameter("langKey", upperKey)

                            if langItem == nil and upperKey ~= "!!" then
                                rawText = rawText:gsub("%[" .. langKey, "[" .. defaultKey)
                            end
                        else
                            iCount = iCount + 1
                        end
                    else
                        parenSum = 0
                    end
                    iCount = iCount + 1
                end
                data.content = rawText
                data.text = ""
                if parenSum == 2 or globalFlag then
                    estRad = estRad * 2
                elseif sum > 3 then
                    estRad = estRad * 1.5
                else
                    estRad = estRad + (estRad * 0.25 + (3 * sum))
                end

                --estrad should be pretty close to actual radius

                --this is where i'd change players if needed
                local players = world.playerQuery(position, estRad, {
                    boundMode = "position",
                })

                -- if xsb then -- FezzedOne: On xStarbound, filter out local secondaries to avoid showing duplicate sent messages.
                --     local localPlayers = world.ownPlayers()
                --     local primaryPlayer = world.primaryPlayer()
                --     for i = #localPlayers, 1, -1 do
                --         if localPlayers[i] == primaryPlayer then
                --             table.remove(localPlayers, i)
                --             break
                --         end
                --     end
                --     for i = #players, 1, -1 do
                --         for j = 1, #localPlayers, 1 do
                --             if players[i] == localPlayers[j] then table.remove(players, i) end
                --         end
                --     end
                -- end

                -- FezzedOne: Added a setting that allows proximity chat to be sent as local chat for compatibility with «standard» local chat.
                -- Chat sent this way is prefixed so that it always shows up as proximity chat for those with the mod installed.
                local chatTags = AuthorIdPrefix
                    .. tostring(player.id())
                    .. DefaultLangPrefix
                    .. tostring(data.defaultLang)
                    .. TagSuffix

                if root.getConfiguration("DynamicProxChat::sendProxChatInLocal") then
                    chat.send(DynamicProxPrefix .. chatTags .. data.content, "Local", not not xsb)
                else
                    for _, pl in ipairs(players) do
                        if xsb then data.sourceId = world.primaryPlayer() end
                        data.targetId = pl -- FezzedOne: Used to distinguish DPC messages from SCCRP messages *and* for filtering messages as seen by secondaries on xStarbound clients.
                        data.mode = "Proximity"
                        world.sendEntityMessage(pl, "scc_add_message", data)
                    end
                end
                if #globalStrings ~= 0 then
                    local globalMsg = ""
                    for _, str in ipairs(globalStrings) do
                        globalMsg = globalMsg .. str .. " "
                    end
                    globalMsg:sub(1, -2)
                    globalMsg = "{{" .. globalMsg .. "}}"
                    globalMsg = globalMsg:gsub("[ ]+", " "):gsub("%{ ", "{"):gsub(" %}", "}")
                    globalMsg = DynamicProxPrefix .. chatTags .. globalMsg
                    -- The third parameter is ignored on StarExtensions, but retains the "..." chat bubble on xStarbound and OpenStarbound.
                    chat.send(globalMsg, "Broadcast", not not xsb)
                end
                if #globalOocStrings ~= 0 then
                    local globalOocMsg = ""
                    for _, str in ipairs(globalOocStrings) do
                        globalOocMsg = globalOocMsg .. str .. " "
                    end
                    globalOocMsg:sub(1, -2)
                    globalOocMsg = "((" .. globalOocMsg .. "))"
                    globalOocMsg = globalOocMsg:gsub("[ ]+", " ")
                    globalOocMsg = DynamicProxPrefix .. globalOocMsg
                    -- The third parameter is ignored on StarExtensions, but retains the "..." chat bubble on xStarbound and OpenStarbound.
                    chat.send(globalOocMsg, "Broadcast", not not xsb)
                end
                return true
            end
        end

        local sendMessagePromise = {
            finished = function()
                local status, errorMsg = pcall(sendMessageToPlayers)
                if status then
                    return errorMsg
                else
                    sb.logWarn(
                        "[DynamicProxChat] Error occurred while sending proximity message: %s\n  Message data: %s",
                        errorMsg,
                        data
                    )
                    return false
                end
            end,
            succeeded = function() return true end,
        }

        promises:add(sendMessagePromise)
        player.say("...")
    end
end

function dynamicprox:formatIncomingMessage(rawMessage)
    local messageFormatter = function(message)
        local hasPrefix = message.text:sub(1, #DynamicProxPrefix) == DynamicProxPrefix

        local timestamp = os.time() + ((root.getConfiguration("DynamicProxChat::timeZone") or 0) * 3600) -- UTC by default
        local seconds_in_day = 86400
        local seconds = timestamp % seconds_in_day
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local hourStr = (hours < 10 and "0" or "") .. tostring(hours)
        local minuteStr = (minutes < 10 and "0" or "") .. tostring(minutes)

        message.time = hourStr .. ":" .. minuteStr
        local isGlobalChat = message.mode == "Broadcast"
        -- FezzedOne: Handle SCCRP Proximity messages if 1) SCCRP isn't installed or 2) it's explicitly enabled via a toggle and SCCRP is installed.
        local skipHandling = false
        local isSccrpMessage = message.mode == "Proximity" and not message.targetId
        local showAsProximity = (sccrpInstalled() and isSccrpMessage)
        local showAsLocal = message.mode == "Local"
        if not root.getConfiguration("DynamicProxChat::handleSccrpProx") then skipHandling = showAsProximity end

        -- FezzedOne: This setting allows local chat to be «funneled» into proximity chat and appropriately formatted and filtered automatically.
        if
            hasPrefix
            or (
                root.getConfiguration("DynamicProxChat::localChatIsProx")
                and (message.mode == "Local" or message.isSccrp or isSccrpMessage)
            )
        then
            message.mode = "Proximity"
            if hasPrefix and not message.processed then message.text = message.text:sub(#DynamicProxPrefix + 1, -1) end
            message.contentIsText = true
        end
        if message.mode == "Proximity" and not skipHandling and not message.processed then
            message.isSccrp = isSccrpMessage or nil
            -- FezzedOne: These are from my SCCRP PR. Ensures that SCCRP messages from and to xStarbound clients are always correctly handled.
            if message.isSccrp then
                message.sourceId = message.senderId
                message.targetId = message.receiverId
            end
            message.mode = "Prox"
            if not message.contentIsText then message.text = message.content end
            message.content = ""

            if message.connection then --i don't know what receivingRestricted does
                local hasAuthorPrefix = message.text:sub(1, #AuthorIdPrefix) == AuthorIdPrefix
                local authorEntityId
                local defaultLangStr = nil
                if hasAuthorPrefix then
                    local i = #AuthorIdPrefix + 1
                    local authorIdStr = ""
                    local c = ""
                    while i <= #message.text do
                        c = message.text:sub(i, i)
                        if c == "," then break end
                        authorIdStr = authorIdStr .. c
                        i = i + 1
                    end
                    authorEntityId = math.tointeger(authorIdStr)
                    if message.text:sub(i, i + #DefaultLangPrefix - 1) == DefaultLangPrefix then
                        i = i + #DefaultLangPrefix
                        defaultLangStr = ""
                        while i <= #message.text do
                            c = message.text:sub(i, i)
                            if c == "," then break end
                            defaultLangStr = defaultLangStr .. c
                            i = i + 1
                        end
                        i = i + #TagSuffix
                    else
                        while i <= #message.text do
                            c = message.text:sub(i, i)
                            if c == ";" then
                                i = i + 1
                                break
                            end
                            i = i + 1
                        end
                    end
                    message.text = message.text:sub(i, -1)
                end
                -- FezzedOne: Allows OpenStarbound and StarExtensions clients to correctly display received messages from xStarbound clients.
                local basePlayerId = message.connection * -65536
                authorEntityId = authorEntityId or message.sourceId or basePlayerId
                local authorRendered = world.entityExists(authorEntityId)
                -- FezzedOne: If the author ID has to be guessed from the connection ID and it's *not* the first ID, that means the author is using xStarbound,
                -- so look for the first rendered player belonging to the author's client. Kinda kludgy, but this is what we have to do for xStarbound clients
                -- that don't send the required information because they don't have this mod or SCCRP!
                if not (authorRendered or hasAuthorPrefix or message.sourceId) then
                    for i = (message.connection * -65536 + 1), (message.connection * -65536 + 255), 1 do
                        if world.entityExists(i) and world.entityType(i) == "player" then
                            authorEntityId = i
                            authorRendered = true
                            break
                        end
                    end
                end
                local receiverEntityId = message.targetId or player.id()
                -- FezzedOne: DPC-side part of fix for SCCRP portraits in dynamically handled messages.
                message.senderId = authorEntityId
                message.receiverId = receiverEntityId
                local ownPlayers = {}
                if xsb then ownPlayers = world.ownPlayers() end
                local isLocalPlayer = function(entityId)
                    if not xsb then return true end
                    for _, plr in ipairs(ownPlayers) do
                        if entityId == plr then return true end
                    end
                    return false
                end

                local handleMessage = function(receiverEntityId, copiedMessage)
                    local uncapRad = isGlobalChat
                    local wasGlobal = isGlobalChat
                    local message = copiedMessage or message
                    if xsb then
                        if copiedMessage or message.targetId then -- FezzedOne: Show the receiver's name for disambiguation on xClient.
                            if world.entityExists(receiverEntityId) then
                                local receiverName = world.entityName(receiverEntityId)
                                if #ownPlayers ~= 1 then
                                    message.nickname = message.nickname .. " -> " .. receiverName
                                end
                                if receiverEntityId ~= player.id() then message.mode = "ProxSecondary" end
                            end
                        end
                    end
                    do
                        local authorPos, messageDistance, inSight = nil, math.huge, false
                        local playerPos = world.entityPosition(
                            world.entityExists(receiverEntityId) and receiverEntityId or player.id()
                        )
                        if authorRendered then
                            authorPos = world.entityPosition(authorEntityId)
                            messageDistance = world.magnitude(playerPos, authorPos)
                            -- messageDistance = 30
                            inSight = not world.lineTileCollision(authorPos, playerPos, { "Block", "Dynamic" }) --not doing dynamic, i think that's only for open doors
                        end

                        -- FezzedOne: Dynamic collision thickness calculation.
                        local collisionA = nil
                        if authorPos and not inSight then
                            collisionA = world.lineTileCollisionPoint(authorPos, playerPos, { "Block", "Dynamic" })
                                or nil
                        end
                        local wallThickness = 0
                        if collisionA then
                            -- FezzedOne: To find wall thickness, run collision checks in opposite directions.
                            local collisionB = world.lineTileCollisionPoint(
                                playerPos,
                                authorPos,
                                { "Block", "Dynamic" }
                            ) or { collisionA[1] }
                            wallThickness = math.floor(world.magnitude(collisionA[1], collisionB[1]))
                        end
                        if DEBUG then
                            sb.logInfo(
                                DEBUG_PREFIX .. "Wall thickness is %s %s.",
                                tostring(wallThickness),
                                wallThickness == 1 and "tile" or "tiles"
                            )
                        end

                        local actionRad = self.proxActionRadius -- FezzedOne: Un-hardcoded the action radius.
                        local loocRad = self.proxOocRadius -- actionRad * 2 -- FezzedOne: Un-hardcoded the local OOC radius.
                        local noiseRad = self.proxTalkRadius -- FezzedOne: Un-hardcoded the talking radius.

                        --originally i made this a function, but tracking the values is difficult and it's easier to manually set them since there are only 9
                        local soundTable = {
                            [-4] = noiseRad / 10,
                            [-3] = noiseRad / 5,
                            [-2] = noiseRad / 4,
                            [-1] = noiseRad / 2,
                            [0] = noiseRad, --based on the default range of talking being 50, this should be good
                            [1] = noiseRad * 1.5,
                            [2] = noiseRad * 2,
                            [3] = noiseRad * 3,
                            [4] = noiseRad * 5,
                        }

                        --i dont like this but it'll have to do
                        local volTable = {
                            [noiseRad / 10] = -4,
                            [noiseRad / 5] = -3,
                            [noiseRad / 4] = -2,
                            [noiseRad / 2] = -1,
                            [noiseRad] = 0, --based on the default range of talking being 50, this should be good
                            [noiseRad * 1.5] = 1,
                            [noiseRad * 2] = 2,
                            [noiseRad * 3] = 3,
                            [noiseRad * 5] = 4,
                        }

                        local tVol, sVol = 0, 0
                        local tVolRad = noiseRad
                        local sVolRad = noiseRad
                        --iterate through message and get components here
                        local curMode = "action"
                        local prevMode = "action"
                        local prevDiffMode = "action"
                        local maxRad = 0 -- Remove the maximum radius restriction from global messages.
                        local rawText = message.text
                        local debugTable = {} --this will eventually be smashed together to make filterText
                        local textTable = {} --this will eventually be smashed together to make filterText
                        local validSum = 0 --number of valid entries in the table
                        local cInd = 1 --lua starts at 1 >:(
                        local charBuffer = ""
                        local languageCode = defaultLangStr or message.defaultLang --the !! shouldn't need to be set, but i'll leave it anyway
                        local radioMode = false --radio flag

                        local modeRadTypes = {
                            action = function() return actionRad end,
                            quote = function() return tVolRad end,
                            sound = function() return sVolRad end,
                            pOOC = function() return loocRad end,
                            lOOC = function() return loocRad end,
                            gOOC = function() return -1 end,
                        }

                        local function rawSub(sInd, eInd) return rawText:sub(sInd, eInd) end

                        --use this to construct the components
                        --any component indications (like :+) that remain should stay, use them for coloring if they aren't picked up here and reset after each component
                        local function formatInsert(str, radius, type, langKey, isValid, msgQuality, inSight, isRadio)
                            if langKey == nil then langKey = "!!" end

                            if msgQuality < 0 then msgQuality = 100 end

                            table.insert(textTable, {
                                text = str,
                                radius = radius,
                                type = type,
                                langKey = langKey,
                                valid = isValid,
                                msgQuality = msgQuality,
                                hasLOS = inSight,
                                isRadio = isRadio,
                            })
                        end

                        local function parseDefault(letter)
                            charBuffer = charBuffer .. letter
                            cInd = cInd + 1
                        end

                        local function newMode(nextMode) --if radius is -1, the insert is instance wide
                            if #charBuffer < 1 or charBuffer == '"' or charBuffer == ">" or charBuffer == "<" then
                                prevMode = curMode
                                curMode = nextMode
                                return
                            end

                            local useRad
                            useRad = modeRadTypes[curMode]()
                            local isValid = false --start with false
                            if messageDistance <= useRad or useRad == -1 then --if in range
                                isValid = true --the message is valid
                                if inSight == false and curMode == "action" then --if i can't see you and the mode is action
                                    isValid = false --the message isn't valid anymore
                                elseif inSight == false and (curMode == "quote" or curMode == "sound") then --else, if i can't see you and the mode is quote or sound
                                    --check for path
                                    local noPathVol
                                    if authorPos then
                                        if
                                            world.findPlatformerPath(
                                                authorPos,
                                                playerPos,
                                                root.monsterMovementSettings("smallflying")
                                            )
                                        then --if path is found
                                            noPathVol = volTable[useRad] - 2 --set the volume to 1 (maybe 2 later on) level lower
                                        else --if the path isn't found
                                            if wallThickness <= 4 then
                                                noPathVol = volTable[useRad] - (wallThickness <= 1 and 2 or 3)
                                            else
                                                noPathVol = volTable[useRad] - 4 --set the volume to 4 levels lower
                                            end
                                        end
                                    else
                                        noPathVol = -4
                                    end
                                    if noPathVol > 4 then
                                        noPathVol = 4
                                    elseif noPathVol < -4 then
                                        noPathVol = -4
                                        isValid = false
                                    end
                                    useRad = soundTable[noPathVol] --set the radius to whatever the soundelevel would be
                                    isValid = isValid and messageDistance <= useRad --set isvalid to the new value if it's still true
                                end
                            end

                            local msgQuality = 0
                            if isValid then
                                validSum = validSum + 1
                                msgQuality = math.min(((useRad / 2) / messageDistance) * 100, 100) --basically, check half the radius and take the percentage of that vs the message distance, cap at 100
                                maxRad = math.max(maxRad, useRad)
                            end

                            if useRad == -1 and maxRad ~= -1 then maxRad = -1 end
                            formatInsert(
                                charBuffer,
                                useRad,
                                curMode,
                                languageCode,
                                isValid,
                                msgQuality,
                                inSight,
                                radioMode
                            )
                            charBuffer = ""

                            prevMode = curMode
                            if curMode ~= nextMode then prevDiffMode = curMode end
                            curMode = nextMode
                        end

                        local defaultKey = getDefaultLang()

                        local mode_table = {
                            ['"'] = function()
                                if curMode == "quote" then
                                    parseDefault("")
                                    newMode("action")
                                elseif curMode == "action" then
                                    newMode("quote")
                                    parseDefault("")
                                else
                                    parseDefault('"')
                                end
                            end,
                            ["<"] = function() --i could combine these two, but i don't want to
                                local nextChar = rawSub(cInd + 1, cInd + 1)
                                if nextChar == "<" then
                                    local oocBump = 0
                                    local oocType
                                    local oocRad
                                    --local ooc
                                    local _, oocEnd = rawText:find(">>+", cInd)
                                    if not oocEnd then
                                        local _, oocEnd2 = rawText:find(">", cInd)
                                        oocEnd = oocEnd2
                                    end
                                    oocEnd = oocEnd or 0
                                    oocBump = 1
                                    oocType = "pOOC"
                                    oocRad = actionRad * 2

                                    if oocEnd ~= nil then
                                        newMode(oocType)
                                        charBuffer = charBuffer .. rawSub(cInd, oocEnd)
                                        newMode(prevMode)
                                    else
                                        charBuffer = charBuffer .. rawSub(cInd, cInd + oocBump)
                                        cInd = cInd + oocBump
                                        oocEnd = cInd
                                    end

                                    cInd = oocEnd + 1
                                else
                                    if curMode ~= "sound" and curMode ~= "quote" then --added quotes here so people can do the cool combine vocoder thing <::Pick up that can.::>
                                        newMode("sound")
                                    end
                                end
                                parseDefault("")
                            end,
                            [">"] = function()
                                parseDefault("")
                                if curMode == "sound" then newMode(prevDiffMode) end
                            end,
                            [":"] = function()
                                local nextChar = rawSub(cInd + 1, cInd + 1)
                                if nextChar == "+" or nextChar == "-" or nextChar == "=" then
                                    newMode(curMode) --this happens to change volume, but mode isn't actually changing

                                    local maxAmp = 4 --maximum chars after the colon

                                    local lStart, lEnd = rawText:find(":%++", cInd)
                                    local qStart, qEnd = rawText:find(":%-+", cInd)
                                    local eStart, eEnd = rawText:find(":%=+", cInd)
                                    local nCStart, nCEnd

                                    if qStart == nil then qStart = #rawText end
                                    if qEnd == nil then qEnd = #rawText end
                                    if lStart == nil then lStart = #rawText end
                                    if lEnd == nil then lEnd = #rawText end
                                    if eStart == nil then eStart = #rawText end
                                    if eEnd == nil then eEnd = #rawText end

                                    if math.min(eStart, lStart, qStart) == eStart then
                                        nCStart = eStart
                                        nCEnd = eEnd
                                    elseif math.min(eStart, lStart, qStart) == lStart then
                                        nCStart = lStart
                                        nCEnd = lEnd
                                    elseif math.min(eStart, lStart, qStart) == qStart then
                                        nCStart = qStart
                                        nCEnd = qEnd
                                    end

                                    local doVolume = "none"
                                    --in these modes, ignore the volume controls
                                    if
                                        curMode == "radio"
                                        or curMode == "gOOC"
                                        or curMode == "lOOC"
                                        or curMode == "pOOC"
                                    then
                                        cInd = nCEnd + 1
                                    elseif curMode == "action" then
                                        local nextInd = rawText:find('["<]', cInd)

                                        if nextChar == nil then --if they just put this at the end for some reason
                                            cInd = nCEnd + 1
                                        elseif nextInd ~= nil then
                                            nextChar = rawSub(nextInd, nextInd)
                                        end
                                        if nextChar == '"' then
                                            doVolume = "quote"
                                        else
                                            doVolume = "sound"
                                        end
                                    else
                                        doVolume = curMode
                                    end

                                    if doVolume ~= "none" then
                                        local sum = 0
                                        local nextStr = rawSub(nCStart + 1, nCEnd)

                                        if doVolume == "quote" then
                                            sum = tVol
                                        else
                                            sum = sVol
                                        end

                                        for i in nextStr:gmatch(".") do
                                            if i == "+" then
                                                sum = sum + 1
                                            elseif i == "-" then
                                                sum = sum - 1
                                            elseif i == "=" then
                                                sum = 0
                                                if doVolume == "quote" then
                                                    tVolRad = noiseRad
                                                else
                                                    sVolRad = noiseRad
                                                end
                                            end
                                        end
                                        cInd = nCEnd

                                        sum = math.min(math.max(sum, -4), 4)

                                        if doVolume == "quote" then
                                            tVol = sum
                                            tVolRad = soundTable[sum]
                                        else
                                            sVol = sum
                                            sVolRad = soundTable[sum]
                                        end
                                    end
                                    cInd = nCEnd + 1
                                else
                                    parseDefault(":")
                                end
                            end,
                            ["*"] = function() --leave this for the visual alterations later on
                                -- i have this commented out so people can keep asterisks in actions if they want
                                -- if curMode == 'action' then
                                --   cInd = cInd + 1
                                -- else
                                --   parseDefault("*")
                                -- end
                                parseDefault("*")
                            end,
                            ["/"] = function() parseDefault("/") end,
                            ["`"] = function() parseDefault("`") end,
                            ["\\"] = function() -- Allow escaping any specially parsed character with `\`.
                                local nextChar = rawSub(cInd + 1, cInd + 1)
                                parseDefault(nextChar)
                                cInd = cInd + 1
                            end,
                            ["("] = function() --check for number of parentheses
                                local nextChar = rawSub(cInd + 1, cInd + 1)
                                if nextChar == "(" then
                                    local oocEnd = 0
                                    local oocBump = 0
                                    local oocType
                                    local oocRad
                                    if not root.getConfiguration("DynamicProxChat::proximityOoc") then
                                        uncapRad = true
                                    end
                                    if rawSub(cInd + 2, cInd + 2) == "(" then
                                        --global ooc
                                        _, oocEnd = rawText:find("%)%)%)+", cInd) --the + catches extra parentheses in case someone adds more than 3
                                        oocType = "gOOC"
                                        oocBump = 2
                                        oocRad = -1
                                    else
                                        --local ooc
                                        _, oocEnd = rawText:find("%)%)+", cInd)
                                        oocBump = 1
                                        oocType = "lOOC"
                                        oocRad = actionRad * 2
                                    end

                                    if oocEnd ~= nil then
                                        newMode(oocType)
                                        charBuffer = charBuffer .. rawSub(cInd, oocEnd)
                                        newMode(prevMode)
                                    else
                                        charBuffer = charBuffer .. rawSub(cInd, cInd + oocBump)
                                        cInd = cInd + oocBump
                                        oocEnd = cInd
                                    end

                                    cInd = oocEnd + 1
                                else
                                    parseDefault("(")
                                end
                            end,
                            ["{"] = function() --this should function as a global IC message, but finding the playercount is not possible (or i'm stupid) clientside
                                --i'm not doing secure radio because you can edit this file and ignore the password requirement with it
                                --if you want to do that, just do it over group chat or something
                                --this is where a stagehand serverside would be useful. In the future it might be worth exploring that

                                --maybe set up multiple radio ranges with multiple brackets? seems kind of pointless imo
                                newMode(curMode)
                                radioMode = true
                                uncapRad = true
                                parseDefault("{")
                            end,
                            ["}"] = function()
                                if rawSub(cInd + 1, cInd + 1) == '"' and curMode == "quote" then
                                    parseDefault("}")
                                    parseDefault('"')
                                    newMode("action")
                                elseif rawSub(cInd + 1, cInd + 1) == "}" then -- Check for an extra curly brace to ensure it's included in the radio chunk.
                                    parseDefault("}")
                                    parseDefault("}")
                                    newMode(curMode)
                                else
                                    parseDefault("}")
                                    newMode(curMode)
                                end

                                radioMode = false
                                -- cInd = cInd + 1
                            end,
                            -- ["|"] = function()
                            --     local fStart = cInd
                            --     local fEnd = rawText:find("|", cInd + 1)
                            --
                            --     if fStart ~= nil and fEnd ~= nil then
                            --         -- local timeNum = tostring(math.floor(os.time()))
                            --         -- local mixNum = tonumber(timeNum .. math.abs(authorEntityId))
                            --         -- randSource:init(mixNum)
                            --         -- local numMax = rawSub(fStart, fEnd - 1):gsub("%D", "")
                            --         -- local roll = randSource:randInt(1, tonumber(numMax) or 20)
                            --         -- FezzedOne: Replaced dice roller with the more flexible one from FezzedTech.
                            --         local diceResults = rawSub(fStart + 1, fEnd):gsub("[ ]*", ""):gsub(
                            --             "(.-)[,|]",
                            --             function(die) return tostring(rollDice(die) or "n/a") .. ", " end
                            --         )
                            --         parseDefault("|" .. diceResults:sub(1, -3) .. "|")
                            --         cInd = fEnd + 1
                            --     else
                            --         parseDefault("|")
                            --     end
                            -- end,
                            ["["] = function()
                                -- FezzedOne: Added escape code handling.
                                local fStart = cInd
                                local fEnd = rawText:find("[^\\]%]", cInd + 1)
                                if rawSub(cInd, cInd + 1) == "[[" then
                                    parseDefault("[[")
                                    cInd = cInd + 1
                                elseif rawSub(cInd, cInd + 1) == "[]" then --this should never happen anymore
                                    newMode(curMode)
                                    languageCode = defaultKey
                                    cInd = cInd + 2
                                elseif fStart ~= nil and fEnd ~= nil then
                                    local newCode = rawSub(fStart + 1, fEnd)

                                    if languageCode ~= newCode and curMode == "quote" then newMode(curMode) end
                                    languageCode = newCode:upper()
                                    cInd = rawText:find("%S", fEnd + 2) or #rawText --set index to the next non whitespace character after the code
                                else
                                    parseDefault("[")
                                end
                            end,
                            default = function(letter)
                                charBuffer = charBuffer .. letter
                                cInd = cInd + 1
                            end,
                        }

                        local c

                        --run this loop to generate textTable, then concatenate
                        while cInd <= #rawText do
                            c = rawSub(cInd, cInd)

                            if mode_table[c] then
                                mode_table[c]()
                            else
                                parseDefault(c)
                            end
                        end
                        newMode(curMode) --makes sure nothing is left out

                        local function degradeMessage(str, quality)
                            local returnStr = ""
                            local char
                            local iCount = 1
                            local rMax = (#str - 2) - ((#str - 2) * (quality / 100)) --basically, how many characters can be "-", helps
                            local rCount = 0
                            while iCount <= #str do
                                char = str:sub(iCount, iCount)
                                if char == "\\" then
                                    returnStr = returnStr .. str:sub(iCount + 1, iCount + 1)
                                    iCount = iCount + 2
                                    -- FezzedOne: Got rid of hardcoded assumption that language codes are two characters long.
                                elseif char == "[" and str:find("]", iCount) ~= nil then
                                    local closingBracket = str:find("]", iCount)
                                    returnStr = returnStr .. str:sub(iCount, closingBracket)
                                    iCount = closingBracket + 1
                                elseif char == "^" and str:find(";", iCount) ~= nil then
                                    local nextSemi = str:find(";", iCount)
                                    returnStr = returnStr .. str:sub(iCount, nextSemi)
                                    iCount = nextSemi + 1
                                else
                                    randSource:init()

                                    local letterRoll = randSource:randInt(1, 100)
                                    if letterRoll > quality and char:match("[%p%s]") == nil then
                                        char = "-"
                                        rCount = rCount + 1
                                    end
                                    returnStr = returnStr .. char
                                    iCount = iCount + 1
                                end
                            end
                            return returnStr
                        end

                        local function wordBytes(word)
                            local returnNum = 0
                            if not type(word) == "string" then return 0 end
                            for char in word:gmatch(".") do
                                char = char:lower()
                                returnNum = returnNum * 16
                                if not math.tointeger(returnNum) then returnNum = math.tointeger(2 ^ 48) end
                                returnNum = returnNum + math.abs(string.byte(char) - 100)
                            end
                            return returnNum
                        end

                        local function langWordRep(word, proficiency, byteLC)
                            -- FezzedOne: The wordRoll parameter is now used.
                            local vowels = {
                                "a",
                                "e",
                                "i",
                                "o",
                                "u",
                                "y",
                            }
                            local consonants = {
                                "b",
                                "c",
                                "d",
                                "f",
                                "g",
                                "h",
                                "j",
                                "k",
                                "l",
                                "m",
                                "n",
                                "p",
                                "q",
                                "r",
                                "s",
                                "t",
                                "v",
                                "w",
                                "x",
                                "z",
                            }
                            -- FezzedOne: Merge a list into a Lua pattern. Assumes input doesn't contain any characters that need to be escaped.
                            local function mergePattern(list)
                                local pattern = "["
                                for _, char in ipairs(list) do
                                    pattern = pattern .. char
                                end
                                return pattern .. "]"
                            end

                            local pickInd = 0
                            local newWord = ""
                            local wordLength = #word
                            randSource:init(math.tointeger(byteLC + wordBytes(word)))
                            for char in word:gmatch(".") do
                                local charLower = char:lower()
                                local isLower = char == charLower
                                local vowelPattern = mergePattern(vowels)
                                local compFail = randSource:randInt(0, 150)
                                    > (proficiency - (wordLength ^ 2 + 10) / (math.max(1, proficiency - 50) / 5))
                                if proficiency < 5 or compFail then -- FezzedOne: Added a chance that a word will be partially comprehensible.
                                    if charLower:match(vowelPattern) then
                                        local randNum = randSource:randInt(1, #vowels)
                                        char = vowels[randNum]
                                    elseif not char:match("[%p]") then -- Don't mess with punctuation.
                                        local randNum = randSource:randInt(1, #consonants)
                                        char = consonants[randNum]
                                    end
                                end
                                if not isLower then char = char:upper() end
                                newWord = newWord .. char
                            end
                            return newWord
                        end

                        local function langScramble(str, prof, langCode, msgColor, langColor)
                            local returnStr = ""
                            str = str .. " "
                            str = str:gsub("  ", " ")
                            local rCount = 0
                            local words = 0
                            for i in str:gmatch(".") do
                                if i == " " then words = words + 1 end
                            end
                            words = words + 1
                            local rMax = words - (words * (prof / 100))
                            local wordBuffer = ""
                            local byteLC = wordBytes(langCode)
                            local iCount = 1
                            local char
                            local effProf = 64 * math.log(prof / 3 + 1, 10)
                            -- local effProf = 64 * math.log(prof / 5, 5) - 20 --attempt at tweaking value, low proficiency seems to bottom out too much
                            if DEBUG then sb.logInfo(DEBUG_PREFIX .. "effProf is " .. effProf) end
                            local uniqueIdBytes = wordBytes(
                                (xsb and isLocalPlayer(receiverEntityId)) and world.entityUniqueId(receiverEntityId)
                                    or player.uniqueId()
                            )

                            if langColor == nil then
                                local hexDigits =
                                    { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" }
                                -- local randSource = sb.makeRandomSource()
                                local hexMin = 3

                                --not sure if there's an cleaner way to do this
                                randSource:init(math.tointeger(byteLC + wordBytes("Red One")))
                                local rNumR = hexDigits[randSource:randInt(hexMin, 16)]
                                randSource:init(math.tointeger(byteLC + wordBytes("Green Two")))
                                local rNumG = hexDigits[randSource:randInt(hexMin, 16)]
                                randSource:init(math.tointeger(byteLC + wordBytes("Blue Three")))
                                local rNumB = hexDigits[randSource:randInt(hexMin, 16)]
                                randSource:init(math.tointeger(byteLC + wordBytes("Red Four")))
                                local rNumR2 = hexDigits[randSource:randInt(hexMin, 16)]
                                randSource:init(math.tointeger(byteLC + wordBytes("Green Five")))
                                local rNumG2 = hexDigits[randSource:randInt(hexMin, 16)]
                                randSource:init(math.tointeger(byteLC + wordBytes("Blue Six")))
                                local rNumB2 = hexDigits[randSource:randInt(hexMin, 16)]
                                langColor = "#" .. rNumR .. rNumG .. rNumB .. rNumR2 .. rNumG2 .. rNumB2
                                if DEBUG then
                                    sb.logInfo(DEBUG_PREFIX .. "langColor for " .. langCode .. " is " .. langColor)
                                end
                            end

                            while iCount <= #str do
                                char = str:sub(iCount, iCount)
                                -- FezzedOne: Got rid of hardcoded assumption that language keys are two characters long.
                                if char == "[" and str:find(iCount, "]") ~= nil then
                                    local closingBracket = str:find("]", iCount)
                                    returnStr = returnStr .. char .. str:sub(iCount + 1, closingBracket)
                                    iCount = closingBracket + 1
                                elseif char == " " and not wordBuffer:match("%a") and #wordBuffer > 0 then
                                    returnStr = returnStr .. " " .. wordBuffer
                                    wordBuffer = ""
                                elseif char ~= "'" and char:match("[%s%p]") then
                                    if #wordBuffer > 0 then
                                        local wordLength = #wordBuffer
                                        local byteWord = wordBytes(wordBuffer)
                                        randSource:init(math.tointeger(uniqueIdBytes + byteLC + byteWord))
                                        local wordRoll = randSource:randInt(1, 100)
                                        if
                                            effProf < 5
                                            or (wordRoll + (wordLength ^ 2 / (math.max(1, effProf - 50) / 5)) - 10)
                                                > effProf
                                        then
                                            wordBuffer = langWordRep(trim(wordBuffer), effProf, byteLC)
                                            wordBuffer = "^" .. langColor .. ";" .. wordBuffer .. "^" .. msgColor .. ";"
                                            rCount = rCount + 1
                                        end
                                    end
                                    returnStr = returnStr .. wordBuffer .. char
                                    wordBuffer = ""
                                else
                                    wordBuffer = wordBuffer .. char
                                end
                                iCount = iCount + 1
                            end

                            if returnStr:match("%s", #returnStr) then returnStr = returnStr:sub(0, #returnStr - 1) end

                            randSource:init()
                            return returnStr
                        end

                        local colorTable = { --transparency is an options here, but it makes things hard to read
                            [-4] = "#555",
                            [-3] = "#777",
                            [-2] = "#999",
                            [-1] = "#bbb",
                            [0] = "#ddd",
                            [1] = "#fff",
                            [2] = "#daa",
                            [3] = "#d66",
                            [4] = "#d00",
                        }

                        local function colorWithin(str, char, color, prevColor)
                            local colorOn = false
                            local charBuffer = ""
                            for i in str:gmatch(".") do
                                if i == char then
                                    if colorOn == false then
                                        charBuffer = charBuffer .. "^" .. color .. ";"
                                        colorOn = true
                                    else
                                        charBuffer = charBuffer .. "^" .. prevColor .. ";"
                                        colorOn = false
                                    end
                                else
                                    --put this outside the if statement to make the characters appear as well as colors
                                    charBuffer = charBuffer .. i
                                end
                            end
                            -- print("Charbuffer is " .. charBuffer)
                            return charBuffer
                        end

                        local function cleanDoubleSpaces(str)
                            --run a loop with the string, ignore codes (^whatever;), then remove more than one space in a row
                            local cleanStr = ""
                            local iCount = 1
                            local prevChar = ""
                            local prevColor = ""

                            while iCount <= #str do
                                local char = str:sub(iCount, iCount)
                                local nextSemi = 0

                                if char == "^" then
                                    nextSemi = str:find(";", iCount)

                                    if nextSemi ~= nil then
                                        local colorCode = str:sub(iCount, nextSemi)
                                        if colorCode ~= prevColor then cleanStr = cleanStr .. colorCode end
                                        prevColor = colorCode
                                        iCount = nextSemi
                                    end
                                elseif char ~= " " or prevChar ~= " " then
                                    cleanStr = cleanStr .. char
                                    prevChar = char
                                end
                                iCount = iCount + 1
                            end
                            cleanStr = cleanStr:gsub("%{ ", "{")
                            cleanStr = cleanStr:gsub(" %}", "}")
                            return cleanStr
                        end

                        --do visual formatting here.
                        --for dialogue (NOT sounds), start degrading the quality of the message at 50% of the quotes's radius
                        local tableStr = ""
                        local prevStr = ""
                        local quoteCombo = ""
                        local soundCombo = ""
                        local prevType = "action"
                        local quoteOpen = false
                        local soundOpen = false
                        local hasValids = false
                        local chunkStr
                        local chunkType
                        local langBank = {} --populate with languages in inventory when you find them
                        local prevLang = getDefaultLang() --either the player's default language, or !!

                        if not (uncapRad or maxRad == -1) and (messageDistance > maxRad and validSum == 0) then
                            message.text = ""
                        else
                            chunkType = nil

                            local prevChunk = ""
                            local repeatFlag = false
                            table.insert(
                                textTable,
                                { -- FezzedOne: Note to self: This dummy chunk is *required* for correct concatenation.
                                    text = "",
                                    radius = "0",
                                    type = "bad",
                                    langKey = ":(",
                                    valid = false,
                                    msgQuality = 0,
                                }
                            )

                            for _, v in ipairs(textTable) do
                                if v["hasLOS"] == false and chunkType == "action" then v["valid"] = false end
                                if
                                    v["valid"]
                                    and v["type"] ~= "pOOC"
                                    and v["type"] ~= "lOOC"
                                    and v["type"] ~= "gOOC"
                                    and not v["isRadio"]
                                then
                                    hasValids = true
                                end
                            end
                            local numChunks = #textTable
                            for k, v in ipairs(textTable) do
                                local lastChunk = k == numChunks

                                if
                                    v["radius"] == -1
                                    or v["isRadio"] == true
                                    or (v["type"] == "pOOC" and wasGlobal)
                                    or (v["type"] == "lOOC" and uncapRad)
                                    or v["type"] == "gOOC"
                                then
                                    v["valid"] = true
                                end

                                chunkStr = v["text"]
                                chunkType = v["type"]
                                local langKey = v["langKey"]
                                if
                                    v["valid"] == true
                                    or (
                                        chunkType == "quote"
                                        and (
                                            (k > 1 and textTable[k - 1]["type"] == "quote")
                                            or (k < #textTable and textTable[k + 1]["type"] == "quote")
                                        )
                                    )
                                then --check if this is surrounded by quotes
                                    v["valid"] = true --this should be set to true in here, since everything in this block should show up on the screen
                                    -- remember, noiserad is a const and radius is for the message

                                    local colorOverride = chunkStr:find("%^%#") ~= nil --don't touch colors if this is true
                                    local actionColor = "#fff" --white for non sound based chunks
                                    local msgColor = "#fff" --white for non sound based chunks
                                    --disguise unheard stuff
                                    if chunkType == "sound" then
                                        if not colorOverride then
                                            msgColor = colorTable[volTable[v["radius"]]]
                                            chunkStr = "^" .. msgColor .. ";" .. chunkStr .. "^" .. actionColor .. ";"
                                        end
                                    elseif chunkType == "quote" then
                                        msgColor = colorTable[volTable[v["radius"]]]

                                        if chunkType == "quote" and langKey ~= "!!" then
                                            local langProf, langColor
                                            if langBank[langKey] ~= nil then
                                                langProf = langBank[langKey]["prof"]
                                                langColor = langBank[langKey]["color"]
                                            end
                                            if langProf == nil then
                                                local receiverIsLocal = isLocalPlayer(receiverEntityId)
                                                local newLang
                                                if xsb and receiverIsLocal then
                                                    newLang = world
                                                        .sendEntityMessage(receiverEntityId, "hasLangKey", langKey)
                                                        :result() or nil
                                                else
                                                    newLang = player.getItemWithParameter("langKey", langKey) or nil
                                                end
                                                if newLang then
                                                    langColor = newLang["parameters"]["color"]
                                                    local hasItem
                                                    if xsb and receiverIsLocal then
                                                        hasItem = world
                                                            .sendEntityMessage(receiverEntityId, "langKeyCount", newLang)
                                                            :result()
                                                    else
                                                        hasItem = player.hasCountOfItem(newLang, true)
                                                    end

                                                    if hasItem then
                                                        langProf = hasItem * 10
                                                    else
                                                        langProf = 0
                                                    end
                                                    langBank[langKey] = {
                                                        prof = langProf,
                                                        color = langColor,
                                                    }
                                                else
                                                    langProf = 0
                                                end
                                            end

                                            if langProf < 100 then
                                                --scramble the word
                                                chunkStr =
                                                    langScramble(trim(chunkStr), langProf, langKey, msgColor, langColor)
                                            end
                                        end
                                        --check message quality
                                        if v["msgQuality"] < 100 and not v["isRadio"] and chunkType == "quote" then
                                            chunkStr = degradeMessage(trim(chunkStr), v["msgQuality"])
                                        end

                                        if not colorOverride then
                                            chunkStr = "^" .. msgColor .. ";" .. chunkStr .. "^" .. actionColor .. ";"
                                        end

                                        --add in languagee indicator
                                        if langKey ~= prevLang then
                                            chunkStr = "^#fff;[" .. langKey .. "]^" .. msgColor .. "; " .. chunkStr
                                            prevLang = langKey
                                        end
                                    end
                                    chunkStr = chunkStr:gsub("%^%#fff%;%^%#fff;", "^#fff;")
                                    chunkStr = chunkStr:gsub("%^" .. msgColor .. ";%^#fff;", "^#fff;")
                                    chunkStr = chunkStr:gsub(
                                        "%^" .. msgColor .. ";%^" .. msgColor .. ";",
                                        "^" .. msgColor .. ";"
                                    )

                                    --recolors certain things for emphasis
                                    if chunkType ~= "action" then --allow asterisks to stay in actions
                                        chunkStr = colorWithin(chunkStr, "*", "#fe7", msgColor) --yellow
                                    end
                                    -- FezzedOne: This now uses backticks.
                                    chunkStr = colorWithin(chunkStr, "`", "#d80", msgColor) --orange
                                elseif chunkType == "quote" and hasValids and prevType ~= "quote" then
                                    chunkStr = "Says something."
                                    v["valid"] = true
                                    chunkType = "action"
                                end

                                --after check, this puts formatted chunks in
                                if chunkType ~= "quote" and prevType == "quote" then
                                    local checkCombo = quoteCombo:gsub("%[%w%w%]", "")

                                    if not checkCombo:match("[%w%d]") then
                                        if prevStr ~= "Says something." and hasValids then
                                            quoteCombo = "Says something."
                                        else
                                            quoteCombo = ""
                                        end
                                        prevStr = quoteCombo
                                    else
                                        quoteCombo = '"' .. quoteCombo .. '"'
                                    end
                                    tableStr = tableStr .. " " .. quoteCombo
                                    quoteCombo = ""
                                end
                                if chunkType ~= "sound" and prevType == "sound" then
                                    if soundCombo:match("[%w%d]") then
                                        soundCombo = "<" .. soundCombo .. ">"
                                        tableStr = tableStr .. " " .. soundCombo
                                    end
                                    soundCombo = ""
                                end

                                if v["valid"] and chunkType == "quote" then
                                    if quoteCombo:sub(#quoteCombo):match("%p") then
                                        --this adds the space after a quote
                                        quoteCombo = quoteCombo .. " " .. chunkStr
                                    else
                                        quoteCombo = quoteCombo .. chunkStr
                                    end
                                elseif v["valid"] and chunkType == "sound" then
                                    if soundCombo:sub(#soundCombo):match("%p") then
                                        --this adds the space after a quote
                                        soundCombo = soundCombo .. " " .. chunkStr
                                    else
                                        soundCombo = soundCombo .. chunkStr
                                    end
                                elseif v["valid"] then --everything that isn't a sound or a quote goes here
                                    tableStr = tableStr .. " " .. chunkStr
                                    prevStr = chunkStr
                                end

                                prevType = chunkType
                            end
                            tableStr = cleanDoubleSpaces(tableStr) --removes double spaces, ignores colors
                            tableStr = tableStr:gsub(' "%s', ' "')
                            tableStr = tableStr:gsub("}}{{", "...") --for multiple radios
                            tableStr = tableStr:gsub("}}{", "...") --for multiple radios
                            tableStr = tableStr:gsub("}{{", "...") --for multiple radios
                            tableStr = tableStr:gsub("}{", "...") --for multiple radios
                            tableStr = trim(tableStr)

                            message.text = tableStr
                        end
                    end

                    message.portrait = message.portrait and message.portrait ~= "" and message.portrait
                        or message.connection
                    if copiedMessage then
                        message.processed = true
                        world.sendEntityMessage(receiverEntityId, "scc_add_message", message)
                    end
                end

                -- FezzedOne: If both SCCRP and Dynamic Proximity Chat are installed, always show SCCRP Proximity messages as such, even if handled by DPC.
                if message.isSccrp then message.mode = "Proximity" end
                -- FezzedOne: Show Local and Broadcast messages as such, even if formatted by DPC.
                if showAsLocal then message.mode = "Local" end
                if isGlobalChat then message.mode = "Broadcast" end

                if xsb and message.contentIsText then
                    if message.isSccrp then
                        handleMessage(receiverEntityId)
                    else
                        for _, pId in ipairs(ownPlayers) do
                            handleMessage(pId, copy(message))
                        end
                        message.text = ""
                    end
                elseif message.contentIsText then
                    if message.isSccrp then
                        handleMessage(receiverEntityId)
                    else
                        handleMessage(receiverEntityId, copy(message))
                        message.text = ""
                    end
                else
                    handleMessage(receiverEntityId)
                end
            end
        end

        if showAsProximity then message.mode = "Proximity" end
        if showAsLocal then message.mode = "Local" end
        if isGlobalChat then message.mode = "Broadcast" end

        return message
    end
    -- return messageFormatter(rawMessage)

    local messageData = copy(rawMessage)
    local rawText = messageData.text
    local status, messageOrError = pcall(messageFormatter, rawMessage)
    if status then
        return messageOrError
    else
        sb.logWarn(
            "[DynamicProxChat] Error occurred while formatting proximity message: %s\n  Message data: %s",
            messageOrError,
            messageData
        )
        rawMessage.text = rawText
        return rawMessage
    end
end

function dynamicprox:onReceiveMessage(message) --here for logging the message you receive, just in case you wanted to save it or something
    if message.connection ~= 0 and (message.mode == "Prox" or message.mode == "ProxSecondary") then
        sb.logInfo("Chat: <%s> %s", message.nickname:gsub("%^[^^;]-;", ""), message.text:gsub("%^[^^;]-;", ""))
    end
end
