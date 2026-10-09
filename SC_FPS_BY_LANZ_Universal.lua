-- SC FPS BY LANZ | Universal lightweight graphics helper
-- Note: Roblox FastFlags cannot generally be changed from an ordinary executor Lua script.
-- This script applies local visual reductions using standard Roblox client APIs instead.
-- UI font: Enum.Font.Arcade for a blocky, Minecraft-like look.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

if not player then
    warn("[SC FPS BY LANZ] LocalPlayer not available. Run this as a client-side script.")
    return
end

local oldGui
pcall(function()
    oldGui = CoreGui:FindFirstChild("SCFPSByLanz")
end)
if not oldGui then
    pcall(function()
        oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("SCFPSByLanz")
    end)
end
if oldGui then oldGui:Destroy() end

local original = {
    GlobalShadows = Lighting.GlobalShadows,
    Effects = {},
    Parts = {},
    Emitters = {},
    TerrainDecoration = nil,
}

local enabled = false
local function rememberAndDisable(obj)
    if obj:IsA("PostEffect") then
        if original.Effects[obj] == nil then original.Effects[obj] = obj.Enabled end
        obj.Enabled = false
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
        if original.Emitters[obj] == nil then original.Emitters[obj] = obj.Enabled end
        obj.Enabled = false
    elseif obj:IsA("BasePart") then
        if original.Parts[obj] == nil then
            original.Parts[obj] = {Material = obj.Material, Reflectance = obj.Reflectance}
        end
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
    end
end

local function applyLowGraphics()
    Lighting.GlobalShadows = false
    pcall(function()
        if Workspace.Terrain then
            if original.TerrainDecoration == nil then
                original.TerrainDecoration = Workspace.Terrain.Decoration
            end
            Workspace.Terrain.Decoration = false
        end
    end)
    for _, obj in ipairs(game:GetDescendants()) do
        pcall(rememberAndDisable, obj)
    end
end

local function restoreGraphics()
    Lighting.GlobalShadows = original.GlobalShadows
    for obj, wasEnabled in pairs(original.Effects) do
        pcall(function() if obj.Parent then obj.Enabled = wasEnabled end end)
    end
    for obj, wasEnabled in pairs(original.Emitters) do
        pcall(function() if obj.Parent then obj.Enabled = wasEnabled end end)
    end
    for obj, props in pairs(original.Parts) do
        pcall(function()
            if obj.Parent then
                obj.Material = props.Material
                obj.Reflectance = props.Reflectance
            end
        end)
    end
    pcall(function()
        if original.TerrainDecoration ~= nil and Workspace.Terrain then
            Workspace.Terrain.Decoration = original.TerrainDecoration
        end
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPSByLanz"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local parented = false
pcall(function()
    if type(gethui) == "function" then
        gui.Parent = gethui()
        parented = true
    end
end)
if not parented then
    pcall(function() gui.Parent = CoreGui; parented = true end)
end
if not parented then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(280, 170)
frame.Position = UDim2.new(0.5, -140, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 190, 95)
stroke.Thickness = 2
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -42, 0, 34)
title.Position = UDim2.fromOffset(10, 4)
title.BackgroundTransparency = 1
title.Text = "SC FPS BY LANZ"
title.TextColor3 = Color3.fromRGB(130, 255, 130)
title.TextSize = 17
title.Font = Enum.Font.Arcade
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28, 26)
close.Position = UDim2.new(1, -34, 0, 6)
close.BackgroundColor3 = Color3.fromRGB(130, 45, 45)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 14
close.Font = Enum.Font.Arcade
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -20, 0, 24)
subtitle.Position = UDim2.fromOffset(10, 40)
subtitle.BackgroundTransparency = 1
subtitle.Text = "LOW GRAPHICS MODE"
subtitle.TextColor3 = Color3.fromRGB(220, 220, 220)
subtitle.TextSize = 12
subtitle.Font = Enum.Font.Arcade
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 38)
toggle.Position = UDim2.fromOffset(10, 72)
toggle.BackgroundColor3 = Color3.fromRGB(45, 105, 50)
toggle.Text = "ENABLE FPS MODE"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.TextSize = 13
toggle.Font = Enum.Font.Arcade
toggle.Parent = frame
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 5)

local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -20, 0, 42)
note.Position = UDim2.fromOffset(10, 119)
note.BackgroundTransparency = 1
note.Text = "Client visuals only; FPS gain depends on the game/device."
note.TextWrapped = true
note.TextColor3 = Color3.fromRGB(175, 175, 175)
note.TextSize = 10
note.Font = Enum.Font.Arcade
note.Parent = frame

-- Drag window using the title area; works with mouse/touch input.
do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        applyLowGraphics()
        toggle.Text = "DISABLE FPS MODE"
        toggle.BackgroundColor3 = Color3.fromRGB(130, 55, 45)
        subtitle.Text = "FPS MODE: ON"
    else
        restoreGraphics()
        toggle.Text = "ENABLE FPS MODE"
        toggle.BackgroundColor3 = Color3.fromRGB(45, 105, 50)
        subtitle.Text = "LOW GRAPHICS MODE"
    end
end)

close.MouseButton1Click:Connect(function()
    if enabled then restoreGraphics() end
    gui:Destroy()
end)

print("[SC FPS BY LANZ] Loaded. Click ENABLE FPS MODE to reduce local visual effects.")
