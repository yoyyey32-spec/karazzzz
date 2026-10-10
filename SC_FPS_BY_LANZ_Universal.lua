
-- SC FPS | Farhan Store

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("SCFPS")
if old then
    old:Destroy()
end

local state = {
    fps = false,
    blur = false,
    bright = false,
    shake = false,
    visible = true
}

local oldLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation
}

local savedParts = setmetatable({}, {__mode = "k"})
local savedEffects = setmetatable({}, {__mode = "k"})
local savedSky = setmetatable({}, {__mode = "k"})

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

local function lowTexture(obj)
    if not state.fps then return end

    savePart(obj)

    pcall(function()
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Beam")
            or obj:IsA("BlurEffect") then

            if savedEffects[obj] == nil then
                savedEffects[obj] = obj.Enabled
            end

            obj.Enabled = false
        end
    end)
end

local function blackSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            if not savedSky[obj] then
                savedSky[obj] = {
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
    for obj, data in pairs(savedSky) do
        if obj and obj.Parent then
            pcall(function()
                for property, value in pairs(data) do
                    obj[property] = value
                end
            end)
        end
    end
end

local function setFPS()
    if state.fps then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            lowTexture(obj)
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        blackSky()
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

        Lighting.GlobalShadows = oldLighting.GlobalShadows
        Lighting.FogEnd = oldLighting.FogEnd
        restoreSky()
    end
end

local function setBlur()
    if not (state.blur or state.shake) then
        for obj, enabled in pairs(savedEffects) do
            if obj and obj.Parent and obj:IsA("BlurEffect") then
                pcall(function()
                    obj.Enabled = enabled
                end)
            end
        end
        return
    end

    local function scan(container)
        if not container then return end

        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("BlurEffect") then
                if savedEffects[obj] == nil then
                    savedEffects[obj] = obj.Enabled
                end

                obj.Enabled = false
            end
        end
    end

    scan(Lighting)
    scan(Workspace.CurrentCamera)
end

local function setBright()
    if state.bright then
        Lighting.Brightness = 2.2
        Lighting.Ambient = Color3.fromRGB(145, 145, 145)
        Lighting.OutdoorAmbient = Color3.fromRGB(165, 165, 165)
        Lighting.ExposureCompensation = 0.15
    else
        Lighting.Brightness = oldLighting.Brightness
        Lighting.Ambient = oldLighting.Ambient
        Lighting.OutdoorAmbient = oldLighting.OutdoorAmbient
        Lighting.ExposureCompensation =
            oldLighting.ExposureCompensation
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(285, 375)
main.Position = UDim2.new(0, 25, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local border = Instance.new("UIStroke")
border.Color = Color3.fromRGB(180, 40, 48)
border.Thickness = 1.2
border.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 38)
header.BackgroundColor3 = Color3.fromRGB(135, 30, 38)
header.BorderSizePixel = 0
header.Parent = main

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)

local function makeText(parent, text, size, pos, fontSize)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.Size = size
    label.Position = pos
    label.Font = Enum.Font.Gotham
    label.TextSize = fontSize or 12
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Parent = parent
    return label
end

local title = makeText(
    header,
    "SC FPS",
    UDim2.new(1, -55, 1, 0),
    UDim2.fromOffset(12, 0),
    14
)
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 26)
close.Position = UDim2.new(1, -35, 0, 6)
close.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 12
close.Font = Enum.Font.GothamBold
close.Parent = header

Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

close.MouseButton1Click:Connect(function()
    state.visible = false
    main.Visible = false
end)

local ping = makeText(
    main,
    "Ping: ...",
    UDim2.new(1, -20, 0, 24),
    UDim2.fromOffset(10, 43),
    12
)
ping.TextColor3 = Color3.fromRGB(100, 220, 130)
ping.BackgroundTransparency = 0
ping.BackgroundColor3 = Color3.fromRGB(33, 33, 38)

Instance.new("UICorner", ping).CornerRadius = UDim.new(0, 5)

local function makeButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 31)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(48, 48, 54)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.Parent = main

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
    return button
end

local toggleButtons = {}

local function makeToggle(key, text, y, callback)
    local button = makeButton("", y)
    toggleButtons[key] = button

    local function refresh()
        button.Text = text .. (state[key] and "  [ON]" or "  [OFF]")
        button.BackgroundColor3 = state[key]
            and Color3.fromRGB(125, 35, 43)
            or Color3.fromRGB(48, 48, 54)
    end

    button.MouseButton1Click:Connect(function()
        state[key] = not state[key]

        local ok, err = pcall(callback)
        if not ok then warn("[SC FPS]", err) end

        refresh()
    end)

    refresh()
end

makeToggle("fps", "FPS Boost", 76, setFPS)
makeToggle("blur", "Anti Blur", 113, setBlur)
makeToggle("bright", "Full Bright", 150, setBright)
makeToggle("shake", "No Shake", 187, setBlur)

-- Font menu
local fontLabel = makeText(
    main,
    "Font",
    UDim2.new(1, -20, 0, 20),
    UDim2.fromOffset(10, 228),
    12
)
fontLabel.TextXAlignment = Enum.TextXAlignment.Left
fontLabel.Font = Enum.Font.GothamBold

local fontList = {
    {name = "Default", font = Enum.Font.Gotham},
    {name = "Minecraft Regular", font = Enum.Font.Code},
    {name = "Lenmok", font = Enum.Font.SciFi}
}

local fontIndex = 1

local fontButton = makeButton("Default", 251)
local applyButton = makeButton("Apply", 288)
local resetButton = makeButton("Reset", 325)

local function applyFont()
    local font = fontList[fontIndex].font

    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox") then
            obj.Font = font
        end
    end

    fontButton.Text = fontList[fontIndex].name
end

fontButton.MouseButton1Click:Connect(function()
    fontIndex = fontIndex % #fontList + 1
    fontButton.Text = fontList[fontIndex].name
end)

applyButton.MouseButton1Click:Connect(applyFont)

resetButton.MouseButton1Click:Connect(function()
    fontIndex = 1
    applyFont()
end)

-- Drag window
do
    local dragging = false
    local dragStart
    local startPosition
    local dragInput

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

    UIS.InputChanged:Connect(function(input)
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

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightAlt then
        state.visible = not state.visible
        main.Visible = state.visible
    end
end)

Workspace.DescendantAdded:Connect(function(obj)
    if state.fps then
        task.defer(function()
            if obj and obj.Parent then lowTexture(obj) end
        end)
    end
end)

Lighting.DescendantAdded:Connect(function(obj)
    if (state.blur or state.shake) and obj:IsA("BlurEffect") then
        task.defer(setBlur)
    end

    if state.fps and obj:IsA("Sky") then
        task.defer(blackSky)
    end
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if state.blur or state.shake then
        task.defer(setBlur)
    end
end)

task.spawn(function()
    while gui.Parent do
        local text = "Ping: N/A"

        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network
                and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats
                and serverStats:FindFirstChild("Data Ping")

            if dataPing then
                text = "Ping: " .. dataPing:GetValueString()
            end
        end)

        if ping.Parent then ping.Text = text end
        task.wait(0.1)
    end
end)

print("[SC FPS] Loaded")
