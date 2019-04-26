Awesome Away
==============

:Author: shmilee
:Version: git
:License: GNU-GPL2
:Source: https://github.com/shmilee/awesome-away

Description
-----------

This module provides wallpapers, widgets and utilities for Awesome_ WM 4.x.


Dependencies
------------

* curl_: download data with URL
* dkjson_: decode json data
* acpi_: optional, for `away.widget.battery`
* sxtwl_: optional, for `away.widget.lunar`

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

* support `name`:
   - `local`: Use images in the given dicrectory
   - `360chrome`: Fetch http://wallpaper.apc.360.cn/ images
   - `baidu`: Fetch http://image.baidu.com/ images
   - `bing`: Fetch https://www.bing.com daily images
   - `nationalgeographic`: Fetch https://www.nationalgeographic.com/photography/photo-of-the-day/ images
   - `spotlight`: Fetch Windows spotlight's images

* support `args` of `local`:

  +-----------+-------------------------+------------------+------------------------+
  | Argument  | Meaning                 | Type             | Default                |
  +===========+=========================+==================+========================+
  | id        | ID                      | string           | nil                    |
  +-----------+-------------------------+------------------+------------------------+
  | dirpath   | images dicrectory path  | string           | nil                    |
  +-----------+-------------------------+------------------+------------------------+
  | imagetype | images extension        | table of strings | {'jpg', 'jpeg', 'png'} |
  +-----------+-------------------------+------------------+------------------------+
  | ls        | cmd `ls`                | string           | 'ls -a'                |
  +-----------+-------------------------+------------------+------------------------+
  | filter    | filename filter pattern | string           | '.*'                   |
  +-----------+-------------------------+------------------+------------------------+
  | setting   | Set wallpaper           | function         | `function(wp) ... end` |
  +-----------+-------------------------+------------------+------------------------+

* support `args` of others, like `bing`:

  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | Argument     | Meaning                                       | Type                | Default                                    |
  +==============+===============================================+=====================+============================================+
  | id           | ID                                            | string              | 'Bing'                                     |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | api          | web api                                       | string              | 'https://www.bing.com/HPImageArchive.aspx' |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | query        | search query                                  | table of parameters | { format='js', idx=-1, n=8 }               |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | choices      | choices in response                           | table of numbers    | { 1, 2, 3, 4, 5, 6, 7, 8 }                 |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | curl         | curl cmd                                      | string              | 'curl -f -s -m 10'                         |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | cachedir     | path to store images                          | string              | "~/.cache/wallpaper-bing"                  |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | timeout_info | refresh timeout seconds for fetching new json | number              | 86400                                      |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | setting      | Set wallpaper                                 | function            | `function(wp) ... end`                     |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | force_hd     | force to use HD image(work with `get_url`)    | boolean             | true                                       |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | get_url      | get image url from response data              | function            | `function(wp, data, choice) ... end`       |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+
  | get_name     | get image name  from response data            | function            | `function(wp, data, choice) ... end`       |
  +--------------+-----------------------------------------------+---------------------+--------------------------------------------+

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
  | candidates            | misc wallpaper candidates                          | table of `solo_wallpaper` table | nil     |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | solo_wallpaper.name   | `local` or `bing` etc                              | string                          | nil     |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | solo_wallpaper.weight | frequency of this wallpaper                        | number                          | nil     |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+
  | solo_wallpaper.args   | args of this wallpaper, see above                  | table                           | nil     |
  +-----------------------+----------------------------------------------------+---------------------------------+---------+

Widget Usage
--------------

Battery
````````

.. code:: lua

    battery = away.widget.battery({
        timeout = 5,
        font ='Ubuntu Mono 12',
        --setting = function(battery) .... end,
    })
    battery:attach(battery.wicon)


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
            version='v1',
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
        --curl = 'curl -f -s -m 1.7'
        --font ='Ubuntu Mono 12',
        --get_info = function(weather, data) end,
        --setting = function(weather) end,
    })
    weather:attach(weather.wicon)


.. _Awesome: https://github.com/awesomeWM/awesome
.. _curl: https://curl.haxx.se/
.. _dkjson: https://github.com/LuaDist/dkjson
.. _acpi: https://sourceforge.net/projects/acpiclient/files/acpiclient/
.. _sxtwl: https://github.com/yuangu/sxtwl_cpp
