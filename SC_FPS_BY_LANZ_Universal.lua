
-- SC FPS | Farhan Store

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
    blackSky = false,
    antiBlur = false,
    fullBright = false,
    noShake = false,
    guiVisible = true
}

local savedParts = setmetatable({}, {__mode = "k"})
local savedEffects = setmetatable({}, {__mode = "k"})
local savedSky = setmetatable({}, {__mode = "k"})
local savedLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation
}

local function savePart(obj)
    if savedParts[obj] then return end

    local data = {}

    pcall(function()
        if obj:IsA("BasePart") then
            data.Material = obj.Material
            data.Reflectance = obj.Reflectance
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            data.Transparency = obj.Transparency
        end
    end)

    savedParts[obj] = data
end

local function saveEffect(obj)
    if savedEffects[obj] == nil then
        pcall(function()
            savedEffects[obj] = obj.Enabled
        end)
    end
end

local function optimizeObject(obj)
    if not state.fpsBoost then return end

    pcall(function()
        if obj:IsA("BasePart") then
            savePart(obj)
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            savePart(obj)
            obj.Transparency = 1

        elseif obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Beam") then

            saveEffect(obj)
            obj.Enabled = false
        end
    end)
end

local function applyFPSBoost()
    if state.fpsBoost then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeObject(obj)
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
    else
        for obj, data in pairs(savedParts) do
            if obj and obj.Parent then
                pcall(function()
                    for property, value in pairs(data) do
                        obj[property] = value
                    end
                end)
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
                obj.CelestialBodiesShown = not state.blackSky
                obj.StarCount = state.blackSky and 0 or savedSky[obj].StarCount
            end)
        end
    end
end

local function applyAntiBlur()
    if not (state.antiBlur or state.noShake) then
        for obj, enabled in pairs(savedEffects) do
            if obj and obj.Parent and obj:IsA("BlurEffect") then
                pcall(function()
                    obj.Enabled = enabled
                end)
            end
        end
        return
    end

    for _, container in ipairs({Lighting, Workspace.CurrentCamera}) do
        if container then
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("BlurEffect") then
                    saveEffect(obj)
                    obj.Enabled = false
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
        Lighting.Brightness = savedLighting.Brightness
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.ExposureCompensation = savedLighting.ExposureCompensation
    end
end

-- GUI

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(300, 445)
main.Position = UDim2.new(0, 24, 0.25, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(220, 55, 65)
stroke.Thickness = 1.5
stroke.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(145, 25, 35)
header.BorderSizePixel = 0
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
close.Parent = header

Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, -24, 0, 25)
pingLabel.Position = UDim2.fromOffset(12, 52)
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
    item.button.Text = item.label .. (enabled and "  [ON]" or "  [OFF]")
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

createToggle("fpsBoost", "FPS Boost / Low Texture", 87, applyFPSBoost)
createToggle("blackSky", "Black Sky", 127, applyBlackSky)
createToggle("antiBlur", "Anti-Blur", 167, applyAntiBlur)
createToggle("fullBright", "Full Bright", 207, applyFullBright)
createToggle("noShake", "No Shake (Safe)", 247, applyAntiBlur)

local fontTitle = Instance.new("TextLabel")
fontTitle.Size = UDim2.new(1, -24, 0, 20)
fontTitle.Position = UDim2.fromOffset(12, 286)
fontTitle.BackgroundTransparency = 1
fontTitle.Text = "Font"
fontTitle.TextColor3 = Color3.new(1, 1, 1)
fontTitle.TextSize = 13
fontTitle.Font = Enum.Font.GothamBold
fontTitle.TextXAlignment = Enum.TextXAlignment.Left
fontTitle.Parent = main

local fontNames = {"Default", "Minecraft Regular", "Lenmok"}
local fontValues = {Enum.Font.Gotham, Enum.Font.Code, Enum.Font.SciFi}
local selectedFont = 1

local fontButton = Instance.new("TextButton")
fontButton.Size = UDim2.new(1, -24, 0, 32)
fontButton.Position = UDim2.fromOffset(12, 310)
fontButton.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
fontButton.BorderSizePixel = 0
fontButton.TextColor3 = Color3.new(1, 1, 1)
fontButton.TextSize = 12
fontButton.Font = Enum.Font.Gotham
fontButton.Text = "Font: Default  >"
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
applyButton.Position = UDim2.fromOffset(12, 350)
applyButton.BackgroundColor3 = Color3.fromRGB(145, 25, 35)
applyButton.BorderSizePixel = 0
applyButton.Text = "Apply"
applyButton.TextColor3 = Color3.new(1, 1, 1)
applyButton.TextSize = 12
applyButton.Font = Enum.Font.GothamBold
applyButton.Parent = main

Instance.new("UICorner", applyButton).CornerRadius = UDim.new(0, 6)

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0.5, -16, 0, 30)
resetButton.Position = UDim2.new(0.5, 4, 0, 350)
resetButton.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
resetButton.BorderSizePixel = 0
resetButton.Text = "Reset"
resetButton.TextColor3 = Color3.new(1, 1, 1)
resetButton.TextSize = 12
resetButton.Font = Enum.Font.GothamBold
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
note.Size = UDim2.new(1, -24, 0, 30)
note.Position = UDim2.fromOffset(12, 390)
note.BackgroundTransparency = 1
note.Text = "Right Alt: buka/tutup menu"
note.TextColor3 = Color3.fromRGB(190, 190, 200)
note.TextSize = 11
note.Font = Enum.Font.Gotham
note.Parent = main

for key in pairs(buttons) do
    updateButton(key)
end

-- Geser GUI dari bagian atas

do
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
end

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
end)

-- Update ping

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
