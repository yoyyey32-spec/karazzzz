
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Terrain = Workspace.Terrain

local SCFont
pcall(function()
    SCFont = Font.fromId(12187372382)
end)

local State = {
    fps = false,
    bright = false,
    interact = false,
    noSpread = false,
    visible = true
}

local Saved = {}
local HiddenSky = {}
local OriginalLighting = {}
local OriginalDecoration
local GrayAtmosphere
local Busy = false

local OldCleanup = getgenv and getgenv().SCFPS_Cleanup
if type(OldCleanup) == "function" then
    pcall(OldCleanup)
end

local Connections = {}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function remember(obj, prop)
    if not obj then return end

    if not Saved[obj] then
        Saved[obj] = {}
    end

    if Saved[obj][prop] ~= nil then return end

    local ok, value = pcall(function()
        return obj[prop]
    end)

    if ok then
        Saved[obj][prop] = value
    end
end

local function change(obj, prop, value)
    if not obj then return end

    remember(obj, prop)

    pcall(function()
        obj[prop] = value
    end)
end

local function restoreSaved()
    for obj, props in pairs(Saved) do
        for prop, value in pairs(props) do
            pcall(function()
                obj[prop] = value
            end)
        end
    end

    table.clear(Saved)
end

local function nameHas(obj, words)
    if not obj then return false end

    local name = string.lower(obj.Name)

    for _, word in ipairs(words) do
        if string.find(name, word, 1, true) then
            return true
        end
    end

    return false
end

local function matches(obj, words)
    local current = obj

    while current and current ~= Workspace do
        if nameHas(current, words) then
            return true
        end

        current = current.Parent
    end

    return false
end

local function protectedCharacter(obj)
    local current = obj

    while current and current ~= Workspace do
        if current:IsA("Model") then
            if Players:GetPlayerFromCharacter(current)
                or current:FindFirstChildOfClass("Humanoid") then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

local function isGunStore(obj)
    return matches(obj, {
        "gunstore", "gun_store", "gun store",
        "gunshop", "gun_shop", "gun shop",
        "weaponstore", "weapon_store", "weapon shop"
    })
end

local function isWeapon(obj)
    local current = obj

    while current and current ~= Workspace do
        if current:IsA("Tool") then
            return true
        end

        current = current.Parent
    end

    return matches(obj, {
        "g17", "glock", "drum", "pistol",
        "rifle", "shotgun", "smg", "revolver",
        "firearm", "magazine", "handgun",
        "ak47", "ak-47", "m1911", "uzi",
        "weaponmodel", "gunmodel"
    })
end

local function isFence(obj)
    return matches(obj, {
        "fence", "fencing", "railing",
        "barbedwire", "ironbar"
    })
end

local function isCar(obj)
    return matches(obj, {
        "vehicle", "automobile", "carbody",
        "car_body", "sedan", "suv",
        "carparts", "car_parts"
    })
end

local function isCarInterior(obj)
    return isCar(obj) and matches(obj, {
        "interior", "dashboard", "seatinside",
        "carseat", "steeringwheel", "car_interior"
    })
end

local function isLeaf(obj)
    return matches(obj, {
        "foliage", "leaves", "leaf",
        "treeleaves", "treetop",
        "canopy", "bush"
    })
end

local function isGunStoreWood(obj)
    if not isGunStore(obj) then return false end

    if nameHas(obj, {
        "wood", "wooden", "plank",
        "timber", "log", "board",
        "shelf", "counter"
    }) then
        return true
    end

    if obj:IsA("BasePart") then
        return obj.Material == Enum.Material.Wood
            or obj.Material == Enum.Material.WoodPlanks
    end

    return false
end

local function isBlood(obj)
    return matches(obj, {
        "blood", "bloodsplatter",
        "blood_splatter", "bleeding",
        "bloodfx"
    })
end

local function isGunFlash(obj)
    return matches(obj, {
        "muzzle", "muzzleflash", "gunflash",
        "gun_flash", "shootingeffect",
        "weaponfx", "bullettrail",
        "bullet_trail", "tracer",
        "shellparticle", "gunsmoke"
    })
end

local function isVisualEffect(obj)
    return obj:IsA("ParticleEmitter")
        or obj:IsA("Beam")
        or obj:IsA("Trail")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
end

local function hideVisual(obj)
    if obj:IsA("BasePart") then
        change(obj, "LocalTransparencyModifier", 1)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)

    elseif isVisualEffect(obj) then
        change(obj, "Enabled", false)

    elseif obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
        change(obj, "Enabled", false)
    end
end

local function blackGun(obj)
    if obj:IsA("BasePart") then
        change(obj, "CastShadow", false)
        change(obj, "Reflectance", 0)
        change(obj, "Material", Enum.Material.SmoothPlastic)
        change(obj, "Color", Color3.fromRGB(12, 12, 14))
        change(obj, "LocalTransparencyModifier", 0)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)

    elseif obj:IsA("SurfaceAppearance") then
        change(obj, "AlphaMode", Enum.AlphaMode.Overlay)
        change(obj, "ColorMap", "")
        change(obj, "NormalMap", "")
        change(obj, "MetalnessMap", "")
        change(obj, "RoughnessMap", "")
    end
end

local function optimizeCar(obj)
    if isCarInterior(obj) then
        hideVisual(obj)
        return
    end

    if obj:IsA("BasePart") then
        change(obj, "CastShadow", false)
        change(obj, "Reflectance", 0)
        change(obj, "Material", Enum.Material.SmoothPlastic)
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)
    elseif isVisualEffect(obj) then
        change(obj, "Enabled", false)
    end
end

local function optimize(obj)
    if not State.fps or not obj or not obj.Parent then
        return
    end

    if obj:IsA("ProximityPrompt")
        or obj:IsA("ClickDetector") then
        return
    end

    if protectedCharacter(obj) then return end

    if isBlood(obj) or isGunFlash(obj) then
        hideVisual(obj)
        return
    end

    if isVisualEffect(obj) then
        change(obj, "Enabled", false)
        return
    end

    if isWeapon(obj) then
        blackGun(obj)
        return
    end

    if isFence(obj) then
        if obj:IsA("BasePart") then
            change(obj, "CastShadow", false)
            change(obj, "Reflectance", 0)
        end
        return
    end

    if isGunStoreWood(obj) then
        hideVisual(obj)
        return
    end

    if isCar(obj) then
        optimizeCar(obj)
        return
    end

    if isLeaf(obj) then
        hideVisual(obj)
        return
    end

    if obj:IsA("BasePart") then
        change(obj, "CastShadow", false)
        change(obj, "Reflectance", 0)
        change(obj, "Material", Enum.Material.SmoothPlastic)
    end
end

local function saveLighting()
    for _, prop in ipairs({
        "Brightness", "ClockTime",
        "ExposureCompensation", "GlobalShadows",
        "FogEnd", "Ambient", "OutdoorAmbient"
    }) do
        if OriginalLighting[prop] == nil then
            pcall(function()
                OriginalLighting[prop] = Lighting[prop]
            end)
        end
    end
end

local function restoreLighting()
    for prop, value in pairs(OriginalLighting) do
        pcall(function()
            Lighting[prop] = value
        end)
    end
end

local function applyGraySky()
    saveLighting()

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky")
            or obj:IsA("Atmosphere")
            or obj:IsA("Clouds") then

            if obj ~= GrayAtmosphere then
                if HiddenSky[obj] == nil then
                    HiddenSky[obj] = obj.Parent
                end

                obj.Parent = nil
            end
        elseif obj:IsA("PostEffect") then
            change(obj, "Enabled", false)
        end
    end

    for _, obj in ipairs(Terrain:GetChildren()) do
        if obj:IsA("Clouds") then
            change(obj, "Enabled", false)
        end
    end

    if not GrayAtmosphere then
        GrayAtmosphere = Instance.new("Atmosphere")
        GrayAtmosphere.Name = "SCFPS_DarkGraySky"
    end

    GrayAtmosphere.Color = Color3.fromRGB(72, 72, 76)
    GrayAtmosphere.Decay = Color3.fromRGB(42, 42, 46)
    GrayAtmosphere.Density = 0.42
    GrayAtmosphere.Glare = 0
    GrayAtmosphere.Haze = 0
    GrayAtmosphere.Parent = Lighting

    if not State.bright then
        Lighting.ClockTime = 14
        Lighting.Brightness = 0.8
        Lighting.ExposureCompensation = -0.12
        Lighting.Ambient = Color3.fromRGB(62, 62, 66)
        Lighting.OutdoorAmbient = Color3.fromRGB(48, 48, 52)
        Lighting.GlobalShadows = false
    end
end

local function restoreSky()
    if GrayAtmosphere then
        GrayAtmosphere:Destroy()
        GrayAtmosphere = nil
    end

    for obj, parent in pairs(HiddenSky) do
        pcall(function()
            obj.Parent = parent
        end)
    end

    table.clear(HiddenSky)
end

local function applyBright()
    saveLighting()

    Lighting.Brightness = 3
    Lighting.ExposureCompensation = 0.5
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    Lighting.Ambient = Color3.fromRGB(170, 170, 170)
    Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
end

local function refreshLighting()
    restoreLighting()

    if State.fps then
        applyGraySky()
    end

    if State.bright then
        applyBright()
    end
end

local function applyFont(obj)
    if not State.fps or not SCFont then return end

    if obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox") then
        change(obj, "FontFace", SCFont)
    end
end

local function applyFPS()
    if Busy then return end
    Busy = true

    if State.fps then
        if OriginalDecoration == nil then
            pcall(function()
                OriginalDecoration = Terrain.Decoration
            end)
        end

        pcall(function()
            Terrain.Decoration = false
        end)

        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimize(obj)
        end

        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            applyFont(obj)
        end
    else
        restoreSaved()

        if OriginalDecoration ~= nil then
            pcall(function()
                Terrain.Decoration = OriginalDecoration
            end)
        end

        restoreSky()
    end

    refreshLighting()
    Busy = false
end

local oldGui = PlayerGui:FindFirstChild("SCFPS_FarhanStore")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPS_FarhanStore"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(215, 235)
frame.Position = UDim2.new(0, 18, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(40, 130, 255)
stroke.Thickness = 1.4
stroke.Parent = frame

local starLayer = Instance.new("Frame")
starLayer.BackgroundTransparency = 1
starLayer.ClipsDescendants = true
starLayer.Size = UDim2.new(1, -8, 1, -8)
starLayer.Position = UDim2.fromOffset(4, 4)
starLayer.ZIndex = 1
starLayer.Parent = frame

local stars = {}

for i = 1, 17 do
    local star = Instance.new("TextLabel")
    star.BackgroundTransparency = 1
    star.Text = "✦"
    star.TextColor3 = Color3.fromRGB(55, 115, 210)
    star.TextTransparency = 0.4
    star.TextSize = math.random(7, 12)
    star.Size = UDim2.fromOffset(14, 14)
    star.Position = UDim2.new(math.random(), 0, math.random(), 0)
    star.ZIndex = 1
    star.Parent = starLayer

    stars[#stars + 1] = {
        label = star,
        speed = 0.025 + math.random() * 0.06
    }
end

local function setFont(obj)
    if SCFont then
        pcall(function()
            obj.FontFace = SCFont
        end)
    else
        obj.Font = Enum.Font.GothamSemibold
    end
end

local function makeLabel(text, size, pos, fontSize)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 240, 255)
    label.Font = Enum.Font.GothamSemibold
    setFont(label)
    label.TextSize = fontSize or 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = size
    label.Position = pos
    label.ZIndex = 3
    label.Parent = frame

    return label
end

makeLabel(
    "SC FPS  |  FARHAN STORE",
    UDim2.fromOffset(170, 22),
    UDim2.fromOffset(12, 7),
    12
)

local close = Instance.new("TextButton")
close.Text = "X"
close.Font = Enum.Font.GothamBold
setFont(close)
close.TextSize = 12
close.TextColor3 = Color3.fromRGB(255, 100, 100)
close.BackgroundTransparency = 1
close.Size = UDim2.fromOffset(25, 23)
close.Position = UDim2.new(1, -30, 0, 5)
close.ZIndex = 4
close.Parent = frame

local pingLabel = makeLabel(
    "PING: -- ms",
    UDim2.fromOffset(180, 18),
    UDim2.fromOffset(12, 30),
    10
)

local function makeButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(191, 27)
    button.Position = UDim2.fromOffset(12, y)
    button.BackgroundColor3 = Color3.fromRGB(22, 24, 33)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(225, 230, 245)
    button.TextSize = 11
    button.Font = Enum.Font.GothamSemibold
    setFont(button)
    button.ZIndex = 3
    button.Parent = frame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = button

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(45, 70, 105)
    s.Parent = button

    return button
end

local fpsButton = makeButton("FPS BOOST: OFF", 53)
local brightButton = makeButton("FULL BRIGHT: OFF", 85)
local interactButton = makeButton("FAST INTERACT: OFF", 117)
local spreadButton = makeButton("NO SPREAD: OFF", 149)

makeLabel(
    "RIGHT ALT = GUI",
    UDim2.fromOffset(190, 18),
    UDim2.fromOffset(12, 187),
    9
)

local function refreshButtons()
    local buttons = {
        {fpsButton, "FPS BOOST", State.fps},
        {brightButton, "FULL BRIGHT", State.bright},
        {interactButton, "FAST INTERACT", State.interact},
        {spreadButton, "NO SPREAD", State.noSpread}
    }

    for _, item in ipairs(buttons) do
        local button, title, enabled = item[1], item[2], item[3]

        button.Text = title .. ": " .. (enabled and "ON" or "OFF")

        button.BackgroundColor3 = enabled
            and Color3.fromRGB(20, 75, 135)
            or Color3.fromRGB(22, 24, 33)
    end
end

connect(fpsButton.MouseButton1Click, function()
    if Busy then return end

    State.fps = not State.fps
    applyFPS()
    refreshButtons()
end)

connect(brightButton.MouseButton1Click, function()
    State.bright = not State.bright
    refreshLighting()
    refreshButtons()
end)

connect(interactButton.MouseButton1Click, function()
    State.interact = not State.interact
    refreshButtons()
end)

connect(spreadButton.MouseButton1Click, function()
    State.noSpread = not State.noSpread
    refreshButtons()
end)

connect(close.MouseButton1Click, function()
    State.visible = false
    frame.Visible = false
end)

connect(UIS.InputBegan, function(input, processed)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        State.visible = not State.visible
        frame.Visible = State.visible
    end
end)

local dragging = false
local dragStart
local startPosition

connect(frame.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        and input.Position.Y <= frame.AbsolutePosition.Y + 27 then

        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if dragging
        and input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

connect(Workspace.DescendantAdded, function(obj)
    if State.fps then
        task.defer(function()
            if State.fps and obj.Parent then
                optimize(obj)
            end
        end)
    end
end)

connect(PlayerGui.DescendantAdded, function(obj)
    if State.fps then
        task.defer(function()
            if State.fps and obj.Parent then
                applyFont(obj)
            end
        end)
    end
end)

connect(Lighting.ChildAdded, function(obj)
    if State.fps and obj ~= GrayAtmosphere then
        if obj:IsA("Sky")
            or obj:IsA("Atmosphere")
            or obj:IsA("Clouds") then

            task.defer(function()
                if State.fps then
                    applyGraySky()
                end
            end)
        end
    end
end)

connect(RunService.RenderStepped, function(dt)
    if not frame.Visible then return end

    for _, item in ipairs(stars) do
        local pos = item.label.Position

        local x = pos.X.Scale - item.speed * dt
        local y = pos.Y.Scale + item.speed * dt

        if x < -0.1 then x = 1.1 end
        if y > 1.1 then y = -0.1 end

        item.label.Position = UDim2.new(x, 0, y, 0)
    end
end)

task.spawn(function()
    while gui.Parent do
        local ping = "--"

        pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network
                and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats
                and serverStats:FindFirstChild("Data Ping")

            if dataPing then
                ping = tostring(math.floor(dataPing:GetValue() + 0.5))
            end
        end)

        pingLabel.Text = "PING: " .. ping .. " ms"
        task.wait(0.1)
    end
end)

local function cleanup()
    State.fps = false
    State.bright = false

    restoreSaved()
    restoreSky()
    restoreLighting()

    if OriginalDecoration ~= nil then
        pcall(function()
            Terrain.Decoration = OriginalDecoration
        end)
    end

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if gui then
        gui:Destroy()
    end
end

if getgenv then
    getgenv().SCFPS_Cleanup = cleanup
end

refreshButtons()
