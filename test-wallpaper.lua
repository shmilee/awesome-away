local os = os
local util = require("away.util")
local wallpaper = require("away.wallpaper")

local test = {}

-- c: test1, test2, misc, local and other wallpaper.available items
function test.get_wallpaper(screen, c)
    if c == 'test1' then
        return wallpaper.get_solowallpaper(screen,'test1', {})
    elseif c == 'test2' then
        return wallpaper.get_miscwallpaper(screen, {}, nil)
    elseif c == 'local' then
        return wallpaper.get_solowallpaper(screen, 'local', {
            id='Local lovebizhi',
            dirpath=os.getenv("HOME") .. "/.cache/wallpaper-lovebizhi",
            filter='^风光风景', timeout=5,
        })
    elseif wallpaper.available[c] then
        return wallpaper.get_solowallpaper(screen, c, { timeout=5 })
    elseif c == 'misc' then
        return wallpaper.get_miscwallpaper(screen, { timeout=5, random=true }, {
            { name='bing', weight=5,
              args={
                query={ format='js', idx=1, n=4 },
                force_hd=true,
              },
            },
            { name='360chrome', weight=1,
              args={
                query={
                    c='WallPaper', a='getAppsByCategory', cid=9,
                    start=100, count=20, from='360chrome',
                },
              },
            },
            { name='baidu', weight=1,
              args={
                query={
                    tn='resultjson_com', cg='wallpaper', ipn='rj',
                    word='壁纸+不同风格+简约',
                    pn=0, rn=30,
                    width=1920, height=1080,
                },
                choices=util.simple_range(1, 30, 1),
                cachedir=os.getenv("HOME") .. "/.cache/wallpaper-baidu-new",
              },
            },
            { name='nationalgeographic', weight=1,
              args={
                choices=util.simple_range(1, 28, 1),
                force_hd=true,
              },
            },
            { name='spotlight', weight=1,
              args={
                query={
                    fmt='json', lc='zh-CN', ctry='CN',
                    pid=209562,
                },
                choices={ 1, 2, 3, 4 },
              },
            },
            { name='local', weight=2,
              args={
                id='Local lovebizhi',
                dirpath=os.getenv("HOME") .. "/.cache/wallpaper-360chrome",
                filter='^风光风景',
              },
            },
        })
    else
        return nil
    end
end

return test
