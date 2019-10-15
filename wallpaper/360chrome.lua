---------------------------------------------------------------------------
--
--  360chrome Wallpaper module for away: away.wallpaper.360chrome
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

-- 360chromeWallPaper: fetch 360chrome's images with meta data
local function get_360chromewallpaper(screen, args)
    local args = args or {}
    args.id    = args.id or '360chrome'
    args.api   = args.api or "http://wallpaper.apc.360.cn/index.php"
    args.query = args.query or {
        c='WallPaper',
        -- Category, cid: http://cdn.apc.360.cn/index.php?c=WallPaper&a=getAllCategoriesV2&from=360chrome
        -- "4K专区"=36, "美女模特"=6, "爱情美图"=30, "风景大片"=9, "小清新"=15, "萌宠动物"=14, ...
        a='getAppsByCategory', cid=36,
        -- search, kw: 4k, 4k专区, 美女, 风景, 风景大片, 写真 ...
        -- a='search', kw='4k 风景',
        start=100, count=20, from='360chrome'
    }
    args.choices  = args.choices or util.simple_range(1, 20, 1)
    args.curl     = args.curl or 'curl -f -s -m 30' -- max-time 30 for 4K
    args.cachedir = args.cachedir or gfs.get_xdg_cache_home() .. "wallpaper-360chrome"
    --args.timeout_info = args.timeout_info or 86400
    --args.async_update = args.async_update or false
    --args.setting      = args.setting or function(wp)
    --    gears.wallpaper.maximized(wp.path[wp.using], wp.screen, false)
    --end
    --args.force_hd = args.force_hd or true
    args.get_url = args.get_url or function(wp, data, choice)
        if data['data'][choice] then
            return string.gsub(data['data'][choice]['url'], "(.*/)__85(/.*)", "%1__90%2")
        else
            return nil
        end
    end
    args.get_name = args.get_name or function(wp, data, choice)
        if data['data'][choice] then
            local name = string.gsub(wp.url[choice], "(.*/)(.*)", "-%2")
            local utag, patterns, i, p = data['data'][choice]['utag'], {{'[_ ]+', '-'}}
            if not utag then
                utag = data['data'][choice]['tag']
                patterns = {{'category', ''}, {'全部', ''}, {'[_ ]+', '_'}, {'^[_]*(.-)[_]*$', '%1'}}
            end
            for i, p in pairs(patterns) do
                utag = string.gsub(utag, p[1], p[2])
            end
            return data['data'][choice]['class_id'] .. '-' .. utag .. name
        else
            return nil
        end
    end

    return core.get_remotewallpaper(screen, args)
end

return get_360chromewallpaper
