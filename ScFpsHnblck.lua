local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local SCFont = Font.fromId(12187372382)

if getgenv and type(getgenv().SCFPS_Cleanup) == "function" then
	pcall(getgenv().SCFPS_Cleanup)
end

local State = {
	fps = false,
	bright = false,
	interact = false,
	noSpread = false,
	visible = true
}

local Saved = {}
local Detached = {}
local SkySaved = {}
local PromptSaved = {}
local BrightSaved = {}
local DecorationSaved = {}
local Connections = {}

local BlackSky
local BlackAtmosphere
local Gui
local Main
local Buttons = {}
local Busy = false
local Active = true
local OriginalDecoration
local StarObjects = {}

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(Connections, connection)
	return connection
end

local function remember(obj, prop)
	if not obj or not obj.Parent then return end

	Saved[obj] = Saved[obj] or {}

	if Saved[obj][prop] == nil then
		local ok, value = pcall(function()
			return obj[prop]
		end)

		if ok then
			Saved[obj][prop] = value
		end
	end
end

local function change(obj, prop, value)
	if not obj or not obj.Parent then return end

	remember(obj, prop)

	pcall(function()
		obj[prop] = value
	end)
end

local function detach(obj)
	if not obj or not obj.Parent then return end

	if Detached[obj] == nil then
		Detached[obj] = obj.Parent
	end

	pcall(function()
		obj.Parent = nil
	end)
end

local function restoreSaved()
	for obj, properties in pairs(Saved) do
		if obj then
			for prop, value in pairs(properties) do
				pcall(function()
					obj[prop] = value
				end)
			end
		end
	end

	for obj, parent in pairs(Detached) do
		if obj and parent then
			pcall(function()
				obj.Parent = parent
			end)
		end
	end

	table.clear(Saved)
	table.clear(Detached)
end

local function hasName(obj, words)
	local name = string.lower(obj.Name)

	for _, word in ipairs(words) do
		if string.find(name, word, 1, true) then
			return true
		end
	end

	return false
end

local function ancestorHasName(obj, words, maxDepth)
	local current = obj
	local depth = 0

	while current and depth < (maxDepth or 8) do
		if hasName(current, words) then
			return true
		end

		current = current.Parent
		depth += 1
	end

	return false
end

local function protectedCharacter(obj)
	local character = Player.Character
	if not character then return false end

	return obj == character or obj:IsDescendantOf(character)
end

local function isFence(obj)
	if not obj:IsA("BasePart") then return false end

	return hasName(obj, {
		"fence", "fencing", "chainlink", "chain_link",
		"ironfence", "metal_fence", "railing", "grate"
	})
end

local function isWeapon(obj)
	if obj:IsA("Tool") then return true end

	if ancestorHasName(obj, {
		"weaponmodel", "weapon_model", "gunmodel",
		"gun_model", "firearms", "weaponfolder"
	}, 5) then
		return true
	end

	return ancestorHasName(obj, {
		"g17", "glock", "drum", "pistol", "rifle",
		"shotgun", "revolver", "firearm", "magazine",
		"handgun", "ak47", "ak-47", "uzi", "weapon",
		"gunmodel", "ammo"
	}, 4)
end

local function isCar(obj)
	return ancestorHasName(obj, {
		"vehicle", "vehicles", "car", "cars",
		"automobile", "truck", "van"
	}, 5)
end

local function isGunStoreWood(obj)
	if not obj:IsA("BasePart") then return false end
	if isWeapon(obj) or isFence(obj) then return false end

	local inStore = ancestorHasName(obj, {
		"gunstore", "gun_store", "gun store",
		"weaponshop", "weapon_shop", "weapon shop",
		"gunshop", "gun_shop", "gun shop"
	}, 10)

	if not inStore then return false end

	local woodMaterial =
		obj.Material == Enum.Material.Wood
		or obj.Material == Enum.Material.WoodPlanks

	local woodName = hasName(obj, {
		"wood", "plank", "timber", "board",
		"shelf", "counter", "woodpart"
	})

	return woodMaterial or woodName
end

local function isLeaf(obj)
	if not obj:IsA("BasePart") then return false end

	return hasName(obj, {
		"leaf", "leaves", "foliage", "bush",
		"grassclump", "smallplant", "plantleaf"
	})
end

local function isBlood(obj)
	return hasName(obj, {
		"blood", "gore", "wound", "bleed",
		"bloodsplatter", "blood_splatter"
	}) or ancestorHasName(obj, {
		"bloodfx", "blood_fx", "blood effect",
		"blood_effect", "gorefx", "gore_fx"
	}, 4)
end

local function isTracer(obj)
	return hasName(obj, {
		"tracer", "bullettrail", "bullet_trail",
		"bullet trail", "projectiletrail",
		"projectile_trail", "muzzleflash",
		"muzzle_flash", "muzzle", "shootingeffect",
		"shooting_effect", "weaponfx", "gunflash",
		"gun_flash", "impacteffect", "bulletimpact",
		"bullet_impact", "shellparticle", "casings",
		"gunsmoke", "laser", "bulletbeam",
		"bullet_beam", "shottrail", "shot_trail"
	}) or ancestorHasName(obj, {
		"tracers", "bullettrails", "bullet_trails",
		"muzzleeffects", "muzzle_effects",
		"weaponfx", "weapon_fx", "gunfx", "gun_fx"
	}, 4)
end

local function isEffect(obj)
	return obj:IsA("ParticleEmitter")
		or obj:IsA("Trail")
		or obj:IsA("Beam")
		or obj:IsA("Smoke")
		or obj:IsA("Fire")
		or obj:IsA("Sparkles")
end

local function hide(obj)
	if obj:IsA("BasePart") then
		change(obj, "Transparency", 1)
		change(obj, "CastShadow", false)
		change(obj, "CanCollide", false)
		change(obj, "CanTouch", false)
		change(obj, "CanQuery", false)
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		change(obj, "Transparency", 1)
	elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
		change(obj, "Enabled", false)
	end
end

local function removeTexture(obj)
	if obj:IsA("SurfaceAppearance") then
		detach(obj)
	elseif obj:IsA("MeshPart") then
		change(obj, "TextureID", "")
	elseif obj:IsA("SpecialMesh") then
		change(obj, "TextureId", "")
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		change(obj, "Transparency", 1)
	end
end

local function optimizeGun(obj)
	if obj:IsA("BasePart") then
		change(obj, "Color", Color3.new(0, 0, 0))
		change(obj, "Material", Enum.Material.SmoothPlastic)
		change(obj, "Reflectance", 0)
		change(obj, "CastShadow", false)

		if obj:IsA("MeshPart") then
			change(obj, "TextureID", "")
		end
	elseif obj:IsA("SpecialMesh") then
		change(obj, "TextureId", "")
	elseif obj:IsA("SurfaceAppearance") then
		detach(obj)
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		change(obj, "Transparency", 1)
	end
end

local function optimize(obj)
	if not State.fps or not obj or not obj.Parent then return end
	if protectedCharacter(obj) then return end

	if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
		return
	end

	if isFence(obj) then
		change(obj, "CastShadow", false)
		change(obj, "Reflectance", 0)
		return
	end

	if isTracer(obj) or isBlood(obj) then
		if isEffect(obj) then
			change(obj, "Enabled", false)
		elseif obj:IsA("BasePart") then
			hide(obj)
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			change(obj, "Transparency", 1)
		elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
			change(obj, "Enabled", false)
		end
		return
	end

	if isWeapon(obj) then
		optimizeGun(obj)
		return
	end

	if isGunStoreWood(obj) or isLeaf(obj) then
		hide(obj)
		return
	end

	if isEffect(obj) then
		change(obj, "Enabled", false)
		return
	end

	if obj:IsA("PostEffect") then
		change(obj, "Enabled", false)
		return
	end

	if obj:IsA("BasePart") then
		change(obj, "CastShadow", false)
		change(obj, "Reflectance", 0)

		if not isCar(obj) then
			change(obj, "Material", Enum.Material.SmoothPlastic)
		end
	end

	removeTexture(obj)
end

local function saveBright()
	if next(BrightSaved) then return end

	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("PostEffect") then
			BrightSaved[obj] = {
				Enabled = obj.Enabled
			}
		end
	end

	BrightSaved._Lighting = {
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ExposureCompensation = Lighting.ExposureCompensation
	}
end

local function applyBright()
	saveBright()

	Lighting.Brightness = 3
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(170, 170, 170)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
	Lighting.ExposureCompensation = 0.15

	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("PostEffect") then
			pcall(function()
				obj.Enabled = false
			end)
		end
	end
end

local function restoreBright()
	local savedLighting = BrightSaved._Lighting

	if savedLighting then
		for prop, value in pairs(savedLighting) do
			pcall(function()
				Lighting[prop] = value
			end)
		end
	end

	for obj, props in pairs(BrightSaved) do
		if obj ~= "_Lighting" and obj then
			for prop, value in pairs(props) do
				pcall(function()
					obj[prop] = value
				end)
			end
		end
	end

	table.clear(BrightSaved)
end

local function applyBlackSky()
	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj ~= BlackSky and obj ~= BlackAtmosphere then
			if obj:IsA("Sky") or obj:IsA("Atmosphere") then
				if SkySaved[obj] == nil then
					SkySaved[obj] = obj.Parent
				end

				pcall(function()
					obj.Parent = nil
				end)
			elseif obj:IsA("PostEffect") then
				change(obj, "Enabled", false)
			end
		end
	end

	if not BlackSky then
		BlackSky = Instance.new("Sky")
		BlackSky.Name = "SCFPS_BlackSky"
	end

	BlackSky.CelestialBodiesShown = false
	BlackSky.StarCount = 0
	BlackSky.SunAngularSize = 0
	BlackSky.MoonAngularSize = 0
	BlackSky.Parent = Lighting

	if not BlackAtmosphere then
		BlackAtmosphere = Instance.new("Atmosphere")
		BlackAtmosphere.Name = "SCFPS_BlackAtmosphere"
	end

	BlackAtmosphere.Color = Color3.new(0, 0, 0)
	BlackAtmosphere.Decay = Color3.new(0, 0, 0)
	BlackAtmosphere.Density = 1
	BlackAtmosphere.Glare = 0
	BlackAtmosphere.Haze = 10
	BlackAtmosphere.Parent = Lighting

	if Terrain then
		for _, obj in ipairs(Terrain:GetChildren()) do
			if obj:IsA("Clouds") then
				change(obj, "Enabled", false)
			end
		end
	end
end

local function restoreSky()
	if BlackSky then
		pcall(function()
			BlackSky:Destroy()
		end)
		BlackSky = nil
	end

	if BlackAtmosphere then
		pcall(function()
			BlackAtmosphere:Destroy()
		end)
		BlackAtmosphere = nil
	end

	for obj, parent in pairs(SkySaved) do
		if obj and parent then
			pcall(function()
				obj.Parent = parent
			end)
		end
	end

	table.clear(SkySaved)
end

local function applyFont(root)
	for _, obj in ipairs(root:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton")
			or obj:IsA("TextBox") then
			pcall(function()
				obj.FontFace = SCFont
			end)
		end
	end
end

local function applyFPS()
	if not State.fps then return end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		optimize(obj)
	end

	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("PostEffect") then
			change(obj, "Enabled", false)
		end
	end

	if Terrain then
		if OriginalDecoration == nil then
			OriginalDecoration = Terrain.Decoration
		end

		pcall(function()
			Terrain.Decoration = false
		end)
	end

	applyBlackSky()
end

local function restoreDecoration()
	if Terrain and OriginalDecoration ~= nil then
		pcall(function()
			Terrain.Decoration = OriginalDecoration
		end)
	end
end

local function fastPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return end

	if PromptSaved[prompt] == nil then
		PromptSaved[prompt] = prompt.HoldDuration
	end

	pcall(function()
		prompt.HoldDuration = 0.2
	end)
end

local function restorePrompts()
	for prompt, duration in pairs(PromptSaved) do
		if prompt then
			pcall(function()
				prompt.HoldDuration = duration
			end)
		end
	end

	table.clear(PromptSaved)
end

local function applyInteract()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			fastPrompt(obj)
		end
	end
end

local function setButtonText(button, label, enabled)
	button.Text = label .. (enabled and ": ON" or ": OFF")
	button.TextColor3 = enabled
		and Color3.fromRGB(120, 210, 255)
		or Color3.fromRGB(225, 225, 225)
end

local function makeButton(parent, label, order)
	local button = Instance.new("TextButton")
	button.Name = label:gsub("%s+", "") .. "Button"
	button.Size = UDim2.new(1, -18, 0, 27)
	button.Position = UDim2.new(0, 9, 0, 40 + (order - 1) * 34)
	button.BackgroundColor3 = Color3.fromRGB(19, 21, 27)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = label .. ": OFF"
	button.TextColor3 = Color3.fromRGB(225, 225, 225)
	button.TextSize = 12
	button.FontFace = SCFont
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 130, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Parent = button

	return button
end

local function makeStars(parent)
	for i = 1, 17 do
		local star = Instance.new("Frame")
		star.Name = "Star" .. i
		star.Size = UDim2.fromOffset(i % 3 == 0 and 3 or 2, i % 3 == 0 and 3 or 2)
		star.Position = UDim2.new((i * 37 % 100) / 100, 0, (i * 19 % 100) / 100, 0)
		star.BackgroundColor3 = Color3.fromRGB(70, 155, 255)
		star.BackgroundTransparency = 0.25 + (i % 4) * 0.12
		star.BorderSizePixel = 0
		star.ZIndex = 1
		star.Parent = parent

		table.insert(StarObjects, {
			Object = star,
			Speed = 0.025 + (i % 5) * 0.012,
			Offset = (i % 7) * 0.08
		})
	end
end

Gui = Instance.new("ScreenGui")
Gui.Name = "SCFPS_FarhanStore"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(215, 235)
Main.Position = UDim2.new(0, 20, 0.5, -117)
Main.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 130, 255)
MainStroke.Thickness = 1.4
MainStroke.Parent = Main

makeStars(Main)

local Top = Instance.new("Frame")
Top.Name = "TopBar"
Top.Size = UDim2.new(1, 0, 0, 32)
Top.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
Top.BorderSizePixel = 0
Top.ZIndex = 2
Top.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = Top

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -35, 1, 0)
Title.Position = UDim2.fromOffset(9, 0)
Title.BackgroundTransparency = 1
Title.Text = "SC FPS | FARHAN STORE"
Title.TextColor3 = Color3.fromRGB(140, 200, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 12
Title.FontFace = SCFont
Title.ZIndex = 3
Title.Parent = Top

local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.Size = UDim2.fromOffset(25, 25)
Close.Position = UDim2.new(1, -28, 0, 3)
Close.BackgroundTransparency = 1
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(220, 225, 235)
Close.TextSize = 13
Close.FontFace = SCFont
Close.ZIndex = 3
Close.Parent = Top

Buttons.FPS = makeButton(Main, "FPS BOOST", 1)
Buttons.Bright = makeButton(Main, "FULL BRIGHT", 2)
Buttons.Interact = makeButton(Main, "FAST INTERACT", 3)
Buttons.NoSpread = makeButton(Main, "NO SPREAD", 4)

local Ping = Instance.new("TextLabel")
Ping.Name = "Ping"
Ping.Size = UDim2.new(1, -16, 0, 17)
Ping.Position = UDim2.new(0, 8, 1, -20)
Ping.BackgroundTransparency = 1
Ping.Text = "PING: -- ms"
Ping.TextColor3 = Color3.fromRGB(120, 185, 255)
Ping.TextSize = 10
Ping.TextXAlignment = Enum.TextXAlignment.Left
Ping.FontFace = SCFont
Ping.ZIndex = 3
Ping.Parent = Main

local function refreshButtons()
	setButtonText(Buttons.FPS, "FPS BOOST", State.fps)
	setButtonText(Buttons.Bright, "FULL BRIGHT", State.bright)
	setButtonText(Buttons.Interact, "FAST INTERACT", State.interact)
	setButtonText(Buttons.NoSpread, "NO SPREAD", State.noSpread)
end

Buttons.FPS.MouseButton1Click:Connect(function()
	if Busy then return end
	Busy = true

	State.fps = not State.fps

	if State.fps then
		applyFPS()
	else
		restoreSaved()
		restoreSky()
		restoreDecoration()
	end

	refreshButtons()
	Busy = false
end)

Buttons.Bright.MouseButton1Click:Connect(function()
	State.bright = not State.bright

	if State.bright then
		applyBright()
	else
		restoreBright()
	end

	refreshButtons()
end)

Buttons.Interact.MouseButton1Click:Connect(function()
	State.interact = not State.interact

	if State.interact then
		applyInteract()
	else
		restorePrompts()
	end

	refreshButtons()
end)

Buttons.NoSpread.MouseButton1Click:Connect(function()
	State.noSpread = not State.noSpread
	refreshButtons()
end)

Close.MouseButton1Click:Connect(function()
	State.visible = false
	Main.Visible = false
end)

local dragging = false
local dragStart
local startPosition

Top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = Main.Position
	end
end)

connect(UIS.InputChanged, function(input)
	if not dragging then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

connect(UIS.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

connect(UIS.InputBegan, function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.RightAlt then
		State.visible = not State.visible
		Main.Visible = State.visible
	elseif input.KeyCode == Enum.KeyCode.X then
		State.visible = false
		Main.Visible = false
	end
end)

connect(Workspace.DescendantAdded, function(obj)
	if State.fps then
		task.defer(function()
			if Active and obj and obj.Parent then
				pcall(optimize, obj)
			end
		end)
	end

	if State.interact and obj:IsA("ProximityPrompt") then
		task.defer(function()
			if Active and obj.Parent then
				fastPrompt(obj)
			end
		end)
	end
end)

connect(Lighting.ChildAdded, function(obj)
	if not State.fps then return end

	task.defer(function()
		if not Active or not obj.Parent then return end

		if obj:IsA("Sky") or obj:IsA("Atmosphere") then
			if obj ~= BlackSky and obj ~= BlackAtmosphere then
				if SkySaved[obj] == nil then
					SkySaved[obj] = obj.Parent
				end

				pcall(function()
					obj.Parent = nil
				end)
			end
		elseif obj:IsA("PostEffect") then
			change(obj, "Enabled", false)
		end
	end)
end)

connect(PlayerGui.DescendantAdded, function(obj)
	task.defer(function()
		if Active and obj.Parent then
			pcall(function()
				if obj:IsA("TextLabel") or obj:IsA("TextButton")
					or obj:IsA("TextBox") then
					obj.FontFace = SCFont
				end
			end)
		end
	end)
end)

connect(RunService.RenderStepped, function(dt)
	for _, item in ipairs(StarObjects) do
		local star = item.Object

		if star and star.Parent and Main.Visible then
			local pos = star.Position
			local x = pos.X.Scale + item.Speed * dt
			local y = pos.Y.Scale + item.Speed * 0.45 * dt

			if x > 1 then x = -0.03 end
			if y > 1 then y = -0.03 end

			star.Position = UDim2.new(x, 0, y, 0)
		end
	end
end)

local pingClock = 0

connect(RunService.Heartbeat, function(dt)
	pingClock += dt
	if pingClock < 0.1 then return end
	pingClock = 0

	local ok, ping = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)

	if ok and type(ping) == "number" then
		Ping.Text = "PING: " .. math.floor(ping + 0.5) .. " ms"
	end
end)

local function cleanup()
	if not Active then return end
	Active = false

	State.fps = false
	State.interact = false

	restorePrompts()
	restoreSaved()
	restoreSky()
	restoreDecoration()

	if State.bright then
		restoreBright()
		State.bright = false
	end

	for _, connection in ipairs(Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(Connections)

	if Gui then
		pcall(function()
			Gui:Destroy()
		end)
	end
end

if getgenv then
	getgenv().SCFPS_Cleanup = cleanup
end

refreshButtons()
print("SC FPS | FARHAN STORE loaded")
