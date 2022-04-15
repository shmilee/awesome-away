local gears = require('gears')
local naughty = require("naughty")
local pairs = pairs
local capi = {
    awesome = awesome,
    client = client,
    mouse = mouse,
    tag = tag,
}

-- adjust the time if you are on a slow cpu to give more time for the client
local micky = { wait_time = 0.05 }

-- relocate mouse to the client, default focus client
function micky.move_to_client(c)
    c = c or capi.client.focus
    if c then
        local g = c:geometry()
        capi.mouse.coords({
            x = g.x + g.width // 2,
            y = g.y + g.height // 2,
        }, true)
    end
end

-- class names defined here would insist micky stays where he is at.
micky.stay_classes = { 
    capi.awesome
    -- taskbar
}

-- check if client c in stay_classes
function micky.check_stay(c)
    return micky.stay_classes[c and c.class] ~= nil
end

-- check if client c is under mouse
function micky.check_under(c)
    return c == capi.mouse.current_client
end

-- check if client c1, c2 have same coords
function micky.check_coords(c1, c2)
    if not c1 or not c2 then
        return false
    end
    local g1, g2 = c1:geometry(), c2:geometry()
    return g1.x == g2.x and g1.y == g2.y
end

-- default rule for signal focus
function micky.rule_focus(c)
    -- c is focused client, wait_time waiting for focus to complete.
    gears.timer.weak_start_new(micky.wait_time, function()
        if micky.check_stay(c) then
            return false
        end
        if micky.check_under(c) then
            return false
        end
        if micky.check_coords(c, capi.mouse.current_client) then
            return false
        end
        micky.move_to_client(c)
        return false -- call only once then stop
    end)
end

-- default rule for signal swapped
function micky.rule_swapped(c)
    if c == capi.client.focus then
        -- callback for only one client
        micky.rule_focus(c)
        -- naughty.notify({text=c.name})
    end
end

-- default rule for signal unmanage
function micky.rule_unmanage(c)
    -- naughty.notify({text=c.name})
    gears.timer.weak_start_new(micky.wait_time, function()
        micky.rule_focus(capi.client.focus)
        return false
    end)
end

-- default rule for signal tag layout
function micky.rule_layout(t)
    -- naughty.notify({text=t.name})
    gears.timer.weak_start_new(micky.wait_time, function()
        micky.rule_focus(capi.client.focus)
        return false
    end)
end

-- flag for signal `all_registered_rules`, enabled or not
micky.enabled = false
micky.all_registered_rules = {
    -- { class e.g. client, signal e.g. 'focus', func e.g. micky.rule_focus }
    { capi.client, "focus", micky.rule_focus },
    { capi.client, "swapped", micky.rule_swapped },
    { capi.client, "unmanage", micky.rule_unmanage },
    { capi.tag, "property::layout", micky.rule_layout },
}

-- enable signal `all_registered_rules`
function micky.enable()
    for _, r in pairs(micky.all_registered_rules) do
        if r[1] and r[1].connect_signal then
            r[1].connect_signal(r[2], r[3])
        end
    end
    micky.enabled = true
end

-- disable signal `all_registered_rules`
function micky.disable()
    for _, r in pairs(micky.all_registered_rules) do
        if r[1] and r[1].disconnect_signal then
            r[1].disconnect_signal(r[2], r[3])
        end
    end
    micky.enabled = false
end

-- toggle enable/disable
function micky.toggle()
    if micky.enabled then
        micky.disable()
    else
        micky.enable()
    end
end

return micky

-- naughty.notify({text=current_client.name})
-- naughty.notify({text=focused_client.name})
-- local inspect = require('inspect')
-- naughty.notify({text=inspect(c:geometry())})
-- naughty.notify({text=inspect(capi.mouse.current_widget_geometry)})
