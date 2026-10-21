
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local ENV = getgenv and getgenv() or _G

if type(ENV.SCFPS_Cleanup) == "function" then
    pcall(ENV.SCFPS_Cleanup)
end

local Alive = true
local Busy = false

local State = {
    FPS = false,
    Bright = false,
    Interact = false,
    Recoil = false,
    Spread = false,
    Visible = true
}

local Connections = {}
local VisualSaved = {}
local Detached = {}
local SkySaved = {}
local PromptSaved = {}
local RecoilSaved = {}
local SpreadSaved = {}
local BrightSaved = nil
local DecorationSaved = nil
local QualitySaved = nil

local BlackSky
local BlackAtmosphere
local Gui
local Main
local Buttons = {}
local Stars = {}

local RecoilKeys = {
    "Recoil", "RecoilAmount", "CameraRecoil",
    "CameraShake", "Kick", "Kickback",
    "VerticalRecoil", "HorizontalRecoil",
    "RecoilX", "RecoilY", "GunRecoil",
    "WeaponRecoil", "AimRecoil",
    "ShakeAmount", "ShakeIntensity"
}

local SpreadKeys = {
    "Spread", "SpreadX", "SpreadY",
    "MinSpread", "MaxSpread", "HipSpread",
    "AimSpread", "SpreadAmount", "Bloom"
}

local FontFace

pcall(function()
    FontFace = Font.fromId(12187372382)
end)

local function bind(signal, callback)
    local c = signal:Connect(callback)
    table.insert(Connections, c)
    return c
end

local function set(obj, prop, value)
    if not obj then return end

    local ok, old = pcall(function()
        return obj[prop]
    end)

    if not ok then return end

    if not VisualSaved[obj] then
        VisualSaved[obj] = {}
    end

    if VisualSaved[obj][prop] == nil then
        VisualSaved[obj][prop] = old
    end

    pcall(function()
        obj[prop] = value
    end)
end

local function detach(obj)
    if not obj or not obj.Parent then return end

    if Detached[obj] == nil then
        Detached[obj] = obj.Parent
    end

    pcall(function()
        obj.Parent = nil
    end)
end

local function restoreVisual()
    for obj, props in pairs(VisualSaved) do
        for prop, value in pairs(props) do
            pcall(function()
                obj[prop] = value
            end)
        end
    end

    for obj, parent in pairs(Detached) do
        pcall(function()
            obj.Parent = parent
        end)
    end

    table.clear(VisualSaved)
    table.clear(Detached)
end

local function hasName(obj, words)
    local name = string.lower(obj.Name)

    for _, word in ipairs(words) do
        if string.find(name, word, 1, true) then
            return true
        end
    end

    return false
end

local function ancestorHas(obj, words, depth)
    local current = obj

    for _ = 1, depth or 6 do
        if not current then break end

        if hasName(current, words) then
            return true
        end

        current = current.Parent
    end

    return false
end

local function getTool(obj)
    local current = obj

    while current and current ~= Workspace do
        if current:IsA("Tool") then
            return current
        end

        current = current.Parent
    end

    return nil
end

local function ownCharacter(obj)
    local char = Player.Character

    return char and (
        obj == char or obj:IsDescendantOf(char)
    )
end

local function isFence(obj)
    return ancestorHas(obj, {
        "fence", "chainlink", "chain_link",
        "railing", "ironfence", "metal_fence",
        "grate"
    }, 6)
end

local function isVehicle(obj)
    return ancestorHas(obj, {
        "vehicle", "automobile", "truck",
        "carbody", "car_model", "vehicles"
    }, 6)
end

local function isWeapon(obj)
    if getTool(obj) then return true end

    return ancestorHas(obj, {
        "g17", "glock", "drum", "pistol",
        "rifle", "shotgun", "revolver",
        "firearm", "handgun", "ak47",
        "ak-47", "uzi", "gunmodel",
        "gun_model", "weaponmodel",
        "weapon_model", "magazine"
    }, 6)
end

local function isFlash(obj)
    return ancestorHas(obj, {
        "muzzle", "flash", "gunfire",
        "gun_fire", "gunshot", "gun_shot",
        "barrelfx", "barrel_fx", "shootfx",
        "shoot_fx", "fireeffect", "fire_effect",
        "tracer", "bullettrail", "bullet_trail",
        "bulletbeam", "bullet_beam",
        "gunsmoke", "gun_smoke",
        "shellparticle", "laser",
        "bulletfx", "bullet_fx",
        "impactfx", "impact_fx"
    }, 5)
end

local function isBlood(obj)
    return ancestorHas(obj, {
        "blood", "gore", "bleed",
        "hitblood", "bloodfx", "blood_fx"
    }, 5)
end

local function isEffect(obj)
    return obj:IsA("ParticleEmitter")
        or obj:IsA("Beam")
        or obj:IsA("Trail")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
end

local function isLight(obj)
    return obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight")
end

local function disableEffect(obj)
    if isEffect(obj) or isLight(obj) then
        set(obj, "Enabled", false)

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        set(obj, "Transparency", 1)

    elseif obj:IsA("BasePart") then
        set(obj, "Transparency", 1)
        set(obj, "CastShadow", false)
    end
end

local function stripTexture(obj)
    if obj:IsA("SurfaceAppearance") then
        detach(obj)

    elseif obj:IsA("MeshPart") then
        set(obj, "TextureID", "")

    elseif obj:IsA("SpecialMesh") then
        set(obj, "TextureId", "")

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        set(obj, "Transparency", 1)
    end
end

local function isStoreWood(obj)
    if not obj:IsA("BasePart") then return false end
    if isWeapon(obj) or isFence(obj) then return false end

    if not ancestorHas(obj, {
        "gunstore", "gun_store", "gun store",
        "gunshop", "gun_shop", "weaponshop",
        "weapon_shop"
    }, 10) then
        return false
    end

    return obj.Material == Enum.Material.Wood
        or obj.Material == Enum.Material.WoodPlanks
        or hasName(obj, {
            "wood", "plank", "timber",
            "shelf", "counter", "board"
        })
end

local function potatoPart(obj, weapon)
    if not obj:IsA("BasePart") then return end

    set(obj, "CastShadow", false)
    set(obj, "Reflectance", 0)
    set(obj, "Material", Enum.Material.SmoothPlastic)

    if weapon then
        set(obj, "Color", Color3.fromRGB(8, 8, 8))
    else
        local c = obj.Color

        local gray = (
            c.R * 0.299 +
            c.G * 0.587 +
            c.B * 0.114
        ) * 255

        gray = math.floor(gray / 64) * 64
        gray = math.clamp(gray, 32, 160)

        set(obj, "Color", Color3.fromRGB(
            gray, gray, gray
        ))
    end

    if obj:IsA("MeshPart") then
        set(obj, "TextureID", "")
    end
end

local function optimize(obj)
    if not Alive or not State.FPS then return end
    if not obj or not obj.Parent then return end

    if obj:IsA("ProximityPrompt")
        or obj:IsA("ClickDetector")
        or obj:IsA("Sound") then
        return
    end

    local tool = getTool(obj)

    if isFlash(obj) or isBlood(obj) then
        disableEffect(obj)
        return
    end

    if tool then
        if isEffect(obj) or isLight(obj) then
            disableEffect(obj)
            return
        end

        if obj:IsA("SurfaceAppearance")
            or obj:IsA("SpecialMesh")
            or obj:IsA("Decal")
            or obj:IsA("Texture") then
            stripTexture(obj)
            return
        end

        if obj:IsA("BasePart") then
            potatoPart(obj, true)
        end

        return
    end

    if ownCharacter(obj) then
        if isEffect(obj) then
            disableEffect(obj)
        end
        return
    end

    if isFence(obj) then
        if obj:IsA("BasePart") then
            set(obj, "CastShadow", false)
            set(obj, "Reflectance", 0)
        end
        return
    end

    if isStoreWood(obj) then
        set(obj, "Transparency", 1)
        set(obj, "CastShadow", false)
        return
    end

    if isEffect(obj) then
        disableEffect(obj)
        return
    end

    if isLight(obj) then
        return
    end

    if obj:IsA("BasePart") then
        potatoPart(obj, isWeapon(obj))

        if isVehicle(obj) then
            set(obj, "CastShadow", false)
        end
    end

    stripTexture(obj)
end

local function optimizeLighting()
    set(Lighting, "GlobalShadows", false)
    set(Lighting, "EnvironmentDiffuseScale", 0)
    set(Lighting, "EnvironmentSpecularScale", 0)
    set(Lighting, "ShadowSoftness", 0)
end

local function optimizeTerrain()
    if not Terrain then return end

    set(Terrain, "WaterWaveSize", 0)
    set(Terrain, "WaterWaveSpeed", 0)
    set(Terrain, "WaterReflectance", 0)
    set(Terrain, "WaterTransparency", 1)

    if DecorationSaved == nil then
        local ok, value = pcall(function()
            return Terrain.Decoration
        end)

        if ok then
            DecorationSaved = value
        end
    end

    pcall(function()
        Terrain.Decoration = false
    end)

    for _, obj in ipairs(Terrain:GetChildren()) do
        if obj:IsA("Clouds") then
            set(obj, "Enabled", false)
        end
    end
end

local function setLowQuality()
    pcall(function()
        local settingsObject = settings()
        local rendering = settingsObject.Rendering

        if QualitySaved == nil then
            QualitySaved = rendering.QualityLevel
        end

        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function restoreQuality()
    if QualitySaved ~= nil then
        pcall(function()
            settings().Rendering.QualityLevel = QualitySaved
        end)

        QualitySaved = nil
    end
end

local function blackSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj ~= BlackSky and obj ~= BlackAtmosphere then
            if obj:IsA("Sky") or obj:IsA("Atmosphere") then
                if SkySaved[obj] == nil then
                    SkySaved[obj] = obj.Parent
                end

                obj.Parent = nil

            elseif obj:IsA("PostEffect") then
                set(obj, "Enabled", false)
            end
        end
    end

    if not BlackSky then
        BlackSky = Instance.new("Sky")
        BlackSky.Name = "SCFPS_BlackSky"
    end

    BlackSky.CelestialBodiesShown = false
    BlackSky.StarCount = 0
    BlackSky.SunAngularSize = 0
    BlackSky.MoonAngularSize = 0
    BlackSky.Parent = Lighting

    if not BlackAtmosphere then
        BlackAtmosphere = Instance.new("Atmosphere")
        BlackAtmosphere.Name = "SCFPS_BlackAtmosphere"
    end

    BlackAtmosphere.Color = Color3.new(0, 0, 0)
    BlackAtmosphere.Decay = Color3.new(0, 0, 0)
    BlackAtmosphere.Density = 1
    BlackAtmosphere.Haze = 10
    BlackAtmosphere.Glare = 0
    BlackAtmosphere.Parent = Lighting
end

local function restoreSky()
    if BlackSky then
        BlackSky:Destroy()
        BlackSky = nil
    end

    if BlackAtmosphere then
        BlackAtmosphere:Destroy()
        BlackAtmosphere = nil
    end

    for obj, parent in pairs(SkySaved) do
        pcall(function()
            obj.Parent = parent
        end)
    end

    table.clear(SkySaved)
end

local function applyFPS()
    if not State.FPS then return end

    optimizeLighting()
    optimizeTerrain()
    setLowQuality()

    for _, obj in ipairs(Workspace:GetDescendants()) do
        optimize(obj)
    end

    blackSky()
end

local function restoreFPS()
    restoreVisual()
    restoreSky()
    restoreQuality()

    if Terrain and DecorationSaved ~= nil then
        pcall(function()
            Terrain.Decoration = DecorationSaved
        end)
    end

    DecorationSaved = nil
end

local function applyBright()
    if not BrightSaved then
        BrightSaved = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            ExposureCompensation = Lighting.ExposureCompensation
        }
    end

    Lighting.Brightness = 3
    Lighting.ClockTime = 14
    Lighting.Ambient = Color3.fromRGB(170, 170, 170)
    Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
    Lighting.ExposureCompensation = 0.15
end

local function restoreBright()
    if not BrightSaved then return end

    for prop, value in pairs(BrightSaved) do
        pcall(function()
            Lighting[prop] = value
        end)
    end

    BrightSaved = nil
end

local function fastPrompt(prompt)
    if not prompt:IsA("ProximityPrompt") then return end

    if PromptSaved[prompt] == nil then
        PromptSaved[prompt] = prompt.HoldDuration
    end

    pcall(function()
        prompt.HoldDuration = 0.1
    end)
end

local function applyInteract()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            fastPrompt(obj)
        end
    end
end

local function restoreInteract()
    for prompt, duration in pairs(PromptSaved) do
        pcall(function()
            prompt.HoldDuration = duration
        end)
    end

    table.clear(PromptSaved)
end

local function getSettings(tool)
    if not tool or not tool:IsA("Tool") then
        return nil
    end

    local setting = tool:FindFirstChild("Setting")

    if not setting or not setting:IsA("ModuleScript") then
        return nil
    end

    local ok, module = pcall(require, setting)

    if not ok or type(module) ~= "table" then
        return nil
    end

    return module
end

local function applyValues(module, keys, saved)
    if not saved[module] then
        saved[module] = {}
    end

    for _, key in ipairs(keys) do
        local current = module[key]

        if type(current) == "number" then
            if saved[module][key] == nil then
                saved[module][key] = current
            end

            module[key] = 0.1
        end
    end
end

local function restoreValues(saved)
    for module, props in pairs(saved) do
        for key, value in pairs(props) do
            pcall(function()
                module[key] = value
            end)
        end
    end

    table.clear(saved)
end

local function applyGun(tool)
    if not State.Recoil and not State.Spread then
        return
    end

    local module = getSettings(tool)
    if not module then return end

    if State.Recoil then
        applyValues(module, RecoilKeys, RecoilSaved)
    end

    if State.Spread then
        applyValues(module, SpreadKeys, SpreadSaved)
    end
end

local function applyAllGuns()
    if not State.Recoil and not State.Spread then
        return
    end

    local character = Player.Character
    local backpack = Player:FindFirstChild("Backpack")

    if character then
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Tool") then
                applyGun(obj)
            end
        end
    end

    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            if obj:IsA("Tool") then
                applyGun(obj)
            end
        end
    end
end

local function makeText(obj, size)
    obj.TextSize = size
    obj.TextColor3 = Color3.fromRGB(225, 230, 240)

    if FontFace then
        obj.FontFace = FontFace
    else
        obj.Font = Enum.Font.Gotham
    end
end

Gui = Instance.new("ScreenGui")
Gui.Name = "SCFPS_FarhanStore"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(215, 260)
Main.Position = UDim2.new(0, 20, 0.5, -130)
Main.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 130, 255)
MainStroke.Thickness = 1.4
MainStroke.Parent = Main

for i = 1, 17 do
    local star = Instance.new("Frame")
    star.Name = "Star" .. i

    star.Size = UDim2.fromOffset(
        i % 3 == 0 and 3 or 2,
        i % 3 == 0 and 3 or 2
    )

    star.Position = UDim2.new(
        (i * 37 % 100) / 100, 0,
        (i * 19 % 100) / 100, 0
    )

    star.BackgroundColor3 = Color3.fromRGB(70, 155, 255)
    star.BackgroundTransparency = 0.25 + (i % 4) * 0.12
    star.BorderSizePixel = 0
    star.ZIndex = 1
    star.Parent = Main

    table.insert(Stars, {
        Object = star,
        Speed = 0.025 + (i % 5) * 0.012
    })
end

local Top = Instance.new("Frame")
Top.Name = "TopBar"
Top.Size = UDim2.new(1, 0, 0, 32)
Top.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
Top.BorderSizePixel = 0
Top.ZIndex = 2
Top.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = Top

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -35, 1, 0)
Title.Position = UDim2.fromOffset(9, 0)
Title.BackgroundTransparency = 1
Title.Text = "SC FPS | FARHAN STORE"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = Top
makeText(Title, 12)
Title.TextColor3 = Color3.fromRGB(140, 200, 255)

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(25, 25)
Close.Position = UDim2.new(1, -28, 0, 3)
Close.BackgroundTransparency = 1
Close.Text = "X"
Close.ZIndex = 3
Close.Parent = Top
makeText(Close, 13)

local function makeButton(label, order)
    local button = Instance.new("TextButton")
    button.Name = label:gsub("%s+", "") .. "Button"
    button.Size = UDim2.new(1, -18, 0, 27)

    button.Position = UDim2.new(
        0, 9,
        0, 39 + (order - 1) * 32
    )

    button.BackgroundColor3 = Color3.fromRGB(19, 21, 27)
    button.BorderSizePixel = 0
    button.Text = label .. ": OFF"
    button.ZIndex = 3
    button.Parent = Main

    makeText(button, 12)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(45, 130, 255)
    stroke.Transparency = 0.35
    stroke.Parent = button

    return button
end

Buttons.FPS = makeButton("FPS BOOST", 1)
Buttons.Bright = makeButton("FULL BRIGHT", 2)
Buttons.Interact = makeButton("FAST INTERACT", 3)
Buttons.Recoil = makeButton("NO RECOIL", 4)
Buttons.Spread = makeButton("LOW SPREAD", 5)

local Ping = Instance.new("TextLabel")
Ping.Size = UDim2.new(1, -16, 0, 17)
Ping.Position = UDim2.new(0, 8, 1, -20)
Ping.BackgroundTransparency = 1
Ping.Text = "PING: -- ms"
Ping.TextXAlignment = Enum.TextXAlignment.Left
Ping.ZIndex = 3
Ping.Parent = Main
makeText(Ping, 10)

local function buttonState(button, label, enabled)
    button.Text = label .. (enabled and ": ON" or ": OFF")

    button.TextColor3 = enabled
        and Color3.fromRGB(120, 210, 255)
        or Color3.fromRGB(225, 225, 225)
end

local function refresh()
    buttonState(Buttons.FPS, "FPS BOOST", State.FPS)
    buttonState(Buttons.Bright, "FULL BRIGHT", State.Bright)
    buttonState(Buttons.Interact, "FAST INTERACT", State.Interact)
    buttonState(Buttons.Recoil, "NO RECOIL", State.Recoil)
    buttonState(Buttons.Spread, "LOW SPREAD", State.Spread)
end

bind(Buttons.FPS.MouseButton1Click, function()
    if Busy then return end
    Busy = true

    State.FPS = not State.FPS

    if State.FPS then
        applyFPS()
    else
        restoreFPS()
    end

    refresh()
    Busy = false
end)

bind(Buttons.Bright.MouseButton1Click, function()
    State.Bright = not State.Bright

    if State.Bright then
        applyBright()
    else
        restoreBright()
    end

    refresh()
end)

bind(Buttons.Interact.MouseButton1Click, function()
    State.Interact = not State.Interact

    if State.Interact then
        applyInteract()
    else
        restoreInteract()
    end

    refresh()
end)

bind(Buttons.Recoil.MouseButton1Click, function()
    State.Recoil = not State.Recoil

    if State.Recoil then
        applyAllGuns()
    else
        restoreValues(RecoilSaved)
    end

    refresh()
end)

bind(Buttons.Spread.MouseButton1Click, function()
    State.Spread = not State.Spread

    if State.Spread then
        applyAllGuns()
    else
        restoreValues(SpreadSaved)
    end

    refresh()
end)

bind(Close.MouseButton1Click, function()
    State.Visible = false
    Main.Visible = false
end)

local Dragging = false
local DragStart
local StartPos

bind(Top.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPos = Main.Position
    end
end)

bind(UIS.InputChanged, function(input)
    if not Dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - DragStart

        Main.Position = UDim2.new(
            StartPos.X.Scale,
            StartPos.X.Offset + delta.X,
            StartPos.Y.Scale,
            StartPos.Y.Offset + delta.Y
        )
    end
end)

bind(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = false
    end
end)

bind(UIS.InputBegan, function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightAlt then
        State.Visible = not State.Visible
        Main.Visible = State.Visible

    elseif input.KeyCode == Enum.KeyCode.X then
        State.Visible = false
        Main.Visible = false
    end
end)

local function watchTool(obj)
    if not obj:IsA("Tool") then return end

    task.defer(function()
        if not Alive or not obj.Parent then return end

        applyGun(obj)

        if State.FPS then
            for _, part in ipairs(obj:GetDescendants()) do
                optimize(part)
            end
        end
    end)
end

local function watchCharacter(character)
    bind(character.ChildAdded, watchTool)

    if State.Recoil or State.Spread then
        task.defer(applyAllGuns)
    end

    if State.FPS then
        task.defer(function()
            if not Alive then return end

            for _, obj in ipairs(character:GetDescendants()) do
                optimize(obj)
            end
        end)
    end
end

if Player.Character then
    watchCharacter(Player.Character)
end

bind(Player.CharacterAdded, watchCharacter)

local Backpack = Player:WaitForChild("Backpack")
bind(Backpack.ChildAdded, watchTool)

bind(Workspace.DescendantAdded, function(obj)
    if State.FPS then
        task.defer(function()
            if Alive and obj.Parent then
                optimize(obj)
            end
        end)
    end

    if State.Interact and obj:IsA("ProximityPrompt") then
        task.defer(function()
            if Alive and obj.Parent then
                fastPrompt(obj)
            end
        end)
    end
end)

bind(Lighting.ChildAdded, function(obj)
    if not State.FPS then return end

    task.defer(function()
        if not Alive or not obj.Parent then return end

        if obj:IsA("Sky") or obj:IsA("Atmosphere") then
            if obj ~= BlackSky and obj ~= BlackAtmosphere then
                if SkySaved[obj] == nil then
                    SkySaved[obj] = obj.Parent
                end

                obj.Parent = nil
            end

        elseif obj:IsA("PostEffect") then
            set(obj, "Enabled", false)
        end
    end)
end)

local PingClock = 0
local GunClock = 0
local FlashClock = 0

local function suppressGunFX()
    local character = Player.Character
    if not character then return end

    for _, obj in ipairs(character:GetDescendants()) do
        if getTool(obj) then
            if isEffect(obj) or isLight(obj) then
                disableEffect(obj)

            elseif isFlash(obj) then
                disableEffect(obj)
            end
        end
    end
end

bind(RunService.Heartbeat, function(dt)
    PingClock += dt
    GunClock += dt
    FlashClock += dt

    if PingClock >= 0.1 then
        PingClock = 0

        local ok, value = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)

        if ok and type(value) == "number" then
            Ping.Text = "PING: "
                .. math.floor(value + 0.5)
                .. " ms"
        end
    end

    if GunClock >= 0.5 then
        GunClock = 0

        if State.Recoil or State.Spread then
            applyAllGuns()
        end
    end

    if FlashClock >= 0.1 then
        FlashClock = 0

        if State.FPS then
            suppressGunFX()
        end
    end
end)

bind(RunService.RenderStepped, function(dt)
    if not Main.Visible then return end

    for _, item in ipairs(Stars) do
        local star = item.Object

        if star and star.Parent then
            local pos = star.Position
            local x = pos.X.Scale + item.Speed * dt
            local y = pos.Y.Scale + item.Speed * 0.45 * dt

            if x > 1 then x = -0.03 end
            if y > 1 then y = -0.03 end

            star.Position = UDim2.new(x, 0, y, 0)
        end
    end
end)

local function cleanup()
    if not Alive then return end
    Alive = false

    State.FPS = false
    State.Interact = false
    State.Recoil = false
    State.Spread = false

    restoreInteract()
    restoreValues(RecoilSaved)
    restoreValues(SpreadSaved)
    restoreFPS()

    if State.Bright then
        restoreBright()
        State.Bright = false
    end

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Connections)

    if Gui then
        Gui:Destroy()
    end
end

ENV.SCFPS_Cleanup = cleanup

refresh()
print("SC FPS | FARHAN STORE - ULTRA POTATO V2")
