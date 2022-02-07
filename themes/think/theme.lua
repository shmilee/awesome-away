-------------------------------
--  "think" awesome theme  --
--        By shmilee       --
-------------------------------

local away  = require("away")
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local dpi   = require("beautiful").xresources.apply_dpi
local gfs   = require("gears.filesystem")
local hotkeys_popup = require("awful.hotkeys_popup")
local os    = {
    date = os.date,
    time = os.time,
    setlocale = os.setlocale,
    getenv = os.getenv,
    execute = os.execute,
}

-- inherit zenburn theme
local theme = dofile(gfs.get_themes_dir() .. "zenburn/theme.lua")

-- {{{ Main
theme.dir = away.util.curdir .. "themes/think"
-- }}}

-- {{{ Wallpaper
theme.wallpaper_fallback = {
    theme.dir .. "/think-1920x1200.jpg",
    theme.dir .. "/violin-1920x1080.jpg",
}

function theme.set_videowall(s, i)
    if i == 1 then
        --http://fy4.nsmc.org.cn/portal/cn/theme/FY4A.html
        s.videowallpaper = away.wallpaper.get_videowallpaper(s, {
            -- 3h, 6h, 12h, 24h, 48h, 72h
            path = 'http://img.nsmc.org.cn/CLOUDIMAGE/FY4A/MTCC/VIDEO/FY4A.disk.24h.mp4',
            timeout = 3600*12,
        })
    else
        return nil
    end
end

function theme.wallpaper(s)
    -- screen 1
    if s.index % 2 == 1 then
        s.miscwallpaper = away.wallpaper.get_miscwallpaper(s, { timeout=300 }, {
            {
                name = 'bing', weight = 2,
                args = {
                    -- idx: TOMORROW=-1, TODAY=0, YESTERDAY=1, ... 7
                    query = { format='js', idx=-1, n=8 },
                    --cachedir = gfs.get_xdg_cache_home() .. "wallpaper-bing",
                    force_hd = true,
                },
            },
            {
                name = 'local', weight = 1,
                args = {
                    id = 'Local bing',
                    dirpath = gfs.get_xdg_cache_home() .. "wallpaper-bing",
                    filter = os.date('^%Y%m',os.time()-30*24*3600),
                    --ls = 'ls -r',
                },
            },
            {
                name = 'local', weight = 2,
                args = {
                    id = 'Local 360chrome',
                    dirpath = gfs.get_xdg_cache_home() .. "wallpaper-360chrome",
                    --filter = '^$',
                    ls = 'ls -r',
                },
            },
        })
        theme.set_videowall(s, 1)
        return theme.wallpaper_fallback[1]
    -- screen 2
    else
        s.miscwallpaper = away.wallpaper.get_miscwallpaper(s, { timeout=300, random=true, update_by_tag=false }, {
            {
                name = '360chrome', weight = 2,
                --args = {},
            },
            {
                name = 'wallhaven', weight = 2,
                args = {
                    query = { q='landscape', atleast='1920x1080', sorting='favorites', page=1 }
                },
            },
            {
                name = 'local', weight = 2,
                args = {
                    id = 'Local bing',
                    dirpath = gfs.get_xdg_cache_home() .. "wallpaper-bing",
                    filter = os.date('^%Y%m',os.time()-365*24*3600),
                },
            },
            {
                name = 'local', weight = 2,
                args = {
                    id = 'Local lovebizhi',
                    dirpath = gfs.get_xdg_cache_home() .. "wallpaper-lovebizhi",
                    filter = '^风光风景',
                },
            },
        })
        theme.set_videowall(s, 2)        
        return theme.wallpaper_fallback[2]
    end
end
-- }}}

-- {{{ Styles
theme.thefont = "WenQuanYi Micro Hei"
theme.font = "WenQuanYi Micro Hei " ..  dpi(10)
-- }}}

-- {{{ Widgets
-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
theme.ac          = theme.dir .. "/widgets/ac.png"
theme.bat         = theme.dir .. "/widgets/bat.png"
theme.bat_low     = theme.dir .. "/widgets/bat_low.png"
theme.bat_no      = theme.dir .. "/widgets/bat_no.png"
theme.cpu         = theme.dir .. "/widgets/cpu.png"
theme.mem         = theme.dir .. "/widgets/mem.png"
theme.netdown     = theme.dir .. "/widgets/net_down.png"
theme.netup       = theme.dir .. "/widgets/net_up.png"
theme.pause       = theme.dir .. "/widgets/pause.png"
theme.play        = theme.dir .. "/widgets/play.png"
theme.temp        = theme.dir .. "/widgets/temp.png"
theme.vol         = theme.dir .. "/widgets/vol.png"
theme.vol_low     = theme.dir .. "/widgets/vol_low.png"
theme.vol_mute    = theme.dir .. "/widgets/vol_mute.png"
theme.vol_no      = theme.dir .. "/widgets/vol_no.png"
theme.widget_bg   = theme.dir .. "/widgets/widget_bg.png"
-- }}}

-- {{{ Misc
theme.awesome_icon      = theme.dir .. "/misc/arch-icon.png"
theme.capslock_on       = theme.dir .. "/misc/capslock_on.png"
theme.capslock_off      = theme.dir .. "/misc/capslock_off.png"
theme.touchpad_on       = theme.dir .. "/misc/touchpad_on.png"
theme.touchpad_off      = theme.dir .. "/misc/touchpad_off.png"
--theme.icon_theme = "Adwaita"
theme.icon_theme = "Faenza"
theme.client_rounded_radius =  dpi(8)
-- }}}

-- {{{ Menu
theme.menu_height = dpi(20)
theme.menu_width  = dpi(120)
theme.terminal = "xfce4-terminal"
theme.editor = os.getenv("EDITOR") or "vim"
theme.editor_cmd = theme.terminal .. " -e '" .. theme.editor .. " %s '"
theme.awesomemenu = {
    { "Awesome", {
        { "hotkeys", function()
            hotkeys_popup.show_help(nil, awful.screen.focused())
        end },
        { "this bing", function()
            local s = awful.screen.focused()
            if s.miscwallpaper then
                s.miscwallpaper.print_using()
            end
        end },
        { "next bing", function()
            local s = awful.screen.focused()
            if s.miscwallpaper then
                s.miscwallpaper.update()
            end
        end },
        { "manual", theme.terminal .. " -e 'man awesome'" },
        { "edit config", string.format(theme.editor_cmd, awesome.conffile) },
        { "restart", awesome.restart },
        { "quit", function() awesome.quit() end }
    }, theme.awesome_icon }
}
theme.custommenu = {
    { "Terminal (&T)", theme.terminal, away.menu.find_icon('terminal', theme.icon_theme) },
    { "Firefox (&B)", "firefox", away.menu.find_icon('firefox', theme.icon_theme) },
}
-- }}}

-- {{{ Layout
theme.layout_tile       = theme.dir .. "/layouts/tile.png"
theme.layout_tileleft   = theme.dir .. "/layouts/tileleft.png"
theme.layout_tilebottom = theme.dir .. "/layouts/tilebottom.png"
theme.layout_tiletop    = theme.dir .. "/layouts/tiletop.png"
theme.layout_fairv      = theme.dir .. "/layouts/fairv.png"
theme.layout_fairh      = theme.dir .. "/layouts/fairh.png"
theme.layout_spiral     = theme.dir .. "/layouts/spiral.png"
theme.layout_dwindle    = theme.dir .. "/layouts/dwindle.png"
theme.layout_max        = theme.dir .. "/layouts/max.png"
theme.layout_fullscreen = theme.dir .. "/layouts/fullscreen.png"
theme.layout_magnifier  = theme.dir .. "/layouts/magnifier.png"
theme.layout_floating   = theme.dir .. "/layouts/floating.png"
local layouts = awful.layout.layouts
theme.layouts = {
    { layouts[1], layouts[1], layouts[2], layouts[1], layouts[1] },
    layouts[2],
    layouts[1],
    layouts[2],
}
-- }}}

-- {{{ Tags
theme.tagnames = {
    { "宫", "商", "角", "徵", "羽" },
    { "壹", "貳", "叄", "肆", "伍", "陸", "柒", "捌", "玖" },
    { "一", "二", "三", "四", "五", "六", "七", "八", "九" },
    {  1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
}
-- }}}

-- {{{ Create Widgets
local wfont = 'Ubuntu Mono '
-- 1. textclock widget
local _wtextclock = wibox.widget.textclock(" %H:%M:%S ",1)
-- 2. calendar
local _wcal = away.third_party.widget.cal({
    attach_to = { _wtextclock },
    week_start = 1,
    notification_preset = {
        font = wfont,
        fg   = theme.fg_normal,
        bg   = theme.bg_normal
    },
    followtag = true,
})
--os.setlocale(os.getenv("LANG"))
_wtextclock:disconnect_signal("mouse::enter", _wcal.hover_on)
-- 3. lunar
local _wlunar = away.widget.lunar({
    timeout  = 10800,
    font = wfont,
})
_wlunar:attach(_wlunar.wtext)
-- 4. weather
local _wweather = away.widget.weather.tianqi({
    timeout = 600, -- 10 min
    font = wfont,
    --query = {.default.in.mod.},
    --curl = 'curl -f -s -m 1.7'
})
-- 5. systray
local _wsystray = wibox.widget.systray()
_wweather:attach(_wweather.wicon)
-- 6. battery
local _wbattery = away.widget.battery({
    theme = theme,
    font = wfont,
})
_wbattery:attach(_wbattery.wicon)
-- 7. ALSA volume
local _wvolume = away.widget.alsa({
    theme = theme,
    setting = function(volume)
        volume.set_now(volume)
        if volume.now.status == "off" then
            os.execute(string.format("volnoti-show -m"))
        else
            os.execute(string.format("volnoti-show %s", volume.now.level))
        end
    end,
    buttoncmds = { left="pavucontrol" },
})
-- 8. coretemp
local _wtemp = away.widget.thermal({
    theme = theme,
    font = wfont,
})
_wtemp:attach(_wtemp.wicon)
-- 9. CPU
local _wcpu = away.widget.cpu({
    theme = theme,
    font = wfont,
})
_wcpu:attach(_wcpu.wicon)
-- 10. MEM
local _wmem = away.widget.memory({
    theme = theme,
    timeout = 2,
})
-- Separators
local separators = away.third_party.separators
local arrl_dl = separators.arrow_left(theme.bg_focus, "alpha")
local arrl_ld = separators.arrow_left("alpha", theme.bg_focus)
local arrr = separators.arrow_right(theme.bg_focus, "alpha")
-- }}}

theme.widgets = {
    textclock = _wtextclock,
    cal = _wcal,
    lunar = _wlunar,
    weather = _wweather,
    systray = _wsystray, -- 5
    battery = _wbattery,
    volume = _wvolume,
    temp = _wtemp,
    cpu = _wcpu,
    mem = _wmem, -- 10
}

-- {{{ Buttons
theme.root_buttons = gears.table.join(
    awful.button({ }, 3, function ()
        local s = awful.screen.focused()
        s.mymainmenu:toggle()
    end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
)
theme.taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
                              if client.focus then
                                  client.focus:move_to_tag(t)
                              end
                          end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
                              if client.focus then
                                  client.focus:toggle_tag(t)
                              end
                          end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)
theme.tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", {raise = true})
        end
    end),
    awful.button({ }, 3, function()
        local s = awful.screen.focused()
        awful.menu.client_list({ theme = {
            width = s.geometry.width*0.678,
            height = dpi(20, s),
            font = theme.thefont .. " " .. dpi(12, s),
        }})
    end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)
theme.layoutbox_buttons = gears.table.join(
    awful.button({ }, 1, function () awful.layout.inc( 1) end),
    awful.button({ }, 3, function () awful.layout.inc(-1) end),
    awful.button({ }, 4, function () awful.layout.inc( 1) end),
    awful.button({ }, 5, function () awful.layout.inc(-1) end)
)
-- }}}

function theme.createmywibox(s)
    if s.geometry.width > 1920 then
        s.dpi = math.floor(s.geometry.width/1920*96)
    end

    -- Wallpaper
    gears.wallpaper.maximized(theme.wallpaper(s), s, true)
    -- Create a launcher widget and a main menu for each screen
    away.menu.use_zh_CN()
    s.mymainmenu = away.menu:generate({
        before = theme.awesomemenu, after = theme.custommenu,
        theme = {
            height = dpi(20, s), width = dpi(120, s),
            font = theme.thefont .. " " .. dpi(12, s),
        },
    })
    s.mylauncher = awful.widget.launcher({
        image = theme.awesome_icon, menu = s.mymainmenu
    })
    -- Each screen has its own tag table.
    awful.tag(theme.tagnames[s.index], s, theme.layouts[s.index])
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = theme.taglist_buttons
    }
    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = theme.tasklist_buttons
    }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height =  dpi(20,s), opacity = 0.88 })
    -- Create right widgets
    s.mywibox.rightwidgets = {
        layout = wibox.layout.fixed.horizontal,
        --mykeyboardlayout,
    }
    -- layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(theme.layoutbox_buttons)
    -- videowallpaper, _wbattery
    if s.videowallpaper then
        table.insert(_wbattery.observer.handlers, function(observer, val)
            if observer.status == 'Discharging' then
                s.videowallpaper.kill_and_set() -- save energy
            end
        end)
    end
    -- group all widgets
    local enablewidgets = {
        {_wmem.wicon, _wmem.wtext},
        {_wcpu.wicon, _wcpu.wtext},
        {_wtemp.wicon, _wtemp.wtext},
        {_wvolume.wicon, _wvolume.wtext},
        {_wbattery.wicon, _wbattery.wtext},
        {_wsystray, _wweather.wicon, _wweather.wtext},
        {_wlunar.wtext, _wtextclock},
        {s.mylayoutbox},
    }
    local right_layout_toggle = true
    local wg, w
    for _, wg in ipairs(enablewidgets) do
        if right_layout_toggle then
            table.insert(s.mywibox.rightwidgets, arrl_ld)
            for _, w in ipairs(wg) do
                table.insert(s.mywibox.rightwidgets, wibox.container.background(w, theme.bg_focus))
            end
        else
            table.insert(s.mywibox.rightwidgets, arrl_dl)
            for _, w in ipairs(wg) do
                table.insert(s.mywibox.rightwidgets, w)
            end
        end
        right_layout_toggle = not right_layout_toggle
    end

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mylauncher,
            s.mytaglist,
            arrr,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        -- Right widgets
        s.mywibox.rightwidgets
    }
end

return theme