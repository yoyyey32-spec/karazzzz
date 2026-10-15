local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("SCFPS_FarhanStore")
if oldGui then
    oldGui:Destroy()
end

local state = {
    fpsBoost = false,
    fullBright = false,
    guiVisible = true,
    minimized = false
}

local savedObjects = {}
local savedEffects = {}
local savedFPSLighting
local savedLight = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation
}

local skyFaces = {
    "SkyboxBk", "SkyboxDn", "SkyboxFt",
    "SkyboxLf", "SkyboxRt", "SkyboxUp"
}

local graySky = ""

local function remember(obj, properties)
    if not obj then return end
    savedObjects[obj] = savedObjects[obj] or {}

    for _, property in ipairs(properties) do
        if savedObjects[obj][property] == nil then
            local ok, value = pcall(function()
                return obj[property]
            end)
            if ok then
                savedObjects[obj][property] = {value = value}
            end
        end
    end
end

local function rememberEffect(obj)
    if not obj or savedEffects[obj] ~= nil then return end
    local ok, enabled = pcall(function()
        return obj.Enabled
    end)
    if ok then
        savedEffects[obj] = enabled
    end
end

local function optimizeObject(obj)
    if not state.fpsBoost or not obj or not obj.Parent then return end

    pcall(function()
        if obj:IsA("BasePart") then
            remember(obj, {"Material", "Reflectance"})
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            remember(obj, {"Transparency"})
            obj.Transparency = 1

        elseif obj:IsA("SurfaceAppearance") then
            remember(obj, {"ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap"})
            obj.ColorMap = ""
            obj.NormalMap = ""
            obj.RoughnessMap = ""
            obj.MetalnessMap = ""

        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail")
            or obj:IsA("Beam") or obj:IsA("Fire")
            or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            rememberEffect(obj)
            obj.Enabled = false
        end
    end)
end

local function restoreWorld()
    for obj, properties in pairs(savedObjects) do
        for property, record in pairs(properties) do
            pcall(function()
                obj[property] = record.value
            end)
        end
    end

    for obj, enabled in pairs(savedEffects) do
        pcall(function()
            obj.Enabled = enabled
        end)
    end

    if savedFPSLighting then
        pcall(function()
            Lighting.GlobalShadows = savedFPSLighting.GlobalShadows
            Lighting.FogEnd = savedFPSLighting.FogEnd
        end)
    end

    savedObjects = {}
    savedEffects = {}
    savedFPSLighting = nil
end

local function setGraySkyObject(obj)
    if not obj then return end

    if obj:IsA("Sky") then
        local props = {"CelestialBodiesShown", "StarCount", "SunAngularSize", "MoonAngularSize", "SkyboxOrientation"}
        for _, face in ipairs(skyFaces) do
            table.insert(props, face)
        end
        remember(obj, props)

        pcall(function()
            obj.CelestialBodiesShown = false
            obj.SunAngularSize = 0
            obj.MoonAngularSize = 0
            obj.StarCount = 0
            obj.SkyboxOrientation = Vector3.zero
        end)

        for _, face in ipairs(skyFaces) do
            pcall(function()
                obj[face] = graySky
            end)
        end

    elseif obj:IsA("Atmosphere") then
        remember(obj, {"Color", "Decay", "Density", "Glare", "Haze"})
        pcall(function()
            obj.Color = Color3.fromRGB(115, 115, 115)
            obj.Decay = Color3.fromRGB(115, 115, 115)
            obj.Density = 0.45
            obj.Glare = 0
            obj.Haze = 2
        end)

    elseif obj:IsA("Clouds") then
        remember(obj, {"Cover", "Density"})
        pcall(function()
            obj.Cover = 0
            obj.Density = 0
        end)
    end
end

local function applyGraySky()
    if not state.fpsBoost then return end

    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") then
            setGraySkyObject(obj)
        end
    end

    for _, obj in ipairs(Workspace.Terrain:GetDescendants()) do
        if obj:IsA("Clouds") then
            setGraySkyObject(obj)
        end
    end
end


local function applyAntiBlur()
    if not state.fpsBoost then return end

    local camera = Workspace.CurrentCamera
    local containers = {Lighting}
    if camera then
        table.insert(containers, camera)
    end

    for _, container in ipairs(containers) do
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("BlurEffect") then
                rememberEffect(obj)
                pcall(function()
                    obj.Enabled = false
                end)
            end
        end
    end
end

local function applyFPSBoost()
    if state.fpsBoost then
        savedFPSLighting = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd
        }

        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeObject(obj)
        end

        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1000000
        end)
        applyGraySky()
        applyAntiBlur()
    else
        restoreWorld()
    end
end

local function applyFullBright()
    if state.fullBright then
        Lighting.Brightness = 2.2
        Lighting.Ambient = Color3.fromRGB(145, 145, 145)
        Lighting.OutdoorAmbient = Color3.fromRGB(165, 165, 165)
        Lighting.ExposureCompensation = 0.15
    else
        Lighting.Brightness = savedLight.Brightness
        Lighting.Ambient = savedLight.Ambient
        Lighting.OutdoorAmbient = savedLight.OutdoorAmbient
        Lighting.ExposureCompensation = savedLight.ExposureCompensation
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(222, 190)
main.Position = UDim2.new(1, -242, 0.5, -95)
main.BackgroundColor3 = Color3.fromRGB(7, 9, 15)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(220, 230, 245)
outline.Thickness = 1.5
outline.Parent = main

math.randomseed(math.floor(os.clock() * 100000))
for i = 1, 25 do
    local star = Instance.new("Frame")
    local size = (i % 5 == 0) and 3 or 2
    star.Size = UDim2.fromOffset(size, size)
    star.Position = UDim2.new(math.random(4, 96) / 100, 0, math.random(5, 95) / 100, 0)
    star.BackgroundColor3 = (i % 4 == 0)
        and Color3.fromRGB(70, 155, 255)
        or Color3.fromRGB(170, 190, 220)
    star.BackgroundTransparency = 0.25 + math.random() * 0.5
    star.BorderSizePixel = 0
    star.ZIndex = 1
    star.Parent = main
    Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)
end


local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -58, 0, 29)
title.Position = UDim2.fromOffset(13, 8)
title.BackgroundTransparency = 1
title.Text = "Farhan Store"
title.TextColor3 = Color3.fromRGB(245, 248, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = main

local accent = Instance.new("Frame")
accent.Size = UDim2.new(0, 55, 0, 2)
accent.Position = UDim2.fromOffset(13, 35)
accent.BackgroundColor3 = Color3.fromRGB(25, 125, 255)
accent.BorderSizePixel = 0
accent.ZIndex = 4
accent.Parent = main

local function makeButton(name, text, y)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -28, 0, 31)
    button.Position = UDim2.fromOffset(14, y)
    button.BackgroundColor3 = Color3.fromRGB(18, 48, 87)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Text = text
    button.TextColor3 = Color3.fromRGB(240, 246, 255)
    button.TextSize = 12
    button.Font = Enum.Font.GothamSemibold
    button.ZIndex = 4
    button.Parent = main
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
    return button
end

local fpsButton = makeButton("FPSBoost", "FPS Boost  [OFF]", 49)
local brightButton = makeButton("FullBright", "Full Bright  [OFF]", 86)

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, -28, 0, 25)
pingLabel.Position = UDim2.fromOffset(14, 126)
pingLabel.BackgroundColor3 = Color3.fromRGB(13, 17, 27)
pingLabel.BorderSizePixel = 0
pingLabel.Text = "Ping: ..."
pingLabel.TextColor3 = Color3.fromRGB(85, 190, 255)
pingLabel.TextSize = 12
pingLabel.Font = Enum.Font.GothamMedium
pingLabel.ZIndex = 4
pingLabel.Parent = main
Instance.new("UICorner", pingLabel).CornerRadius = UDim.new(0, 6)

local minimize = Instance.new("TextButton")
minimize.Name = "Minimize"
minimize.Size = UDim2.fromOffset(19, 19)
minimize.Position = UDim2.new(1, -28, 0, 7)
minimize.BackgroundColor3 = Color3.fromRGB(0, 105, 230)
minimize.BorderSizePixel = 0
minimize.Text = "−"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.TextSize = 16
minimize.Font = Enum.Font.GothamBold
minimize.ZIndex = 5
minimize.Parent = main
Instance.new("UICorner", minimize).CornerRadius = UDim.new(1, 0)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -28, 0, 15)
hint.Position = UDim2.fromOffset(14, 159)
hint.BackgroundTransparency = 1
hint.Text = "Right Alt: buka / tutup"
hint.TextColor3 = Color3.fromRGB(150, 160, 180)
hint.TextSize = 10
hint.Font = Enum.Font.Gotham
hint.ZIndex = 4
hint.Parent = main

local function refreshButtons()
    fpsButton.Text = "FPS Boost  [" .. (state.fpsBoost and "ON" or "OFF") .. "]"
    fpsButton.BackgroundColor3 = state.fpsBoost
        and Color3.fromRGB(0, 87, 170)
        or Color3.fromRGB(18, 48, 87)

    brightButton.Text = "Full Bright  [" .. (state.fullBright and "ON" or "OFF") .. "]"
    brightButton.BackgroundColor3 = state.fullBright
        and Color3.fromRGB(0, 87, 170)
        or Color3.fromRGB(18, 48, 87)
end

fpsButton.MouseButton1Click:Connect(function()
    state.fpsBoost = not state.fpsBoost
    local ok, err = pcall(applyFPSBoost)
    if not ok then warn("[Farhan Store] FPS Boost error: " .. tostring(err)) end
    refreshButtons()
end)

brightButton.MouseButton1Click:Connect(function()
    state.fullBright = not state.fullBright
    local ok, err = pcall(applyFullBright)
    if not ok then warn("[Farhan Store] Full Bright error: " .. tostring(err)) end
    refreshButtons()
end)

minimize.MouseButton1Click:Connect(function()
    state.minimized = not state.minimized
    fpsButton.Visible = not state.minimized
    brightButton.Visible = not state.minimized
    pingLabel.Visible = not state.minimized
    hint.Visible = not state.minimized
    accent.Visible = not state.minimized
    main.Size = state.minimized and UDim2.fromOffset(222, 48) or UDim2.fromOffset(222, 190)
    minimize.Text = state.minimized and "+" or "−"
end)

do
    local dragging = false
    local dragStart
    local startPosition

    title.InputBegan:Connect(function(input)
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

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
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

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        state.guiVisible = not state.guiVisible
        gui.Enabled = state.guiVisible
    end
end)

Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not obj or not obj.Parent then return end
        if state.fpsBoost then
            optimizeObject(obj)
            if obj:IsA("Clouds") or obj:IsA("Sky") or obj:IsA("Atmosphere") then
                setGraySkyObject(obj)
            end
            if obj:IsA("BlurEffect") then
                rememberEffect(obj)
                obj.Enabled = false
            end
        end
    end)
end)

Lighting.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not state.fpsBoost or not obj or not obj.Parent then return end
        if obj:IsA("Sky") or obj:IsA("Atmosphere") then
            setGraySkyObject(obj)
        elseif obj:IsA("BlurEffect") then
            rememberEffect(obj)
            obj.Enabled = false
        end
    end)
end)

task.spawn(function()
    while gui.Parent do
        if state.fpsBoost then
            pcall(applyBlackSky)
            pcall(applyAntiBlur)
        end
        if state.fullBright then
            pcall(applyFullBright)
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while gui.Parent do
        local value = "N/A"
        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")
            if dataPing then
                value = dataPing:GetValueString()
            end
        end)

        if pingLabel and pingLabel.Parent then
            pingLabel.Text = "Ping: " .. value
        end
        task.wait(0.1)
    end
end)

refreshButtons()
print("Farhan Store aktif")
