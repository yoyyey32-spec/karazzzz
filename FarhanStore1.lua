FPSLabel = infoLabel('FPS: --', UDim2.new(.57, 0, 0, 0), UDim2.new(.43, -7, 1, 0), Enum.TextXAlignment.Right)
Status = Instance.new('TextLabel')
Status.Size = UDim2.new(1, -20, 0, 19)
Status.Position = UDim2.fromOffset(10, 167)
Status.BackgroundTransparency = 1
Status.TextSize = 11
Status.Font = Enum.Font.GothamMedium
Status.Parent = Main

bind(EnableButton.MouseButton1Click, function()
    if Busy then return end
    if Enabled then disable() else task.spawn(enable) end
end)
bind(LightButton.MouseButton1Click, function()
    if Busy then return end
    FullBright = not FullBright
    applyLighting()
    refresh()
end)
bind(Minimize.MouseButton1Click, function()
    Minimized = not Minimized
    EnableButton.Visible = not Minimized
    LightButton.Visible = not Minimized
    Info.Visible = not Minimized
    Status.Visible = not Minimized
    Main.Size = Minimized and UDim2.fromOffset(225, 39) or UDim2.fromOffset(225, 192)
    Minimize.Text = Minimized and '+' or '-'
end)
bind(UIS.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightAlt then
        GUI.Enabled = not GUI.Enabled
    end
end)

local Dragging, DragStart, StartPosition = false, nil, nil
bind(Header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
    end
end)
bind(UIS.InputChanged, function(input)
    if not Dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - DragStart
        Main.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y)
    end
end)
bind(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = false
    end
end)

bind(game.DescendantAdded, function(obj)
    if not Alive or not Enabled then return end
    if GUI and (obj == GUI or obj:IsDescendantOf(GUI)) then return end
    local valid = false
    pcall(function() valid = obj:IsDescendantOf(Workspace) or obj:IsDescendantOf(Lighting) or obj:IsDescendantOf(PlayerGui) end)
    if valid then pcall(optimize, obj) end
end)

local frames, lastFPS = 0, os.clock()
bind(RunService.RenderStepped, function()
    frames += 1
    local now = os.clock()
    local elapsed = now - lastFPS
    if elapsed >= .5 then
        FPS = math.floor(frames / elapsed + .5)
        frames = 0
        lastFPS = now
    end
end)

task.spawn(function()
    while Alive do
        local display = '--'
        pcall(function()
            local item = Stats.Network.ServerStatsItem['Data Ping']
            local number = tonumber(item:GetValueString():match('[%d%.]+'))
            if number then Ping = math.floor(number + .5); display = tostring(Ping) end
        end)
        if PingLabel then PingLabel.Text = 'PING: ' .. display .. ' ms' end
        if FPSLabel then FPSLabel.Text = 'FPS: ' .. FPS end
        task.wait(.2)
    end
end)

local function cleanup()
    if not Alive then return end
    Alive = false
    if Enabled or Busy then
        Enabled = false
        for obj, properties in pairs(Saved) do
            for property, original in pairs(properties) do
                pcall(function() obj[property] = original[1] end)
            end
        end
        if OriginalQuality ~= nil then
            pcall(function() settings().Rendering.QualityLevel = OriginalQuality end)
        end
    end
    FullBright = false
    applyLighting()
    for _, connection in ipairs(Connections) do pcall(function() connection:Disconnect() end) end
    if GUI then GUI:Destroy() end
end
ENV.FarhanFPSOnlyCleanup = cleanup
refresh()
print('FARHAN STORE | FPS ONLY EXTREME V2.6')
