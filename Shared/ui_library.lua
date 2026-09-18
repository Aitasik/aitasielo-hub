-- Shared/ui_library.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local UILibrary = {}
UILibrary.__index = UILibrary

local ACCENT_COLOR = Color3.fromRGB(0, 170, 255) -- Неоновый синий акцент

local function getSafeParent()
    if typeof(gethui) == "function" then
        return gethui()
    end
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success and coreGui then
        return coreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function animate(instance, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(instance, tweenInfo, properties):Play()
end

function UILibrary.CreateWindow(titleText)
    local self = setmetatable({}, UILibrary)
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StandaloneHub_UI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = getSafeParent()
    self.ScreenGui = screenGui

    -- Главное окно
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 520, 0, 340)
    mainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    -- Стильная тонкая неоновая рамка
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(35, 35, 45)
    stroke.Thickness = 1.2
    stroke.Parent = mainFrame

    -- Заголовок
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 42)
    titleLabel.Position = UDim2.new(0, 18, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleText or "Script Hub"
    titleLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = mainFrame

    -- Разделительная линия
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 42)
    divider.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    divider.BorderSizePixel = 0
    divider.Parent = mainFrame

    -- Сайдбар вкладок
    local tabSidebar = Instance.new("ScrollingFrame")
    tabSidebar.Size = UDim2.new(0, 130, 1, -55)
    tabSidebar.Position = UDim2.new(0, 10, 0, 48)
    tabSidebar.BackgroundTransparency = 1
    tabSidebar.ScrollBarThickness = 0
    tabSidebar.Parent = mainFrame

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.Padding = UDim.new(0, 6)
    sidebarLayout.Parent = tabSidebar

    -- Область контента
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -160, 1, -55)
    contentContainer.Position = UDim2.new(0, 150, 0, 48)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    self.TabSidebar = tabSidebar
    self.ContentContainer = contentContainer
    self.Tabs = {}

    self:SetupAdaptiveControls()
    return self
end

function UILibrary:SetupAdaptiveControls()
    local isVisible = true

    local function toggleVisibility()
        isVisible = not isVisible
        self.MainFrame.Visible = isVisible
    end

    if UserInputService.TouchEnabled then
        local floatBtn = Instance.new("TextButton")
        floatBtn.Name = "FloatToggle"
        floatBtn.Size = UDim2.new(0, 48, 0, 48)
        floatBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
        floatBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        floatBtn.Text = "HUB"
        floatBtn.TextColor3 = ACCENT_COLOR
        floatBtn.Font = Enum.Font.GothamBold
        floatBtn.TextSize = 13
        floatBtn.Parent = self.ScreenGui

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = floatBtn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = ACCENT_COLOR
        btnStroke.Thickness = 1.5
        btnStroke.Parent = floatBtn

        local dragging, dragStart, startPos
        floatBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = floatBtn.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = input.Position - dragStart
                floatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        floatBtn.Activated:Connect(toggleVisibility)
    else
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
                toggleVisibility()
            end
        end)
    end
end

function UILibrary:CreateTab(name)
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(1, 0, 0, 32)
    tabButton.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    tabButton.Text = name
    tabButton.TextColor3 = Color3.fromRGB(150, 150, 165)
    tabButton.Font = Enum.Font.GothamMedium
    tabButton.TextSize = 13
    tabButton.Parent = self.TabSidebar

    local tabBtnCorner = Instance.new("UICorner")
    tabBtnCorner.CornerRadius = UDim.new(0, 6)
    tabBtnCorner.Parent = tabButton

    local pageFrame = Instance.new("ScrollingFrame")
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.BackgroundTransparency = 1
    pageFrame.ScrollBarThickness = 2
    pageFrame.ScrollBarImageColor3 = Color3.fromRGB(45, 45, 55)
    pageFrame.Visible = (#self.Tabs == 0)
    pageFrame.Parent = self.ContentContainer

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = pageFrame

    table.insert(self.Tabs, { Button = tabButton, Page = pageFrame })

    if #self.Tabs == 1 then
        tabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        tabButton.TextColor3 = ACCENT_COLOR
    end

    tabButton.Activated:Connect(function()
        for _, tab in ipairs(self.Tabs) do
            tab.Page.Visible = (tab.Page == pageFrame)
            local isCurrent = (tab.Button == tabButton)
            animate(tab.Button, {
                BackgroundColor3 = isCurrent and Color3.fromRGB(30, 30, 40) or Color3.fromRGB(22, 22, 28),
                TextColor3 = isCurrent and ACCENT_COLOR or Color3.fromRGB(150, 150, 165)
            })
        end
    end)

    local tabMethods = {}

    function tabMethods:AddToggle(label, default, callback)
        local state = default or false

        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(1, -6, 0, 38)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        toggleFrame.Parent = pageFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = toggleFrame

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -50, 1, 0)
        text.Position = UDim2.new(0, 12, 0, 0)
        text.BackgroundTransparency = 1
        text.Text = label
        text.TextColor3 = Color3.fromRGB(220, 220, 230)
        text.Font = Enum.Font.Gotham
        text.TextSize = 13
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.Parent = toggleFrame

        local indicator = Instance.new("TextButton")
        indicator.Size = UDim2.new(0, 22, 0, 22)
        indicator.Position = UDim2.new(1, -32, 0.5, -11)
        indicator.BackgroundColor3 = state and ACCENT_COLOR or Color3.fromRGB(38, 38, 48)
        indicator.Text = ""
        indicator.Parent = toggleFrame

        local indCorner = Instance.new("UICorner")
        indCorner.CornerRadius = UDim.new(0, 4)
        indCorner.Parent = indicator

        indicator.Activated:Connect(function()
            state = not state
            animate(indicator, {
                BackgroundColor3 = state and ACCENT_COLOR or Color3.fromRGB(38, 38, 48)
            })
            if callback then callback(state) end
        end)
    end

    function tabMethods:AddButton(label, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
        btn.Text = label
        btn.TextColor3 = Color3.fromRGB(235, 235, 245)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.Parent = pageFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        btn.Activated:Connect(function()
            animate(btn, { BackgroundColor3 = ACCENT_COLOR, TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.08)
            task.wait(0.08)
            animate(btn, { BackgroundColor3 = Color3.fromRGB(26, 26, 34), TextColor3 = Color3.fromRGB(235, 235, 245) }, 0.12)
            if callback then callback() end
        end)
    end

    return tabMethods
end

return UILibrary
