
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")

local Config = {
    AutoFireDelay = 0.08,
    TargetDistance = 1000,
    KillEffectDuration = 0.45,
    InteractDelay = 0.01,
    GunValue = 0.1
}

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera
local ENV = getgenv and getgenv() or _G

if type(ENV.FarhanLiteCleanup) == "function" then
    pcall(ENV.FarhanLiteCleanup)
end

local Alive = true
local State = {
    AutoFire = false,
    Recoil = false,
    Interact = false,
    KillEffect = false,
    Color = "Kuning",
    Visible = true
}

local Colors = {
    Kuning = Color3.fromRGB(255, 215, 45),
    Biru = Color3.fromRGB(35, 145, 255),
    Merah = Color3.fromRGB(255, 55, 65)
}

local Connections = {}
local PromptSaved = {}
local GunSaved = {}
local WatchedTools = {}
local Buttons = {}
local FontFace

pcall(function()
    FontFace = Font.fromId(12187372382)
end)

local function bind(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function textStyle(obj, size)
    obj.TextSize = size
    obj.TextColor3 = Color3.new(1, 1, 1)
    obj.Font = Enum.Font.GothamMedium

    if FontFace then
        pcall(function()
            obj.FontFace = FontFace
        end)
    end
end

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "FarhanStore_Lite_Pink"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(195, 206)
Main.Position = UDim2.new(0, 35, 0.5, -103)
Main.BackgroundColor3 = Color3.fromRGB(36, 16, 29)
Main.BackgroundTransparency = 0.12
Main.BorderSizePixel = 0
Main.Parent = Gui

makeCorner(Main, 11)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 55, 193)
Stroke.Thickness = 2
Stroke.Parent = Main

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(59, 23, 43)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(27, 15, 25))
})
Gradient.Rotation = 90
Gradient.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -12, 0, 26)
Title.Position = UDim2.fromOffset(6, 3)
Title.BackgroundTransparency = 1
Title.Text = "Farhan Store"
Title.TextStrokeTransparency = 0.65
Title.Parent = Main
textStyle(Title, 14)

local function makeToggle(name, y, key)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.fromOffset(115, 26)
    Label.Position = UDim2.fromOffset(13, y)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Main
    textStyle(Label, 12)

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.fromOffset(42, 21)
    Toggle.Position = UDim2.fromOffset(140, y + 2)
    Toggle.BackgroundColor3 = Color3.fromRGB(95, 55, 77)
    Toggle.BorderSizePixel = 0
    Toggle.Text = ""
    Toggle.Parent = Main
    makeCorner(Toggle, 12)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.fromOffset(15, 15)
    Dot.Position = UDim2.fromOffset(3, 3)
    Dot.BackgroundColor3 = Color3.new(1, 1, 1)
    Dot.BorderSizePixel = 0
    Dot.Parent = Toggle
    makeCorner(Dot, 9)

    local function refresh()
        local on = State[key]

        Toggle.BackgroundColor3 = on
            and Color3.fromRGB(255, 45, 190)
            or Color3.fromRGB(95, 55, 77)

        TweenService:Create(
            Dot,
            TweenInfo.new(0.13),
            {
                Position = on
                    and UDim2.fromOffset(24, 3)
                    or UDim2.fromOffset(3, 3)
            }
        ):Play()
    end

    Buttons[key] = {
        Button = Toggle,
        Refresh = refresh
    }

    return Toggle
end

local AutoButton = makeToggle("Auto Fire", 33, "AutoFire")
local RecoilButton = makeToggle("No Recoil", 63, "Recoil")
local InteractButton = makeToggle("Fast Interact", 93, "Interact")
local KillButton = makeToggle("Kill Effect", 123, "KillEffect")

local ColorLabel = Instance.new("TextLabel")
ColorLabel.Size = UDim2.fromOffset(67, 26)
ColorLabel.Position = UDim2.fromOffset(13, 156)
ColorLabel.BackgroundTransparency = 1
ColorLabel.Text = "Warna:"
ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
ColorLabel.Parent = Main
textStyle(ColorLabel, 12)

local ColorButton = Instance.new("TextButton")
ColorButton.Size = UDim2.fromOffset(99, 23)
ColorButton.Position = UDim2.fromOffset(83, 157)
ColorButton.BackgroundColor3 = Color3.fromRGB(76, 39, 52)
ColorButton.BorderSizePixel = 0
ColorButton.Parent = Main
makeCorner(ColorButton, 7)
textStyle(ColorButton, 11)

local ColorDot = Instance.new("Frame")
ColorDot.Size = UDim2.fromOffset(11, 11)
ColorDot.Position = UDim2.fromOffset(8, 6)
ColorDot.BorderSizePixel = 0
ColorDot.Parent = ColorButton
makeCorner(ColorDot, 7)

local ColorOrder = {"Kuning", "Biru", "Merah"}
local ColorIndex = 1

local function refreshColor()
    ColorButton.Text = "    " .. State.Color .. "  ▾"
    ColorDot.BackgroundColor3 = Colors[State.Color]
end

local Effect = Instance.new("Frame")
Effect.Name = "KillEffect"
Effect.Size = UDim2.new(1, 0, 0.43, 0)
Effect.Position = UDim2.new(0, 0, 1, 0)
Effect.BackgroundColor3 = Colors.Kuning
Effect.BackgroundTransparency = 1
Effect.BorderSizePixel = 0
Effect.ZIndex = 20
Effect.Parent = Gui

local EffectGradient = Instance.new("UIGradient")
EffectGradient.Rotation = 90
EffectGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.45, 0.35),
    NumberSequenceKeypoint.new(1, 0)
})
EffectGradient.Parent = Effect

local ActiveEffect

local function playKillEffect()
    if not Alive or not State.KillEffect then return end

    if ActiveEffect then
        ActiveEffect:Cancel()
    end

    Effect.BackgroundColor3 = Colors[State.Color]
    Effect.Position = UDim2.new(0, 0, 1, 0)
    Effect.BackgroundTransparency = 0.2

    ActiveEffect = TweenService:Create(
        Effect,
        TweenInfo.new(
            Config.KillEffectDuration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Position = UDim2.new(0, 0, 0.57, 0),
            BackgroundTransparency = 1
        }
    )

    ActiveEffect:Play()
end

local RecoilKeys = {
    "Recoil", "RecoilAmount", "CameraRecoil",
    "CameraShake", "Kick", "Kickback",
    "VerticalRecoil", "HorizontalRecoil",
    "RecoilX", "RecoilY", "GunRecoil",
    "WeaponRecoil", "AimRecoil",
    "ShakeAmount", "ShakeIntensity",
    "Spread", "SpreadX", "SpreadY",
    "MinSpread", "MaxSpread", "HipSpread",
    "AimSpread", "SpreadAmount", "Bloom"
}

local function restoreGuns()
    for module, properties in pairs(GunSaved) do
        for key, original in pairs(properties) do
            pcall(function()
                module[key] = original
            end)
        end
        GunSaved[module] = nil
    end
end

local function applyGun(tool)
    if not State.Recoil or not tool:IsA("Tool") then return end

    local setting = tool:FindFirstChild("Setting", true)
    if not setting or not setting:IsA("ModuleScript") then return end

    local ok, module = pcall(require, setting)
    if not ok or type(module) ~= "table" then return end

    GunSaved[module] = GunSaved[module] or {}

    for _, key in ipairs(RecoilKeys) do
        local value = module[key]

        if type(value) == "number" then
            if GunSaved[module][key] == nil then
                GunSaved[module][key] = value
            end

            module[key] = Config.GunValue
        end
    end
end

local function applyAllGuns()
    if not State.Recoil then return end

    local character = Player.Character
    local backpack = Player:FindFirstChild("Backpack")

    for _, root in ipairs({character, backpack}) do
        if root then
            for _, obj in ipairs(root:GetChildren()) do
                if obj:IsA("Tool") then
                    pcall(applyGun, obj)
                end
            end
        end
    end
end

local function fastPrompt(prompt)
    if not State.Interact or not prompt:IsA("ProximityPrompt") then
        return
    end

    if PromptSaved[prompt] == nil then
        PromptSaved[prompt] = prompt.HoldDuration
    end

    pcall(function()
        prompt.HoldDuration = Config.InteractDelay
    end)
end

local function restorePrompts()
    for prompt, original in pairs(PromptSaved) do
        pcall(function()
            prompt.HoldDuration = original
        end)
        PromptSaved[prompt] = nil
    end
end

local function getEquippedTool()
    local character = Player.Character
    if not character then return nil end

    return character:FindFirstChildOfClass("Tool")
end

local function getCrosshairTarget()
    Camera = Workspace.CurrentCamera
    if not Camera then return nil end

    local character = Player.Character
    local center = Camera.ViewportSize / 2
    local ray = Camera:ViewportPointToRay(center.X, center.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = character and {character} or {}
    params.IgnoreWater = true

    local result = Workspace:Raycast(
        ray.Origin,
        ray.Direction * Config.TargetDistance,
        params
    )

    if not result then return nil end

    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if not model then return nil end

    local targetPlayer = Players:GetPlayerFromCharacter(model)
    if not targetPlayer or targetPlayer == Player then return nil end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end

    return targetPlayer, humanoid
end

local function fireWeapon(tool)
    return false
end

local function refreshButtons()
    for _, item in pairs(Buttons) do
        item.Refresh()
    end
end

bind(AutoButton.MouseButton1Click, function()
    State.AutoFire = not State.AutoFire
    refreshButtons()
end)

bind(RecoilButton.MouseButton1Click, function()
    State.Recoil = not State.Recoil

    if State.Recoil then
        applyAllGuns()
    else
        restoreGuns()
    end

    refreshButtons()
end)

bind(InteractButton.MouseButton1Click, function()
    State.Interact = not State.Interact

    if State.Interact then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                fastPrompt(obj)
            end
        end
    else
        restorePrompts()
    end

    refreshButtons()
end)

bind(KillButton.MouseButton1Click, function()
    State.KillEffect = not State.KillEffect
    refreshButtons()
end)

bind(ColorButton.MouseButton1Click, function()
    ColorIndex = ColorIndex % #ColorOrder + 1
    State.Color = ColorOrder[ColorIndex]
    refreshColor()
end)

local Dragging = false
local DragStart
local StartPosition

bind(Main.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
    end
end)

bind(UIS.InputChanged, function(input)
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
    end
end)

bind(Workspace.DescendantAdded, function(obj)
    if not Alive then return end

    if State.Interact and obj:IsA("ProximityPrompt") then
        fastPrompt(obj)
    end
end)

local function watchTool(tool)
    if not tool:IsA("Tool") or WatchedTools[tool] then return end
    WatchedTools[tool] = true

    bind(tool.DescendantAdded, function(obj)
        if Alive and obj:IsA("ModuleScript") and obj.Name == "Setting" then
            task.defer(function()
                if Alive then
                    applyGun(tool)
                end
            end)
        end
    end)

    task.defer(function()
        if Alive then
            applyGun(tool)
        end
    end)
end

local function watchCharacter(character)
    bind(character.ChildAdded, watchTool)

    for _, child in ipairs(character:GetChildren()) do
        watchTool(child)
    end
end

if Player.Character then
    watchCharacter(Player.Character)
end

bind(Player.CharacterAdded, watchCharacter)

local Backpack = Player:WaitForChild("Backpack")
bind(Backpack.ChildAdded, watchTool)

for _, child in ipairs(Backpack:GetChildren()) do
    watchTool(child)
end

local FireClock = 0
local GunClock = 0

bind(RunService.Heartbeat, function(dt)
    if not Alive then return end

    FireClock += dt
    GunClock += dt

    if GunClock >= 0.5 then
        GunClock = 0
        applyAllGuns()
    end

    if FireClock >= Config.AutoFireDelay then
        FireClock = 0

        if State.AutoFire
            and not UIS:GetFocusedTextBox()
            and getEquippedTool() then

            local target = getCrosshairTarget()

            if target then
                fireWeapon(getEquippedTool())
            end
        end
    end
end)

local function cleanup()
    if not Alive then return end
    Alive = false

    State.AutoFire = false
    State.Recoil = false
    State.Interact = false
    State.KillEffect = false

    restoreGuns()
    restorePrompts()

    if ActiveEffect then
        ActiveEffect:Cancel()
    end

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if Gui then
        Gui:Destroy()
    end
end

ENV.FarhanLiteCleanup = cleanup
ENV.FarhanLiteKillEffectPreview = playKillEffect

refreshButtons()
refreshColor()

print("FARHAN STORE | LITE PINK")
