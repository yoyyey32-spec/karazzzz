
    task.defer(function()
        if not Alive or not obj.Parent then return end

        if obj:IsA("Sky") or obj:IsA("Atmosphere") then
            if obj ~= BlackSky and obj ~= GrayAtmosphere then
                if SkySaved[obj] == nil then
                    SkySaved[obj] = obj.Parent
                end

                obj.Parent = nil
            end

        elseif obj:IsA("PostEffect") then
            set(obj, "Enabled", false)
        end
    end)
end)

local function suppressGunFX()
    local character = Player.Character
    if not character then return end

    for _, obj in ipairs(character:GetDescendants()) do
        if getTool(obj) then
            if isEffect(obj) or isLight(obj) then
                disableFX(obj)

            elseif isFlash(obj) then
                disableFX(obj)
            end
        end
    end
end

local PingClock = 0
local GunClock = 0
local FlashClock = 0

bind(RunService.Heartbeat, function(dt)
    PingClock += dt
    GunClock += dt
    FlashClock += dt

    if PingClock >= 0.1 then
        PingClock = 0

        local ok, value = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)

        if ok and type(value) == "number" then
            Ping.Text = "PING: "
                .. math.floor(value + 0.5)
                .. " ms"
        end
    end

    if GunClock >= 0.5 then
        GunClock = 0

        if State.Recoil or State.Spread then
            applyAllGuns()
        end
    end

    if FlashClock >= 0.1 then
        FlashClock = 0

        if State.FPS then
            suppressGunFX()
        end
    end
end)

bind(RunService.RenderStepped, function(dt)
    if not Main.Visible then return end

    for _, item in ipairs(Stars) do
        local star = item.Object

        if star and star.Parent then
            local pos = star.Position
            local x = pos.X.Scale + item.Speed * dt
            local y = pos.Y.Scale + item.Speed * 0.45 * dt

            if x > 1 then x = -0.03 end
            if y > 1 then y = -0.03 end

            star.Position = UDim2.new(x, 0, y, 0)
        end
    end
end)

local function cleanup()
    if not Alive then return end
    Alive = false

    State.FPS = false
    State.Interact = false
    State.Recoil = false
    State.Spread = false

    restoreInteract()
    restoreValues(RecoilSaved)
    restoreValues(SpreadSaved)

    if State.Bright then
        restoreBright()
        State.Bright = false
    end

    restoreFPS()

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Connections)

    if Gui then
        Gui:Destroy()
    end
end

ENV.SCFPS_Cleanup = cleanup
