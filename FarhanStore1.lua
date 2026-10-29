
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
local State = "off"
local Light = false
local Minimized = false
local Token = 0
local Workers = 0

local FONT_ID = 12187372382
local FRAME_BUDGET = 0.003
local Saved = {}
local FontSaved = {}
local Connections = {}
local OriginalLighting = {}
local OriginalQuality

local Gui, Main, FPSButton, LightButton
local PingLabel, FPSLabel, StatusLabel

local CustomFont
pcall(function()
    CustomFont = Font.fromId(FONT_ID)
end)

local function useFont(label, fallback)
    if CustomFont then
        pcall(function()
            label.FontFace = CustomFont
        end)
    else
        label.Font = fallback or Enum.Font.GothamBold
    end
end

local function connect(signal, fn)
    local c = signal:Connect(fn)
    Connections[#Connections + 1] = c
    return c
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

local function protected(obj)
    local char = Player.Character

    if char and (obj == char or obj:IsDescendantOf(char)) then
        return true
    end

    if obj:FindFirstAncestorOfClass("Tool")
        or obj:FindFirstAncestorOfClass("Accessory") then
        return true
    end

    return false
end

local function isGunStoreWood(obj)
    if not obj:IsA("BasePart") then return false end
    if obj.CanCollide or obj.CanTouch then return false end

    local wood, store = false, false
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

    return wood and store
end

local function optimize(obj)
    if not Alive or State ~= "on" then return end
    if not obj or not obj.Parent or protected(obj) then return end

    if obj:IsA("BasePart") then
        saveSet(obj, "Material", Enum.Material.Plastic)
        saveSet(obj, "Reflectance", 0)
        saveSet(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            saveSet(obj, "TextureID", "")
            saveSet(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
        end

        if isGunStoreWood(obj) then
            saveSet(obj, "LocalTransparencyModifier", 1)
        end

    elseif obj:IsA("SpecialMesh") then
        saveSet(obj, "TextureId", "")

    elseif obj:IsA("SurfaceAppearance") then
        saveSet(obj, "ColorMap", "")
        saveSet(obj, "NormalMap", "")
        saveSet(obj, "MetalnessMap", "")
        saveSet(obj, "RoughnessMap", "")

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
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
    "FogEnd", "EnvironmentDiffuseScale",
    "EnvironmentSpecularScale", "ShadowSoftness"
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
                OriginalLighting.Brightness or 1, 1.35
            )
            Lighting.Ambient = Color3.fromRGB(95, 95, 95)
            Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 105)
            Lighting.ExposureCompensation = 0
        end)
    end
end

local function refresh()
    if FPSButton then
        FPSButton.Text = "Enabled"
        FPSButton.BackgroundColor3 = State == "on"
            and Color3.fromRGB(13, 110, 239)
            or Color3.fromRGB(23, 34, 56)
    end

    if LightButton then
        LightButton.Text = "Light"
        LightButton.BackgroundColor3 = Light
            and Color3.fromRGB(13, 110, 239)
            or Color3.fromRGB(23, 34, 56)
    end

    if StatusLabel then
        StatusLabel.Text = State == "on" and "● POTATO ACTIVE"
            or State == "restoring" and "● RESTORING..."
            or "● READY"

        StatusLabel.TextColor3 = State == "on"
            and Color3.fromRGB(87, 220, 151)
            or Color3.fromRGB(146, 163, 190)
    end
end

local function scan(root, token)
    Workers += 1

    local stack = {root}
    local lastYield = os.clock()

    while #stack > 0 do
        if not Alive or State ~= "on" or token ~= Token then
            break
        end

        local obj = table.remove(stack)

        if obj then
            pcall(optimize, obj)

            local children = obj:GetChildren()
            for i = 1, #children do
                stack[#stack + 1] = children[i]
            end
        end

        if os.clock() - lastYield >= FRAME_BUDGET then
            RunService.Heartbeat:Wait()
            lastYield = os.clock()
        end
    end

    Workers -= 1
end

local function enable()
    if State ~= "off" or not Alive then return end

    State = "on"
    Token += 1

    saveSet(Terrain, "WaterWaveSize", 0)
    saveSet(Terrain, "WaterWaveSpeed", 0)
    saveSet(Terrain, "WaterReflectance", 0)
    saveSet(Terrain, "WaterTransparency", 1)
    saveSet(Terrain, "Decoration", false)

    pcall(function()
        local rendering = settings().Rendering
        OriginalQuality = rendering.QualityLevel
        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    applyLighting()
    refresh()

    local token = Token
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
        local lastYield = os.clock()

        for obj, properties in pairs(Saved) do
            for prop, old in pairs(properties) do
                pcall(function()
                    obj[prop] = old
                end)
            end

            Saved[obj] = nil
            count += 1

            if os.clock() - lastYield >= FRAME_BUDGET then
                RunService.Heartbeat:Wait()
                lastYield = os.clock()
            end
        end

        if OriginalQuality ~= nil then
            pcall(function()
                settings().Rendering.QualityLevel = OriginalQuality
            end)
            OriginalQuality = nil
        end

        State = "off"
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

    if Gui and obj:IsDescendantOf(Gui) then return end

    if FontSaved[obj] == nil then
        pcall(function()
            FontSaved[obj] = obj.FontFace
        end)
    end

    pcall(function()
        obj.FontFace = CustomFont
    end)
end

Gui = Instance.new("ScreenGui")
Gui.Name = "FarhanStore_V16"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(218, 185)
Main.Position = UDim2.new(0, 25, 0.5, -92)
Main.BackgroundColor3 = Color3.fromRGB(8, 11, 20)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 11)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(205, 220, 245)
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.15
mainStroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(12, 20, 35)
Header.BorderSizePixel = 0
Header.Parent = Main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 11)
headerCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -45, 0, 30)
Title.Position = UDim2.fromOffset(12, 4)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = '<font color="#FFFFFF">Farhan</font><font color="#168BFF">Store</font>'
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 19
useFont(Title)
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(21, 21)
Minimize.Position = UDim2.new(1, -30, 0, 8)
Minimize.BackgroundColor3 = Color3.fromRGB(15, 108, 225)
Minimize.BorderSizePixel = 0
Minimize.Text = "−"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 16
useFont(Minimize)
Minimize.Parent = Header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(1, 0)
minCorner.Parent = Minimize

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
    b.BackgroundColor3 = Color3.fromRGB(23, 34, 56)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(245, 248, 255)
    b.TextSize = 15
    useFont(b)
    b.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(47, 81, 130)
    s.Thickness = 1
    s.Transparency = 0.25
    s.Parent = b

    return b
end

FPSButton = makeButton("FPSBoost", 49)
LightButton = makeButton("Light", 88)

local Info = Instance.new("Frame")
Info.Size = UDim2.new(1, -28, 0, 25)
Info.Position = UDim2.fromOffset(14, 128)
Info.BackgroundColor3 = Color3.fromRGB(13, 22, 38)
Info.BorderSizePixel = 0
Info.Parent = Main

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 5)
infoCorner.Parent = Info

PingLabel = Instance.new("TextLabel")
PingLabel.Size = UDim2.new(0.55, 0, 1, 0)
PingLabel.Position = UDim2.fromOffset(7, 0)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "PING: -- ms"
PingLabel.TextXAlignment = Enum.TextXAlignment.Left
PingLabel.TextColor3 = Color3.fromRGB(105, 190, 255)
PingLabel.TextSize = 13
useFont(PingLabel)
PingLabel.Parent = Info

FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0.4, -7, 1, 0)
FPSLabel.Position = UDim2.new(0.6, 0, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: --"
FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
FPSLabel.TextColor3 = Color3.fromRGB(105, 190, 255)
FPSLabel.TextSize = 13
useFont(FPSLabel)
FPSLabel.Parent = Info

StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.fromOffset(10, 158)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextSize = 11
useFont(StatusLabel)
StatusLabel.Parent = Main

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
    Info.Visible = not Minimized
    StatusLabel.Visible = not Minimized

    Main.Size = Minimized
        and UDim2.fromOffset(218, 38)
        or UDim2.fromOffset(218, 185)

    Minimize.Text = Minimized and "+" or "−"
end)

connect(UIS.InputBegan, function(input)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        Gui.Enabled = not Gui.Enabled
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

connect(game.DescendantAdded, applyGameFont)

task.spawn(function()
    local lastYield = os.clock()

    for _, obj in ipairs(game:GetDescendants()) do
        if not Alive then break end
        applyGameFont(obj)

        if os.clock() - lastYield >= FRAME_BUDGET then
            RunService.Heartbeat:Wait()
            lastYield = os.clock()
        end
    end
end)

local frames = 0
local fpsValue = 0
local fpsTimer = os.clock()

connect(RunService.RenderStepped, function()
    frames += 1

    local now = os.clock()
    local elapsed = now - fpsTimer

    if elapsed >= 0.5 then
        fpsValue = math.floor(frames / elapsed + 0.5)
        frames = 0
        fpsTimer = now
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
        FPSLabel.Text = "FPS: " .. fpsValue

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
print("FARHAN STORE | POTATO V1.6")
