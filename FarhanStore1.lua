print('[Farhan FPS] V3.0: script started')
local __ok, __err = xpcall(function()
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local Lighting = game:GetService('Lighting')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Stats = game:GetService('Stats')
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild('PlayerGui')
local ENV = getgenv and getgenv() or _G

if type(ENV.FarhanFPSOnlyCleanup) == 'function' then
    pcall(ENV.FarhanFPSOnlyCleanup)
end

local Alive, Enabled, FullBright, Busy, Minimized = true, false, false, false, false
local Saved = {}
local FontSaved = {}
local FontGuards = {}
local EffectGuards = {}
local GraySky = Color3.fromRGB(105, 105, 105)
local CustomFont
pcall(function() CustomFont = Font.fromId(12187372382) end)
local Detached = {}
local Connections = {}
local OriginalQuality
local OriginalLighting = {}
local GUI, Main, EnableButton, LightButton, Status, PingLabel, FPSLabel
local FPS, Ping = 0, nil
local Theme = {
    Back = Color3.fromRGB(7, 12, 23),
    Panel = Color3.fromRGB(12, 25, 47),
    Off = Color3.fromRGB(22, 37, 60),
    On = Color3.fromRGB(0, 110, 245),
    Text = Color3.fromRGB(235, 245, 255),
    Muted = Color3.fromRGB(112, 193, 255)
}

local function bind(signal, callback)
    local connection = signal:Connect(callback)
    Connections[#Connections + 1] = connection
    return connection
end

local function setSaved(obj, property, value)
    if not obj then return end
    local ok, original = pcall(function() return obj[property] end)
    if not ok then return end
    if not Saved[obj] then Saved[obj] = {} end
    if Saved[obj][property] == nil then
        Saved[obj][property] = {original}
    end
    pcall(function() obj[property] = value end)
end

local function applyFont(obj)
    if not CustomFont then return end
    if not (obj:IsA('TextLabel') or obj:IsA('TextButton') or obj:IsA('TextBox')) then return end
    if FontSaved[obj] == nil then
        local ok, old = pcall(function() return obj.FontFace end)
        if ok then FontSaved[obj] = old end
    end
    pcall(function() obj.FontFace = CustomFont end)
    if not FontGuards[obj] then
        FontGuards[obj] = bind(obj:GetPropertyChangedSignal('FontFace'), function()
            if Alive and obj.Parent and CustomFont and obj.FontFace ~= CustomFont then
                pcall(function() obj.FontFace = CustomFont end)
            end
        end)
    end
end

local function scanFonts(root)
    applyFont(root)
    for _, obj in ipairs(root:GetDescendants()) do applyFont(obj) end
end

local function isProtected(obj)
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char and (obj == char or obj:IsDescendantOf(char)) then return true end
    end
    if obj:FindFirstAncestorOfClass('Tool') then return true end
    if obj:FindFirstAncestorOfClass('Accessory') then return true end
    if obj:FindFirstAncestorOfClass('VehicleSeat') then return true end
    return false
end

local function nameContains(name, words)
    name = name:lower()
    for _, word in ipairs(words) do
        if name:find(word, 1, true) then return true end
    end
    return false
end

local function hasImportantAncestor(obj)
    local current = obj
    while current and current ~= Workspace do
        if nameContains(current.Name, {
            'door', 'gate', 'handle', 'button', 'prompt', 'weapon', 'gunstore',
            'gun store', 'register', 'counter', 'floor', 'road', 'street',
            'sidewalk', 'stairs', 'ladder', 'bridge', 'vehicle', 'car', 'wheel',
            'spawn', 'shop', 'apartment', 'loot', 'interact', 'seat'
        }) then return true end
        current = current.Parent
    end
    return false
end

local function shootEffect(obj)
    local current = obj
    while current and current ~= game do
        if nameContains(current.Name, {
            'muzzle', 'flash', 'gunfire', 'shoot', 'shotfx', 'gunsmoke',
            'blood', 'bleed', 'splatter', 'hitfx', 'impactfx', 'bulletfx',
            'blooddrop', 'bloodparticle', 'bloodsplatter', 'bloodstain',
            'hitmarkerfx', 'wound', 'droplet', 'drip', 'hitparticle',
            'recoilblur', 'gunfx', 'smoke', 'spark', 'shellfx'
        }) then return true end
        current = current.Parent
    end
    return false
end

local function suppressEffect(obj)
    if obj:IsA('ParticleEmitter') then
        setSaved(obj, 'Enabled', false)
        setSaved(obj, 'Rate', 0)
        pcall(function() obj:Clear() end)
    elseif obj:IsA('Trail') or obj:IsA('Beam') or obj:IsA('Smoke')
        or obj:IsA('Fire') or obj:IsA('Sparkles') or obj:IsA('Highlight')
        or obj:IsA('PostEffect') or obj:IsA('Light') then
        setSaved(obj, 'Enabled', false)
    elseif obj:IsA('Decal') or obj:IsA('Texture') then
        setSaved(obj, 'Transparency', 1)
    elseif obj:IsA('BasePart') and shootEffect(obj) and not isProtected(obj) then
        setSaved(obj, 'LocalTransparencyModifier', 1)
    end
    if (obj:IsA('ParticleEmitter') or obj:IsA('Trail') or obj:IsA('Beam')
        or obj:IsA('Smoke') or obj:IsA('Fire') or obj:IsA('Sparkles')) and not EffectGuards[obj] then
        EffectGuards[obj] = bind(obj:GetPropertyChangedSignal('Enabled'), function()
            if Alive and Enabled and obj.Parent and obj.Enabled then
                pcall(function() obj.Enabled = false end)
                if obj:IsA('ParticleEmitter') then pcall(function() obj:Clear() end) end
            end
        end)
    end
end

local function visualEffect(obj)
    return obj:IsA('ParticleEmitter') or obj:IsA('Smoke')
        or obj:IsA('Fire') or obj:IsA('Sparkles')
        or obj:IsA('Trail') or obj:IsA('Beam')
        or obj:IsA('PostEffect')
end

local function isFoliage(obj)
    if not obj:IsA('BasePart') or isProtected(obj) then return false end
    if not obj.Anchored or obj.CanCollide or obj.CanTouch then return false end
    if hasImportantAncestor(obj) then return false end
    if obj:FindFirstChildWhichIsA('ProximityPrompt', true)
        or obj:FindFirstChildWhichIsA('ClickDetector', true) then return false end
    local current = obj
    while current and current ~= Workspace do
        if nameContains(current.Name, {
            'leaf', 'leaves', 'foliage', 'bush', 'shrub', 'semak',
            'grass', 'rumput', 'weed', 'flower', 'fern', 'plant',
            'vegetation', 'ranting', 'twig'
        }) then return true end
        current = current.Parent
    end
    return false
end

local function isSafeDecoration(obj)
    if not obj:IsA('BasePart') or isProtected(obj) then return false end
    if not obj.Anchored or obj.CanCollide or obj.CanTouch or obj.CanQuery then return false end
    if hasImportantAncestor(obj) then return false end
    if obj:FindFirstChildWhichIsA('ProximityPrompt', true) then return false end
    if obj:FindFirstChildWhichIsA('ClickDetector', true) then return false end
    if obj:FindFirstChildWhichIsA('TouchTransmitter', true) then return false end
    return nameContains(obj.Name, {
        'debris', 'trash', 'garbage', 'litter', 'rubbish', 'paper',
        'leaf', 'leaves', 'grass', 'bush', 'weed', 'decor', 'decoration',
        'poster', 'graffiti', 'rubble', 'pebble', 'smallrock',
        'flower', 'twig', 'branch', 'can', 'bottle', 'scrap', 'clutter'
    })
end

local function optimize(obj)
    if not Alive or not Enabled or not obj or not obj.Parent then return end
    if GUI and (obj == GUI or obj:IsDescendantOf(GUI)) then return end

    if visualEffect(obj) then
        suppressEffect(obj)
        return
    end
    if shootEffect(obj) and (obj:IsA('Light') or obj:IsA('Decal') or obj:IsA('Texture')
        or (obj:IsA('BasePart') and not isProtected(obj))) then
        suppressEffect(obj)
        return
    end

    if obj:IsA('BloomEffect') or obj:IsA('BlurEffect') or obj:IsA('SunRaysEffect')
        or obj:IsA('DepthOfFieldEffect') or obj:IsA('ColorCorrectionEffect') then
        setSaved(obj, 'Enabled', false)
        return
    end

    if obj:IsA('Highlight') then
        if not isProtected(obj) then setSaved(obj, 'Enabled', false) end
        return
    end

    if obj:IsA('PointLight') or obj:IsA('SpotLight') or obj:IsA('SurfaceLight') then
        setSaved(obj, 'Shadows', false)
        if nameContains(obj.Name, {'muzzle', 'flash', 'gunfire', 'shot', 'gunfx'}) then
            setSaved(obj, 'Enabled', false)
        end
        return
    end

    if obj:IsA('Decal') or obj:IsA('Texture') then
        if not isProtected(obj) or shootEffect(obj) then setSaved(obj, 'Transparency', 1) end
        return
    end

    if obj:IsA('SurfaceAppearance') then
        if not isProtected(obj) then
            setSaved(obj, 'ColorMap', '')
            setSaved(obj, 'NormalMap', '')
            setSaved(obj, 'MetalnessMap', '')
            setSaved(obj, 'RoughnessMap', '')
        end
        return
    end

    if obj:IsA('SpecialMesh') then
        if not isProtected(obj) then setSaved(obj, 'TextureId', '') end
        return
    end

    if obj:IsA('BasePart') then
        if isProtected(obj) then return end
        if isFoliage(obj) or isSafeDecoration(obj) then
            -- Local visual hiding only; do not destroy or reparent gameplay geometry.
            setSaved(obj, 'LocalTransparencyModifier', 1)
            return
        end
        local partName = obj.Name:lower()
        local parentName = obj.Parent and obj.Parent.Name:lower() or ''
        local doorPanel = nameContains(partName, {'door', 'glasspanel', 'glass pane'})
            or (nameContains(parentName, {'door'}) and nameContains(partName, {'panel', 'glass', 'window'}))
        if doorPanel and not nameContains(partName, {'handle', 'hinge', 'knob', 'frame', 'hitbox', 'collision'}) and obj.Transparency < 0.5 then
            setSaved(obj, 'Material', Enum.Material.Glass)
            setSaved(obj, 'Color', Color3.fromRGB(110, 110, 110))
            setSaved(obj, 'Transparency', 0.48)
            setSaved(obj, 'Reflectance', 0)
            setSaved(obj, 'CastShadow', false)
            return
        end
        setSaved(obj, 'Material', Enum.Material.Plastic)
        setSaved(obj, 'MaterialVariant', '')
        -- Flat, aggressively reduced palette for environmental geometry.
        -- Do not recolor gameplay tools, character, or interactable parts.
        local n = obj.Name:lower()
        local surface = obj.Parent
        while surface and surface ~= Workspace do
            if nameContains(surface.Name, {'road', 'street', 'asphalt', 'pavement', 'sidewalk', 'curb'}) then
                n = n .. ' ' .. surface.Name:lower()
                break
            end
            surface = surface.Parent
        end
        local c = obj.Color
        local gray = math.floor((c.R * 0.299 + c.G * 0.587 + c.B * 0.114) * 255 / 64 + .5) * 64
        gray = math.clamp(math.floor(gray / 64 + 0.5) * 64, 48, 176)
        if nameContains(n, {'road', 'street', 'asphalt', 'pavement'}) then
            setSaved(obj, 'Color', Color3.fromRGB(72, 72, 72))
        elseif nameContains(n, {'sidewalk', 'concrete', 'curb'}) then
            setSaved(obj, 'Color', Color3.fromRGB(112, 112, 112))
        elseif not hasImportantAncestor(obj) then
            setSaved(obj, 'Color', Color3.fromRGB(gray, gray, gray))
        end
        setSaved(obj, 'Reflectance', 0)
        -- Preserve original Transparency: invisible helper/hitbox parts must stay invisible.
        setSaved(obj, 'CastShadow', false)
        if obj:IsA('MeshPart') then
            setSaved(obj, 'TextureID', '')
            setSaved(obj, 'RenderFidelity', Enum.RenderFidelity.Performance)
            pcall(function() setSaved(obj, 'DoubleSided', false) end)
        end
        return
    end

    if obj:IsA('Clouds') then
        setSaved(obj, 'Enabled', false)
    elseif obj:IsA('Atmosphere') then
        setSaved(obj, 'Density', 0)
        setSaved(obj, 'Haze', 0)
        setSaved(obj, 'Glare', 0)
    elseif obj:IsA('Sky') then
        for _, property in ipairs({
            'SkyboxBk', 'SkyboxDn', 'SkyboxFt',
            'SkyboxLf', 'SkyboxRt', 'SkyboxUp'
        }) do setSaved(obj, property, '') end
        setSaved(obj, 'CelestialBodiesShown', false)
        setSaved(obj, 'StarCount', 0)
    end
end

for _, property in ipairs({
    'Brightness', 'Ambient', 'OutdoorAmbient', 'ExposureCompensation',
    'GlobalShadows', 'EnvironmentDiffuseScale', 'EnvironmentSpecularScale',
    'ShadowSoftness', 'FogColor', 'FogStart', 'FogEnd', 'ClockTime', 'GeographicLatitude'
}) do
    pcall(function() OriginalLighting[property] = Lighting[property] end)
end

local function applyLighting()
    for property, value in pairs(OriginalLighting) do
        pcall(function() Lighting[property] = value end)
    end
    if Enabled then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            Lighting.ShadowSoftness = 0
            Lighting.FogColor = GraySky
            Lighting.FogStart = 180
            Lighting.FogEnd = 900
            Lighting.ClockTime = 12
            Lighting.GeographicLatitude = 0
            Lighting.Ambient = Color3.fromRGB(90, 90, 90)
            Lighting.OutdoorAmbient = GraySky
            Lighting.Brightness = 1
            Lighting.ExposureCompensation = 0
        end)
    end
    if FullBright then
        pcall(function()
            Lighting.Brightness = 1.35
            Lighting.Ambient = Color3.fromRGB(95, 95, 95)
            Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 105)
            Lighting.ExposureCompensation = 0
        end)
    end
end

local function refresh()
    if not Alive or not EnableButton then return end
    EnableButton.BackgroundColor3 = Enabled and Theme.On or Theme.Off
    LightButton.BackgroundColor3 = FullBright and Theme.On or Theme.Off
    EnableButton.Text = 'Enabled'
    LightButton.Text = 'Light'
    Status.Text = Busy and 'PROCESSING...' or (Enabled and 'EXTREME ACTIVE' or 'READY')
    Status.TextColor3 = Enabled and Color3.fromRGB(89, 232, 161) or Theme.Muted
end

local function scan(root)
    local objects = root:GetDescendants()
    for index, obj in ipairs(objects) do
        if not Alive or not Enabled then return end
        pcall(optimize, obj)
        if index % 180 == 0 then task.wait() end
    end
end

local function enable()
    if Busy or Enabled or not Alive then return end
    Busy, Enabled = true, true
    refresh()
    local terrain = Workspace.Terrain
    setSaved(terrain, 'Decoration', false)
    setSaved(terrain, 'GrassLength', 0)
    setSaved(terrain, 'WaterWaveSize', 0)
    setSaved(terrain, 'WaterWaveSpeed', 0)
    setSaved(terrain, 'WaterReflectance', 0)
    setSaved(terrain, 'WaterTransparency', 1)
    pcall(function()
        local rendering = settings().Rendering
        if OriginalQuality == nil then OriginalQuality = rendering.QualityLevel end
        rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    applyLighting()
    for _, root in ipairs({Lighting, Workspace, PlayerGui}) do
        if not Enabled or not Alive then break end
        local ok, err = pcall(scan, root)
        if not ok then warn('[Farhan FPS] Scan error:', err) end
        task.wait()
    end
    Busy = false
    refresh()
end

local function disable()
    if not Enabled and not Busy then return end
    Enabled = false
    Busy = true
    refresh()
    for obj, connection in pairs(EffectGuards) do pcall(function() connection:Disconnect() end); EffectGuards[obj] = nil end
    for obj, properties in pairs(Saved) do
        for property, original in pairs(properties) do
            pcall(function() obj[property] = original[1] end)
        end
        Saved[obj] = nil
    end
    table.clear(Detached)
    if OriginalQuality ~= nil then
        pcall(function() settings().Rendering.QualityLevel = OriginalQuality end)
        OriginalQuality = nil
    end
    applyLighting()
    Busy = false
    refresh()
end

local function corner(parent, radius)
    local c = Instance.new('UICorner')
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

GUI = Instance.new('ScreenGui')
GUI.Name = 'FarhanStore_FPS_ONLY_EXTREME_V31'
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

Main = Instance.new('Frame')
Main.Size = UDim2.fromOffset(225, 207)
Main.Position = UDim2.new(0, 24, 0.5, -103)
Main.BackgroundColor3 = Theme.Back
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = GUI
corner(Main, 12)

local outline = Instance.new('UIStroke')
outline.Color = Color3.fromRGB(75, 159, 255)
outline.Thickness = 1.3
outline.Parent = Main

local Header = Instance.new('Frame')
Header.Size = UDim2.new(1, 0, 0, 53)
Header.BackgroundColor3 = Theme.Panel
Header.BorderSizePixel = 0
Header.Active = true
Header.Parent = Main
corner(Header, 12)

local Title = Instance.new('TextLabel')
Title.Size = UDim2.new(1, -50, 0, 29)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.RichText = true
Title.Text = '<font color="#FFFFFF">Farhan</font><font color="#168BFF">Store</font>'
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.Parent = Header

local Subtitle = Instance.new('TextLabel')
Subtitle.Name = 'FPSSubtitle'
Subtitle.Size = UDim2.new(1, -24, 0, 16)
Subtitle.Position = UDim2.fromOffset(12, 29)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = 'FPS'
Subtitle.TextColor3 = Theme.On
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextXAlignment = Enum.TextXAlignment.Center
Subtitle.Parent = Header

local Minimize = Instance.new('TextButton')
Minimize.Size = UDim2.fromOffset(21, 21)
Minimize.Position = UDim2.new(1, -31, 0, 9)
Minimize.BackgroundColor3 = Theme.On
Minimize.Text = '-'
Minimize.TextSize = 16
Minimize.TextColor3 = Theme.Text
Minimize.BorderSizePixel = 0
Minimize.Parent = Header
corner(Minimize, 10)

local Accent = Instance.new('Frame')
Accent.Size = UDim2.new(1, -24, 0, 2)
Accent.Position = UDim2.fromOffset(12, 53)
Accent.BackgroundColor3 = Theme.On
Accent.BorderSizePixel = 0
Accent.Parent = Main

local function makeButton(y)
    local b = Instance.new('TextButton')
    b.Size = UDim2.new(1, -28, 0, 33)
    b.Position = UDim2.fromOffset(14, y)
    b.BackgroundColor3 = Theme.Off
    b.BorderSizePixel = 0
    b.TextColor3 = Theme.Text
    b.TextSize = 15
    b.Font = Enum.Font.GothamMedium
    b.Parent = Main
    corner(b, 8)
    local s = Instance.new('UIStroke')
    s.Color = Color3.fromRGB(48, 89, 145)
    s.Parent = b
    return b
end

EnableButton = makeButton(65)
LightButton = makeButton(106)

local Info = Instance.new('Frame')
Info.Size = UDim2.new(1, -28, 0, 27)
Info.Position = UDim2.fromOffset(14, 149)
Info.BackgroundColor3 = Color3.fromRGB(11, 22, 40)
Info.BorderSizePixel = 0
Info.Parent = Main
corner(Info, 6)

local function infoLabel(text, pos, size, alignment)
    local label = Instance.new('TextLabel')
    label.Size = size
    label.Position = pos
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Muted
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = alignment
    label.Parent = Info
    return label
end

PingLabel = infoLabel('PING: -- ms', UDim2.fromOffset(7, 0), UDim2.new(.57, -7, 1, 0), Enum.TextXAlignment.Left)
FPSLabel = infoLabel('FPS: --', UDim2.new(.57, 0, 0, 0), UDim2.new(.43, -7, 1, 0), Enum.TextXAlignment.Right)
Status = Instance.new('TextLabel')
Status.Size = UDim2.new(1, -20, 0, 19)
Status.Position = UDim2.fromOffset(10, 181)
Status.BackgroundTransparency = 1
Status.TextSize = 11
Status.Font = Enum.Font.GothamMedium
Status.Parent = Main

bind(EnableButton.MouseButton1Click, function()
    if Busy then return end
    if Enabled then disable() else task.spawn(function()
        local ok, err = pcall(enable)
        if not ok then Busy = false; Status.Text = 'ERROR - CHECK CONSOLE'; warn('[Farhan FPS] Enable error:', err) end
    end) end
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
    Main.Size = Minimized and UDim2.fromOffset(225, 53) or UDim2.fromOffset(225, 207)
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
    if not Alive then return end
    if obj:IsDescendantOf(PlayerGui) or (GUI and obj:IsDescendantOf(GUI)) then
        applyFont(obj)
    end
    if not Enabled then return end
    if GUI and (obj == GUI or obj:IsDescendantOf(GUI)) then return end
    local valid = false
    pcall(function() valid = obj:IsDescendantOf(Workspace) or obj:IsDescendantOf(Lighting) or obj:IsDescendantOf(PlayerGui) end)
    if valid then pcall(optimize, obj) end
end)

task.spawn(function()
    while Alive do
        if Enabled and not Busy then
            applyLighting()
            -- Weather/time scripts may replace effects; only revisit the small effects set.
            for _, root in ipairs({Lighting, Workspace.CurrentCamera}) do
                if root then
                    for _, obj in ipairs(root:GetDescendants()) do
                        if not Alive or not Enabled then break end
                        if visualEffect(obj) or obj:IsA('Sky') or obj:IsA('Atmosphere') or obj:IsA('Clouds') then
                            pcall(optimize, obj)
                        end
                    end
                end
            end
        end
        task.wait(2)
    end
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
    for obj, connection in pairs(EffectGuards) do pcall(function() connection:Disconnect() end); EffectGuards[obj] = nil end
    applyLighting()
    for obj, connection in pairs(FontGuards) do pcall(function() connection:Disconnect() end); FontGuards[obj] = nil end
    for obj, original in pairs(FontSaved) do
        pcall(function() obj.FontFace = original end)
        FontSaved[obj] = nil
    end
    for _, connection in ipairs(Connections) do pcall(function() connection:Disconnect() end) end
    if GUI then GUI:Destroy() end
end
ENV.FarhanFPSOnlyCleanup = cleanup
scanFonts(PlayerGui)
scanFonts(GUI)
refresh()
print('FARHAN STORE | FPS ONLY EXTREME V2.9')

end, function(err) return tostring(err) .. '\n' .. debug.traceback() end)
if not __ok then
    warn('[Farhan FPS] STARTUP ERROR: ' .. tostring(__err))
    pcall(function()
        local p = game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')
        local g = Instance.new('ScreenGui'); g.Name = 'FarhanFPS_Error'; g.ResetOnSpawn = false; g.Parent = p
        local t = Instance.new('TextLabel'); t.Size = UDim2.fromOffset(340, 90); t.Position = UDim2.fromOffset(20, 100)
        t.BackgroundColor3 = Color3.fromRGB(40, 10, 15); t.TextColor3 = Color3.new(1,1,1)
        t.TextWrapped = true; t.Text = 'FARHAN FPS STARTUP ERROR\n' .. tostring(__err):sub(1,180); t.Parent = g
    end)
end
