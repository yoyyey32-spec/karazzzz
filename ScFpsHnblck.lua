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
    blackSky = false,
    antiBlur = false,
    fullBright = false,
    noShake = false,
    guiVisible = true
}

local savedParts = setmetatable({}, {__mode = "k"})
local savedEffects = setmetatable({}, {__mode = "k"})
local savedSurface = setmetatable({}, {__mode = "k"})
local savedSky = setmetatable({}, {__mode = "k"})
local savedInstances = setmetatable({}, {__mode = "k"})

local originalLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
}

local function saveProperty(obj, property)
    savedInstances[obj] = savedInstances[obj] or {}
    local data = savedInstances[obj]

    if data[property] == nil then
        local ok, value = pcall(function()
            return obj[property]
        end)
        if ok then data[property] = value end
    end
end

local function savePart(obj)
    if savedParts[obj] then return end

    local data = {}

    pcall(function()
        if obj:IsA("BasePart") then
            data.Material = obj.Material
            data.Reflectance = obj.Reflectance
            data.CastShadow = obj.CastShadow
            data.MaterialVariant = obj.MaterialVariant
        end

        if obj:IsA("MeshPart") then
            data.TextureID = obj.TextureID
        end

        if obj:IsA("SpecialMesh") then
            data.TextureId = obj.TextureId
        end

        if obj:IsA("Decal") or obj:IsA("Texture") then
            data.Transparency = obj.Transparency
        end
    end)

    savedParts[obj] = data
end

local function optimizeObject(obj)
    if not state.fpsBoost then return end

    pcall(function()
        if obj:IsA("BasePart") then
            savePart(obj)
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            obj.MaterialVariant = ""

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            savePart(obj)
            obj.Transparency = 1

        elseif obj:IsA("MeshPart") then
            savePart(obj)
            obj.TextureID = ""

        elseif obj:IsA("SpecialMesh") then
            savePart(obj)
            obj.TextureId = ""

        elseif obj:IsA("SurfaceAppearance") then
            if not savedSurface[obj] then
                savedSurface[obj] = obj.Parent
                obj.Parent = nil
            end

        elseif obj:IsA("Highlight") then
            if not savedEffects[obj] then
                savedEffects[obj] = {Enabled = obj.Enabled}
            end
            obj.Enabled = false

        elseif obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Beam")
            or obj:IsA("Fire")
            or obj:IsA("Smoke")
            or obj:IsA("Sparkles") then

            if not savedEffects[obj] then
                savedEffects[obj] = {Enabled = obj.Enabled}
            end
            obj.Enabled = false
        end
    end)
end

local function restoreOptimization()
    for obj, data in pairs(savedParts) do
        if obj then
            pcall(function()
                for property, value in pairs(data) do
                    obj[property] = value
                end
            end)
        end
    end

    for obj, data in pairs(savedEffects) do
        if obj then
            pcall(function()
                for property, value in pairs(data) do
                    obj[property] = value
                end
            end)
        end
    end

    for obj, parent in pairs(savedSurface) do
        if obj and parent then
            pcall(function()
                obj.Parent = parent
            end)
        end
    end

    table.clear(savedParts)
    table.clear(savedEffects)
    table.clear(savedSurface)

    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.EnvironmentSpecularScale =
        originalLighting.EnvironmentSpecularScale
    Lighting.EnvironmentDiffuseScale =
        originalLighting.EnvironmentDiffuseScale
end

local function applyOptimization()
    if state.fpsBoost then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeObject(obj)
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        Lighting.EnvironmentSpecularScale = 0
        Lighting.EnvironmentDiffuseScale = 0
    else
        restoreOptimization()
    end
end

local function applyBlackSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            if not savedSky[obj] then
                savedSky[obj] = {
                    CelestialBodiesShown = obj.CelestialBodiesShown,
                    StarCount = obj.StarCount
                }
            end

            pcall(function()
                if state.blackSky then
                    obj.CelestialBodiesShown = false
                    obj.StarCount = 0
                else
                    obj.CelestialBodiesShown =
                        savedSky[obj].CelestialBodiesShown
                    obj.StarCount = savedSky[obj].StarCount
                end
            end)
        end
    end
end

local function applyAntiBlur()
    for _, container in ipairs({Lighting, Workspace.CurrentCamera}) do
        if container then
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("BlurEffect") then
                    if state.antiBlur or state.noShake then
                        if not savedEffects[obj] then
                            savedEffects[obj] = {Enabled = obj.Enabled}
                        end
                        obj.Enabled = false
                    elseif savedEffects[obj] then
                        pcall(function()
                            obj.Enabled = savedEffects[obj].Enabled
                        end)
                    end
                end
            end
        end
    end
end

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

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(300, 425)
main.Position = UDim2.new(0, 24, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(3, 3, 8)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(220, 55, 65)
stroke.Thickness = 1.5
stroke.Parent = main

local starLayer = Instance.new("Frame")
starLayer.Name = "StarBackground"
starLayer.Size = UDim2.fromScale(1, 1)
starLayer.BackgroundColor3 = Color3.fromRGB(3, 3, 8)
starLayer.BorderSizePixel = 0
starLayer.ClipsDescendants = true
starLayer.ZIndex = 0
starLayer.Parent = main

Instance.new("UICorner", starLayer).CornerRadius = UDim.new(0, 10)

local starGradient = Instance.new("UIGradient")
starGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 4, 12)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 5, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 3, 8))
})
starGradient.Rotation = 35
starGradient.Parent = starLayer

local stars = {}

for i = 1, 45 do
    local star = Instance.new("Frame")
    local size = math.random(1, 3)

    star.Size = UDim2.fromOffset(size, size)
    star.Position = UDim2.new(math.random(), 0, math.random(), 0)
    star.BackgroundColor3 = Color3.fromRGB(
        math.random(170, 255),
        math.random(170, 220),
        255
    )
    star.BackgroundTransparency = math.random(15, 65) / 100
    star.BorderSizePixel = 0
    star.ZIndex = 1
    star.Parent = starLayer

    Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)

    stars[#stars + 1] = {
        object = star,
        speed = math.random(5, 20) / 1000,
        phase = math.random() * 6.28
    }
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(145, 25, 35)
header.BackgroundTransparency = 0.08
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = main

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "Farhan Store"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 28)
close.Position = UDim2.new(1, -37, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.ZIndex = 4
close.Parent = header

Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, -24, 0, 25)
pingLabel.Position = UDim2.fromOffset(12, 52)
pingLabel.BackgroundColor3 = Color3.fromRGB(31, 31, 38)
pingLabel.BackgroundTransparency = 0.1
pingLabel.Text = "Ping: ..."
pingLabel.TextColor3 = Color3.fromRGB(100, 220, 130)
pingLabel.TextSize = 12
pingLabel.Font = Enum.Font.GothamMedium
pingLabel.ZIndex = 3
pingLabel.Parent = main

Instance.new("UICorner", pingLabel).CornerRadius = UDim.new(0, 5)

local buttons = {}

local function updateButton(key)
    local item = buttons[key]
    if not item then return end

    local enabled = state[key]
    item.button.Text = item.label .. (enabled and "  [ON]" or "  [OFF]")
    item.button.BackgroundColor3 = enabled
        and Color3.fromRGB(125, 30, 40)
        or Color3.fromRGB(48, 48, 56)
end

local function createToggle(key, label, y, callback)
    local button = Instance.new("TextButton")
    button.Name = key .. "Toggle"
    button.Size = UDim2.new(1, -24, 0, 32)
    button.Position = UDim2.fromOffset(12, y)
    button.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    button.BackgroundTransparency = 0.08
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamSemibold
    button.ZIndex = 3
    button.Parent = main

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    buttons[key] = {button = button, label = label}

    button.MouseButton1Click:Connect(function()
        state[key] = not state[key]

        local ok, err = pcall(callback)
        if not ok then
            warn("[SC FPS] " .. tostring(err))
        end

        updateButton(key)
    end)
end

createToggle("fpsBoost", "FPS BOOST", 87, applyOptimization)
createToggle("blackSky", "Black Sky", 124, applyBlackSky)
createToggle("antiBlur", "Anti-Blur", 161, applyAntiBlur)
createToggle("fullBright", "Full Bright", 198, applyFullBright)
createToggle("noShake", "No Shake (Safe)", 235, applyAntiBlur)

local fontTitle = Instance.new("TextLabel")
fontTitle.Size = UDim2.new(1, -24, 0, 20)
fontTitle.Position = UDim2.fromOffset(12, 272)
fontTitle.BackgroundTransparency = 1
fontTitle.Text = "Font"
fontTitle.TextColor3 = Color3.new(1, 1, 1)
fontTitle.TextSize = 13
fontTitle.Font = Enum.Font.GothamBold
fontTitle.TextXAlignment = Enum.TextXAlignment.Left
fontTitle.ZIndex = 3
fontTitle.Parent = main

local fontNames = {"Default", "Minecraft Regular", "Lenmok"}
local fontValues = {Enum.Font.Gotham, Enum.Font.Code, Enum.Font.SciFi}
local selectedFont = 1

local fontButton = Instance.new("TextButton")
fontButton.Size = UDim2.new(1, -24, 0, 30)
fontButton.Position = UDim2.fromOffset(12, 295)
fontButton.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
fontButton.BorderSizePixel = 0
fontButton.TextColor3 = Color3.new(1, 1, 1)
fontButton.TextSize = 12
fontButton.Font = Enum.Font.Gotham
fontButton.Text = "Font: Default  >"
fontButton.ZIndex = 3
fontButton.Parent = main

Instance.new("UICorner", fontButton).CornerRadius = UDim.new(0, 6)

fontButton.MouseButton1Click:Connect(function()
    selectedFont = selectedFont % #fontNames + 1
    fontButton.Text = "Font: " .. fontNames[selectedFont] .. "  >"
end)

local function applyFont(font)
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            obj.Font = font
        end
    end
end

local applyButton = Instance.new("TextButton")
applyButton.Size = UDim2.new(0.5, -16, 0, 30)
applyButton.Position = UDim2.fromOffset(12, 332)
applyButton.BackgroundColor3 = Color3.fromRGB(145, 25, 35)
applyButton.BorderSizePixel = 0
applyButton.Text = "Apply"
applyButton.TextColor3 = Color3.new(1, 1, 1)
applyButton.TextSize = 12
applyButton.Font = Enum.Font.GothamBold
applyButton.ZIndex = 3
applyButton.Parent = main

Instance.new("UICorner", applyButton).CornerRadius = UDim.new(0, 6)

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0.5, -16, 0, 30)
resetButton.Position = UDim2.new(0.5, 4, 0, 332)
resetButton.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
resetButton.BorderSizePixel = 0
resetButton.Text = "Reset"
resetButton.TextColor3 = Color3.new(1, 1, 1)
resetButton.TextSize = 12
resetButton.Font = Enum.Font.GothamBold
resetButton.ZIndex = 3
resetButton.Parent = main

Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 6)

applyButton.MouseButton1Click:Connect(function()
    applyFont(fontValues[selectedFont])
end)

resetButton.MouseButton1Click:Connect(function()
    selectedFont = 1
    applyFont(Enum.Font.Gotham)
    fontButton.Text = "Font: Default  >"
end)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -24, 0, 35)
note.Position = UDim2.fromOffset(12, 370)
note.BackgroundTransparency = 1
note.Text = "Right Alt: buka/tutup menu"
note.TextColor3 = Color3.fromRGB(190, 190, 200)
note.TextSize = 11
note.Font = Enum.Font.Gotham
note.ZIndex = 3
note.Parent = main

for key in pairs(buttons) do
    updateButton(key)
end

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
    if state.fpsBoost then
        task.defer(function()
            if obj and obj.Parent then
                optimizeObject(obj)
            end
        end)
    end
end)

Lighting.DescendantAdded:Connect(function(obj)
    if obj:IsA("BlurEffect") and (state.antiBlur or state.noShake) then
        task.defer(applyAntiBlur)
    end

    if obj:IsA("Sky") and state.blackSky then
        task.defer(applyBlackSky)
    end
end)

task.spawn(function()
    while gui.Parent do
        for _, item in ipairs(stars) do
            local star = item.object

            if star.Parent then
                local dt = 0.03
                local x = star.Position.X.Scale
                local y = star.Position.Y.Scale + item.speed * dt * 30

                if y > 1 then
                    y = 0
                    x = math.random()
                end

                star.Position = UDim2.fromScale(x, y)
                item.phase = item.phase + dt * 2
                star.BackgroundTransparency =
                    0.25 + (math.sin(item.phase) + 1) * 0.3
            end
        end

        task.wait(0.03)
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
print("[SC FPS | Farhan Store] Loaded")
