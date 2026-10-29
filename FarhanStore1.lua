
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Terrain = Workspace.Terrain

local ENV = getgenv and getgenv() or _G

if type(ENV.FarhanFPSOnlyCleanup) == "function" then
    pcall(ENV.FarhanFPSOnlyCleanup)
end

local Alive = true
local FPS = false
local Bright = false
local Minimized = false
local Generation = 0

local Connections = {}
local Saved = {}
local LightingSaved = {}
local QualitySaved = nil

local Queue = {}
local QueueHead = 1
local Queued = setmetatable({}, {__mode = "k"})

local BATCH = 35
local DELAY = 0.025

local POTATO_TEXTURE = "rbxassetid://10385902758728957"

local GUI
local Main
local FPSToggle
local BrightToggle
local PingLabel

local function connect(signal, callback)
    local c = signal:Connect(callback)
    Connections[#Connections + 1] = c
    return c
end

local function change(obj, prop, value)
    if not obj then return end

    local ok, old = pcall(function()
        return obj[prop]
    end)

    if not ok then return end

    local data = Saved[obj]

    if not data then
        data = {}
        Saved[obj] = data
    end

    if data[prop] == nil then
        data[prop] = old
    end

    pcall(function()
        obj[prop] = value
    end)
end

local function restoreObjects()
    for obj, data in pairs(Saved) do
        for prop, old in pairs(data) do
            pcall(function()
                obj[prop] = old
            end)
        end
    end

    table.clear(Saved)
end

local function captureLighting()
    local properties = {
        "Brightness",
        "Ambient",
        "OutdoorAmbient",
        "ExposureCompensation",
        "GlobalShadows",
        "FogEnd",
        "EnvironmentDiffuseScale",
        "EnvironmentSpecularScale",
        "ShadowSoftness"
    }

    for _, prop in ipairs(properties) do
        pcall(function()
            LightingSaved[prop] = Lighting[prop]
        end)
    end
end

captureLighting()

local function applyLighting()
    for prop, old in pairs(LightingSaved) do
        pcall(function()
            Lighting[prop] = old
        end)
    end

    if FPS then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.ShadowSoftness = 0
        end)
    end

    if Bright then
        Lighting.Brightness = math.max(
            LightingSaved.Brightness or 1,
            1.5
        )

        Lighting.Ambient = Color3.fromRGB(105, 105, 105)
        Lighting.OutdoorAmbient = Color3.fromRGB(115, 115, 115)
        Lighting.ExposureCompensation = 0
    end
end

local function protected(obj)
    if not obj then return true end

    if obj:FindFirstAncestorOfClass("Tool")
        or obj:FindFirstAncestorOfClass("Accessory") then
        return true
    end

    local character = Player.Character

    if character and (
        obj == character
        or obj:IsDescendantOf(character)
    ) then
        return true
    end

    return false
end

local function optimize(obj)
    if not Alive or not FPS then return end
    if not obj or not obj.Parent then return end
    if protected(obj) then return end

    if obj:IsA("BasePart") then
        change(obj, "Material", Enum.Material.Plastic)
        change(obj, "Reflectance", 0)
        change(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            change(obj, "TextureID", POTATO_TEXTURE)

            pcall(function()
                change(
                    obj,
                    "RenderFidelity",
                    Enum.RenderFidelity.Performance
                )
            end)
        end

    elseif obj:IsA("SpecialMesh") then
        change(obj, "TextureId", POTATO_TEXTURE)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)

    elseif obj:IsA("SurfaceAppearance") then
        change(obj, "ColorMap", "")
        change(obj, "NormalMap", "")
        change(obj, "MetalnessMap", "")
        change(obj, "RoughnessMap", "")

    elseif obj:IsA("ParticleEmitter") then
        change(obj, "Enabled", false)
        change(obj, "Rate", 0)

        pcall(function()
            obj:Clear()
        end)

    elseif obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles") then

        change(obj, "Enabled", false)

    elseif obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then

        change(obj, "Shadows", false)

    elseif obj:IsA("Highlight")
        or obj:IsA("PostEffect")
        or obj:IsA("Clouds") then

        change(obj, "Enabled", false)
    end
end

local function optimizeEnvironment()
    change(Terrain, "WaterWaveSize", 0)
    change(Terrain, "WaterWaveSpeed", 0)
    change(Terrain, "WaterReflectance", 0)
    change(Terrain, "WaterTransparency", 1)

    pcall(function()
        change(Terrain, "Decoration", false)
    end)

    if type(sethiddenproperty) == "function" then
        pcall(function()
            sethiddenproperty(Terrain, "Decoration", false)
        end)
    end

    pcall(function()
        local rendering = settings().Rendering

        if QualitySaved == nil then
            QualitySaved = rendering.QualityLevel
        end

        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    applyLighting()
end

local function enqueue(obj)
    if not Alive or not FPS or not obj then return end
    if Queued[obj] then return end

    Queued[obj] = true
    Queue[#Queue + 1] = obj
end

local function scan(root, token)
    local stack = {root}
    local count = 0

    while #stack > 0 do
        if not Alive or not FPS or token ~= Generation then
            return
        end

        local obj = table.remove(stack)

        if obj then
            enqueue(obj)

            local children = obj:GetChildren()

            for i = 1, #children do
                stack[#stack + 1] = children[i]
            end
        end

        count += 1

        if count >= BATCH then
            count = 0
            task.wait(DELAY)
        end
    end
end

local function worker(token)
    while Alive and FPS and token == Generation do
        local count = 0

        while count < BATCH and QueueHead <= #Queue do
            if not Alive or not FPS or token ~= Generation then
                return
            end

            local obj = Queue[QueueHead]
            Queue[QueueHead] = false
            QueueHead += 1

            if obj then
                Queued[obj] = nil
                pcall(optimize, obj)
            end

            count += 1
        end

        if QueueHead > #Queue then
            Queue = {}
            QueueHead = 1
        end

        task.wait(DELAY)
    end
end

local function refresh()
    if FPSToggle then
        FPSToggle.Text = FPS
            and "FPS BOOST : ON"
            or "FPS BOOST : OFF"

        FPSToggle.BackgroundColor3 = FPS
            and Color3.fromRGB(0, 95, 210)
            or Color3.fromRGB(26, 39, 62)
    end

    if BrightToggle then
        BrightToggle.Text = Bright
            and "FULL BRIGHT : ON"
            or "FULL BRIGHT : OFF"

        BrightToggle.BackgroundColor3 = Bright
            and Color3.fromRGB(0, 95, 210)
            or Color3.fromRGB(26, 39, 62)
    end
end

local function enableFPS()
    if FPS or not Alive then return end

    FPS = true
    Generation += 1

    local token = Generation

    optimizeEnvironment()
    refresh()

    task.spawn(worker, token)
    task.spawn(scan, Workspace, token)
    task.spawn(scan, Lighting, token)
end

local function disableFPS()
    if not FPS then return end

    FPS = false
    Generation += 1

    Queue = {}
    QueueHead = 1
    Queued = setmetatable({}, {__mode = "k"})

    restoreObjects()

    if QualitySaved ~= nil then
        pcall(function()
            settings().Rendering.QualityLevel = QualitySaved
        end)

        QualitySaved = nil
    end

    applyLighting()
    refresh()
end

local function setBright(value)
    Bright = value
    applyLighting()
    refresh()
end

GUI = Instance.new("ScreenGui")
GUI.Name = "FarhanStore_FPS_ONLY_V12"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(195, 155)
Main.Position = UDim2.new(0, 25, 0.5, -77)
Main.BackgroundColor3 = Color3.fromRGB(7, 9, 16)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(235, 238, 245)
Stroke.Thickness = 1.4
Stroke.Parent = Main

for i = 1, 18 do
    local star = Instance.new("Frame")
    star.Size = UDim2.fromOffset(1, 1)

    star.Position = UDim2.new(
        ((i * 37) % 100) / 100, 0,
        ((i * 23) % 100) / 100, 0
    )

    star.BackgroundColor3 = Color3.fromRGB(220, 230, 255)
    star.BackgroundTransparency = (i % 3) * 0.2
    star.BorderSizePixel = 0
    star.Parent = Main
end

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -36, 0, 28)
Title.Position = UDim2.fromOffset(10, 7)
Title.BackgroundTransparency = 1
Title.Text = "FarhanStore"
Title.TextColor3 = Color3.fromRGB(245, 245, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.ZIndex = 2
Title.Parent = Main

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(18, 18)
Minimize.Position = UDim2.new(1, -24, 0, 9)
Minimize.BackgroundColor3 = Color3.fromRGB(0, 91, 205)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 15
Minimize.Font = Enum.Font.GothamBold
Minimize.BorderSizePixel = 0
Minimize.ZIndex = 3
Minimize.Parent = Main

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = Minimize

local function makeButton(name, y)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -34, 0, 29)
    button.Position = UDim2.fromOffset(17, y)
    button.BackgroundColor3 = Color3.fromRGB(26, 39, 62)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.ZIndex = 2
    button.Parent = Main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    return button
end

FPSToggle = makeButton("FPSBoost", 43)
BrightToggle = makeButton("FullBrightLow", 79)

PingLabel = Instance.new("TextLabel")
PingLabel.Name = "Ping"
PingLabel.Size = UDim2.new(1, -20, 0, 23)
PingLabel.Position = UDim2.fromOffset(10, 119)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "PING : -- ms"
PingLabel.TextColor3 = Color3.fromRGB(105, 190, 255)
PingLabel.TextSize = 15
PingLabel.Font = Enum.Font.GothamBold
PingLabel.ZIndex = 2
PingLabel.Parent = Main

connect(FPSToggle.MouseButton1Click, function()
    if FPS then
        disableFPS()
    else
        enableFPS()
    end
end)

connect(BrightToggle.MouseButton1Click, function()
    setBright(not Bright)
end)

connect(Minimize.MouseButton1Click, function()
    Minimized = not Minimized

    FPSToggle.Visible = not Minimized
    BrightToggle.Visible = not Minimized
    PingLabel.Visible = not Minimized

    Main.Size = Minimized
        and UDim2.fromOffset(195, 42)
        or UDim2.fromOffset(195, 155)

    Minimize.Text = Minimized and "+" or "-"
end)

connect(UIS.InputBegan, function(input)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        GUI.Enabled = not GUI.Enabled
    end
end)

local Dragging = false
local DragStart
local StartPosition

connect(Title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if not Dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = false
    end
end)

connect(Workspace.DescendantAdded, function(obj)
    if FPS then
        enqueue(obj)
    end
end)

connect(Lighting.DescendantAdded, function(obj)
    if FPS then
        enqueue(obj)
    end
end)

task.spawn(function()
    while Alive do
        local ping = "--"

        pcall(function()
            local item = Stats.Network.ServerStatsItem["Data Ping"]
            local value = item:GetValueString()
            local number = tonumber(value:match("[%d%.]+"))

            if number then
                ping = tostring(math.floor(number + 0.5))
            end
        end)

        if PingLabel then
            PingLabel.Text = "PING : " .. ping .. " ms"
        end

        task.wait(0.1)
    end
end)

local function cleanup()
    if not Alive then return end

    disableFPS()
    setBright(false)

    Alive = false
    Generation += 1

    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    table.clear(Connections)

    if GUI then
        GUI:Destroy()
    end
end

ENV.FarhanFPSOnlyCleanup = cleanup

refresh()

print("FARHAN STORE | EXTREME POTATO V1.2")
