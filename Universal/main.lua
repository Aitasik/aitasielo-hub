-- Universal/main.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 1. Ссылки на Shared-модули (Замени на свой актуальный репозиторий)
local REPO_URL = "https://raw.githubusercontent.com/ВАШ_АККАУНТ/ВАШ_РЕПОЗИТОРИЙ/main/"

local UILibrary = loadstring(game:HttpGet(REPO_URL .. "Shared/ui_library.lua"))()
local Utils = loadstring(game:HttpGet(REPO_URL .. "Shared/utils.lua"))()

-- Менеджер соединений для безопасного отключения
local ConnManager = Utils.NewConnectionManager()

-- Состояния функций
local Config = {
    SpeedEnabled = false,
    SpeedValue = 32,
    JumpEnabled = false,
    JumpValue = 80,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    InfJump = false,
    Fullbright = false,
    ESP = false
}

-- Инициализация окна
local Window = UILibrary.CreateWindow("Universal Hub")
local MoveTab = Window:CreateTab("Movement")
local VisualsTab = Window:CreateTab("Visuals")

-- ==================== ДВИЖЕНИЕ (MOVEMENT) ====================

-- Speed
MoveTab:AddToggle("Speed Boost", false, function(state)
    Config.SpeedEnabled = state
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = state and Config.SpeedValue or 16
    end
end)

-- JumpPower
MoveTab:AddToggle("High Jump", false, function(state)
    Config.JumpEnabled = state
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.UseJumpPower = true
        char.Humanoid.JumpPower = state and Config.JumpValue or 50
    end
end)

-- Noclip (Сквозь стены)
MoveTab:AddToggle("Noclip", false, function(state)
    Config.Noclip = state
end)

ConnManager:Add(RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end))

-- Infinite Jump (Бесконечный прыжок)
MoveTab:AddToggle("Infinite Jump", false, function(state)
    Config.InfJump = state
end)

ConnManager:Add(UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

-- Fly (Полет)
local flyBodyGyro, flyBodyVelocity
MoveTab:AddToggle("Fly", false, function(state)
    Config.Fly = state
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not root then return end

    if state then
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.CFrame = root.CFrame
        flyBodyGyro.Parent = root

        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.zero
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = root
    else
        if flyBodyGyro then flyBodyGyro:Destroy() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if char:FindFirstChild("Humanoid") then
            char.Humanoid.PlatformStand = false
        end
    end
end)

ConnManager:Add(RunService.RenderStepped:Connect(function()
    if Config.Fly and LocalPlayer.Character and flyBodyVelocity and flyBodyGyro then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then humanoid.PlatformStand = true end

        local moveDirection = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserФайл `Universal/main.lua` выступает запасным (fallback) скриптом: он запускается, если текущий `PlaceId` не совпал ни с одной конкретной игрой. Его задача — загрузить интерфейс из `ui_library.lua`, подключить `utils.lua` и предоставить базовый набор функций для управления персонажем и визуализацией.

Ниже приведена реализация `Universal/main.lua`. В начале скрипта укажите ваш GitHub-аккаунт и имя репозитория в переменной `BASE_URL`.

```lua
-- Universal/main.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Базовый URL к сырым файлам вашего репозитория
local BASE_URL = "[https://raw.githubusercontent.com/ВАШ_АККАУНТ/ВАШ_РЕПОЗИТОРИЙ/main/](https://raw.githubusercontent.com/ВАШ_АККАУНТ/ВАШ_РЕПОЗИТОРИЙ/main/)"

-- Подгрузка общих зависимостей
local UILibrary = loadstring(game:HttpGet(BASE_URL .. "Shared/ui_library.lua"))()
local Utils = loadstring(game:HttpGet(BASE_URL .. "Shared/utils.lua"))()

-- Менеджер соединений для чистого завершения работы
local ConnManager = Utils.NewConnectionManager()

-- Состояние функций
local Settings = {
    SpeedEnabled = false,
    SpeedValue = 32,
    InfiniteJump = false,
    Noclip = false,
    Fullbright = false,
    ESPEnabled = false
}

-- Инициализация окна интерфейса
local Window = UILibrary.CreateWindow("Universal Hub")
local MovementTab = Window:CreateTab("Передвижение")
local VisualsTab = Window:CreateTab("Визуал")
local MiscTab = Window:CreateTab("Разное")

-- ==================== ПЕРЕДВИЖЕНИЕ ====================

-- Изменение скорости бега
MovementTab:AddToggle("Увеличенная скорость", false, function(state)
    Settings.SpeedEnabled = state
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = state and Settings.SpeedValue or 16
    end
end)

-- Noclip (проход сквозь коллизии стен)
local noclipConnection
MovementTab:AddToggle("Noclip (Сквозь стены)", false, function(state)
    Settings.Noclip = state
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        ConnManager:Add(noclipConnection)
    else
        if noclipConnection and noclipConnection.Connected then
            noclipConnection:Disconnect()
        end
    end
end)

-- Бесконечный прыжок
MovementTab:AddToggle("Бесконечный прыжок", false, function(state)
    Settings.InfiniteJump = state
end)

local jumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
    if Settings.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
ConnManager:Add(jumpConnection)

-- ==================== ВИЗУАЛ ====================

-- Подсветка всех игроков (ESP)
VisualsTab:AddToggle("Highlight ESP", false, function(state)
    Settings.ESPEnabled = state
    if state then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                Utils.CreateHighlightESP(player, Color3.fromRGB(0, 170, 255))
            end
        end
        -- Автоматически вешаем подсветку на входящих игроков
        local addedConn = Players.PlayerAdded:Connect(function(player)
            if Settings.ESPEnabled then
                Utils.CreateHighlightESP(player, Color3.fromRGB(0, 170, 255))
            end
        end)
        ConnManager:Add(addedConn)
    else
        Utils.ClearAllESP()
    end
end)

-- Полная яркость (Fullbright)
local originalBrightness = Lighting.Brightness
local originalClock = Lighting.ClockTime
VisualsTab:AddToggle("Fullbright (Освещение)", false, function(state)
    Settings.Fullbright = state
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = originalBrightness
        Lighting.ClockTime = originalClock
        Lighting.GlobalShadows = true
    end
end)

-- ==================== РАЗНОЕ ====================

-- Быстрый ресет персонажа
MiscTab:AddButton("Самоуничтожение (Reset)", function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
    end
end)

-- Телепортация к случайному игроку
MiscTab:AddButton("ТП к случайному игроку", function()
    local allPlayers = Players:GetPlayers()
    local targets = {}
    for _, p in ipairs(allPlayers) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(targets, p)
        end
    end

    if #targets > 0 then
        local randomPlayer = targets[math.random(1, #targets)]
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
            myRoot.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
        end
    end
end)

-- Автосброс характеристик при респавне
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid", 3)
    if hum and Settings.SpeedEnabled then
        hum.WalkSpeed = Settings.SpeedValue
    end
end)
