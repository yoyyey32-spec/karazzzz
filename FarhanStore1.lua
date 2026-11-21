local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

local Settings = {
    Aimbot = { Enabled = false, Silent = false, FOV = 200, Bone = "Head", CheckFriend = true },
    KillAura = { Enabled = false, Range = 18, Speed = 0.1, Headshot = true },
    JobAura = { Enabled = false, Range = 25, AutoEquip = true },
    Esp = { Enabled = false, Box = true, Name = true },
    Farm = { Amount = 50, Mallow = false, Multi = false, Rejoin = false },
    Player = { Walk = false, Speed = 30, Fly = false, FlySpeed = 50, Noclip = false, God = false, Fullbright = false, Fps = false, Ammo = false, Spin = false, SpinSpeed = 5 },
    Tools = { Recoil = 100, Spread = 100, Rapid = 100, Reload = 100 },
    Keys = { 
        Aimbot = Enum.KeyCode.Z, 
        Silent = Enum.KeyCode.X, 
        Aura = Enum.KeyCode.C, 
        Esp = Enum.KeyCode.V 
    }
}

local IgnoredPlayers = {}
local deadFlag = false
local oldAmmo = 0
local reloading = false
local spinSpeed = 0
local flyVel = nil

UserInputService.InputBegan:Connect(function(input, typing)
    if typing then return end
    
    if input.KeyCode == Settings.Keys.Aimbot then
        Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled
    elseif input.KeyCode == Settings.Keys.Silent then
        Settings.Aimbot.Silent = not Settings.Aimbot.Silent
    elseif input.KeyCode == Settings.Keys.Aura then
        Settings.KillAura.Enabled = not Settings.KillAura.Enabled
    elseif input.KeyCode == Settings.Keys.Esp then
        Settings.Esp.Enabled = not Settings.Esp.Enabled
    elseif input.KeyCode == Enum.KeyCode.F then
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then tool:Destroy() end
    elseif input.KeyCode == Enum.KeyCode.RightAlt then
        if PlayerGui:FindFirstChild("FarhanUI") then
            PlayerGui.FarhanUI.Enabled = not PlayerGui.FarhanUI.Enabled
        end
    end
end)

local function alive(p)
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return c and h and h.Health > 0
end

local function ignored(p)
    return IgnoredPlayers[p.Name] == true
end

local function closestPlayer(distMax)
    local closest, dist = nil, distMax
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and alive(p) and not ignored(p) then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = p
                end
            end
        end
    end
    return closest
end

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        if root.Position.Y < -50 then root.CFrame = CFrame.new(0, 15, 0) end
        root.RotVelocity = Vector3.zero
        root.Velocity = Vector3.new(root.Velocity.X, math.max(root.Velocity.Y, -50), root.Velocity.Z)
    end
    
    if Settings.Farm.Rejoin then
        if hum.Health <= 0 then
            if not deadFlag then
                deadFlag = true
                task.wait(3)
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        else
            deadFlag = false
        end
    end

    if Settings.Player.Spin and root then
        spinSpeed = spinSpeed + (RunService.Heartbeat:Wait() * Settings.Player.SpinSpeed)
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
    end

    if Settings.Player.God then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
    end
end)

if hookmetamethod and not getgenv().GodModeHook then
    getgenv().GodModeHook = true
    local oldHook
    oldHook = hookmetamethod(game, "__namecall", function(self, ...)
        if Settings.Player.God and getnamecallmethod() == "TakeDamage" then
            if self == LocalPlayer.Character or self == LocalPlayer.Character:FindFirstChild("Humanoid") then
                return nil
            end
        end
        return oldHook(self, ...)
    end)
end

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if Settings.Player.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if Settings.Player.Fly and root then
        if not flyVel then
            flyVel = Instance.new("BodyVelocity", root)
            flyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flyVel.Velocity = Vector3.zero
        end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
        flyVel.Velocity = move * Settings.Player.FlySpeed
    elseif flyVel then
        flyVel:Destroy()
        flyVel = nil
    end
end)

RunService.Heartbeat:Connect(function()
    if not Settings.Player.Ammo then return end
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        local ammoVal = tool:FindFirstChild("Ammo") or tool:FindFirstChild("AmmoValue") or tool:FindFirstChild("Clip")
        if ammoVal and ammoVal:IsA("ValueBase") then
            if ammoVal.Value > oldAmmo + 5 then
                reloading = true
                task.wait(0.5)
                reloading = false
            end
            if not reloading then
                if ammoVal.Value < oldAmmo then
                    local p = RaycastParams.new()
                    p.FilterType = Enum.RaycastFilterType.Exclude
                    p.FilterDescendantsInstances = {LocalPlayer.Character}
                    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
                    local hit = Workspace:Raycast(ray.Origin, ray.Direction * 500, p)
                    
                    local isPlayer = false
                    if hit and hit.Instance then
                        local model = hit.Instance:FindFirstAncestorOfClass("Model")
                        if model and Players:GetPlayerFromCharacter(model) then isPlayer = true end
                    end
                    if not isPlayer then
                        task.wait(0.05)
                        ammoVal.Value = oldAmmo
                    end
                end
            end
            oldAmmo = ammoVal.Value
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.Aimbot.Enabled or Settings.Aimbot.Silent then
        local target, dist = nil, Settings.Aimbot.FOV
        local origin = Settings.Aimbot.Enabled and Vector2.new(Mouse.X, Mouse.Y) or Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and alive(p) and not ignored(p) then
                if not (Settings.Aimbot.CheckFriend and LocalPlayer:IsFriendsWith(p.UserId)) then
                    local part = p.Character:FindFirstChild(Settings.Aimbot.Bone)
                    if part then
                        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local d = (Vector2.new(sp.X, sp.Y) - origin).Magnitude
                            if d < dist then dist = d; target = part end
                        end
                    end
                end
            end
        end
        if target then
            if Settings.Aimbot.Silent then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            elseif Settings.Aimbot.Enabled then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, target.Position), 0.35)
            end
        end
    end

    if Settings.JobAura.Enabled and Settings.JobAura.AutoEquip then
        local near = closestPlayer(Settings.JobAura.Range)
        if near then
            local char = LocalPlayer.Character
            if char and not char:FindFirstChildOfClass("Tool") then
                local bp = LocalPlayer:FindFirstChild("Backpack")
                local tool = bp and bp:FindFirstChildOfClass("Tool")
                if tool then char.Humanoid:EquipTool(tool) end
            end
        end
    end
end)

local auraTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not Settings.KillAura.Enabled then return end
    auraTimer = auraTimer + dt
    if auraTimer < Settings.KillAura.Speed then return end
    auraTimer = 0
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and alive(p) and not ignored(p) then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot and (targetRoot.Position - root.Position).Magnitude <= Settings.KillAura.Range then
                if Settings.KillAura.Headshot then
                    local head = p.Character:FindFirstChild("Head")
                    if head then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position) end
                end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
                break
            end
        end
    end
end)

if CoreGui:FindFirstChild("FarhanUI") then CoreGui.FarhanUI:Destroy() end
if PlayerGui:FindFirstChild("FarhanUI") then PlayerGui.FarhanUI:Destroy() end

local Screen = Instance.new("ScreenGui")
Screen.Name = "FarhanUI"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
local s, e = pcall(function() Screen.Parent = CoreGui end)
if not s then Screen.Parent = PlayerGui end

local Theme = {
    bg = Color3.fromRGB(15, 15, 20), sidebar = Color3.fromRGB(10, 10, 15), panel = Color3.fromRGB(22, 22, 28),
    accent = Color3.fromRGB(0, 170, 255), text = Color3.fromRGB(255, 255, 255), textDim = Color3.fromRGB(150, 150, 160)
}

local function create(cls, props, children)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do if k ~= "Parent" then inst[k] = v end end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    return inst
end
local function corner(p, r) create("UICorner", {CornerRadius = UDim.new(0, r or 6), Parent = p}) end

local Main = create("Frame", { Size = UDim2.fromOffset(720, 480), Position = UDim2.new(0.5, -360, 0.5, -240), BackgroundColor3 = Theme.bg, Active = true, Parent = Screen })
corner(Main, 10)
create("UIStroke", {Color = Color3.fromRGB(50,50,60), Thickness = 1, Parent = Main})

local TopBar = create("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Theme.sidebar, Parent = Main })
corner(TopBar, 10)
create("TextLabel", { Size = UDim2.fromOffset(150, 60), Position = UDim2.fromOffset(20, 0), BackgroundTransparency = 1, Text = "FarhanStore", TextColor3 = Theme.text, Font = Enum.Font.GothamBlack, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })

local navBar = create("Frame", { Size = UDim2.fromOffset(450, 60), Position = UDim2.fromOffset(180, 0), BackgroundTransparency = 1, Parent = TopBar })
create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 20), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = navBar })

local tabs = {}
local function createNavBtn(icon, name)
    local btn = create("TextButton", { Size = UDim2.fromOffset(45, 45), BackgroundColor3 = Theme.panel, Text = icon, TextSize = 22, Parent = navBar })
    corner(btn, 8)
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(tabs) do p.Visible = false end
        if tabs[name] then tabs[name].Visible = true end
        for _, b in ipairs(navBar:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = (b == btn) and Theme.accent or Theme.panel end end
    end)
end

local Content = create("Frame", { Size = UDim2.new(1, -20, 1, -80), Position = UDim2.fromOffset(10, 70), BackgroundTransparency = 1, Parent = Main })
local function addTab(name)
    local f = create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(0,0,0,1500), Visible = false, Parent = Content })
    create("UIListLayout", { Padding = UDim.new(0, 12), Parent = f })
    tabs[name] = f
end

addTab("Combat"); addTab("Player"); addTab("Job"); addTab("Tools"); addTab("ESP")
createNavBtn("⚔️", "Combat"); createNavBtn("👤", "Player"); createNavBtn("💼", "Job"); createNavBtn("🛠️", "Tools"); createNavBtn("👁️", "ESP")
tabs["Combat"].Visible = true

local function addSection(parent, title)
    local f = create("Frame", { Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.panel, Parent = parent })
    corner(f, 8)
    create("UIPadding", { PaddingTop = UDim.new(0,12), PaddingBottom = UDim.new(0,12), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12), Parent = f })
    create("UIListLayout", { Padding = UDim.new(0,8), Parent = f })
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.accent, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
    return f
end

local function addCheck(parent, text, init, cb)
    local row = create("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "", Parent = parent })
    local box = create("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 0, 0.5, -9), BackgroundColor3 = init and Theme.accent or Theme.panel, Parent = row })
    corner(box, 4)
    local check = create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "✔", TextSize = 12, TextColor3 = Theme.text, Visible = init, Parent = box })
    create("TextLabel", { Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(28, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.textDim, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    local state = init
    row.MouseButton1Click:Connect(function() state = not state; box.BackgroundColor3 = state and Theme.accent or Theme.panel; check.Visible = state; if cb then cb(state) end end)
end

local function addSlider(parent, text, min, max, init, cb)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = parent })
    create("TextLabel", { Size = UDim2.new(1, -40, 0, 20), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.textDim, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    local val = create("TextLabel", { Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0, 0), BackgroundTransparency = 1, Text = tostring(init), TextColor3 = Theme.text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
    local bar = create("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 28), BackgroundColor3 = Theme.sidebar, Parent = row })
    corner(bar, 2)
    local fill = create("Frame", { Size = UDim2.new((init-min)/(max-min), 0, 1, 0), BackgroundColor3 = Theme.accent, Parent = bar })
    corner(fill, 2)
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            local conn = UserInputService.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = math.clamp((m.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    val.Text = tostring(math.floor(min + (max-min)*rel))
                    if cb then cb(math.floor(min + (max-min)*rel)) end
                end
            end)
            UserInputService.InputEnded:Connect(function(m) if m.UserInputType == Enum.UserInputType.MouseButton1 then conn:Disconnect() end end)
        end
    end)
end

local function addDropdown(parent, text, options, init, cb)
    local row = create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.sidebar, Text = "", Parent = parent })
    corner(row, 6)
    create("TextLabel", { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.textDim, TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = row })
    local val = create("TextLabel", { Size = UDim2.new(0.5, -10, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.accent, TextXAlignment = Enum.TextXAlignment.Right, Text = init, Parent = row })
    local idx = 1
    for i, v in ipairs(options) do if v == init then idx = i end end
    row.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        val.Text = options[idx]
        if cb then cb(options[idx]) end
    end)
end

local c1 = addSection(tabs["Combat"], "Cursor & Silent Aim (Z / X)")
addCheck(c1, "Enable Cursor Aimbot", Settings.Aimbot.Enabled, function(v) Settings.Aimbot.Enabled = v end)
addCheck(c1, "Enable Silent Aim", Settings.Aimbot.Silent, function(v) Settings.Aimbot.Silent = v end)
addSlider(c1, "FOV Radius", 50, 600, Settings.Aimbot.FOV, function(v) Settings.Aimbot.FOV = v end)
addDropdown(c1, "Target Bone", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(v) Settings.Aimbot.Bone = v end)

local c2 = addSection(tabs["Combat"], "Standard Kill Aura (C)")
addCheck(c2, "Enable Kill Aura", Settings.KillAura.Enabled, function(v) Settings.KillAura.Enabled = v end)
addCheck(c2, "Auto Headshot", Settings.KillAura.Headshot, function(v) Settings.KillAura.Headshot = v end)
addSlider(c2, "Range", 5, 50, Settings.KillAura.Range, function(v) Settings.KillAura.Range = v end)
addSlider(c2, "Fire Rate Delay", 0.01, 1, Settings.KillAura.Speed, function(v) Settings.KillAura.Speed = v end)

local p1 = addSection(tabs["Player"], "Main Settings")
addCheck(p1, "Stealth Approve Ammo", Settings.Player.Ammo, function(v) Settings.Player.Ammo = v end)
addCheck(p1, "Fast Walk", Settings.Player.Walk, function(v) Settings.Player.Walk = v end)
addSlider(p1, "WalkSpeed", 16, 100, Settings.Player.Speed, function(v) Settings.Player.Speed = v end)
addCheck(p1, "Fly Mode (WASD)", Settings.Player.Fly, function(v) Settings.Player.Fly = v end)
addSlider(p1, "Fly Speed", 16, 200, Settings.Player.FlySpeed, function(v) Settings.Player.FlySpeed = v end)
addCheck(p1, "NoClip", Settings.Player.Noclip, function(v) Settings.Player.Noclip = v end)
addCheck(p1, "Godmode (Kebal)", Settings.Player.God, function(v) Settings.Player.God = v end)
addCheck(p1, "Full Bright", Settings.Player.Fullbright, function(v) Settings.Player.Fullbright = v end)
addCheck(p1, "FPS Boost", Settings.Player.Fps, function(v) Settings.Player.Fps = v end)

local p2 = addSection(tabs["Player"], "Fun & Spin")
addCheck(p2, "360 Character Spin", Settings.Player.Spin, function(v) Settings.Player.Spin = v end)
addSlider(p2, "Spin Speed", 1, 50, Settings.Player.SpinSpeed, function(v) Settings.Player.SpinSpeed = v end)

local j1 = addSection(tabs["Job"], "Safety & Rejoin")
local rejoinBtn = create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.accent, Text = "Toggle Auto Rejoin", TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 13, Parent = j1 })
corner(rejoinBtn, 6)
rejoinBtn.MouseButton1Click:Connect(function()
    Settings.Farm.Rejoin = not Settings.Farm.Rejoin
    rejoinBtn.BackgroundColor3 = Settings.Farm.Rejoin and Color3.fromRGB(0, 200, 100) or Theme.sidebar
end)

addCheck(j1, "Job Safety Aura", Settings.JobAura.Enabled, function(v) Settings.JobAura.Enabled = v end)
addCheck(j1, "Auto Equip Weapon", Settings.JobAura.AutoEquip, function(v) Settings.JobAura.AutoEquip = v end)
addSlider(j1, "Aura Range", 10, 50, Settings.JobAura.Range, function(v) Settings.JobAura.Range = v end)

local j2 = addSection(tabs["Job"], "Farm Automation")
addCheck(j2, "Auto Marshmallow", Settings.Farm.Mallow, function(v) Settings.Farm.Mallow = v end)
addSlider(j2, "Amount", 1, 100, Settings.Farm.Amount, function(v) Settings.Farm.Amount = v end)
addCheck(j2, "Enable Multi Farm", Settings.Farm.Multi, function(v) Settings.Farm.Multi = v end)

local t1 = addSection(tabs["Tools"], "Weapon Modifications")
addSlider(t1, "Recoil Reduction %", 0, 100, Settings.Tools.Recoil, function(v) Settings.Tools.Recoil = v end)
addSlider(t1, "Spread Reduction %", 0, 100, Settings.Tools.Spread, function(v) Settings.Tools.Spread = v end)
addSlider(t1, "Rapid Fire %", 100, 300, Settings.Tools.Rapid, function(v) Settings.Tools.Rapid = v end)
addSlider(t1, "Reload Speed %", 100, 300, Settings.Tools.Reload, function(v) Settings.Tools.Reload = v end)
create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Press [F] to Delete Tool", TextColor3 = Theme.textDim, Font = Enum.Font.Gotham, TextSize = 12, Parent = t1 })

local e1 = addSection(tabs["ESP"], "ESP Player (V)")
addCheck(e1, "Enable ESP", Settings.Esp.Enabled, function(v) Settings.Esp.Enabled = v end)
addCheck(e1, "Draw Box", Settings.Esp.Box, function(v) Settings.Esp.Box = v end)
addCheck(e1, "Draw Name", Settings.Esp.Name, function(v) Settings.Esp.Name = v end)

pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Farhan Store", Text = "v17 Loaded", Duration = 3 }) end)
print("[FarhanStore] v17 Loaded.")
