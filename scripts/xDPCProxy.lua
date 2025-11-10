-- FezzedOne: This script is needed to correctly handle language items on secondary players. Now also handles name tags on xStarbound. --

local function getNames()
    local currentName = status.statusProperty("currentName")
    currentName = type(currentName) == "string" and currentName
    local defaultName = status.statusProperty("defaultName")
    defaultName = type(defaultName) == "string" and defaultName
    return currentName, defaultName
end

function init()
    message.setHandler("hasLangKey", function(_, isLocal, langKey)
        if isLocal then return player.getItemWithParameter("langKey", langKey) end
    end)
    message.setHandler("langKeyCount", function(_, isLocal, langKeyItem)
        if isLocal then return player.hasCountOfItem(langKeyItem, true) end
    end)
    message.setHandler("getCommCodes", function(_, isLocal)
        if isLocal then return player.getProperty("xDPC::commCodes") or { ["0"] = false } end
    end)
    message.setHandler("setCommCodes", function(_, isLocal, newCommCodes)
        if isLocal then return player.setProperty("xDPC::commCodes", newCommCodes or { ["0"] = false }) end
    end)
    message.setHandler("getDefaultCommCode", function(_, isLocal, newDefault)
        if isLocal then
            local default = player.getProperty("xDPC::defaultCommCode")
            if default ~= nil then
                return default
            else
                return "0"
            end
        end
    end)
    message.setHandler("setDefaultCommCode", function(_, isLocal, newDefault)
        if isLocal then
            if newDefault == nil then newDefault = "0" end
            return player.setProperty("xDPC::defaultCommCode", newDefault)
        end
    end)
    message.setHandler("showRecog", function(_, _, aliasInfo)
        --[[
        aliasInfo = {
                    ["alias"] = playerAliases[aliasPrio],
                    ["priority"] = aliasPrio,
                    ["UUID"] = player.uniqueId()
                }
        ]]
        local recoged = player.getProperty("xDPC::recognizedPlayers") or {}
        local playerUid = aliasInfo.UUID or nil
        if not playerUid then return false end
        local playerRecog = recoged[playerUid] or nil
        if not playerRecog or (playerRecog and playerRecog.aliasPrio <= aliasInfo.priority) then
            -- FezzedOne: Allowed updating aliases at the same priority level.
            --check priority, apply if new is higher
            playerRecog = {
                ["savedName"] = aliasInfo.alias,
                ["manName"] = false,
                ["aliasPrio"] = aliasInfo.priority,
            }
            recoged[playerUid] = playerRecog
            player.setProperty("xDPC::recognizedPlayers", recoged)
            return true
        end
    end)
    message.setHandler("receiverName", function(_, isLocal)
        if isLocal then
            local _, defaultName = getNames()
            return defaultName
        end
    end)

    message.setHandler("xdpcGetRecogs", function(_, isLocal)
        if isLocal then return player.getProperty("xDPC::recognizedPlayers") or {} end
    end)

    message.setHandler("xdpcSetRecogs", function(_, isLocal, newRecogs)
        if isLocal then player.setProperty("xDPC::recognizedPlayers", newRecogs) end
    end)

    local currentName, defaultName = getNames()
    if not defaultName then status.setStatusProperty("defaultName", player.name()) end

    if xsb then
        -- FezzedOne: Hides the name tag (or sets a custom one) on *all* clients seeing the player, not just oSB clients.
        -- With DPC installed on xSB, use `/setname` instead of `/identity set name` for changing the character's name.
        player.setName(currentName or "")
    elseif player.setName then -- FezzedOne: On OpenStarbound and StarExtensions, undoes xStarbound's name tag change.
        local defaultName = status.statusProperty("defaultName")
        if type(defaultName) == "string" then player.setName(defaultName) end
        status.setStatusProperty("defaultName", nil)
    end
end

function uninit()
    if xsb then
        -- FezzedOne: If your player has no name in the character selection screen due to a sudden disconnection or similar,
        -- just load the player once and unload it or return to the main to ensure this code runs and the player gets its name back.
        local _, defaultName = getNames()
        if defaultName then
            player.setName(defaultName or "")
            status.setStatusProperty("defaultName", nil)
        end
    end
end
