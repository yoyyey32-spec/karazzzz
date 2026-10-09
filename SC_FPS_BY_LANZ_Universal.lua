-- SC FPS | Farhan Store - lightweight client visual helper
-- IMPORTANT: This LocalScript cannot set Roblox FastFlags. It only changes local visual properties.
-- Enum.Font.Arcade is a built-in blocky font; an exact Minecraft font requires a supported custom font asset.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then warn("Run on the client."); return end

local playerGui = player:WaitForChild("PlayerGui")
pcall(function() local old = playerGui:FindFirstChild("SCFPSFarhanStore"); if old then old:Destroy() end end)

local gui = Instance.new("ScreenGui")
gui.Name = "SCFPSFarhanStore"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local ok = pcall(function() if type(gethui) == "function" then gui.Parent = gethui() end end)
if not ok or not gui.Parent then gui.Parent = playerGui end

local C = {
  bg = Color3.fromRGB(13, 18, 23), panel = Color3.fromRGB(22, 29, 36), panel2 = Color3.fromRGB(29, 39, 47),
  green = Color3.fromRGB(58, 220, 112), greenDark = Color3.fromRGB(24, 111, 62), text = Color3.fromRGB(240, 246, 242),
  muted = Color3.fromRGB(155, 173, 166), red = Color3.fromRGB(225, 82, 82), line = Color3.fromRGB(49, 69, 62)
}
local function make(class, props, parent)
  local obj = Instance.new(class)
  for k,v in pairs(props or {}) do obj[k] = v end
  obj.Parent = parent
  return obj
end
local function corner(obj, radius) make("UICorner", {CornerRadius=UDim.new(0,radius or 8)}, obj) end
local function stroke(obj, color, thickness) make("UIStroke", {Color=color or C.line, Thickness=thickness or 1}, obj) end
local function label(parent, text, size, pos, fontSize, color, font)
  return make("TextLabel", {BackgroundTransparency=1, Text=text, Size=size, Position=pos, Font=font or Enum.Font.Arcade,
    TextSize=fontSize or 14, TextColor3=color or C.text, TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Center, TextWrapped=true}, parent)
end

local main = make("Frame", {Name="Main", Size=UDim2.fromOffset(390, 330), Position=UDim2.new(0.5,-195,0.5,-165),
  BackgroundColor3=C.bg, BorderSizePixel=0, Active=true}, gui)
corner(main, 12); stroke(main, C.green, 1.5)
local top = make("Frame", {Size=UDim2.new(1,0,0,64), BackgroundColor3=C.panel, BorderSizePixel=0}, main); corner(top,12)
make("Frame", {Position=UDim2.new(0,0,1,-2), Size=UDim2.new(1,0,0,2), BackgroundColor3=C.green, BorderSizePixel=0}, top)
label(top, "SC FPS", UDim2.new(1,-65,0,31), UDim2.fromOffset(15,5), 22, C.green)
label(top, "FARHAN STORE  •  LIGHTWEIGHT MODE", UDim2.new(1,-22,0,20), UDim2.fromOffset(16,36), 10, C.muted, Enum.Font.Code)
local close = make("TextButton", {Size=UDim2.fromOffset(30,30), Position=UDim2.new(1,-40,0,12), BackgroundColor3=C.panel2,
  BorderSizePixel=0, Text="X", Font=Enum.Font.Arcade, TextSize=14, TextColor3=C.text, AutoButtonColor=true}, top)
corner(close,7)

local status = make("Frame", {Size=UDim2.new(1,-24,0,42), Position=UDim2.fromOffset(12,76), BackgroundColor3=C.panel, BorderSizePixel=0}, main)
corner(status,8); stroke(status,C.line,1)
label(status,"●  LOCAL VISUAL MODE",UDim2.new(1,-16,1,0),UDim2.fromOffset(10,0),12,C.green)

local saved = {shadows=Lighting.GlobalShadows, effects={}, parts={}, terrain=nil}
local enabled = false
local function setVisuals(on)
  enabled = on
  if on then
    saved.shadows = Lighting.GlobalShadows
    Lighting.GlobalShadows = false
    pcall(function() saved.terrain = Workspace.Terrain.Decoration; Workspace.Terrain.Decoration = false end)
    -- Only change workspace visuals; keep a snapshot so they can be restored.
    for _, obj in ipairs(Workspace:GetDescendants()) do
      pcall(function()
        if obj:IsA("PostEffect") then
          if saved.effects[obj] == nil then saved.effects[obj] = obj.Enabled end
          obj.Enabled = false
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
          if saved.effects[obj] == nil then saved.effects[obj] = obj.Enabled end
          obj.Enabled = false
        elseif obj:IsA("BasePart") then
          if saved.parts[obj] == nil then saved.parts[obj] = {obj.Material, obj.Reflectance} end
          obj.Material = Enum.Material.SmoothPlastic
          obj.Reflectance = 0
        end
      end)
    end
  else
    Lighting.GlobalShadows = saved.shadows
    for obj, wasEnabled in pairs(saved.effects) do pcall(function() if obj.Parent then obj.Enabled = wasEnabled end end) end
    for obj, props in pairs(saved.parts) do pcall(function() if obj.Parent then obj.Material=props[1]; obj.Reflectance=props[2] end end) end
    pcall(function() if saved.terrain ~= nil then Workspace.Terrain.Decoration = saved.terrain end end)
  end
end

local function actionButton(y, titleText, descText, accent, callback)
  local row = make("Frame", {Size=UDim2.new(1,-24,0,55), Position=UDim2.fromOffset(12,y), BackgroundColor3=C.panel, BorderSizePixel=0}, main)
  corner(row,8); stroke(row,C.line,1)
  label(row,titleText,UDim2.new(1,-115,0,25),UDim2.fromOffset(11,3),13,accent)
  label(row,descText,UDim2.new(1,-115,0,19),UDim2.fromOffset(11,29),10,C.muted,Enum.Font.Code)
  local btn = make("TextButton", {Size=UDim2.fromOffset(92,32), Position=UDim2.new(1,-102,0.5,-16), BackgroundColor3=C.greenDark,
    BorderSizePixel=0, Text="OFF", Font=Enum.Font.Arcade, TextSize=12, TextColor3=C.text}, row)
  corner(btn,7)
  btn.MouseButton1Click:Connect(function() callback(btn) end)
  return btn
end

local fpsButton = actionButton(128,"FPS BOOST","Kurangi efek visual lokal",C.green,function(btn)
  setVisuals(not enabled)
  btn.Text = enabled and "ON" or "OFF"
  btn.BackgroundColor3 = enabled and C.greenDark or C.panel2
end)
local textureButton = actionButton(190,"TEXTURE / MATERIAL","Material lokal jadi SmoothPlastic",C.text,function(btn)
  -- Texture images are not FastFlags; this visual helper only simplifies part materials.
  local on = btn:GetAttribute("On") ~= true
  btn:SetAttribute("On",on)
  if on then
    for _, obj in ipairs(Workspace:GetDescendants()) do
      if obj:IsA("BasePart") then
        if saved.parts[obj] == nil then saved.parts[obj] = {obj.Material, obj.Reflectance} end
        pcall(function() obj.Material=Enum.Material.SmoothPlastic; obj.Reflectance=0 end)
      end
    end
    btn.Text="ON"; btn.BackgroundColor3=C.greenDark
  else
    for obj,props in pairs(saved.parts) do pcall(function() if obj.Parent then obj.Material=props[1]; obj.Reflectance=props[2] end end) end
    btn.Text="OFF"; btn.BackgroundColor3=C.panel2
  end
end)

local info = make("Frame", {Size=UDim2.new(1,-24,0,46), Position=UDim2.fromOffset(12,252), BackgroundColor3=C.panel2, BorderSizePixel=0}, main)
corner(info,8)
label(info,"FAST FLAGS: tidak bisa diubah dari executor Lua",UDim2.new(1,-16,0,20),UDim2.fromOffset(9,3),10,C.green,Enum.Font.Code)
label(info,"Font Arcade = gaya pixel; bukan font Minecraft asli.",UDim2.new(1,-16,0,18),UDim2.fromOffset(9,23),9,C.muted,Enum.Font.Code)

-- Drag window from the header.
do
  local dragging, dragInput, dragStart, startPos
  top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging=true; dragStart=input.Position; startPos=main.Position
      input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
  end)
  UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
      local delta=input.Position-dragStart
      main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
  end)
end
close.MouseButton1Click:Connect(function() if enabled then setVisuals(false) end; gui:Destroy() end)
print("[SC FPS Farhan Store] Loaded. FastFlags are not modified by this script.")
