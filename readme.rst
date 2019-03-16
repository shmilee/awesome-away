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

Installation
------------

.. code:: bash

   cd ~/.config/awesome
   git clone https://github.com/shmilee/awesome-away.git

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

* `name` is one of
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

* support `margs` `candidates`

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

.. TODO
TODO


.. _Awesome: https://github.com/awesomeWM/awesome
.. _curl: https://curl.haxx.se/
.. _dkjson: https://github.com/LuaDist/dkjson
