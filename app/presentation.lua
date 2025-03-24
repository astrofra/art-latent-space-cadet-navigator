-- presentation

presentation = {
    {
        -- slide 1 'Intro'
    },
    {
        -- slide 2 'Latent Space Cadet'
        {type = action_type.node, ref = "photo0"},
        {type = action_type.func, ref = "SceneMiro", context = "miro", ar_flag = true, hide_slide = true},
        {type = action_type.func, ref = "SceneLatentSpaceCadet", context = "latentspacecadet", ar_flag = true, hide_slide = true}
    },
    {
        -- slide 3 'Contact'
    }
}