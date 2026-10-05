local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WorkingMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main window
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 360, 0, 290)
main.Position = UDim2.new(0.5, -180, 0.5, -145)
main.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
main.BorderSizePixel = 0
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(90, 140, 255)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "WORKING MENU"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

-- Team section
local teamLabel = Instance.new("TextLabel")
teamLabel.Size = UDim2.new(0, 100, 0, 20)
teamLabel.Position = UDim2.new(0, 18, 0, 52)
teamLabel.BackgroundTransparency = 1
teamLabel.Text = "Team"
teamLabel.Font = Enum.Font.GothamMedium
teamLabel.TextSize = 14
teamLabel.TextColor3 = Color3.fromRGB(180, 190, 220)
teamLabel.Parent = main

local teamPanel = Instance.new("Frame")
teamPanel.Size = UDim2.new(1, -36, 0, 52)
teamPanel.Position = UDim2.new(0, 18, 0, 72)
teamPanel.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
teamPanel.BorderSizePixel = 0
teamPanel.Parent = main

local teamPanelCorner = Instance.new("UICorner")
teamPanelCorner.CornerRadius = UDim.new(0, 10)
teamPanelCorner.Parent = teamPanel

local teamButtons = {}
local teamColors = {
    Red = Color3.fromRGB(255, 90, 90),
    Blue = Color3.fromRGB(90, 140, 255),
    Spectator = Color3.fromRGB(150, 150, 180)
}

for index, name in ipairs({"Red", "Blue", "Spectator"}) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.33, -8, 1, -10)
    btn.Position = UDim2.new((index - 1) * 0.33, 5, 0, 5)
    btn.BackgroundColor3 = teamColors[name]
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = teamPanel

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    table.insert(teamButtons, btn)

    btn.MouseButton1Click:Connect(function()
        for _, other in ipairs(teamButtons) do
            other.BackgroundTransparency = 0
        end
        btn.BackgroundTransparency = 0.12
        print("Selected team:", name)
    end)
end

-- Settings
local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(0, 120, 0, 20)
settingsLabel.Position = UDim2.new(0, 18, 0, 138)
settingsLabel.BackgroundTransparency = 1
settingsLabel.Text = "Settings"
settingsLabel.Font = Enum.Font.GothamMedium
settingsLabel.TextSize = 14
settingsLabel.TextColor3 = Color3.fromRGB(180, 190, 220)
settingsLabel.Parent = main

local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(1, -36, 0, 72)
settingsPanel.Position = UDim2.new(0, 18, 0, 158)
settingsPanel.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
settingsPanel.BorderSizePixel = 0
settingsPanel.Parent = main

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 10)
settingsCorner.Parent = settingsPanel

local streamMode = false
local streamBtn = Instance.new("TextButton")
streamBtn.Size = UDim2.new(0.55, -12, 0, 26)
streamBtn.Position = UDim2.new(0, 10, 0, 10)
streamBtn.Text = "Stream Mode: Off"
streamBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 90)
streamBtn.TextColor3 = Color3.fromRGB(255,255,255)
streamBtn.Font = Enum.Font.GothamBold
streamBtn.TextSize = 12
streamBtn.BorderSizePixel = 0
streamBtn.Parent = settingsPanel

local streamCorner = Instance.new("UICorner")
streamCorner.CornerRadius = UDim.new(0, 8)
streamCorner.Parent = streamBtn

streamBtn.MouseButton1Click:Connect(function()
    streamMode = not streamMode
    streamBtn.Text = streamMode and "Stream Mode: On" or "Stream Mode: Off"
    streamBtn.BackgroundColor3 = streamMode and Color3.fromRGB(55,170,110) or Color3.fromRGB(70,75,90)
end)

-- Auto-allow / remember choice (safe pattern)
local isAutoAllowed = false
local rememberToggle = Instance.new("TextButton")
rememberToggle.Size = UDim2.new(0.35, -12, 0, 26)
rememberToggle.Position = UDim2.new(0.58, 0, 0, 10)
rememberToggle.Text = "Auto-allow: Off"
rememberToggle.BackgroundColor3 = Color3.fromRGB(80, 90, 110)
rememberToggle.TextColor3 = Color3.fromRGB(255,255,255)
rememberToggle.Font = Enum.Font.GothamBold
rememberToggle.TextSize = 11
rememberToggle.BorderSizePixel = 0
rememberToggle.Parent = settingsPanel

local rememberCorner = Instance.new("UICorner")
rememberCorner.CornerRadius = UDim.new(0, 8)
rememberCorner.Parent = rememberToggle

rememberToggle.MouseButton1Click:Connect(function()
    isAutoAllowed = not isAutoAllowed
    rememberToggle.Text = isAutoAllowed and "Auto-allow: On" or "Auto-allow: Off"
    rememberToggle.BackgroundColor3 = isAutoAllowed and Color3.fromRGB(80, 160, 110) or Color3.fromRGB(80, 90, 110)
end)

-- Radius and FOV panel
local sliderPanel = Instance.new("Frame")
sliderPanel.Size = UDim2.new(1, -36, 0, 52)
sliderPanel.Position = UDim2.new(0, 18, 0, 236)
sliderPanel.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
sliderPanel.BorderSizePixel = 0
sliderPanel.Parent = main

local sliderPanelCorner = Instance.new("UICorner")
sliderPanelCorner.CornerRadius = UDim.new(0, 10)
sliderPanelCorner.Parent = sliderPanel

local radiusValue = 40
local fovValue = 70

local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0, 80, 0, 16)
radiusLabel.Position = UDim2.new(0, 8, 0, 8)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Radius: 40"
radiusLabel.Font = Enum.Font.GothamBold
radiusLabel.TextSize = 12
radiusLabel.TextColor3 = Color3.fromRGB(200,210,255)
radiusLabel.Parent = sliderPanel

local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(0, 70, 0, 16)
fovLabel.Position = UDim2.new(0.52, 0, 0, 8)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV: 70"
fovLabel.Font = Enum.Font.GothamBold
fovLabel.TextSize = 12
fovLabel.TextColor3 = Color3.fromRGB(200,210,255)
fovLabel.Parent = sliderPanel

local radiusSlider = Instance.new("TextButton")
radiusSlider.Size = UDim2.new(0.42, -8, 0, 12)
radiusSlider.Position = UDim2.new(0, 8, 0, 30)
radiusSlider.Text = ""
radiusSlider.BackgroundColor3 = Color3.fromRGB(110,120,140)
radiusSlider.BorderSizePixel = 0
radiusSlider.Parent = sliderPanel

local radiusSliderCorner = Instance.new("UICorner")
radiusSliderCorner.CornerRadius = UDim.new(0, 6)
radiusSliderCorner.Parent = radiusSlider

local fovSlider = Instance.new("TextButton")
fovSlider.Size = UDim2.new(0.42, -8, 0, 12)
fovSlider.Position = UDim2.new(0.52, 0, 0, 30)
fovSlider.Text = ""
fovSlider.BackgroundColor3 = Color3.fromRGB(110,120,140)
fovSlider.BorderSizePixel = 0
fovSlider.Parent = sliderPanel

local fovSliderCorner = Instance.new("UICorner")
fovSliderCorner.CornerRadius = UDim.new(0, 6)
fovSliderCorner.Parent = fovSlider

local radiusFill = Instance.new("Frame")
radiusFill.Size = UDim2.new(0.5, 0, 1, 0)
radiusFill.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
radiusFill.BorderSizePixel = 0
radiusFill.Parent = radiusSlider

local radiusFillCorner = Instance.new("UICorner")
radiusFillCorner.CornerRadius = UDim.new(0, 6)
radiusFillCorner.Parent = radiusFill

local fovFill = Instance.new("Frame")
fovFill.Size = UDim2.new(0.5, 0, 1, 0)
fovFill.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
fovFill.BorderSizePixel = 0
fovFill.Parent = fovSlider

local fovFillCorner = Instance.new("UICorner")
fovFillCorner.CornerRadius = UDim.new(0, 6)
fovFillCorner.Parent = fovFill

local function updateRadiusVisual()
    radiusFill.Size = UDim2.new(radiusValue / 100, 0, 1, 0)
    radiusLabel.Text = "Radius: " .. tostring(radiusValue)
end

local function updateFovVisual()
    fovFill.Size = UDim2.new(fovValue / 100, 0, 1, 0)
    fovLabel.Text = "FOV: " .. tostring(fovValue)
end

radiusSlider.MouseButton1Click:Connect(function()
    radiusValue = math.clamp(radiusValue + 10, 10, 100)
    updateRadiusVisual()
end)

fovSlider.MouseButton1Click:Connect(function()
    fovValue = math.clamp(fovValue + 10, 20, 100)
    updateFovVisual()
end)

updateRadiusVisual()
updateFovVisual()
