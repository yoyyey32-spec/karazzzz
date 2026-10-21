local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

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
    noRecoil = false,
    lowSpread = false,
    visible = true
}

local Saved = {}
local Detached = {}
local SkySaved = {}
local PromptSaved = {}
local BrightSaved = {}

local RecoilSaved = {}
local SpreadSaved = {}

local Connections = {}
local Stars = {}

local Active = true
local Busy = false
local OriginalDecoration

local BlackSky
local BlackAtmosphere
local Gui
local Main
local Buttons = {}

local RecoilKeys = {
    "Recoil",
    "RecoilAmount",
    "CameraRecoil",
    "CameraShake",
    "Kick",
    "Kickback",
    "VerticalRecoil",
    "HorizontalRecoil",
    "RecoilX",
    "RecoilY",
    "GunRecoil",
    "WeaponRecoil",
    "AimRecoil",
    "ShakeAmount",
    "ShakeIntensity"
}

local SpreadKeys = {
    "Spread",
    "SpreadX",
    "SpreadY",
    "MinSpread",
    "MaxSpread",
    "HipSpread",
    "AimSpread",
    "SpreadAmount",
    "Bloom"
}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function change(obj, prop, value)
    if not obj or not obj.Parent then return end

    Saved[obj] = Saved[obj] or {}

    if Saved[obj][prop] == nil then
        local ok, old = pcall(function()
            return obj[prop]
        end)

        if ok then
            Saved[obj][prop] = old
        end
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

local function restoreVisuals()
    for obj, props in pairs(Saved) do
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

    table.clear(Saved)
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
        if hasName(current, words) then return true end
        current = current.Parent
    end

    return false
end

local function isCharacter(obj)
    local character = Player.Character

    return character and (
        obj == character or obj:IsDescendantOf(character)
    )
end

local function isFence(obj)
    return ancestorHas(obj, {
        "fence", "chainlink", "chain_link",
        "railing", "ironfence", "metal_fence",
        "grate"
    }, 4)
end

local function isWeapon(obj)
    if obj:IsA("Tool") then return true end

    return ancestorHas(obj, {
        "g17", "glock", "drum", "pistol",
        "rifle", "shotgun", "revolver",
        "firearm", "handgun", "ak47",
        "ak-47", "uzi", "gunmodel",
        "gun_model", "weaponmodel",
        "weapon_model", "magazine"
    }, 5)
end

local function isCar(obj)
    return ancestorHas(obj, {
        "vehicle", "automobile", "truck",
        "carbody", "car_model", "vehicles"
    }, 5)
end

local function isStoreWood(obj)
    if not obj:IsA("BasePart") then return false end
    if isWeapon(obj) or isFence(obj) then return false end

    local store = ancestorHas(obj, {
        "gunstore", "gun_store", "gun store",
        "gunshop", "gun_shop", "weaponshop",
        "weapon_shop"
    }, 10)

    if not store then return false end

    return obj.Material == Enum.Material.Wood
        or obj.Material == Enum.Material.WoodPlanks
        or hasName(obj, {
            "wood", "plank", "timber",
            "shelf", "counter", "board"
        })
end

local function isEffect(obj)
    return obj:IsA("ParticleEmitter")
        or obj:IsA("Trail")
        or obj:IsA("Beam")
        or obj:IsA("Smoke")
        or obj:IsA("Fire")
        or obj:IsA("Sparkles")
end

local function isUnwantedEffect(obj)
    return ancestorHas(obj, {
        "blood", "gore", "bleed",
        "tracer", "bullettrail", "bullet_trail",
        "muzzle", "gunflash", "gun_flash",
        "weaponfx", "weapon_fx",
        "gunfx", "gun_fx", "bulletbeam",
        "bullet_beam", "gunsmoke",
        "bulletimpact", "bullet_impact",
        "laser", "shellparticle"
    }, 5)
end

local function hide(obj)
    if obj:IsA("BasePart") then
        change(obj, "Transparency", 1)
        change(obj, "CastShadow", false)
        change(obj, "CanCollide", false)
        change(obj, "CanTouch", false)
        change(obj, "CanQuery", false)
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)
    end
end

local function stripTexture(obj)
    if obj:IsA("SurfaceAppearance") then
        detach(obj)
    elseif obj:IsA("MeshPart") then
        change(obj, "TextureID", "")
    elseif obj:IsA("SpecialMesh") then
        change(obj, "TextureId", "")
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        change(obj, "Transparency", 1)
    end
end

local function optimizeGun(obj)
    if obj:IsA("BasePart") then
        change(obj, "Color", Color3.new(0, 0, 0))
        change(obj, "Material", Enum.Material.SmoothPlastic)
        change(obj, "Reflectance", 0)
        change(obj, "CastShadow", false)

        if obj:IsA("MeshPart") then
            change(obj, "TextureID", "")
        end
    else
        stripTexture(obj)
    end
end

local function optimize(obj)
    if not State.fps or not obj or not obj.Parent then return end
    if isCharacter(obj) then return end

    if obj:IsA("ProximityPrompt")
        or obj:IsA("ClickDetector") then
        return
    end

    if isUnwantedEffect(obj) then
        if isEffect(obj) then
            change(obj, "Enabled", false)
        else
            hide(obj)
        end
        return
    end

    if isWeapon(obj) then
        optimizeGun(obj)
        return
    end

    if isFence(obj) then
        if obj:IsA("BasePart") then
            change(obj, "CastShadow", false)
            change(obj, "Reflectance", 0)
        end
        return
    end

    if isStoreWood(obj) then
        hide(obj)
        return
    end

    if isEffect(obj) then
        change(obj, "Enabled", false)
        return
    end

    if obj:IsA("BasePart") then
        change(obj, "CastShadow", false)
        change(obj, "Reflectance", 0)

        if not isCar(obj) then
            change(obj, "Material", Enum.Material.SmoothPlastic)
        end
    end

    stripTexture(obj)
end

local function applyBlackSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj ~= BlackSky and obj ~= BlackAtmosphere then
            if obj:IsA("Sky") or obj:IsA("Atmosphere") then
                if SkySaved[obj] == nil then
                    SkySaved[obj] = obj.Parent
                end

                obj.Parent = nil
            elseif obj:IsA("PostEffect") then
                change(obj, "Enabled", false)
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

    if Terrain then
        for _, obj in ipairs(Terrain:GetChildren()) do
            if obj:IsA("Clouds") then
                change(obj, "Enabled", false)
            end
        end
    end
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
    if not State.fps then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        optimize(obj)
    end

    if Terrain then
        if OriginalDecoration == nil then
            OriginalDecoration = Terrain.Decoration
        end

        pcall(function()
            Terrain.Decoration = false
        end)
    end

    applyBlackSky()
end

local function restoreDecoration()
    if Terrain and OriginalDecoration ~= nil then
        pcall(function()
            Terrain.Decoration = OriginalDecoration
        end)
    end
end

local function applyBright()
    if not BrightSaved.Lighting then
        BrightSaved.Lighting = {
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
    if BrightSaved.Lighting then
        for prop, value in pairs(BrightSaved.Lighting) do
            pcall(function()
                Lighting[prop] = value
            end)
        end
    end

    table.clear(BrightSaved)
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

local function restorePrompts()
    for prompt, duration in pairs(PromptSaved) do
        pcall(function()
            prompt.HoldDuration = duration
        end)
    end

    table.clear(PromptSaved)
end

local function getGunSettings(tool)
    if not tool or not tool:IsA("Tool") then return nil end

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

local function applyValues(module, keys, saved, value)
    if not module then return end

    if not saved[module] then
        saved[module] = {}
    end

    for _, key in ipairs(keys) do
        local current = module[key]

        if type(current) == "number" then
            if saved[module][key] == nil then
                saved[module][key] = current
            end

            module[key] = value
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
    if not State.noRecoil and not State.lowSpread then
        return
    end

    local module = getGunSettings(tool)
    if not module then return end

    if State.noRecoil then
        applyValues(module, RecoilKeys, RecoilSaved, 0.1)
    end

    if State.lowSpread then
        applyValues(module, SpreadKeys, SpreadSaved, 0.1)
    end
end

local function applyToAll()
    if not State.noRecoil and not State.lowSpread then
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

local function refreshButton(button, label, enabled)
    button.Text = label .. (enabled and ": ON" or ": OFF")

    button.TextColor3 = enabled
        and Color3.fromRGB(120, 210, 255)
        or Color3.fromRGB(225, 225, 225)
end

local function makeButton(parent, label, order)
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
    button.TextColor3 = Color3.fromRGB(225, 225, 225)
    button.TextSize = 12
    button.ZIndex = 3
    button.Parent = parent

    if SCFont then
        button.FontFace = SCFont
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(45, 130, 255)
    stroke.Transparency = 0.35
    stroke.Parent = button

    return button
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
Title.TextColor3 = Color3.fromRGB(140, 200, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 12
Title.ZIndex = 3
Title.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(25, 25)
Close.Position = UDim2.new(1, -28, 0, 3)
Close.BackgroundTransparency = 1
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(220, 225, 235)
Close.TextSize = 13
Close.ZIndex = 3
Close.Parent = Top

if SCFont then
    Title.FontFace = SCFont
    Close.FontFace = SCFont
end

Buttons.FPS = makeButton(Main, "FPS BOOST", 1)
Buttons.Bright = makeButton(Main, "FULL BRIGHT", 2)
Buttons.Interact = makeButton(Main, "FAST INTERACT", 3)
Buttons.NoRecoil = makeButton(Main, "NO RECOIL", 4)
Buttons.LowSpread = makeButton(Main, "LOW SPREAD", 5)

local Ping = Instance.new("TextLabel")
Ping.Size = UDim2.new(1, -16, 0, 17)
Ping.Position = UDim2.new(0, 8, 1, -20)
Ping.BackgroundTransparency = 1
Ping.Text = "PING: -- ms"
Ping.TextColor3 = Color3.fromRGB(120, 185, 255)
Ping.TextSize = 10
Ping.TextXAlignment = Enum.TextXAlignment.Left
Ping.ZIndex = 3
Ping.Parent = Main

if SCFont then
    Ping.FontFace = SCFont
end

local function refresh()
    refreshButton(Buttons.FPS, "FPS BOOST", State.fps)
    refreshButton(Buttons.Bright, "FULL BRIGHT", State.bright)
    refreshButton(Buttons.Interact, "FAST INTERACT", State.interact)
    refreshButton(Buttons.NoRecoil, "NO RECOIL", State.noRecoil)
    refreshButton(Buttons.LowSpread, "LOW SPREAD", State.lowSpread)
end

connect(Buttons.FPS.MouseButton1Click, function()
    if Busy then return end
    Busy = true

    State.fps = not State.fps

    if State.fps then
        applyFPS()
    else
        restoreVisuals()
        restoreSky()
        restoreDecoration()
    end

    refresh()
    Busy = false
end)

connect(Buttons.Bright.MouseButton1Click, function()
    State.bright = not State.bright

    if State.bright then
        applyBright()
    else
        restoreBright()
    end

    refresh()
end)

connect(Buttons.Interact.MouseButton1Click, function()
    State.interact = not State.interact

    if State.interact then
        applyInteract()
    else
        restorePrompts()
    end

    refresh()
end)

connect(Buttons.NoRecoil.MouseButton1Click, function()
    State.noRecoil = not State.noRecoil

    if State.noRecoil then
        applyToAll()
    else
        restoreValues(RecoilSaved)
    end

    refresh()
end)

connect(Buttons.LowSpread.MouseButton1Click, function()
    State.lowSpread = not State.lowSpread

    if State.lowSpread then
        applyToAll()
    else
        restoreValues(SpreadSaved)
    end

    refresh()
end)

connect(Close.MouseButton1Click, function()
    State.visible = false
    Main.Visible = false
end)

local dragging = false
local dragStart
local startPosition

connect(Top.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

connect(UIS.InputBegan, function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightAlt then
        State.visible = not State.visible
        Main.Visible = State.visible
    elseif input.KeyCode == Enum.KeyCode.X then
        State.visible = false
        Main.Visible = false
    end
end)

local function watchTool(obj)
    if not obj:IsA("Tool") then return end

    task.defer(function()
        if Active and obj.Parent then
            applyGun(obj)
        end
    end)
end

local function watchCharacter(character)
    connect(character.ChildAdded, watchTool)

    if State.noRecoil or State.lowSpread then
        task.defer(applyToAll)
    end
end

if Player.Character then
    watchCharacter(Player.Character)
end

connect(Player.CharacterAdded, watchCharacter)

local Backpack = Player:WaitForChild("Backpack")
connect(Backpack.ChildAdded, watchTool)

connect(Workspace.DescendantAdded, function(obj)
    if State.fps then
        task.defer(function()
            if Active and obj.Parent then
                pcall(optimize, obj)
            end
        end)
    end

    if State.interact and obj:IsA("ProximityPrompt") then
        task.defer(function()
            if Active and obj.Parent then
                fastPrompt(obj)
            end
        end)
    end
end)

connect(Lighting.ChildAdded, function(obj)
    if not State.fps then return end

    task.defer(function()
        if not Active or not obj.Parent then return end

        if obj:IsA("Sky") or obj:IsA("Atmosphere") then
            if obj ~= BlackSky and obj ~= BlackAtmosphere then
                if SkySaved[obj] == nil then
                    SkySaved[obj] = obj.Parent
                end

                obj.Parent = nil
            end
        elseif obj:IsA("PostEffect") then
            change(obj, "Enabled", false)
        end
    end)
end)

local pingClock = 0
local gunClock = 0

connect(RunService.Heartbeat, function(dt)
    pingClock += dt
    gunClock += dt

    if pingClock >= 0.1 then
        pingClock = 0

        local ok, ping = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)

        if ok and type(ping) == "number" then
            Ping.Text = "PING: " .. math.floor(ping + 0.5) .. " ms"
        end
    end

    if gunClock >= 0.5 then
        gunClock = 0

        if State.noRecoil or State.lowSpread then
            applyToAll()
        end
    end
end)

connect(RunService.RenderStepped, function(dt)
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
    if not Active then return end
    Active = false

    State.fps = false
    State.interact = false
    State.noRecoil = false
    State.lowSpread = false

    restorePrompts()
    restoreValues(RecoilSaved)
    restoreValues(SpreadSaved)

    restoreVisuals()
    restoreSky()
    restoreDecoration()

    if State.bright then
        restoreBright()
        State.bright = false
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

if getgenv then
    getgenv().SCFPS_Cleanup = cleanup
end

refresh()
print("SC FPS | FARHAN STORE loaded")
