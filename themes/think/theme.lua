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
local capi = { screen = screen }
local os = {
    date = os.date,
    time = os.time,
    setlocale = os.setlocale,
    getenv = os.getenv,
}
local secretloaded, secret = pcall(require, "away.secret")
if not secretloaded then
    secret = {}
end

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

function theme.get_miscwall(s, i)
    if i == 1 then
        return away.wallpaper.get_miscwallpaper(s, { timeout=300 }, {
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
    elseif i == 2 then
        return away.wallpaper.get_miscwallpaper(s, { timeout=300, random=true, update_by_tag=false }, {
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
                name = 'spotlight', weight = 1,
                --args = {},
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
    else
        return nil
    end
end

theme.enable_videowall = true

function theme.get_videowall(s, i)
    if i == 1 then
        --http://fy4.nsmc.org.cn/nsmc/cn/theme/FY4B.html
        return away.wallpaper.get_videowallpaper(s, {
            -- 3h, 6h, 12h, 24h, 48h, 72h
            path = 'http://img.nsmc.org.cn/CLOUDIMAGE/FY4B/AGRI/GCLR/VIDEO/FY4B.disk.gclr.24h.mp4',
            timeout = 3600*12,
        })
    else
        return nil
    end
end

function theme.wallpaper(s)
    local index = s.index % 2
    if index == 0 then
        -- screen 2, 4, 6
        index = 2
    end
    if s.miscwallpaper then
        s.miscwallpaper.update()
    else
        s.miscwallpaper = theme.get_miscwall(s, index)
    end
    if s.videowallpaper then
        s.videowallpaper.update()
    else
        s.videowallpaper = theme.enable_videowall and theme.get_videowall(s, index)
    end
    return theme.wallpaper_fallback[index]
end

function theme.del_selected_videowall(s)
    if type(s) ~= 'screen' then
        s = awful.screen.focused()
    end
    if s.videowallpaper then
        s.videowallpaper.delete_timer()
        s.videowallpaper.kill_and_set()
        s.videowallpaper = nil
    end
end
-- delete timer of wallpaper
function theme.del_wallpaper_timer(s)
    away.util.print_info('Removed screen is ' .. gears.debug.dump_return(s.outputs))
    if s.miscwallpaper then
        s.miscwallpaper.delete_timer()
    end
    theme.del_selected_videowall(s)
end

function theme.update_focused_videowall()
    local s = awful.screen.focused()
    if s.videowallpaper then
        s.videowallpaper.update()
    end
end
function theme.kill_focused_videowall()
    local s = awful.screen.focused()
    if s.videowallpaper then
        s.videowallpaper.kill_and_set()
    end
end
-- }}}

-- {{{ Styles
theme.thefont = "WenQuanYi Micro Hei"
theme.font = "WenQuanYi Micro Hei 12"
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

-- {{{ ChatGPT
theme.gpt_icon1 = theme.dir .. '/chatgpt/chatgpt-icon.png'
theme.gpt_icon2 = theme.dir .. '/chatgpt/chatgpt-logo.png'
theme.gpt_icon3 = theme.dir .. '/chatgpt/openai-black.png'
theme.gpt_icon4 = theme.dir .. '/chatgpt/openai-white.png'
theme.ca_icon1  = theme.dir .. '/chatgpt/chatanywhere.png'
theme.ca_icon2  = theme.dir .. '/chatgpt/chatanywhere-light.png'
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
theme.terminal = "xterm"
theme.editor = os.getenv("EDITOR") or "vim"
theme.editor_cmd = theme.terminal .. " -e '" .. theme.editor .. " %s'"
away.menu.init({ icon_theme=theme.icon_theme })
away.menu.menubar_nice_category_name()
function theme.xrandr_menu()
    return away.xrandr_menu({})
end
function theme.updates_menu()
    local t = {
        { "main menu", function()
            local s = awful.screen.focused()
            if s.mymainmenu then
                s.mymainmenu:update()
            end
        end },
        { "weather", function()
            if theme.widgets and theme.widgets.weather then
                theme.widgets.weather.update()
            end
        end },
        { "lunar", function()
            if theme.widgets and theme.widgets.lunar then
                theme.widgets.lunar.update()
            end
        end },
        { "misc wall", function()
            local s = awful.screen.focused()
            if s.miscwallpaper then
                s.miscwallpaper.update()
            end
        end },
    }
    if theme.enable_videowall then
        t = away.util.table_merge(t, {
            { "video wall", theme.update_focused_videowall },
            { "kill videowall", theme.kill_focused_videowall },
            { "del videowall", theme.del_selected_videowall },
        })
    end
    return t
end
theme.more_awesomemenu = nil
function theme.awesomemenu()
    local t = {
        { "updates", theme.updates_menu() },
        { "xrandr", theme.xrandr_menu() },
        { "this bing", function()
            local s = awful.screen.focused()
            if s.miscwallpaper then
                s.miscwallpaper.print_using()
            end
        end } }
    if theme.enable_videowall then
        t = away.util.table_merge(t, {
            { "this video", function()
                local s = awful.screen.focused()
                if s.videowallpaper then
                    s.videowallpaper.print_using()
                end
            end } })
    end
    if type(theme.more_awesomemenu) == 'function' then
        t = away.util.table_merge(t, theme.more_awesomemenu())
    end
    t = away.util.table_merge(t, {
        -- add default myawesomemenu
        { "hotkeys", function()
            hotkeys_popup.show_help(nil, awful.screen.focused())
        end },
        { "manual", theme.terminal .. " -e 'man awesome'" },
        { "edit config", string.format(theme.editor_cmd, awesome.conffile) },
        { "restart", awesome.restart },
        { "quit", function() awesome.quit() end } })
    return { {"Awesome", t, theme.awesome_icon} }
end
function theme.custommenu()
    return {
        { "Terminal (&T)", theme.terminal, away.menu.find_icon('terminal') },
        { "Firefox (&B)", "firefox", away.menu.find_icon('firefox') },
    }
end
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
local wfont = 'Ubuntu Mono 14'
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
-- 3.3 ChatAnywhere usage
local causage_api1 = function(KEY, model)
    local get_info = function(self, data)
        -- get self.today {.tokens, .count, .cost} and self.detail
        local today = { tokens=0, count=0, cost=0 }
        local detail = {
            ' Day   Tokens\tCount\tCost',  -- \t=8
            '-----  ------\t-----\t----',
        }
        local row = "%s\t<b>%s</b>\t <b>%d</b>\t<b>%.2f</b>"
        for i = #data,1,-1 do  -- reversed
            local day = data[i]['time']:sub(6,10)  -- 5
            local tokens = data[i]['totalTokens']
            local count = data[i]['count']
            local cost = data[i]['cost']
            if tokens > 10000 then
                tokens = string.format("%.1fw", tokens/10000)
            end
            if i == #data then  -- last, latest
                if day == os.date('%m-%d') then  -- today
                    today.tokens = tokens
                    today.count = count
                    today.cost = cost
                end
            end
            table.insert(detail, string.format(row, day, tokens, count, cost))
        end
        self.today = today
        self.detail = table.concat(detail, '\n')
    end
    return {
        url = "https://api.chatanywhere.org/v1/query/day_usage_details",
        header = { ['Content-Type']  = "application/json",
                   ['Authorization'] = KEY, },
        postdata = string.format('{"days":5,"model":"%s"}', model),
        get_info = get_info,
    }
end
local causage_api2 = function(KEY)
    return {
        url = "https://api.chatanywhere.org/v1/query/balance",
        header = { ['Content-Type']  = "application/json",
                   ['Authorization'] = KEY, },
        postdata = '',
        get_info = function(self, data)
            -- get self.balance {.used, .total, .perc}
            local used, total = data['balanceUsed'], data['balanceTotal']
            local perc
            if total == 0 then  -- free
                perc = 0
            else
                perc = used/total*100
            end
            self.balance = { used=used, total=total, perc=perc }
        end
    }
end
local causages, cargs, timeout, plus = {}, nil, 3599, '+'
for _, cargs in ipairs(secret.CA_API_USAGE) do
    local key = cargs.key
    local shortkey = string.sub(key,-4,-1)
    table.insert(causages, away.widget.apiusage({
        id = 'CA-sk-' .. shortkey, timeout= timeout, font = 'Ubuntu Mono 14',
        apis = {
            causage_api1(key, cargs.model or '%'),
            causage_api2(key),
        },
        setting = function(self)
            self.now.icon = theme[cargs.icon1 or 'ca_icon1']
            self.now.notification_icon = theme[cargs.icon2 or 'ca_icon2']
            local today =  self.today or { tokens=-1, count=-1, cost=-1 }
            local balance = self.balance or { used=-1, total=-1, perc=-1 }
            local text
            if cargs.txt == 'count' then
                text = string.format("<b>%s%d</b>", plus, today.count)
                if today.count > 70 then
                    text = away.util.markup_span(text, '#FF6600')
                elseif today.count > 40 then
                    text = away.util.markup_span(text, '#E0DA37')
                end
            elseif cargs.txt == 'perc' then
                text = string.format("<b>%s%.0f%%</b>", plus, balance.perc)
                if balance.perc > 80 then
                    text = away.util.markup_span(text, '#FF6600')
                elseif balance.perc > 50 then
                    text = away.util.markup_span(text, '#E0DA37')
                end
            else  -- default text, used
                text = string.format("<b>%s%.1f</b>", plus, balance.used)
            end
            self.now.text = text
            local title = string.format("sk-%s: %.2f", shortkey, balance.used)
            if balance.total > 10000 then
                title = title .. string.format("/%.1fw", balance.total/10000)
            elseif balance.total > 0 then
                title = title .. string.format("/%.0f", balance.total)
            end
            if cargs.model and cargs.model ~= '%' then
                title = string.format('%s | %s', title, cargs.model)
            end
            local indent = string.rep(' ', (28-title:len())//2)
            title = string.format('%s<b>%s</b>\n', indent, title)
            self.now.notification_text = title .. (self.detail or '')
        end
        })
    )
    timeout = timeout + 1
end
--away.util.print_info(away.third_party.inspect(causages))
local _wCA = {}
if #causages > 0 then
    -- group( 1.workers, 2.wibox.widget args )
    local cawidgets = { causages[1].wicon }
    for _, causg in ipairs(causages) do
        table.insert(cawidgets, causg.wtext)
    end
    _wCA = away.widget.apiusage.group(causages, cawidgets)
    _wCA:attach(_wCA.wlayout)
    _wCA.wlayout:buttons(_wCA.updatebuttons)
end
-- 4. weather
local _wweather = away.widget.weather.tianqi({
    --timeout = 1800, -- 30 min
    font = wfont,
    query = secret.yiketianqi_query,  -- default in tianqi.lua
    --curl = 'curl -f -s -m 1.7'
})
_wweather:attach(_wweather.wicon)
-- 5. systray
local _wsystray = wibox.widget.systray()
-- 6. battery
local _wbattery = away.widget.battery({
    theme = theme,
    font = wfont,
})
_wbattery:attach(_wbattery.wicon)
-- kill videowallpaper, save energy
table.insert(_wbattery.observer.handlers, function(observer, val)
    if observer.status == 'Discharging' then
        for s in capi.screen do
            if s.videowallpaper and s.videowallpaper.pid then
                s.videowallpaper.kill_and_set()
            end
        end
    end
end)
-- 7. ALSA volume
local _wvolume = away.widget.alsa({
    theme = theme,
    setting = function(volume)
        volume.set_now(volume)
        if volume.now.status == "off" then
            awful.spawn("volnoti-show -m")
        else
            awful.spawn(string.format("volnoti-show %s", volume.now.level))
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
    font = wfont,
    timeout = 2,
})
_wmem:attach(_wmem.wicon)
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
    causage = _wCA,
    weather = _wweather,
    systray = _wsystray, -- 5
    battery = _wbattery,
    volume = _wvolume,
    temp = _wtemp,
    cpu = _wcpu,
    mem = _wmem, -- 10
}
-- group all widgets
local _w = theme.widgets
theme.groupwidgets = {
    {_w.mem.wicon, _w.mem.wtext},
    {_w.cpu.wicon, _w.cpu.wtext},
    {_w.temp.wicon, _w.temp.wtext},
    {_w.volume.wicon, _w.volume.wtext},
    {_w.battery.wicon, _w.battery.wtext},
    {_w.systray, _w.weather.wicon, _w.weather.wtext, _wCA.wlayout},
    {_w.lunar.wtext, _w.textclock},
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
            font = s.mymainmenu.menu_font,
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

function theme.set_dpi(s)
    if s.geometry.width > 1920 then
        s.dpi = math.floor(s.geometry.width/1920*96)
    else
        s.dpi = 96
    end
    away.xrandr.read_and_set_dpi(function(dpi)
        if s.dpi < dpi then
            s.dpi = dpi
        end
    end)
end

function theme.createmywibox(s)
    -- DPI
    theme.set_dpi(s)
    -- Wallpaper
    gears.wallpaper.maximized(theme.wallpaper(s), s, true)
    -- Create a launcher widget and a main menu for each screen
    local menu_font = theme.font
    --local menu_font = theme.thefont .. " 15"
    s.mymainmenu = away.menu({
        before = theme.awesomemenu(), after = theme.custommenu(),
        theme = {
            height = dpi(20, s), width = dpi(120, s), font = menu_font,
        },
    })
    s.mymainmenu.menu_font = menu_font
    s.mylauncher = awful.widget.launcher({
        image = theme.awesome_icon, menu = s.mymainmenu
    })
    -- Each screen has its own tag table.
    awful.tag(theme.tagnames[s.index], s, theme.layouts[s.index])
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = theme.taglist_buttons,
        --style   = { font=theme.font }
    }
    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = theme.tasklist_buttons,
        --style   = { font=theme.font }
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
    -- group all widgets
    local enablewidgets = away.util.table_merge({}, theme.groupwidgets)
    enablewidgets = away.util.table_merge(enablewidgets, { {s.mylayoutbox} })
    local right_layout_toggle = true
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
