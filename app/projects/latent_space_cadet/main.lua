-- Latent Space Cadet, gallery

hg = require("harfang")
require("projects/latent_space_cadet/latent_images")
require("utils")

function SceneLatentSpaceCadetSetup(res, pipeline_info, bg_color, height_ratio)
    height_ratio = height_ratio or 1.0
    -- Load scene
    local _scene = hg.Scene()
    -- hg.LoadSceneFromAssets("projects/latent_space_cadet/template.scn", _scene, res, pipeline_info)
    _scene.canvas.color = bg_color
    _scene.environment.fog_color = bg_color
    _scene.canvas.clear_color = false

    local template_height = 6.0 * height_ratio
    local template_padding = 1.2

    -- load photos using the template.scn
    local _y = 0.0
    local _idx
    for _idx=1, #latent_images do
        local _temp_mat =  hg.TransformationMat4(hg.Vec3(0,_y,0), hg.Vec3(0,0,0))
        -- load template
        local _new_node, _ret = hg.CreateInstanceFromAssets(_scene, _temp_mat, "projects/latent_space_cadet/template.scn", res, pipeline_info)

        -- change photos textures
        local _ai_node = _new_node:GetInstanceSceneView():GetNode(_scene, "ai")
        local _photo_node = _new_node:GetInstanceSceneView():GetNode(_scene, "photo")
        local _title_node = _new_node:GetInstanceSceneView():GetNode(_scene, "title")

        if _idx == 20 or _idx == 30 then
            local _scale = _ai_node:GetTransform():GetScale()
            _scale.x = _scale.x * (1640.0 / 2048.0)
            _ai_node:GetTransform():SetScale(_scale)
            _photo_node:GetTransform():SetScale(_scale)
        end

        local _texture = hg.LoadTextureFromAssets("projects/latent_space_cadet/images/" .. latent_images[_idx].images[2], hg.TF_UClamp | hg.TF_VClamp, res)
        hg.SetMaterialTexture(_ai_node:GetObject():GetMaterial(0), "uBaseOpacityMap", _texture, 0)

        local _texture = hg.LoadTextureFromAssets("projects/latent_space_cadet/images/" .. latent_images[_idx].images[1], hg.TF_UClamp | hg.TF_VClamp, res)
        hg.SetMaterialTexture(_photo_node:GetObject():GetMaterial(0), "uBaseOpacityMap", _texture, 0)

        local _texture = hg.LoadTextureFromAssets(string.format("projects/latent_space_cadet/images/" .. "%02d_title.png", _idx - 1), hg.TF_UClamp | hg.TF_VClamp, res)
        hg.SetMaterialTexture(_title_node:GetObject():GetMaterial(0), "uBaseOpacityMap", _texture, 0)


        _y = _y - (template_height * template_padding)
    end

    -- local _camera = _scene:GetNode("Camera")
    -- local _pos = _camera:GetTransform():GetPos()
	-- main camera
	local _fov = hg.DegreeToRadian(15.0) -- narrow view angle to limit the distortions
	local _distance_to_slide = CalculateCameraDistance(_fov, template_height)
    local cam_base_pos = hg.Vec3(0,0,-_distance_to_slide)
	local main_camera = hg.CreateCamera(_scene,hg.TransformationMat4(cam_base_pos, hg.Vec3(0,0,0)), _distance_to_slide / 2.0, _distance_to_slide * 2.0, _fov)
	_scene:SetCurrentCamera(main_camera)

    local ctx = {
        scene = _scene,
        camera = main_camera,
        original_pos = cam_base_pos,
        pos = cam_base_pos,
        current_photo_cursor = 0.0,
        template_height = template_height,
        template_padding = template_padding
    }

    return ctx
end

function SceneLatentSpaceCadetUpdate(ctx, keyboard, gamepad, prev_gamepad, dt, current_clock)
    local dts = hg.time_to_sec_f(dt)

    if keyboard:Released(hg.K_Z) then
        ctx.current_photo_cursor = ctx.current_photo_cursor - 1.0
    elseif keyboard:Released(hg.K_S) then
        ctx.current_photo_cursor = ctx.current_photo_cursor + 1.0
    end

    -- gamepad
    if gamepad and prev_gamepad then -- and gamepad:Connected() then
        local trigger_right = gamepad:Axes(hg.GA_RightTrigger)
        local prev_trigger_right = prev_gamepad:Axes(hg.GA_RightTrigger)
        if trigger_right > 0.0 and prev_trigger_right > 0.0 then
            ctx.current_photo_cursor = ctx.current_photo_cursor - trigger_right * dts * 5.0 -- pressing previous
        elseif trigger_right <= 0.0 and prev_trigger_right > 0.0 then
            ctx.current_photo_cursor = math.floor(ctx.current_photo_cursor) -- stopped pressing previous
        end
        -- print(trigger_right)
        if gamepad:Button(hg.GB_RightBumper) and not prev_gamepad:Button(hg.GB_RightBumper) then
            ctx.current_photo_cursor = math.floor(ctx.current_photo_cursor + 1.0) -- pressed next (once)
        end
    end

    if ctx.current_photo_cursor < 0.0 then
        ctx.current_photo_cursor = 0.0
    elseif ctx.current_photo_cursor >= #latent_images then
            ctx.current_photo_cursor = #latent_images - 1
    end

    local target_pos = ctx.original_pos - hg.Vec3(0.0, ctx.current_photo_cursor * ctx.template_height * ctx.template_padding, 0.0)
    ctx.pos = dtAwareDamp(ctx.pos, target_pos, 0.1, dts * 10.0)
    ctx.camera:GetTransform():SetPos(ctx.pos)

    ctx.scene:Update(dt)

    return ctx
end

function SceneLatentSpaceCadetRender(ctx, view_id, rect, ar_flag, res, pipeline_info, frame)
    -- render
    view_id, passId = hg.SubmitSceneToPipeline(view_id, ctx.scene, rect, ar_flag, pipeline_info, res)
    return view_id, passId
end    
