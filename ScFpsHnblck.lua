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
    ultraBurik = false,
    blackSky = false,
    antiBlur = false,
    fullBright = false,
    noShake = false,
    instantInteract = false,
    guiVisible = true
}

local savedObjects = setmetatable({}, {__mode = "k"})
local savedEffects = setmetatable({}, {__mode = "k"})
local savedSky = setmetatable({}, {__mode = "k"})
local savedPrompts = setmetatable({}, {__mode = "k"})
local savedLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation,
    ClockTime = Lighting.ClockTime
}

local function saveProperty(obj, property)
    savedObjects[obj] = savedObjects[obj] or {}
    local data = savedObjects[obj]
    if data[property] == nil then
        pcall(function() data[property] = obj[property] end)
    end
end

local function saveEffect(obj)
    if savedEffects[obj] ~= nil then return end
    pcall(function() savedEffects[obj] = obj.Enabled end)
end

local function optimizeObject(obj)
    if not (state.fpsBoost or state.ultraBurik) then return end
    pcall(function()
        if obj:IsA("MeshPart") then
            saveProperty(obj, "Material")
            saveProperty(obj, "Reflectance")
            saveProperty(obj, "CastShadow")
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            if state.ultraBurik then
                saveProperty(obj, "TextureID")
                obj.TextureID = ""
            end
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
        elseif obj:IsA("SpecialMesh") and state.ultraBurik then
            saveProperty(obj, "TextureId")
            obj.TextureId = ""
        elseif (obj:IsA("Decal") or obj:IsA("Texture")) and state.ultraBurik then
            saveProperty(obj, "Transparency")
            obj.Transparency = 1
        elseif obj:IsA("SurfaceAppearance") and state.ultraBurik then
            saveProperty(obj, "Parent")
            obj.Parent = nil
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            saveEffect(obj)
            obj.Enabled = false
        elseif obj:IsA("PostEffect") and (state.fpsBoost or state.ultraBurik) then
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
                        if value and obj.Parent == nil then obj.Parent = value end
                    elseif obj.Parent then
                        obj[property] = value
                    end
                end)
            end
        end
    end
    for obj, enabled in pairs(savedEffects) do
        if obj and obj.Parent then pcall(function() obj.Enabled = enabled end) end
    end
    Lighting.GlobalShadows = savedLighting.GlobalShadows
    Lighting.FogEnd = savedLighting.FogEnd
end

local function applyOptimization()
    if state.fpsBoost or state.ultraBurik then
        for _, obj in ipairs(Workspace:GetDescendants()) do optimizeObject(obj) end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
    else
        restoreVisuals()
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
                    obj.CelestialBodiesShown = savedSky[obj].CelestialBodiesShown
                    obj.StarCount = savedSky[obj].StarCount
                end
            end)
        end
    end
end

local function applyAntiBlur()
    local active = state.antiBlur or state.noShake
    local containers = {Lighting}
    if Workspace.CurrentCamera then table.insert(containers, Workspace.CurrentCamera) end
    for _, container in ipairs(containers) do
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("BlurEffect") then
                if active then
                    saveEffect(obj)
                    obj.Enabled = false
                elseif savedEffects[obj] ~= nil then
                    pcall(function() obj.Enabled = savedEffects[obj] end)
                end
            end
        end
    end
end

local function applyFullBright()
    if state.fullBright then
        Lighting.Brightness = 2.2
        Lighting.Ambient = Color3.fromRGB(155, 155, 155)
        Lighting.OutdoorAmbient = Color3.fromRGB(175, 175, 175)
        Lighting.ExposureCompensation = 0.2
    else
        Lighting.Brightness = savedLighting.Brightness
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.ExposureCompensation = savedLighting.ExposureCompensation
    end
end

local function applyInstantInteract()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if state.instantInteract then
                if savedPrompts[obj] == nil then savedPrompts[obj] = obj.HoldDuration end
                obj.HoldDuration = 0
            elseif savedPrompts[obj] ~= nil then
                pcall(function() obj.HoldDuration = savedPrompts[obj] end)
                savedPrompts[obj] = nil
            end
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
main.Size = UDim2.fromOffset(250, 360)
main.Position = UDim2.new(0, 24, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(220, 55, 65)
stroke.Thickness = 1.5
stroke.Parent = main

local stars = Instance.new("Frame")
stars.Name = "Stars"
stars.BackgroundTransparency = 1
stars.Size = UDim2.fromScale(1, 1)
stars.ClipsDescendants = true
stars.ZIndex = 1
stars.Parent = main
Instance.new("UICorner", stars).CornerRadius = UDim.new(0, 10)
for i = 1, 32 do
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(i % 4 == 0 and 2 or 1, i % 4 == 0 and 2 or 1)
    dot.Position = UDim2.new(((i * 37) % 97) / 100, 0, ((i * 23) % 95) / 100, 0)
    dot.BackgroundColor3 = Color3.fromRGB(190, 190, 210)
    dot.BackgroundTransparency = 0.15 + ((i % 4) * 0.15)
    dot.BorderSizePixel = 0
    dot.ZIndex = 1
    dot.Parent = stars
end

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(125, 20, 32)
header.BackgroundTransparency = 0.05
header.BorderSizePixel = 0
header.ZIndex = 2
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
title.ZIndex = 3
title.Parent = header
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 27)
close.Position = UDim2.new(1, -35, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 13
close.Font = Enum.Font.GothamBold
close.ZIndex = 3
close.Parent = header
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, -24, 0, 24)
pingLabel.Position = UDim2.fromOffset(12, 52)
pingLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
pingLabel.BackgroundTransparency = 0.1
pingLabel.Text = "PING: ..."
pingLabel.TextColor3 = Color3.fromRGB(100, 230, 145)
pingLabel.TextSize = 11
pingLabel.Font = Enum.Font.GothamMedium
pingLabel.ZIndex = 2
pingLabel.Parent = main
Instance.new("UICorner", pingLabel).CornerRadius = UDim.new(0, 5)

local buttons = {}
local function updateButton(key)
    local item = buttons[key]
    if not item then return end
    local enabled = state[key]
    item.button.Text = item.label .. (enabled and "  [ON]" or "  [OFF]")
    item.button.BackgroundColor3 = enabled and Color3.fromRGB(125, 25, 38) or Color3.fromRGB(35, 35, 43)
end

local function createToggle(key, label, y, callback)
    local button = Instance.new("TextButton")
    button.Name = key .. "Toggle"
    button.Size = UDim2.new(1, -24, 0, 30)
    button.Position = UDim2.fromOffset(12, y)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 43)
    button.BackgroundTransparency = 0.05
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 11
    button.Font = Enum.Font.GothamSemibold
    button.ZIndex = 2
    button.Parent = main
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    buttons[key] = {button = button, label = label}
    button.MouseButton1Click:Connect(function()
        state[key] = not state[key]
        local ok, err = pcall(callback)
        if not ok then warn("[SC FPS] " .. tostring(err)) end
        updateButton(key)
    end)
end

createToggle("fpsBoost", "FPS BOOST", 84, applyOptimization)
createToggle("ultraBurik", "ULTRA BURIK", 119, applyOptimization)
createToggle("blackSky", "BLACK SKY", 154, applyBlackSky)
createToggle("antiBlur", "ANTI-BLUR", 189, applyAntiBlur)
createToggle("fullBright", "FULL BRIGHT", 224, applyFullBright)
createToggle("noShake", "NO SHAKE (SAFE)", 259, applyAntiBlur)
createToggle("instantInteract", "INSTANT INTERACT", 294, applyInstantInteract)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -24, 0, 20)
note.Position = UDim2.fromOffset(12, 331)
note.BackgroundTransparency = 1
note.Text = "Right Alt: show / hide"
note.TextColor3 = Color3.fromRGB(175, 175, 190)
note.TextSize = 10
note.Font = Enum.Font.Gotham
note.ZIndex = 2
note.Parent = main

for key in pairs(buttons) do updateButton(key) end

local dragging, dragStart, startPosition = false, nil, nil
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
UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
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
        if state.fpsBoost or state.ultraBurik then optimizeObject(obj) end
        if state.instantInteract and obj:IsA("ProximityPrompt") then
            if savedPrompts[obj] == nil then savedPrompts[obj] = obj.HoldDuration end
            obj.HoldDuration = 0
        end
    end)
end)
Lighting.DescendantAdded:Connect(function(obj)
    if obj:IsA("BlurEffect") and (state.antiBlur or state.noShake) then
        task.defer(applyAntiBlur)
    end
end)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if state.antiBlur or state.noShake then task.defer(applyAntiBlur) end
end)

local starTime = 0
RunService.RenderStepped:Connect(function(dt)
    starTime += dt
    if starTime >= 0.08 then
        starTime = 0
        for i, dot in ipairs(stars:GetChildren()) do
            if dot:IsA("Frame") then
                local y = dot.Position.Y.Scale + (i % 2 == 0 and 0.002 or 0.001)
                if y > 1 then y = 0 end
                dot.Position = UDim2.new(dot.Position.X.Scale, 0, y, 0)
            end
        end
    end
end)

task.spawn(function()
    while gui.Parent do
        local value = "N/A"
        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")
            if dataPing then value = dataPing:GetValueString() end
        end)
        if pingLabel and pingLabel.Parent then pingLabel.Text = "PING: " .. value end
        task.wait(0.1)
    end
end)
print("[SC FPS | Farhan Store] Loaded")
