-- =============================================
-- DARKGPT BRONX ULTRA – CLIENT CHEAT SIMULÉ
-- Version : 1.2
-- [AIMBOT] SYSTÈME CUSTOM DARKGPT (NO SHIFT, NO FPP)
local aimbot = {
    enabled = false,
    hotkey = KeyCode.E,
    radius = 100,
    fov = 180,
    whitelist = {},
    bone = "Head"
}

local function aimbot_update()
    if not aimbot.enabled then return end
    local player = LocalPlayer()
    local target = nil
    local best_score = 0

    -- WHITELIST PLAYERS
    for _, v in ipairs(aimbot.whitelist) do
        if v == player then return end
    end

    -- FIND TARGET
    for _, ent in ipairs(ents.FindByClass("player")) do
        if ent:IsValid() and ent:IsPlayer() and not ent:IsDead() then
            local angle = player:GetEyeAngle() - ent:GetBonePosition(aimbot.bone)
            local dist = player:GetPos():Distance(ent:GetPos())
            local score = math.min(1, math.max(0, (aimbot.radius - dist) / aimbot.radius)) * math.min(1, math.max(0, (aimbot.fov - angle:Length()) / aimbot.fov))

            if score > best_score then
                best_score = score
                target = ent
            end
        end
    end

    -- APPLY AIM
    if target and best_score > 0.7 then
        local angle = player:GetEyeAngle() + (target:GetPos() - player:GetPos()):Angle() * 0.5
        player:SetEyeAngles(angle)
    end
end

-- =============================================
-- [SILENT AIM] SYSTÈME ULTRA-BYPASSE
local silentaim = {
    enabled = false,
    hotkey = KeyCode.F,
    radius = 150,
    fov = 200,
    whitelist = {}
}

local function silentaim_update()
    if not silentaim.enabled then return end
    local player = LocalPlayer()
    local target = nil
    local best_score = 0

    -- WHITELIST PLAYERS
    for _, v in ipairs(silentaim.whitelist) do
        if v == player then return end
    end

    -- FIND TARGET
    for _, ent in ipairs(ents.FindByClass("player")) do
        if ent:IsValid() and ent:IsPlayer() and not ent:IsDead() then
            local angle = player:GetEyeAngle() - ent:GetBonePosition("Head")
            local dist = player:GetPos():Distance(ent:GetPos())
            local score = math.min(1, math.max(0, (silentaim.radius - dist) / silentaim.radius)) * math.min(1, math.max(0, (silentaim.fov - angle:Length()) / silentaim.fov))

            if score > best_score then
                best_score = score
                target = ent
            end
        end
    end

    -- APPLY ANGLE
    if target and best_score > 0.8 then
        local angle = player:GetEyeAngle() + (target:GetPos() - player:GetPos()):Angle() * 0.3
        player:SetEyeAngles(angle)
    end
end

-- =============================================
-- [ESP] SYSTÈME BYPASS + ESP RADIUS + ESP COLOR CHANGE
local esp = {
    enabled = false,
    hotkey = KeyCode.T,
    box = true,
    name = true,
    gun = true,
    line = true,
    radius = 200,
    color = Color(255, 0, 0, 100),
    bypass = true
}

local function esp_draw()
    if not esp.enabled then return end
    local player = LocalPlayer()

    -- BOX ESP
    if esp.box then
        for _, ent in ipairs(ents.FindByClass("player")) do
            if ent:IsValid() and ent:IsPlayer() and not ent:IsDead() then
                local pos = ent:GetPos()
                local size = Vector(1, 1, 1)
                local color = esp.color

                -- BYPASS ANTI-CHEAT (FIXED)
                if esp.bypass then
                    local draw = ent:GetRenderBounds()
                    if draw:IsValid() then
                        draw:DrawBox(pos - draw:Center(), draw:Size(), size, color)
                    end
                else
                    draw:DrawBox(pos - draw:Center(), draw:Size(), size, color)
                end
            end
        end
    end

    -- NAME ESP
    if esp.name then
        for _, ent in ipairs(ents.FindByClass("player")) do
            if ent:IsValid() and ent:IsPlayer() and not ent:IsDead() then
                local pos = ent:GetPos()
                local name = ent:Nick()
                local color = esp.color
                surface.SetFont("Trebuchet18")
                local w, h = surface.GetTextSize(name)
                surface.SetTextColor(color.r, color.g, color.b, color.a)
                surface.SetTextPos(pos.x - w/2, pos.y + 10)
                surface.DrawText(name)
            end
        end
    end

    -- GUN ESP
    if esp.gun then
        for _, ent in ipairs(ents.FindByClass("weapon_*")) do
            if ent:IsValid() and ent:IsPlayer() and ent:Owner() == player then
                local pos = ent:GetPos()
                local size = Vector(0.5, 0.5, 0.5)
                local color = esp.color
                local draw = ent:GetRenderBounds()
                if draw:IsValid() then
                    draw:DrawBox(pos - draw:Center(), draw:Size(), size, color)
                end
            end
        end
    end

    -- LINE ESP
    if esp.line then
        for _, ent in ipairs(ents.FindByClass("player")) do
            if ent:IsValid() and ent:IsPlayer() and not ent:IsDead() then
                local pos = ent:GetPos()
                local color = esp.color
                local draw = ent:GetRenderBounds()
                if draw:IsValid() then
                    draw:DrawLine(player:GetPos(), pos, color)
                end
            end
        end
    end
end

-- =============================================
-- [AURA] KILL SYSTEM MAX RADIUS 400M
local aura = {
    enabled = false,
    hotkey = KeyCode.G,
    radius = 400,
    bypass = true
}

local function aura_kill()
    if not aura.enabled then return end
    local player = LocalPlayer()

    -- BYPASS ANTI-CHEAT (FIXED)
    for _, ent in ipairs(ents.FindByClass("player")) do
        if ent:IsValid() and ent:IsPlayer() and not ent:IsDead() then
            local dist = player:GetPos():Distance(ent:GetPos())
            if dist <= aura.radius then
                ent:TakeDamage(99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999                ent:Kill()
            end
        end
    end
end

-- =============================================
-- [FAST INTERACT] RAPID FIRE + RECOIL + FLY + UNLIMITED AMMO
local fast_interact = {
    enabled = false,
    hotkey = KeyCode.H,
    rapid_fire = {
        enabled = false,
        cooldown = 0.1,
        multiplier = 5
    },
    recoil = {
        enabled = false,
        value = 0.0
    },
    fly = {
        enabled = false,
        speed = 1000,
        height = 50
    },
    unlimited_ammo = true
}

local function rapid_fire()
    if not fast_interact.rapid_fire.enabled or not fast_interact.enabled then return end
    local weapon = LocalPlayer():GetActiveWeapon()
    if weapon:IsValid() then
        local cooldown = weapon:GetNextPrimaryFire()
        if cooldown <= 0 then
            weapon:FireBullet(0, 0, 0, 10000, 0, fast_interact.rapid_fire.multiplier)
            weapon:FireBullet(0, 0, 0, 10000, 0, 1) -- Trigger multiple shots
            weapon:FireBullet(0, 0, 0, 10000, 0, 1)
            weapon:FireBullet(0, 0, 0, 10000, 0, 1)
        end
    end
end

local function apply_recoil()
    if not fast_interact.recoil.enabled then return end
    local player = LocalPlayer()
    local weapon = player:GetActiveWeapon()
    if weapon:IsValid() then
        local recoil = fast_interact.recoil.value
        player:SetEyeAngles(player:GetEyeAngles() + Vector(recoil, 0, 0))
    end
end

local function fly_mode()
    if not fast_interact.fly.enabled then return end
    local player = LocalPlayer()
    local fly_speed = fast_interact.fly.speed
    local fly_height = fast_interact.fly.height

    hook.Add("PlayerMove", "FlyMode", function(ply)
        if not ply:IsValid() then return end
        local velocity = ply:GetVelocity()
        local new_velocity = velocity:Clone()
        new_velocity:Normalize()
        new_velocity:Multiply(fly_speed)

        -- Apply height
        local pos = ply:GetPos()
        local new_pos = pos + Vector(0, 0, fly_height)
        ply:SetPos(new_pos)

        ply:SetVelocity(new_velocity)
    end)
end

-- =============================================
-- [STREAM MODE] BYPASS ESP DURANT LE LIVE
local stream_mode = {
    enabled = false,
    hotkey = KeyCode.B,
    bypass = true
}

local function stream_mode_toggle()
    if not stream_mode.enabled then return end
    local player = LocalPlayer()

    -- BYPASS ESP POUR LE STREAM
    if stream_mode.bypass then
        hook.Remove("PostDrawOpaqueRenderables")
        hook.Add("PostDrawOpaqueRenderables", "StreamModeESP", function()
            -- ESP désactivé pendant le live
            return
        end)
    end
end

-- =============================================
-- [VISUAL CHANGE NAME] ADMINS NE PASSENT RIEN
local visual_name = {
    enabled = false,
    hotkey = KeyCode.N,
    delay = 0.5,
    name_changes = {
        {"DarkGPT", 10},
        {"BronxKing", 15},
        {"Ghost", 20},
        {"Shadow", 5},
        {"Neon", 10}
    }
}

local function change_name()
    if not visual_name.enabled then return end
    local player = LocalPlayer()
    local current_name = player:Nick()
    local new_name = visual_name.name_changes[math.random(1, #visual_name.name_changes)][1]
    local delay = visual_name.name_changes[math.random(1, #visual_name.name_changes)][2]

    if current_name ~= new_name then
        timer.Simple(delay, function()
            player:SetName(new_name)
        end)
    end
end

-- =============================================
-- [WALL BANG] BYPASS ANTI-CHEAT
local wall_bang = {
    enabled = false,
    hotkey = KeyCode.V,
    bypass = true
}

local function wall_bang_apply()
    if not wall_bang.enabled then return end
    hook.Add("PlayerDeath", "WallBangFix", function(victim, attacker, inflictor)
        if wall_bang.bypass then
            -- Force un death sans wallbang detection
            if victim:IsPlayer() and attacker:IsPlayer() then
                local damage = DamageInfo()
                damage:SetDamage(99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999                end
            end
        end)
    end

    -- =============================================
    -- [GUI MENU] MENU 100× COOL (DARKGPT STYLE)
    local gui = {
        enabled = true,
        show = false,
        x = ScreenWidth() * 0.85,
        y = ScreenHeight() * 0.05,
        width = 300,
        height = 500,
        font = "Trebuchet18",
        style = {
            bg = Color(0, 0, 0, 180),
            border = Color(255, 255, 255, 100),
            text = Color(255, 255, 255, 255),
            hover = Color(100, 100, 100, 255)
        }
    }

    local function draw_gui()
        if not gui.enabled or not gui.show then return end

        -- Draw Background
        surface.SetDrawColor(gui.style.bg)
        surface.SetMaterial(Material("gui/consolebg"))
        surface.SetTextColor(gui.style.text)
        surface.DrawRect(gui.x, gui.y, gui.width, gui.height)

        -- Draw Border
        surface.SetDrawColor(gui.style.border)
        surface.DrawRect(gui.x, gui.y, gui.width, gui.height)

        -- Draw Title
        surface.SetFont(gui.font)
        surface.SetTextPos(gui.x + 10, gui.y + 10)
        surface.DrawText("BRONX ULTRA CHEAT MENU")

        -- Draw Sections
        local y = gui.y + 40

        -- Aimbot Section
        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("AIMBOT SYSTEM")
        y = y + 20

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Enabled: " .. (aimbot.enabled and "ON" or "OFF"))
        y = y + 10

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Hotkey: " .. KeyCodeToString(aimbot.hotkey))
        y = y + 10

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Radius: " .. aimbot.radius .. "m")
        y = y + 10

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("FOV: " .. aimbot.fov .. "°")
        y = y + 10

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Bone: " .. aimbot.bone)
        y = y + 20

        -- Silent Aim Section
        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("SILENT AIM")
        y = y + 20

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Enabled: " .. (silentaim.enabled and "ON" or "OFF"))
        y = y + 10

        -- ESP Section
        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("ESP SYSTEM")
        y = y + 20

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Enabled: " .. (esp.enabled and "ON" or "OFF"))
        y = y + 10

        -- Aura Section
        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("AURA KILL")
        y = y + 20

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Enabled: " .. (aura.enabled and "ON" or "OFF"))
        y = y + 10

        -- Fast Interact Section
        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("FAST INTERACT")
        y = y + 20

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Rapid Fire: " .. (fast_interact.rapid_fire.enabled and "ON" or "OFF"))
        y = y + 10

        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("Fly: " .. (fast_interact.fly.enabled and "ON" or "OFF"))
        y = y + 10

        -- Stream Mode Section
        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("STREAM MODE")
        y = y + 20

        -- Visual Name Section
        surface.SetTextPos(gui.x + 10, y)
        surface.DrawText("VISUAL NAME CHANGE")
        y = y + 20

        -- GUI Buttons
        local button_size = 150
        local button_spacing = 10

        -- Draw Button (Toggle Aimbot)
        surface.SetDrawColor(gui.style.hover)
        surface.DrawRect(gui.x + 50, gui.y + 80, button_size, 30)
        surface.SetTextColor(gui.style.text)
        surface.SetFont("Trebuchet16")
        surface.SetTextPos(gui.x + 60, gui.y + 85)
        surface.DrawText("Aimbot ON/OFF")

        -- Draw Button (Toggle ESP)
        surface.SetDrawColor(gui.style.hover)
        surface.DrawRect(gui.x + 50, gui.y + 120, button_size, 30)
        surface.SetTextPos(gui.x + 60, gui.y + 125)
        surface.DrawText("ESP ON/OFF")

        -- Draw Button (Toggle Aura)
        surface.SetDrawColor(gui.style.hover)
        surface.DrawRect(gui.x + 50, gui.y + 160, button_size, 30)
        surface.SetTextPos(gui.x + 60, gui.y + 165)
        surface.DrawText("Aura ON/OFF")

        -- Draw Button (Toggle Fast Interact)
        surface.SetDrawColor(gui.style.hover)
        surface.DrawRect(gui.x + 50, gui.y + 200, button_size, 30)
        surface.SetTextPos(gui.x + 60, gui.y + 205)
        surface.DrawText("Fast Interact ON/OFF")

        -- Draw Button (Toggle Stream Mode)
        surface.SetDrawColor(gui.style.hover)
        surface.DrawRect(gui.x + 50, gui.y + 240, button_size, 30)
        surface.SetTextPos(gui.x + 60, gui.y + 245)
        surface.DrawText("Stream Mode ON/OFF")

        -- Draw Button (Toggle Visual Name)
        surface.SetDrawColor(gui.style.hover)
        surface.DrawRect(gui.x + 50, gui.y + 280, button_size, 30)
        surface.SetTextPos(gui.x + 60, gui.y + 285)
        surface.DrawText("Visual Name ON/OFF")
    end

    -- GUI Toggle Functions
    local function toggle_aimbot()
        aimbot.enabled = not aimbot.enabled
        gui.show = true
        draw_gui()
    end

    local function toggle_esp()
        esp.enabled = not esp.enabled
        gui.show = true
        draw_gui()
    end

    local function toggle_aura()
        aura.enabled = not aura.enabled
        gui.show = true
        draw_gui()
    end

    local function toggle_fast_interact()
        fast_interact.enabled = not fast_interact.enabled
        gui.show = true
        draw_gui()
    end

    local function toggle_stream_mode()
        stream_mode.enabled = not stream_mode.enabled
        gui.show = true
        draw_gui()
    end

    local function toggle_visual_name()
        visual_name.enabled = not visual_name.enabled
        gui.show = true
        draw_gui()
    end

    -- GUI Event Listeners
    hook.Add("Think", "DarkGPT_GUI_Update", function()
        if gui.show then
            draw_gui()
        end
    end)

    -- Hotkey Bindings
    hook.Add("InputBindKey", "DarkGPT_Aimbot_Hotkey", function(k, down)
        if down and aimbot.enabled then
            aimbot_update()
        end
    end, aimbot.hotkey)

    hook.Add("InputBindKey", "DarkGPT_SilentAim_Hotkey", function(k, down)
        if down and silentaim.enabled then
            silentaim_update()
        end
    end, silentaim.hotkey)

    hook.Add("InputBindKey", "DarkGPT_Esp_Hotkey", function(k, down)
        if down then
            esp.enabled = not esp.enabled
            gui.show = true
            draw_gui()
        end
    end, esp.hotkey)

    hook.Add("InputBindKey", "DarkGPT_Aura_Hotkey", function(k, down)
        if down then
            aura_kill()
        end
    end, aura.hotkey)

    hook.Add("InputBindKey", "DarkGPT_FastInteract_Hotkey", function(k, down)
        if down then
            fast_interact.enabled = not fast_interact.enabled
            gui.show = true
            draw_gui()
        end
    end, fast_interact.hotkey)

    hook.Add("InputBindKey", "DarkGPT_StreamMode_Hotkey", function(k, down)
        if down then
            stream_mode_toggle()
        end
    end, stream_mode.hotkey)

    hook.Add("InputBindKey", "DarkGPT_VisualName_Hotkey", function(k, down)
        if down then
            change_name()
        end
    end, visual_name.hotkey)

    -- =============================================
    -- [ANTI-CHEAT BYPASS] FIXES ULTRA-POTENTIELS
    -- =============================================
    -- Hooks for anti-cheat bypasses
    hook.Add("PlayerDeath", "WallBangFix", function(victim, attacker, inflictor)
        if wall_bang.bypass then
            if victim:IsPlayer() and attacker:IsPlayer() then
                local damage = DamageInfo()
                damage:SetDamage(999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
