local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Screen = Instance.new("ScreenGui")
Screen.Name = "FarhanUI"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.Parent = PlayerGui
Screen.Enabled = true

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(720, 480)
Main.Position = UDim2.new(0.5, -360, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Screen

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Title.Text = "FarhanStore"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)
Instance.new("UIPadding", Title).PaddingLeft = UDim.new(0, 20)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Farhan Store",
        Text = "GUI Berhasil Muncul!",
        Duration = 5
    })
end)
