-- Games/MM2/main.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local REPO_URL = "https://raw.githubusercontent.com/ВАШ_АККАУНТ/ВАШ_РЕПОЗИТОРИЙ/main/"

local UILibrary = loadstring(game:HttpGet(REPO_URL .. "Shared/ui_library.lua"))()
local Utils = loadstring(game:HttpGet(REPO_URL .. "Shared/utils.lua"))()
local ConnManager = Utils.NewConnectionManager()

local Config = {
    RoleESP = false,
    GunESP = false,
    AutoGun = false,
    AutoCoin = false,
    KillAura = false,
    HitboxExpander = false,
    HitboxSize = 15,
    AntiFling = false,
    SafeSpeed = 45
}

local roleHighlights = {}
local gunHighlight = nil
local activeTween = nil

local Window = UILibrary.CreateWindow("MM2 Premium Hub")
local CombatTab = Window:CreateTab("🎯 Combat")
local VisualsTab = Window:CreateTab("👁️ Visuals")
local MovementTab = Window:CreateTab("🏃 Movement")
local FarmTab = Window:CreateTab("💰 Farming")
local MiscTab = Window:CreateTab("⚙️ Misc")

-- ==================== СЛУЖЕБНЫЕ ФУНКЦИИ ====================

local function getPlayerRole(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    local function checkItem(itemName)
        return (char and char:FindFirstChild(itemName)) or (backpack and backpack:FindFirstChild(itemName))
    end

    if checkItem("Knife") then return "Murderer", Color3.fromRGB(255, 0, 0) end
    if checkItem("Gun") then return "Sheriff", Color3.fromRGB(0, 150, 255) end
    return "Innocent", Color3.fromRGB(0, 255, 0)
end

local function travelToBypass(targetPos)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local distance = (root.Position - targetPos).Magnitude
    local timeToTravel = distance / Config.SafeSpeed

    root.Anchored = true 
    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    activeTween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos) + Vector3.new(0, 3, 0)})
    
    activeTween:Play()
    local reached = false
    local conn
    conn = activeTween.Completed:Connect(function()
        reached = true
        if conn then conn:Disconnect() end
    end)

    while not reached and (Config.AutoCoin or Config.AutoGun) do task.wait(0.1) end
    root.Anchored = false
    return reached
end

-- ==================== 🎯 COMBAT (БОЙ) ====================

CombatTab:AddToggle("Hitbox Expander (Silent Aim)", false, function(state)
    Config.HitboxExpander = state
    if not state then
        -- Возвращаем нормальные размеры
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                p.Character.HumanoidRootPart.Transparency = 1
            end
        end
    end
end)

-- Расширение хитбоксов в реальном времени
ConnManager:Add(RunService.RenderStepped:Connect(function()
    if Config.HitboxExpander then
        local myRole = getPlayerRole(LocalPlayer)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local targetRole = getPlayerRole(p)
                
                -- Увеличиваем хитбокс Убийцы (если мы Шериф/Мирный) или всех (если мы Убийца)
                if myRole == "Sheriff" and targetRole == "Murderer" or myRole == "Murderer" then
                    p.Character.HumanoidRootPart.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    p.Character.HumanoidRootPart.Transparency = 0.7
                    p.Character.HumanoidRootPart.CanCollide = false
                end
            end
        end
    end
end))

CombatTab:AddToggle("Kill Aura (Только для Убийцы)", false, function(state)
    Config.KillAura = state
    if state then
        task.spawn(function()
            while Config.KillAura do
                local myRole = getPlayerRole(LocalPlayer)
                if myRole == "Murderer" and LocalPlayer.Character then
                    -- Экипируем нож автоматически
                    local knife = LocalPlayer.Backpack:FindFirstChild("Knife")
                    if knife then
                        LocalPlayer.Character.Humanoid:EquipTool(knife)
                    end

                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = Utils.GetDistance(LocalPlayer.Character.HumanoidRootPart, p.Character.HumanoidRootPart)
                            if dist < 15 then -- Радиус удара
                                VirtualUser:ClickButton1(Vector2.new(0, 0)) -- Имитация клика (удар)
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)

CombatTab:AddButton("Kill All (ТП ко всем + Удар)", function()
    local myRole = getPlayerRole(LocalPlayer)
    if myRole ~= "Murderer" then return end
    
    local knife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
    if knife then LocalPlayer.Character.Humanoid:EquipTool(knife) end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            myRoot.CFrame = p.Character.HumanoidRootPart.CFrame + Vector3.new(0, 0, 2)
            task.wait(0.2)
            VirtualUser:ClickButton1(Vector2.new())
            task.wait(0.1)
        end
    end
end)

-- ==================== 👁️ VISUALS (ВИЗУАЛ) ====================

VisualsTab:AddToggle("Role ESP (Красный/Синий/Зел)", false, function(state)
    Config.RoleESP = state
    if not state then
        for _, hl in pairs(roleHighlights) do pcall(function() hl:Destroy() end) end
        table.clear(roleHighlights)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Config.RoleESP then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local role, color = getPlayerRole(player)
                    if not roleHighlights[player] then
                        local hl = Instance.new("Highlight")
                        hl.FillTransparency = 0.5
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = (typeof(gethui) == "function" and gethui()) or player.Character
                        hl.Adornee = player.Character
                        roleHighlights[player] = hl
                    end
                    if roleHighlights[player] then
                        roleHighlights[player].FillColor = color
                        roleHighlights[player].OutlineColor = color
                    end
                end
            end
        end
    end
end)

VisualsTab:AddToggle("Gun Drop ESP", false, function(state)
    Config.GunESP = state
    if not state and gunHighlight then pcall(function() gunHighlight:Destroy() end) gunHighlight = nil end
end)

VisualsTab:AddToggle("Fullbright / X-Ray", false, function(state)
    game:GetService("Lighting").GlobalShadows = not state
    game:GetService("Lighting").Brightness = state and 3 or 1
end)

-- ==================== 🏃 MOVEMENT ====================

MovementTab:AddToggle("Speed Hack (Ускорение)", false, function(state)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = state and 35 or 16
    end
end)

MovementTab:AddToggle("Noclip (Сквозь стены)", false, function(state)
    Config.Noclip = state
end)

MovementTab:AddToggle("Anti-Fling (Якорь/Вес)", false, function(state)
    Config.AntiFling = state
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        -- Делаем персонажа невероятно тяжелым, чтобы другие не могли его откинуть
        char.HumanoidRootPart.CustomPhysicalProperties = state and PhysicalProperties.new(100, 0.3, 0.5) or PhysicalProperties.new(0.7, 0.3, 0.5)
    end
end)

ConnManager:Add(RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end))

-- ==================== 💰 FARMING (ФАРМ) ====================

FarmTab:AddToggle("Auto Grab Gun (TP к пистолету)", false, function(state)
    Config.AutoGun = state
    if state then
        task.spawn(function()
            while Config.AutoGun do
                local drop = nil
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj.Name == "GunDrop" and obj:IsA("BasePart") then drop = obj break end
                end
                
                if drop then
                    travelToBypass(drop.Position)
                    task.wait(1)
                end
                task.wait(0.5)
            end
        end)
    else
        if activeTween then activeTween:Cancel() end
    end
end)

FarmTab:AddToggle("Auto Farm Coins (Скрытный)", false, function(state)
    Config.AutoCoin = state
    if state then
        task.spawn(function()
            while Config.AutoCoin do
                local role = getPlayerRole(LocalPlayer)
                if role == "Innocent" then -- Фармим монеты, только если мы мирные
                    local coin = nil
                    pcall(function()
                        for _, c in ipairs(Workspace.Normal.CoinContainer:GetChildren()) do
                            if c.Name == "Coin_Server" and c.Transparency == 0 then coin = c break end
                        end
                    end)
                    if coin then travelToBypass(coin.Position) else task.wait(1) end
                else
                    task.wait(2)
                end
                task.wait(0.1)
            end
        end)
    else
        if activeTween then activeTween:Cancel() end
    end
end)

-- ==================== ⚙️ MISC ====================

MiscTab:AddButton("Role Reveal (Вывести в консоль)", function()
    print("----- РОЛИ ИГРОКОВ -----")
    for _, player in ipairs(Players:GetPlayers()) do
        local role = getPlayerRole(player)
        print(player.Name .. " - " .. role)
    end
    print("------------------------")
end)

-- Анти-АФК
MiscTab:AddToggle("Anti-AFK", false, function(state)
    if state then
        local vu = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end
end)
