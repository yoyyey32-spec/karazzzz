
-- SC FPS | FARHAN STORE
-- PROJECT CODE: 201303
-- Low Texture + Anti-Blur + Anti-Reflection
-- Mild Full Bright + CameraOffset Shake Reduction + Ping
-- Right Alt = Show/Hide GUI | X = Hide GUI

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
    local old = playerGui:FindFirstChild("SCFPS_FarhanStore")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = playerGui

local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 7)
    c.Parent = obj
end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 230)
frame.Position = UDim2.new(0, 25, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(23, 24, 31)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
round(frame, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(85, 88, 112)
stroke.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(34, 36, 47)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = frame
round(titleBar, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -45, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "Farhan Store"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.Arcade
title.TextSize = 17
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 27)
close.Position = UDim2.new(1, -35, 0, 4)
close.BackgroundColor3 = Color3.fromRGB(170, 55, 65)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.Arcade
close.TextSize = 14
close.BorderSizePixel = 0
close.Parent = titleBar
round(close, 6)

local ping = Instance.new("TextLabel")
ping.Size = UDim2.new(1, -20, 0, 24)
ping.Position = UDim2.fromOffset(10, 42)
ping.BackgroundColor3 = Color3.fromRGB(31, 33, 43)
ping.Text = "ROBLOX PING: ..."
ping.TextColor3 = Color3.new(1, 1, 1)
ping.Font = Enum.Font.Code
ping.TextSize = 12
ping.BorderSizePixel = 0
ping.Parent = frame
round(ping, 6)

local function makeButton(text, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.fromOffset(10, y)
    b.BackgroundColor3 = Color3.fromRGB(49, 52, 67)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Arcade
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.Parent = frame
    round(b, 6)
    return b
end

local fpsBtn = makeButton("FPS BOOST: OFF", 73)
local brightBtn = makeButton("FULL BRIGHT: OFF", 108)
local shakeBtn = makeButton("NO SHAKE: OFF", 143)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 25)
hint.Position = UDim2.fromOffset(10, 181)
hint.BackgroundTransparency = 1
hint.Text = "Right Alt: Show / Hide"
hint.TextColor3 = Color3.fromRGB(165, 170, 185)
hint.Font = Enum.Font.Code
hint.TextSize = 11
hint.Parent = frame

local ON = Color3.fromRGB(42, 125, 86)
local OFF = Color3.fromRGB(49, 52, 67)

local fpsEnabled = false
local brightEnabled = false
local shakeEnabled = false

local savedParts = {}
local savedEffects = {}
local savedLighting = nil

local textureConnection
local lightingConnection
local cameraConnection
local cameraChangedConnection
local shakeConnection
local blackSky

local function updateButton(button, name, enabled)
    button.Text = name .. (enabled and ": ON" or ": OFF")
    button.BackgroundColor3 = enabled and ON or OFF
end

-- Skip character parts and fence objects to preserve their appearance.
local function isCharacterOrFence(obj)
    local current = obj
    while current and current ~= Workspace do
        local name = string.lower(current.Name)

        if current:IsA("Model")
            and Players:GetPlayerFromCharacter(current) then
            return true
        end

        if string.find(name, "fence", 1, true)
            or string.find(name, "pagar", 1, true)
            or string.find(name, "railing", 1, true)
            or string.find(name, "gate", 1, true) then
            return true
        end

        current = current.Parent
    end

    return false
end

-- LOW TEXTURE + REDUCE REFLECTION
local function optimizeObject(obj)
    if not obj:IsA("BasePart") then return end
    if isCharacterOrFence(obj) then return end

    if not savedParts[obj] then
        savedParts[obj] = {
            Material = obj.Material,
            Reflectance = obj.Reflectance
        }
    end

    pcall(function()
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
    end)
end

local function setLowTexture(enabled)
    if enabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeObject(obj)
        end

        if textureConnection then
            textureConnection:Disconnect()
        end

        textureConnection = Workspace.DescendantAdded:Connect(function(obj)
            if fpsEnabled then
                task.defer(function()
                    if fpsEnabled and obj.Parent then
                        optimizeObject(obj)
                    end
                end)
            end
        end)
    else
        if textureConnection then
            textureConnection:Disconnect()
            textureConnection = nil
        end

        for obj, old in pairs(savedParts) do
            if obj.Parent then
                pcall(function()
                    obj.Material = old.Material
                    obj.Reflectance = old.Reflectance
                end)
            end
        end

        table.clear(savedParts)
    end
end

-- ANTI-BLUR + POST EFFECTS
local function disableEffect(obj)
    if not obj:IsA("PostEffect") then return end
    if obj == blackSky then return end

    if savedEffects[obj] == nil then
        savedEffects[obj] = obj.Enabled
    end

    pcall(function()
        obj.Enabled = false
    end)
end

local function scanEffects(container)
    if not container then return end

    for _, obj in ipairs(container:GetDescendants()) do
        disableEffect(obj)
    end
end

local function watchCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end

    local camera = Workspace.CurrentCamera
    if not fpsEnabled or not camera then return end

    scanEffects(camera)

    cameraConnection = camera.DescendantAdded:Connect(function(obj)
        if fpsEnabled then
            task.defer(function()
                if fpsEnabled and obj.Parent then
                    disableEffect(obj)
                end
            end)
        end
    end)
end

local function setFPS(enabled)
    fpsEnabled = enabled

    if enabled then
        setLowTexture(true)

        blackSky = Instance.new("ColorCorrectionEffect")
        blackSky.Name = "SCFPS_BlackSky"
        blackSky.Brightness = -0.12
        blackSky.Contrast = 0.02
        blackSky.Saturation = -0.12
        blackSky.Parent = Lighting

        scanEffects(Lighting)
        watchCamera()

        if lightingConnection then
            lightingConnection:Disconnect()
        end

        lightingConnection = Lighting.DescendantAdded:Connect(function(obj)
            if fpsEnabled then
                task.defer(function()
                    if fpsEnabled and obj.Parent then
                        disableEffect(obj)
                    end
                end)
            end
        end)

        if cameraChangedConnection then
            cameraChangedConnection:Disconnect()
        end

        cameraChangedConnection =
            Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
                if fpsEnabled then
                    watchCamera()
                end
            end)
    else
        if lightingConnection then
            lightingConnection:Disconnect()
            lightingConnection = nil
        end

        if cameraConnection then
            cameraConnection:Disconnect()
            cameraConnection = nil
        end

        if cameraChangedConnection then
            cameraChangedConnection:Disconnect()
            cameraChangedConnection = nil
        end

        setLowTexture(false)

        if blackSky then
            blackSky:Destroy()
            blackSky = nil
        end

        for obj, old in pairs(savedEffects) do
            if obj.Parent then
                pcall(function()
                    obj.Enabled = old
                end)
            end
        end

        table.clear(savedEffects)
    end

    updateButton(fpsBtn, "FPS BOOST", fpsEnabled)
end

-- MILD FULL BRIGHT
local function setFullBright(enabled)
    brightEnabled = enabled

    if enabled then
        if not savedLighting then
            savedLighting = {
                Brightness = Lighting.Brightness,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                Exposure = Lighting.ExposureCompensation
            }
        end

        pcall(function()
            Lighting.Brightness = math.max(Lighting.Brightness, 2.2)
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(115, 115, 125)
            Lighting.OutdoorAmbient = Color3.fromRGB(135, 135, 145)
            Lighting.ExposureCompensation = 0.15
        end)
    else
        if savedLighting then
            pcall(function()
                Lighting.Brightness = savedLighting.Brightness
                Lighting.GlobalShadows = savedLighting.GlobalShadows
                Lighting.Ambient = savedLighting.Ambient
                Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
                Lighting.ExposureCompensation = savedLighting.Exposure
            end)
            savedLighting = nil
        end
    end

    updateButton(brightBtn, "FULL BRIGHT", brightEnabled)
end

-- SHAKE REDUCTION: Humanoid.CameraOffset only.
-- This does not guarantee removal of weapon recoil.
local function setNoShake(enabled)
    shakeEnabled = enabled

    if shakeConnection then
        shakeConnection:Disconnect()
        shakeConnection = nil
    end

    if enabled then
        shakeConnection = RunService.RenderStepped:Connect(function()
            local character = player.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.CameraOffset.Magnitude > 0.001 then
                humanoid.CameraOffset = Vector3.zero
            end
        end)
    end

    updateButton(shakeBtn, "NO SHAKE", shakeEnabled)
end

fpsBtn.MouseButton1Click:Connect(function()
    setFPS(not fpsEnabled)
end)

brightBtn.MouseButton1Click:Connect(function()
    setFullBright(not brightEnabled)
end)

shakeBtn.MouseButton1Click:Connect(function()
    setNoShake(not shakeEnabled)
end)

-- X hides the GUI only.
close.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        frame.Visible = not frame.Visible
    end
end)

-- DRAG GUI
local dragging = false
local dragStart, startPos, dragInput

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- PING
-- Reads Roblox's reported Data Ping value without inventing a number.
-- Roblox's value can differ from a game's custom ping display.
task.spawn(function()
    while gui.Parent do
        local valueText

        pcall(function()
            valueText =
                Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        end)

        if valueText then
            ping.Text = "ROBLOX PING: " .. valueText

            local number = tonumber(valueText:match("[%d%.]+"))

            if number and number < 100 then
                ping.TextColor3 = Color3.fromRGB(100, 230, 145)
            elseif number and number < 180 then
                ping.TextColor3 = Color3.fromRGB(245, 205, 95)
            else
                ping.TextColor3 = Color3.fromRGB(255, 105, 105)
            end
        else
            ping.Text = "ROBLOX PING: N/A"
            ping.TextColor3 = Color3.fromRGB(210, 215, 230)
        end

        task.wait(0.1)
    end
end)
