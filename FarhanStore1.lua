
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

local CONFIG = {
    FontID = 12187372382,
    FrameBudget = 0.0025,
    PriorityDistance = 140,
    RemoveGunStoreWood = true,
    HighPing = 180,
    NetworkSafeMode = true
}

local Alive = true
local State = "preparing"
local Light = false
local Minimized = false
local Generation = 0

local Saved = {}
local Detached = {}
local Indexed = {}
local Known = {}
local Connections = {}

local Queue = {}
local Head = 1
local Queued = {}
local WorkerRunning = false

local QualityOriginal
local OriginalLighting = {}
local PingValue = 0
local CurrentFPS = 0

local GUI, Main
local FPSButton, LightButton
local PingLabel, FPSLabel, StatusLabel

local CustomFont

pcall(function()
    CustomFont = Font.fromId(CONFIG.FontID)
end)

local function connect(signal, callback)
    local c = signal:Connect(callback)
    Connections[#Connections + 1] = c
    return c
end

local function setFont(obj)
    if CustomFont then
        local ok = pcall(function()
            obj.FontFace = CustomFont
        end)

        if ok then return end
    end

    obj.Font = Enum.Font.GothamBold
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
    if not obj then return true end

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

local function gunStoreWood(obj)
    if not CONFIG.RemoveGunStoreWood then return false end
    if not obj:IsA("BasePart") then return false end

    if not obj.Anchored then return false end
    if obj.CanCollide or obj.CanTouch or obj.CanQuery then
        return false
    end

    local wood = false
    local store = false
    local current = obj

    while current and current ~= Workspace do
        local n = current.Name:lower()

        if n:find("door", 1, true)
            or n:find("floor", 1, true)
            or n:find("weapon", 1, true)
            or n:find("counter", 1, true)
            or n:find("register", 1, true)
            or n:find("handle", 1, true) then
            return false
        end

        if n:find("wood", 1, true)
            or n:find("plank", 1, true)
            or n:find("board", 1, true)
            or n:find("timber", 1, true)
            or n:find("kayu", 1, true) then
            wood = true
        end

        if n:find("gunstore", 1, true)
            or n:find("gun store", 1, true)
            or n:find("gunshop", 1, true)
            or n:find("gun_shop", 1, true) then
            store = true
        end

        current = current.Parent
    end

    if obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        or obj:FindFirstChildWhichIsA("ClickDetector", true) then
        return false
    end

    return wood and store
end

local function optimize(obj)
    if not Alive or State ~= "on" then return end
    if not obj or not obj.Parent then return end
    if isProtected(obj) then return end

    if obj:IsA("BasePart") then
        if gunStoreWood(obj) then
            if Detached[obj] == nil then
                Detached[obj] = obj.Parent

                pcall(function()
                    obj.Parent = nil
                end)
            end

            return
        end

        saveSet(obj, "Material", Enum.Material.Plastic)
        saveSet(obj, "Reflectance", 0)
        saveSet(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            saveSet(obj, "TextureID", "")

            pcall(function()
                saveSet(
                    obj,
                    "RenderFidelity",
                    Enum.RenderFidelity.Performance
                )
            end)
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

        pcall(function()
            obj:Clear()
        end)

    elseif obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles") then

        saveSet(obj, "Enabled", false)

    elseif obj:IsA("Highlight")
        or obj:IsA("PostEffect")
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
        for _, prop in ipairs({
            "SkyboxBk",
            "SkyboxDn",
            "SkyboxFt",
            "SkyboxLf",
            "SkyboxRt",
            "SkyboxUp"
        }) do
            saveSet(obj, prop, "")
        end

        saveSet(obj, "CelestialBodiesShown", false)
        saveSet(obj, "StarCount", 0)
    end
end

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
        OriginalLighting[prop] = Lighting[prop]
    end)
end

local function applyLighting()
    for prop, original in pairs(OriginalLighting) do
        pcall(function()
            Lighting[prop] = original
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

local function index(obj)
    if not obj or Known[obj] then return end

    Known[obj] = true
    Indexed[#Indexed + 1] = obj
end

local function enqueue(obj)
    if not obj or not obj.Parent then return end
    if Queued[obj] then return end

    Queued[obj] = true
    Queue[#Queue + 1] = obj
end

local function resetQueue()
    Queue = {}
    Head = 1
    Queued = {}
end

local function refresh()
    if not FPSButton then return end

    FPSButton.Text = "Enabled"

    FPSButton.BackgroundColor3 = State == "on"
        and Color3.fromRGB(0, 107, 239)
        or Color3.fromRGB(20, 35, 58)

    LightButton.BackgroundColor3 = Light
        and Color3.fromRGB(0, 107, 239)
        or Color3.fromRGB(20, 35, 58)

    local status = {
        preparing = "PREPARING",
        ready = "READY",
        on = "ULTRA POTATO ACTIVE",
        restoring = "RESTORING"
    }

    StatusLabel.Text = status[State] or "READY"

    StatusLabel.TextColor3 = State == "on"
        and Color3.fromRGB(88, 230, 156)
        or Color3.fromRGB(153, 175, 205)
end

local function processQueue()
    if WorkerRunning then return end
    if State ~= "on" then return end

    WorkerRunning = true
    local token = Generation

    task.spawn(function()
        while Alive and State == "on" and token == Generation do
            local started = os.clock()

            local budget = PingValue >= CONFIG.HighPing
                and 0.0015
                or CONFIG.FrameBudget

            while Head <= #Queue do
                if State ~= "on" or token ~= Generation then
                    break
                end

                local obj = Queue[Head]
                Queue[Head] = false
                Head += 1

                if obj then
                    Queued[obj] = nil
                    pcall(optimize, obj)
                end

                if os.clock() - started >= budget then
                    break
                end
            end

            if Head > #Queue then
                resetQueue()
                break
            end

            RunService.Heartbeat:Wait()
        end

        WorkerRunning = false

        if Alive and State == "on" and Head <= #Queue then
            task.defer(processQueue)
        end
    end)
end

local function enable()
    if State ~= "ready" or not Alive then return end

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

        if QualityOriginal == nil then
            QualityOriginal = rendering.QualityLevel
        end

        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    applyLighting()
    refresh()
    resetQueue()

    local camera = Workspace.CurrentCamera
    local cameraPosition = camera and camera.CFrame.Position

    if cameraPosition then
        for _, obj in ipairs(Indexed) do
            if obj.Parent
                and obj:IsA("BasePart")
                and (obj.Position - cameraPosition).Magnitude
                    <= CONFIG.PriorityDistance then

                enqueue(obj)

                for _, child in ipairs(obj:GetChildren()) do
                    enqueue(child)
                end
            end
        end
    end

    for _, obj in ipairs(Indexed) do
        enqueue(obj)
    end

    processQueue()
end

local function disable()
    if State ~= "on" then return end

    State = "restoring"
    Generation += 1
    refresh()

    task.spawn(function()
        while WorkerRunning do
            RunService.Heartbeat:Wait()
        end

        resetQueue()

        local started = os.clock()

        for obj, originalParent in pairs(Detached) do
            pcall(function()
                obj.Parent = originalParent
            end)

            Detached[obj] = nil

            if os.clock() - started >= CONFIG.FrameBudget then
                RunService.Heartbeat:Wait()
                started = os.clock()
            end
        end

        for obj, properties in pairs(Saved) do
            for prop, original in pairs(properties) do
                pcall(function()
                    obj[prop] = original
                end)
            end

            Saved[obj] = nil

            if os.clock() - started >= CONFIG.FrameBudget then
                RunService.Heartbeat:Wait()
                started = os.clock()
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

GUI = Instance.new("ScreenGui")
GUI.Name = "FarhanStore_UltraPotato_V18"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(225, 192)
Main.Position = UDim2.new(0, 24, 0.5, -96)
Main.BackgroundColor3 = Color3.fromRGB(7, 11, 21)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = Main

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(165, 202, 255)
outline.Thickness = 1.3
outline.Transparency = 0.12
outline.Parent = Main

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(
        0,
        Color3.fromRGB(13, 23, 43)
    ),
    ColorSequenceKeypoint.new(
        1,
        Color3.fromRGB(5, 8, 17)
    )
})
gradient.Rotation = 90
gradient.Parent = Main

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 39)
Header.BackgroundColor3 = Color3.fromRGB(12, 24, 45)
Header.BorderSizePixel = 0
Header.Parent = Main

local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 12)
hc.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -48, 0, 30)
Title.Position = UDim2.fromOffset(12, 5)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 19
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Text =
    '<font color="#FFFFFF">Farhan</font>' ..
    '<font color="#168BFF">Store</font>'
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

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(1, 0)
mc.Parent = Minimize

local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, -24, 0, 2)
Accent.Position = UDim2.fromOffset(12, 39)
Accent.BackgroundColor3 = Color3.fromRGB(0, 117, 255)
Accent.BorderSizePixel = 0
Accent.Parent = Main

local function makeButton(name, y)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -28, 0, 33)
    b.Position = UDim2.fromOffset(14, y)
    b.BackgroundColor3 = Color3.fromRGB(20, 35, 58)
    b.BorderSizePixel = 0
    b.Text = name
    b.TextColor3 = Color3.fromRGB(245, 249, 255)
    b.TextSize = 15
    setFont(b)
    b.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(48, 89, 145)
    s.Thickness = 1
    s.Parent = b

    return b
end

FPSButton = makeButton("Enabled", 51)
LightButton = makeButton("Light", 92)

local Info = Instance.new("Frame")
Info.Size = UDim2.new(1, -28, 0, 27)
Info.Position = UDim2.fromOffset(14, 135)
Info.BackgroundColor3 = Color3.fromRGB(11, 22, 40)
Info.BorderSizePixel = 0
Info.Parent = Main

local ic = Instance.new("UICorner")
ic.CornerRadius = UDim.new(0, 6)
ic.Parent = Info

local function infoLabel(text, position, size, align)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = position
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(112, 193, 255)
    l.TextSize = 13
    l.TextXAlignment = align
    setFont(l)
    l.Parent = Info
    return l
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

StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 19)
StatusLabel.Position = UDim2.fromOffset(10, 167)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextSize = 11
StatusLabel.TextColor3 = Color3.fromRGB(150, 175, 205)
setFont(StatusLabel)
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

    if obj:IsDescendantOf(Workspace)
        or obj:IsDescendantOf(Lighting) then

        index(obj)

        if State == "on" then
            enqueue(obj)
            processQueue()
        end
    end
end)

connect(Player.CharacterAdded, function()
    if State ~= "on" then return end

    local token = Generation

    task.delay(0.1, function()
        if not Alive or State ~= "on" or token ~= Generation then
            return
        end

        local character = Player.Character
        local root = character
            and character:FindFirstChild("HumanoidRootPart")

        if not root then return end

        for _, obj in ipairs(Indexed) do
            if obj:IsA("BasePart")
                and obj.Parent
                and not isProtected(obj)
                and (obj.Position - root.Position).Magnitude <= 120 then

                enqueue(obj)
            end
        end

        processQueue()
    end)
end)

local Frames = 0
local LastFPS = os.clock()

connect(RunService.RenderStepped, function()
    Frames += 1

    local now = os.clock()
    local elapsed = now - LastFPS

    if elapsed >= 0.5 then
        CurrentFPS = math.floor(Frames / elapsed + 0.5)
        Frames = 0
        LastFPS = now
    end
end)

task.spawn(function()
    while Alive do
        local pingText = "--"

        pcall(function()
            local item = Stats.Network.ServerStatsItem["Data Ping"]
            local value = item:GetValueString()
            local number = tonumber(value:match("[%d%.]+"))

            if number then
                PingValue = math.floor(number + 0.5)
                pingText = tostring(PingValue)
            end
        end)

        if PingLabel then
            PingLabel.Text = "PING: " .. pingText .. " ms"
        end

        if FPSLabel then
            FPSLabel.Text = "FPS: " .. CurrentFPS
        end

        task.wait(0.1)
    end
end)

task.spawn(function()
    local started = os.clock()

    for _, root in ipairs({Workspace, Lighting}) do
        if not Alive then return end

        index(root)

        for _, obj in ipairs(root:GetDescendants()) do
            if not Alive then return end

            index(obj)

            if os.clock() - started >= CONFIG.FrameBudget then
                RunService.Heartbeat:Wait()
                started = os.clock()
            end
        end
    end

    if Alive and State == "preparing" then
        State = "ready"
        refresh()
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
    Generation += 1

    applyLighting()

    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    table.clear(Connections)
    table.clear(Indexed)
    table.clear(Known)

    if GUI then
        GUI:Destroy()
    end
end

ENV.FarhanFPSOnlyCleanup = cleanup

refresh()

print("FARHAN STORE")
