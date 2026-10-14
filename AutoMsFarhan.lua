-- BABAPRO v4.1: MARSHMALLOW AUTOMATION (DÜZELTİLMİŞ)
_G.MarshmallowFarmActive = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

-- E TUŞU BASMA MOTORU
local function pressEKey()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- GUI OLUŞTUR
local Gui = Instance.new("ScreenGui")
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 9999
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
Main.Size = UDim2.new(0, 260, 0, 280)
Main.Position = UDim2.new(0.1, 0, 0.25, 0)
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 1
Main.Parent = Gui

-- BAŞLIK
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 32)
Title.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
Title.Text = "   FARHAN STORE | MARSHMALLOW"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2
Title.Parent = Main

-- KAPATMA BUTONU
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 32)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 3
CloseBtn.Parent = Main

-- DURUM ETİKETİ
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0.13, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Durum: BAŞLATILMADI"
StatusLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 13
StatusLabel.ZIndex = 2
StatusLabel.Parent = Main

-- SAYAÇ ALANI
local CounterFrame = Instance.new("Frame")
CounterFrame.Size = UDim2.new(0.9, 0, 0, 135)
CounterFrame.Position = UDim2.new(0.05, 0, 0.23, 0)
CounterFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 25)
CounterFrame.BorderSizePixel = 0
CounterFrame.ZIndex = 2
CounterFrame.Parent = Main

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 3)
UIListLayout.Parent = CounterFrame

local function createCounterLabel(text, color, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -15, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. text
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3
    lbl.LayoutOrder = order
    lbl.Parent = CounterFrame
    return lbl
end

local LargeLabel = createCounterLabel("📦 Large Bag: 0 adet", Color3.fromRGB(255, 100, 100), 1)
local MediumLabel = createCounterLabel("📦 Medium Bag: 0 adet", Color3.fromRGB(255, 200, 100), 2)
local SmallLabel = createCounterLabel("📦 Small Bag: 0 adet", Color3.fromRGB(100, 200, 255), 3)

local Spacer = Instance.new("TextLabel")
Spacer.Size = UDim2.new(1, 0, 0, 4)
Spacer.BackgroundTransparency = 1
Spacer.Text = ""
Spacer.LayoutOrder = 4
Spacer.Parent = CounterFrame

local WaterLabel = createCounterLabel("💧 Eldeki Water: 0 adet", Color3.fromRGB(80, 170, 255), 5)
local SugarLabel = createCounterLabel("🍬 Eldeki Sugar Bag: 0 adet", Color3.fromRGB(255, 140, 255), 6)
local GelatinLabel = createCounterLabel("🧪 Eldeki Gelatin: 0 adet", Color3.fromRGB(150, 255, 150), 7)

-- BAŞLATMA BUTONU
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 38)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.76, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 55, 40)
ToggleBtn.Text = "OTO FARMI BAŞLAT"
ToggleBtn.TextColor3 = Color3.fromRGB(50, 230, 50)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 14
ToggleBtn.BorderSizePixel = 0
ToggleBtn.ZIndex = 99
ToggleBtn.AutoButtonColor = true
ToggleBtn.Parent = Main

local ShortcutInfo = Instance.new("TextLabel")
ShortcutInfo.Size = UDim2.new(1, 0, 0, 15)
ShortcutInfo.Position = UDim2.new(0, 0, 1, -15)
ShortcutInfo.BackgroundTransparency = 1
ShortcutInfo.Text = "[Insert] ile menüyü aç/kapat"
ShortcutInfo.TextColor3 = Color3.fromRGB(120, 120, 120)
ShortcutInfo.TextSize = 10
ShortcutInfo.ZIndex = 2
ShortcutInfo.Parent = Main

-- SÜRÜKLEME MOTORU
local dragging = false
local dragStart = Vector3.new()
local startPos = UDim2.new()

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ENVANTER SAYACI
local function countAllItems()
    local large, medium, small = 0, 0, 0
    local water, sugar, gelatin = 0, 0, 0
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character

    local function scanFolder(folder)
        if not folder then return end
        for _, item in pairs(folder:GetChildren()) do
            if item:IsA("Tool") then
                local nameLower = string.lower(item.Name)
                if string.find(nameLower, "large") then 
                    large = large + 1
                elseif string.find(nameLower, "medium") then 
                    medium = medium + 1
                elseif string.find(nameLower, "small") then 
                    small = small + 1
                elseif string.find(nameLower, "water") then 
                    water = water + 1
                elseif string.find(nameLower, "sugar block bag") then 
                    sugar = sugar + 1
                elseif string.find(nameLower, "gelatin") then 
                    gelatin = gelatin + 1 
                end
            end
        end
    end
    scanFolder(backpack)
    scanFolder(character)

    LargeLabel.Text = "  📦 Large Bag: " .. large .. " adet"
    MediumLabel.Text = "  📦 Medium Bag: " .. medium .. " adet"
    SmallLabel.Text = "  📦 Small Bag: " .. small .. " adet"
    WaterLabel.Text = "  💧 Eldeki Water: " .. water .. " adet"
    SugarLabel.Text = "  🍬 Eldeki Sugar Bag: " .. sugar .. " adet"
    GelatinLabel.Text = "  🧪 Eldeki Gelatin: " .. gelatin .. " adet"
end

RunService.Heartbeat:Connect(countAllItems)

-- EŞYA KULLANIMI
local function useTool(toolName, waitTime)
    if not _G.MarshmallowFarmActive then return end
    
    local character = LocalPlayer.Character
    if not character then 
        StatusLabel.Text = "HATA: Karakter yok!"
        return 
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then 
        StatusLabel.Text = "HATA: Sırt çantası yok!"
        return 
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then 
        StatusLabel.Text = "HATA: Humanoid yok!"
        return 
    end
    
    local tool = backpack:FindFirstChild(toolName) or character:FindFirstChild(toolName)
    if tool then
        StatusLabel.Text = "Eldeki: " .. toolName
        humanoid:EquipTool(tool)
        task.wait(0.5)
        
        if _G.MarshmallowFarmActive then
            pressEKey()
        end
        
        for i = waitTime, 1, -1 do
            if not _G.MarshmallowFarmActive then 
                StatusLabel.Text = "Durduruldu: " .. toolName
                return 
            end
            StatusLabel.Text = string.format("%s | Kalan: %ds", toolName, i)
            task.wait(1)
        end
    else
        StatusLabel.Text = "HATA: '" .. toolName .. "' yok!"
        task.wait(1.5)
    end
end

-- OTOMASYON DÖNGÜSÜ
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.MarshmallowFarmActive then
            useTool("Water", 23)
            if not _G.MarshmallowFarmActive then continue end
            useTool("Sugar Block Bag", 1)
            if not _G.MarshmallowFarmActive then continue end
            useTool("Gelatin", 47)
            if not _G.MarshmallowFarmActive then continue end
            useTool("Empty Bag", 1)
        end
    end
end)

-- TOGGLE FONKSİYONU
local function runToggle()
    _G.MarshmallowFarmActive = not _G.MarshmallowFarmActive
    if _G.MarshmallowFarmActive then
        ToggleBtn.Text = "OTO FARMI DURDUR"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(75, 35, 35)
        ToggleBtn.TextColor3 = Color3.fromRGB(230, 50, 50)
        StatusLabel.Text = "Durum: ÇALIŞIYOR"
    else
        ToggleBtn.Text = "OTO FARMI BAŞLAT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 55, 40)
        ToggleBtn.TextColor3 = Color3.fromRGB(50, 230, 50)
        StatusLabel.Text = "Durum: DURDURULDU"
    end
end

ToggleBtn.MouseButton1Down:Connect(runToggle)

-- KAPATMA BUTONU
CloseBtn.MouseButton1Click:Connect(function()
    _G.MarshmallowFarmActive = false
    Gui:Destroy()
end)

-- INSERT KISAYOLU
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert then 
        Main.Visible = not Main.Visible 
    end
end)

-- SPEED HACK
local function applySpeed(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.WalkSpeed = 50
    end
end

if LocalPlayer.Character then
    applySpeed(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(applySpeed)

print("✅ BABAPRO v4.1 Yüklendi!")
