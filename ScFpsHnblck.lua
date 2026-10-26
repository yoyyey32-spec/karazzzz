
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ENV = getgenv and getgenv() or _G

if type(ENV.SCFPS_Cleanup) == "function" then
    pcall(ENV.SCFPS_Cleanup)
end

local Alive = true

local State = {
    Bright = false,
    Interact = false,
    Recoil = false,
    Spread = false,
    Visible = true
}

local Connections = {}
local PromptSaved = {}
local FontSaved = {}
local RecoilSaved = {}
local SpreadSaved = {}

local OriginalGunValues = setmetatable({}, {
    __mode = "k"
})

local WatchedTools = setmetatable({}, {
    __mode = "k"
})

local BrightSaved
local Gui
local Main

local Buttons = {}
local Stars = {}

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

local FontFace

pcall(function()
    FontFace = Font.fromId(12187372382)
end)

local function bind(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function applyBright()
    if not BrightSaved then
        BrightSaved = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            ExposureCompensation = Lighting.ExposureCompensation,
            GlobalShadows = Lighting.GlobalShadows
        }
    end

    Lighting.Brightness = 1.5
    Lighting.Ambient = Color3.fromRGB(105, 105, 105)
    Lighting.OutdoorAmbient = Color3.fromRGB(115, 115, 115)
    Lighting.ExposureCompensation = 0
    Lighting.GlobalShadows = false
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
    if not prompt:IsA("ProximityPrompt") then
        return
    end

    if PromptSaved[prompt] == nil then
        PromptSaved[prompt] = prompt.HoldDuration
    end

    pcall(function()
        prompt.HoldDuration = 0.01
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

    local setting = tool:FindFirstChild("Setting", true)

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
    local original = OriginalGunValues[module]

    if not original then
        original = {}
        OriginalGunValues[module] = original
    end

    saved[module] = saved[module] or {}

    for _, key in ipairs(keys) do
        local current = module[key]

        if type(current) == "number" then
            if original[key] == nil and current ~= 0.1 then
                original[key] = current
            end

            if saved[module][key] == nil
                and original[key] ~= nil then

                saved[module][key] = original[key]
            end

            if saved[module][key] ~= nil then
                module[key] = 0.1
            end
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

local function watchTool(tool)
    if not tool:IsA("Tool") then return end
    if WatchedTools[tool] then return end

    WatchedTools[tool] = true

    bind(tool.DescendantAdded, function(obj)
        if not Alive then return end

        if obj:IsA("ModuleScript")
            and obj.Name == "Setting" then

            task.defer(function()
                if Alive then
                    applyGun(tool)
                end
            end)
        end
    end)

    task.defer(function()
        if Alive and tool.Parent then
            applyGun(tool)
        end
    end)
end

local function watchCharacter(character)
    bind(character.ChildAdded, watchTool)

    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Tool") then
            watchTool(obj)
        end
    end

    task.defer(function()
        if Alive then
            applyAllGuns()
        end
    end)
end

local function applyGameFont(obj)
    if not Alive or not FontFace then return end
    if not obj or not obj.Parent then return end

    if Gui and obj:IsDescendantOf(Gui) then
        return
    end

    if obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox") then

        if FontSaved[obj] == nil then
            local ok, old = pcall(function()
                return obj.FontFace
            end)

            if ok then
                FontSaved[obj] = old
            end
        end

        pcall(function()
            obj.FontFace = FontFace
        end)
    end
end

local function restoreGameFont()
    for obj, font in pairs(FontSaved) do
        pcall(function()
            obj.FontFace = font
        end)
    end

    table.clear(FontSaved)
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
Gui.Name = "SCFPS_FarhanStore_Lite"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(215, 228)
Main.Position = UDim2.new(0, 20, 0.5, -114)
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
Title.Text = "FARHAN STORE | LITE"
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

Buttons.Bright = makeButton("FULL BRIGHT", 1)
Buttons.Interact = makeButton("FAST INTERACT", 2)
Buttons.Recoil = makeButton("NO RECOIL", 3)
Buttons.Spread = makeButton("LOW SPREAD", 4)

local Ping = Instance.new("TextLabel")
Ping.Size = UDim2.new(1, -16, 0, 23)
Ping.Position = UDim2.new(0, 9, 1, -27)
Ping.BackgroundTransparency = 1
Ping.Text = "PING: -- ms"
Ping.TextXAlignment = Enum.TextXAlignment.Left
Ping.TextStrokeTransparency = 0.55
Ping.ZIndex = 3
Ping.Parent = Main

makeText(Ping, 15)
Ping.TextColor3 = Color3.fromRGB(140, 210, 255)

local function buttonState(button, label, enabled)
    button.Text = label .. (
        enabled and ": ON" or ": OFF"
    )

    button.TextColor3 = enabled
        and Color3.fromRGB(120, 210, 255)
        or Color3.fromRGB(225, 225, 225)
end

local function refresh()
    buttonState(
        Buttons.Bright,
        "FULL BRIGHT",
        State.Bright
    )

    buttonState(
        Buttons.Interact,
        "FAST INTERACT",
        State.Interact
    )

    buttonState(
        Buttons.Recoil,
        "NO RECOIL",
        State.Recoil
    )

    buttonState(
        Buttons.Spread,
        "LOW SPREAD",
        State.Spread
    )
end

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

if Player.Character then
    watchCharacter(Player.Character)
end

bind(Player.CharacterAdded, watchCharacter)

local Backpack = Player:WaitForChild("Backpack")

bind(Backpack.ChildAdded, watchTool)

for _, obj in ipairs(Backpack:GetChildren()) do
    if obj:IsA("Tool") then
        watchTool(obj)
    end
end

for _, obj in ipairs(PlayerGui:GetDescendants()) do
    applyGameFont(obj)
end

bind(PlayerGui.DescendantAdded, applyGameFont)

bind(Workspace.DescendantAdded, function(obj)
    if not Alive then return end

    if obj:IsA("TextLabel")
        or obj:IsA("TextButton")
        or obj:IsA("TextBox") then

        applyGameFont(obj)
    end

    if State.Interact and obj:IsA("ProximityPrompt") then
        fastPrompt(obj)
    end
end)

local PingClock = 0
local GunClock = 0

bind(RunService.Heartbeat, function(dt)
    PingClock += dt
    GunClock += dt

    if PingClock >= 0.1 then
        PingClock = 0

        local ok, value = pcall(function()
            return Stats.Network.ServerStatsItem[
                "Data Ping"
            ]:GetValue()
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

    State.Interact = false
    State.Recoil = false
    State.Spread = false

    restoreInteract()
    restoreValues(RecoilSaved)
    restoreValues(SpreadSaved)
    restoreGameFont()

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

print("FARHAN STORE")
