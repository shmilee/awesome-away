---------------------------------------------------------------------------
--
--  Baidu Wallpaper module for away: away.wallpaper.baidu
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util = require("away.util")
local core = require("away.wallpaper.core")
local gfs  = require("gears.filesystem")

local string = { gsub = string.gsub }
local pairs  = pairs

-- http://img0.bdstatic.com/static/common/pkg/cores_xxxxxxx.js
local function baidu_url_uncompile(s)
    local t = {
        ["w"]="a",
        ["k"]="b",
        ["v"]="c",
        ["1"]="d",
        ["j"]="e",
        ["u"]="f",
        ["2"]="g",
        ["i"]="h",
        ["t"]="i",
        ["3"]="j",
        ["h"]="k",
        ["s"]="l",
        ["4"]="m",
        ["g"]="n",
        ["5"]="o",
        ["r"]="p",
        ["q"]="q",
        ["6"]="r",
        ["f"]="s",
        ["p"]="t",
        ["7"]="u",
        ["e"]="v",
        ["o"]="w",
        ["8"]="1",
        ["d"]="2",
        ["n"]="3",
        ["9"]="4",
        ["c"]="5",
        ["m"]="6",
        ["0"]="7",
        ["b"]="8",
        ["l"]="9",
        ["a"]="0",
        ["_z2C$q"]=":",
        ["_z&e3B"]=".",
        ["AzdH3F"]="/",
    }
    local patterns= {"(_z2C$q)", "(_z&e3B)", "(AzdH3F)", '([a-w%d])'}
    local i, p
    for i, p in pairs(patterns) do
        s = string.gsub(s, p, function(i) return t[i] end)
    end
    return s
end

-- BaiduWallPaper: fetch Baidu's images with meta data
local function get_baiduwallpaper(screen, args)
    local args = args or {}
    args.id    = args.id or 'Baidu'
    args.api   = args.api or "http://image.baidu.com/search/acjson"
    args.query = args.query or {
        tn='resultjson_com', cg='wallpaper', ipn='rj',
        word='壁纸+不同风格+简约',
        pn=0, rn=30,
        width=1920, height=1080,
        --width=screen.geometry.width, height=screen.geometry.height,
        -- ic: http://img1.bdstatic.com/static/searchresult/pkg/result_xxxxxxx.js
        -- red: 1, orange: 256, yellow: 2, green: 4, blue: 16,
        -- gray: 128, white: 1024, black: 512, bw: 2048, ...
        --ic=1,
    }
    args.choices  = args.choices or util.simple_range(1, 30, 1)
    --args.curl     = args.curl or 'curl -f -s -m 10'
    args.cachedir = args.cachedir or gfs.get_xdg_cache_home() .. "wallpaper-baidu"
    --args.timeout_info = args.timeout_info or 86400
    --args.async_update = args.async_update or false
    --args.setting      = args.setting or function(wp)
    --    gears.wallpaper.maximized(wp.path[wp.using], wp.screen, false)
    --end
    --args.force_hd = args.force_hd or true
    args.get_url  = args.get_url or function(wp, data, choice)
        if data['data'][choice] then
            return baidu_url_uncompile(data['data'][choice]['objURL'])
        else
            return nil
        end
    end
    args.get_name = args.get_name or function(wp, data, choice)
        if wp.url[choice] then
            local name = string.gsub(wp.url[choice], "(.*/)(.*)", "-%2")
            name = string.gsub(name, '%?down$', "")
            return string.gsub(data['queryExt'], " ", "_") .. name
        else
            return nil
        end
    end

    return core.get_remotewallpaper(screen, args)
end

return get_baiduwallpaper
