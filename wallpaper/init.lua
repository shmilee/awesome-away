---------------------------------------------------------------------------
--
--  Wallpaper module for away: away.wallpaper
--
--  Copyright (c) 2019 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local util    = require("away.util")
local core    = require("away.wallpaper.core")
local gears   = require("gears")
local naughty = require("naughty")

local os    = { time = os.time }
local math  = { randomseed = math.randomseed, random = math.random }
local table = { insert = table.insert }
local next, type, tonumber, tostring = next, type, tonumber, tostring

local wallpaper = {}

wallpaper.available = {
    ['local'] = core.get_localwallpaper,
    ['360chrome'] = require("away.wallpaper.360chrome"),
    ['baidu'] = require("away.wallpaper.baidu"),
    ['bing'] = require("away.wallpaper.bing"),
    ['nationalgeographic'] = require("away.wallpaper.nationalgeographic"),
    ['spotlight'] = require("away.wallpaper.spotlight"),
    ['wallhaven'] = require("away.wallpaper.wallhaven"),
    -- Need to sign up
    -- unsplash : https://unsplash.com/documentation
    -- -- client_id, curl xxx -d ''
    -- pixabay : https://pixabay.com/api/docs/
    -- -- key, orientation
}

-- Solo Wallpaper
function wallpaper.get_solowallpaper(screen, name, args)
    if wallpaper.available[name] ~= nil then
        args = args or {}
        args.async_update = true
        local swp = wallpaper.available[name](screen, args)
        local timeout = args.timeout or 60
        swp.timer = gears.timer({ timeout=timeout, autostart=true, callback=swp.update })
        function swp.print_using()
            if swp.path == nil or swp.path[swp.using] == nil then
                util.print_info('Using Wallpaper nil', swp.id)
                naughty.notify({ title = 'Using Wallpaper nil' })
            else
                util.print_info('Using Wallpaper ' .. swp.path[swp.using], swp.id)
                naughty.notify({ title = 'Using Wallpaper ' .. swp.path[swp.using]})
            end
        end
        return swp
    else
        return nil
    end
end

-- MISC Wallpaper
function wallpaper.get_miscwallpaper(screen, margs, candidates)
    local mwp     = { screen=screen, members={}, using=nil }
    local id      = core.assemble_id_with_screen(screen, 'MISC')
    local timeout = margs.timeout or 60
    local random  = margs.random or false

    if type(candidates) ~= 'table' then
        util.print_error('Need table of candidates!', id)
        return nil
    end
    local candidates_on = {}
    local i, j, name, weight, args
    for i=1,#candidates do
        name, weight = candidates[i].name, tonumber(candidates[i].weight)
        if weight and weight > 0 and wallpaper.available[name] ~= nil then
            table.insert(candidates_on, candidates[i])
        end
    end
    if #candidates_on < 1 then
        util.print_error('Need at least one candidate!', id)
        return nil
    end
    mwp.using = 1
    if random then
        math.randomseed(os.time())
        mwp.using = math.random(1, #candidates_on)
    end
    for i=1,#candidates_on do
        name, args = candidates[i].name, candidates[i].args or {}
        weight = tonumber(candidates[i].weight)
        if i == mwp.using then
            args.async_update = true
            -- mwp.using rise with weight
            mwp.using = #mwp.members + 1
        else
            args.async_update = false
        end
        wp = wallpaper.available[name](screen, args)
        if wp then
            for j=1,weight do
                table.insert(mwp.members, wp)
            end
        end
    end
    if #mwp.members < 1 then
        util.print_error('Need at least one member!', id)
        return nil
    end

    local recursion_try = 0
    function mwp.update()
        if random then
            mwp.using = math.random(1,#mwp.members)
        else
            mwp.using = next(mwp.members, mwp.using)
            if mwp.using == nil then
                mwp.using = next(mwp.members, nil)
            end
        end
        local wall = mwp.members[mwp.using]
        if wall and wall.update() ~= false then
            recursion_try = 0
            -- Restart the timer, correct timeout
            mwp.timer:again()
        else
            recursion_try = recursion_try + 1
            if recursion_try <= util.recursion_try_limit then
                util.print_info('Recursion try ' .. tostring(recursion_try), id)
                mwp.update()
            end
        end
    end

    function mwp.print_using()
        local wall = mwp.members[mwp.using]
        if wall.print_using() then
            util.print_info('Using Wallpaper ' .. wall.print_using(), id)
            naughty.notify({ title = 'Using Wallpaper ' .. wall.print_using()})
        else
            util.print_info('Using Wallpaper nil', id)
            naughty.notify({ title = 'Using Wallpaper nil' })            
        end
    end

    mwp.timer = gears.timer({ timeout=timeout, autostart=true, callback=mwp.update })

    return mwp
end

return wallpaper
