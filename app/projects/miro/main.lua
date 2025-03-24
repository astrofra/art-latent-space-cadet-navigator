-- Latent Space Cadet, Miro board revisited

hg = require("harfang")
require("utils")

function QuantizeZoomLevel(value)
    if value < 0.005 then
        return 0.0
    elseif value < 0.995 then
        return 0.70
    else
        return 1.0
    end
end

function SmoothZoomLevel(value)
    local quantized_value = QuantizeZoomLevel(value)
    local lerp = 0.9995
    return (quantized_value * lerp) + (value * (1.0 - lerp))
end

function SceneMiroSetup(res, pipeline_info, bg_color, height_ratio)
    height_ratio = height_ratio or 1.0

    -- Load scene
    local _scene = hg.Scene()
    hg.LoadSceneFromAssets("projects/latent_space_cadet/miro/main.scn", _scene, res, pipeline_info)
    _scene.canvas.color = bg_color
    _scene.environment.fog_color = bg_color

    local _camera = _scene:GetNode("Camera")
    local default_fov = _camera:GetCamera():GetFov()
    _camera:GetCamera():SetFov(default_fov * height_ratio)
    local _pos = _camera:GetTransform():GetPos()
    _pos.x = -6.6240782737732
    _pos.y = 0.97838085889816

    local ctx = {
        scene = _scene,
        camera = _camera,
        original_pos = _pos,
        pos = _pos,
        zoom_level = 0.0
    }

    return ctx
end

function SceneMiroUpdate(ctx, keyboard, gamepad, prev_gamepad, dt, current_clock)
    local dts = hg.time_to_sec_f(dt)

    local cam_dir = hg.Vec3(0,0,0)
    local cam_dir_keyboard = hg.Vec3(0,0,0)
    local far_speed = 300.0
    local close_speed = 100.0
    local target_zoom_level = 0.0
    local target_zoom_level_keyboard = 0.0

    if keyboard:Down(hg.K_Z) then
        cam_dir_keyboard.y = 1.0 -- Up
    elseif keyboard:Down(hg.K_S) then
        cam_dir_keyboard.y = -1.0 -- Down
    end
    if keyboard:Down(hg.K_Q) then
        cam_dir_keyboard.x = -1.0 -- Left
    elseif keyboard:Down(hg.K_D) then
        cam_dir_keyboard.x = 1.0 -- Right
    end
    if keyboard:Down(hg.K_Space) then
        target_zoom_level_keyboard = 1.0
    end

    if gamepad and prev_gamepad then
        -- if prev_gamepad:Button(hg.GB_RightBumper) == false and gamepad:Button(hg.GB_RightBumper) == true then
        --     scene_nav = 1
        -- end
        cam_dir.x = gamepad:Axes(hg.GA_RightX)
        cam_dir.y = -gamepad:Axes(hg.GA_RightY)
        target_zoom_level = map(gamepad:Axes(hg.GA_RightTrigger), -1.0, 1.0, 0.0, 1.0)
        target_zoom_level = SmoothZoomLevel(target_zoom_level)
        target_zoom_level = clamp(target_zoom_level, 0.0, 1.0)
        target_zoom_level = map(target_zoom_level, 0.0, 1.0, 0.0, 1.1)
    end

    ctx.zoom_level = hg.Lerp(ctx.zoom_level, target_zoom_level + target_zoom_level_keyboard, 0.1)
    -- ctx.zoom_level = SmoothZoomLevel(ctx.zoom_level)

    local zoom_factor = map(ctx.zoom_level, 0.0, 1.0, 0.4, 0.8)
    local width = 28.0
    local height = 8.0 -- (width / 16.0) * 9.0

    -- print(ctx.pos.x .. ", " ..  ctx.pos.y)

    local target_pos = ctx.pos + (cam_dir + cam_dir_keyboard) * map(ctx.zoom_level, 0.0, 1.0, far_speed, close_speed) * dts
    target_pos.z = map(ctx.zoom_level, 0.0, 1.0, ctx.original_pos.z * 0.4, ctx.original_pos.z * 0.125)
    ctx.pos = hg.Lerp(ctx.pos, target_pos, 0.05)

    ctx.pos.x = clamp(ctx.pos.x, -(width * zoom_factor) / 2.0, (width * zoom_factor) / 2.0)
    ctx.pos.y = clamp(ctx.pos.y, -(height * zoom_factor) / 2.0, (height * zoom_factor) / 2.0)

    -- ctx.pos = dtAwareDamp(ctx.pos, target_pos, 0.1, dts)
    -- print(ctx.pos.x .. ", " .. ctx.pos.y)

    ctx.camera:GetTransform():SetPos(ctx.pos)

    ctx.scene:Update(dt)

    return ctx
end

function SceneMiroRender(ctx, view_id, rect, ar_flag, res, pipeline_info, frame)
    -- render miro
    view_id, passId = hg.SubmitSceneToPipeline(view_id, ctx.scene, rect, ar_flag, pipeline_info, res)
    return view_id, passId
end    
