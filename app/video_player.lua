hg = require("harfang")

function CreateSceneVideoPlayer(texture, progress_bar_node, title_material, size_material, framerate_material)
    progress_bar_node = progress_bar_node or nil
    title_material = title_material or nil
    size_material = size_material or nil
    framerate_material = framerate_material or nil

    local this = {
		streamer = hg.MakeVideoStreamer('hg_ffmpeg.dll'),
		size = hg.iVec2(1024, 1024),
		fmt = hg.TF_RGB8,
        texture = texture,
		texture_updated = false,
        handle = nil,
        video_start_clock = nil,
        video_duration_sec = nil,
        progress_bar_node = progress_bar_node,
        title_material = title_material,
        size_material = size_material,
        framerate_material = framerate_material
        -- video_filename = nil
    }

    local function Play(video_filename, current_clock, video_duration_sec, video_size, video_framerate, res)
        res = res or nil
        -- this.video_filename = video_filename
        -- start streamer
        this.streamer:Startup()
        this.handle = this.streamer:Open(video_filename)
        -- this.streamer:Seek(this.handle, 0)
        this.streamer:Play(this.handle)
        this.video_start_clock = current_clock
        this.video_duration_sec = video_duration_sec

        -- update gui
        if this.title_material and res then
            -- video title
            local tex_filename = video_filename:match("([^/]+)%.mp4$")
            tex_filename = "videos/" .. tex_filename .. ".png"
            local tex_ref = hg.LoadTextureFromAssets(tex_filename, 0, res)
            hg.SetMaterialTexture(this.title_material, 'uBaseOpacityMap', tex_ref, 0)

            -- video size
            tex_filename = "common/video_player_size_" .. tostring(video_size) .. "p.png"
            tex_ref = hg.LoadTextureFromAssets(tex_filename, 0, res)
            hg.SetMaterialTexture(this.size_material, 'uBaseOpacityMap', tex_ref, 0)

            -- video framerate
            tex_filename = "common/video_player_framerate_" .. tostring(video_framerate) .. "fps.png"
            tex_ref = hg.LoadTextureFromAssets(tex_filename, 0, res)
            hg.SetMaterialTexture(this.framerate_material, 'uBaseOpacityMap', tex_ref, 0)
        end

    end

    local function Close()
        this.streamer:Close(this.handle)
        this.handle = nil
    end

    local function Update(current_clock)
        -- loop video
        if this.handle then
            if current_clock - this.video_start_clock > hg.time_from_sec_f(this.video_duration_sec) then
                this.video_start_clock = current_clock
                print("Restart video at " .. this.video_duration_sec .. "sec !")
                this.streamer:Seek(this.handle, 0)
                this.streamer:Play(this.handle)
            end

            -- update texture decoded by the ffmpeg player
            this.texture_updated, this.texture, this.size, this.fmt = hg.UpdateTexture(this.streamer, this.handle, this.texture, this.size, this.fmt)

            -- update the progress bar
            if this.progress_bar_node then
                local progress = clamp((current_clock - this.video_start_clock) / hg.time_from_sec_f(this.video_duration_sec), 0.0, 1.0)
                this.progress_bar_node:GetTransform():SetScale(hg.Vec3(progress, 1.0, 1.0))
            end
        else
            print("! Video stream closed")
        end
    end

    return {
        Play = Play,
        Close = Close,
        Update = Update
    }
end

-- -- Setup video streaming
-- local streamer = hg.MakeVideoStreamer('hg_ffmpeg.dll')
-- local video_res_x, video_res_y = 1024, 1024
-- local size = hg.iVec2(video_res_x, video_res_y)
-- local fmt = hg.TF_RGB8
-- local texture_updated

-- Initialize video streaming
-- streamer:Startup()
-- local handle = streamer:Open('assets_compiled/videos/astlan_gameplay_video.mp4')
-- streamer:Play(handle)

-- Update video texture
-- texture_updated, texture, size, fmt = hg.UpdateTexture(streamer, handle, texture, size, fmt)