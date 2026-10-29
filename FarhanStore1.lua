
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Terrain = Workspace.Terrain
local ENV = getgenv and getgenv() or _G

if type(ENV.FarhanFPSOnlyCleanup) == "function" then
    pcall(ENV.FarhanFPSOnlyCleanup)
end

local Alive = true
local State = "preparing"
local Light = false
local Minimized = false
local Generation = 0

local Saved = {}
local Fonts = {}
local Indexed = {}
local Known = {}
local Connections = {}
local Queue = {}
local QueueHead = 1
local WorkerRunning = false
local QualityOriginal

local GUI, Main, FPSButton, LightButton
local StatusLabel, PingLabel, FPSLabel

local CustomFont
pcall(function()
    CustomFont = Font.fromId(12187372382)
end)

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(Connections, c)
    return c
end

local function font(obj)
    if CustomFont then
        pcall(function()
            obj.FontFace = CustomFont
        end)
    else
        obj.Font = Enum.Font.GothamBold
    end
end

local function saveSet(obj, prop, value)
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

local function isProtected(obj)
    local character = Player.Character

    if character and (
        obj == character
        or obj:IsDescendantOf(character)
    ) then
        return true
    end

    if obj:FindFirstAncestorOfClass("Tool")
        or obj:FindFirstAncestorOfClass("Accessory") then
        return true
    end

    return false
end

local function isGunWood(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.CanCollide or obj.CanTouch then return false end

    local wood = false
    local store = false
    local parent = obj

    while parent and parent ~= Workspace do
        local n = parent.Name:lower()

        if n:find("door", 1, true)
            or n:find("floor", 1, true)
            or n:find("weapon", 1, true) then
            return false
        end

        if n:find("wood", 1, true)
            or n:find("plank", 1, true)
            or n:find("board", 1, true)
            or n:find("kayu", 1, true) then
            wood = true
        end

        if n:find("gunstore", 1, true)
            or n:find("gun store", 1, true)
            or n:find("gunshop", 1, true) then
            store = true
        end

        parent = parent.Parent
    end

    if obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        or obj:FindFirstChildWhichIsA("ClickDetector", true) then
        return false
    end

    return wood and store
end

local function optimize(obj)
    if State ~= "on" or not Alive then return end
    if not obj or not obj.Parent then return end
    if isProtected(obj) then return end

    if obj:IsA("BasePart") then
        saveSet(obj, "Material", Enum.Material.Plastic)
        saveSet(obj, "Reflectance", 0)
        saveSet(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            saveSet(obj, "TextureID", "")
            saveSet(
                obj,
                "RenderFidelity",
                Enum.RenderFidelity.Performance
            )
        end

        if isGunWood(obj) then
            saveSet(obj, "LocalTransparencyModifier", 1)
        end

    elseif obj:IsA("SpecialMesh") then
        saveSet(obj, "TextureId", "")

    elseif obj:IsA("SurfaceAppearance") then
        saveSet(obj, "ColorMap", "")
        saveSet(obj, "NormalMap", "")
        saveSet(obj, "MetalnessMap", "")
        saveSet(obj, "RoughnessMap", "")

    elseif obj:IsA("Decal")
        or obj:IsA("Texture") then
        saveSet(obj, "Transparency", 1)

    elseif obj:IsA("ParticleEmitter") then
        saveSet(obj, "Enabled", false)
        saveSet(obj, "Rate", 0)
        pcall(function() obj:Clear() end)

    elseif obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles") then
        saveSet(obj, "Enabled", false)

    elseif obj:IsA("PostEffect")
        or obj:IsA("Highlight")
        or obj:IsA("Clouds") then
        saveSet(obj, "Enabled", false)

    elseif obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
        saveSet(obj, "Shadows", false)

    elseif obj:IsA("Atmosphere") then
        saveSet(obj, "Density", 0)
        saveSet(obj, "Haze", 0)
        saveSet(obj, "Glare", 0)

    elseif obj:IsA("Sky") then
        for _, property in ipairs({
            "SkyboxBk", "SkyboxDn", "SkyboxFt",
            "SkyboxLf", "SkyboxRt", "SkyboxUp"
        }) do
            saveSet(obj, property, "")
        end

        saveSet(obj, "CelestialBodiesShown", false)
        saveSet(obj, "StarCount", 0)
    end
end

local LightingOriginal = {}

for _, prop in ipairs({
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
        LightingOriginal[prop] = Lighting[prop]
    end)
end

local function applyLighting()
    for prop, value in pairs(LightingOriginal) do
        pcall(function()
            Lighting[prop] = value
        end)
    end

    if State == "on" then
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
    if not FPSButton then return end

    FPSButton.Text = "Enabled"
    FPSButton.BackgroundColor3 = State == "on"
        and Color3.fromRGB(12, 107, 230)
        or Color3.fromRGB(23, 36, 58)

    LightButton.BackgroundColor3 = Light
        and Color3.fromRGB(12, 107, 230)
        or Color3.fromRGB(23, 36, 58)

    local labels = {
        preparing = "● PREPARING",
        ready = "● READY",
        on = "● POTATO ACTIVE",
        restoring = "● RESTORING"
    }

    StatusLabel.Text = labels[State] or "● READY"

    StatusLabel.TextColor3 = State == "on"
        and Color3.fromRGB(88, 220, 145)
        or Color3.fromRGB(150, 175, 205)
end

local function enqueue(obj)
    if not Alive or State ~= "on" then return end
    if not obj or not obj.Parent then return end

    Queue[#Queue + 1] = obj
end

local function processQueue()
    if WorkerRunning then return end
    WorkerRunning = true

    task.spawn(function()
        while Alive do
            if State ~= "on" then
                break
            end

            local start = os.clock()

            while QueueHead <= #Queue do
                if State ~= "on" then break end

                local obj = Queue[QueueHead]
                Queue[QueueHead] = false
                QueueHead += 1

                pcall(optimize, obj)

                if os.clock() - start >= 0.003 then
                    break
                end
            end

            if QueueHead > #Queue then
                Queue = {}
                QueueHead = 1
                break
            end

            RunService.Heartbeat:Wait()
        end

        WorkerRunning = false
    end)
end

local function indexObject(obj)
    if Known[obj] then return end
    Known[obj] = true

    Indexed[#Indexed + 1] = obj
end

local function enable()
    if State ~= "ready" then return end

    State = "on"
    Generation += 1

    saveSet(Terrain, "WaterWaveSize", 0)
    saveSet(Terrain, "WaterWaveSpeed", 0)
    saveSet(Terrain, "WaterReflectance", 0)
    saveSet(Terrain, "WaterTransparency", 1)

    pcall(function()
        saveSet(Terrain, "Decoration", false)
    end)

    pcall(function()
        local rendering = settings().Rendering
        QualityOriginal = rendering.QualityLevel
        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    applyLighting()
    refresh()

    Queue = {}
    QueueHead = 1

    -- Prioritas pertama: objek dekat kamera.
    local camera = Workspace.CurrentCamera
    local position = camera and camera.CFrame.Position

    if position then
        for _, obj in ipairs(Indexed) do
            if obj:IsA("BasePart")
                and obj.Parent
                and (obj.Position - position).Magnitude <= 125 then
                enqueue(obj)
            end
        end
    end

    -- Lanjutkan semua objek yang sudah terindeks.
    for _, obj in ipairs(Indexed) do
        if obj.Parent then
            enqueue(obj)
        end
    end

    processQueue()
end

local function disable()
    if State ~= "on" then return end

    State = "restoring"
    Generation += 1
    Queue = {}
    QueueHead = 1
    refresh()

    task.spawn(function()
        while WorkerRunning do
            RunService.Heartbeat:Wait()
        end

        local start = os.clock()

        for obj, properties in pairs(Saved) do
            for prop, value in pairs(properties) do
                pcall(function()
                    obj[prop] = value
                end)
            end

            Saved[obj] = nil

            if os.clock() - start >= 0.003 then
                RunService.Heartbeat:Wait()
                start = os.clock()
            end
        end

        if QualityOriginal ~= nil then
            pcall(function()
                settings().Rendering.QualityLevel = QualityOriginal
            end)

            QualityOriginal = nil
        end

        State = "ready"
        applyLighting()
        refresh()
    end)
end

local function applyGameFont(obj)
    if not Alive or not CustomFont then return end

    if not (
        obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox")
    ) then return end

    if GUI and obj:IsDescendantOf(GUI) then return end

    if Fonts[obj] == nil then
        pcall(function()
            Fonts[obj] = obj.FontFace
        end)
    end

    pcall(function()
        obj.FontFace = CustomFont
    end)
end

GUI = Instance.new("ScreenGui")
GUI.Name = "FarhanStore_V17"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(218, 185)
Main.Position = UDim2.new(0, 25, 0.5, -92)
Main.BackgroundColor3 = Color3.fromRGB(8, 11, 20)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 11)
corner.Parent = Main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(210, 225, 245)
stroke.Thickness = 1.2
stroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(12, 20, 35)
Header.BorderSizePixel = 0
Header.Parent = Main

local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 11)
hc.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -45, 0, 30)
Title.Position = UDim2.fromOffset(12, 4)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = '<font color="#FFFFFF">Farhan</font><font color="#168BFF">Store</font>'
Title.TextSize = 19
font(Title)
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(21, 21)
Minimize.Position = UDim2.new(1, -30, 0, 8)
Minimize.BackgroundColor3 = Color3.fromRGB(15, 108, 225)
Minimize.BorderSizePixel = 0
Minimize.Text = "−"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 16
font(Minimize)
Minimize.Parent = Header

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(1, 0)
mc.Parent = Minimize

for i = 1, 13 do
    local star = Instance.new("Frame")
    star.Size = UDim2.fromOffset(1, 1)
    star.Position = UDim2.new(
        ((i * 37) % 100) / 100, 0,
        ((i * 23) % 100) / 100, 0
    )
    star.BackgroundColor3 = Color3.fromRGB(195, 220, 255)
    star.BackgroundTransparency = (i % 3) * 0.2
    star.BorderSizePixel = 0
    star.Parent = Main
end

local function makeButton(name, y)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -28, 0, 32)
    b.Position = UDim2.fromOffset(14, y)
    b.BackgroundColor3 = Color3.fromRGB(23, 36, 58)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(245, 248, 255)
    b.TextSize = 15
    b.Text = name
    font(b)
    b.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(47, 81, 130)
    s.Thickness = 1
    s.Parent = b

    return b
end

FPSButton = makeButton("Enabled", 49)
LightButton = makeButton("Light", 88)

local Info = Instance.new("Frame")
Info.Size = UDim2.new(1, -28, 0, 25)
Info.Position = UDim2.fromOffset(14, 128)
Info.BackgroundColor3 = Color3.fromRGB(13, 22, 38)
Info.BorderSizePixel = 0
Info.Parent = Main

local ic = Instance.new("UICorner")
ic.CornerRadius = UDim.new(0, 5)
ic.Parent = Info

PingLabel = Instance.new("TextLabel")
PingLabel.Size = UDim2.new(0.55, 0, 1, 0)
PingLabel.Position = UDim2.fromOffset(7, 0)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "PING: -- ms"
PingLabel.TextXAlignment = Enum.TextXAlignment.Left
PingLabel.TextColor3 = Color3.fromRGB(105, 190, 255)
PingLabel.TextSize = 13
font(PingLabel)
PingLabel.Parent = Info

FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0.4, -7, 1, 0)
FPSLabel.Position = UDim2.new(0.6, 0, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: --"
FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
FPSLabel.TextColor3 = Color3.fromRGB(105, 190, 255)
FPSLabel.TextSize = 13
font(FPSLabel)
FPSLabel.Parent = Info

StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.fromOffset(10, 158)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextSize = 11
font(StatusLabel)
StatusLabel.Parent = Main

connect(FPSButton.MouseButton1Click, function()
    if State == "ready" then
        enable()
    elseif State == "on" then
        disable()
    end
end)

connect(LightButton.MouseButton1Click, function()
    Light = not Light

    if State ~= "restoring" then
        applyLighting()
    end

    refresh()
end)

connect(Minimize.MouseButton1Click, function()
    Minimized = not Minimized

    FPSButton.Visible = not Minimized
    LightButton.Visible = not Minimized
    Info.Visible = not Minimized
    StatusLabel.Visible = not Minimized

    Main.Size = Minimized
        and UDim2.fromOffset(218, 38)
        or UDim2.fromOffset(218, 185)

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
    if Dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
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

    applyGameFont(obj)

    if obj:IsDescendantOf(Workspace)
        or obj:IsDescendantOf(Lighting) then

        indexObject(obj)

        if State == "on" then
            enqueue(obj)
            processQueue()
        end
    end
end)

-- Saat respawn, boost tidak dimatikan.
-- Streaming objek baru tetap ditangani DescendantAdded.
connect(Player.CharacterAdded, function()
    if State ~= "on" then return end

    local generation = Generation

    task.delay(0.15, function()
        if not Alive
            or State ~= "on"
            or generation ~= Generation then
            return
        end

        -- Prioritaskan objek dekat lokasi spawn.
        local character = Player.Character
        local root = character
            and character:FindFirstChild("HumanoidRootPart")

        if not root then return end

        for _, obj in ipairs(Indexed) do
            if obj:IsA("BasePart")
                and obj.Parent
                and not isProtected(obj)
                and (obj.Position - root.Position).Magnitude <= 110 then
                enqueue(obj)
            end
        end

        processQueue()
    end)
end)

local frames = 0
local currentFPS = 0
local lastFPS = os.clock()

connect(RunService.RenderStepped, function()
    frames += 1

    local now = os.clock()
    local elapsed = now - lastFPS

    if elapsed >= 0.5 then
        currentFPS = math.floor(frames / elapsed + 0.5)
        frames = 0
        lastFPS = now
    end
end)

task.spawn(function()
    while Alive do
        local ping = "--"

        pcall(function()
            local value = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            local number = tonumber(value:match("[%d%.]+"))

            if number then
                ping = tostring(math.floor(number + 0.5))
            end
        end)

        PingLabel.Text = "PING: " .. ping .. " ms"
        FPSLabel.Text = "FPS: " .. currentFPS

        task.wait(0.1)
    end
end)

-- PRE-SCAN: berjalan sebelum Enabled.
task.spawn(function()
    local start = os.clock()

    for _, root in ipairs({Workspace, Lighting}) do
        indexObject(root)

        for _, obj in ipairs(root:GetDescendants()) do
            if not Alive then return end

            indexObject(obj)

            if os.clock() - start >= 0.003 then
                RunService.Heartbeat:Wait()
                start = os.clock()
            end
        end
    end

    if Alive and State == "preparing" then
        State = "ready"
        refresh()
    end
end)

task.spawn(function()
    local start = os.clock()

    for _, obj in ipairs(game:GetDescendants()) do
        if not Alive then return end

        applyGameFont(obj)

        if os.clock() - start >= 0.003 then
            RunService.Heartbeat:Wait()
            start = os.clock()
        end
    end
end)

local function cleanup()
    if not Alive then return end

    if State == "on" then
        disable()
    end

    while State == "restoring" do
        RunService.Heartbeat:Wait()
    end

    Alive = false
    Light = false
    applyLighting()

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    for obj, original in pairs(Fonts) do
        pcall(function()
            obj.FontFace = original
        end)
    end

    table.clear(Connections)
    table.clear(Fonts)
    table.clear(Indexed)
    table.clear(Known)

    GUI:Destroy()
end

ENV.FarhanFPSOnlyCleanup = cleanup

refresh()
print("FARHAN STORE | V1.7")
