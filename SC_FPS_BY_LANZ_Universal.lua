-- ============================================================
-- SC FPS | Farhan Store - Complete
-- FPS Boost | Low Texture | Black Sky | Anti-Blur
-- Mild Full Bright | No Recoil/Shake | Ping | Right Alt GUI
-- ============================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicate GUIs when re-executed
local previous = PlayerGui:FindFirstChild("SCFPS_FarhanStore")
if previous then previous:Destroy() end

local state = {
    fpsBoost = false,
    antiBlur = false,
    fullBright = false,
    noShake = false,
    guiVisible = true,
}

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
}

local originalObjects = setmetatable({}, { __mode = "k" })
local processing = false

-- ============================================================
-- NO SHAKE / NO RECOIL (user-provided function)
-- ============================================================
local function applyNoRecoil(tool)
    if not tool or not tool:IsA("Tool") then return end
    local s = tool:FindFirstChild("Setting")
    if not s or not s:IsA("ModuleScript") then return end
    pcall(function()
        local m = require(s)
        if type(m) ~= "table" then return end
        if m.Recoil ~= nil then m.Recoil = 0 end
        if m.RecoilAmount ~= nil then m.RecoilAmount = 0 end
        if m.CameraRecoil ~= nil then m.CameraRecoil = 0 end
        if m.CameraShake ~= nil then m.CameraShake = 0 end
        if m.Kick ~= nil then m.Kick = 0 end
        if m.Kickback ~= nil then m.Kickback = 0 end
        if m.VerticalRecoil ~= nil then m.VerticalRecoil = 0 end
        if m.HorizontalRecoil ~= nil then m.HorizontalRecoil = 0 end
        if m.RecoilX ~= nil then m.RecoilX = 0 end
        if m.RecoilY ~= nil then m.RecoilY = 0 end
        if m.GunRecoil ~= nil then m.GunRecoil = 0 end
        if m.WeaponRecoil ~= nil then m.WeaponRecoil = 0 end
        if m.AimRecoil ~= nil then m.AimRecoil = 0 end
        if m.ShakeAmount ~= nil then m.ShakeAmount = 0 end
        if m.ShakeIntensity ~= nil then m.ShakeIntensity = 0 end
    end)
end

local function scanTools(container)
    if not container then return end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") then applyNoRecoil(item) end
    end
end

local function applyNoRecoilToCharacter()
    scanTools(LocalPlayer:FindFirstChildOfClass("Backpack"))
    scanTools(LocalPlayer.Character)
end

-- ============================================================
-- VISUAL OPTIMIZATION
-- ============================================================
local function saveOriginal(instance)
    if originalObjects[instance] then return end
    local data = {}
    pcall(function()
        if instance:IsA("BasePart") then
            data.Material = instance.Material
            data.Reflectance = instance.Reflectance
        elseif instance:IsA("Decal") or instance:IsA("Texture") then
            data.Transparency = instance.Transparency
        elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
            data.Enabled = instance.Enabled
        elseif instance:IsA("PostEffect") then
            data.Enabled = instance.Enabled
        end
    end)
    originalObjects[instance] = data
end

local function optimizeInstance(instance)
    if not state.fpsBoost then return end
    saveOriginal(instance)
    pcall(function()
        if instance:IsA("BasePart") then
            instance.Material = Enum.Material.SmoothPlastic
            instance.Reflectance = 0
        elseif instance:IsA("Decal") or instance:IsA("Texture") then
            instance.Transparency = 1
        elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
            instance.Enabled = false
        elseif instance:IsA("PostEffect") and instance:IsA("BlurEffect") then
            instance.Enabled = false
        end
    end)
end

local function applyFPSBoost()
    if state.fpsBoost then
        for _, obj in ipairs(workspace:GetDescendants()) do
            optimizeInstance(obj)
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        -- Black sky: hide celestial bodies without deleting the Sky instance.
        for _, sky in ipairs(Lighting:GetChildren()) do
            if sky:IsA("Sky") then
                pcall(function()
                    sky.CelestialBodiesShown = false
                    sky.StarCount = 0
                    sky.SunAngularSize = 0
                    sky.MoonAngularSize = 0
                end)
            end
        end
    else
        for instance, data in pairs(originalObjects) do
            if instance and instance.Parent then
                pcall(function()
                    for property, value in pairs(data) do
                        instance[property] = value
                    end
                end)
            end
        end
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.FogEnd = originalLighting.FogEnd
    end
end

local function applyAntiBlur()
    if not state.antiBlur then return end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("BlurEffect") then
            pcall(function() obj.Enabled = false end)
        end
    end
    local camera = workspace.CurrentCamera
    if camera then
        for _, obj in ipairs(camera:GetChildren()) do
            if obj:IsA("BlurEffect") then
                pcall(function() obj.Enabled = false end)
            end
        end
    end
end

local function applyFullBright()
    if state.fullBright then
        Lighting.Brightness = 2.2
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(145, 145, 145)
        Lighting.OutdoorAmbient = Color3.fromRGB(165, 165, 165)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
end

local function applyBlackSky()
    -- Hides sky visuals without deleting the game's Sky object.
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            pcall(function()
                obj.CelestialBodiesShown = false
                obj.StarCount = 0
                obj.SunAngularSize = 0
                obj.MoonAngularSize = 0
            end)
        end
    end
end

-- ============================================================
-- GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(300, 330)
main.Position = UDim2.new(0, 24, 0.32, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(220, 55, 65)
stroke.Thickness = 1.5
stroke.Parent = main

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(145, 25, 35)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -72, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "SC FPS | FARHAN STORE"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local close = Instance.new("TextButton")
close.Name = "HideButton"
close.Size = UDim2.fromOffset(32, 28)
close.Position = UDim2.new(1, -38, 0, 7)
close.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.Parent = header
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function()
    state.guiVisible = false
    main.Visible = false -- X only hides the GUI; features remain enabled
end)

local pingLabel = Instance.new("TextLabel")
pingLabel.Name = "PingLabel"
pingLabel.Size = UDim2.new(1, -24, 0, 24)
pingLabel.Position = UDim2.fromOffset(12, 48)
pingLabel.BackgroundColor3 = Color3.fromRGB(31, 31, 38)
pingLabel.Text = "Ping: ..."
pingLabel.TextColor3 = Color3.fromRGB(100, 220, 130)
pingLabel.TextSize = 12
pingLabel.Font = Enum.Font.GothamMedium
pingLabel.Parent = main
Instance.new("UICorner", pingLabel).CornerRadius = UDim.new(0, 5)

local buttons = {}
local function createToggle(key, label, y, callback)
    local button = Instance.new("TextButton")
    button.Name = key .. "Toggle"
    button.Size = UDim2.new(1, -24, 0, 34)
    button.Position = UDim2.fromOffset(12, y)
    button.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamSemibold
    button.Parent = main
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    buttons[key] = { button = button, label = label }
    button.MouseButton1Click:Connect(function()
        state[key] = not state[key]
        callback()
        updateButton(key)
    end)
end

function updateButton(key)
    local item = buttons[key]
    if not item then return end
    local enabled = state[key]
    item.button.Text = item.label .. (enabled and "  [ON]" or "  [OFF]")
    item.button.BackgroundColor3 = enabled and Color3.fromRGB(125, 30, 40) or Color3.fromRGB(48, 48, 56)
end

createToggle("fpsBoost", "FPS Boost / Low Texture", 80, applyFPSBoost)
createToggle("antiBlur", "Anti-Blur", 120, applyAntiBlur)
createToggle("fullBright", "Full Bright (mild)", 160, applyFullBright)
createToggle("noShake", "No Shake / No Recoil", 200, applyNoRecoilToCharacter)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -24, 0, 38)
note.Position = UDim2.fromOffset(12, 244)
note.BackgroundTransparency = 1
note.Text = "Right Alt: tampil/sembunyi GUI\nX: sembunyikan GUI saja"
note.TextColor3 = Color3.fromRGB(190, 190, 200)
note.TextSize = 11
note.Font = Enum.Font.Gotham
note.TextWrapped = true
note.Parent = main

for key in pairs(buttons) do updateButton(key) end

-- Make the panel draggable by its header.
do
    local dragging = false
    local dragInput, dragStart, startPosition
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
end

-- Right Alt toggles visibility. X only hides; Right Alt can show it again.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        state.guiVisible = not state.guiVisible
        main.Visible = state.guiVisible
    end
end)

-- Re-apply visual options to new objects as they appear.
workspace.DescendantAdded:Connect(function(obj)
    if state.fpsBoost then task.defer(function() optimizeInstance(obj) end) end
end)

Lighting.ChildAdded:Connect(function(obj)
    if state.antiBlur and obj:IsA("BlurEffect") then
        task.defer(function() pcall(function() obj.Enabled = false end) end)
    end
    if state.fpsBoost and obj:IsA("Sky") then
        task.defer(applyBlackSky)
    end
end)

-- Ping display refreshes every 0.1 seconds.
task.spawn(function()
    while gui.Parent do
        local pingText = "Ping: N/A"
        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")
            if dataPing then pingText = "Ping: " .. tostring(dataPing:GetValueString()) end
        end)
        if pingLabel and pingLabel.Parent then pingLabel.Text = pingText end
        task.wait(0.1)
    end
end)

-- Keep No Recoil applied to tools that are equipped or added later.
task.spawn(function()
    while gui.Parent do
        if state.noShake then applyNoRecoilToCharacter() end
        task.wait(0.5)
    end
end)

print("[SC FPS | Farhan Store] Loaded successfully.")
print("Right Alt = show/hide GUI | X = hide GUI only")
