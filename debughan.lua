
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local ENV = getgenv and getgenv() or _G

if type(ENV.FarhanScannerCleanup) == "function" then
    pcall(ENV.FarhanScannerCleanup)
end

local Alive = true
local Scanning = false
local Connections = {}
local ScanConnections = {}
local Watched = {}
local Reports = {}
local Events = {}
local SelectedGun = nil
local MaxEvents = 3000

local function bind(signal, callback, bucket)
    local c = signal:Connect(callback)
    table.insert(bucket or Connections, c)
    return c
end

local function disconnect(bucket)
    for _, c in ipairs(bucket) do
        pcall(function()
            c:Disconnect()
        end)
    end
    table.clear(bucket)
end

local function now()
    return string.format("%.3f", os.clock())
end

local function event(gun, message)
    if not Scanning then return end

    table.insert(Events, {
        gun = gun or "SYSTEM",
        text = "[" .. now() .. "] " .. message
    })

    if #Events > MaxEvents then
        table.remove(Events, 1)
    end
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "FarhanStoreScannerV2"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(320, 330)
Main.Position = UDim2.new(0, 35, 0.5, -165)
Main.BackgroundColor3 = Color3.fromRGB(7, 13, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Gui

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0, 8)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(35, 145, 255)
Stroke.Thickness = 2

local function label(parent, value, pos, size, textSize)
    local x = Instance.new("TextLabel")
    x.BackgroundTransparency = 1
    x.Position = pos
    x.Size = size
    x.Font = Enum.Font.Code
    x.TextSize = textSize or 12
    x.TextColor3 = Color3.fromRGB(220, 235, 255)
    x.TextXAlignment = Enum.TextXAlignment.Left
    x.Text = value
    x.Parent = parent
    return x
end

local Header = label(
    Main,
    "FARHAN STORE | AUDIT V2",
    UDim2.fromOffset(9, 5),
    UDim2.new(1, -18, 0, 25),
    14
)
Header.TextColor3 = Color3.fromRGB(55, 165, 255)

local Status = label(
    Main,
    "STATUS: IDLE",
    UDim2.fromOffset(9, 32),
    UDim2.new(1, -18, 0, 18),
    11
)

local function button(name, x, y, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(w, 27)
    b.Position = UDim2.fromOffset(x, y)
    b.BackgroundColor3 = Color3.fromRGB(16, 66, 115)
    b.BorderSizePixel = 0
    b.Text = name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 11
    b.Parent = Main

    local c = Instance.new("UICorner", b)
    c.CornerRadius = UDim.new(0, 5)

    return b
end

local Start = button("START", 8, 57, 72)
local Stop = button("STOP", 85, 57, 72)
local CopyAll = button("COPY ALL", 162, 57, 72)
local Export = button("EXPORT TXT", 239, 57, 73)

local Prev = button("<", 8, 91, 30)
local Next = button(">", 282, 91, 30)

local GunName = label(
    Main,
    "SELECTED: NONE",
    UDim2.fromOffset(44, 94),
    UDim2.fromOffset(233, 20),
    11
)
GunName.TextXAlignment = Enum.TextXAlignment.Center

local CopyGun = button("COPY CURRENT GUN", 8, 124, 147)
local Clear = button("CLEAR DATA", 162, 124, 150)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -165)
Scroll.Position = UDim2.fromOffset(8, 158)
Scroll.BackgroundColor3 = Color3.fromRGB(3, 9, 18)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(40, 150, 255)
Scroll.CanvasSize = UDim2.fromOffset(0, 0)
Scroll.Parent = Main

local Output = label(
    Scroll,
    "Press START to scan your weapons.",
    UDim2.fromOffset(5, 5),
    UDim2.new(1, -12, 0, 20),
    11
)
Output.TextWrapped = true
Output.TextYAlignment = Enum.TextYAlignment.Top
Output.AutomaticSize = Enum.AutomaticSize.Y

local function gunNames()
    local names = {}

    for name in pairs(Reports) do
        table.insert(names, name)
    end

    table.sort(names)
    return names
end

local function currentReport()
    return SelectedGun and Reports[SelectedGun]
end

local function refresh()
    if not Alive then return end

    local names = gunNames()

    if not SelectedGun or not Reports[SelectedGun] then
        SelectedGun = names[1]
    end

    GunName.Text = SelectedGun or "NO GUN SELECTED"

    local lines = {
        "PLACE ID: " .. tostring(game.PlaceId),
        "WEAPONS FOUND: " .. tostring(#names),
        "EVENTS SAVED: " .. tostring(#Events),
        "",
    }

    local r = currentReport()

    if r then
        table.insert(lines, "WEAPON: " .. r.name)
        table.insert(lines, "SETTING: " .. tostring(r.setting))
        table.insert(lines, "MODULES: " .. tostring(r.modules))
        table.insert(lines, "ACTIVATED: " .. tostring(r.activated))
        table.insert(lines, "DEACTIVATED: " .. tostring(r.deactivated))
        table.insert(lines, "MUZZLE EVENTS: " .. tostring(r.muzzle))
        table.insert(lines, "EQUIPPED: " .. tostring(r.equipped))
        table.insert(lines, "UNEQUIPPED: " .. tostring(r.unequipped))
        table.insert(lines, "")
        table.insert(lines, "SCRIPT / MODULE OBJECTS:")

        for _, obj in ipairs(r.objects) do
            table.insert(lines, "- " .. obj)
        end
    end

    Output.Text = table.concat(lines, "\n")

    task.defer(function()
        if not Alive then return end
        Scroll.CanvasSize = UDim2.fromOffset(
            0,
            Output.AbsoluteSize.Y + 12
        )
    end)
end

local function getReport(tool)
    local r = Reports[tool.Name]

    if not r then
        r = {
            name = tool.Name,
            setting = false,
            modules = 0,
            activated = 0,
            deactivated = 0,
            muzzle = 0,
            equipped = 0,
            unequipped = 0,
            objects = {},
            objectMap = {}
        }

        Reports[tool.Name] = r
    end

    return r
end

local function inspect(tool)
    local r = getReport(tool)

    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("ModuleScript") then
            if obj.Name == "Setting" then
                r.setting = true
            end

            local entry = obj.ClassName .. " | " .. obj.Name

            if not r.objectMap[entry] then
                r.objectMap[entry] = true
                table.insert(r.objects, entry)
                r.modules += 1
            end

        elseif obj:IsA("LocalScript")
            or obj:IsA("Script")
            or obj:IsA("RemoteEvent")
            or obj:IsA("RemoteFunction") then

            local entry = obj.ClassName .. " | " .. obj.Name

            if not r.objectMap[entry] then
                r.objectMap[entry] = true
                table.insert(r.objects, entry)
            end
        end
    end

    refresh()
end

local function watchTool(tool)
    if not Scanning or not tool:IsA("Tool") then return end
    if Watched[tool] then return end

    Watched[tool] = true

    local r = getReport(tool)

    event(tool.Name, "FOUND " .. tool.Name)
    inspect(tool)

    bind(tool.Equipped, function()
        r.equipped += 1
        event(tool.Name, "EQUIPPED")
        inspect(tool)
    end, ScanConnections)

    bind(tool.Unequipped, function()
        r.unequipped += 1
        event(tool.Name, "UNEQUIPPED")
        refresh()
    end, ScanConnections)

    bind(tool.Activated, function()
        r.activated += 1
        event(tool.Name, "ACTIVATED")
        refresh()
    end, ScanConnections)

    bind(tool.Deactivated, function()
        r.deactivated += 1
        event(tool.Name, "DEACTIVATED")
        refresh()
    end, ScanConnections)

    bind(tool.DescendantAdded, function(obj)
        if obj:IsA("ParticleEmitter") and obj.Name == "Muzzle" then
            r.muzzle += 1
            event(tool.Name, "MUZZLE ADDED")
            refresh()

        elseif obj:IsA("ModuleScript")
            or obj:IsA("LocalScript")
            or obj:IsA("Script")
            or obj:IsA("RemoteEvent")
            or obj:IsA("RemoteFunction") then

            inspect(tool)
        end
    end, ScanConnections)
end

local function watchContainer(container)
    if not container then return end

    for _, obj in ipairs(container:GetChildren()) do
        watchTool(obj)
    end

    bind(container.ChildAdded, function(obj)
        if obj:IsA("Tool") then
            watchTool(obj)
        end
    end, ScanConnections)
end

local function startScan()
    if Scanning then return end

    Scanning = true
    Status.Text = "STATUS: SCANNING"
    Status.TextColor3 = Color3.fromRGB(65, 220, 145)

    table.clear(Watched)

    watchContainer(Player:FindFirstChild("Backpack"))
    watchContainer(Player.Character)

    bind(Player.CharacterAdded, function(character)
        event("SYSTEM", "CHARACTER RESPAWNED")
        watchContainer(character)
    end, ScanConnections)

    event("SYSTEM", "SCAN STARTED")
    refresh()
end

local function stopScan()
    if not Scanning then return end

    Scanning = false
    disconnect(ScanConnections)
    table.clear(Watched)

    Status.Text = "STATUS: STOPPED"
    Status.TextColor3 = Color3.fromRGB(255, 190, 80)
    refresh()
end

local function buildReport(onlyGun)
    local lines = {
        "FARHAN STORE DEBUG AUDIT V2",
        "PLACE ID: " .. tostring(game.PlaceId),
        "WEAPONS FOUND: " .. tostring(#gunNames()),
        ""
    }

    for _, name in ipairs(gunNames()) do
        if not onlyGun or onlyGun == name then
            local r = Reports[name]

            table.insert(lines, "========================")
            table.insert(lines, "WEAPON: " .. name)
            table.insert(lines, "SETTING FOUND: " .. tostring(r.setting))
            table.insert(lines, "MODULE COUNT: " .. tostring(r.modules))
            table.insert(lines, "ACTIVATED: " .. tostring(r.activated))
            table.insert(lines, "DEACTIVATED: " .. tostring(r.deactivated))
            table.insert(lines, "MUZZLE EVENTS: " .. tostring(r.muzzle))
            table.insert(lines, "EQUIPPED: " .. tostring(r.equipped))
            table.insert(lines, "UNEQUIPPED: " .. tostring(r.unequipped))

            table.insert(lines, "OBJECTS:")

            for _, obj in ipairs(r.objects) do
                table.insert(lines, "  " .. obj)
            end

            table.insert(lines, "")
        end
    end

    table.insert(lines, "EVENT LOG:")

    for _, entry in ipairs(Events) do
        if not onlyGun
            or entry.gun == onlyGun
            or entry.gun == "SYSTEM" then

            table.insert(lines, entry.text)
        end
    end

    return table.concat(lines, "\n")
end

bind(Start.MouseButton1Click, startScan)
bind(Stop.MouseButton1Click, stopScan)

bind(CopyAll.MouseButton1Click, function()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, buildReport())

        Status.Text = ok and "STATUS: ALL COPIED" or "STATUS: COPY FAILED"
    else
        Status.Text = "STATUS: NO CLIPBOARD API"
    end
end)

bind(CopyGun.MouseButton1Click, function()
    if not SelectedGun then return end

    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, buildReport(SelectedGun))

        Status.Text = ok and "STATUS: GUN COPIED" or "STATUS: COPY FAILED"
    else
        Status.Text = "STATUS: NO CLIPBOARD API"
    end
end)

bind(Export.MouseButton1Click, function()
    if type(writefile) ~= "function" then
        Status.Text = "STATUS: EXPORT NOT SUPPORTED"
        return
    end

    local filename = "Farhan_Audit_V2_" .. tostring(game.PlaceId) .. ".txt"
    local ok = pcall(writefile, filename, buildReport())

    Status.Text = ok and "STATUS: TXT EXPORTED" or "STATUS: EXPORT FAILED"
end)

bind(Clear.MouseButton1Click, function()
    table.clear(Reports)
    table.clear(Events)
    SelectedGun = nil

    refresh()
    Status.Text = "STATUS: DATA CLEARED"
end)

bind(Prev.MouseButton1Click, function()
    local names = gunNames()
    if #names == 0 then return end

    local index = table.find(names, SelectedGun) or 1
    SelectedGun = names[((index - 2) % #names) + 1]
    refresh()
end)

bind(Next.MouseButton1Click, function()
    local names = gunNames()
    if #names == 0 then return end

    local index = table.find(names, SelectedGun) or 0
    SelectedGun = names[(index % #names) + 1]
    refresh()
end)

local Dragging = false
local DragStart
local OriginalPosition

bind(Header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        OriginalPosition = Main.Position
    end
end)

bind(UIS.InputChanged, function(input)
    if not Dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - DragStart

        Main.Position = UDim2.new(
            OriginalPosition.X.Scale,
            OriginalPosition.X.Offset + delta.X,
            OriginalPosition.Y.Scale,
            OriginalPosition.Y.Offset + delta.Y
        )
    end
end)

bind(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

local function cleanup()
    if not Alive then return end

    stopScan()
    Alive = false
    disconnect(Connections)

    Gui:Destroy()
end

ENV.FarhanScannerCleanup = cleanup

refresh()
