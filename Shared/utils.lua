-- Shared/utils.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Utils = {}
Utils.__index = Utils

local activeHighlights = {}
local activeDrawings = {}

-- ==================== ESP: HIGHLIGHT ====================
function Utils.CreateHighlightESP(player, fillColor, outlineColor)
    if player == LocalPlayer then return end
    Utils.RemoveHighlightESP(player)

    local function apply(char)
        if not char then return end
        local hl = Instance.new("Highlight")
        hl.Name = "Hub_Highlight"
        hl.Adornee = char
        hl.FillColor = fillColor or Color3.fromRGB(0, 170, 255)
        hl.OutlineColor = outlineColor or Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local parent = (typeof(gethui) == "function" and gethui()) or char
        hl.Parent = parent
        activeHighlights[player] = hl
    end

    if player.Character then apply(player.Character) end

    local conn = player.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        apply(char)
    end)

    return conn
end

function Utils.RemoveHighlightESP(player)
    if activeHighlights[player] then
        pcall(function() activeHighlights[player]:Destroy() end)
        activeHighlights[player] = nil
    end
end

-- ==================== ESP: DRAWING 2D BOX & TRACERS ====================
function Utils.CreateDrawingESP(player, color)
    if player == LocalPlayer or not Drawing then return end
    Utils.RemoveDrawingESP(player)

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = color or Color3.fromRGB(0, 255, 140)
    box.Thickness = 1.5
    box.Filled = false

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = color or Color3.fromRGB(0, 255, 140)
    tracer.Thickness = 1

    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Size = 13
    nameTag.Center = true
    nameTag.Outline = true

    activeDrawings[player] = { Box = box, Tracer = tracer, Name = nameTag }

    local updater
    updater = RunService.RenderStepped:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            box.Visible = false
            tracer.Visible = false
            nameTag.Visible = false
            return
        end

        local root = player.Character.HumanoidRootPart
        local head = player.Character:FindFirstChild("Head") or root
        
        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        if onScreen then
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height * 0.65

            -- Отрисовка бокса
            box.Size = Vector2.new(width, height)
            box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
            box.Visible = true

            -- Отрисовка трасера (снизу экрана)
            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            tracer.To = Vector2.new(rootPos.X, rootPos.Y + height / 2)
            tracer.Visible = true

            -- Ник и дистанция
            local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
            nameTag.Text = player.Name .. " [" .. dist .. "m]"
            nameTag.Position = Vector2.new(rootPos.X, rootPos.Y - height / 2 - 15)
            nameTag.Visible = true
        else
            box.Visible = false
            tracer.Visible = false
            nameTag.Visible = false
        end
    end)

    return updater
end

function Utils.RemoveDrawingESP(player)
    if activeDrawings[player] then
        pcall(function()
            activeDrawings[player].Box:Remove()
            activeDrawings[player].Tracer:Remove()
            activeDrawings[player].Name:Remove()
        end)
        activeDrawings[player] = nil
    end
end

-- ==================== МАТЕМАТИКА И AIMBOT ХЕЛПЕРЫ ====================

-- Поиск ближайшего к прицелу мыши игрока в пределах FOV
function Utils.GetClosestPlayerToCursor(fovRadius, checkWalls)
    local mousePos = UserInputService:GetMouseLocation()
    local target = nil
    local shortestDist = fovRadius or math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local root = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                if screenDist < shortestDist then
                    if checkWalls then
                        if Utils.IsVisible(root.Position, {LocalPlayer.Character, player.Character}) then
                            shortestDist = screenDist
                            target = player
                        end
                    else
                        shortestDist = screenDist
                        target = player
                    end
                end
            end
        end
    end

    return target
end

-- Проверка, видна ли точка (сквозь стены)
function Utils.IsVisible(targetPos, ignoreList)
    local origin = Camera.CFrame.Position
    local direction = (targetPos - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or {LocalPlayer.Character}
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    return result == nil -- Если луч ни во что не врезался, враг виден
end

-- Дистанция в студах/метрах
function Utils.GetDistance(pos1, pos2)
    local v1 = (typeof(pos1) == "Instance" and pos1:IsA("BasePart")) and pos1.Position or pos1
    local v2 = (typeof(pos2) == "Instance" and pos2:IsA("BasePart")) and pos2.Position or pos2

    if typeof(v1) == "Vector3" and typeof(v2) == "Vector3" then
        return math.floor((v1 - v2).Magnitude)
    end
    return 0
end

-- ==================== СИСТЕМА ОЧИСТКИ ====================
function Utils.ClearAllESP()
    for player, _ in pairs(activeHighlights) do
        Utils.RemoveHighlightESP(player)
    end
    for player, _ in pairs(activeDrawings) do
        Utils.RemoveDrawingESP(player)
    end
end

function Utils.NewConnectionManager()
    local manager = { Connections = {} }

    function manager:Add(connection)
        table.insert(self.Connections, connection)
        return connection
    end

    function manager:Cleanup()
        for _, conn in ipairs(self.Connections) do
            if typeof(conn) == "RBXScriptConnection" and conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(self.Connections)
    end

    return manager
end

return Utils
