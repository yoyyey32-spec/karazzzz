local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = {
    AutoFireDelay = 0.16,
    AutoPulse = 0.055,
    KillCreditWindow = 1.5,
    TargetDistance = 1000,
    KillEffectDuration = 0.55,
    InteractDelay = 0.1,
    GunValue = 0.1,
    RecoilRefresh = 0.75
}

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
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

local Theme = {
    Background = Color3.fromRGB(7, 15, 27),
    Secondary = Color3.fromRGB(15, 35, 59),
    Blue = Color3.fromRGB(25, 135, 255),
    Text = Color3.fromRGB(235, 245, 255),
    Off = Color3.fromRGB(52, 72, 94)
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
local WatchedHumanoids = {}
local Buttons = {}

local ActiveEffect
local ActiveTool
local LastFire = 0
local RecoilClock = 0
local DropdownOpen = false
local RecentTargets = {}
local GunModules = {}
local GunStats = {Changed = 0, Checked = 0}
local ManualFireUntil = 0
local ManualHeld = false
local LastAutoTarget = nil
local AutoPulseId = 0
local TargetMarkClock = 0

local function bind(signal, callback)
    local connection = signal:Connect(callback)
    Connections[#Connections + 1] = connection
    return connection
end

local function round(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
end

local function styleText(object, size)
    object.Font = Enum.Font.GothamMedium
    object.TextSize = size
    object.TextColor3 = Theme.Text
    object.BorderSizePixel = 0

    pcall(function()
        object.FontFace = Font.fromId(12187372382)
    end)
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "FarhanStore_BlueBlack_V42"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(205, 211)
Main.Position = UDim2.new(0, 35, 0.5, -105)
Main.BackgroundColor3 = Theme.Background
Main.BackgroundTransparency = 0.06
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Gui
round(Main, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Theme.Blue
Stroke.Thickness = 2
Stroke.Parent = Main

local BackgroundGradient = Instance.new("UIGradient")
BackgroundGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Secondary),
    ColorSequenceKeypoint.new(1, Theme.Background)
})
BackgroundGradient.Rotation = 90
BackgroundGradient.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 31)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -12, 1, 0)
Title.Position = UDim2.fromOffset(6, 0)
Title.BackgroundTransparency = 1
Title.Text = "Farhan Store"
Title.TextColor3 = Color3.fromRGB(85, 180, 255)
Title.TextStrokeTransparency = 0.65
Title.Parent = Header
styleText(Title, 14)
Title.TextColor3 = Color3.fromRGB(85, 180, 255)

local function makeToggle(name, y, key)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.fromOffset(120, 26)
    Label.Position = UDim2.fromOffset(13, y)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Main
    styleText(Label, 12)

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.fromOffset(42, 21)
    Toggle.Position = UDim2.fromOffset(150, y + 2)
    Toggle.BackgroundColor3 = Theme.Off
    Toggle.BorderSizePixel = 0
    Toggle.Text = ""
    Toggle.Parent = Main
    round(Toggle, 12)

    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.fromOffset(15, 15)
    Dot.Position = UDim2.fromOffset(3, 3)
    Dot.BackgroundColor3 = Color3.new(1, 1, 1)
    Dot.BorderSizePixel = 0
    Dot.Parent = Toggle
    round(Dot, 9)

    Buttons[key] = function()
        local on = State[key]
        Toggle.BackgroundColor3 = on and Theme.Blue or Theme.Off

        TweenService:Create(
            Dot,
            TweenInfo.new(0.12),
            {
                Position = on
                    and UDim2.fromOffset(24, 3)
                    or UDim2.fromOffset(3, 3)
            }
        ):Play()
    end

    return Toggle
end

local AutoButton = makeToggle("Auto Fire", 34, "AutoFire")
local RecoilButton = makeToggle("No Recoil", 65, "Recoil")
local InteractButton = makeToggle("Fast Interact", 96, "Interact")
local KillButton = makeToggle("Kill Effect", 127, "KillEffect")

local ColorLabel = Instance.new("TextLabel")
ColorLabel.Size = UDim2.fromOffset(65, 25)
ColorLabel.Position = UDim2.fromOffset(13, 163)
ColorLabel.BackgroundTransparency = 1
ColorLabel.Text = "Warna:"
ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
ColorLabel.Parent = Main
styleText(ColorLabel, 12)

local ColorButton = Instance.new("TextButton")
ColorButton.Size = UDim2.fromOffset(109, 24)
ColorButton.Position = UDim2.fromOffset(83, 163)
ColorButton.BackgroundColor3 = Theme.Secondary
ColorButton.Text = ""
ColorButton.BorderSizePixel = 0
ColorButton.Parent = Main
round(ColorButton, 6)

local ColorStroke = Instance.new("UIStroke")
ColorStroke.Color = Color3.fromRGB(36, 104, 171)
ColorStroke.Thickness = 1
ColorStroke.Parent = ColorButton

local ColorDot = Instance.new("Frame")
ColorDot.Size = UDim2.fromOffset(10, 10)
ColorDot.Position = UDim2.fromOffset(8, 7)
ColorDot.BorderSizePixel = 0
ColorDot.Parent = ColorButton
round(ColorDot, 6)

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.fromOffset(64, 24)
SelectedLabel.Position = UDim2.fromOffset(22, 0)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.Parent = ColorButton
styleText(SelectedLabel, 11)

local Arrow = Instance.new("TextLabel")
Arrow.Size = UDim2.fromOffset(19, 24)
Arrow.Position = UDim2.fromOffset(88, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = "▼"
Arrow.Parent = ColorButton
styleText(Arrow, 10)

local Dropdown = Instance.new("Frame")
Dropdown.Size = UDim2.fromOffset(109, 81)
Dropdown.Position = UDim2.fromOffset(83, 190)
Dropdown.BackgroundColor3 = Theme.Background
Dropdown.BorderSizePixel = 0
Dropdown.Visible = false
Dropdown.ZIndex = 10
Dropdown.Parent = Main
round(Dropdown, 6)

local DropdownStroke = Instance.new("UIStroke")
DropdownStroke.Color = Theme.Blue
DropdownStroke.Thickness = 1
DropdownStroke.Parent = Dropdown

local function refreshColor()
    SelectedLabel.Text = State.Color
    ColorDot.BackgroundColor3 = Colors[State.Color]
end

for index, name in ipairs({"Kuning", "Biru", "Merah"}) do
    local Option = Instance.new("TextButton")
    Option.Size = UDim2.new(1, -6, 0, 25)
    Option.Position = UDim2.fromOffset(3, (index - 1) * 26 + 2)
    Option.BackgroundColor3 = Theme.Secondary
    Option.BackgroundTransparency = 0.25
    Option.Text = "●  " .. name
    Option.TextColor3 = Colors[name]
    Option.ZIndex = 11
    Option.Parent = Dropdown
    styleText(Option, 11)
    Option.TextColor3 = Colors[name]
    round(Option, 4)

    bind(Option.MouseButton1Click, function()
        State.Color = name
        DropdownOpen = false
        Dropdown.Visible = false
        Arrow.Text = "▼"
        refreshColor()
    end)
end

bind(ColorButton.MouseButton1Click, function()
    DropdownOpen = not DropdownOpen
    Dropdown.Visible = DropdownOpen
    Arrow.Text = DropdownOpen and "▲" or "▼"
end)

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

local GunKeys = {
    "Recoil", "RecoilAmount", "CameraRecoil", "CameraShake", "Kick", "Kickback",
    "VerticalRecoil", "HorizontalRecoil", "RecoilX", "RecoilY", "GunRecoil",
    "WeaponRecoil", "AimRecoil", "ShakeAmount", "ShakeIntensity", "Spread",
    "SpreadX", "SpreadY", "MinSpread", "MaxSpread", "HipSpread", "AimSpread",
    "SpreadAmount", "Bloom"
}

local function applyGun(tool)
    if not Alive or not State.Recoil or not tool or not tool:IsA("Tool") then return end
    for _, setting in ipairs(tool:GetDescendants()) do
        if setting:IsA("ModuleScript") and setting.Name == "Setting" and not GunModules[setting] then
            GunModules[setting] = true
            -- require can initialize the module; never assume its returned keys are universal.
            local ok, module = pcall(require, setting)
            if ok and type(module) == "table" then
                GunStats.Checked += 1
                local saved = GunSaved[module] or {}
                GunSaved[module] = saved
                for _, key in ipairs(GunKeys) do
                    local good, value = pcall(function() return rawget(module, key) end)
                    if good and type(value) == "number" then
                        if saved[key] == nil then saved[key] = value end
                        local changed = pcall(function() rawset(module, key, Config.GunValue) end)
                        if changed then GunStats.Changed += 1 end
                    end
                end
            end
        end
    end
end

local function applyAllGuns()
    if not State.Recoil then return end
    for _, root in ipairs({Player.Character, Player:FindFirstChild("Backpack")}) do
        if root then
            for _, obj in ipairs(root:GetChildren()) do
                if obj:IsA("Tool") then pcall(applyGun, obj) end
            end
        end
    end
end

local function restoreGuns()
    for module, properties in pairs(GunSaved) do
        for key, original in pairs(properties) do
            pcall(function() rawset(module, key, original) end)
        end
        GunSaved[module] = nil
    end
    table.clear(GunModules)
    GunStats.Changed = 0
    GunStats.Checked = 0
end

local function fastPrompt(prompt)
    if not State.Interact then return end
    if not prompt:IsA("ProximityPrompt") then return end

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
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local character = Player.Character
    local center = camera.ViewportSize / 2
    local ray = camera:ViewportPointToRay(center.X, center.Y)

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

    local current = result.Instance

    while current and current ~= Workspace do
        if current:IsA("Model") then
            local humanoid = current:FindFirstChildOfClass("Humanoid")

            if humanoid then
                local target = Players:GetPlayerFromCharacter(current)

                if target
                    and target ~= Player
                    and humanoid.Health > 0 then

                    return target, humanoid
                end

                return nil
            end
        end

        current = current.Parent
    end

    return nil
end

local function stopFire()
    AutoPulseId += 1
    if ActiveTool then
        pcall(function() ActiveTool:Deactivate() end)
        ActiveTool = nil
    end
    LastAutoTarget = nil
end

local function markShotTarget()
    if not State.KillEffect then return end
    local _, humanoid = getCrosshairTarget()
    if humanoid then RecentTargets[humanoid] = os.clock() end
end

local function tryAutoFire()
    if not State.AutoFire or UIS:GetFocusedTextBox() then
        stopFire()
        return
    end
    if ManualHeld or os.clock() < ManualFireUntil then return end
    local tool = getEquippedTool()
    if not tool or not tool.Enabled then
        stopFire()
        return
    end
    local target, humanoid = getCrosshairTarget()
    if not target or not humanoid then
        stopFire()
        return
    end
    local now = os.clock()
    if now - LastFire < Config.AutoFireDelay then return end
    if ActiveTool then stopFire() end
    LastFire = now
    RecentTargets[humanoid] = now
    AutoPulseId += 1
    local pulse = AutoPulseId
    local ok = pcall(function() tool:Activate() end)
    if ok then
        ActiveTool = tool
        LastAutoTarget = humanoid
        task.delay(Config.AutoPulse, function()
            if not Alive or pulse ~= AutoPulseId then return end
            if ActiveTool == tool and not ManualHeld then
                pcall(function() tool:Deactivate() end)
                ActiveTool = nil
            end
        end)
    end
end

local function hasKillCredit(humanoid)
    for _, name in ipairs({"creator", "Creator", "killer", "Killer"}) do
        local tag = humanoid:FindFirstChild(name)
        if tag and tag:IsA("ObjectValue") and tag.Value == Player then return true end
    end
    return false
end

local function watchHumanoid(humanoid)
    if WatchedHumanoids[humanoid] then return end
    WatchedHumanoids[humanoid] = true
    bind(humanoid.Died, function()
        if not Alive or not State.KillEffect then return end
        local last = RecentTargets[humanoid]
        local recent = last and os.clock() - last <= Config.KillCreditWindow
        local credited = hasKillCredit(humanoid)
        if credited or recent then
            playKillEffect()
        else
            -- A replicated credit tag may arrive just after Died.
            task.delay(0.12, function()
                if Alive and State.KillEffect and hasKillCredit(humanoid) then
                    playKillEffect()
                end
            end)
        end
        RecentTargets[humanoid] = nil
    end)
end

local function watchPlayer(targetPlayer)
    if targetPlayer == Player then return end

    local function watchCharacter(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 10)

        if Alive and humanoid then
            watchHumanoid(humanoid)
        end
    end

    bind(targetPlayer.CharacterAdded, watchCharacter)

    if targetPlayer.Character then
        task.defer(watchCharacter, targetPlayer.Character)
    end
end

for _, targetPlayer in ipairs(Players:GetPlayers()) do
    watchPlayer(targetPlayer)
end

bind(Players.PlayerAdded, watchPlayer)

local function refreshButtons()
    for _, refresh in pairs(Buttons) do
        refresh()
    end
end

bind(AutoButton.MouseButton1Click, function()
    State.AutoFire = not State.AutoFire

    if not State.AutoFire then
        stopFire()
    end

    LastFire = 0
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

local Dragging = false
local DragStart
local StartPosition

bind(Header.InputBegan, function(input)
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not processed then
        stopFire()
        ManualHeld = true
        markShotTarget()
    end
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightAlt then
        State.Visible = not State.Visible
        Main.Visible = State.Visible
        Dropdown.Visible = false
        DropdownOpen = false
        Arrow.Text = "▼"
    end
end)

bind(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        ManualHeld = false
        ManualFireUntil = os.clock() + 0.2
    end
end)

bind(Workspace.DescendantAdded, function(obj)
    if Alive and State.Interact and obj:IsA("ProximityPrompt") then
        fastPrompt(obj)
    end
end)

local function watchTool(tool)
    if not tool:IsA("Tool") or WatchedTools[tool] then return end

    WatchedTools[tool] = true

    bind(tool.Activated, function()
        if Alive then markShotTarget() end
    end)

    bind(tool.Equipped, function()
        if Alive then
            task.defer(function()
                applyGun(tool)
            end)
        end
    end)

    bind(tool.Unequipped, function()
        if ActiveTool == tool then
            stopFire()
        end
    end)

    bind(tool.DescendantAdded, function(obj)
        if Alive
            and obj:IsA("ModuleScript")
            and obj.Name == "Setting" then

            task.defer(function()
                applyGun(tool)
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
    stopFire()

    bind(character.ChildAdded, function(child)
        if child:IsA("Tool") then
            watchTool(child)

            if State.Recoil then
                task.defer(function()
                    applyGun(child)
                end)
            end
        end
    end)

    for _, child in ipairs(character:GetChildren()) do
        watchTool(child)
    end
end

if Player.Character then
    watchCharacter(Player.Character)
end

bind(Player.CharacterAdded, watchCharacter)

local Backpack = Player:WaitForChild("Backpack")

bind(Backpack.ChildAdded, function(child)
    watchTool(child)
end)

for _, child in ipairs(Backpack:GetChildren()) do
    watchTool(child)
end

bind(RunService.Heartbeat, function(dt)
    if not Alive then return end

    RecoilClock += dt

    if RecoilClock >= Config.RecoilRefresh then
        RecoilClock = 0

        if State.Recoil then
            applyAllGuns()
        end
    end

    if ManualHeld and State.KillEffect then
        TargetMarkClock += dt
        if TargetMarkClock >= 0.06 then
            TargetMarkClock = 0
            markShotTarget()
        end
    else
        TargetMarkClock = 0
    end
    tryAutoFire()
end)

local function cleanup()
    if not Alive then return end
    Alive = false

    State.AutoFire = false
    State.Recoil = false
    State.Interact = false
    State.KillEffect = false
    table.clear(RecentTargets)

    stopFire()
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

    table.clear(Connections)

    if Gui then
        Gui:Destroy()
    end
end

ENV.FarhanLiteCleanup = cleanup
ENV.FarhanLiteKillEffectPreview = playKillEffect

refreshButtons()
refreshColor()

print("FARHAN STORE | BLUE BLACK V4.1 | Setting modules checked:", GunStats.Checked, "numeric fields changed:", GunStats.Changed)
