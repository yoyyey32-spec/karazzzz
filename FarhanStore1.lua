local code = [==[
--[[
  CAPEK KONTOL BIKIN BEGINIAN BIKIN MUMET ASU ]
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

local Config = {
    Aimbot = { CursorEnabled = false, SilentEnabled = false, HitChance = 100, HitPart = "Head", FOVRadius = 60, FriendCheck = true },
    KillAura = { Enabled = false, Range = 18 },
    ForceAuto = { Enabled = false, CPS = 15 },
    ESP = { Enabled = false, Box = true, Name = true },
    Farm = { Amount = 50, AutoMarshmallow = false, MultiFarm = false },
    Player = { FastWalk = false, WalkSpeed = 30, NoClip = false, FPSBoost = false, FullBright = false },
    Tools = { NoRecoil = false, NoSpread = false, RecoilPct = 100, SpreadPct = 100 },
    AntiVoid = true, AntiFling = true, AntiDetect = true
}

local IgnoredPlayers = {}

-- EXTREME BYPASS
if hookmetamethod and not getgenv().FarhanHooked then
    getgenv().FarhanHooked = true
    local oldIndex = hookmetamethod(game, "__index", function(self, key)
        local caller = getcallingscript()
        if not checkcaller() and caller and string.find(string.lower(caller.Name), "anti") then
            if key == "WalkSpeed" or key == "JumpPower" or key == "Gravity" then return 16 end
        end
        if key == "WalkSpeed" and Config.Player.FastWalk then return Config.Player.WalkSpeed end
        return oldIndex(self, key)
    end)
end

if hookmetamethod and not getgenv().FarhanNamecallHooked then
    getgenv().FarhanNamecallHooked = true
    local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() then
            if method == "Kick" or method == "Destroy" or method == "Remove" then return nil end
            if method == "FireServer" and (self.Name == "Teleport" or self.Name == "Kick") then return nil end
        end
        return oldNamecall(self, ...)
    end)
end

if hookfunction and not getgenv().FarhanFireHooked then
    getgenv().FarhanFireHooked = true
    local oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
        if self.Name == "AntiCheat" or self.Name == "Detection" then return end
        return oldFire(self, ...)
    end)
end

RunService.Heartbeat:Connect(function()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if Config.AntiVoid and hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(0, 15, 0) end
    if Config.AntiFling then
        hrp.RotVelocity = Vector3.zero
        hrp.Velocity = Vector3.new(hrp.Velocity.X, math.max(hrp.Velocity.Y, -50), hrp.Velocity.Z)
    end
end)

local function isAlive(plr)
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return c and h and h.Health > 0
end
local function isIgnored(plr) return IgnoredPlayers[plr.Name] == true end

RunService.RenderStepped:Connect(function()
    if not Config.Aimbot.CursorEnabled and not Config.Aimbot.SilentEnabled then return end
    if not LocalPlayer.Character then return end
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
    if closest and math.random(1, 100) <= Config.Aimbot.HitChance then
        if Config.Aimbot.SilentEnabled then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, closest.Position)
        elseif Config.Aimbot.CursorEnabled then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, closest.Position), 0.35)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not Config.KillAura.Enabled then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) and not isIgnored(plr) then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and (root.Position - hrp.Position).Magnitude <= Config.KillAura.Range then
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
                break
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if Config.ForceAuto.Enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        task.spawn(function()
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and Config.ForceAuto.Enabled do
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                task.wait(1 / Config.ForceAuto.CPS)
            end
        end)
    end
end)

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

if CoreGui:FindFirstChild("FarhanStoreUI") then CoreGui.FarhanStoreUI:Destroy() end
local Screen = create("ScreenGui", { Name = "FarhanStoreUI", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = CoreGui })

local Main = create("Frame", { Size = UDim2.fromOffset(700, 460), Position = UDim2.new(0.5, -350, 0.5, -230), BackgroundColor3 = Theme.bg, Active = true, Parent = Screen })
corner(Main, 10)
create("UIStroke", {Color = Color3.fromRGB(50,50,60), Thickness = 1, Parent = Main})

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightAlt then
        Main.Visible = not Main.Visible
        if popup then popup.Visible = false end
    end
end)

local hintTxt = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 1, -25), BackgroundTransparency = 1,
    Text = "Press [Right Alt] to Hide Menu", TextColor3 = Theme.textDim, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = Main
})

local dStart, sPos, isDragging = nil, nil, false
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true; dStart = i.Position; sPos = Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if isDragging and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dStart; Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end end)

local TopBar = create("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Theme.sidebar, Parent = Main })
corner(TopBar, 10)
create("TextLabel", { Size = UDim2.fromOffset(120, 60), Position = UDim2.fromOffset(15, 0), BackgroundTransparency = 1, Text = "FarhanStore", TextColor3 = Theme.text, Font = Enum.Font.GothamBlack, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })

local navBar = create("Frame", { Size = UDim2.fromOffset(400, 60), Position = UDim2.fromOffset(150, 0), BackgroundTransparency = 1, Parent = TopBar })
create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 20), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = navBar })

local tabs = {}
local function createNavBtn(icon, name)
    local btn = create("TextButton", { Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Theme.panel, Text = icon, TextSize = 20, Parent = navBar })
    corner(btn, 8)
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(tabs) do p.Visible = false end
        if tabs[name] then tabs[name].Visible = true end
        for _, b in ipairs(navBar:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = (b == btn) and Theme.accent or Theme.panel end end
    end)
    return btn
end

local Content = create("Frame", { Size = UDim2.new(1, -20, 1, -95), Position = UDim2.fromOffset(10, 70), BackgroundTransparency = 1, Parent = Main })
local function addTab(name)
    local f = create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(0,0,0,1000), Visible = false, Parent = Content })
    create("UIListLayout", { Padding = UDim.new(0, 10), Parent = f })
    tabs[name] = f
    return f
end

local tabCombat = addTab("Combat"); local tabJob = addTab("Job"); local tabESP = addTab("ESP"); local tabTools = addTab("Tools"); local tabPlayer = addTab("Player")
createNavBtn("⚔️", "Combat"); createNavBtn("💼", "Job"); createNavBtn("👁️", "ESP"); createNavBtn("🛠️", "Tools"); createNavBtn("👤", "Player")
tabs["Combat"].Visible = true

local function addSection(parent, title)
    local f = create("Frame", { Size = UDim2.new(0.5, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.panel, Parent = parent })
    corner(f, 8)
    create("UIPadding", { PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10), Parent = f })
    create("UIListLayout", { Padding = UDim.new(0,6), Parent = f })
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.accent, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
    return f
end

local function addCheck(parent, text, init, cb)
    local row = create("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "", Parent = parent })
    local box = create("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = init and Theme.accent or Theme.panel, Parent = row })
    corner(box, 4)
    local check = create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "✔", TextSize = 10, TextColor3 = Theme.text, Visible = init, Parent = box })
    create("TextLabel", { Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(26, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.textDim, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    local state = init
    row.MouseButton1Click:Connect(function() state = not state; box.BackgroundColor3 = state and Theme.accent or Theme.panel; check.Visible = state; if cb then cb(state) end end)
end

local function addSlider(parent, text, min, max, init, cb)
    local row = create("Frame", { Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, Parent = parent })
    create("TextLabel", { Size = UDim2.new(1, -40, 0, 18), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.textDim, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
    local val = create("TextLabel", { Size = UDim2.fromOffset(40, 18), Position = UDim2.new(1, -40, 0, 0), BackgroundTransparency = 1, Text = tostring(init), TextColor3 = Theme.text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
    local bar = create("Frame", { Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 0, 24), BackgroundColor3 = Theme.sidebar, Parent = row })
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

local c1 = addSection(tabCombat, "Cursor Aimbot")
addCheck(c1, "Enable Cursor Aim", Config.Aimbot.CursorEnabled, function(v) Config.Aimbot.CursorEnabled = v end)
local c2 = addSection(tabCombat, "Silent Aim")
addCheck(c2, "Enable Silent Aim", Config.Aimbot.SilentEnabled, function(v) Config.Aimbot.SilentEnabled = v end)
local c3 = addSection(tabCombat, "Kill Aura")
addCheck(c3, "Enable Kill Aura", Config.KillAura.Enabled, function(v) Config.KillAura.Enabled = v end)
addSlider(c3, "Aura Range", 5, 50, Config.KillAura.Range, function(v) Config.KillAura.Range = v end)
local c4 = addSection(tabCombat, "Force Auto")
addCheck(c4, "Enable Force Auto", Config.ForceAuto.Enabled, function(v) Config.ForceAuto.Enabled = v end)
addSlider(c4, "CPS (Click/Sec)", 1, 30, Config.ForceAuto.CPS, function(v) Config.ForceAuto.CPS = v end)

local j1 = addSection(tabJob, "Single Job")
addCheck(j1, "Auto Marshmallow", Config.Farm.AutoMarshmallow, function(v) Config.Farm.AutoMarshmallow = v end)
addSlider(j1, "Amount", 1, 100, Config.Farm.Amount, function(v) Config.Farm.Amount = v end)
local j2 = addSection(tabJob, "Multi Farm")
addCheck(j2, "Enable Multi Farm", Config.Farm.MultiFarm, function(v) Config.Farm.MultiFarm = v end)

local e1 = addSection(tabESP, "ESP Player")
addCheck(e1, "Enable ESP (Box + Name)", Config.ESP.Enabled, function(v) Config.ESP.Enabled = v end)

local t1 = addSection(tabTools, "Weapon Mods")
addCheck(t1, "No Recoil", Config.Tools.NoRecoil, function(v) Config.Tools.NoRecoil = v end)
addSlider(t1, "Recoil %", 0, 100, Config.Tools.RecoilPct, function(v) Config.Tools.RecoilPct = v end)
addCheck(t1, "No Spread", Config.Tools.NoSpread, function(v) Config.Tools.NoSpread = v end)
addSlider(t1, "Spread %", 0, 100, Config.Tools.SpreadPct, function(v) Config.Tools.SpreadPct = v end)

local t2 = addSection(tabTools, "Target Settings")
local toggleBtn = create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.accent, Text = "Open Player Toggle Menu", TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 12, Parent = t2 })
corner(toggleBtn, 6)

local p1 = addSection(tabPlayer, "Performance")
addCheck(p1, "Aggressive FPS Boost", Config.Player.FPSBoost, function(v) Config.Player.FPSBoost = v end)
addCheck(p1, "Full Bright", Config.Player.FullBright, function(v) Config.Player.FullBright = v end)
local p2 = addSection(tabPlayer, "Movement")
addCheck(p2, "Fast Walk", Config.Player.FastWalk, function(v) Config.Player.FastWalk = v end)
addSlider(p2, "Speed", 16, 100, Config.Player.WalkSpeed, function(v) Config.Player.WalkSpeed = v end)

local popup = create("Frame", { Size = UDim2.fromOffset(300, 350), Position = UDim2.new(0.5, -150, 0.5, -175), BackgroundColor3 = Theme.panel, Visible = false, Parent = Screen })
corner(popup, 10)
create("UIStroke", {Color = Theme.accent, Thickness = 1, Parent = popup})
create("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "Player Toggle (Ignore)", TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 16, Parent = popup })
local closePopup = create("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -40, 0, 5), BackgroundTransparency = 1, Text = "✕", TextColor3 = Theme.textDim, Font = Enum.Font.GothamBold, TextSize = 14, Parent = popup })
closePopup.MouseButton1Click:Connect(function() popup.Visible = false end)

local popupScroll = create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -50), Position = UDim2.fromOffset(10, 40), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.accent, CanvasSize = UDim2.new(0,0,0,0), Parent = popup })
create("UIListLayout", { Padding = UDim.new(0, 5), Parent = popupScroll })

local function refreshPopup()
    for _, c in ipairs(popupScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local isOff = IgnoredPlayers[plr.Name] == true
            local btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = isOff and Color3.fromRGB(200, 50, 50) or Theme.sidebar, Text = (isOff and "[ OFF ] " or "[ ON ] ") .. plr.Name, TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = popupScroll })
            corner(btn, 6)
            create("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = btn })
            btn.MouseButton1Click:Connect(function()
                IgnoredPlayers[plr.Name] = not isOff
                refreshPopup()
            end)
        end
    end
    popupScroll.CanvasSize = UDim2.new(0, 0, 0, (#Players:GetPlayers() * 35))
end

toggleBtn.MouseButton1Click:Connect(function()
    popup.Visible = not popup.Visible
    if popup.Visible then refreshPopup() end
end)

pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Farhan Store", Text = "v10 Extreme Loaded. Right Alt to Hide.", Duration = 3 }) end)
print("[FarhanStore] v10 Extreme Loaded.")
]==]

if writefile then
    writefile("FarhanStore.lua", code)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Farhan Store",
        Text = "File berhasil disimpan di folder Workspace executor lu!",
        Duration = 5
    })
else
    print("Executor lu tidak support writefile, min. Copy manual aja.")
end
