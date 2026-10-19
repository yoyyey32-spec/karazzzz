
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("SCFPS_FarhanStore")
if oldGui then oldGui:Destroy() end

local state = {
    fpsBoost = false,
    fullBright = false,
    instantInteract = false,
    guiVisible = true
}

local savedObjects = setmetatable({}, {__mode = "k"})
local savedEffects = setmetatable({}, {__mode = "k"})
local savedPrompts = setmetatable({}, {__mode = "k"})
local savedSkyParents = setmetatable({}, {__mode = "k"})
local savedAtmosphere = setmetatable({}, {__mode = "k"})

local savedLighting = {
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
    ColorShift_Top = Lighting.ColorShift_Top
}

local grayAtmosphere
local updating = false

local function saveProperty(obj, property)
    savedObjects[obj] = savedObjects[obj] or {}
    local data = savedObjects[obj]

    if data[property] == nil then
        pcall(function()
            data[property] = obj[property]
        end)
    end
end

local function saveEffect(obj)
    if savedEffects[obj] ~= nil then return end

    pcall(function()
        savedEffects[obj] = obj.Enabled
    end)
end

local function optimizeObject(obj)
    if not state.fpsBoost or not obj then return end

    pcall(function()
        if obj:IsA("MeshPart") then
            saveProperty(obj, "Material")
            saveProperty(obj, "Reflectance")
            saveProperty(obj, "CastShadow")
            saveProperty(obj, "TextureID")
            saveProperty(obj, "RenderFidelity")

            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            obj.TextureID = ""
            obj.RenderFidelity = Enum.RenderFidelity.Performance

        elseif obj:IsA("BasePart") then
            saveProperty(obj, "Material")
            saveProperty(obj, "Reflectance")
            saveProperty(obj, "CastShadow")

            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false

            pcall(function()
                saveProperty(obj, "MaterialVariant")
                obj.MaterialVariant = ""
            end)

        elseif obj:IsA("SpecialMesh") then
            saveProperty(obj, "TextureId")
            obj.TextureId = ""

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            saveProperty(obj, "Transparency")
            obj.Transparency = 1

        elseif obj:IsA("SurfaceAppearance") then
            if not savedObjects[obj] then
                savedObjects[obj] = {}
            end
            saveProperty(obj, "Parent")
            obj.Parent = nil

        elseif obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Beam")
            or obj:IsA("Smoke")
            or obj:IsA("Fire")
            or obj:IsA("Sparkles")
            or obj:IsA("PostEffect") then

            saveEffect(obj)
            obj.Enabled = false
        end
    end)
end

local function restoreVisuals()
    for obj, properties in pairs(savedObjects) do
        if obj then
            for property, value in pairs(properties) do
                pcall(function()
                    if property == "Parent" then
                        if value and obj.Parent == nil then
                            obj.Parent = value
                        end
                    elseif obj.Parent then
                        obj[property] = value
                    end
                end)
            end
        end
    end

    for obj, enabled in pairs(savedEffects) do
        if obj and obj.Parent then
            pcall(function()
                obj.Enabled = enabled
            end)
        end
    end

    Lighting.GlobalShadows = savedLighting.GlobalShadows
    Lighting.FogEnd = savedLighting.FogEnd
end

local function enforceGraySky()
    if not state.fpsBoost then return end

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            if savedSkyParents[obj] == nil then
                savedSkyParents[obj] = obj.Parent
            end
            pcall(function()
                obj.Parent = nil
            end)
        end
    end

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

    if not atmosphere then
        if not grayAtmosphere or grayAtmosphere.Parent ~= Lighting then
            grayAtmosphere = Instance.new("Atmosphere")
            grayAtmosphere.Name = "SCFPS_GrayAtmosphere"
            grayAtmosphere.Parent = Lighting
        end
        atmosphere = grayAtmosphere
    elseif atmosphere ~= grayAtmosphere and not savedAtmosphere[atmosphere] then
        savedAtmosphere[atmosphere] = {
            Color = atmosphere.Color,
            Decay = atmosphere.Decay,
            Density = atmosphere.Density,
            Haze = atmosphere.Haze,
            Glare = atmosphere.Glare,
            Offset = atmosphere.Offset
        }
    end

    if atmosphere then
        pcall(function()
            atmosphere.Color = Color3.fromRGB(155, 155, 160)
            atmosphere.Decay = Color3.fromRGB(125, 125, 132)
            atmosphere.Density = 0.35
            atmosphere.Haze = 2
            atmosphere.Glare = 0
            atmosphere.Offset = 0.25
        end)
    end

    Lighting.ColorShift_Top = Color3.fromRGB(110, 110, 115)
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1000000
end

local function restoreSky()
    for obj, parent in pairs(savedSkyParents) do
        if obj and parent then
            pcall(function()
                obj.Parent = parent
            end)
        end
    end

    for obj, properties in pairs(savedAtmosphere) do
        if obj and obj.Parent then
            pcall(function()
                for property, value in pairs(properties) do
                    obj[property] = value
                end
            end)
        end
    end

    if grayAtmosphere and grayAtmosphere.Parent then
        grayAtmosphere:Destroy()
    end

    grayAtmosphere = nil
    Lighting.ColorShift_Top = savedLighting.ColorShift_Top
end

local function applyFPSBoost()
    if updating then return end
    updating = true

    if state.fpsBoost then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeObject(obj)
        end

        for _, obj in ipairs(Lighting:GetDescendants()) do
            if obj:IsA("PostEffect") then
                saveEffect(obj)
                obj.Enabled = false
            end
        end

        enforceGraySky()
    else
        restoreVisuals()
        restoreSky()
    end

    updating = false
end

local function applyFullBright()
    if state.fullBright then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(135, 135, 135)
        Lighting.OutdoorAmbient = Color3.fromRGB(155, 155, 155)
        Lighting.ExposureCompensation = 0.1
    else
        Lighting.Brightness = savedLighting.Brightness
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.ExposureCompensation = savedLighting.ExposureCompensation
    end
end

local function setInstantPrompt(obj)
    if not state.instantInteract or not obj:IsA("ProximityPrompt") then
        return
    end

    if savedPrompts[obj] == nil then
        savedPrompts[obj] = obj.HoldDuration
    end

    pcall(function()
        obj.HoldDuration = 0
    end)
end

local function applyInstantInteract()
    if state.instantInteract then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            setInstantPrompt(obj)
        end
    else
        for obj, duration in pairs(savedPrompts) do
            if obj and obj.Parent then
                pcall(function()
                    obj.HoldDuration = duration
                end)
            end
            savedPrompts[obj] = nil
        end
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(220, 180)
main.Position = UDim2.new(0, 12, 0, 70)
main.BackgroundColor3 = Color3.fromRGB(5, 6, 11)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(55, 91, 145)
stroke.Thickness = 1
stroke.Parent = main

local stars = Instance.new("Frame")
stars.Name = "Stars"
stars.Size = UDim2.fromScale(1, 1)
stars.BackgroundTransparency = 1
stars.ClipsDescendants = true
stars.ZIndex = 1
stars.Parent = main

local random = Random.new()

for i = 1, 30 do
    local dot = Instance.new("Frame")
    local size = random:NextInteger(1, 2)

    dot.Size = UDim2.fromOffset(size, size)
    dot.Position = UDim2.fromScale(random:NextNumber(), random:NextNumber())
    dot.BackgroundColor3 = Color3.fromRGB(205, 220, 255)
    dot.BackgroundTransparency = random:NextNumber(0.15, 0.6)
    dot.BorderSizePixel = 0
    dot.ZIndex = 1
    dot.Parent = stars
end

local shootingStars = {}

for i = 1, 3 do
    local trail = Instance.new("Frame")
    trail.Name = "ShootingStar"
    trail.Size = UDim2.fromOffset(random:NextInteger(12, 25), 1)
    trail.AnchorPoint = Vector2.new(0.5, 0.5)
    trail.Rotation = 35
    trail.BackgroundColor3 = Color3.fromRGB(155, 195, 255)
    trail.BorderSizePixel = 0
    trail.ZIndex = 2
    trail.Parent = stars

    shootingStars[i] = {
        object = trail,
        x = random:NextNumber(-0.2, 1.1),
        y = random:NextNumber(-0.5, 0.9),
        speed = random:NextNumber(0.15, 0.35)
    }
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Color3.fromRGB(12, 23, 42)
header.BackgroundTransparency = 0.05
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -43, 1, 0)
title.Position = UDim2.fromOffset(9, 0)
title.BackgroundTransparency = 1
title.Text = "Farhan Store"
title.TextColor3 = Color3.fromRGB(240, 245, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(23, 22)
close.Position = UDim2.new(1, -28, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(24, 44, 72)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 11
close.Font = Enum.Font.GothamBold
close.ZIndex = 4
close.Parent = header

Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, -18, 0, 18)
pingLabel.Position = UDim2.fromOffset(9, 36)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "PING: --"
pingLabel.TextColor3 = Color3.fromRGB(120, 190, 255)
pingLabel.TextSize = 10
pingLabel.Font = Enum.Font.GothamMedium
pingLabel.TextXAlignment = Enum.TextXAlignment.Left
pingLabel.ZIndex = 3
pingLabel.Parent = main

local buttons = {}

local function updateButton(key)
    local item = buttons[key]
    if not item then return end

    local enabled = state[key]
    item.button.Text = item.label .. (enabled and "  ON" or "  OFF")
    item.button.BackgroundColor3 = enabled
        and Color3.fromRGB(24, 83, 145)
        or Color3.fromRGB(17, 23, 35)
end

local function createToggle(key, label, y, callback)
    local button = Instance.new("TextButton")
    button.Name = key .. "Toggle"
    button.Size = UDim2.new(1, -18, 0, 29)
    button.Position = UDim2.fromOffset(9, y)
    button.BackgroundColor3 = Color3.fromRGB(17, 23, 35)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(245, 247, 255)
    button.TextSize = 11
    button.Font = Enum.Font.GothamSemibold
    button.ZIndex = 3
    button.Parent = main

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)

    buttons[key] = {
        button = button,
        label = label
    }

    button.MouseButton1Click:Connect(function()
        state[key] = not state[key]

        local ok, err = pcall(callback)
        if not ok then
            warn("[SC FPS] " .. tostring(err))
        end

        updateButton(key)
    end)

    updateButton(key)
end

createToggle("fpsBoost", "FPS BOOST", 57, applyFPSBoost)
createToggle("fullBright", "FULL BRIGHT", 91, applyFullBright)
createToggle("instantInteract", "FAST INTERACT", 125, applyInstantInteract)

local dragging = false
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

close.MouseButton1Click:Connect(function()
    state.guiVisible = false
    main.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightAlt then
        state.guiVisible = not state.guiVisible
        main.Visible = state.guiVisible
    end
end)

Workspace.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if not obj or not obj.Parent then return end

        if state.fpsBoost then
            optimizeObject(obj)

            if obj:IsA("Sky") then
                enforceGraySky()
            end
        end

        if state.instantInteract then
            setInstantPrompt(obj)
        end
    end)
end)

Lighting.DescendantAdded:Connect(function(obj)
    if not state.fpsBoost then return end

    task.defer(function()
        if not obj or not obj.Parent then return end

        if obj:IsA("Sky") then
            enforceGraySky()
        elseif obj:IsA("PostEffect") then
            saveEffect(obj)
            obj.Enabled = false
        end
    end)
end)

local skyTimer = 0
local starTimer = 0

RunService.RenderStepped:Connect(function(dt)
    starTimer += dt
    skyTimer += dt

    if starTimer >= 0.04 then
        starTimer = 0

        for _, star in ipairs(shootingStars) do
            local obj = star.object

            star.x += star.speed * 0.04
            star.y += star.speed * 0.04

            if star.x > 1.15 or star.y > 1.15 then
                star.x = random:NextNumber(-0.2, 0.1)
                star.y = random:NextNumber(-0.4, 0.1)
                star.speed = random:NextNumber(0.15, 0.35)
            end

            obj.Position = UDim2.fromScale(star.x, star.y)
        end
    end

    if skyTimer >= 0.5 then
        skyTimer = 0

        if state.fpsBoost then
            enforceGraySky()

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and state.instantInteract then
                    setInstantPrompt(obj)
                end
            end
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        local value = "--"

        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")

            if dataPing then
                value = dataPing:GetValueString()
            end
        end)

        if pingLabel and pingLabel.Parent then
            pingLabel.Text = "PING: " .. value
        end

        task.wait(0.1)
    end
end)
print("[SC FPS | Farhan Store] Loaded")
