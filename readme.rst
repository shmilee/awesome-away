Awesome Away
==============

:Author: shmilee
:Version: git
:License: GNU-GPL2
:Source: https://github.com/shmilee/awesome-away

Description
-----------

This module provides wallpapers, widgets, themes and utilities for Awesome_ WM 4.x.
Some partial widgets and utilities extracted from other repositories are also included in `./third_party`.


Dependencies
------------

* curl_: download data with URL
* dkjson_: decode json data, included in `./third_party`
* xwinwrap_: optional, for video wallpaper `away.wallpaper.get_videowallpaper`
* mpv_: optional, for video wallpaper `away.wallpaper.get_videowallpaper`
* you-get_: optional, for Bilibili video wallpaper `away.wallpaper.get_bilivideowallpaper`
* alsa-utils_: optional, for `away.widget.alsa`
* acpi_: optional, for `away.widget.battery`
* sxtwl_: optional, for `away.widget.lunar`

optional: install xwinwrap & mpv & you-get
``````````````````````````````````````````

.. code:: shell

    # archlinux
    sudo pacman -S mpv you-get
    sudo yay -S xwinwrap-git
    # debian, ubuntu, etc
    sudo apt-get install mpv
    # install xwinwrap from source, see its homepage

optional: install alsa-utils
````````````````````````````

.. code:: shell

    sudo pacman -S alsa-utils # archlinux
    sudo apt-get install alsa-utils # debian, ubuntu, etc

optional: install acpi
```````````````````````

.. code:: shell

    sudo pacman -S acpi # archlinux
    sudo apt-get install acpi # debian, ubuntu, etc

optional: install sxtwl
```````````````````````

.. code:: shell

   git clone https://github.com/yuangu/sxtwl_cpp.git
   mkdir sxtwl_cpp/build
   cd sxtwl_cpp/build
   cmake .. -G "Unix Makefiles" -DSXTWL_WRAPPER_LUA=1
   cmake --build .
   strip sxtwl_lua.so
   cp sxtwl_lua.so ~/.config/awesome/sxtwl.so


Installation
------------

.. code:: bash

   cd ~/.config/awesome
   git clone https://github.com/shmilee/awesome-away.git away

then include `away` into your `rc.lua`

.. code:: lua

   local away = require("away")

Wallpaper Usage
---------------

example: `test-wallpaper.lua`

solo wallpaper
``````````````

.. code:: lua

   -- get_solowallpaper(screen, name, args)
   wp = away.wallpaper.get_solowallpaper(screen, 'local', {
      id='Local test',
      dirpath='/path/to/image/dir',
   })
   wp.update() -- set next wallpaper
   wp.print_using() -- print using wallpaper

* support name
   - `local`: Use images in the given dicrectory
   - `360chrome`: Fetch http://wallpaper.apc.360.cn/ images
   - `baidu`: Fetch http://image.baidu.com/ images
   - `bing`: Fetch https://www.bing.com daily images
   - `nationalgeographic`: Fetch https://www.nationalgeographic.com/photography/photo-of-the-day/ images
   - `spotlight`: Fetch Windows spotlight's images
   - `wallhaven`: Fetch https://wallhaven.cc/ images

* support `args` of `local`:

  +---------------+----------------------------------------------------+------------------+------------------------+
  | Argument      | Meaning                                            | Type             | Default                |
  +===============+====================================================+==================+========================+
  | id            | ID                                                 | string           | nil                    |
  +---------------+----------------------------------------------------+------------------+------------------------+
  | dirpath       | images dicrectory path                             | string           | nil                    |
  +---------------+----------------------------------------------------+------------------+------------------------+
  | imagetype     | images extension                                   | table of strings | {'jpg', 'jpeg', 'png'} |
  +---------------+----------------------------------------------------+------------------+------------------------+
  | ls            | cmd `ls`                                           | string           | 'ls -a'                |
  +---------------+----------------------------------------------------+------------------+------------------------+
  | filter        | filename filter pattern                            | string           | '.*'                   |
  +---------------+----------------------------------------------------+------------------+------------------------+
  | setting       | set wallpaper                                      | function         | `function(wp) ... end` |
  +---------------+----------------------------------------------------+------------------+------------------------+
  | timeout       | refresh timeout seconds for setting next wallpaper | number           | 60                     |
  +---------------+----------------------------------------------------+------------------+------------------------+
  | update_by_tag | set wallpaper when tag changed                     | boolean          | false                  |
  +---------------+----------------------------------------------------+------------------+------------------------+

* support `args` of others, like `bing`:

  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | Argument      | Meaning                                            | Type                | Default                                    |
  +===============+====================================================+=====================+============================================+
  | id            | ID                                                 | string              | 'Bing'                                     |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | api           | web api                                            | string              | 'https://www.bing.com/HPImageArchive.aspx' |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | query         | search query                                       | table of parameters | { format='js', idx=-1, n=8 }               |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | choices       | choices in response                                | table of numbers    | { 1, 2, 3, 4, 5, 6, 7, 8 }                 |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | curl          | curl cmd                                           | string              | 'curl -f -s -m 10'                         |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | cachedir      | path to store images                               | string              | "~/.cache/wallpaper-bing"                  |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | timeout_info  | refresh timeout seconds for fetching new json      | number              | 86400                                      |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | setting       | Set wallpaper                                      | function            | `function(wp) ... end`                     |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | force_hd      | force to use HD image(work with `get_url`)         | boolean or 'UHD'    | true                                       |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | get_url       | get image url from response data                   | function            | `function(wp, data, choice) ... end`       |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | get_name      | get image name  from response data                 | function            | `function(wp, data, choice) ... end`       |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | timeout       | refresh timeout seconds for setting next wallpaper | number              | 60                                         |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+
  | update_by_tag | set wallpaper when tag changed                     | boolean             | false                                      |
  +---------------+----------------------------------------------------+---------------------+--------------------------------------------+

misc wallpaper
``````````````

combine solo wallpapers `local` `360chrome` `baidu` `bing` etc.

.. code:: lua

   -- get_miscwallpaper(screen, margs, candidates)
   wp = away.wallpaper.get_miscwallpaper(
      screen, { timeout=5, random=true },
      {
         { name='bing', weight=2, args={ query={ format='js', idx=1, n=4 } } },
         { name='local', weight=2, args={ id='Local', dirpath='/dir/path' } },
         -- more ...
      })
   wp.update() -- set next wallpaper
   wp.print_using() -- print using wallpaper

* support `margs` `candidates`:

  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | Input Variable        | Meaning                                            | Type                            | Default |
  +=======================+====================================================+=================================+=========+
  | margs.timeout         | refresh timeout seconds for setting next wallpaper | number                          | 60      |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | margs.random          | random wallpaper for next                          | boolean                         | false   |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | margs.update_by_tag   | set wallpaper when tag changed                     | boolean                         | false   |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | candidates            | misc wallpaper candidates                          | table of `solo_wallpaper` table | nil     |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | solo_wallpaper.name   | `local` or `bing` etc                              | string                          | nil     |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | solo_wallpaper.weight | frequency of this wallpaper                        | number                          | nil     |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | solo_wallpaper.args   | args of this wallpaper, see above. args.timeout    | table                           | nil     |
  |                       | and args.update_by_tag are ignored.                |                                 |         |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+

video wallpaper
```````````````

.. code:: lua

   -- get_videowallpaper(screen, args)
   -- get_bilivideowallpaper(screen, args)
   wp = away.wallpaper.get_videowallpaper(screen, {
      id='Video test',
      path='/path/to/video/file.mp4',
   })
   wp.update() -- update wallpaper, reopen player
   wp.print_using() -- print video path

* support `args`:

  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | Argument     | Meaning                                                 | Type            | Default                |
  +==============+=========================================================+=================+========================+
  | id           | ID                                                      | string          | 'Video'                |
  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | path         | video path or url                                       | string          | nil                    |
  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | get_realpath | get real video path from url                            | function        | nil                    |
  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | xwinwrap     | xwinwrap cmd                                            | string          | 'xwinwrap'             |
  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | xargs        | options for xwinwrap (without -g)                       | table of string | {'-b -ov -ni -nf -un   |
  |              |                                                         |                 | -s -st -sp -o 0.9'}    |
  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | player       | video player                                            | string          | 'mpv'                  |
  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | pargs        | options for player                                      | table of string | { '-wid WID  ...etc ', |
  |              |                                                         |                 | '--loop-file ...etc'}  |
  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | after_prg    | set wallpaper after *after_prg* (pgrep pattern) started | string          | nil                    |
  +--------------+---------------------------------------------------------+-----------------+------------------------+
  | timeout      | refresh timeout seconds for updating wallpaper          | number (>=0)    | 0 (do not update)      |
  +--------------+---------------------------------------------------------+-----------------+------------------------+

* additional `arg` for Bili Video Wallpaper, `choices={'dash-flv', 'flv720', ...}`


Widget Usage
--------------

ALSA
`````

.. code:: lua

    volume = away.widget.alsa({
        theme = theme, -- or beautiful
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

Battery
````````

.. code:: lua

    battery = away.widget.battery({
        timeout = 5,
        font ='Ubuntu Mono 12',
        --setting = function(battery) .... end,
    })
    battery:attach(battery.wicon)
    -- add battery.observer.handlers to handle observer.status
    --table.insert(battery.observer.handlers, function(observer, val) ... end)

CPU
`````

.. code:: lua

   _wcpu = away.widget.cpu({
        theme = theme,
        font = wfont,
    })
    _wcpu:attach(_wcpu.wicon)

农历
````````

.. code:: lua

    lunar = away.widget.lunar({
        timeout  = 10800,
        font ='Ubuntu Mono 12',
        --setting = function(lunar) .... end,
    })
    lunar:attach(lunar.wtext)

Weather
````````

.. code:: lua

    -- available weather module's query
    weather_querys = {
        etouch = {
            citykey=101210101, --杭州
        },
        meizu = {
            cityIds=101210101,
        },
        tianqi = {
            version='v1', unescape=1,
            appid=23035354, appsecret='8YvlPNrz',
            --cityid= 101210101, -- default weather by IP address
        },
        xiaomiv2 = {
            cityId=101210101,
        },
        xiaomiv3 ={
            latitude = 0,
            longitude = 0,
            locationKey = 'weathercn:101210101', --杭州
            appKey = 'weather20151024',
            sign = 'zUFJoAR2ZVrDy1vF3D07',
            isGlobal = 'false',
            locale = 'zh_cn',
            days = 6,
        },
    }
    weather = away.widget.weather['tianqi']({
        timeout = 600, -- 10 min
        query = weather_querys['tianqi'],
        --curl = 'curl -f -s -m 7'
        --font ='Ubuntu Mono 12',
        --get_info = function(weather, data) end,
        --setting = function(weather) end,
    })
    weather:attach(weather.wicon)

每日一文
`````````

.. code:: lua

    meiriyiwen = away.widget.meiriyiwen({
        font = 'WenQuanYi Micro Hei',
        font_size = 15,
        ratio = 0, -- 0: all content; (0-1): content*ratio
        height = 0.9, -- screen.height*0.9
    })
    yiwen = meiriyiwen.update
    -- 长文章后半段, Super + x : yiwen({ratio=0.5})

Memory
``````

.. code:: lua

    mem = away.widget.memory({
        theme = theme,
        timeout = 2,
        --setting = function(mem) end,
    })

Thermal temp
````````````
.. code:: lua

    _wtemp = away.widget.thermal({
        theme = theme,
        font = wfont,
    })
    _wtemp:attach(_wtemp.wicon)


menu
----

.. code:: lua

    away.menu.init({
        osi_wm_name="",      -- Name of the WM for the OnlyShowIn entry
        icon_theme=nil,      -- icon theme for application icons
        categories_name=nil, -- category name with nice name
    })
    -- away.menu.menubar_nice_category_name()
    local dpi = require("beautiful").xresources.apply_dpi
    -- mainmenu for each screen
    s.mymainmenu = away.menu({
        before=thinktheme.awesomemenu(), -- items before freedesktop.org menu
        after=thinktheme.custommenu(),   -- items after freedesktop.org menu
        theme={ -- set menu item height, width, font for each screen
            height=dpi(20, s), width=dpi(120, s), font=nil,
        },
    })


xrandr menu
-----------

1. generate awful menu items:

.. code:: lua

    xrandr_menu = away.xrandr_menu({
        { name="H-S-MiTV", dpi=144, complete=true, monitors={
            { key='eDP1-310x170-1366x768', scale=1.5 },  -- laptop T450
            { key='Mi-TV-1220x690-3840x2160', scale=1.0 } -- Mi TV
        } },
        { name='Reset', complete=true, monitors={
            'eDP1-310x170-1366x768',  -- laptop T450, dpi=96, scale=1.0
        } },
    })
    -- showX: show connected monitors info get by 'xrandr -q --prop'
    -- showA: show screen info get from awesome
    -- Hline-auto: stack all connected outputs horizontally (--auto)
    -- Hline-scale: stack all connected outputs horizontally (--scale 1.0)
    -- H-S-MiTV: stack T450 scale=1.5, MiTV scale=1.0 horizontally
    -- Reset: only enable T450 scale=1.0, disable others (--off)

2. Get keys in lua interactive mode:

.. code:: lua

   > xrandr = require("away.xrandr") -- or xrandr = require("xrandr")
   > xrandr.show_connected()
   2022-04-06 10:41:09 Away[I]: Run command: xrandr -q --prop, DONE with exit code 0
   Monitor 1: 
   Key: eDP1-310x170-1366x768
   DPI: 112.59
   Geometry: 1366x768
   Size: 310mmx170mm
   Preferred: 1366x768
   
   Monitor 2: DELL U2723QX
   Key: DELL-U2723QX-600x340-3840x2160
   DPI: 162.28
   Geometry: 3840x2160
   Size: 600mmx340mm
   Preferred: 3840x2160
   >


Theme: think
--------------

inherit **zenburn** theme, then add

1. function theme.wallpaper(s)

   + use `away.wallpaper`
        - `os.getenv("HOME") .. "/.cache/wallpaper-bing"`
        - `os.getenv("HOME") .. "/.cache/wallpaper-360chrome"`
        - `os.getenv("HOME") .. "/.cache/wallpaper-wallhaven"`
        - `os.getenv("HOME") .. "/.cache/wallpaper-lovebizhi"`
        - online(like FY-4A) video wallpaper
   + fallback
        - think-1920x1200.jpg
        - violin-1920x1080.jpg

2. menu

   + terminal: xterm
   + editor: vim
   + firefox

3. table theme.layouts for 4 screens
4. table theme.tagnames for 4 screens
5. Widgets from `away`, save to `theme.widgets`

   + textclock, calendar
   + lunar, weather, battery, volume: need dependencies_
   + volume: also need pavucontrol, volnoti_
   + systray, coretemp, cpu, mem

6. function theme.createmywibox(s)

   + wallpaper, mainmenu, taglist, promptbox, tasklist, widgets
   + theme.height etc. for mainmenu, tasklist
   + different dpi for each screen

7. fonts

   + default: WenQuanYi Micro Hei
   + widget: Ubuntu Mono

.. _Awesome: https://github.com/awesomeWM/awesome
.. _curl: https://curl.haxx.se/
.. _dkjson: https://github.com/LuaDist/dkjson
.. _xwinwrap: https://github.com/ujjwal96/xwinwrap
.. _mpv: https://mpv.io/
.. _you-get: https://www.soimort.org/you-get/
.. _alsa-utils: https://www.alsa-project.org
.. _acpi: https://sourceforge.net/projects/acpiclient/files/acpiclient/
.. _sxtwl: https://github.com/yuangu/sxtwl_cpp
.. _dependencies: https://github.com/shmilee/awesome-away#dependencies
.. _volnoti: https://github.com/hcchu/volnoti
