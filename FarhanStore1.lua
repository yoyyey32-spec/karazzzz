
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Backpack = Player:WaitForChild("Backpack")
local Terrain = Workspace.Terrain
local ENV = getgenv and getgenv() or _G

if type(ENV.FarhanFPSOnlyCleanup) == "function" then
    pcall(ENV.FarhanFPSOnlyCleanup)
end

local Alive = true
local Enabled = false
local Light = false
local Busy = false
local Minimized = false
local Saved = {}
local FontSaved = {}
local Detached = {}
local Guards = {}
local Connections = {}
local OriginalLighting = {}
local OriginalQuality
local Ping = 0
local FPS = 0
local HighPing = false
local GUI, Main, EnableButton, LightButton
local Status, PingLabel, FPSLabel
local CustomFont

pcall(function()
    CustomFont = Font.fromId(12187372382)
end)

local function connect(signal, fn)
    local c = signal:Connect(fn)
    Connections[#Connections + 1] = c
    return c
end

local function isText(obj)
    return obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox")
end

local function applyFont(obj)
    if not Alive or not CustomFont or not isText(obj) then return end

    if FontSaved[obj] == nil then
        local ok, original = pcall(function()
            return obj.FontFace
        end)

        if ok then
            FontSaved[obj] = original
        end
    end

    pcall(function()
        obj.FontFace = CustomFont
    end)
end

local function scanFonts(root)
    if not root then return end

    if isText(root) then
        applyFont(root)
    end

    for _, obj in ipairs(root:GetDescendants()) do
        applyFont(obj)
    end
end

local function saveSet(obj, prop, value)
    if not obj then return end

    local ok, original = pcall(function()
        return obj[prop]
    end)

    if not ok then return end

    local data = Saved[obj]

    if not data then
        data = {}
        Saved[obj] = data
    end

    if data[prop] == nil then
        data[prop] = {original}
    end

    pcall(function()
        obj[prop] = value
    end)
end

local function isEffect(obj)
    return obj:IsA("ParticleEmitter")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Highlight")
        or obj:IsA("PostEffect")
end

local function weaponVisual(obj)
    local current = obj

    while current and current ~= game do
        local n = current.Name:lower()

        for _, word in ipairs({
            "muzzle", "flash", "gunfire", "shoot",
            "smoke", "shotblur", "shootblur",
            "recoilblur", "gunblur", "gunfx"
        }) do
            if n:find(word, 1, true) then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

local function protectedGeometry(obj)
    local char = Player.Character

    if char and obj:IsDescendantOf(char) then
        return true
    end

    return obj:FindFirstAncestorOfClass("Tool") ~= nil
        or obj:FindFirstAncestorOfClass("Accessory") ~= nil
end

local function guard(obj)
    if Guards[obj] then return end

    local ok, connection = pcall(function()
        return obj:GetPropertyChangedSignal("Enabled"):Connect(function()
            if not Alive or not Enabled then return end

            pcall(function()
                if obj.Enabled then
                    obj.Enabled = false
                end
            end)
        end)
    end)

    if ok then
        Guards[obj] = connection
    end
end

local function gunStoreWood(obj)
    if not obj:IsA("BasePart") then return false end
    if protectedGeometry(obj) then return false end
    if not obj.Anchored then return false end
    if obj.CanCollide or obj.CanTouch or obj.CanQuery then return false end

    if obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        or obj:FindFirstChildWhichIsA("ClickDetector", true) then
        return false
    end

    local wood = false
    local store = false
    local current = obj

    while current and current ~= Workspace do
        local n = current.Name:lower()

        for _, word in ipairs({
            "door", "floor", "weapon", "counter",
            "register", "handle", "button"
        }) do
            if n:find(word, 1, true) then
                return false
            end
        end

        for _, word in ipairs({
            "wood", "plank", "board", "timber", "kayu"
        }) do
            if n:find(word, 1, true) then
                wood = true
            end
        end

        for _, word in ipairs({
            "gunstore", "gun store", "gunshop", "gun_shop"
        }) do
            if n:find(word, 1, true) then
                store = true
            end
        end

        current = current.Parent
    end

    return wood and store
end

local function optimize(obj)
    if not Alive or not Enabled or not obj.Parent then return end
    if GUI and (obj == GUI or obj:IsDescendantOf(GUI)) then return end

    if isEffect(obj) then
        saveSet(obj, "Enabled", false)

        if obj:IsA("ParticleEmitter") then
            saveSet(obj, "Rate", 0)

            pcall(function()
                obj:Clear()
            end)
        end

        guard(obj)
        return
    end

    if obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then

        if weaponVisual(obj) then
            saveSet(obj, "Enabled", false)
            guard(obj)
        else
            saveSet(obj, "Shadows", false)
        end

        return
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        if not protectedGeometry(obj) or weaponVisual(obj) then
            saveSet(obj, "Transparency", 1)
        end

        return
    end

    if obj:IsA("BasePart") then
        if protectedGeometry(obj) then return end

        if gunStoreWood(obj) then
            if Detached[obj] == nil then
                local parent = obj.Parent
                local ok = pcall(function()
                    obj.Parent = nil
                end)

                if ok then
                    Detached[obj] = parent
                end
            end

            return
        end

        saveSet(obj, "Material", Enum.Material.Plastic)
        saveSet(obj, "Reflectance", 0)
        saveSet(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            saveSet(obj, "TextureID", "")
            saveSet(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
        end

    elseif obj:IsA("SpecialMesh") then
        if not protectedGeometry(obj) then
            saveSet(obj, "TextureId", "")
        end

    elseif obj:IsA("SurfaceAppearance") then
        if not protectedGeometry(obj) then
            saveSet(obj, "ColorMap", "")
            saveSet(obj, "NormalMap", "")
            saveSet(obj, "MetalnessMap", "")
            saveSet(obj, "RoughnessMap", "")
        end

    elseif obj:IsA("Clouds") then
        saveSet(obj, "Enabled", false)

    elseif obj:IsA("Atmosphere") then
        saveSet(obj, "Density", 0)
        saveSet(obj, "Haze", 0)
        saveSet(obj, "Glare", 0)

    elseif obj:IsA("Sky") then
        for _, prop in ipairs({
            "SkyboxBk", "SkyboxDn", "SkyboxFt",
            "SkyboxLf", "SkyboxRt", "SkyboxUp"
        }) do
            saveSet(obj, prop, "")
        end

        saveSet(obj, "CelestialBodiesShown", false)
        saveSet(obj, "StarCount", 0)
    end
end

for _, prop in ipairs({
    "Brightness", "Ambient", "OutdoorAmbient",
    "ExposureCompensation", "GlobalShadows",
    "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
    "ShadowSoftness"
}) do
    pcall(function()
        OriginalLighting[prop] = Lighting[prop]
    end)
end

local function applyLighting()
    for prop, value in pairs(OriginalLighting) do
        pcall(function()
            Lighting[prop] = value
        end)
    end

    if Enabled then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.ShadowSoftness = 0
        end)
    end

    if Light then
        pcall(function()
            Lighting.Brightness = 1.35
            Lighting.Ambient = Color3.fromRGB(95, 95, 95)
            Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 105)
            Lighting.ExposureCompensation = 0
        end)
    end
end

local function refresh()
    if not EnableButton then return end

    EnableButton.BackgroundColor3 = Enabled
        and Color3.fromRGB(0, 110, 245)
        or Color3.fromRGB(22, 37, 60)

    LightButton.BackgroundColor3 = Light
        and Color3.fromRGB(0, 110, 245)
        or Color3.fromRGB(22, 37, 60)

    Status.Text = Busy and "PROCESSING"
        or Enabled and HighPing and "ACTIVE | HIGH PING"
        or Enabled and "ULTRA POTATO ACTIVE"
        or "READY"

    Status.TextColor3 = Enabled
        and Color3.fromRGB(89, 232, 161)
        or Color3.fromRGB(151, 179, 210)
end

local function scanNow()
    for _, root in ipairs({
        Lighting, PlayerGui, Backpack, Workspace
    }) do
        for _, obj in ipairs(root:GetDescendants()) do
            if not Alive or not Enabled then return end
            pcall(optimize, obj)
        end
    end
end

local function enable()
    if Busy or Enabled or not Alive then return end

    Busy = true
    Enabled = true
    refresh()

    saveSet(Terrain, "WaterWaveSize", 0)
    saveSet(Terrain, "WaterWaveSpeed", 0)
    saveSet(Terrain, "WaterReflectance", 0)
    saveSet(Terrain, "WaterTransparency", 1)

    pcall(function()
        local rendering = settings().Rendering

        if OriginalQuality == nil then
            OriginalQuality = rendering.QualityLevel
        end

        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    applyLighting()
    scanNow()

    Busy = false
    refresh()
end

local function disable()
    if Busy or not Enabled then return end

    Busy = true
    Enabled = false
    refresh()

    for obj, connection in pairs(Guards) do
        pcall(function()
            connection:Disconnect()
        end)
        Guards[obj] = nil
    end

    for obj, parent in pairs(Detached) do
        pcall(function()
            obj.Parent = parent
        end)
        Detached[obj] = nil
    end

    for obj, properties in pairs(Saved) do
        for prop, original in pairs(properties) do
            pcall(function()
                obj[prop] = original[1]
            end)
        end
        Saved[obj] = nil
    end

    if OriginalQuality ~= nil then
        pcall(function()
            settings().Rendering.QualityLevel = OriginalQuality
        end)
        OriginalQuality = nil
    end

    Busy = false
    applyLighting()
    refresh()
end

GUI = Instance.new("ScreenGui")
GUI.Name = "FarhanStore_V23"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(225, 192)
Main.Position = UDim2.new(0, 24, 0.5, -96)
Main.BackgroundColor3 = Color3.fromRGB(7, 12, 23)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = Main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(166, 204, 255)
stroke.Thickness = 1.3
stroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 39)
Header.BackgroundColor3 = Color3.fromRGB(12, 25, 47)
Header.BorderSizePixel = 0
Header.Parent = Main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -48, 0, 30)
Title.Position = UDim2.fromOffset(12, 5)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 19
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Text = '<font color="#FFFFFF">Farhan</font><font color="#168BFF">Store</font>'
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(21, 21)
Minimize.Position = UDim2.new(1, -31, 0, 9)
Minimize.BackgroundColor3 = Color3.fromRGB(0, 108, 232)
Minimize.BorderSizePixel = 0
Minimize.Text = "−"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 16
Minimize.Parent = Header

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(1, 0)
minimizeCorner.Parent = Minimize

local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, -24, 0, 2)
Accent.Position = UDim2.fromOffset(12, 39)
Accent.BackgroundColor3 = Color3.fromRGB(0, 117, 255)
Accent.BorderSizePixel = 0
Accent.Parent = Main

local function makeButton(name, y)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -28, 0, 33)
    button.Position = UDim2.fromOffset(14, y)
    button.BackgroundColor3 = Color3.fromRGB(22, 37, 60)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(245, 249, 255)
    button.TextSize = 15
    button.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = button

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(48, 89, 145)
    s.Thickness = 1
    s.Parent = button

    return button
end

EnableButton = makeButton("Enabled", 51)
LightButton = makeButton("Light", 92)

local Info = Instance.new("Frame")
Info.Size = UDim2.new(1, -28, 0, 27)
Info.Position = UDim2.fromOffset(14, 135)
Info.BackgroundColor3 = Color3.fromRGB(11, 22, 40)
Info.BorderSizePixel = 0
Info.Parent = Main

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 6)
infoCorner.Parent = Info

local function infoLabel(value, position, size, alignment)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = value
    label.TextColor3 = Color3.fromRGB(112, 193, 255)
    label.TextSize = 13
    label.TextXAlignment = alignment
    label.Parent = Info
    return label
end

PingLabel = infoLabel(
    "PING: -- ms",
    UDim2.fromOffset(7, 0),
    UDim2.new(0.57, -7, 1, 0),
    Enum.TextXAlignment.Left
)

FPSLabel = infoLabel(
    "FPS: --",
    UDim2.new(0.57, 0, 0, 0),
    UDim2.new(0.43, -7, 1, 0),
    UDim2.new(0.43, -7, 1, 0) and Enum.TextXAlignment.Right
)

Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 19)
Status.Position = UDim2.fromOffset(10, 167)
Status.BackgroundTransparency = 1
Status.TextSize = 11
Status.TextColor3 = Color3.fromRGB(151, 179, 210)
Status.Parent = Main

connect(EnableButton.MouseButton1Click, function()
    if Busy then return end

    if Enabled then
        disable()
    else
        enable()
    end
end)

connect(LightButton.MouseButton1Click, function()
    if Busy then return end
    Light = not Light
    applyLighting()
    refresh()
end)

connect(Minimize.MouseButton1Click, function()
    Minimized = not Minimized

    EnableButton.Visible = not Minimized
    LightButton.Visible = not Minimized
    Info.Visible = not Minimized
    Status.Visible = not Minimized

    Main.Size = Minimized
        and UDim2.fromOffset(225, 39)
        or UDim2.fromOffset(225, 192)

    Minimize.Text = Minimized and "+" or "−"
end)

connect(UIS.InputBegan, function(input)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        GUI.Enabled = not GUI.Enabled
    end
end)

local Dragging = false
local DragStart
local StartPosition

connect(Header.InputBegan, function(input)
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

connect(game.DescendantAdded, function(obj)
    if not Alive then return end

    if isText(obj) then
        applyFont(obj)
    end

    if not Enabled or Busy then return end

    local valid = false

    pcall(function()
        valid = obj:IsDescendantOf(Workspace)
            or obj:IsDescendantOf(Lighting)
            or obj:IsDescendantOf(PlayerGui)
            or obj:IsDescendantOf(Backpack)
    end)

    if valid then
        pcall(optimize, obj)
    end
end)

local Frames = 0
local LastFPS = os.clock()

connect(RunService.RenderStepped, function()
    Frames += 1

    local now = os.clock()
    local elapsed = now - LastFPS

    if elapsed >= 0.5 then
        FPS = math.floor(Frames / elapsed + 0.5)
        Frames = 0
        LastFPS = now
    end
end)

task.spawn(function()
    while Alive do
        local display = "--"

        pcall(function()
            local item = Stats.Network.ServerStatsItem["Data Ping"]
            local number = tonumber(
                item:GetValueString():match("[%d%.]+")
            )

            if number then
                Ping = math.floor(number + 0.5)
                display = tostring(Ping)
            end
        end)

        local previous = HighPing

        if Ping >= 180 then
            HighPing = true
        elseif Ping > 0 and Ping <= 140 then
            HighPing = false
        end

        if previous ~= HighPing then
            refresh()
        end

        if PingLabel then
            PingLabel.Text = "PING: " .. display .. " ms"
        end

        if FPSLabel then
            FPSLabel.Text = "FPS: " .. FPS
        end

        task.wait(HighPing and 0.25 or 0.1)
    end
end)

local function cleanup()
    if not Alive then return end

    if Enabled then
        disable()
    end

    Alive = false
    Light = false

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    for _, connection in pairs(Guards) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    for obj, original in pairs(FontSaved) do
        pcall(function()
            obj.FontFace = original
        end)
    end

    table.clear(FontSaved)
    applyLighting()

    if GUI then
        GUI:Destroy()
    end
end

ENV.FarhanFPSOnlyCleanup = cleanup

scanFonts(PlayerGui)
pcall(function()
    scanFonts(CoreGui)
end)

refresh()

print("FARHAN STORE")
