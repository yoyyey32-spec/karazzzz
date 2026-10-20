
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Terrain = Workspace.Terrain

local FAST_HOLD = 0.5

local SCFont
pcall(function()
    SCFont = Font.fromId(12187372382)
end)

if getgenv and type(getgenv().SCFPS_Cleanup) == "function" then
    pcall(getgenv().SCFPS_Cleanup)
end

local State = {
    fps = false,
    bright = false,
    interact = false,
    noSpread = false,
    visible = true
}

local Saved = {}
local Detached = {}
local SkySaved = {}
local BrightSaved = {}
local PromptSaved = {}
local Connections = {}

local DecorationSaved
local GrayAtmosphere
local Busy = false

local function connect(signal, fn)
    local c = signal:Connect(fn)
    Connections[#Connections + 1] = c
    return c
end

local function change(obj, prop, value)
    if not obj then return end

    local data = Saved[obj]

    if not data then
        data = {}
        Saved[obj] = data
    end

    if data[prop] == nil then
        local ok, old = pcall(function()
            return obj[prop]
        end)

        if ok then
            data[prop] = old
        end
    end

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

    for obj, parent in pairs(Detached) do
        pcall(function()
            obj.Parent = parent
        end)
    end

    table.clear(Detached)
end

local function detach(obj)
    if not obj or not obj.Parent then return end

    if Detached[obj] == nil then
        Detached[obj] = obj.Parent
    end

    obj.Parent = nil
end

local function hasName(obj, words)
    if not obj then return false end

    local name = obj.Name:lower()

    for _, word in ipairs(words) do
        if name:find(word, 1, true) then
            return true
        end
    end

    return false
end

local function matches(obj, words)
    local current = obj

    while current and current ~= Workspace do
        if hasName(current, words) then
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
        "rifle", "shotgun", "revolver",
        "firearm", "magazine", "handgun",
        "ak47", "ak-47", "uzi",
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

local function isStore(obj)
    return matches(obj, {
        "gunstore", "gun_store", "gun store",
        "gunshop", "gun_shop", "gun shop",
        "weaponstore", "weapon_store", "weapon shop"
    })
end

local function isWood(obj)
    if not isStore(obj) then return false end

    if hasName(obj, {
        "wood", "wooden", "plank",
        "timber", "board", "shelf", "counter"
    }) then
        return true
    end

    return obj:IsA("BasePart") and (
        obj.Material == Enum.Material.Wood
        or obj.Material == Enum.Material.WoodPlanks
    )
end

local function isLeaf(obj)
    return matches(obj, {
        "foliage", "leaves", "leaf",
        "treetop", "canopy", "bush"
    })
end

local function isBlood(obj)
    return matches(obj, {
        "blood", "bloodsplatter",
        "blood_splatter", "bleeding"
    })
end

local function isFlash(obj)
    return matches(obj, {
        "muzzle", "gunflash", "gun_flash",
        "shootingeffect", "weaponfx",
        "bullettrail", "bullet_trail",
        "tracer", "gunsmoke"
    })
end

local function isEffect(obj)
    return obj:IsA("ParticleEmitter")
        or obj:IsA("Beam")
        or obj:IsA("Trail")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
end

local function hide(obj)
    if obj:IsA("BasePart") then
        change(obj, "LocalTransparencyModifier", 1)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)

    elseif isEffect(obj) then
        change(obj, "Enabled", false)

    elseif obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
        change(obj, "Enabled", false)
    end
end

local function removeTexture(obj)
    if obj:IsA("MeshPart") then
        change(obj, "TextureID", "")

    elseif obj:IsA("SpecialMesh") then
        change(obj, "TextureId", "")

    elseif obj:IsA("SurfaceAppearance") then
        detach(obj)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)
    end
end

local function blackGun(obj)
    if obj:IsA("BasePart") then
        change(obj, "CastShadow", false)
        change(obj, "Reflectance", 0)
        change(obj, "Material", Enum.Material.SmoothPlastic)
        change(obj, "Color", Color3.fromRGB(8, 8, 9))

        if obj:IsA("MeshPart") then
            change(obj, "TextureID", "")
        end

    elseif obj:IsA("SpecialMesh") then
        change(obj, "TextureId", "")
        change(
            obj,
            "VertexColor",
            Vector3.new(0.04, 0.04, 0.04)
        )

    elseif obj:IsA("SurfaceAppearance") then
        detach(obj)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)
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

    if isBlood(obj) or isFlash(obj) then
        hide(obj)
        return
    end

    if isEffect(obj) then
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

    if isWood(obj) or isLeaf(obj) then
        hide(obj)
        return
    end

    if obj:IsA("BasePart") then
        change(obj, "CastShadow", false)
        change(obj, "Reflectance", 0)
        change(obj, "Material", Enum.Material.SmoothPlastic)

        if isCar(obj) then
            change(obj, "Color", Color3.fromRGB(85, 85, 85))
        end
    end

    removeTexture(obj)
end

local function saveBright()
    for _, prop in ipairs({
        "Brightness", "ExposureCompensation",
        "GlobalShadows", "FogEnd",
        "Ambient", "OutdoorAmbient"
    }) do
        if BrightSaved[prop] == nil then
            pcall(function()
                BrightSaved[prop] = Lighting[prop]
            end)
        end
    end
end

local function restoreBright()
    for prop, value in pairs(BrightSaved) do
        pcall(function()
            Lighting[prop] = value
        end)
    end
end

local function applyBright()
    saveBright()

    Lighting.Brightness = 3
    Lighting.ExposureCompensation = 0.5
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    Lighting.Ambient = Color3.fromRGB(170, 170, 170)
    Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
end

local function applyGraySky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj ~= GrayAtmosphere and (
            obj:IsA("Sky") or obj:IsA("Atmosphere")
        ) then
            if SkySaved[obj] == nil then
                SkySaved[obj] = obj.Parent
            end

            obj.Parent = nil

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
        GrayAtmosphere.Name = "SCFPS_GraySky"
    end

    GrayAtmosphere.Color = Color3.fromRGB(78, 78, 82)
    GrayAtmosphere.Decay = Color3.fromRGB(48, 48, 52)
    GrayAtmosphere.Density = 0.38
    GrayAtmosphere.Glare = 0
    GrayAtmosphere.Haze = 0
    GrayAtmosphere.Parent = Lighting
end

local function restoreSky()
    if GrayAtmosphere then
        GrayAtmosphere:Destroy()
        GrayAtmosphere = nil
    end

    for obj, parent in pairs(SkySaved) do
        pcall(function()
            obj.Parent = parent
        end)
    end

    table.clear(SkySaved)
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
        if DecorationSaved == nil then
            pcall(function()
                DecorationSaved = Terrain.Decoration
            end)
        end

        pcall(function()
            Terrain.Decoration = false
        end)

        applyGraySky()

        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimize(obj)
        end

        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            applyFont(obj)
        end
    else
        restoreSaved()
        restoreSky()

        if DecorationSaved ~= nil then
            pcall(function()
                Terrain.Decoration = DecorationSaved
            end)
        end
    end

    Busy = false
end

local function fastPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end

    if PromptSaved[prompt] == nil then
        PromptSaved[prompt] = prompt.HoldDuration
    end

    local original = PromptSaved[prompt]

    if original > FAST_HOLD then
        pcall(function()
            prompt.HoldDuration = FAST_HOLD
        end)
    end
end

local function restorePrompts()
    for prompt, duration in pairs(PromptSaved) do
        pcall(function()
            prompt.HoldDuration = duration
        end)
    end

    table.clear(PromptSaved)
end

local function applyInteract()
    if State.interact then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                fastPrompt(obj)
            end
        end
    else
        restorePrompts()
    end
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
        local button = item[1]
        local title = item[2]
        local enabled = item[3]

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

    if State.bright then
        applyBright()
    else
        restoreBright()
    end

    refreshButtons()
end)

connect(interactButton.MouseButton1Click, function()
    State.interact = not State.interact
    applyInteract()
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

connect(UIS.InputBegan, function(input)
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
    task.defer(function()
        if not obj.Parent then return end

        if State.fps then
            optimize(obj)
        end

        if State.interact and obj:IsA("ProximityPrompt") then
            fastPrompt(obj)
        end
    end)
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
        if obj:IsA("Sky") or obj:IsA("Atmosphere") then
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
    State.interact = false

    restorePrompts()
    restoreSaved()
    restoreSky()

    if State.bright then
        restoreBright()
    end

    if DecorationSaved ~= nil then
        pcall(function()
            Terrain.Decoration = DecorationSaved
        end)
    end

    for _, c in ipairs(Connections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    gui:Destroy()
end

if getgenv then
    getgenv().SCFPS_Cleanup = cleanup
end

refreshButtons()
