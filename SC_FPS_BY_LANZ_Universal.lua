-- SC FPS | Farhan Store - Low Texture Edition
-- Local visual optimization only. Does NOT modify Roblox FastFlags or network routing.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("SCFPS_FarhanStore")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = gethui() end)
if not gui.Parent then gui.Parent = playerGui end

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(248, 124)
frame.Position = UDim2.new(0.5, -124, 0.42, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 20, 23)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 11)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(55, 220, 115)
stroke.Thickness = 1.3

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 37)
top.BackgroundColor3 = Color3.fromRGB(27, 33, 30)
top.BorderSizePixel = 0
top.Parent = frame
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 11)
local cover = Instance.new("Frame", top)
cover.Size = UDim2.new(1, 0, 0, 10)
cover.Position = UDim2.new(0, 0, 1, -10)
cover.BackgroundColor3 = top.BackgroundColor3
cover.BorderSizePixel = 0

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 0)
title.Size = UDim2.new(1, -48, 1, 0)
title.Font = Enum.Font.Arcade
title.Text = "SC FPS"
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(90, 255, 145)
title.Parent = top

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(27, 25)
close.Position = UDim2.new(1, -32, 0, 6)
close.BackgroundColor3 = Color3.fromRGB(45, 52, 48)
close.Text = "×"
close.TextSize = 19
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.fromRGB(240, 240, 240)
close.BorderSizePixel = 0
close.Parent = top
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(13, 42)
status.Size = UDim2.new(1, -26, 0, 18)
status.Font = Enum.Font.GothamMedium
status.Text = "FPS MODE  •  OFF"
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(190, 198, 204)
status.Parent = frame

local pingLabel = Instance.new("TextLabel")
pingLabel.BackgroundTransparency = 1
pingLabel.Position = UDim2.fromOffset(13, 59)
pingLabel.Size = UDim2.new(1, -26, 0, 17)
pingLabel.Font = Enum.Font.Gotham
pingLabel.Text = "PING  •  membaca..."
pingLabel.TextSize = 10
pingLabel.TextXAlignment = Enum.TextXAlignment.Left
pingLabel.TextColor3 = Color3.fromRGB(170, 185, 178)
pingLabel.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Position = UDim2.fromOffset(12, 83)
toggle.Size = UDim2.new(1, -24, 0, 29)
toggle.BackgroundColor3 = Color3.fromRGB(42, 49, 45)
toggle.BorderSizePixel = 0
toggle.Font = Enum.Font.GothamBold
toggle.Text = "FPS BOOST: OFF"
toggle.TextSize = 11
toggle.TextColor3 = Color3.fromRGB(240, 244, 241)
toggle.Parent = frame
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 7)

local active = false
local saved = { parts = {}, decals = {}, effects = {}, shadows = nil }
local function applyLowTexture()
    saved.shadows = Lighting.GlobalShadows
    Lighting.GlobalShadows = false
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("PostEffect") then
            saved.effects[obj] = obj.Enabled
            obj.Enabled = false
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            saved.parts[obj] = {Material = obj.Material, Reflectance = obj.Reflectance}
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            saved.decals[obj] = obj.Transparency
            obj.Transparency = 1
        end
    end
    active = true
end
local function restore()
    if saved.shadows ~= nil then Lighting.GlobalShadows = saved.shadows end
    for obj, values in pairs(saved.parts) do
        if obj and obj.Parent then pcall(function() obj.Material = values.Material; obj.Reflectance = values.Reflectance end) end
    end
    for obj, value in pairs(saved.decals) do
        if obj and obj.Parent then pcall(function() obj.Transparency = value end) end
    end
    for obj, value in pairs(saved.effects) do
        if obj and obj.Parent then pcall(function() obj.Enabled = value end) end
    end
    saved = {parts = {}, decals = {}, effects = {}, shadows = nil}
    active = false
end
local function updateUI()
    if active then
        status.Text = "FPS MODE  •  ON"
        status.TextColor3 = Color3.fromRGB(90, 255, 145)
        toggle.Text = "FPS BOOST: ON"
        toggle.BackgroundColor3 = Color3.fromRGB(25, 135, 72)
    else
        status.Text = "FPS MODE  •  OFF"
        status.TextColor3 = Color3.fromRGB(190, 198, 204)
        toggle.Text = "FPS BOOST: OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(42, 49, 45)
    end
end
toggle.MouseButton1Click:Connect(function()
    if active then restore() else applyLowTexture() end
    updateUI()
end)
close.MouseButton1Click:Connect(function()
    if active then restore() end
    gui:Destroy()
end)

-- Draggable title bar
local dragging, dragStart, startPos
 top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Display ping if this Roblox client exposes the statistic; this does not lower ping.
task.spawn(function()
    while gui.Parent do
        local ok, value = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        end)
        pingLabel.Text = ok and ("PING  •  " .. tostring(value)) or "PING  •  tidak tersedia"
        task.wait(2)
    end
end)
updateUI()
