-- Games/Tower_of_Hell/main.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Базовый URL репозитория
local REPO_URL = "https://raw.githubusercontent.com/ВАШ_АККАУНТ/ВАШ_РЕПОЗИТОРИЙ/main/"

local UILibrary = loadstring(game:HttpGet(REPO_URL .. "Shared/ui_library.lua"))()
local Utils = loadstring(game:HttpGet(REPO_URL .. "Shared/utils.lua"))()
local ConnManager = Utils.NewConnectionManager()

local Config = {
    Godmode = false,
    AntiFall = false,
    Fly = false,
    FlySpeed = 50,
    Fullbright = false
}

local Window = UILibrary.CreateWindow("Tower of Hell Hub")
local MainTab = Window:CreateTab("🏆 Main")
local MoveTab = Window:CreateTab("🏃 Movement")
local MiscTab = Window:CreateTab("⚙️ Misc")

local antiFallPart = nil

-- ==================== СЛУЖЕБНЫЕ ФУНКЦИИ ====================

-- Поиск финишной зоны на самом верху башни
local function getFinishBlock()
    local tower = Workspace:FindFirstChild("tower")
    if tower and tower:FindFirstChild("sections") then
        local finishSection = tower.sections:FindFirstChild("finish")
        if finishSection then
            return finishSection:FindFirstChildWhichIsA("BasePart", true)
        end
    end
    return nil
end

-- ==================== 🏆 MAIN (ОСНОВНОЕ) ====================

MainTab:AddToggle("Godmode (Неуязвимость)", false, function(state)
    Config.Godmode = state
    
    local function patchKillBrick(part)
        if part:IsA("BasePart") then
            -- В ToH убивающие блоки работают через событие касания (TouchInterest)
            if part:FindFirstChild("TouchInterest") then
                part.CanTouch = not state
            end
        end
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        patchKillBrick(obj)
    end

    if state then
        ConnManager:Add(Workspace.DescendantAdded:Connect(function(child)
            task.wait(0.1)
            if Config.Godmode then
                patchKillBrick(child)
            end
        end))
    end
end)

MainTab:AddButton("Auto Win (ТП на финиш)", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local finishBlock = getFinishBlock()
    
    if root then
        if finishBlock then
            root.CFrame = finishBlock.CFrame + Vector3.new(0, 5, 0)
        else
            -- Если структура башни не успела прогрузиться, телепортируем просто высоко вверх (стандартная высота башни ~300-350 стадов)
            root.CFrame = root.CFrame + Vector3.new(0, 350, 0)
        end
    end
end)

MainTab:AddButton("Пропустить 1 уровень (ТП вверх)", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        -- Высота одной секции в ToH примерно 50-60 стадов
        root.CFrame = root.CFrame + Vector3.new(0, 55, 0)
    end
end)

MainTab:AddToggle("Anti-Fall (Страховочный пол)", false, function(state)
    Config.AntiFall = state
    
    if state then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            antiFallPart = Instance.new("Part")
            antiFallPart.Name = "Hub_AntiFall"
            antiFallPart.Size = Vector3.new(100, 2, 100)
            antiFallPart.Anchored = true
            antiFallPart.Transparency = 0.5
            antiFallPart.Color = Color3.fromRGB(0, 255, 100)
            antiFallPart.Material = Enum.Material.ForceField
            antiFallPart.CFrame = root.CFrame - Vector3.new(0, 15, 0)
            
            local parent = (typeof(gethui) == "function" and gethui()) or Workspace
            antiFallPart.Parent = parent
        end
    else
        if antiFallPart then
            antiFallPart:Destroy()
            antiFallPart = nil
        end
    end
end)

MainTab:AddButton("Обновить высоту Anti-Fall", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if Config.AntiFall and antiFallPart and root then
        -- Поднимаем пол прямо под текущую позицию игрока
        antiFallPart.CFrame = root.CFrame - Vector3.new(0, 15, 0)
    end
end)

-- ==================== 🏃 MOVEMENT (ДВИЖЕНИЕ) ====================

local flyGyro, flyVelocity
MoveTab:AddToggle("Свободный полет (Fly)", false, function(state)
    Config.Fly = state
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if state then
        flyGyro = Instance.new("BodyGyro")
        flyGyro.P = 9e4
        flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyGyro.CFrame = root.CFrame
        flyGyro.Parent = root

        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.Velocity = Vector3.zero
        flyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyVelocity.Parent = root
    else
        if flyGyro then flyGyro:Destroy() end
        if flyVelocity then flyVelocity:Destroy() end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end)

ConnManager:Add(RunService.RenderStepped:Connect(function()
    if Config.Fly and flyVelocity and flyGyro and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        flyGyro.CFrame = Camera.CFrame
        local direction = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Camera.CFrame.RightVector end
        
        flyVelocity.Velocity = direction * Config.FlySpeed
    end
end))

MoveTab:AddToggle("Бесконечный прыжок", false, function(state)
    Config.InfJump = state
end)

ConnManager:Add(UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

MoveTab:AddToggle("Ускорение бега (Speed)", false, function(state)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = state and 35 or 16
    end
end)

-- ==================== ⚙️ MISC (РАЗНОЕ) ====================

local originalBrightness = Lighting.Brightness
local originalClock = Lighting.ClockTime

MiscTab:AddToggle("Fullbright (Убрать тьму)", false, function(state)
    Config.Fullbright = state
    if state then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = originalBrightness
        Lighting.ClockTime = originalClock
        Lighting.GlobalShadows = true
    end
end)

MiscTab:AddButton("Купить мутаторы (Требует коины)", function()
    -- Tower of Hell использует RemoteEvents для покупки мутаторов в магазине (invincibility, low gravity)
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("buyMutator") then
        -- Пытаемся купить "Неуязвимость" легально, если у игрока есть внутриигровые монеты
        pcall(function()
            remotes.buyMutator:InvokeServer("invincibility")
        end)
    end
end)
