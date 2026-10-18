hl.env("GTK_THEME", "Adwaita-dark")

-- monitors matched by description, not port, so they survive cable swaps and reinstalls
-- layout: [vertical BenQ] [main ASUS] [Lenovo 1440p]
local vert = "desc:BNQ ZOWIE XL LCD EB42M00628SL0"
local main = "desc:ASUSTek COMPUTER INC VG249QM1A T4LMQS070584"
local side = "desc:Lenovo Group Limited LEN P27q-10 0x01010101"

hl.monitor({ output = vert, mode = "1920x1080@143.98", position = "-1080x-420", scale = 1, transform = 3 })
hl.workspace_rule({ workspace = "2", monitor = vert })

hl.monitor({ output = main, mode = "1920x1080@270.00", position = "0x0", scale = 1 })
hl.workspace_rule({ workspace = "1", monitor = main, default = true })

hl.monitor({ output = side, mode = "2560x1440@59.95", position = "1920x-180", scale = 1 })
hl.workspace_rule({ workspace = "3", monitor = side })

local terminal    = "ghostty"
local fileManager = "ghostty -e yazi"
local menu        = "noctalia msg panel-toggle launcher"
local browser     = "zen-browser"

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl dispatch 'hl.dsp.focus({ workspace = 1 })'")

    -- noctalia replaces waybar + hyprpaper; to go back, swap these lines
    hl.exec_cmd("noctalia -d")
    -- hl.exec_cmd("waybar")
    -- hl.exec_cmd("~/.config/hypr/start-hyprpaper.sh")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = { top = 6, right = 8, bottom = 8, left = 8 }, -- top sits under waybar

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(89b4faee)", "rgba(cba6f7ee)"}, angle = 45 },
            inactive_border = "rgba(45475a99)",
        },

        resize_on_border = false,

        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.96,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "rgba(00000066)",
        },

        blur = {
            enabled  = true,
            size       = 5,
            passes     = 2,
            brightness = 0.75, -- darken what shows through so text on top stays readable
            vibrancy   = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,    -- hyprpaper handles the wallpaper
        disable_hyprland_logo   = true,
    },

    input = {
        kb_layout  = "custom_fi",
        kb_variant = "basic",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.2,
        },
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.device({ name = "vancer-vancer-akitsu-mouse-consumer-control-1", sensitivity = -1.0 })
hl.device({ name = "vancer-vancer-akitsu-mouse-1",                  sensitivity = -1.0 })

hl.device({ name = "apple-inc.-magic-trackpad", sensitivity = 0.2, accel_profile = "adaptive" })

-- spotify slightly see-through like the terminal; the blur behind keeps it readable.
-- (vesktop does its own background-only transparency in its theme so images stay solid)
hl.window_rule({
    name    = "spotify-opacity",
    match   = { class = "^Spotify$" },
    opacity = "0.9",
})

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + M", hl.dsp.exit())

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- noctalia panels
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mainMod .. " + ESCAPE",    hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))

-- fullscreen: SUPER+F maximizes (keeps waybar), SUPER+SHIFT+F covers everything
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

hl.bind(mainMod .. " + ALT + J", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))

hl.bind("CTRL + Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" ~/Pictures/Screenshots/area_$(date +%Y%m%d_%H%M%S).png && wl-copy < ~/Pictures/Screenshots/$(ls -t ~/Pictures/Screenshots | grep area_ | head -n1)]]))

hl.bind("ALT + Print", hl.dsp.exec_cmd([[grim /home/konna/Pictures/Screenshots/full_$(date +%Y%m%d_%H%M%S).png && wl-copy < /home/konna/Pictures/Screenshots/$(ls -t /home/konna/Pictures/Screenshots | grep full_ | head -n1)]]))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- routed through noctalia so the volume OSD shows up
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("noctalia msg mic-mute"),    { locked = true, repeating = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
