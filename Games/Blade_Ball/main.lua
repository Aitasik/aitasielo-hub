-- Games/Blade_Ball/main.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager") -- Надежнее для кликов
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Замени на свой актуальный адрес репозитория
local REPO_URL = "https://raw.githubusercontent.com/ВАШ_АККАУНТ/ВАШ_РЕПОЗИТОРИЙ/main/"

local UILibrary = loadstring(game:HttpGet(REPO_URL .. "Shared/ui_library.lua"))()
local Utils = loadstring(game:HttpGet(REPO_URL .. "Shared/utils.lua"))()

local ConnManager = Utils.NewConnectionManager()

local Config = {
    AutoParry = false,
    AutoSpam = false, -- Для близких дистанций (Clash)
    ParryDistance = 25, -- Статическая дистанция подстраховки
    ReactionTime = 0.4, -- Время реакции (в секундах) до удара
    BallESP = false
}

local Window = UILibrary.CreateWindow("Blade Ball Hub")
local CombatTab = Window:CreateTab("⚔️ Combat")
local VisualsTab = Window:CreateTab("👁️ Visuals")

local activeBallHighlight = nil

-- ==================== СЛУЖЕБНЫЕ ФУНКЦИИ ====================

-- Поиск мяча на карте (в Blade Ball мяч обычно спавнится в Workspace и называется "Ball" или находится в папке Balls)
local function getRealBall()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Ball" and obj.Transparency < 1 then
            return obj
        end
    end
    return nil
end

-- Функция имитации левого клика мыши (Блок)
local function triggerParry()
    -- VirtualInputManager лучше обходит базовые защиты от автокликеров, чем VirtualUser
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- ==================== ⚔️ COMBAT (БОЙ) ====================

CombatTab:AddToggle("Auto-Parry (Умный блок)", false, function(state)
    Config.AutoParry = state
end)

CombatTab:AddToggle("Auto-Spam (Авто-клик вблизи)", false, function(state)
    Config.AutoSpam = state
end)

-- Основной цикл расчета траектории и авто-блока
ConnManager:Add(RunService.RenderStepped:Connect(function()
    if not (Config.AutoParry or Config.AutoSpam) then return end
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local ball = getRealBall()
    if not ball then return end

    -- Высчитываем дистанцию и скорость
    local distance = (root.Position - ball.Position).Magnitude
    local velocity = ball.Velocity.Magnitude

    -- Логика для Auto-Spam (Clash - когда мяч пингует между двумя игроками впритык)
    if Config.AutoSpam and distance <= 15 then
        triggerParry()
        return -- Прерываем, чтобы не считать дальше
    end

    if not Config.AutoParry then return end

    -- Проверка: Летит ли мяч в нашу сторону?
    -- Используем Dot Product: если значение близко к 1, мяч летит прямо в нас
    local directionToMe = (root.Position - ball.Position).Unit
    local ballDirection = ball.Velocity.Unit
    local dotProduct = directionToMe:Dot(ballDirection)

    -- Если мяч летит в нас (dotProduct > 0.5) или он уже экстремально близко
    if dotProduct > 0.3 or distance <= Config.ParryDistance then
        -- Высчитываем, через сколько секунд мяч врежется в нас
        local timeToImpact = distance / (velocity > 0 and velocity or 1)

        -- Если время до удара меньше нашей реакции ИЛИ он в мертвой зоне — бьем!
        if timeToImpact <= Config.ReactionTime or distance <= Config.ParryDistance then
            triggerParry()
        end
    end
end))

-- ==================== 👁️ VISUALS (ВИЗУАЛ) ====================

VisualsTab:AddToggle("Ball ESP (Подсветка мяча)", false, function(state)
    Config.BallESP = state
    
    if not state and activeBallHighlight then
        activeBallHighlight:Destroy()
        activeBallHighlight = nil
    end
end)

-- Обновление ESP мяча
task.spawn(function()
    while task.wait(0.1) do
        if Config.BallESP then
            local ball = getRealBall()
            if ball then
                if not activeBallHighlight then
                    activeBallHighlight = Instance.new("Highlight")
                    activeBallHighlight.FillColor = Color3.fromRGB(255, 0, 50)
                    activeBallHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    activeBallHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    activeBallHighlight.Parent = (typeof(gethui) == "function" and gethui()) or ball
                end
                activeBallHighlight.Adornee = ball
            elseif activeBallHighlight then
                activeBallHighlight:Destroy()
                activeBallHighlight = nil
            end
        end
    end
end)

-- ==================== НАСТРОЙКИ СКРИПТА ====================

VisualsTab:AddButton("Настроить тайминги", function()
    print("Тайминги авто-паррирования зависят от вашего пинга.")
    print("Текущая дистанция страховки: " .. Config.ParryDistance)
    print("Текущее время реакции: " .. Config.ReactionTime .. " сек.")
end)

-- Отключаем коллизии с игроками, чтобы нас не толкали во время потной катки
ConnManager:Add(RunService.Stepped:Connect(function()
    if LocalPlayer.Character then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end))
