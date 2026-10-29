
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
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
local Light = false
local Minimized = false
local Busy = false
local Token = 0

local FONT_ID = 12187372382
local BATCH = 25
local PAUSE = 0.04

local Connections = {}
local Saved = {}
local FontSaved = {}
local LightingSaved = {}
local QualitySaved

local GUI
local Main
local FPSButton
local LightButton
local PingLabel

local SkyCreated
local OriginalSkies = {}

local function connect(signal, fn)
    local connection = signal:Connect(fn)
    Connections[#Connections + 1] = connection
    return connection
end

local function setSaved(obj, prop, value)
    if not obj then return end

    local ok, old = pcall(function()
        return obj[prop]
    end)

    if not ok then return end

    local record = Saved[obj]

    if not record then
        record = {}
        Saved[obj] = record
    end

    if record[prop] == nil then
        record[prop] = old
    end

    pcall(function()
        obj[prop] = value
    end)
end

local function saveLighting()
    for _, prop in ipairs({
        "Brightness",
        "Ambient",
        "OutdoorAmbient",
        "ExposureCompensation",
        "GlobalShadows",
        "FogEnd",
        "EnvironmentDiffuseScale",
        "EnvironmentSpecularScale",
        "ShadowSoftness"
    }) do
        pcall(function()
            LightingSaved[prop] = Lighting[prop]
        end)
    end
end

saveLighting()

local function applyLighting()
    for prop, value in pairs(LightingSaved) do
        pcall(function()
            Lighting[prop] = value
        end)
    end

    if FPS then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1000000000
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.ShadowSoftness = 0
        end)
    end

    if Light then
        pcall(function()
            Lighting.Brightness = math.max(
                LightingSaved.Brightness or 1,
                1.35
            )

            Lighting.Ambient = Color3.fromRGB(95, 95, 95)
            Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 105)
            Lighting.ExposureCompensation = 0
        end)
    end
end

local function protectedObject(obj)
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
    if protectedObject(obj) then return end

    if obj:IsA("BasePart") then
        setSaved(obj, "Material", Enum.Material.Plastic)
        setSaved(obj, "Reflectance", 0)
        setSaved(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            setSaved(obj, "TextureID", "")

            pcall(function()
                setSaved(
                    obj,
                    "RenderFidelity",
                    Enum.RenderFidelity.Performance
                )
            end)
        end

    elseif obj:IsA("SpecialMesh") then
        setSaved(obj, "TextureId", "")

    elseif obj:IsA("SurfaceAppearance") then
        setSaved(obj, "ColorMap", "")
        setSaved(obj, "NormalMap", "")
        setSaved(obj, "MetalnessMap", "")
        setSaved(obj, "RoughnessMap", "")

    elseif obj:IsA("Decal")
        or obj:IsA("Texture") then

        setSaved(obj, "Transparency", 1)

    elseif obj:IsA("ParticleEmitter") then
        setSaved(obj, "Enabled", false)
        setSaved(obj, "Rate", 0)

        pcall(function()
            obj:Clear()
        end)

    elseif obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles") then

        setSaved(obj, "Enabled", false)

    elseif obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then

        setSaved(obj, "Shadows", false)

    elseif obj:IsA("Highlight")
        or obj:IsA("PostEffect")
        or obj:IsA("Clouds") then

        setSaved(obj, "Enabled", false)

    elseif obj:IsA("Atmosphere") then
        setSaved(obj, "Density", 0)
        setSaved(obj, "Haze", 0)
        setSaved(obj, "Glare", 0)
    end
end

local function applySky()
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            OriginalSkies[child] = child.Parent
            child.Parent = nil
        end
    end

    if SkyCreated then
        SkyCreated:Destroy()
    end

    local sky = Instance.new("Sky")
    sky.Name = "FarhanStore_LowSky"

    sky.SkyboxBk = ""
    sky.SkyboxDn = ""
    sky.SkyboxFt = ""
    sky.SkyboxLf = ""
    sky.SkyboxRt = ""
    sky.SkyboxUp = ""

    sky.CelestialBodiesShown = false
    sky.StarCount = 0
    sky.Parent = Lighting

    SkyCreated = sky
end

local function restoreSky()
    if SkyCreated then
        SkyCreated:Destroy()
        SkyCreated = nil
    end

    for sky, parent in pairs(OriginalSkies) do
        pcall(function()
            sky.Parent = parent
        end)
    end

    table.clear(OriginalSkies)
end

local function environment()
    setSaved(Terrain, "WaterWaveSize", 0)
    setSaved(Terrain, "WaterWaveSpeed", 0)
    setSaved(Terrain, "WaterReflectance", 0)
    setSaved(Terrain, "WaterTransparency", 1)

    pcall(function()
        setSaved(Terrain, "Decoration", false)
    end)

    pcall(function()
        local rendering = settings().Rendering

        if QualitySaved == nil then
            QualitySaved = rendering.QualityLevel
        end

        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    applySky()
    applyLighting()
end

local function restoreObjects()
    local count = 0

    for obj, properties in pairs(Saved) do
        for prop, old in pairs(properties) do
            pcall(function()
                obj[prop] = old
            end)
        end

        Saved[obj] = nil
        count += 1

        if count >= BATCH then
            count = 0
            task.wait(PAUSE)
        end
    end

    if QualitySaved ~= nil then
        pcall(function()
            settings().Rendering.QualityLevel = QualitySaved
        end)

        QualitySaved = nil
    end

    restoreSky()
end

local function scan(root, token)
    local stack = {root}
    local count = 0

    while #stack > 0 do
        if not Alive or not FPS or token ~= Token then
            return
        end

        local obj = table.remove(stack)

        if obj and obj.Parent then
            pcall(optimize, obj)

            local children = obj:GetChildren()

            for i = 1, #children do
                stack[#stack + 1] = children[i]
            end
        end

        count += 1

        if count >= BATCH then
            count = 0
            task.wait(PAUSE)
        end
    end
end

local function refresh()
    if FPSButton then
        FPSButton.Text = "Enabled"

        FPSButton.BackgroundColor3 = FPS
            and Color3.fromRGB(0, 105, 225)
            or Color3.fromRGB(26, 39, 62)
    end

    if LightButton then
        LightButton.Text = "Light"

        LightButton.BackgroundColor3 = Light
            and Color3.fromRGB(0, 105, 225)
            or Color3.fromRGB(26, 39, 62)
    end
end

local function enableFPS()
    if FPS or Busy or not Alive then return end

    FPS = true
    Token += 1

    local currentToken = Token

    environment()
    refresh()

    task.spawn(function()
        scan(Workspace, currentToken)
    end)

    task.spawn(function()
        scan(Lighting, currentToken)
    end)
end

local function disableFPS()
    if not FPS or Busy then return end

    FPS = false
    Busy = true
    Token += 1

    refresh()

    task.spawn(function()
        restoreObjects()
        applyLighting()

        Busy = false
        refresh()
    end)
end

local GameFont

pcall(function()
    GameFont = Font.fromId(FONT_ID)
end)

local function applyFont(obj)
    if not Alive or not GameFont then return end
    if not obj then return end

    if GUI and obj:IsDescendantOf(GUI) then
        return
    end

    if not (
        obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox")
    ) then
        return
    end

    if FontSaved[obj] == nil then
        local ok, old = pcall(function()
            return obj.FontFace
        end)

        if ok then
            FontSaved[obj] = old
        end
    end

    pcall(function()
        obj.FontFace = GameFont
    end)
end

local function scanFonts(root)
    local count = 0

    for _, obj in ipairs(root:GetDescendants()) do
        if not Alive then return end

        applyFont(obj)

        count += 1

        if count >= BATCH then
            count = 0
            task.wait(PAUSE)
        end
    end
end

local function restoreFonts()
    for obj, old in pairs(FontSaved) do
        pcall(function()
            obj.FontFace = old
        end)
    end

    table.clear(FontSaved)
end

GUI = Instance.new("ScreenGui")
GUI.Name = "FarhanStore_UltraPotato"
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
Title.Size = UDim2.new(1, -35, 0, 28)
Title.Position = UDim2.fromOffset(10, 7)
Title.BackgroundTransparency = 1
Title.RichText = true

Title.Text =
    '<font color="#FFFFFF">Farhan</font>' ..
    '<font color="#168BFF">Store</font>'

Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.ZIndex = 2
Title.Parent = Main

local Minimize = Instance.new("TextButton")
Minimize.Name = "Minimize"
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
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.ZIndex = 2
    button.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = button

    return button
end

FPSButton = makeButton("FPSBoost", 43)
LightButton = makeButton("FullBrightLow", 79)

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

connect(FPSButton.MouseButton1Click, function()
    if Busy then return end

    if FPS then
        disableFPS()
    else
        enableFPS()
    end
end)

connect(LightButton.MouseButton1Click, function()
    Light = not Light
    applyLighting()
    refresh()
end)

connect(Minimize.MouseButton1Click, function()
    Minimized = not Minimized

    FPSButton.Visible = not Minimized
    LightButton.Visible = not Minimized
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
    if FPS and not Busy then
        task.defer(function()
            if FPS and Alive then
                pcall(optimize, obj)
            end
        end)
    end

    applyFont(obj)
end)

connect(Lighting.DescendantAdded, function(obj)
    if FPS and not Busy and obj ~= SkyCreated then
        task.defer(function()
            if FPS and Alive then
                pcall(optimize, obj)
            end
        end)
    end
end)

connect(PlayerGui.DescendantAdded, applyFont)

connect(game.DescendantAdded, function(obj)
    if obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox") then

        applyFont(obj)
    end
end)

task.spawn(function()
    scanFonts(PlayerGui)
    scanFonts(Workspace)
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

    FPS = false
    Light = false
    Token += 1
    Busy = true

    Alive = false

    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    table.clear(Connections)

    restoreObjects()
    restoreFonts()
    applyLighting()

    if GUI then
        GUI:Destroy()
    end
end

ENV.FarhanFPSOnlyCleanup = cleanup

refresh()

print("FARHAN STORE | ULTRA POTATO V1.4")
