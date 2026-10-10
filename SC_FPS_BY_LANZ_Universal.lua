
-- ============================================================
-- SC FPS | FARHAN STORE - COMPLETE SAFE VERSION
-- FPS Boost | Low Texture | Black Sky | Anti-Blur
-- Mild Full Bright | Safe No Shake | Ping | Right Alt GUI
-- ============================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remove duplicate GUI
local previous = PlayerGui:FindFirstChild("SCFPS_FarhanStore")
if previous then
    previous:Destroy()
end

local state = {
    fpsBoost = false,
    antiBlur = false,
    fullBright = false,
    noShake = false,
    guiVisible = true
}

local originalLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation
}

local originalObjects = setmetatable({}, {__mode = "k"})
local originalSky = setmetatable({}, {__mode = "k"})
local originalEffects = setmetatable({}, {__mode = "k"})

-- ============================================================
-- VISUAL SETTINGS
-- ============================================================

local function rememberObject(obj)
    if originalObjects[obj] then return end

    local data = {}

    pcall(function()
        if obj:IsA("BasePart") then
            data.Material = obj.Material
            data.Reflectance = obj.Reflectance
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            data.Transparency = obj.Transparency
        end
    end)

    originalObjects[obj] = data
end

local function optimizeInstance(obj)
    if not state.fpsBoost then return end

    rememberObject(obj)

    pcall(function()
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Beam") then
            if originalEffects[obj] == nil then
                originalEffects[obj] = obj.Enabled
            end
            obj.Enabled = false
        elseif obj:IsA("BlurEffect") then
            if originalEffects[obj] == nil then
                originalEffects[obj] = obj.Enabled
            end
            obj.Enabled = false
        end
    end)
end

local function applyBlackSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            if not originalSky[obj] then
                originalSky[obj] = {
                    CelestialBodiesShown = obj.CelestialBodiesShown,
                    StarCount = obj.StarCount,
                    SunAngularSize = obj.SunAngularSize,
                    MoonAngularSize = obj.MoonAngularSize
                }
            end

            pcall(function()
                obj.CelestialBodiesShown = false
                obj.StarCount = 0
                obj.SunAngularSize = 0
                obj.MoonAngularSize = 0
            end)
        end
    end
end

local function restoreSky()
    for sky, data in pairs(originalSky) do
        if sky and sky.Parent then
            pcall(function()
                for property, value in pairs(data) do
                    sky[property] = value
                end
            end)
        end
    end
end

local function applyFPSBoost()
    if state.fpsBoost then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeInstance(obj)
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        applyBlackSky()
    else
        for obj, data in pairs(originalObjects) do
            if obj and obj.Parent then
                pcall(function()
                    for property, value in pairs(data) do
                        obj[property] = value
                    end
                end)
            end
        end

        for obj, enabled in pairs(originalEffects) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Enabled = enabled
                end)
            end
        end

        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.FogEnd = originalLighting.FogEnd
        restoreSky()
    end
end

-- ============================================================
-- ANTI-BLUR / SAFE NO SHAKE
-- ============================================================

local function disableBlurEffects()
    local function check(container)
        if not container then return end

        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("BlurEffect") then
                if originalEffects[obj] == nil then
                    originalEffects[obj] = obj.Enabled
                end

                pcall(function()
                    obj.Enabled = false
                end)
            end
        end
    end

    check(Lighting)
    check(Workspace.CurrentCamera)
end

local function applyAntiBlur()
    if state.antiBlur or state.noShake then
        disableBlurEffects()
    else
        for obj, enabled in pairs(originalEffects) do
            if obj and obj.Parent and obj:IsA("BlurEffect") then
                pcall(function()
                    obj.Enabled = enabled
                end)
            end
        end
    end
end

-- This safe mode does not edit weapon settings or claim to
-- remove game-controlled weapon recoil/camera shake.
local function applyNoShake()
    applyAntiBlur()
end

-- ============================================================
-- MILD FULL BRIGHT - WORKS WITHOUT FORCING DAYTIME
-- ============================================================

local function applyFullBright()
    if state.fullBright then
        Lighting.Brightness = 2.2
        Lighting.Ambient = Color3.fromRGB(145, 145, 145)
        Lighting.OutdoorAmbient = Color3.fromRGB(165, 165, 165)
        Lighting.ExposureCompensation = 0.15
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.ExposureCompensation =
            originalLighting.ExposureCompensation
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

local function updateButton(key)
    local item = buttons[key]
    if not item then return end

    local enabled = state[key]
    item.button.Text = item.label ..
        (enabled and "  [ON]" or "  [OFF]")

    item.button.BackgroundColor3 = enabled
        and Color3.fromRGB(125, 30, 40)
        or Color3.fromRGB(48, 48, 56)
end

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

    buttons[key] = {
        button = button,
        label = label
    }

    button.MouseButton1Click:Connect(function()
        state[key] = not state[key]

        local ok, err = pcall(callback)
        if not ok then
            warn("[SC FPS] Toggle error:", err)
        end

        updateButton(key)
    end)
end

close.MouseButton1Click:Connect(function()
    state.guiVisible = false
    main.Visible = false
end)

createToggle("fpsBoost", "FPS Boost / Low Texture", 80, applyFPSBoost)
createToggle("antiBlur", "Anti-Blur", 120, applyAntiBlur)
createToggle("fullBright", "Full Bright (Mild)", 160, applyFullBright)
createToggle("noShake", "No Shake (Safe Mode)", 200, applyNoShake)

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

for key in pairs(buttons) do
    updateButton(key)
end

-- ============================================================
-- DRAGGABLE GUI
-- ============================================================

do
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

-- Right Alt toggles GUI visibility
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.RightAlt then
        state.guiVisible = not state.guiVisible
        main.Visible = state.guiVisible
    end
end)

-- ============================================================
-- AUTO-APPLY TO NEW OBJECTS
-- ============================================================

Workspace.DescendantAdded:Connect(function(obj)
    if state.fpsBoost then
        task.defer(function()
            if obj and obj.Parent then
                optimizeInstance(obj)
            end
        end)
    end
end)

Lighting.DescendantAdded:Connect(function(obj)
    if (state.antiBlur or state.noShake) and obj:IsA("BlurEffect") then
        task.defer(function()
            if obj and obj.Parent then
                disableBlurEffects()
            end
        end)
    end
end)

-- Reapply visual settings after respawn/camera replacement
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(function()
        if state.antiBlur or state.noShake then
            disableBlurEffects()
        end
    end)
end)

-- ============================================================
-- PING DISPLAY: UPDATE EVERY 0.1 SECONDS
-- ============================================================

task.spawn(function()
    while gui.Parent do
        local pingText = "Ping: N/A"

        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network
                and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats
                and serverStats:FindFirstChild("Data Ping")

            if dataPing then
                pingText = "Ping: " .. dataPing:GetValueString()
            end
        end)

        if pingLabel and pingLabel.Parent then
            pingLabel.Text = pingText
        end

        task.wait(0.1)
    end
end)

print("[SC FPS | Farhan Store] Loaded successfully.")
print("Right Alt = show/hide GUI | X = hide GUI only")
