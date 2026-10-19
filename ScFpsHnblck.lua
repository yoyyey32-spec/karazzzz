
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("SCFPS_FarhanStore")
if oldGui then oldGui:Destroy() end

local State = {
    fps = false,
    bright = false,
    interact = false,
    visible = true
}

local saved = setmetatable({}, {__mode = "k"})
local savedSky = setmetatable({}, {__mode = "k"})
local savedAtmos = setmetatable({}, {__mode = "k"})
local savedPrompts = setmetatable({}, {__mode = "k"})
local baseLighting = {}
local grayAtmosphere
local applying = false

local function save(obj, prop)
    if not obj then return end
    saved[obj] = saved[obj] or {}
    if saved[obj][prop] ~= nil then return end

    local ok, value = pcall(function()
        return obj[prop]
    end)

    if ok then
        saved[obj][prop] = value
    end
end

local function set(obj, prop, value)
    if not obj then return end
    save(obj, prop)
    pcall(function()
        obj[prop] = value
    end)
end

local function saveLighting()
    for _, prop in ipairs({
        "Brightness", "Ambient", "OutdoorAmbient",
        "GlobalShadows", "ExposureCompensation",
        "ColorShift_Top", "ColorShift_Bottom",
        "FogEnd", "ClockTime", "GeographicLatitude"
    }) do
        if baseLighting[prop] == nil then
            pcall(function()
                baseLighting[prop] = Lighting[prop]
            end)
        end
    end
end

local function restoreLighting()
    for prop, value in pairs(baseLighting) do
        pcall(function()
            Lighting[prop] = value
        end)
    end
end

local function applyLighting()
    saveLighting()

    if State.bright then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(165, 165, 170)
        Lighting.OutdoorAmbient = Color3.fromRGB(175, 175, 180)
        Lighting.ExposureCompensation = 0.15
    else
        for _, prop in ipairs({
            "Brightness", "Ambient", "OutdoorAmbient",
            "ExposureCompensation"
        }) do
            local value = baseLighting[prop]
            if value ~= nil then
                pcall(function()
                    Lighting[prop] = value
                end)
            end
        end
    end

    if State.fps then
        Lighting.GlobalShadows = false
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
    else
        for _, prop in ipairs({
            "GlobalShadows", "ColorShift_Top",
            "ColorShift_Bottom", "FogEnd"
        }) do
            local value = baseLighting[prop]
            if value ~= nil then
                pcall(function()
                    Lighting[prop] = value
                end)
            end
        end
    end
end

local function optimize(obj)
    if not State.fps or not obj or obj == grayAtmosphere then
        return
    end

    if obj:IsA("MeshPart") then
        set(obj, "TextureID", "")
        set(obj, "Material", Enum.Material.SmoothPlastic)
        set(obj, "Reflectance", 0)
        set(obj, "CastShadow", false)
        pcall(function()
            set(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
        end)

    elseif obj:IsA("BasePart") then
        set(obj, "Material", Enum.Material.SmoothPlastic)
        set(obj, "Reflectance", 0)
        set(obj, "CastShadow", false)
        pcall(function()
            set(obj, "MaterialVariant", "")
        end)

    elseif obj:IsA("SpecialMesh") then
        set(obj, "TextureId", "")

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        set(obj, "Transparency", 1)

    elseif obj:IsA("SurfaceAppearance") then
        for _, prop in ipairs({
            "ColorMap", "MetalnessMap",
            "NormalMap", "RoughnessMap"
        }) do
            set(obj, prop, "")
        end

    elseif obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
        or obj:IsA("PostEffect") then
        set(obj, "Enabled", false)
    end
end

local function applyGraySky()
    if not State.fps then return end

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            if savedSky[obj] == nil then
                savedSky[obj] = obj.Parent
            end
            pcall(function()
                obj.Parent = nil
            end)

        elseif obj:IsA("Atmosphere") and obj ~= grayAtmosphere then
            if not savedAtmos[obj] then
                savedAtmos[obj] = {
                    Color = obj.Color,
                    Decay = obj.Decay,
                    Density = obj.Density,
                    Haze = obj.Haze,
                    Glare = obj.Glare,
                    Offset = obj.Offset
                }
            end

            pcall(function()
                obj.Color = Color3.fromRGB(150, 150, 155)
                obj.Decay = Color3.fromRGB(120, 120, 126)
                obj.Density = 0.3
                obj.Haze = 1
                obj.Glare = 0
                obj.Offset = 0.1
            end)
        end
    end

    if not grayAtmosphere or not grayAtmosphere.Parent then
        grayAtmosphere = Instance.new("Atmosphere")
        grayAtmosphere.Name = "SCFPS_GraySky"
        grayAtmosphere.Color = Color3.fromRGB(150, 150, 155)
        grayAtmosphere.Decay = Color3.fromRGB(120, 120, 126)
        grayAtmosphere.Density = 0.3
        grayAtmosphere.Haze = 1
        grayAtmosphere.Glare = 0
        grayAtmosphere.Offset = 0.1
        grayAtmosphere.Parent = Lighting
    end
end

local function restoreSky()
    for sky, parent in pairs(savedSky) do
        if sky then
            pcall(function()
                sky.Parent = parent or Lighting
            end)
        end
        savedSky[sky] = nil
    end

    for atmosphere, props in pairs(savedAtmos) do
        if atmosphere then
            for prop, value in pairs(props) do
                pcall(function()
                    atmosphere[prop] = value
                end)
            end
        end
        savedAtmos[atmosphere] = nil
    end

    if grayAtmosphere then
        pcall(function()
            grayAtmosphere:Destroy()
        end)
        grayAtmosphere = nil
    end
end

local function restoreObjects()
    for obj, props in pairs(saved) do
        if obj then
            for prop, value in pairs(props) do
                pcall(function()
                    obj[prop] = value
                end)
            end
        end
        saved[obj] = nil
    end
end

local function setFPS(enabled)
    if applying then return end
    applying = true
    State.fps = enabled

    if enabled then
        saveLighting()

        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimize(obj)
        end

        for _, obj in ipairs(Lighting:GetDescendants()) do
            optimize(obj)
        end

        applyGraySky()
    else
        restoreObjects()
        restoreSky()
    end

    applyLighting()
    applying = false
end

local function setBright(enabled)
    State.bright = enabled
    applyLighting()
end

local function setPrompt(obj)
    if not obj:IsA("ProximityPrompt") then return end

    if State.interact then
        if savedPrompts[obj] == nil then
            savedPrompts[obj] = obj.HoldDuration
        end
        pcall(function()
            obj.HoldDuration = 0
        end)
    elseif savedPrompts[obj] ~= nil then
        pcall(function()
            obj.HoldDuration = savedPrompts[obj]
        end)
        savedPrompts[obj] = nil
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if State.fps then optimize(obj) end
        if State.interact then setPrompt(obj) end
    end)
end)

Lighting.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not State.fps then return end

        if obj:IsA("Sky") then
            if savedSky[obj] == nil then
                savedSky[obj] = obj.Parent
            end
            pcall(function()
                obj.Parent = nil
            end)
        elseif obj:IsA("Atmosphere") then
            applyGraySky()
        else
            optimize(obj)
        end
    end)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(215, 169)
main.Position = UDim2.new(0, 12, 0, 70)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 7)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(50, 125, 255)
outline.Thickness = 1
outline.Parent = main

local starsLayer = Instance.new("Frame")
starsLayer.Size = UDim2.fromScale(1, 1)
starsLayer.BackgroundTransparency = 1
starsLayer.ClipsDescendants = true
starsLayer.ZIndex = 1
starsLayer.Parent = main

local stars = {}

for i = 1, 24 do
    local star = Instance.new("Frame")
    local size = math.random(1, 2)
    star.Size = UDim2.fromOffset(size, size)
    star.Position = UDim2.new(math.random(), 0, math.random(), 0)
    star.BackgroundColor3 = Color3.fromRGB(190, 210, 255)
    star.BackgroundTransparency = math.random(2, 7) / 10
    star.BorderSizePixel = 0
    star.ZIndex = 1
    star.Parent = starsLayer

    stars[#stars + 1] = {
        obj = star,
        speed = math.random(10, 28),
        drift = math.random(4, 13)
    }
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -48, 0, 27)
title.Position = UDim2.fromOffset(9, 3)
title.BackgroundTransparency = 1
title.Text = "Farhan Store"
title.TextColor3 = Color3.fromRGB(240, 245, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(23, 23)
close.Position = UDim2.new(1, -27, 0, 4)
close.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 12
close.Font = Enum.Font.GothamBold
close.BorderSizePixel = 0
close.ZIndex = 4
close.Parent = main

Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

local ping = Instance.new("TextLabel")
ping.Size = UDim2.new(1, -18, 0, 17)
ping.Position = UDim2.fromOffset(9, 29)
ping.BackgroundTransparency = 1
ping.Text = "PING: ..."
ping.TextColor3 = Color3.fromRGB(160, 190, 255)
ping.TextSize = 10
ping.Font = Enum.Font.Gotham
ping.TextXAlignment = Enum.TextXAlignment.Left
ping.ZIndex = 3
ping.Parent = main

local function makeButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -18, 0, 28)
    button.Position = UDim2.fromOffset(9, y)
    button.BackgroundColor3 = Color3.fromRGB(20, 38, 68)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(235, 240, 255)
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.ZIndex = 3
    button.Parent = main
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
    return button
end

local fpsButton = makeButton("FPS BOOST: OFF", 51)
local brightButton = makeButton("FULL BRIGHT: OFF", 85)
local interactButton = makeButton("FAST INTERACT: OFF", 119)

local function refresh()
    fpsButton.Text = "FPS BOOST: " .. (State.fps and "ON" or "OFF")
    brightButton.Text = "FULL BRIGHT: " .. (State.bright and "ON" or "OFF")
    interactButton.Text = "FAST INTERACT: " .. (State.interact and "ON" or "OFF")

    local on = Color3.fromRGB(25, 90, 55)
    local off = Color3.fromRGB(20, 38, 68)

    fpsButton.BackgroundColor3 = State.fps and on or off
    brightButton.BackgroundColor3 = State.bright and on or off
    interactButton.BackgroundColor3 = State.interact and on or off
end

fpsButton.MouseButton1Click:Connect(function()
    setFPS(not State.fps)
    refresh()
end)

brightButton.MouseButton1Click:Connect(function()
    setBright(not State.bright)
    refresh()
end)

interactButton.MouseButton1Click:Connect(function()
    State.interact = not State.interact

    for _, obj in ipairs(Workspace:GetDescendants()) do
        setPrompt(obj)
    end

    refresh()
end)

local function hideGUI()
    State.visible = false
    main.Visible = false
end

close.MouseButton1Click:Connect(hideGUI)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightAlt then
        State.visible = not State.visible
        main.Visible = State.visible
    elseif input.KeyCode == Enum.KeyCode.X then
        hideGUI()
    end
end)

local dragging = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function(dt)
    for _, star in ipairs(stars) do
        local p = star.obj.Position
        local x = p.X.Scale + star.drift * dt / 1000
        local y = p.Y.Scale + star.speed * dt / 1000

        if y > 1 then
            y = 0
            x = math.random()
        end
        if x > 1 then x = 0 end

        star.obj.Position = UDim2.new(x, 0, y, 0)
    end
end)

task.spawn(function()
    while gui.Parent do
        local ok, value = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        end)

        ping.Text = ok and ("PING: " .. value) or "PING: N/A"
        task.wait(0.1)
    end
end)

task.spawn(function()
    while gui.Parent do
        if State.fps then
            applyGraySky()
            Lighting.GlobalShadows = false
        end
        task.wait(1)
    end
end)

refresh()
print("[SC FPS | Farhan Store] Loaded")
