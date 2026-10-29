
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
local Enabled = false
local Minimized = false
local Generation = 0

local Connections = {}
local Saved = {}
local QualitySaved

local Queue = {}
local QueueHead = 1
local Queued = setmetatable({}, {__mode = "k"})

local BATCH_SIZE = 30
local BATCH_WAIT = 0.035

local GUI, Main, Toggle, PingLabel

local function connect(signal, callback)
    local c = signal:Connect(callback)
    Connections[#Connections + 1] = c
    return c
end

local function change(obj, prop, value)
    if not obj then return end

    local ok, original = pcall(function()
        return obj[prop]
    end)

    if not ok then return end

    local record = Saved[obj]

    if not record then
        record = {}
        Saved[obj] = record
    end

    if record[prop] == nil then
        record[prop] = original
    end

    pcall(function()
        obj[prop] = value
    end)
end

local function restore()
    for obj, properties in pairs(Saved) do
        for prop, original in pairs(properties) do
            pcall(function()
                obj[prop] = original
            end)
        end
    end

    table.clear(Saved)

    if QualitySaved ~= nil then
        pcall(function()
            settings().Rendering.QualityLevel = QualitySaved
        end)

        QualitySaved = nil
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

local function importantObject(obj)
    local current = obj

    while current and current ~= Workspace do
        local name = string.lower(current.Name)

        if name:find("door", 1, true)
            or name:find("floor", 1, true)
            or name:find("ground", 1, true)
            or name:find("wall", 1, true)
            or name:find("stairs", 1, true)
            or name:find("seat", 1, true)
            or name:find("vehicle", 1, true)
            or name:find("gun", 1, true)
            or name:find("weapon", 1, true)
            or name:find("shop", 1, true) then

            return true
        end

        current = current.Parent
    end

    return false
end

local function canHideDecoration(obj)
    if not obj:IsA("MeshPart") then return false end
    if obj.CanCollide or obj.CanTouch or obj.CanQuery then
        return false
    end

    if importantObject(obj) then return false end

    if obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        or obj:FindFirstChildWhichIsA("ClickDetector", true) then
        return false
    end

    return true
end

local function optimize(obj)
    if not Alive or not Enabled then return end
    if not obj or not obj.Parent then return end
    if protected(obj) then return end

    if obj:IsA("BasePart") then
        change(obj, "CastShadow", false)
        change(obj, "Reflectance", 0)
        change(obj, "Material", Enum.Material.Plastic)

        if obj:IsA("MeshPart") then
            change(obj, "TextureID", "")

            pcall(function()
                change(
                    obj,
                    "RenderFidelity",
                    Enum.RenderFidelity.Performance
                )
            end)

            if canHideDecoration(obj) then
                change(obj, "LocalTransparencyModifier", 1)
            end
        end

    elseif obj:IsA("SpecialMesh") then
        change(obj, "TextureId", "")

    elseif obj:IsA("SurfaceAppearance") then
        change(obj, "ColorMap", "")
        change(obj, "NormalMap", "")
        change(obj, "MetalnessMap", "")
        change(obj, "RoughnessMap", "")

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)

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

    change(Lighting, "GlobalShadows", false)
    change(Lighting, "FogEnd", 1000000000)
    change(Lighting, "EnvironmentDiffuseScale", 0)
    change(Lighting, "EnvironmentSpecularScale", 0)
    change(Lighting, "ShadowSoftness", 0)

    pcall(function()
        local rendering = settings().Rendering

        if QualitySaved == nil then
            QualitySaved = rendering.QualityLevel
        end

        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function enqueue(obj)
    if not Alive or not Enabled or not obj then return end
    if Queued[obj] then return end

    Queued[obj] = true
    Queue[#Queue + 1] = obj
end

local function scan(root, token)
    local stack = {root}
    local count = 0

    while #stack > 0 do
        if not Alive or not Enabled or token ~= Generation then
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

        if count >= BATCH_SIZE then
            count = 0
            task.wait(BATCH_WAIT)
        end
    end
end

local function worker(token)
    while Alive and Enabled and token == Generation do
        local processed = 0

        while processed < BATCH_SIZE and QueueHead <= #Queue do
            if not Alive or not Enabled or token ~= Generation then
                return
            end

            local obj = Queue[QueueHead]
            Queue[QueueHead] = false
            QueueHead += 1

            if obj then
                Queued[obj] = nil
                pcall(optimize, obj)
            end

            processed += 1
        end

        if QueueHead > #Queue then
            Queue = {}
            QueueHead = 1
        end

        task.wait(BATCH_WAIT)
    end
end

local function refresh()
    if not Toggle then return end

    Toggle.Text = Enabled and "Enabled" or "Disabled"

    Toggle.BackgroundColor3 = Enabled
        and Color3.fromRGB(0, 95, 210)
        or Color3.fromRGB(27, 42, 66)
end

local function enable()
    if Enabled or not Alive then return end

    Enabled = true
    Generation += 1

    local token = Generation

    optimizeEnvironment()
    refresh()

    task.spawn(worker, token)
    task.spawn(scan, Workspace, token)
    task.spawn(scan, Lighting, token)
end

local function disable()
    if not Enabled then return end

    Enabled = false
    Generation += 1

    Queue = {}
    QueueHead = 1
    Queued = setmetatable({}, {__mode = "k"})

    restore()
    refresh()
end

GUI = Instance.new("ScreenGui")
GUI.Name = "FarhanStore_FPS_ONLY"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(190, 125)
Main.Position = UDim2.new(0, 25, 0.5, -62)
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
Title.Position = UDim2.fromOffset(10, 8)
Title.BackgroundTransparency = 1
Title.Text = "FarhanStore"
Title.TextColor3 = Color3.fromRGB(245, 245, 255)
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

Toggle = Instance.new("TextButton")
Toggle.Name = "FPSBoost"
Toggle.Size = UDim2.new(1, -48, 0, 29)
Toggle.Position = UDim2.new(0, 24, 0, 49)
Toggle.BackgroundColor3 = Color3.fromRGB(27, 42, 66)
Toggle.BorderSizePixel = 0
Toggle.Text = "Disabled"
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.TextSize = 14
Toggle.Font = Enum.Font.GothamBold
Toggle.ZIndex = 2
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 7)
ToggleCorner.Parent = Toggle

PingLabel = Instance.new("TextLabel")
PingLabel.Name = "Ping"
PingLabel.Size = UDim2.new(1, -20, 0, 23)
PingLabel.Position = UDim2.new(0, 10, 0, 88)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "PING : -- ms"
PingLabel.TextColor3 = Color3.fromRGB(105, 190, 255)
PingLabel.TextSize = 15
PingLabel.Font = Enum.Font.GothamBold
PingLabel.ZIndex = 2
PingLabel.Parent = Main

connect(Toggle.MouseButton1Click, function()
    if Enabled then
        disable()
    else
        enable()
    end
end)

connect(Minimize.MouseButton1Click, function()
    Minimized = not Minimized

    Toggle.Visible = not Minimized
    PingLabel.Visible = not Minimized

    Main.Size = Minimized
        and UDim2.fromOffset(190, 43)
        or UDim2.fromOffset(190, 125)

    Minimize.Text = Minimized and "+" or "-"
end)

connect(UIS.InputBegan, function(input, processed)
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
    if Enabled then enqueue(obj) end
end)

connect(Lighting.DescendantAdded, function(obj)
    if Enabled then enqueue(obj) end
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

    disable()
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

print("FARHAN STORE ")
