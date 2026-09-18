local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local REPO_OWNER = "Aitasik"
local REPO_NAME = "aitasielo-hub"
local BRANCH = "main"
local BASE_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", REPO_OWNER, REPO_NAME, BRANCH)

local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1550463795292409957/entC-IAH6c1W7uGG6DiDz1p727yt3MQakIbu2urWBLyIBD87Uh1XRULAqEoxgIeFM4Tp"

local GAME_ROUTING = {
    [142823291]  = {name = "Murder Mystery 2", path = "Games/MM2/main.lua"},
    [1962086868] = {name = "Tower of Hell",     path = "Games/Tower_of_Hell/main.lua"},
    -- Впишите реальные PlaceId вместо 0:
    [107778070777162]          = {name = "Steal an Egg",      path = "Games/Steal_an_Grade/main.lua"},
    [13772394625]          = {name = "Blade Ball",              path = "Games/Blade_Ball/main.lua"},
}

local UNIVERSAL_MODULE = {name = "Universal", path = "Universal/main.lua"}

local function getDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
        return "Console"
    else
        return "PC"
    end
end

local function sendWebhookNotification(targetGameName)
    if not DISCORD_WEBHOOK_URL or DISCORD_WEBHOOK_URL == "" then
    return
end

    local payload = {
        ["embeds"] = {{
            ["title"] = "Запуск Script Hub",
            ["color"] = 0x5865F2,
            ["fields"] = {
                {["name"] = "Игрок", ["value"] = LocalPlayer.Name, ["inline"] = true},
                {["name"] = "User ID", ["value"] = tostring(LocalPlayer.UserId), ["inline"] = true},
                {["name"] = "Устройство", ["value"] = getDeviceType(), ["inline"] = true},
                {["name"] = "Режим", ["value"] = targetGameName, ["inline"] = true},
                {["name"] = "Place ID", ["value"] = tostring(game.PlaceId), ["inline"] = true},
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    local requestFunction = (syn and syn.request) or (http and http.request) or http_request or request
    if requestFunction then
        pcall(function()
            requestFunction({
                Url = DISCORD_WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end
end

-- Загрузка и исполнение удаленного модуля
local function executeModule(moduleInfo)
    local fileUrl = BASE_URL .. moduleInfo.path

    task.spawn(function()
        sendWebhookNotification(moduleInfo.name)
    end)

    local success, scriptContent = pcall(function()
        return game:HttpGet(fileUrl)
    end)

    if not success or not scriptContent or scriptContent == "" then
        warn(string.format("[Loader Error] Не удалось скачать модуль '%s' по URL: %s", moduleInfo.name, fileUrl))
        return
    end

    local compiledFunc, compileError = loadstring(scriptContent)
    if not compiledFunc then
        warn(string.format("[Loader Error] Ошибка компиляции модуля '%s': %s", moduleInfo.name, tostring(compileError)))
        return
    end

    local execSuccess, runtimeError = pcall(compiledFunc)
    if not execSuccess then
        warn(string.format("[Loader Error] Ошибка исполнения модуля '%s': %s", moduleInfo.name, tostring(runtimeError)))
    end
end

-- Маршрутизация по текущему PlaceId
local currentPlaceId = game.PlaceId
local selectedModule = GAME_ROUTING[currentPlaceId] or UNIVERSAL_MODULE

executeModule(selectedModule)
