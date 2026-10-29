
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

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
local Version = 0

local Saved = {}
local Indexed = {}
local Known = {}
local Connections = {}
local Guards = {}
local Queue = {}
local Queued = {}
local Head = 1
local Running = false
local OriginalLighting = {}
local OriginalQuality
local Ping = 0
local FPS = 0

local GUI
local Main
local EnableButton
local LightButton
local Status
local PingLabel
local FPSLabel
local Font

pcall(function()
    Font = Font.fromId(12187372382)
end)

local function connect(signal, fn)
    local c = signal:Connect(fn)
    Connections[#Connections + 1] = c
    return c
end

local function setFont(obj)
    if Font then
        local ok = pcall(function()
            obj.FontFace = Font
        end)
        if ok then return end
    end
    obj.Font = Enum.Font.GothamBold
end

local function saveSet(obj, property, value)
    if not obj then return end

    local ok, original = pcall(function()
        return obj[property]
    end)

    if not ok then return end

    if not Saved[obj] then
        Saved[obj] = {}
    end

    if not Saved[obj][property] then
        Saved[obj][property] = {original}
    end

    pcall(function()
        obj[property] = value
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

local function isWeaponEffect(obj)
    local current = obj

    while current and current ~= game do
        local name = current.Name:lower()

        if name:find("muzzle", 1, true)
            or name:find("flash", 1, true)
            or name:find("gunfire", 1, true)
            or name:find("shoot", 1, true)
            or name:find("smoke", 1, true)
            or name:find("recoilblur", 1, true)
            or name:find("shootblur", 1, true) then
            return true
        end

        current = current.Parent
    end

    return false
end

local function guard(obj)
    if Guards[obj] or not Alive then return end

    local ok, c = pcall(function()
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
        Guards[obj] = c
    end
end

local function optimizeEffect(obj)
    if not Enabled or not obj.Parent then return end

    if isEffect(obj) then
        saveSet(obj, "Enabled", false)

        if obj:IsA("ParticleEmitter") then
            saveSet(obj, "Rate", 0)
            pcall(function()
                obj:Clear()
            end)
        end

        guard(obj)
        return true
    end

    if obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then

        if isWeaponEffect(obj) then
            saveSet(obj, "Enabled", false)
            guard(obj)
        else
            saveSet(obj, "Shadows", false)
        end

        return true
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        if isWeaponEffect(obj) then
            saveSet(obj, "Transparency", 1)
            return true
        end
    end

    return false
end

local function protectedGeometry(obj)
    local character = Player.Character

    if character and obj:IsDescendantOf(character) then
        return true
    end

    if obj:FindFirstAncestorOfClass("Tool")
        or obj:FindFirstAncestorOfClass("Accessory") then
        return true
    end

    return false
end

local function optimize(obj)
    if not Alive or not Enabled or not obj.Parent then return end

    if optimizeEffect(obj) then return end

    if obj:IsA("BasePart") then
        if protectedGeometry(obj) then return end

        saveSet(obj, "Material", Enum.Material.Plastic)
        saveSet(obj, "Reflectance", 0)
        saveSet(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            saveSet(obj, "TextureID", "")
            saveSet(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
        end

    elseif obj:IsA("SpecialMesh") then
        if protectedGeometry(obj) then return end
        saveSet(obj, "TextureId", "")

    elseif obj:IsA("SurfaceAppearance") then
        if protectedGeometry(obj) then return end
        saveSet(obj, "ColorMap", "")
        saveSet(obj, "NormalMap", "")
        saveSet(obj, "MetalnessMap", "")
        saveSet(obj, "RoughnessMap", "")

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if protectedGeometry(obj) then return end
        saveSet(obj, "Transparency", 1)

    elseif obj:IsA("Clouds") then
        saveSet(obj, "Enabled", false)

    elseif obj:IsA("Atmosphere") then
        saveSet(obj, "Density", 0)
        saveSet(obj, "Haze", 0)
        saveSet(obj, "Glare", 0)

    elseif obj:IsA("Sky") then
        for _, property in ipairs({
            "SkyboxBk",
            "SkyboxDn",
            "SkyboxFt",
            "SkyboxLf",
            "SkyboxRt",
            "SkyboxUp"
        }) do
            saveSet(obj, property, "")
        end

        saveSet(obj, "CelestialBodiesShown", false)
        saveSet(obj, "StarCount", 0)
    end
end

for _, property in ipairs({
    "Brightness",
    "Ambient",
    "OutdoorAmbient",
    "ExposureCompensation",
    "GlobalShadows",
    "EnvironmentDiffuseScale",
    "EnvironmentSpecularScale",
    "ShadowSoftness"
}) do
    pcall(function()
        OriginalLighting[property] = Lighting[property]
    end)
end

local function applyLighting()
    for property, value in pairs(OriginalLighting) do
        pcall(function()
            Lighting[property] = value
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

local function index(obj)
    if Known[obj] then return end
    Known[obj] = true
    Indexed[#Indexed + 1] = obj
end

local function enqueue(obj)
    if not obj or not obj.Parent or Queued[obj] then return end
    Queued[obj] = true
    Queue[#Queue + 1] = obj
end

local function clearQueue()
    Queue = {}
    Queued = {}
    Head = 1
end

local function refresh()
    if not EnableButton then return end

    EnableButton.BackgroundColor3 = Enabled
        and Color3.fromRGB(0, 110, 245)
        or Color3.fromRGB(22, 37, 60)

    LightButton.BackgroundColor3 = Light
        and Color3.fromRGB(0, 110, 245)
        or Color3.fromRGB(22, 37, 60)

    Status.Text = Busy and "RESTORING"
        or Enabled and "ULTRA POTATO ACTIVE"
        or "READY"

    Status.TextColor3 = Enabled
        and Color3.fromRGB(89, 232, 161)
        or Color3.fromRGB(151, 179, 210)
end

local function worker()
    if Running or not Enabled then return end

    Running = true
    local token = Version

    task.spawn(function()
        while Alive and Enabled and token == Version do
            local start = os.clock()
            local budget = Ping >= 180 and 0.001 or 0.0025

            while Head <= #Queue do
                if not Enabled or token ~= Version then break end

                local obj = Queue[Head]
                Queue[Head] = false
                Head += 1

                if obj then
                    Queued[obj] = nil
                    pcall(optimize, obj)
                end

                if os.clock() - start >= budget then
                    break
                end
            end

            if Head > #Queue then
                clearQueue()
                break
            end

            RunService.Heartbeat:Wait()
        end

        Running = false

        if Alive and Enabled and Head <= #Queue then
            task.defer(worker)
        end
    end)
end

local function enable()
    if Busy or Enabled or not Alive then return end

    Enabled = true
    Version += 1
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

    local camera = Workspace.CurrentCamera
    local position = camera and camera.CFrame.Position

    clearQueue()

    local priority = {}
    local remaining = {}

    for _, obj in ipairs(Indexed) do
        if obj.Parent then
            if isEffect(obj) or isWeaponEffect(obj) then
                priority[#priority + 1] = obj

            elseif position and obj:IsA("BasePart")
                and (obj.Position - position).Magnitude <= 110 then

                priority[#priority + 1] = obj

                for _, child in ipairs(obj:GetChildren()) do
                    priority[#priority + 1] = child
                end
            else
                remaining[#remaining + 1] = obj
            end
        end
    end

    local start = os.clock()

    for _, obj in ipairs(priority) do
        pcall(optimize, obj)

        if os.clock() - start >= 0.008 then
            RunService.Heartbeat:Wait()
            start = os.clock()
        end
    end

    for _, obj in ipairs(remaining) do
        enqueue(obj)
    end

    worker()
end

local function disable()
    if Busy or not Enabled then return end

    Busy = true
    Enabled = false
    Version += 1
    refresh()

    task.spawn(function()
        while Running do
            RunService.Heartbeat:Wait()
        end

        clearQueue()

        for obj, connection in pairs(Guards) do
            pcall(function()
                connection:Disconnect()
            end)
            Guards[obj] = nil
        end

        local start = os.clock()

        for obj, properties in pairs(Saved) do
            for property, original in pairs(properties) do
                pcall(function()
                    obj[property] = original[1]
                end)
            end

            Saved[obj] = nil

            if os.clock() - start >= 0.0025 then
                RunService.Heartbeat:Wait()
                start = os.clock()
            end
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
    end)
end

GUI = Instance.new("ScreenGui")
GUI.Name = "FarhanStore_V20"
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
setFont(Title)
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(21, 21)
Minimize.Position = UDim2.new(1, -31, 0, 9)
Minimize.BackgroundColor3 = Color3.fromRGB(0, 108, 232)
Minimize.BorderSizePixel = 0
Minimize.Text = "−"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 16
setFont(Minimize)
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
    setFont(button)
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
    setFont(label)
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
    Enum.TextXAlignment.Right
)

Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 19)
Status.Position = UDim2.fromOffset(10, 167)
Status.BackgroundTransparency = 1
Status.TextSize = 11
Status.TextColor3 = Color3.fromRGB(151, 179, 210)
setFont(Status)
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

local Minimized = false

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

    local valid = false

    pcall(function()
        valid = obj:IsDescendantOf(Workspace)
            or obj:IsDescendantOf(Lighting)
            or obj:IsDescendantOf(PlayerGui)
            or obj:IsDescendantOf(Backpack)
    end)

    if not valid then return end

    index(obj)

    if Enabled then
        if isEffect(obj) or isWeaponEffect(obj) then
            pcall(optimize, obj)
        else
            enqueue(obj)
            worker()
        end
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
        local value = "--"

        pcall(function()
            local item = Stats.Network.ServerStatsItem["Data Ping"]
            local number = tonumber(item:GetValueString():match("[%d%.]+"))

            if number then
                Ping = math.floor(number + 0.5)
                value = tostring(Ping)
            end
        end)

        PingLabel.Text = "PING: " .. value .. " ms"
        FPSLabel.Text = "FPS: " .. FPS

        task.wait(0.1)
    end
end)

task.spawn(function()
    local start = os.clock()

    for _, root in ipairs({
        Workspace,
        Lighting,
        PlayerGui,
        Backpack
    }) do
        if not Alive then return end

        index(root)

        for _, obj in ipairs(root:GetDescendants()) do
            if not Alive then return end

            index(obj)

            if Enabled then
                enqueue(obj)
            end

            if os.clock() - start >= 0.0025 then
                RunService.Heartbeat:Wait()
                start = os.clock()
            end
        end
    end

    if Enabled then
        worker()
    end
end)

local function cleanup()
    if not Alive then return end

    if Enabled then
        disable()
    end

    while Busy do
        RunService.Heartbeat:Wait()
    end

    Alive = false
    Light = false
    Version += 1

    applyLighting()

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

    if GUI then
        GUI:Destroy()
    end
end

ENV.FarhanFPSOnlyCleanup = cleanup

refresh()

print("FARHAN STORE | V2.0")
