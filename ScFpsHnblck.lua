
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SCFont
pcall(function()
    SCFont = Font.fromId(12187372382)
end)

local State = {
    fps = false,
    bright = false,
    interact = false,
    noRecoil = false,
    visible = true
}

local Saved = setmetatable({}, {__mode = "k"})
local OriginalLighting = {}
local OriginalSky = {}
local OriginalDecoration
local GrayAtmosphere
local Busy = false

local function remember(obj, prop)
    if not obj then return end
    Saved[obj] = Saved[obj] or {}
    if Saved[obj][prop] ~= nil then return end

    local ok, value = pcall(function()
        return obj[prop]
    end)

    if ok then Saved[obj][prop] = value end
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
        if obj then
            for prop, value in pairs(props) do
                pcall(function()
                    obj[prop] = value
                end)
            end
        end
    end
    table.clear(Saved)
end

local function applyFont(obj)
    if not State.fps or not SCFont or not obj then return end

    if obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox") then
        change(obj, "FontFace", SCFont)
    end
end

local function matches(obj, words)
    local current = obj
    while current and current ~= Workspace do
        local name = string.lower(current.Name)
        for _, word in ipairs(words) do
            if string.find(name, word, 1, true) then
                return true
            end
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

local function isCar(obj)
    return matches(obj, {"vehicle", "automobile", "carbody", "car_body"})
end

local function isLaser(obj)
    return matches(obj, {
        "laser", "tracer", "bullettrail", "bullet_trail",
        "bullet trail", "muzzle", "shootingeffect", "weaponfx"
    })
end

local function isLeaf(obj)
    return matches(obj, {
        "foliage", "leaves", "leaf", "treeleaves",
        "treetop", "canopy", "bush"
    })
end

local function isFence(obj)
    return matches(obj, {
        "fence", "fencing", "railing", "barbedwire"
    })
end

local function isGunStoreWood(obj)
    return matches(obj, {"gunstore", "gun_store", "gun store"})
        and matches(obj, {"wood", "wooden", "plank", "timber", "log"})
end

local function isCarInterior(obj)
    return isCar(obj) and matches(obj, {
        "interior", "dashboard", "seatinside",
        "carseat", "steeringwheel", "car_interior"
    })
end

local function isFaceTexture(obj)
    if not (obj:IsA("Decal") or obj:IsA("Texture")) then
        return false
    end

    local name = string.lower(obj.Name)
    return name == "face"
        or name == "face decal"
        or name == "facetexture"
end

local function hideObject(obj)
    if obj:IsA("BasePart") then
        change(obj, "LocalTransparencyModifier", 1)
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)
    elseif obj:IsA("Beam") or obj:IsA("Trail")
        or obj:IsA("ParticleEmitter") then
        change(obj, "Enabled", false)
    end
end

local function optimize(obj)
    if not State.fps or not obj or not obj.Parent then return end
    if obj:IsA("ProximityPrompt") then return end

    if isLaser(obj) then
        hideObject(obj)
        return
    end

    if protectedCharacter(obj) then return end

    if isFaceTexture(obj) or isLeaf(obj) or isFence(obj)
        or isGunStoreWood(obj) or isCarInterior(obj) then
        hideObject(obj)
        return
    end

    if obj:IsA("BasePart") then
        change(obj, "CastShadow", false)
        change(obj, "Reflectance", 0)

        if not isCar(obj) then
            change(obj, "Material", Enum.Material.SmoothPlastic)
        end
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)
    elseif obj:IsA("MeshPart") then
        change(obj, "TextureID", "")
    elseif obj:IsA("SpecialMesh") then
        change(obj, "TextureId", "")
    elseif obj:IsA("SurfaceAppearance") then
        for _, prop in ipairs({
            "ColorMap", "NormalMap",
            "RoughnessMap", "MetalnessMap"
        }) do
            change(obj, prop, "")
        end
    elseif obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
        or obj:IsA("BlurEffect") then
        change(obj, "Enabled", false)
    end

    if matches(obj, {"blood", "bloodsplatter", "blood_splatter"}) then
        if obj:IsA("ParticleEmitter") then
            change(obj, "Enabled", false)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            change(obj, "Transparency", 1)
        end
    end
end

local function saveLighting()
    for _, prop in ipairs({
        "Brightness", "ClockTime", "ExposureCompensation",
        "GlobalShadows", "FogEnd", "Ambient", "OutdoorAmbient"
    }) do
        if OriginalLighting[prop] == nil then
            pcall(function()
                OriginalLighting[prop] = Lighting[prop]
            end)
        end
    end
end

local function applyBright()
    saveLighting()
    pcall(function()
        Lighting.Brightness = 3
        Lighting.ExposureCompensation = 0.5
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(170, 170, 170)
        Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
    end)
end

local function restoreBright()
    for prop, value in pairs(OriginalLighting) do
        pcall(function()
            Lighting[prop] = value
        end)
    end
end

local function applyGraySky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            if OriginalSky[obj] == nil then
                OriginalSky[obj] = obj.Parent
            end
            pcall(function()
                obj.Parent = nil
            end)
        end
    end

    if not GrayAtmosphere then
        GrayAtmosphere = Instance.new("Atmosphere")
        GrayAtmosphere.Name = "SCFPS_GrayAtmosphere"
    end

    GrayAtmosphere.Color = Color3.fromRGB(145, 145, 145)
    GrayAtmosphere.Decay = Color3.fromRGB(90, 90, 90)
    GrayAtmosphere.Density = 0.3
    GrayAtmosphere.Glare = 0
    GrayAtmosphere.Haze = 0
    GrayAtmosphere.Parent = Lighting
end

local function restoreSky()
    for obj, parent in pairs(OriginalSky) do
        if obj then
            pcall(function()
                obj.Parent = parent or Lighting
            end)
        end
    end
    table.clear(OriginalSky)

    if GrayAtmosphere then
        GrayAtmosphere:Destroy()
        GrayAtmosphere = nil
    end
end

local function applyFPS()
    if Busy then return end
    Busy = true

    if State.fps then
        if OriginalDecoration == nil then
            pcall(function()
                OriginalDecoration = Workspace.Terrain.Decoration
            end)
        end

        applyGraySky()

        pcall(function()
            Workspace.Terrain.Decoration = false
        end)

        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimize(obj)
        end

        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            applyFont(obj)
        end
    else
        restoreSaved()
        restoreSky()

        if OriginalDecoration ~= nil then
            pcall(function()
                Workspace.Terrain.Decoration = OriginalDecoration
            end)
        end
    end

    Busy = false
end

Workspace.DescendantAdded:Connect(function(obj)
    if State.fps then
        task.defer(function()
            if State.fps and obj.Parent then
                optimize(obj)
            end
        end)
    end
end)

PlayerGui.DescendantAdded:Connect(function(obj)
    if State.fps then
        task.defer(function()
            if State.fps and obj.Parent then
                applyFont(obj)
            end
        end)
    end
end)

Lighting.ChildAdded:Connect(function(obj)
    if State.fps and obj:IsA("Sky") then
        task.defer(function()
            if State.fps then applyGraySky() end
        end)
    end
end)

local oldGui = PlayerGui:FindFirstChild("SCFPS_FarhanStore")
if oldGui then oldGui:Destroy() end

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
    table.insert(stars, {
        label = star,
        speed = 0.025 + math.random() * 0.06
    })
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

makeLabel("SC FPS  |  FARHAN STORE",
    UDim2.fromOffset(170, 22), UDim2.fromOffset(12, 7), 12)

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

local pingLabel = makeLabel("PING: -- ms",
    UDim2.fromOffset(180, 18), UDim2.fromOffset(12, 30), 10)

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
local recoilButton = makeButton("NO RECOIL: OFF", 149)

makeLabel("RIGHT ALT = GUI",
    UDim2.fromOffset(190, 18), UDim2.fromOffset(12, 187), 9)

local function refreshButtons()
    fpsButton.Text = "FPS BOOST: " .. (State.fps and "ON" or "OFF")
    fpsButton.BackgroundColor3 = State.fps
        and Color3.fromRGB(20, 75, 135)
        or Color3.fromRGB(22, 24, 33)

    brightButton.Text = "FULL BRIGHT: " .. (State.bright and "ON" or "OFF")
    brightButton.BackgroundColor3 = State.bright
        and Color3.fromRGB(20, 75, 135)
        or Color3.fromRGB(22, 24, 33)

    interactButton.Text = "FAST INTERACT: " .. (State.interact and "ON" or "OFF")
    interactButton.BackgroundColor3 = State.interact
        and Color3.fromRGB(20, 75, 135)
        or Color3.fromRGB(22, 24, 33)

    recoilButton.Text = "NO RECOIL: " .. (State.noRecoil and "ON" or "OFF")
    recoilButton.BackgroundColor3 = State.noRecoil
        and Color3.fromRGB(20, 75, 135)
        or Color3.fromRGB(22, 24, 33)
end

fpsButton.MouseButton1Click:Connect(function()
    State.fps = not State.fps
    applyFPS()
    refreshButtons()
end)

brightButton.MouseButton1Click:Connect(function()
    State.bright = not State.bright
    if State.bright then
        applyBright()
    else
        restoreBright()
    end
    refreshButtons()
end)

interactButton.MouseButton1Click:Connect(function()
    State.interact = not State.interact
    refreshButtons()
end)

recoilButton.MouseButton1Click:Connect(function()
    State.noRecoil = not State.noRecoil
    refreshButtons()
end)

close.MouseButton1Click:Connect(function()
    State.visible = false
    frame.Visible = false
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        State.visible = not State.visible
        frame.Visible = State.visible
    end
end)

local dragging = false
local dragStart
local startPosition

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        and input.Position.Y <= frame.AbsolutePosition.Y + 27 then
        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function(dt)
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
            local serverStats = network and network:FindFirstChild("ServerStatsItem")
            local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")

            if dataPing then
                ping = tostring(math.floor(dataPing:GetValue() + 0.5))
            end
        end)

        pingLabel.Text = "PING: " .. ping .. " ms"
        task.wait(0.1)
    end
end)

refreshButtons()
