
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ENV = getgenv and getgenv() or _G

if type(ENV.FarhanScannerCleanup) == "function" then
    pcall(ENV.FarhanScannerCleanup)
end

local Config = {
    MaxLogs = 120,
    ScanInterval = 0.5,
    MaxChildren = 35
}

local Alive = true
local Scanning = false
local Connections = {}
local ScanConnections = {}
local WatchedTools = {}
local Logs = {}
local LastTool = nil

local function connect(signal, callback, bucket)
    local connection = signal:Connect(callback)
    table.insert(bucket or Connections, connection)
    return connection
end

local function disconnectAll(bucket)
    for _, connection in ipairs(bucket) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(bucket)
end

local function timestamp()
    return string.format("%.2f", os.clock())
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "FarhanStore_DebugScanner"
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(310, 335)
Main.Position = UDim2.new(0, 35, 0.5, -167)
Main.BackgroundColor3 = Color3.fromRGB(7, 15, 27)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 9)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(20, 140, 255)
Stroke.Thickness = 2
Stroke.Parent = Main

local function textObject(class, parent, size, position, value)
    local obj = Instance.new(class)
    obj.Size = size
    obj.Position = position
    obj.BackgroundTransparency = 1
    obj.BorderSizePixel = 0
    obj.Font = Enum.Font.Code
    obj.TextSize = 12
    obj.TextColor3 = Color3.fromRGB(230, 242, 255)
    obj.Text = value or ""
    obj.Parent = parent
    return obj
end

local Header = textObject(
    "TextLabel",
    Main,
    UDim2.new(1, -12, 0, 30),
    UDim2.fromOffset(6, 3),
    "FARHAN STORE | DEBUG SCANNER"
)
Header.TextColor3 = Color3.fromRGB(65, 170, 255)
Header.TextSize = 13

local Status = textObject(
    "TextLabel",
    Main,
    UDim2.new(1, -16, 0, 20),
    UDim2.fromOffset(8, 32),
    "STATUS: IDLE"
)
Status.TextXAlignment = Enum.TextXAlignment.Left

local function button(name, x, width)
    local obj = Instance.new("TextButton")
    obj.Size = UDim2.fromOffset(width, 27)
    obj.Position = UDim2.fromOffset(x, 58)
    obj.BackgroundColor3 = Color3.fromRGB(18, 70, 118)
    obj.BorderSizePixel = 0
    obj.Text = name
    obj.TextColor3 = Color3.new(1, 1, 1)
    obj.Font = Enum.Font.GothamMedium
    obj.TextSize = 11
    obj.Parent = Main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = obj

    return obj
end

local StartButton = button("START", 8, 65)
local StopButton = button("STOP", 79, 65)
local CopyButton = button("COPY LOG", 150, 82)
local ClearButton = button("CLEAR", 238, 64)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -100)
Scroll.Position = UDim2.fromOffset(8, 92)
Scroll.BackgroundColor3 = Color3.fromRGB(3, 10, 20)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(35, 145, 255)
Scroll.CanvasSize = UDim2.fromOffset(0, 0)
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 3)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local function addLog(message)
    if not Alive then return end

    local line = "[" .. timestamp() .. "] " .. tostring(message)
    table.insert(Logs, line)

    while #Logs > Config.MaxLogs do
        table.remove(Logs, 1)
    end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -9, 0, 18)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(195, 220, 245)
    label.Font = Enum.Font.Code
    label.TextSize = 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = line
    label.Parent = Scroll

    local count = 0

    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("TextLabel") then
            count += 1
            if count > Config.MaxLogs then
                child:Destroy()
            end
        end
    end

    task.defer(function()
        if not Alive then return end
        Scroll.CanvasSize = UDim2.fromOffset(
            0,
            Layout.AbsoluteContentSize.Y + 10
        )
        Scroll.CanvasPosition = Vector2.new(
            0,
            math.max(0, Layout.AbsoluteContentSize.Y)
        )
    end)
end

local function inspectTool(tool)
    if not Scanning or not tool:IsA("Tool") then return end

    addLog("TOOL: " .. tool.Name)
    addLog("CLASS: " .. tool.ClassName)
    addLog("ENABLED: " .. tostring(tool.Enabled))
    addLog("REQUIRES HANDLE: " .. tostring(tool.RequiresHandle))

    local descendants = tool:GetDescendants()
    addLog("DESCENDANTS: " .. tostring(#descendants))

    local count = 0

    for _, obj in ipairs(descendants) do
        if count >= Config.MaxChildren then
            addLog("... remaining objects omitted")
            break
        end

        if obj:IsA("ModuleScript")
            or obj:IsA("LocalScript")
            or obj:IsA("Script")
            or obj:IsA("RemoteEvent")
            or obj:IsA("RemoteFunction")
            or obj:IsA("BindableEvent")
            or obj:IsA("BindableFunction")
            or obj:IsA("Animation") then

            addLog(
                "CHILD: "
                .. obj.ClassName
                .. " | "
                .. obj:GetFullName()
            )

            count += 1
        end
    end
end

local function watchTool(tool)
    if not Scanning or not tool:IsA("Tool") then return end
    if WatchedTools[tool] then return end

    WatchedTools[tool] = true

    addLog("FOUND TOOL: " .. tool.Name)
    inspectTool(tool)

    connect(tool.Equipped, function()
        addLog("EQUIPPED: " .. tool.Name)
        inspectTool(tool)
    end, ScanConnections)

    connect(tool.Unequipped, function()
        addLog("UNEQUIPPED: " .. tool.Name)
    end, ScanConnections)

    connect(tool.Activated, function()
        addLog("ACTIVATED: " .. tool.Name)
    end, ScanConnections)

    connect(tool.Deactivated, function()
        addLog("DEACTIVATED: " .. tool.Name)
    end, ScanConnections)

    connect(tool:GetPropertyChangedSignal("Enabled"), function()
        addLog(
            "TOOL ENABLED CHANGED: "
            .. tool.Name
            .. " = "
            .. tostring(tool.Enabled)
        )
    end, ScanConnections)

    connect(tool.DescendantAdded, function(obj)
        addLog(
            "ADDED TO "
            .. tool.Name
            .. ": "
            .. obj.ClassName
            .. " | "
            .. obj.Name
        )
    end, ScanConnections)

    connect(tool.DescendantRemoving, function(obj)
        addLog(
            "REMOVED FROM "
            .. tool.Name
            .. ": "
            .. obj.ClassName
            .. " | "
            .. obj.Name
        )
    end, ScanConnections)
end

local function watchContainer(container)
    if not container then return end

    for _, child in ipairs(container:GetChildren()) do
        watchTool(child)
    end

    connect(container.ChildAdded, function(child)
        if child:IsA("Tool") then
            addLog("TOOL ADDED TO " .. container.Name)
            watchTool(child)
        end
    end, ScanConnections)

    connect(container.ChildRemoved, function(child)
        if child:IsA("Tool") then
            addLog(
                "TOOL REMOVED FROM "
                .. container.Name
                .. ": "
                .. child.Name
            )
        end
    end, ScanConnections)
end

local function startScan()
    if Scanning then return end

    Scanning = true
    Status.Text = "STATUS: SCANNING"
    Status.TextColor3 = Color3.fromRGB(65, 200, 135)

    addLog("SCAN STARTED")
    addLog("PLAYER: " .. Player.Name)
    addLog("PLACE ID: " .. tostring(game.PlaceId))

    table.clear(WatchedTools)

    local backpack = Player:FindFirstChild("Backpack")
    local character = Player.Character

    watchContainer(backpack)
    watchContainer(character)

    connect(Player.CharacterAdded, function(newCharacter)
        addLog("CHARACTER RESPAWNED")
        watchContainer(newCharacter)
    end, ScanConnections)

    connect(UIS.InputBegan, function(input, processed)
        if processed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local tool = Player.Character
                and Player.Character:FindFirstChildOfClass("Tool")

            addLog(
                "LEFT CLICK DOWN | TOOL: "
                .. (tool and tool.Name or "NONE")
            )
        end
    end, ScanConnections)

    connect(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            addLog("LEFT CLICK UP")
        end
    end, ScanConnections)

    addLog("Try equipping and firing a weapon manually")
end

local function stopScan()
    if not Scanning then return end

    Scanning = false
    disconnectAll(ScanConnections)
    table.clear(WatchedTools)

    Status.Text = "STATUS: STOPPED"
    Status.TextColor3 = Color3.fromRGB(255, 190, 75)

    addLog("SCAN STOPPED")
end

connect(StartButton.MouseButton1Click, startScan)
connect(StopButton.MouseButton1Click, stopScan)

connect(CopyButton.MouseButton1Click, function()
    local content = table.concat(Logs, "\n")

    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, content)

        if ok then
            addLog("LOG COPIED")
        else
            addLog("COPY FAILED")
        end
    else
        addLog("CLIPBOARD API NOT AVAILABLE")
    end
end)

connect(ClearButton.MouseButton1Click, function()
    table.clear(Logs)

    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    Scroll.CanvasSize = UDim2.fromOffset(0, 0)
    addLog("LOG CLEARED")
end)

local Dragging = false
local DragStart
local OriginalPosition

connect(Header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        OriginalPosition = Main.Position
    end
end)

connect(UIS.InputChanged, function(input)
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

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

local function cleanup()
    if not Alive then return end

    stopScan()
    Alive = false

    disconnectAll(Connections)

    if Gui then
        Gui:Destroy()
    end
end

ENV.FarhanScannerCleanup = cleanup

addLog("FARHAN DEBUG SCANNER V1 READY")
addLog("Press START to begin")

