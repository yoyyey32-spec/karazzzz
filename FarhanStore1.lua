--[[
    LAPET STYLE
]]

--==================== SERVICES ====================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService   = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Mouse       = LocalPlayer:GetMouse()

--==================== CONFIG ====================
local Config = {
    Aimbot = { CursorEnabled = false, SilentEnabled = false, HitChance = 100, HitPart = "Head", FOVRadius = 200, FriendCheck = true },
    KillAura = { Enabled = false, Range = 18, FireRate = 0.1, AutoHead = true },
    JobAura = { Enabled = false, Range = 25, AutoEquip = true }, 
    ESP = { Enabled = false, Box = true, Name = true },
    Farm = { Amount = 50, AutoMarshmallow = false, MultiFarm = false, AutoRejoin = false },
    Player = { FastWalk = false, WalkSpeed = 30, NoClip = false, FPSBoost = false, FullBright = false, ApproveAmmo = false, SpinEnabled = false, SpinSpeed = 5 },
    Tools = { RecoilPct = 100, SpreadPct = 100, RapidFirePct = 100 },
    Hotkeys = {
        Aimbot = Enum.KeyCode.Z,
        Silent = Enum.KeyCode.X,
        Aura = Enum.KeyCode.C,
        ESP = Enum.KeyCode.V
    },
    Bypass = { AntiVoid = true, AntiFling = true, AntiDetect = true }
}

local IgnoredPlayers = {}
local isDead = false
local lastAmmo = 0
local isReloading = false
local spinAcc = 0

--==================== HOTKEY SYSTEM ====================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Config.Hotkeys.Aimbot then
        Config.Aimbot.CursorEnabled = not Config.Aimbot.CursorEnabled
        print("Aimbot: " .. tostring(Config.Aimbot.CursorEnabled))
    elseif input.KeyCode == Config.Hotkeys.Silent then
        Config.Aimbot.SilentEnabled = not Config.Aimbot.SilentEnabled
        print("Silent Aim: " .. tostring(Config.Aimbot.SilentEnabled))
    elseif input.KeyCode == Config.Hotkeys.Aura then
        Config.KillAura.Enabled = not Config.KillAura.Enabled
        print("Kill Aura: " .. tostring(Config.KillAura.Enabled))
    elseif input.KeyCode == Config.Hotkeys.ESP then
        Config.ESP.Enabled = not Config.ESP.Enabled
        print("ESP: " .. tostring(Config.ESP.Enabled))
    end
end)

--==================== UTIL ====================
local function isAlive(plr)
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return c and h and h.Health > 0
end

local function isIgnored(plr) return IgnoredPlayers[plr.Name] == true end

local function getClosestPlayerToMe(range)
    local closest, dist = nil, range
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) and not isIgnored(plr) then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < dist then dist = d; closest = plr end
            end
        end
    end
    return closest
end

--==================== BYPASS & BACKGROUND ====================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if Config.Bypass.AntiVoid and hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(0, 15, 0) end
        if Config.Bypass.AntiFling then
            hrp.RotVelocity = Vector3.zero
            hrp.Velocity = Vector3.new(hrp.Velocity.X, math.max(hrp.Velocity.Y, -50), hrp.Velocity.Z)
        end
    end
    
    -- Auto Rejoin
    if Config.Farm.AutoRejoin then
        if hum.Health <= 0 then
            if not isDead then
                isDead = true
                task.wait(3)
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
            end
        else
            isDead = false
        end
    end

    -- 360 Spin Character
    if Config.Player.SpinEnabled and hrp then
        spinAcc = spinAcc + (RunService.Heartbeat:Wait() * Config.Player.SpinSpeed)
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinAcc), 0)
    end
end)

--==================== STEALTH AMMO (RAYCAST) ====================
RunService.Heartbeat:Connect(function()
    if not Config.Player.ApproveAmmo then return end
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    
    if tool then
        local ammoVal = tool:FindFirstChild("Ammo") or tool:FindFirstChild("AmmoValue") or tool:FindFirstChild("Clip")
        if ammoVal and ammoVal:IsA("ValueBase") then
            if ammoVal.Value > lastAmmo + 5 then
                isReloading = true
                task.wait(0.5)
                isReloading = false
            end
            
            if not isReloading then
                if ammoVal.Value < lastAmmo then
                    -- Cek apakah crosshair beneran ngarah ke player
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {char}
                    local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
                    local hit = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
                    
                    local hitPlayer = false
                    if hit and hit.Instance then
                        local model = hit.Instance:FindFirstAncestorOfClass("Model")
                        if model and Players:GetPlayerFromCharacter(model) then
                            hitPlayer = true
                        end
                    end

                    -- Kalau nggak kena player, balikin ammo
                    if not hitPlayer then
                        task.wait(0.05)
                        ammoVal.Value = lastAmmo 
                    end
                end
            end
            lastAmmo = ammoVal.Value
        end
    end
end)

--==================== COMBAT & JOB SAFETY ====================
RunService.RenderStepped:Connect(function()
    -- Aimbot
    if Config.Aimbot.CursorEnabled or Config.Aimbot.SilentEnabled then
        local closest, dist = nil, Config.Aimbot.FOVRadius
        local origin = Config.Aimbot.CursorEnabled and Vector2.new(Mouse.X, Mouse.Y) or Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and isAlive(plr) and not isIgnored(plr) then
                if not (Config.Aimbot.FriendCheck and LocalPlayer:IsFriendsWith(plr.UserId)) then
                    local part = plr.Character:FindFirstChild(Config.Aimbot.HitPart)
                    if part then
                        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local d = (Vector2.new(sp.X, sp.Y) - origin).Magnitude
                            if d < dist then dist = d; closest = part end
                        end
                    end
                end
            end
        end
        if closest then
            if Config.Aimbot.SilentEnabled then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, closest.Position)
            elseif Config.Aimbot.CursorEnabled then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, closest.Position), 0.35)
            end
        end
    end

    -- Job Safety Aura (Auto Equip Weapon)
    if Config.JobAura.Enabled and Config.JobAura.AutoEquip then
        local nearbyPlayer = getClosestPlayerToMe(Config.JobAura.Range)
        if nearbyPlayer then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if not tool then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    local newTool = backpack and backpack:FindFirstChildOfClass("Tool")
                    if newTool then
                        char.Humanoid:EquipTool(newTool)
                    end
                end
            end
        end
    end
end)

-- Kill Aura
local auraAcc = 0
RunService.Heartbeat:Connect(function(dt)
    if not Config.KillAura.Enabled then return end
    auraAcc = auraAcc + dt
    if auraAcc < Config.KillAura.FireRate then return end
    auraAcc = 0
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) and not isIgnored(plr) then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - hrp.Position).Magnitude <= Config.KillAura.Range then
                if Config.KillAura.AutoHead then
                    local head = plr.Character:FindFirstChild("Head")
                    if head then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position) end
                end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
                break
            end
        end
    end
end)

--==================== UI SYSTEM ====================
if CoreGui:FindFirstChild("FarhanStoreUI") then CoreGui.FarhanStoreUI:Destroy() end
if PlayerGui:FindFirstChild("FarhanStoreUI") then PlayerGui.FarhanStoreUI:Destroy() end

local Screen = Instance.new("ScreenGui")
Screen.Name = "FarhanStoreUI"
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

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then Main.Visible = not Main.Visible end
end)

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

-- COMBAT TAB
local c1 = addSection(tabs["Combat"], "Cursor & Silent Aim (Hotkeys: Z / X)")
addCheck(c1, "Enable Cursor Aimbot", Config.Aimbot.CursorEnabled, function(v) Config.Aimbot.CursorEnabled = v end)
addCheck(c1, "Enable Silent Aim", Config.Aimbot.SilentEnabled, function(v) Config.Aimbot.SilentEnabled = v end)
addSlider(c1, "FOV Radius", 50, 600, Config.Aimbot.FOVRadius, function(v) Config.Aimbot.FOVRadius = v end)
addDropdown(c1, "Target Bone", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(v) Config.Aimbot.HitPart = v end)

local c2 = addSection(tabs["Combat"], "Standard Kill Aura (Hotkey: C)")
addCheck(c2, "Enable Kill Aura", Config.KillAura.Enabled, function(v) Config.KillAura.Enabled = v end)
addCheck(c2, "Auto Headshot", Config.KillAura.AutoHead, function(v) Config.KillAura.AutoHead = v end)
addSlider(c2, "Range", 5, 50, Config.KillAura.Range, function(v) Config.KillAura.Range = v end)
addSlider(c2, "Fire Rate Delay", 0.01, 1, Config.KillAura.FireRate, function(v) Config.KillAura.FireRate = v end)

-- PLAYER TAB
local p1 = addSection(tabs["Player"], "Main Settings")
addCheck(p1, "Stealth Approve Ammo", Config.Player.ApproveAmmo, function(v) Config.Player.ApproveAmmo = v end)
addCheck(p1, "Fast Walk", Config.Player.FastWalk, function(v) Config.Player.FastWalk = v end)
addSlider(p1, "WalkSpeed", 16, 100, Config.Player.WalkSpeed, function(v) Config.Player.WalkSpeed = v end)
addCheck(p1, "Full Bright", Config.Player.FullBright, function(v) Config.Player.FullBright = v end)
addCheck(p1, "FPS Boost", Config.Player.FPSBoost, function(v) Config.Player.FPSBoost = v end)

local p2 = addSection(tabs["Player"], "Fun & Spin")
addCheck(p2, "360 Character Spin", Config.Player.SpinEnabled, function(v) Config.Player.SpinEnabled = v end)
addSlider(p2, "Spin Speed", 1, 50, Config.Player.SpinSpeed, function(v) Config.Player.SpinSpeed = v end)

-- JOB TAB
local j1 = addSection(tabs["Job"], "Safety & Rejoin")
local rejoinBtn = create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.accent, Text = "Toggle Auto Rejoin", TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 13, Parent = j1 })
corner(rejoinBtn, 6)
rejoinBtn.MouseButton1Click:Connect(function()
    Config.Farm.AutoRejoin = not Config.Farm.AutoRejoin
    rejoinBtn.BackgroundColor3 = Config.Farm.AutoRejoin and Color3.fromRGB(0, 200, 100) or Theme.sidebar
end)

addCheck(j1, "Job Safety Aura", Config.JobAura.Enabled, function(v) Config.JobAura.Enabled = v end)
addCheck(j1, "Auto Equip Weapon", Config.JobAura.AutoEquip, function(v) Config.JobAura.AutoEquip = v end)
addSlider(j1, "Aura Range", 10, 50, Config.JobAura.Range, function(v) Config.JobAura.Range = v end)

local j2 = addSection(tabs["Job"], "Farm Automation")
addCheck(j2, "Auto Marshmallow", Config.Farm.AutoMarshmallow, function(v) Config.Farm.AutoMarshmallow = v end)
addSlider(j2, "Amount", 1, 100, Config.Farm.Amount, function(v) Config.Farm.Amount = v end)
addCheck(j2, "Enable Multi Farm", Config.Farm.MultiFarm, function(v) Config.Farm.MultiFarm = v end)

-- TOOLS TAB
local t1 = addSection(tabs["Tools"], "Weapon Modifications")
addSlider(t1, "Recoil Reduction %", 0, 100, Config.Tools.RecoilPct, function(v) Config.Tools.RecoilPct = v end)
addSlider(t1, "Spread Reduction %", 0, 100, Config.Tools.SpreadPct, function(v) Config.Tools.SpreadPct = v end)
addSlider(t1, "Rapid Fire %", 100, 300, Config.Tools.RapidFirePct, function(v) Config.Tools.RapidFirePct = v end)

-- ESP TAB
local e1 = addSection(tabs["ESP"], "ESP Player (Hotkey: V)")
addCheck(e1, "Enable ESP", Config.ESP.Enabled, function(v) Config.ESP.Enabled = v end)
addCheck(e1, "Draw Box", Config.ESP.Box, function(v) Config.ESP.Box = v end)
addCheck(e1, "Draw Name", Config.ESP.Name, function(v) Config.ESP.Name = v end)

pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Farhan Store", Text = "Jan Gasak Kali Kau Kampang", Duration = 3 }) end)
print("[FarhanStore] v14 Loaded.")
