-- Games/Steal_an_Grade/main.lua (Bypass Anti-Cheat Version)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Замени на свой актуальный адрес репозитория
local REPO_URL = "https://raw.githubusercontent.com/ВАШ_АККАУНТ/ВАШ_РЕПОЗИТОРИЙ/main/"

local UILibrary = loadstring(game:HttpGet(REPO_URL .. "Shared/ui_library.lua"))()
local Utils = loadstring(game:HttpGet(REPO_URL .. "Shared/utils.lua"))()

local ConnManager = Utils.NewConnectionManager()

-- Состояния и настройки
local State = {
    AutoFarmLoop = false,
    InstantInteract = false,
    AntiTraps = false,
    ItemESP = false,
    BaseSafeSpot = nil,
    FarmDelay = 0.5,
    IgnoreGuards = false,
    SafeSpeed = 45 -- БЕЗОПАСНАЯ СКОРОСТЬ (Если кикает, уменьши до 35. Если не кикает, пробуй 60)
}

local itemHighlights = {}
local activeTween = nil -- Храним текущий полет, чтобы можно было прервать

-- UI Окно
local Window = UILibrary.CreateWindow("Steal an Egg (Bypass)")
local FarmTab = Window:CreateTab("Auto Farm")
local VisualsTab = Window:CreateTab("Visuals")
local DefenseTab = Window:CreateTab("Defense")

-- ==================== BYPASS ПЕРЕМЕЩЕНИЕ ====================

local function getTargets()
    local targets = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("egg") or name:find("grade") or name:find("collect") or obj:IsA("ProximityPrompt") then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart") or obj.Parent:FindFirstChildWhichIsA("BasePart")
            if part and not table.find(targets, part) then
                table.insert(targets, part)
            end
        end
    end
    return targets
end

-- Обход античита: Плавный полет без физики (CFrame Tweening)
local function travelToBypass(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- Высчитываем дистанцию, чтобы лететь с одинаковой скоростью
    local distance = (root.Position - targetCFrame.Position).Magnitude
    local timeToTravel = distance / State.SafeSpeed

    -- Чтобы гравитация и античит не мешали, замораживаем физику
    root.Anchored = true 

    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    activeTween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame + Vector3.new(0, 2.5, 0)})
    
    activeTween:Play()
    
    -- Ждем, пока долетит
    local reached = false
    local connection
    connection = activeTween.Completed:Connect(function(playbackState)
        reached = true
        if connection then connection:Disconnect() end
    end)

    -- Ждем завершения твина, но с проверкой, не отключили ли фарм
    while not reached and State.AutoFarmLoop do
        task.wait(0.1)
    end

    -- Возвращаем физику
    root.Anchored = false
    
    if not State.AutoFarmLoop and activeTween then
        activeTween:Cancel()
    end
    
    return reached
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if typeof(fireproximityprompt) == "function" then
        fireproximityprompt(prompt)
    else
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end
end

-- ==================== ВКЛАДКА: AUTO FARM ====================

FarmTab:AddButton("Установить точку сдачи (Базу)", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        State.BaseSafeSpot = root.CFrame
    end
end)

FarmTab:AddToggle("Auto Farm (Bypass)", false, function(active)
    State.AutoFarmLoop = active

    if active then
        task.spawn(function()
            while State.AutoFarmLoop do
                local list = getTargets()
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                if root and #list > 0 then
                    for _, item in ipairs(list) do
                        if not State.AutoFarmLoop then break end

                        -- Используем безопасный перелет
                        local success = travelToBypass(item.CFrame)
                        
                        if success and State.AutoFarmLoop then
                            task.wait(0.1)
                            local prompt = item:FindFirstChildOfClass("ProximityPrompt") or item.Parent:FindFirstChildOfClass("ProximityPrompt")
                            if prompt then
                                triggerPrompt(prompt)
                            end

                            task.wait(State.FarmDelay)

                            -- Возврат на базу
                            if State.BaseSafeSpot then
                                travelToBypass(State.BaseSafeSpot)
                                task.wait(0.2)
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        -- Если выключили фарм — отменяем полет в воздухе и размораживаем перса
        if activeTween then activeTween:Cancel() end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored = false end
    end
end)

-- Обход античита на Noclip: отключаем коллизии только при фарме
ConnManager:Add(RunService.Stepped:Connect(function()
    if State.AutoFarmLoop and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end))

-- ==================== ВКЛАДКА: VISUALS И DEFENSE ====================

VisualsTab:AddToggle("ESP на яйца и предметы", false, function(state)
    State.ItemESP = state
    if state then
        for _, item in ipairs(getTargets()) do
            if not itemHighlights[item] then
                local hl = Instance.new("Highlight")
                hl.Adornee = item
                hl.FillColor = Color3.fromRGB(0, 255, 100)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = (typeof(gethui) == "function" and gethui()) or item
                itemHighlights[item] = hl
            end
        end
    else
        for _, hl in pairs(itemHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(itemHighlights)
    end
end)

DefenseTab:AddToggle("Anti-Traps / Lasers", false, function(state)
    local function patchTrap(part)
        if part:IsA("BasePart") then
            local n = part.Name:lower()
            if n:find("laser") or n:find("trap") or n:find("kill") or n:find("lava") then
                part.CanTouch = not state
                part.CanCollide = not state
                part.Transparency = state and 0.8 or 0
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do patchTrap(obj) end
end)
