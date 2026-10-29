
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Terrain = Workspace.Terrain
local ENV = getgenv and getgenv() or _G

if type(ENV.FarhanFPSOnlyCleanup) == "function" then
    pcall(ENV.FarhanFPSOnlyCleanup)
end

local Alive = true
local State = "off"
local Light = false
local Minimized = false
local Token = 0
local Workers = 0

local FONT_ID = 12187372382
local BATCH = 100

local Saved = {}
local FontSaved = {}
local Connections = {}
local LightOriginal = {}
local QualityOriginal
local Gui, Main, FPSButton, LightButton, PingLabel

local function connect(signal, fn)
    local c = signal:Connect(fn)
    Connections[#Connections + 1] = c
    return c
end

local function set(obj, prop, value)
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
        data[prop] = original
    end

    pcall(function()
        obj[prop] = value
    end)
end

local function protected(obj)
    if obj:FindFirstAncestorOfClass("Tool")
        or obj:FindFirstAncestorOfClass("Accessory") then
        return true
    end

    local char = Player.Character
    if char and (obj == char or obj:IsDescendantOf(char)) then
        return true
    end

    return false
end

local function isGunStoreWood(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.CanCollide or obj.CanTouch then return false end

    local wood = false
    local store = false
    local current = obj

    while current and current ~= Workspace do
        local name = current.Name:lower()

        if name:find("wood", 1, true)
            or name:find("plank", 1, true)
            or name:find("board", 1, true)
            or name:find("timber", 1, true)
            or name:find("kayu", 1, true) then
            wood = true
        end

        if name:find("gunstore", 1, true)
            or name:find("gun store", 1, true)
            or name:find("gun_shop", 1, true)
            or name:find("gunshop", 1, true) then
            store = true
        end

        if name:find("door", 1, true)
            or name:find("floor", 1, true)
            or name:find("weapon", 1, true) then
            return false
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
    if not obj or not obj.Parent or protected(obj) then return end

    if obj:IsA("BasePart") then
        set(obj, "Material", Enum.Material.Plastic)
        set(obj, "Reflectance", 0)
        set(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            set(obj, "TextureID", "")

            pcall(function()
                set(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
            end)
        end

        if isGunStoreWood(obj) then
            set(obj, "LocalTransparencyModifier", 1)
        end

    elseif obj:IsA("SpecialMesh") then
        set(obj, "TextureId", "")

    elseif obj:IsA("SurfaceAppearance") then
        set(obj, "ColorMap", "")
        set(obj, "NormalMap", "")
        set(obj, "MetalnessMap", "")
        set(obj, "RoughnessMap", "")

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        set(obj, "Transparency", 1)

    elseif obj:IsA("ParticleEmitter") then
        set(obj, "Enabled", false)
        set(obj, "Rate", 0)
        pcall(function() obj:Clear() end)

    elseif obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles") then
        set(obj, "Enabled", false)

    elseif obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
        set(obj, "Shadows", false)

    elseif obj:IsA("Highlight")
        or obj:IsA("PostEffect")
        or obj:IsA("Clouds") then
        set(obj, "Enabled", false)

    elseif obj:IsA("Atmosphere") then
        set(obj, "Density", 0)
        set(obj, "Haze", 0)
        set(obj, "Glare", 0)

    elseif obj:IsA("Sky") then
        for _, prop in ipairs({
            "SkyboxBk", "SkyboxDn", "SkyboxFt",
            "SkyboxLf", "SkyboxRt", "SkyboxUp"
        }) do
            set(obj, prop, "")
        end

        set(obj, "CelestialBodiesShown", false)
        set(obj, "StarCount", 0)
    end
end

for _, prop in ipairs({
    "Brightness", "Ambient", "OutdoorAmbient",
    "ExposureCompensation", "GlobalShadows",
    "FogEnd", "EnvironmentDiffuseScale",
    "EnvironmentSpecularScale", "ShadowSoftness"
}) do
    pcall(function()
        LightOriginal[prop] = Lighting[prop]
    end)
end

local function applyLighting()
    for prop, value in pairs(LightOriginal) do
        pcall(function()
            Lighting[prop] = value
        end)
    end

    if State == "on" then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.ShadowSoftness = 0
        end)
    end

    if Light then
        pcall(function()
            Lighting.Brightness = math.max(
                LightOriginal.Brightness or 1, 1.35
            )
            Lighting.Ambient = Color3.fromRGB(95, 95, 95)
            Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 105)
            Lighting.ExposureCompensation = 0
        end)
    end
end

local function refresh()
    if FPSButton then
        FPSButton.Text = State == "restoring" and "Restoring..."
            or State == "on" and "Enabled"
            or "Enabled"

        FPSButton.BackgroundColor3 = State == "on"
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

local function scan(root, token)
    Workers += 1

    local stack = {root}
    local count = 0

    while #stack > 0 do
        if not Alive or State ~= "on" or token ~= Token then
            break
        end

        local obj = table.remove(stack)

        if obj then
            pcall(optimize, obj)

            for _, child in ipairs(obj:GetChildren()) do
                stack[#stack + 1] = child
            end
        end

        count += 1

        if count >= BATCH then
            count = 0
            RunService.Heartbeat:Wait()
        end
    end

    Workers -= 1
end

local function enable()
    if not Alive or State ~= "off" then return end

    State = "on"
    Token += 1
    local token = Token

    set(Terrain, "WaterWaveSize", 0)
    set(Terrain, "WaterWaveSpeed", 0)
    set(Terrain, "WaterReflectance", 0)
    set(Terrain, "WaterTransparency", 1)

    pcall(function()
        set(Terrain, "Decoration", false)
    end)

    pcall(function()
        local rendering = settings().Rendering
        QualityOriginal = rendering.QualityLevel
        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    applyLighting()
    refresh()

    task.spawn(scan, Workspace, token)
    task.spawn(scan, Lighting, token)
end

local function disable()
    if State ~= "on" then return end

    State = "restoring"
    Token += 1
    refresh()

    task.spawn(function()
        while Workers > 0 do
            RunService.Heartbeat:Wait()
        end

        local count = 0

        for obj, properties in pairs(Saved) do
            for prop, original in pairs(properties) do
                pcall(function()
                    obj[prop] = original
                end)
            end

            Saved[obj] = nil
            count += 1

            if count >= BATCH then
                count = 0
                RunService.Heartbeat:Wait()
            end
        end

        if QualityOriginal ~= nil then
            pcall(function()
                settings().Rendering.QualityLevel = QualityOriginal
            end)
            QualityOriginal = nil
        end

        State = "off"
        applyLighting()
        refresh()
    end)
end

local GameFont
pcall(function()
    GameFont = Font.fromId(FONT_ID)
end)

local function applyFont(obj)
    if not Alive or not GameFont then return end

    if not (
        obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox")
    ) then return end

    if Gui and obj:IsDescendantOf(Gui) then return end

    if FontSaved[obj] == nil then
        pcall(function()
            FontSaved[obj] = obj.FontFace
        end)
    end

    pcall(function()
        obj.FontFace = GameFont
    end)
end

Gui = Instance.new("ScreenGui")
Gui.Name = "FarhanStore_Potato_V15"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(195, 155)
Main.Position = UDim2.new(0, 25, 0.5, -77)
Main.BackgroundColor3 = Color3.fromRGB(7, 9, 16)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = Main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(235, 238, 245)
stroke.Thickness = 1.4
stroke.Parent = Main

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
Title.Size = UDim2.new(1, -35, 0, 28)
Title.Position = UDim2.fromOffset(10, 7)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = '<font color="#FFFFFF">Farhan</font><font color="#168BFF">Store</font>'
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
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
Minimize.Parent = Main

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(1, 0)
mc.Parent = Minimize

local function button(name, y)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -34, 0, 29)
    b.Position = UDim2.fromOffset(17, y)
    b.BackgroundColor3 = Color3.fromRGB(26, 39, 62)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 14
    b.Font = Enum.Font.GothamBold
    b.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b

    return b
end

FPSButton = button("FPSBoost", 43)
LightButton = button("Light", 79)

PingLabel = Instance.new("TextLabel")
PingLabel.Size = UDim2.new(1, -20, 0, 23)
PingLabel.Position = UDim2.fromOffset(10, 119)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "PING : -- ms"
PingLabel.TextColor3 = Color3.fromRGB(105, 190, 255)
PingLabel.TextSize = 15
PingLabel.Font = Enum.Font.GothamBold
PingLabel.Parent = Main

connect(FPSButton.MouseButton1Click, function()
    if State == "off" then
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
    PingLabel.Visible = not Minimized

    Main.Size = Minimized
        and UDim2.fromOffset(195, 42)
        or UDim2.fromOffset(195, 155)

    Minimize.Text = Minimized and "+" or "-"
end)

connect(UIS.InputBegan, function(input)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        Gui.Enabled = not Gui.Enabled
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
    if State == "on" then
        local token = Token
        task.defer(function()
            if Alive and State == "on" and token == Token then
                pcall(optimize, obj)
            end
        end)
    end
end)

connect(Lighting.DescendantAdded, function(obj)
    if State == "on" then
        local token = Token
        task.defer(function()
            if Alive and State == "on" and token == Token then
                pcall(optimize, obj)
            end
        end)
    end
end)

connect(game.DescendantAdded, applyFont)

task.spawn(function()
    local count = 0

    for _, obj in ipairs(game:GetDescendants()) do
        if not Alive then break end
        applyFont(obj)
        count += 1

        if count >= BATCH then
            count = 0
            RunService.Heartbeat:Wait()
        end
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

        PingLabel.Text = "PING : " .. ping .. " ms"
        task.wait(0.1)
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

    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    for obj, font in pairs(FontSaved) do
        pcall(function()
            obj.FontFace = font
        end)
    end

    table.clear(Connections)
    table.clear(FontSaved)

    Gui:Destroy()
end

ENV.FarhanFPSOnlyCleanup = cleanup

refresh()
print("FARHAN STORE | POTATO V1.5")
