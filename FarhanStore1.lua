
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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
local WorkerRunning = false

local Connections = {}
local Saved = {}
local Queue = {}
local Queued = setmetatable({}, {__mode = "k"})

local QualitySaved
local GUI
local Main
local Toggle
local Minimize

local BATCH_SIZE = 35
local BATCH_WAIT = 0.035

local function connect(signal, callback)
    local c = signal:Connect(callback)
    Connections[#Connections + 1] = c
    return c
end

local function change(obj, property, value)
    if not obj then return end

    local ok, original = pcall(function()
        return obj[property]
    end)

    if not ok then return end

    local record = Saved[obj]

    if not record then
        record = {}
        Saved[obj] = record
    end

    if record[property] == nil then
        record[property] = original
    end

    pcall(function()
        obj[property] = value
    end)
end

local function restore()
    for obj, properties in pairs(Saved) do
        for property, value in pairs(properties) do
            pcall(function()
                obj[property] = value
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

local function protectedObject(obj)
    if not obj then return true end

    if obj:FindFirstAncestorOfClass("Tool") then
        return true
    end

    if obj:FindFirstAncestorOfClass("Accessory") then
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
    if not Alive or not Enabled then return end
    if not obj or not obj.Parent then return end

    if protectedObject(obj) then return end

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
        end

    elseif obj:IsA("SpecialMesh") then
        change(obj, "TextureId", "")

    elseif obj:IsA("SurfaceAppearance") then
        change(obj, "ColorMap", "")
        change(obj, "NormalMap", "")
        change(obj, "MetalnessMap", "")
        change(obj, "RoughnessMap", "")

    elseif obj:IsA("Decal")
        or obj:IsA("Texture") then

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

    elseif obj:IsA("Highlight") then
        change(obj, "Enabled", false)

    elseif obj:IsA("PostEffect") then
        change(obj, "Enabled", false)

    elseif obj:IsA("Clouds") then
        change(obj, "Enabled", false)
    end
end

local function environment()
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
    if not Alive or not Enabled or not obj then
        return
    end

    if Queued[obj] then return end

    Queued[obj] = true
    Queue[#Queue + 1] = obj
end

local function worker()
    if WorkerRunning then return end

    WorkerRunning = true

    while Alive do
        if not Enabled then break end

        local token = Generation
        local processed = 0

        while processed < BATCH_SIZE and #Queue > 0 do
            if not Alive
                or not Enabled
                or token ~= Generation then
                break
            end

            local obj = table.remove(Queue)

            if obj then
                Queued[obj] = nil
                pcall(optimize, obj)
            end

            processed += 1
        end

        if #Queue == 0 then
            break
        end

        task.wait(BATCH_WAIT)
    end

    WorkerRunning = false

    if Alive and Enabled and #Queue > 0 then
        task.defer(worker)
    end
end

local function scanTree(root, token)
    local stack = {root}
    local count = 0

    while #stack > 0 do
        if not Alive
            or not Enabled
            or token ~= Generation then
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

local function refresh()
    if not Toggle then return end

    Toggle.Text = Enabled and "Enabled" or "Disabled"

    Toggle.BackgroundColor3 = Enabled
        and Color3.fromRGB(7, 75, 158)
        or Color3.fromRGB(24, 39, 65)
end

local function enable()
    if Enabled or not Alive then return end

    Enabled = true
    Generation += 1

    local token = Generation

    environment()
    refresh()

    task.spawn(function()
        scanTree(Workspace, token)
    end)

    task.spawn(function()
        scanTree(Lighting, token)
    end)

    task.spawn(function()
        while Alive and Enabled and token == Generation do
            if #Queue > 0 and not WorkerRunning then
                worker()
            end

            task.wait(0.1)
        end
    end)
end

local function disable()
    if not Enabled then return end

    Enabled = false
    Generation += 1

    table.clear(Queue)
    table.clear(Queued)

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
Main.Size = UDim2.fromOffset(180, 105)
Main.Position = UDim2.new(0, 25, 0.5, -52)
Main.BackgroundColor3 = Color3.fromRGB(7, 9, 16)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(235, 238, 245)
Stroke.Thickness = 1.5
Stroke.Parent = Main

for i = 1, 17 do
    local star = Instance.new("Frame")
    star.Name = "Star" .. i
    star.Size = UDim2.fromOffset(1, 1)

    star.Position = UDim2.new(
        ((i * 37) % 100) / 100, 0,
        ((i * 23) % 100) / 100, 0
    )

    star.BackgroundColor3 = Color3.fromRGB(220, 225, 245)
    star.BackgroundTransparency = (i % 3) * 0.2
    star.BorderSizePixel = 0
    star.Parent = Main
end

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -28, 0, 35)
Title.Position = UDim2.fromOffset(10, 10)
Title.BackgroundTransparency = 1
Title.Text = "FarhanStore"
Title.TextColor3 = Color3.fromRGB(245, 245, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.ZIndex = 2
Title.Parent = Main

Minimize = Instance.new("TextButton")
Minimize.Name = "Minimize"
Minimize.Size = UDim2.fromOffset(18, 18)
Minimize.Position = UDim2.new(1, -23, 0, 9)
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
Toggle.Size = UDim2.new(1, -48, 0, 30)
Toggle.Position = UDim2.new(0, 24, 0, 57)
Toggle.BackgroundColor3 = Color3.fromRGB(24, 39, 65)
Toggle.BorderSizePixel = 0
Toggle.Text = "Disabled"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextSize = 14
Toggle.Font = Enum.Font.GothamBold
Toggle.ZIndex = 2
Toggle.Parent = Main

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 7)
ToggleCorner.Parent = Toggle

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

    Main.Size = Minimized
        and UDim2.fromOffset(180, 43)
        or UDim2.fromOffset(180, 105)

    Minimize.Text = Minimized and "+" or "-"
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
    if Enabled then
        enqueue(obj)
    end
end)

connect(Lighting.DescendantAdded, function(obj)
    if Enabled then
        enqueue(obj)
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

print("FARHAN STORE | FPS BOOST ONLY V1.0 AGGRESSIVE")
