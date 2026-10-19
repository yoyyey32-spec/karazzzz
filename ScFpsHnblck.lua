
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local State = {
    fps = false,
    bright = false,
    interact = false,
    visible = true
}

local saved = setmetatable({}, {__mode = "k"})
local savedSky = setmetatable({}, {__mode = "k"})
local savedPrompts = setmetatable({}, {__mode = "k"})
local originalLighting = {}
local originalAtmospheres = setmetatable({}, {__mode = "k"})
local generatedAtmosphere
local changing = false

local function remember(obj, prop)
    if not obj or not obj.Parent then return end
    saved[obj] = saved[obj] or {}

    if saved[obj][prop] == nil then
        local ok, value = pcall(function()
            return obj[prop]
        end)
        if ok then
            saved[obj][prop] = value
        end
    end
end

local function change(obj, prop, value)
    if not obj or not obj.Parent then return end
    remember(obj, prop)
    pcall(function()
        obj[prop] = value
    end)
end

local function rememberLighting()
    for _, prop in ipairs({
        "Brightness", "Ambient", "OutdoorAmbient",
        "GlobalShadows", "ExposureCompensation",
        "ColorShift_Top", "ColorShift_Bottom", "FogEnd"
    }) do
        if originalLighting[prop] == nil then
            pcall(function()
                originalLighting[prop] = Lighting[prop]
            end)
        end
    end
end

local function optimize(obj)
    if not State.fps or not obj or not obj.Parent then return end

    if obj:IsA("MeshPart") then
        change(obj, "TextureID", "")
        change(obj, "Material", Enum.Material.SmoothPlastic)
        change(obj, "Reflectance", 0)
        change(obj, "CastShadow", false)
        pcall(function()
            change(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
        end)

    elseif obj:IsA("BasePart") then
        change(obj, "Material", Enum.Material.SmoothPlastic)
        change(obj, "Reflectance", 0)
        change(obj, "CastShadow", false)
        pcall(function()
            change(obj, "MaterialVariant", "")
        end)

    elseif obj:IsA("SpecialMesh") then
        change(obj, "TextureId", "")

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)

    elseif obj:IsA("SurfaceAppearance") then
        for _, prop in ipairs({
            "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"
        }) do
            change(obj, prop, "")
        end

    elseif obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
        or obj:IsA("PostEffect") then
        change(obj, "Enabled", false)
    end
end

local function setGrayLighting()
    rememberLighting()

    pcall(function()
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(90, 90, 94)
        Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 110)
        Lighting.ExposureCompensation = -0.15
        Lighting.GlobalShadows = false
        Lighting.ColorShift_Top = Color3.fromRGB(3, 3, 3)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.FogEnd = 100000
    end)
end

local function graySky()
    if not State.fps then return end

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            if savedSky[obj] == nil then
                savedSky[obj] = obj.Parent
            end
            pcall(function()
                obj.Parent = nil
            end)

        elseif obj:IsA("Atmosphere") and obj ~= generatedAtmosphere then
            if not originalAtmospheres[obj] then
                originalAtmospheres[obj] = {
                    Color = obj.Color,
                    Decay = obj.Decay,
                    Density = obj.Density,
                    Haze = obj.Haze,
                    Glare = obj.Glare,
                    Offset = obj.Offset
                }
            end

            pcall(function()
                obj.Color = Color3.fromRGB(155, 155, 160)
                obj.Decay = Color3.fromRGB(125, 125, 132)
                obj.Density = 0.3
                obj.Haze = 1
                obj.Glare = 0
                obj.Offset = 0.1
            end)
        end
    end

    if not Lighting:FindFirstChildOfClass("Atmosphere") then
        generatedAtmosphere = Instance.new("Atmosphere")
        generatedAtmosphere.Name = "SCFPS_GrayAtmosphere"
        generatedAtmosphere.Color = Color3.fromRGB(155, 155, 160)
        generatedAtmosphere.Decay = Color3.fromRGB(125, 125, 132)
        generatedAtmosphere.Density = 0.3
        generatedAtmosphere.Haze = 1
        generatedAtmosphere.Glare = 0
        generatedAtmosphere.Offset = 0.1
        generatedAtmosphere.Parent = Lighting
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

    for atmosphere, props in pairs(originalAtmospheres) do
        if atmosphere then
            for prop, value in pairs(props) do
                pcall(function()
                    atmosphere[prop] = value
                end)
            end
        end
        originalAtmospheres[atmosphere] = nil
    end

    if generatedAtmosphere then
        pcall(function()
            generatedAtmosphere:Destroy()
        end)
        generatedAtmosphere = nil
    end

    for prop, value in pairs(originalLighting) do
        pcall(function()
            Lighting[prop] = value
        end)
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

local function applyFPS()
    if changing then return end
    changing = true

    if State.fps then
        rememberLighting()
        setGrayLighting()

        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimize(obj)
        end

        for _, obj in ipairs(Lighting:GetDescendants()) do
            optimize(obj)
        end

        graySky()
    else
        restoreObjects()
        restoreSky()
    end

    changing = false
end

local function applyBright()
    if State.bright then
        rememberLighting()
        pcall(function()
            Lighting.Brightness = 1.5
            Lighting.Ambient = Color3.fromRGB(115, 115, 120)
            Lighting.OutdoorAmbient = Color3.fromRGB(130, 130, 135)
            Lighting.ExposureCompensation = 0
        end)
    else
        if not State.fps then
            for prop, value in pairs(originalLighting) do
                pcall(function()
                    Lighting[prop] = value
                end)
            end
        else
            setGrayLighting()
        end
    end
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
        else
            optimize(obj)
            graySky()
        end
    end)
end)

local screen = Instance.new("ScreenGui")
screen.Name = "SCFPS_FarhanStore"
screen.ResetOnSpawn = false
screen.DisplayOrder = 999
screen.Parent = PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(215, 169)
main.Position = UDim2.new(0, 12, 0, 70)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 7)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(50, 125, 255)
stroke.Thickness = 1
stroke.Parent = main

local starLayer = Instance.new("Frame")
starLayer.Size = UDim2.fromScale(1, 1)
starLayer.BackgroundTransparency = 1
starLayer.ClipsDescendants = true
starLayer.ZIndex = 1
starLayer.Parent = main

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
    star.Parent = starLayer

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

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = close

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

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = button
    return button
end

local fpsButton = makeButton("FPS BOOST: OFF", 51)
local brightButton = makeButton("FULL BRIGHT: OFF", 85)
local interactButton = makeButton("FAST INTERACT: OFF", 119)

local function refreshButtons()
    fpsButton.Text = "FPS BOOST: " .. (State.fps and "ON" or "OFF")
    brightButton.Text = "FULL BRIGHT: " .. (State.bright and "ON" or "OFF")
    interactButton.Text = "FAST INTERACT: " .. (State.interact and "ON" or "OFF")

    local onColor = Color3.fromRGB(25, 90, 55)
    local offColor = Color3.fromRGB(20, 38, 68)

    fpsButton.BackgroundColor3 = State.fps and onColor or offColor
    brightButton.BackgroundColor3 = State.bright and onColor or offColor
    interactButton.BackgroundColor3 = State.interact and onColor or offColor
end

fpsButton.MouseButton1Click:Connect(function()
    State.fps = not State.fps
    applyFPS()
    if State.bright then applyBright() end
    refreshButtons()
end)

brightButton.MouseButton1Click:Connect(function()
    State.bright = not State.bright
    applyBright()
    refreshButtons()
end)

interactButton.MouseButton1Click:Connect(function()
    State.interact = not State.interact

    for _, obj in ipairs(Workspace:GetDescendants()) do
        setPrompt(obj)
    end

    refreshButtons()
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
local startPosition

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
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
    while screen.Parent do
        local ok, result = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        end)
        ping.Text = ok and ("PING: " .. result) or "PING: N/A"
        task.wait(0.1)
    end
end)

task.spawn(function()
    while screen.Parent do
        if State.fps then
            setGrayLighting()
            graySky()
        end
        task.wait(1)
    end
end)

refreshButtons()
print("[SC FPS | Farhan Store] Loaded")
